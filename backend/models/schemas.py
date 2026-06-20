from pydantic import BaseModel
from typing import Optional
from .state import FinalReport, ScoreSet, StreamEvent


class CreateSessionRequest(BaseModel):
    topic: str
    participant_ids: list[str]


class CreateSessionResponse(BaseModel):
    session_id: str
    topic: str
    participant_ids: list[str]


class SessionStateResponse(BaseModel):
    session_id: str
    topic: str
    phase: str
    round: int
    moderator_intro: Optional[str] = None
    moderator_followup: Optional[str] = None
    independent_responses: dict[str, str] = {}
    discussion_responses: dict[str, str] = {}
    scores: dict[str, ScoreSet] = {}
    final_report: Optional[FinalReport] = None
    events_count: int = 0
    completed: bool = False
