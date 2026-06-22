from google.adk.tools import FunctionTool, ToolContext


def record_citation(
    title: str,
    url: str,
    excerpt: str,
    tool_context: ToolContext,
) -> str:
    """Record a source citation after finding useful information via search.

    Call this after each google_search or url_context result that you cite in
    your response. The citations are included in the final report.

    Args:
        title: The title of the source article or page.
        url: The full URL of the source.
        excerpt: A short quote or summary of the key fact you are citing.
    """
    if "citations" not in tool_context.state:
        tool_context.state["citations"] = []

    tool_context.state["citations"].append(
        {"title": title, "url": url, "excerpt": excerpt}
    )
    total = len(tool_context.state["citations"])
    return f"Citation recorded (total: {total}): {title}"


record_citation_tool = FunctionTool(record_citation)
