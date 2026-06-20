from typing import Optional, TypedDict, Annotated
import operator


class ScoringWeights(TypedDict):
    innovation: float
    market: float
    ux: float
    feasibility: float
    monetization: float
    risk: float


class AgentPersona(TypedDict):
    id: str
    name: str
    role: str
    personality: list[str]
    expertise: list[str]
    biases: list[str]
    hidden_motivation: str
    temperature: float
    communication_style: str
    scoring_weights: ScoringWeights


class ScoreSet(TypedDict):
    innovation: float
    market: float
    ux: float
    feasibility: float
    monetization: float
    risk: float


class FinalReport(TypedDict):
    overall_score: float
    scores_by_agent: dict[str, ScoreSet]
    category_averages: ScoreSet
    category_std_dev: ScoreSet
    consensus_confidence: float
    key_concerns: list[str]
    key_strengths: list[str]
    action_items: list[str]
    recommendation: str
    sentiment: str


class StreamEvent(TypedDict):
    type: str          # phase_change | agent_message | score_update | report_complete
    agent_id: Optional[str]
    agent_name: Optional[str]
    phase: str
    content: str
    scores: Optional[ScoreSet]


class FocusGroupState(TypedDict):
    session_id: str
    topic: str
    participants: list[AgentPersona]
    phase: str
    round: int
    moderator_intro: str
    moderator_followup: str
    independent_responses: Annotated[dict[str, str], operator.or_]
    discussion_responses: Annotated[dict[str, str], operator.or_]
    scores: Annotated[dict[str, ScoreSet], operator.or_]
    final_report: Optional[FinalReport]
    stream_events: Annotated[list[StreamEvent], operator.add]
