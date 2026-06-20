import asyncio
import json
from fastapi import APIRouter, HTTPException
from sse_starlette.sse import EventSourceResponse
from .sessions import _sessions, _session_complete

router = APIRouter(prefix="/sessions", tags=["stream"])

# Per-session event queues for SSE delivery
_event_queues: dict[str, asyncio.Queue] = {}


def get_or_create_queue(session_id: str) -> asyncio.Queue:
    if session_id not in _event_queues:
        _event_queues[session_id] = asyncio.Queue()
    return _event_queues[session_id]


async def push_event(session_id: str, event: dict):
    q = get_or_create_queue(session_id)
    await q.put(event)


async def _event_generator(session_id: str):
    q = get_or_create_queue(session_id)

    # Replay any events already stored (handles reconnect or late-join)
    state = _sessions.get(session_id, {})
    past_events = state.get("stream_events", [])
    for evt in past_events:
        yield {"data": json.dumps(evt)}

    already_sent = len(past_events)

    while True:
        # Check for new events in state (polled from background task updates)
        current_state = _sessions.get(session_id, {})
        current_events = current_state.get("stream_events", [])

        if len(current_events) > already_sent:
            for evt in current_events[already_sent:]:
                yield {"data": json.dumps(evt)}
            already_sent = len(current_events)

        if _session_complete.get(session_id, False) and already_sent >= len(current_events):
            yield {"data": json.dumps({"type": "done", "phase": "complete", "content": "Session complete"})}
            break

        await asyncio.sleep(0.5)


@router.get("/{session_id}/stream")
async def stream_session(session_id: str):
    if session_id not in _sessions:
        raise HTTPException(status_code=404, detail="Session not found")

    return EventSourceResponse(_event_generator(session_id))
