import json
from google.adk.agents import LlmAgent
from google.adk.agents.context import Context
from google.adk.tools import google_search, url_context
from pydantic import BaseModel
from ...models.state import FocusGroupState, AgentPersona, StreamEvent, ScoreSet
from ...agents.tools import record_citation_tool

SCORE_CATEGORIES = ["innovation", "market", "ux", "feasibility", "monetization", "risk"]

class VoteScores(BaseModel):
    innovation: float
    market: float
    ux: float
    feasibility: float
    monetization: float
    risk: float

def _build_persona_context(persona: AgentPersona) -> str:
    return f"""You are {persona['name']}, a {persona['role']} in a focus group.

Your personality: {', '.join(persona['personality'])}
Your expertise: {', '.join(persona['expertise'])}
Your known biases: {', '.join(persona['biases'])}
Your communication style: {persona['communication_style']}

Stay in character. Disagree when your worldview differs from others. Be direct."""


async def make_independent_response(ctx: Context, state: FocusGroupState, persona: AgentPersona) -> dict:
    topic = state["topic"]
    moderator_intro = state.get("moderator_intro", "")

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

    agent = LlmAgent(
        name=f"participant_{persona['id']}_indep",
        model="gemini-2.5-flash",
        instruction=prompt,
        tools=[google_search, url_context, record_citation_tool],
    )
    
    # Run the agent inside the workflow context
    result = await ctx.run_node(agent, node_input="")
    content = result.text if hasattr(result, "text") else str(result)

    event: StreamEvent = {
        "type": "agent_message",
        "agent_id": persona["id"],
        "agent_name": f"{persona['name']} ({persona['role']})",
        "phase": "independent",
        "content": content,
        "scores": None,
    }

    return {
        "independent_responses": {persona["id"]: content},
        "stream_events": [event],
    }


async def make_discussion_response(ctx: Context, state: FocusGroupState, persona: AgentPersona) -> dict:
    topic = state["topic"]
    moderator_followup = state.get("moderator_followup", "")
    independent_responses = state.get("independent_responses", {})
    participants = state["participants"]

    other_responses = "\n\n".join(
        f"**{next((p['name'] for p in participants if p['id'] == aid), aid)} "
        f"({next((p['role'] for p in participants if p['id'] == aid), '')}):**\n{resp}"
        for aid, resp in independent_responses.items()
        if aid != persona["id"]
    )

    own_response = independent_responses.get(persona["id"], "")

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

    agent = LlmAgent(
        name=f"participant_{persona['id']}_disc",
        model="gemini-2.5-flash",
        instruction=prompt,
        tools=[google_search, url_context, record_citation_tool],
    )

    result = await ctx.run_node(agent, node_input="")
    content = result.text if hasattr(result, "text") else str(result)

    event: StreamEvent = {
        "type": "agent_message",
        "agent_id": persona["id"],
        "agent_name": f"{persona['name']} ({persona['role']})",
        "phase": "discussion",
        "content": content,
        "scores": None,
    }

    return {
        "discussion_responses": {persona["id"]: content},
        "stream_events": [event],
    }


async def make_vote(ctx: Context, state: FocusGroupState, persona: AgentPersona) -> dict:
    topic = state["topic"]
    own_response = state.get("independent_responses", {}).get(persona["id"], "")
    discussion_response = state.get("discussion_responses", {}).get(persona["id"], "")

    scoring_weights = persona["scoring_weights"]
    weights_desc = ", ".join(f"{k} (weight: {v})" for k, v in scoring_weights.items())

    prompt = f"""{_build_persona_context(persona)}

Topic: {topic}

Your assessments:
Round 1: {own_response}
Round 2: {discussion_response}

Score this topic 0-10 for each category. Your scoring priorities: {weights_desc}

For "risk", 0 = extremely risky, 10 = very safe/low risk."""

    agent = LlmAgent(
        name=f"participant_{persona['id']}_vote",
        model="gemini-2.5-flash",
        instruction=prompt,
        output_schema=VoteScores,
    )

    score_data = await ctx.run_node(agent, node_input="")
    
    if isinstance(score_data, dict):
        scores: ScoreSet = {
            "innovation": float(score_data.get("innovation", 5)),
            "market": float(score_data.get("market", 5)),
            "ux": float(score_data.get("ux", 5)),
            "feasibility": float(score_data.get("feasibility", 5)),
            "monetization": float(score_data.get("monetization", 5)),
            "risk": float(score_data.get("risk", 5)),
        }
    else:
        scores: ScoreSet = {
            "innovation": float(score_data.innovation),
            "market": float(score_data.market),
            "ux": float(score_data.ux),
            "feasibility": float(score_data.feasibility),
            "monetization": float(score_data.monetization),
            "risk": float(score_data.risk),
        }

    event: StreamEvent = {
        "type": "score_update",
        "agent_id": persona["id"],
        "agent_name": f"{persona['name']} ({persona['role']})",
        "phase": "voting",
        "content": f"Scored: innovation={scores['innovation']}, market={scores['market']}, ux={scores['ux']}, feasibility={scores['feasibility']}, monetization={scores['monetization']}, risk={scores['risk']}",
        "scores": scores,
    }

    return {
        "scores": {persona["id"]: scores},
        "phase": "voting",
        "stream_events": [event],
    }
