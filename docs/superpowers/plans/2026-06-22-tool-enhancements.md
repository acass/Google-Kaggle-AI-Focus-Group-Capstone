# Tool Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `url_context`, citation tracking, and `google_search` to all agents that benefit from them, and fix the Blue Team plugin's threshold so it doesn't fire on every normal session.

**Architecture:** ADK's built-in `url_context` tool (Gemini 2 native — no code execution needed) lets agents follow search result URLs to read full article content. A `FunctionTool`-wrapped `record_citation` function writes structured source citations into workflow state, making every search result traceable through to the final report. The Blue Team plugin is fixed to track per-node call counts (using `tool_context.node_path`) instead of a single global counter that triggers on normal usage.

**Tech Stack:** Google ADK 2.0, `google.adk.tools.FunctionTool`, `google.adk.tools.url_context`, `google.adk.tools.google_search`, Python 3.11, pytest.

## Global Constraints

- All agents use Gemini 2 models (`gemini-2.5-pro` or `gemini-2.5-flash`) — `url_context` requires Gemini 2.
- Tool imports must use `from google.adk.tools import ...` — not the genai package directly.
- `FunctionTool` auto-injects `tool_context: ToolContext` when the parameter is typed with `ToolContext`.
- Do not modify the voting node (`make_vote`) — it uses `output_schema` for structured JSON and doesn't benefit from search.
- Do not add `record_citation_tool` to the synthesizer — it aggregates, it doesn't discover; it should reference citations already in state.
- Keep all existing exports working; use `Annotated[list[dict], operator.add]` for the `citations` state field (merge-safe for parallel nodes).

---

### Task 1: Add `citations` to state model and `FinalReport`

**Files:**
- Modify: `backend/models/state.py`

**Interfaces:**
- Produces: `FocusGroupState["citations"]` — `Annotated[list[dict], operator.add]`, merged across parallel nodes
- Produces: `FinalReport["citations"]` — `list[dict]`, each entry has `title: str`, `url: str`, `excerpt: str`

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_schemas.py — add to the existing file
def test_focus_group_state_has_citations_field():
    from backend.models.state import FocusGroupState
    import typing
    hints = typing.get_type_hints(FocusGroupState, include_extras=True)
    assert "citations" in hints

def test_final_report_has_citations_field():
    from backend.models.state import FinalReport
    import typing
    hints = typing.get_type_hints(FinalReport, include_extras=True)
    assert "citations" in hints
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/christophercass03/Desktop/Agentic-Focus-Group
backend/.venv/bin/pytest backend/tests/test_schemas.py -v -k "citations"
```

Expected: FAIL with `AssertionError`

- [ ] **Step 3: Add fields to state.py**

Open `backend/models/state.py`. Add `citations` to `FocusGroupState` and `FinalReport`:

```python
# In FinalReport TypedDict — add after `sentiment`:
    citations: list[dict]
```

```python
# In FocusGroupState TypedDict — add after `stream_events`:
    citations: Annotated[list[dict], operator.add]
```

- [ ] **Step 4: Run test to verify it passes**

```bash
backend/.venv/bin/pytest backend/tests/test_schemas.py -v -k "citations"
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/models/state.py backend/tests/test_schemas.py
git commit -m "feat: add citations field to FocusGroupState and FinalReport"
```

---

### Task 2: Create the citation tracker tool

**Files:**
- Create: `backend/agents/tools/__init__.py`
- Create: `backend/agents/tools/citation_tracker.py`

**Interfaces:**
- Consumes: `google.adk.tools.FunctionTool`, `google.adk.tools.ToolContext`
- Produces: `record_citation_tool` — a `FunctionTool` instance, importable from `backend.agents.tools`

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_tools.py — new file
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
backend/.venv/bin/pytest backend/tests/test_tools.py -v
```

Expected: FAIL with `ModuleNotFoundError`

- [ ] **Step 3: Create `backend/agents/tools/citation_tracker.py`**

```python
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
```

- [ ] **Step 4: Create `backend/agents/tools/__init__.py`**

```python
from .citation_tracker import record_citation_tool

__all__ = ["record_citation_tool"]
```

- [ ] **Step 5: Run test to verify it passes**

```bash
backend/.venv/bin/pytest backend/tests/test_tools.py -v
```

Expected: all 3 PASS

- [ ] **Step 6: Commit**

```bash
git add backend/agents/tools/ backend/tests/test_tools.py
git commit -m "feat: add record_citation FunctionTool for source tracking"
```

---

### Task 3: Wire tools into moderator nodes

**Files:**
- Modify: `backend/agents/nodes/moderator.py:1-49` (intro node)
- Modify: `backend/agents/nodes/moderator.py:52-100` (followup node)

**Interfaces:**
- Consumes: `record_citation_tool` from `backend.agents.tools`
- Consumes: `url_context` from `google.adk.tools`

- [ ] **Step 1: Update imports in `moderator.py`**

Replace the existing import block at the top of `backend/agents/nodes/moderator.py`:

```python
from google.adk.agents import LlmAgent
from google.adk.agents.context import Context
from google.adk.tools import google_search, url_context
from ...models.state import FocusGroupState, StreamEvent
from ...agents.tools import record_citation_tool
```

- [ ] **Step 2: Update moderator intro node — tools list and prompt**

Replace the `agent = LlmAgent(...)` block inside `moderator_introduce_node` (lines 26-31):

```python
    agent = LlmAgent(
        name="moderator_intro",
        model="gemini-2.5-pro",
        instruction=prompt,
        tools=[google_search, url_context, record_citation_tool],
    )
```

Replace the prompt string (the `f"""..."""` block) with:

```python
    prompt = f"""You are a neutral, analytical focus group moderator running a synthetic research panel.

Topic being evaluated: {topic}

Panel participants: {panel}

Write a brief, focused introduction (3-5 sentences) that:
1. States the topic clearly
2. Sets the expectation that each panelist will give their honest, independent assessment
3. Asks them to identify strengths, weaknesses, risks, and specific suggestions

Before writing your introduction:
- Use your Search tool to fetch 1-2 real-world facts or recent news context about this topic.
- Follow at least one promising URL with the url_context tool to read the full article.
- Call record_citation for each source you use (title, url, key excerpt).

Be concise and professional. Do not be overly formal."""
```

- [ ] **Step 3: Update moderator followup node — tools list and prompt**

Replace the `agent = LlmAgent(...)` block inside `moderator_followup_node` (lines 76-81):

```python
    agent = LlmAgent(
        name="moderator_followup",
        model="gemini-2.5-pro",
        instruction=prompt,
        tools=[google_search, url_context, record_citation_tool],
    )
```

Replace the `prompt = f"""..."""` block in `moderator_followup_node` with:

```python
    prompt = f"""You are a neutral focus group moderator. The panel has just completed their independent evaluations.

Topic: {topic}

Independent responses:
{responses_text}

Write 2-3 targeted follow-up questions that:
1. Address the most significant disagreements between panelists
2. Probe the most critical unresolved risk or concern
3. Ask panelists to respond to each other's strongest point

If any panelist cited a specific factual claim you want to verify, use Search and url_context to check it, then call record_citation for the source. Reference what was actually said. Keep to 2-3 focused questions."""
```

- [ ] **Step 4: Verify the backend imports cleanly**

```bash
cd /Users/christophercass03/Desktop/Agentic-Focus-Group
backend/.venv/bin/python -c "from backend.agents.nodes.moderator import moderator_introduce_node, moderator_followup_node; print('OK')"
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add backend/agents/nodes/moderator.py
git commit -m "feat: add url_context and record_citation to moderator nodes"
```

---

### Task 4: Wire tools into participant nodes

**Files:**
- Modify: `backend/agents/nodes/participant.py`

**Interfaces:**
- Consumes: `record_citation_tool` from `backend.agents.tools`
- Consumes: `url_context` from `google.adk.tools`
- Does NOT modify `make_vote` — voting uses `output_schema` and no tools.

- [ ] **Step 1: Update imports in `participant.py`**

Replace the existing import block at the top of `backend/agents/nodes/participant.py`:

```python
import json
from google.adk.agents import LlmAgent
from google.adk.agents.context import Context
from google.adk.tools import google_search, url_context
from pydantic import BaseModel
from ...models.state import FocusGroupState, AgentPersona, StreamEvent, ScoreSet
from ...agents.tools import record_citation_tool
```

- [ ] **Step 2: Update independent response node — tools list and prompt**

Replace the `agent = LlmAgent(...)` block in `make_independent_response` (lines 50-55):

```python
    agent = LlmAgent(
        name=f"participant_{persona['id']}_indep",
        model="gemini-2.5-flash",
        instruction=prompt,
        tools=[google_search, url_context, record_citation_tool],
    )
```

Replace the `prompt = f"""..."""` block in `make_independent_response` with:

```python
    prompt = f"""{_build_persona_context(persona)}

{moderator_intro}

Topic to evaluate: {topic}

Before answering:
- Use Search to find actual real-world data, news, or context about this topic.
- Follow at least one URL with url_context to read the full article, not just the snippet.
- Call record_citation for each source you use (title, url, key excerpt).

Give your honest, independent assessment. Cover:
- Your first impression (1-2 sentences)
- 2-3 specific strengths
- 2-3 specific weaknesses or risks
- Your top suggestion for improvement

Be direct and specific. Speak from your perspective as a {persona['role']}.
Do NOT hedge excessively. If you hate something, say so."""
```

- [ ] **Step 3: Update discussion response node — tools list and prompt**

Replace the `agent = LlmAgent(...)` block in `make_discussion_response` (lines 110-115):

```python
    agent = LlmAgent(
        name=f"participant_{persona['id']}_disc",
        model="gemini-2.5-flash",
        instruction=prompt,
        tools=[google_search, url_context, record_citation_tool],
    )
```

Replace the `prompt = f"""..."""` block in `make_discussion_response` with:

```python
    prompt = f"""{_build_persona_context(persona)}

Topic: {topic}

Your Round 1 assessment:
{own_response}

Other panelists' Round 1 assessments:
{other_responses}

Moderator's follow-up questions:
{moderator_followup}

Respond to the moderator's questions and engage with what the other panelists said.
- Agree where you genuinely agree, but explain why
- Push back hard where you disagree — don't just be polite
- Add new points the group missed
- If you cite a specific fact or statistic, use Search + url_context to verify it and call record_citation
- Keep it to 3-5 sentences. Be sharp."""
```

- [ ] **Step 4: Verify imports cleanly**

```bash
backend/.venv/bin/python -c "from backend.agents.nodes.participant import make_independent_response, make_discussion_response, make_vote; print('OK')"
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add backend/agents/nodes/participant.py
git commit -m "feat: add url_context and record_citation to participant nodes"
```

---

### Task 5: Wire tools and citations into synthesizer

**Files:**
- Modify: `backend/agents/nodes/synthesizer.py`

**Interfaces:**
- Consumes: `google_search`, `url_context` from `google.adk.tools`
- Consumes: `state.get("citations", [])` from workflow state
- Produces: `FinalReport["citations"]` populated from state

- [ ] **Step 1: Update imports in `synthesizer.py`**

Replace the existing import block at the top of `backend/agents/nodes/synthesizer.py`:

```python
import json
import math
from google.adk.agents import LlmAgent
from google.adk.agents.context import Context
from google.adk.tools import google_search, url_context
from pydantic import BaseModel, Field
from ...models.state import FocusGroupState, FinalReport, ScoreSet, StreamEvent
```

- [ ] **Step 2: Update synthesizer LlmAgent — add tools and update prompt**

Replace the `agent = LlmAgent(...)` block (lines 84-90):

```python
    agent = LlmAgent(
        name="synthesizer",
        model="gemini-2.5-pro",
        instruction=prompt,
        output_schema=SynthesisResult,
        tools=[google_search, url_context],
        generate_content_config={"temperature": 0.4},
    )
```

Replace the `prompt = f"""..."""` block with:

```python
    prompt = f"""You are a senior analyst synthesizing a focus group evaluation.

Topic evaluated: {topic}

Full discussion:
{discussion_text}

Scores:
{scores_summary}

Category averages: {json.dumps(averages)}
Consensus confidence: {consensus_confidence}

If any specific factual claims in the discussion are central to the recommendation,
use Search + url_context to verify them before concluding. Reference the actual
discussion points — do not be generic.

Produce a structured synthesis based on the provided discussion and scores."""
```

- [ ] **Step 3: Include citations in the final report**

In `synthesizer_node`, find the `report: FinalReport = {` block and add `citations`:

```python
    report: FinalReport = {
        "overall_score": overall_score,
        "scores_by_agent": scores,
        "category_averages": averages,
        "category_std_dev": std_devs,
        "consensus_confidence": consensus_confidence,
        "key_concerns": analysis.get("key_concerns", []),
        "key_strengths": analysis.get("key_strengths", []),
        "action_items": analysis.get("action_items", []),
        "recommendation": analysis.get("recommendation", ""),
        "sentiment": analysis.get("sentiment", "neutral"),
        "citations": state.get("citations", []),
    }
```

- [ ] **Step 4: Verify imports cleanly**

```bash
backend/.venv/bin/python -c "from backend.agents.nodes.synthesizer import synthesizer_node; print('OK')"
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add backend/agents/nodes/synthesizer.py
git commit -m "feat: add google_search and url_context to synthesizer, surface citations in report"
```

---

### Task 6: Fix Blue Team plugin — per-node tracking

**Files:**
- Modify: `backend/plugins/blue_team_plugin.py`

**Problem:** `state["agbom"]` is a single shared list. Threshold is 5 total. A normal 4-participant session generates 10+ search calls before voting. The plugin fires immediately on every run.

**Fix:** Track call counts per workflow node using `tool_context.node_path`. Flag a node only if it calls tools more than `MAX_TOOLS_PER_NODE` times (10 is generous for search + url_context + record_citation per agent turn).

**Interfaces:**
- Consumes: `tool_context.node_path` (str, e.g. `"moderator_intro"`, `"independent_p1"`)
- Produces: `state["agbom_per_node"]` — `dict[str, list[dict]]` keyed by node path

- [ ] **Step 1: Write the failing test**

```python
# backend/tests/test_plugins.py — new file
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
backend/.venv/bin/pip install pytest-asyncio -q
backend/.venv/bin/pytest backend/tests/test_plugins.py -v
```

Expected: FAIL (import error for `MAX_TOOLS_PER_NODE` and logic assertion)

- [ ] **Step 3: Rewrite `blue_team_plugin.py`**

```python
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
        self, *, tool: BaseTool, args: dict, tool_context: ToolContext, tool_response: dict
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
            "args": args,
            "status": "success" if tool_response else "unknown",
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
backend/.venv/bin/pytest backend/tests/test_plugins.py -v
```

Expected: both tests PASS

- [ ] **Step 5: Run full test suite to check for regressions**

```bash
backend/.venv/bin/pytest backend/tests/ -v
```

Expected: all tests PASS

- [ ] **Step 6: Commit**

```bash
git add backend/plugins/blue_team_plugin.py backend/tests/test_plugins.py
git commit -m "fix: track Blue Team tool calls per workflow node, raise threshold to 10"
```

---

## Self-Review

**Spec coverage:**
- `url_context` added to moderator, participants, synthesizer — covered in Tasks 3, 4, 5
- Citation tracker tool created and wired in — covered in Tasks 2, 3, 4
- `google_search` added to synthesizer — covered in Task 5
- `FinalReport` surfaces citations — covered in Tasks 1, 5
- Blue Team plugin fixed — covered in Task 6
- Voting node intentionally untouched — constraint documented

**Placeholder scan:** None present — all steps have concrete code.

**Type consistency:**
- `citations: Annotated[list[dict], operator.add]` defined in Task 1, consumed in Task 5 via `state.get("citations", [])`
- `record_citation_tool` produced in Task 2, imported in Tasks 3 and 4
- `MAX_TOOLS_PER_NODE` exported from plugin module, imported in test in Task 6
