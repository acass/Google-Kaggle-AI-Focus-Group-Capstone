import json
import math
from google.adk.agents import LlmAgent
from google.adk.agents.context import Context
from google.adk.tools import google_search, url_context
from pydantic import BaseModel, Field
from ...models.state import FocusGroupState, FinalReport, ScoreSet, StreamEvent

CATEGORIES = ["innovation", "market", "ux", "feasibility", "monetization", "risk"]

class SynthesisResult(BaseModel):
    key_concerns: list[str] = Field(description="3-5 specific concerns raised by multiple panelists")
    key_strengths: list[str] = Field(description="3-5 genuine strengths identified")
    action_items: list[str] = Field(description="3-5 concrete next steps")
    recommendation: str = Field(description="2-3 sentence overall recommendation")
    sentiment: str = Field(description="'positive', 'neutral', 'skeptical', or 'negative'")


def _compute_stats(scores: dict[str, ScoreSet]) -> tuple[ScoreSet, ScoreSet, float]:
    if not scores:
        empty: ScoreSet = {c: 0.0 for c in CATEGORIES}
        return empty, empty, 0.0

    averages: ScoreSet = {}
    std_devs: ScoreSet = {}

    for cat in CATEGORIES:
        vals = [s[cat] for s in scores.values()]
        mean = sum(vals) / len(vals)
        variance = sum((v - mean) ** 2 for v in vals) / len(vals)
        averages[cat] = round(mean, 2)
        std_devs[cat] = round(math.sqrt(variance), 2)

    overall = sum(averages[c] for c in CATEGORIES) / len(CATEGORIES)
    avg_std = sum(std_devs[c] for c in CATEGORIES) / len(CATEGORIES)
    consensus = max(0.0, round(1.0 - (avg_std / 5.0), 2))

    return averages, std_devs, consensus


async def synthesizer_node(ctx: Context, state: FocusGroupState) -> dict:
    topic = state["topic"]
    participants = state["participants"]
    independent_responses = state.get("independent_responses", {})
    discussion_responses = state.get("discussion_responses", {})
    scores = state.get("scores", {})

    averages, std_devs, consensus_confidence = _compute_stats(scores)
    overall_score = round(sum(averages[c] for c in CATEGORIES) / len(CATEGORIES), 2)

    all_responses = []
    for p in participants:
        pid = p["id"]
        r1 = independent_responses.get(pid, "")
        r2 = discussion_responses.get(pid, "")
        if r1 or r2:
            all_responses.append(
                f"{p['name']} ({p['role']}):\nRound 1: {r1}\nRound 2: {r2}"
            )

    discussion_text = "\n\n---\n\n".join(all_responses)

    scores_summary = "\n".join(
        f"{next((p['name'] for p in participants if p['id'] == aid), aid)}: "
        + ", ".join(f"{c}={s[c]}" for c in CATEGORIES)
        for aid, s in scores.items()
    )

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

    agent = LlmAgent(
        name="synthesizer",
        model="gemini-2.5-pro",
        instruction=prompt,
        output_schema=SynthesisResult,
        tools=[google_search, url_context],
        generate_content_config={"temperature": 0.4},
    )

    analysis_data = await ctx.run_node(agent, node_input="")
    
    if isinstance(analysis_data, dict):
        analysis = analysis_data
    else:
        analysis = {
            "key_concerns": analysis_data.key_concerns,
            "key_strengths": analysis_data.key_strengths,
            "action_items": analysis_data.action_items,
            "recommendation": analysis_data.recommendation,
            "sentiment": analysis_data.sentiment,
        }

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

    event: StreamEvent = {
        "type": "report_complete",
        "agent_id": "synthesizer",
        "agent_name": "Synthesizer",
        "phase": "synthesis",
        "content": report["recommendation"],
        "scores": averages,
    }

    return {
        "final_report": report,
        "phase": "synthesis",
        "stream_events": [event],
    }
