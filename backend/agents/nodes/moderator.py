from google import genai
from google.genai import types
from ...models.state import FocusGroupState, StreamEvent

client = genai.Client()

async def moderator_introduce_node(state: FocusGroupState) -> dict:
    topic = state["topic"]
    participants = state["participants"]
    panel = ", ".join(f"{p['name']} ({p['role']})" for p in participants)

    prompt = f"""You are a neutral, analytical focus group moderator running a synthetic research panel.

Topic being evaluated: {topic}

Panel participants: {panel}

Write a brief, focused introduction (3-5 sentences) that:
1. States the topic clearly
2. Sets the expectation that each panelist will give their honest, independent assessment
3. Asks them to identify strengths, weaknesses, risks, and specific suggestions

Before writing your introduction, use your Search tool to fetch 1-2 real-world facts or recent news context about this topic and include them to ground the discussion.

Be concise and professional. Do not be overly formal."""

    response = await client.aio.models.generate_content(
        model="gemini-2.5-pro",
        contents=prompt,
        config=types.GenerateContentConfig(
            tools=[{"google_search": {}}],
        )
    )
    intro = response.text

    event: StreamEvent = {
        "type": "agent_message",
        "agent_id": "moderator",
        "agent_name": "Moderator",
        "phase": "intro",
        "content": intro,
        "scores": None,
    }

    return {
        "moderator_intro": intro,
        "phase": "independent",
        "stream_events": [event],
    }


async def moderator_followup_node(state: FocusGroupState) -> dict:
    topic = state["topic"]
    independent_responses = state["independent_responses"]
    participants = state["participants"]

    responses_text = "\n\n".join(
        f"**{next(p['name'] for p in participants if p['id'] == agent_id)} ({next(p['role'] for p in participants if p['id'] == agent_id)}):**\n{response}"
        for agent_id, response in independent_responses.items()
    )

    prompt = f"""You are a neutral focus group moderator. The panel has just completed their independent evaluations.

Topic: {topic}

Independent responses:
{responses_text}

Write 2-3 targeted follow-up questions that:
1. Address the most significant disagreements between panelists
2. Probe the most critical unresolved risk or concern
3. Ask panelists to respond to each other's strongest point

Be specific — reference what was actually said. Keep the total to 2-3 focused questions."""

    response = await client.aio.models.generate_content(
        model="gemini-2.5-pro",
        contents=prompt,
    )
    followup = response.text

    event: StreamEvent = {
        "type": "phase_change",
        "agent_id": "moderator",
        "agent_name": "Moderator",
        "phase": "discussion",
        "content": followup,
        "scores": None,
    }

    return {
        "moderator_followup": followup,
        "phase": "discussion",
        "round": 2,
        "stream_events": [event],
    }
