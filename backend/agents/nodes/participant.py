import json
from google import genai
from google.genai import types
from pydantic import BaseModel
from ...models.state import FocusGroupState, AgentPersona, StreamEvent, ScoreSet

client = genai.Client()

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


async def make_independent_response(state: FocusGroupState, persona: AgentPersona) -> dict:
    topic = state["topic"]
    moderator_intro = state.get("moderator_intro", "")

    prompt = f"""{_build_persona_context(persona)}

{moderator_intro}

Topic to evaluate: {topic}

Give your honest, independent assessment. Cover:
- Your first impression (1-2 sentences)
- 2-3 specific strengths
- 2-3 specific weaknesses or risks
- Your top suggestion for improvement

Be direct and specific. Speak from your perspective as a {persona['role']}.
Do NOT hedge excessively. If you hate something, say so."""

    response = await client.aio.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
    )
    content = response.text

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


async def make_discussion_response(state: FocusGroupState, persona: AgentPersona) -> dict:
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
- Keep it to 3-5 sentences. Be sharp."""

    response = await client.aio.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
    )
    content = response.text

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


async def make_vote(state: FocusGroupState, persona: AgentPersona) -> dict:
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

    response = await client.aio.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=VoteScores,
        ),
    )
    
    try:
        score_data = json.loads(response.text)
        scores: ScoreSet = {
            "innovation": float(score_data.get("innovation", 5)),
            "market": float(score_data.get("market", 5)),
            "ux": float(score_data.get("ux", 5)),
            "feasibility": float(score_data.get("feasibility", 5)),
            "monetization": float(score_data.get("monetization", 5)),
            "risk": float(score_data.get("risk", 5)),
        }
    except (json.JSONDecodeError, KeyError):
        scores = {
            "innovation": 5.0,
            "market": 5.0,
            "ux": 5.0,
            "feasibility": 5.0,
            "monetization": 5.0,
            "risk": 5.0,
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
