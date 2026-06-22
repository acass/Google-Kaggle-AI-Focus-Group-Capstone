import pytest
from backend.agents.personas import get_persona, get_all_persona_ids, PERSONAS


def test_all_persona_ids_returns_five():
    ids = get_all_persona_ids()
    assert len(ids) == 5


def test_all_expected_personas_present():
    ids = set(get_all_persona_ids())
    assert ids == {"skeptical_investor", "early_adopter", "enterprise_cto", "ux_researcher", "growth_marketer"}


def test_get_persona_returns_correct_persona():
    persona = get_persona("skeptical_investor")
    assert persona["id"] == "skeptical_investor"
    assert persona["name"] == "Marcus Chen"
    assert persona["role"] == "Skeptical Investor"


def test_get_persona_unknown_raises_value_error():
    with pytest.raises(ValueError, match="Unknown persona"):
        get_persona("nonexistent_persona")


def test_all_personas_have_required_fields():
    required = [
        "id", "name", "role", "personality", "expertise", "biases",
        "hidden_motivation", "temperature", "communication_style", "scoring_weights",
    ]
    for pid, persona in PERSONAS.items():
        for field in required:
            assert field in persona, f"{pid} missing field '{field}'"


def test_scoring_weights_have_six_categories():
    categories = {"innovation", "market", "ux", "feasibility", "monetization", "risk"}
    for pid, persona in PERSONAS.items():
        assert set(persona["scoring_weights"].keys()) == categories, f"{pid} has wrong scoring_weight keys"


def test_temperature_is_in_valid_range():
    for pid, persona in PERSONAS.items():
        t = persona["temperature"]
        assert 0.0 <= t <= 1.0, f"{pid} temperature {t} is out of [0, 1]"
