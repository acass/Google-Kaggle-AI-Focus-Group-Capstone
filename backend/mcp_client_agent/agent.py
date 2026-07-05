"""ADK CLI agent that consumes the project's own MCP server.

This demonstrates the **Agent Skills / Agents CLI** capability: the same
synthetic research panel that powers the Flutter app is also published as a
standard MCP server (``backend/mcp_server/server.py``). Here an ADK agent, run
from the terminal via ``adk run``, connects to that server as an MCP *client*
and calls its tools (``list_personas``, ``score_idea``, ``record_citation`` …).

Run it from the REPO ROOT so the server's package-relative imports resolve:

    export GOOGLE_API_KEY=...        # or GEMINI_API_KEY
    backend/.venv/bin/adk run backend/mcp_client_agent

Then, at the prompt, try:

    List the panel personas, then have Marcus Chen score an idea with
    innovation 8, market 6, ux 5, feasibility 7, monetization 4, risk 3.
"""

from __future__ import annotations

import os

from google.adk.agents import Agent
from google.adk.tools.mcp_tool import MCPToolset, StdioConnectionParams
from mcp import StdioServerParameters

# Absolute repo root, derived from this file's location so the launched MCP
# server subprocess always starts with the correct working directory
# (its imports are package-relative and require cwd == repo root).
_REPO_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), os.pardir, os.pardir)
)

# Connect to our own MCP server over stdio. A generous timeout gives the
# server process time to import google-adk on cold start.
_panel_toolset = MCPToolset(
    connection_params=StdioConnectionParams(
        server_params=StdioServerParameters(
            command=os.path.join(_REPO_ROOT, "backend", ".venv", "bin", "python"),
            args=["-m", "backend.mcp_server.server"],
            cwd=_REPO_ROOT,
        ),
        timeout=30.0,
    ),
)

root_agent = Agent(
    name="panel_cli",
    model="gemini-2.0-flash",
    instruction=(
        "You drive a synthetic market-research panel through its MCP tools. "
        "Use `list_personas` to discover the panel, `get_persona` for detail, "
        "and `score_idea` to compute a persona's weighted verdict. Always call "
        "the tools rather than guessing; report the numbers the tools return."
    ),
    tools=[_panel_toolset],
)
