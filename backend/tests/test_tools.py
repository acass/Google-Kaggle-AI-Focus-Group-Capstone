import pytest


def test_record_citation_writes_to_state():
    from backend.agents.tools.citation_tracker import record_citation
    from unittest.mock import MagicMock

    mock_ctx = MagicMock()
    mock_ctx.state = {}

    result = record_citation(
        title="Test Article",
        url="https://example.com/article",
        excerpt="Key finding from the article.",
        tool_context=mock_ctx,
    )

    assert mock_ctx.state["citations"] == [
        {"title": "Test Article", "url": "https://example.com/article", "excerpt": "Key finding from the article."}
    ]
    assert "1" in result  # total count in message


def test_record_citation_appends_to_existing():
    from backend.agents.tools.citation_tracker import record_citation
    from unittest.mock import MagicMock

    mock_ctx = MagicMock()
    mock_ctx.state = {"citations": [{"title": "First", "url": "https://a.com", "excerpt": "x"}]}

    record_citation(title="Second", url="https://b.com", excerpt="y", tool_context=mock_ctx)

    assert len(mock_ctx.state["citations"]) == 2


def test_record_citation_tool_is_function_tool():
    from backend.agents.tools.citation_tracker import record_citation_tool
    from google.adk.tools import FunctionTool

    assert isinstance(record_citation_tool, FunctionTool)
    assert record_citation_tool.name == "record_citation"
