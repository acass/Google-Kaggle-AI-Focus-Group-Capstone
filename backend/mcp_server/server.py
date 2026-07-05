"""Synthetic Market Intelligence — MCP Server.

Why this exists
---------------
The core product runs an in-process Google ADK workflow (see
``backend/agents/graph.py``). That is great for the bundled Flutter frontend,
but it locks the panel's capabilities inside this Python process. This module
publishes those same capabilities over the **Model Context Protocol (MCP)** so
external agents and hosts (Claude Desktop, the Agents CLI, another ADK agent
acting as an MCP *client*) can:

* discover the five research personas and their scoring lenses,
* compute a weighted score for a candidate idea using a persona's own weights,
* record and read back source citations that back a panel verdict.

Design notes
------------
* **Single source of truth.** Persona data comes straight from
  ``backend.agents.personas.PERSONAS`` — the MCP surface never re-declares
  personas, so the panel the frontend sees and the panel an MCP client sees can
  never drift apart.
* **Standalone-safe citations.** The in-workflow ``record_citation`` tool writes
  to ADK ``tool_context.state``. An MCP client has no ADK state, so here we
  persist citations to a small JSON file (``CITATIONS_STORE``) keyed by session.
  This keeps the MCP tool useful on its own while mirroring the same
  ``{title, url, excerpt}`` record shape used everywhere else in the codebase.
* **Transport.** Runs over stdio by default (what Claude Desktop / the Agents
  CLI expect). Pass ``--http`` to serve streamable HTTP instead.

Run it
------
    # from the repo root, with the project venv active
    python -m backend.mcp_server.server            # stdio (default)
    python -m backend.mcp_server.server --http     # streamable HTTP on :8765
"""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP

# Reuse the canonical persona library rather than redefining it here.
# ``get_persona`` is imported under a private alias because we expose a public
# MCP tool of the same name below; the alias keeps the internal lookup working.
from backend.agents.personas import (
    PERSONAS,
    get_all_persona_ids,
    get_persona as _get_persona,
)

# ---------------------------------------------------------------------------
# Persistence for citations (standalone equivalent of ADK tool_context.state)
# ---------------------------------------------------------------------------

# Allow the store path to be overridden (e.g. a tmpfs in production / tests).
CITATIONS_STORE = Path(
    os.environ.get(
        "MCP_CITATIONS_STORE",
        Path(__file__).with_name("citations_store.json"),
    )
)


def _load_citations() -> dict[str, list[dict[str, str]]]:
    """Return the on-disk citation map, or an empty map if none exists yet."""
    if CITATIONS_STORE.exists():
        try:
            return json.loads(CITATIONS_STORE.read_text())
        except json.JSONDecodeError:
            # Corrupt file should never crash the server; start clean.
            return {}
    return {}


def _save_citations(data: dict[str, list[dict[str, str]]]) -> None:
    """Atomically persist the citation map to disk."""
    tmp = CITATIONS_STORE.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, indent=2))
    tmp.replace(CITATIONS_STORE)


# ---------------------------------------------------------------------------
# Server definition
# ---------------------------------------------------------------------------

mcp = FastMCP(
    "synthetic-market-intelligence",
    instructions=(
        "A synthetic research panel of five opinionated AI personas. Use "
        "list_personas to discover the panel, get_persona for a single "
        "persona's biases and scoring lens, score_idea to see how a specific "
        "persona would weight a set of category scores, and record_citation / "
        "list_citations to attach evidence to a verdict."
    ),
)


# ----- Tools ---------------------------------------------------------------


@mcp.tool()
def list_personas() -> list[dict[str, Any]]:
    """List every research persona on the panel with a short profile.

    Returns id, name, role, hidden motivation and scoring weights for each of
    the five personas — enough for a client to decide which lens to apply.
    """
    return [
        {
            "id": p["id"],
            "name": p["name"],
            "role": p["role"],
            "hidden_motivation": p["hidden_motivation"],
            "scoring_weights": p["scoring_weights"],
        }
        for p in PERSONAS.values()
    ]


@mcp.tool()
def get_persona(persona_id: str) -> dict[str, Any]:
    """Return the full profile for one persona.

    Args:
        persona_id: One of the ids from ``list_personas`` (e.g.
            "skeptical_investor", "enterprise_cto").
    """
    # Reuses backend.agents.personas.get_persona (aliased _get_persona), which
    # raises ValueError with the list of valid ids on a bad key — surfaced to
    # the client as a tool error.
    return dict(_get_persona(persona_id))  # type: ignore[arg-type]


@mcp.tool()
def score_idea(persona_id: str, category_scores: dict[str, float]) -> dict[str, Any]:
    """Weight raw category scores by a persona's personal scoring lens.

    Mirrors how the ADK ``vote`` node combines per-category scores with each
    persona's ``scoring_weights`` into a single weighted score, so an MCP
    client gets the same math the internal workflow uses.

    Args:
        persona_id: The persona whose weights to apply.
        category_scores: Raw 0-10 scores keyed by category. Valid categories:
            innovation, market, ux, feasibility, monetization, risk.
    """
    persona = _get_persona(persona_id)
    weights = persona["scoring_weights"]

    valid = set(weights.keys())
    unknown = set(category_scores) - valid
    if unknown:
        raise ValueError(
            f"Unknown categories {sorted(unknown)}. Valid: {sorted(valid)}"
        )

    weighted_total = 0.0
    weight_total = 0.0
    for category, weight in weights.items():
        raw = float(category_scores.get(category, 0.0))
        weighted_total += raw * weight
        weight_total += weight

    weighted_score = round(weighted_total / weight_total, 2) if weight_total else 0.0
    return {
        "persona_id": persona_id,
        "persona_name": persona["name"],
        "weighted_score": weighted_score,
        "applied_weights": weights,
    }


@mcp.tool()
def record_citation(
    title: str,
    url: str,
    excerpt: str,
    session_id: str = "default",
) -> str:
    """Record a source citation that backs a panel finding.

    Standalone MCP equivalent of the in-workflow ``record_citation`` tool: it
    stores the same ``{title, url, excerpt}`` record shape, but persists to the
    JSON store (``MCP_CITATIONS_STORE``) instead of ADK session state.

    Args:
        title: Title of the source article or page.
        url: Full URL of the source.
        excerpt: Short quote or summary of the key fact being cited.
        session_id: Group citations by panel session (defaults to "default").
    """
    data = _load_citations()
    bucket = data.setdefault(session_id, [])
    bucket.append(
        {
            "title": title,
            "url": url,
            "excerpt": excerpt,
            "recorded_at": datetime.now(timezone.utc).isoformat(),
        }
    )
    _save_citations(data)
    return f"Citation recorded (session '{session_id}', total: {len(bucket)}): {title}"


@mcp.tool()
def list_citations(session_id: str = "default") -> list[dict[str, str]]:
    """Return all citations recorded for a session.

    Args:
        session_id: The session whose citations to return (defaults to "default").
    """
    return _load_citations().get(session_id, [])


# ----- Resources -----------------------------------------------------------


@mcp.resource("persona://{persona_id}")
def persona_resource(persona_id: str) -> str:
    """Expose a persona profile as a readable MCP resource (JSON text)."""
    return json.dumps(dict(_get_persona(persona_id)), indent=2)  # type: ignore[arg-type]


@mcp.resource("panel://roster")
def panel_roster() -> str:
    """Expose the full panel roster as a single readable resource."""
    roster = {pid: PERSONAS[pid]["name"] for pid in get_all_persona_ids()}
    return json.dumps(roster, indent=2)


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------


def build_server() -> FastMCP:
    """Return the configured server (handy for tests and embedding)."""
    return mcp


def main() -> None:
    parser = argparse.ArgumentParser(description="Synthetic Market Intelligence MCP server")
    parser.add_argument(
        "--http",
        action="store_true",
        help="Serve streamable HTTP instead of stdio.",
    )
    args = parser.parse_args()

    # FastMCP picks the transport by name: "stdio" for CLI/desktop hosts,
    # "streamable-http" for network hosts.
    mcp.run(transport="streamable-http" if args.http else "stdio")


if __name__ == "__main__":
    main()
