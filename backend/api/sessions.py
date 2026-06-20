import asyncio
import uuid
from fastapi import APIRouter, BackgroundTasks, HTTPException
from ..models.schemas import CreateSessionRequest, CreateSessionResponse, SessionStateResponse
from ..models.state import FocusGroupState
from ..agents.personas import get_persona
from ..agents.graph import build_graph
from google.adk.apps import App
from google.adk.runners import InMemoryRunner
from google.genai import types

router = APIRouter(prefix="/sessions", tags=["sessions"])

# In-memory session store: session_id -> state dict
_sessions: dict[str, dict] = {}
_session_complete: dict[str, bool] = {}


def get_session_store() -> dict[str, dict]:
    return _sessions


async def _run_session(session_id: str, initial_state: FocusGroupState):
    participants = initial_state["participants"]
    workflow = build_graph(participants)
    
    app = App(name=f"focus_group_{session_id}", root_agent=workflow)
    runner = InMemoryRunner(app=app)
    
    session = await runner.session_service.create_session(
        app_name=app.name, user_id="system", session_id=session_id, state=dict(initial_state)
    )

    # Stream state updates so the SSE endpoint sees incremental progress
    async for event in runner.run_async(
        user_id="system",
        session_id=session_id,
        new_message=types.Content(role="user", parts=[types.Part.from_text(text="start")]),
    ):
        if event.output:
            node_output = event.output
            if isinstance(node_output, dict):
                current = _sessions[session_id]
                # Merge stream_events (append)
                if "stream_events" in node_output:
                    existing = current.get("stream_events", [])
                    current["stream_events"] = existing + node_output["stream_events"]
                    node_output_copy = {k: v for k, v in node_output.items() if k != "stream_events"}
                else:
                    node_output_copy = node_output.copy()
                # Merge dict fields (independent_responses, discussion_responses, scores)
                for key in ("independent_responses", "discussion_responses", "scores"):
                    if key in node_output_copy:
                        merged = {**current.get(key, {}), **node_output_copy[key]}
                        current[key] = merged
                        del node_output_copy[key]
                current.update(node_output_copy)
    _session_complete[session_id] = True


@router.post("", response_model=CreateSessionResponse)
async def create_session(
    body: CreateSessionRequest,
    background_tasks: BackgroundTasks,
):
    if not body.participant_ids:
        raise HTTPException(status_code=400, detail="At least one participant required")
    if len(body.participant_ids) > 5:
        raise HTTPException(status_code=400, detail="Maximum 5 participants")

    participants = []
    for pid in body.participant_ids:
        try:
            participants.append(get_persona(pid))
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    session_id = str(uuid.uuid4())
    initial_state: FocusGroupState = {
        "session_id": session_id,
        "topic": body.topic,
        "participants": participants,
        "phase": "intro",
        "round": 1,
        "moderator_intro": "",
        "moderator_followup": "",
        "independent_responses": {},
        "discussion_responses": {},
        "scores": {},
        "final_report": None,
        "stream_events": [],
    }

    _sessions[session_id] = dict(initial_state)
    _session_complete[session_id] = False

    background_tasks.add_task(_run_session, session_id, initial_state)

    return CreateSessionResponse(
        session_id=session_id,
        topic=body.topic,
        participant_ids=body.participant_ids,
    )


@router.get("/{session_id}", response_model=SessionStateResponse)
async def get_session(session_id: str):
    if session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")

    state = _sessions[session_id]
    return SessionStateResponse(
        session_id=session_id,
        topic=state.get("topic", ""),
        phase=state.get("phase", "intro"),
        round=state.get("round", 1),
        moderator_intro=state.get("moderator_intro"),
        moderator_followup=state.get("moderator_followup"),
        independent_responses=state.get("independent_responses", {}),
        discussion_responses=state.get("discussion_responses", {}),
        scores=state.get("scores", {}),
        final_report=state.get("final_report"),
        events_count=len(state.get("stream_events", [])),
        completed=_session_complete.get(session_id, False),
    )
