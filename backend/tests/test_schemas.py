import pytest
from pydantic import ValidationError
from backend.models.schemas import CreateSessionRequest, CreateSessionResponse, SessionStateResponse


def test_create_session_request_valid():
    req = CreateSessionRequest(topic="My App", participant_ids=["skeptical_investor"])
    assert req.topic == "My App"
    assert req.participant_ids == ["skeptical_investor"]
    assert req.security_test_mode is False


def test_create_session_request_security_test_mode_defaults_false():
    req = CreateSessionRequest(topic="t", participant_ids=["early_adopter"])
    assert req.security_test_mode is False


def test_create_session_request_security_test_mode_explicit():
    req = CreateSessionRequest(topic="t", participant_ids=["early_adopter"], security_test_mode=True)
    assert req.security_test_mode is True


def test_create_session_request_missing_topic_raises():
    with pytest.raises(ValidationError):
        CreateSessionRequest(participant_ids=["skeptical_investor"])


def test_create_session_response_fields():
    resp = CreateSessionResponse(
        session_id="abc-123",
        topic="Test Topic",
        participant_ids=["skeptical_investor"],
    )
    assert resp.session_id == "abc-123"
    assert resp.topic == "Test Topic"


def test_session_state_response_defaults():
    resp = SessionStateResponse(
        session_id="s1",
        topic="T",
        phase="intro",
        round=1,
    )
    assert resp.independent_responses == {}
    assert resp.discussion_responses == {}
    assert resp.scores == {}
    assert resp.completed is False
    assert resp.final_report is None
    assert resp.moderator_intro is None


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
