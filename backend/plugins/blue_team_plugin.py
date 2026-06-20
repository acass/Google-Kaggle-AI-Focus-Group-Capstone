import logging
from google.adk.plugins.base_plugin import BasePlugin
from google.adk.tools import BaseTool, ToolContext

logger = logging.getLogger(__name__)

class BlueTeamAnalyticsPlugin(BasePlugin):
    """
    Agent Defender (Blue Team)
    Monitors the Runtime AgBOM (Agent Bill of Materials) and calculates a Trust Score.
    Detects Intent Drift if the agent enters an infinite loop or calls an unusual number of tools.
    """

    def __init__(self, name: str = "blue_team_analytics"):
        super().__init__(name=name)

    async def after_tool_callback(self, *, tool: BaseTool, args: dict, tool_context: ToolContext, tool_response: dict) -> dict | None:
        state = tool_context.state
        
        # Initialize AgBOM and Trust Score if not present
        if "agbom" not in state:
            state["agbom"] = []
        if "trust_score" not in state:
            state["trust_score"] = 100

        # Record the tool invocation in the AgBOM
        invocation_record = {
            "tool": tool.name,
            "args": args,
            # We don't log the full response here to avoid massive state, just the status if possible
            "status": "success" if tool_response else "unknown"
        }
        state["agbom"].append(invocation_record)

        # Behavioural Analytics: Detect Intent Drift (e.g. too many tool calls)
        total_calls = len(state["agbom"])
        
        if total_calls > 5:  # Low threshold for demonstration
            logger.warning(f"Blue Team Alert: Agent has called {total_calls} tools. Potential Intent Drift detected.")
            state["trust_score"] = max(0, state["trust_score"] - 25)
            
            if state["trust_score"] < 50:
                logger.error("Blue Team Alert: Trust Score below threshold. Flagging for Green Team quarantine.")
                state["quarantine_flag"] = True

        return None
