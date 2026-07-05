<!-- generated-by: gsd-doc-writer -->
# API Reference

The Synthetic Market Intelligence Platform exposes a REST API served by FastAPI at `http://localhost:8000`. All request and response bodies use JSON. The SSE stream endpoint uses the `text/event-stream` content type.

> **Note:** This document covers the HTTP/SSE API consumed by the Flutter frontend. The same panel capabilities (persona discovery, persona-weighted scoring, and citation recording) are also published over the Model Context Protocol by a separate server — see [MCP-SERVER.md](MCP-SERVER.md) for that surface. The MCP server is not part of the HTTP API described below.

## Authentication

No authentication is required in the current implementation. The API is designed for local development use. All endpoints are open.

<!-- VERIFY: production deployments should add authentication before exposing this API externally -->

## Endpoints Overview

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/personas` | List all available personas |
| `POST` | `/sessions` | Create a new focus group session |
| `GET` | `/sessions/{session_id}` | Get current session state |
| `GET` | `/sessions/{session_id}/stream` | Subscribe to real-time SSE event stream |

---

## GET /health

Returns the service health status.

**Response**

```json
{"status": "ok"}
```

---

## GET /personas

Returns all available AI personas that can participate in a focus group session.

**Response**

A dictionary keyed by `persona_id`, where each value contains:

| Field | Type | Description |
|-------|------|-------------|
| `id` | `string` | Unique persona identifier |
| `name` | `string` | Display name |
| `role` | `string` | Role description |
| `communication_style` | `string` | How this persona communicates |

**Available persona IDs**

| ID | Name | Role |
|----|------|------|
| `skeptical_investor` | Marcus Chen | Skeptical Investor |
| `early_adopter` | Zoe Park | Enthusiastic Early Adopter |
| `enterprise_cto` | David Okafor | Enterprise CTO |
| `ux_researcher` | Priya Sharma | UX Researcher |
| `growth_marketer` | Jordan Ellis | Growth Marketer |

**Example response**

```json
{
  "skeptical_investor": {
    "id": "skeptical_investor",
    "name": "Marcus Chen",
    "role": "Skeptical Investor",
    "communication_style": "Blunt, uses precise financial language, asks hard questions"
  },
  "early_adopter": {
    "id": "early_adopter",
    "name": "Zoe Park",
    "role": "Enthusiastic Early Adopter",
    "communication_style": "Energetic, uses superlatives, speaks from personal experience"
  }
}
```

---

## POST /sessions

Creates a new focus group session and starts the multi-agent workflow in the background.

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `topic` | `string` | Yes | The idea, product, or concept to evaluate |
| `participant_ids` | `list[string]` | Yes | 1 to 5 persona IDs from `/personas` |
| `security_test_mode` | `bool` | No (default `false`) | Enables Blue Team monitoring stress test |

**Example request**

```json
{
  "topic": "An AI-powered meal planning app that adapts to dietary restrictions",
  "participant_ids": ["skeptical_investor", "early_adopter", "ux_researcher"],
  "security_test_mode": false
}
```

**Response — 200 OK**

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | `string` | UUID identifying this session |
| `topic` | `string` | The topic as submitted |
| `participant_ids` | `list[string]` | The participant IDs as submitted |

```json
{
  "session_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "topic": "An AI-powered meal planning app that adapts to dietary restrictions",
  "participant_ids": ["skeptical_investor", "early_adopter", "ux_researcher"]
}
```

**Errors**

| Status | Detail |
|--------|--------|
| `400` | `"At least one participant required"` — `participant_ids` was empty |
| `400` | `"Maximum 5 participants"` — more than 5 IDs were provided |
| `400` | `"Unknown persona: {id}. Available: [...]"` — an unrecognized persona ID was supplied |

---

## GET /sessions/{session_id}

Returns the current state of a session, including all agent responses, scores, and the final report once available.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `session_id` | `string` | UUID from `POST /sessions` |

**Response — 200 OK**

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | `string` | Session UUID |
| `topic` | `string` | The evaluated topic |
| `phase` | `string` | Current workflow phase (see below) |
| `round` | `int` | Current discussion round |
| `moderator_intro` | `string \| null` | AI moderator introduction text |
| `moderator_followup` | `string \| null` | AI moderator follow-up prompt |
| `independent_responses` | `dict[persona_id, string]` | Each persona's initial uninfluenced response |
| `discussion_responses` | `dict[persona_id, string]` | Each persona's discussion-phase response |
| `scores` | `dict[persona_id, ScoreSet]` | Scoring results per persona |
| `final_report` | `FinalReport \| null` | Synthesized final report, or `null` if not yet complete |
| `events_count` | `int` | Total number of SSE events emitted so far |
| `completed` | `bool` | Whether the workflow has finished |

**Workflow phases**

| Phase | Description |
|-------|-------------|
| `intro` | Moderator is generating the introduction |
| `independent` | Personas are providing independent responses |
| `discussion` | Personas are engaging in multi-turn discussion |
| `voting` | Personas are scoring the topic |
| `synthesis` | Synthesizer is compiling the final report |
| `complete` | Workflow finished |

**Errors**

| Status | Detail |
|--------|--------|
| `404` | `"Session not found"` |

---

## GET /sessions/{session_id}/stream

Subscribes to a Server-Sent Events (SSE) stream of real-time session events. Past events are replayed on every connect, so reconnecting is safe and idempotent.

Content-Type: `text/event-stream`

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| `session_id` | `string` | UUID from `POST /sessions` |

**Event fields**

Each SSE `data` payload is a JSON object with these fields:

| Field | Type | Description |
|-------|------|-------------|
| `type` | `string` | Event type identifier (see below) |
| `phase` | `string` | Current workflow phase at time of event |
| `content` | `string` | Human-readable content or message body |
| `agent_id` | `string \| null` | Persona ID — present on `agent_message` and `score_update` |
| `agent_name` | `string \| null` | Persona display name — present on `agent_message` and `score_update` |
| `scores` | `ScoreSet \| null` | Score breakdown — present on `score_update` |

**Event types**

| Type | Description | Notable fields |
|------|-------------|----------------|
| `phase_change` | Workflow moved to a new phase | `phase`, `content` |
| `agent_message` | A persona produced a response | `agent_id`, `agent_name`, `content` |
| `score_update` | A persona submitted scores | `agent_id`, `agent_name`, `scores` |
| `report_complete` | Final report is ready | `content` (report text) |
| `done` | Session is complete — stream ends after this event | `phase: "complete"` |
| `error` | Workflow error occurred | `content` (error message) |

**Example events**

```
data: {"type": "phase_change", "phase": "intro", "content": "Starting focus group...", "agent_id": null, "agent_name": null, "scores": null}

data: {"type": "agent_message", "phase": "independent", "content": "This concept has serious monetization gaps...", "agent_id": "skeptical_investor", "agent_name": "Marcus Chen", "scores": null}

data: {"type": "score_update", "phase": "voting", "content": "", "agent_id": "early_adopter", "agent_name": "Zoe Park", "scores": {"innovation": 9.0, "market": 8.5, "ux": 8.0, "feasibility": 7.0, "monetization": 6.5, "risk": 7.5}}

data: {"type": "done", "phase": "complete", "content": "Session complete"}
```

**Errors**

| Status | Detail |
|--------|--------|
| `404` | `"Session not found"` |

---

## Data Types

### ScoreSet

Scoring dimensions used by every persona when evaluating the topic. All values are floats in the range 0–10.

| Field | Type | Description |
|-------|------|-------------|
| `innovation` | `float` | Novelty and creativity of the concept |
| `market` | `float` | Market size and demand potential |
| `ux` | `float` | User experience and usability |
| `feasibility` | `float` | Technical and operational feasibility |
| `monetization` | `float` | Revenue model strength |
| `risk` | `float` | Risk level (higher = riskier) |

### FinalReport

Returned in `GET /sessions/{session_id}` as `final_report` once the synthesis phase completes.

| Field | Type | Description |
|-------|------|-------------|
| `overall_score` | `float` | Weighted composite score across all personas |
| `scores_by_agent` | `dict[persona_id, ScoreSet]` | Full score breakdown per persona |
| `category_averages` | `ScoreSet` | Mean score per scoring dimension |
| `category_std_dev` | `ScoreSet` | Standard deviation per scoring dimension (measures consensus) |
| `consensus_confidence` | `float` | Aggregate confidence in the panel's agreement |
| `key_concerns` | `list[string]` | Top concerns raised across personas |
| `key_strengths` | `list[string]` | Top strengths identified across personas |
| `action_items` | `list[string]` | Recommended next steps |
| `recommendation` | `string` | Synthesizer's overall recommendation |
| `sentiment` | `string` | Overall sentiment label (e.g., `"positive"`, `"mixed"`, `"negative"`) |
| `citations` | `list[dict]` | Source citations referenced by the synthesizer |

---

## CORS

The API allows cross-origin requests from the following origins:

- `http://localhost:8080` and `http://127.0.0.1:8080` — Flutter web frontend (`flutter run --web-port=8080`)
- `http://localhost:3000` and `http://127.0.0.1:3000` — legacy Next.js frontend

All HTTP methods and headers are permitted. Credentials are allowed.

## Rate Limits

No rate limiting is configured in the current implementation.

<!-- VERIFY: production deployments should add rate limiting before public exposure -->
