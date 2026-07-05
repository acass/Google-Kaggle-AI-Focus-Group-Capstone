"""MCP server package.

Exposes the Synthetic Market Intelligence panel (personas + citation tools)
over the Model Context Protocol so that *any* MCP-capable client — Claude
Desktop, the Agents CLI, another ADK agent, etc. — can drive the panel without
importing this project's Python internals.

The server deliberately reuses the same persona definitions
(``backend.agents.personas``) and the same citation contract
(``backend.agents.tools.citation_tracker``) that the in-process ADK workflow
uses, so there is a single source of truth.
"""

from .server import mcp, build_server

__all__ = ["mcp", "build_server"]
