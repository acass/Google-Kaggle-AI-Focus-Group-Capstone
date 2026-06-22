from unittest.mock import patch, AsyncMock


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_list_personas(client):
    resp = client.get("/personas")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 5
    assert "skeptical_investor" in data
    p = data["skeptical_investor"]
    assert p["name"] == "Marcus Chen"
    assert p["role"] == "Skeptical Investor"
    # Only the summary fields should be returned, not internal details
    assert "hidden_motivation" not in p


def test_create_session_empty_participants_returns_400(client):
    resp = client.post("/sessions", json={"topic": "Test", "participant_ids": []})
    assert resp.status_code == 400
    assert "participant" in resp.json()["detail"].lower()


def test_create_session_too_many_participants_returns_400(client):
    resp = client.post("/sessions", json={
        "topic": "Test",
        "participant_ids": [
            "skeptical_investor", "early_adopter", "enterprise_cto",
            "ux_researcher", "growth_marketer", "skeptical_investor",
        ],
    })
    assert resp.status_code == 400


def test_create_session_unknown_persona_returns_400(client):
    resp = client.post("/sessions", json={"topic": "Test", "participant_ids": ["ghost"]})
    assert resp.status_code == 400
    assert "ghost" in resp.json()["detail"]


def test_create_session_success(client):
    with patch("backend.api.sessions._run_session", new_callable=AsyncMock):
        resp = client.post("/sessions", json={
            "topic": "AI Focus Group Test",
            "participant_ids": ["skeptical_investor"],
        })
    assert resp.status_code == 200
    data = resp.json()
    assert "session_id" in data
    assert data["topic"] == "AI Focus Group Test"
    assert data["participant_ids"] == ["skeptical_investor"]


def test_get_session_not_found_returns_404(client):
    resp = client.get("/sessions/00000000-0000-0000-0000-000000000000")
    assert resp.status_code == 404


def test_get_session_returns_initial_state(client):
    with patch("backend.api.sessions._run_session", new_callable=AsyncMock):
        create = client.post("/sessions", json={
            "topic": "Retrieval test",
            "participant_ids": ["early_adopter", "ux_researcher"],
        })
    session_id = create.json()["session_id"]

    get = client.get(f"/sessions/{session_id}")
    assert get.status_code == 200
    data = get.json()
    assert data["session_id"] == session_id
    assert data["topic"] == "Retrieval test"
    assert data["phase"] == "intro"
    assert data["round"] == 1
    assert data["independent_responses"] == {}
    assert data["scores"] == {}
