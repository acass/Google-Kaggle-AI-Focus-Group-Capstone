# MCP Server

The project ships a **Model Context Protocol (MCP) server** that publishes the
synthetic research panel's capabilities to any MCP-capable host — Claude
Desktop, the Agents CLI, or another ADK agent acting as an MCP *client*.

This is the same panel the Flutter frontend uses, exposed over a standard
protocol instead of being locked inside the Python process. Persona data comes
directly from `backend/agents/personas.py`, so the internal workflow and the MCP
surface can never drift apart.

## Why an MCP server?

The in-process ADK workflow (`backend/agents/graph.py`) is ideal for the bundled
UI, but it can't be reused by external agents. Wrapping the panel as an MCP
server makes three capabilities portable and composable:

- **Discover the panel** — list the five personas and their scoring lenses.
- **Apply a persona's lens** — weight raw category scores with a persona's own
  `scoring_weights`, using the same math as the ADK `vote` node.
- **Attach evidence** — record and read back `{title, url, excerpt}` citations,
  mirroring the in-workflow `record_citation` tool.

## Surface

### Tools

| Tool | Purpose |
|------|---------|
| `list_personas` | List all five personas with role, hidden motivation, and scoring weights. |
| `get_persona(persona_id)` | Full profile for one persona. |
| `score_idea(persona_id, category_scores)` | Weight raw 0–10 category scores by that persona's lens. |
| `record_citation(title, url, excerpt, session_id?)` | Persist a source citation for a session. |
| `list_citations(session_id?)` | Read back a session's citations. |

### Resources

| Resource URI | Content |
|--------------|---------|
| `panel://roster` | Map of persona id → name. |
| `persona://{persona_id}` | Full JSON profile for one persona. |

Categories used by `score_idea`: `innovation`, `market`, `ux`, `feasibility`,
`monetization`, `risk`.

## Running

Install deps (adds the `mcp` package) and run from the **repo root** so the
package-relative imports resolve:

```bash
backend/.venv/bin/pip install -r backend/requirements.txt

# stdio transport (Claude Desktop / Agents CLI)
backend/.venv/bin/python -m backend.mcp_server.server

# streamable HTTP on :8765
backend/.venv/bin/python -m backend.mcp_server.server --http
```

## Wiring into a client

See `backend/mcp_server/client-config.example.json`. For Claude Desktop, add the
`mcpServers` entry to your host config, set `cwd` to the repo root, and point
`command` at the project venv's Python.

## Agents CLI demo

The MCP server isn't just consumable by Claude Desktop — it can be driven from
the **Google ADK Agents CLI**. `backend/mcp_client_agent/` is a minimal ADK
agent that connects to this server as an MCP *client* (via `MCPToolset` over
stdio) and calls its tools from the terminal. This demonstrates the panel's
capabilities being discovered and invoked through a standard CLI host, with no
UI in the loop.

Run it **from the repo root** (the server uses package-relative imports and
requires `cwd` == repo root, which the agent sets automatically):

```bash
export GOOGLE_API_KEY=...        # or GEMINI_API_KEY — the agent's Gemini model
backend/.venv/bin/adk run backend/mcp_client_agent
```

`adk run` imports the agent directory, finds `root_agent`, and opens an
interactive prompt. On the first tool call the agent spawns
`python -m backend.mcp_server.server` as a stdio subprocess and lists its tools.
Try:

```
List the panel personas, then have Marcus Chen score an idea with
innovation 8, market 6, ux 5, feasibility 7, monetization 4, risk 3.
```

The agent calls `list_personas` then `score_idea` and returns Marcus's weighted
verdict — the same scoring math as the in-workflow ADK `vote` node, now reached
through the CLI. (Use `adk web` instead of `adk run` for a browser UI.)

## Configuration

| Env var | Default | Purpose |
|---------|---------|---------|
| `MCP_CITATIONS_STORE` | `backend/mcp_server/citations_store.json` | Where citations persist. The store is gitignored. |

The store is the standalone equivalent of ADK `tool_context.state` — an MCP
client has no ADK session, so citations persist to JSON instead.
