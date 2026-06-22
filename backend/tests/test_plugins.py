import pytest
from unittest.mock import MagicMock, AsyncMock


@pytest.mark.asyncio
async def test_blue_team_does_not_fire_on_normal_usage():
    from backend.plugins.blue_team_plugin import BlueTeamAnalyticsPlugin, MAX_TOOLS_PER_NODE

    plugin = BlueTeamAnalyticsPlugin()

    mock_tool = MagicMock()
    mock_tool.name = "google_search"

    mock_ctx = MagicMock()
    mock_ctx.state = {"trust_score": 100}
    mock_ctx.node_path = "independent_p1"

    # Simulate MAX_TOOLS_PER_NODE calls from the same node — should NOT trigger quarantine
    for _ in range(MAX_TOOLS_PER_NODE):
        await plugin.after_tool_callback(
            tool=mock_tool, args={}, tool_context=mock_ctx, tool_response={"result": "ok"}
        )

    assert mock_ctx.state.get("quarantine_flag") is not True
    assert mock_ctx.state["trust_score"] == 100


@pytest.mark.asyncio
async def test_blue_team_fires_on_excessive_node_usage():
    from backend.plugins.blue_team_plugin import BlueTeamAnalyticsPlugin, MAX_TOOLS_PER_NODE

    plugin = BlueTeamAnalyticsPlugin()

    mock_tool = MagicMock()
    mock_tool.name = "google_search"

    mock_ctx = MagicMock()
    mock_ctx.state = {"trust_score": 100}
    mock_ctx.node_path = "independent_p1"

    # Exceed the threshold
    for _ in range(MAX_TOOLS_PER_NODE + 3):
        await plugin.after_tool_callback(
            tool=mock_tool, args={}, tool_context=mock_ctx, tool_response={"result": "ok"}
        )

    assert mock_ctx.state["trust_score"] < 100
