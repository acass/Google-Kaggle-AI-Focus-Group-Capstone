import logging
from google.adk.plugins.base_plugin import BasePlugin
from google.adk.tools import BaseTool, ToolContext

logger = logging.getLogger(__name__)

MAX_TOOLS_PER_NODE = 10


class BlueTeamAnalyticsPlugin(BasePlugin):
    """
    Agent Defender (Blue Team)
    Monitors per-node tool usage and calculates a Trust Score.
    Detects Intent Drift if a single workflow node calls an unusual number of tools.
    """

    def __init__(self, name: str = "blue_team_analytics"):
        super().__init__(name=name)

    async def after_tool_callback(
        self, *, tool: BaseTool, tool_args: dict, tool_context: ToolContext, result: dict
    ) -> dict | None:
        state = tool_context.state
        node = tool_context.node_path or "unknown"

        if "agbom" not in state:
            state["agbom"] = []
        if "agbom_per_node" not in state:
            state["agbom_per_node"] = {}
        if "trust_score" not in state:
            state["trust_score"] = 100

        record = {
            "node": node,
            "tool": tool.name,
            "args": tool_args,
            "status": "success" if result else "unknown",
        }
        state["agbom"].append(record)

        if node not in state["agbom_per_node"]:
            state["agbom_per_node"][node] = []
        state["agbom_per_node"][node].append(record)

        node_call_count = len(state["agbom_per_node"][node])

        if node_call_count > MAX_TOOLS_PER_NODE:
            logger.warning(
                f"Blue Team Alert: Node '{node}' has called {node_call_count} tools "
                f"(threshold: {MAX_TOOLS_PER_NODE}). Potential Intent Drift detected."
            )
            state["trust_score"] = max(0, state["trust_score"] - 25)

            if state["trust_score"] < 50:
                logger.error(
                    "Blue Team Alert: Trust Score below threshold. "
                    "Flagging for Green Team quarantine."
                )
                state["quarantine_flag"] = True

        return None
