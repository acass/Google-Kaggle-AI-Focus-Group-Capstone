# BDD Specification System Design

**Date:** 2026-06-22
**Project:** Synthetic Market Intelligence Platform (AI Focus Group)
**Status:** Approved

---

## Overview

A documentation-only BDD specification system stored in `specs/` at the repo root. The folder acts as the authoritative behavioral source of truth for the platform, organized by domain. Specs are written in Gherkin (`.feature`) and YAML (`.schema.yaml`, `.contract.yaml`) and are never executed by a test runner — they exist to give AI agents precise, unambiguous instructions and to eliminate vague implementation decisions.

The core principle: code must conform to specs, not the other way around. An AI agent assigned to any domain reads that domain's `specs/` folder first, before touching any code.

---

## Folder Structure

```
specs/
  README.md
  session/
    session-lifecycle.feature
    session-state.schema.yaml
    session-api.contract.yaml
  agents/
    persona-behavior.feature
    personas.schema.yaml
  stream/
    sse-streaming.feature
    stream-event.schema.yaml
  security/
    plugin-behavior.feature
    trust-score.schema.yaml
  workflow/
    graph-topology.schema.yaml
```

Each domain folder is self-contained. No cross-folder imports or references between spec files. A file in `session/` does not reference a file in `stream/`.

---

## File Naming Conventions

| Extension | Artifact type | When to use |
|-----------|---------------|-------------|
| `.feature` | Gherkin BDD scenarios | Behavioral requirements: what the system does from a user or agent perspective |
| `.schema.yaml` | Structural data contract | Shape of internal data objects: field names, types, nullability, merge semantics |
| `.contract.yaml` | HTTP API contract | Request/response shape, required fields, status codes, enums |

---

## Content Conventions

### `.feature` files

Every `.feature` file opens with a comment header block that declares:
- `domain:` — which `specs/` subfolder this belongs to
- `maps-to:` — the backend or frontend files this spec governs
- `constraint:` — any hard invariants an implementer must not break

The Gherkin structure is strict: **Given** = system state preconditions, **When** = the single triggering action, **Then** = the observable outcome. No implementation detail in any clause. Scenarios describe behavior from the outside, not internal mechanics.

Example shape:

```gherkin
# domain: session
# maps-to: backend/api/sessions.py, backend/models/state.py
# constraint: session IDs are UUIDs; state is in-memory only

Feature: Session Lifecycle
  A client submits a topic and participant list.
  The platform runs the full ADK workflow and produces a final report.

  Scenario: Successful session creation
    Given a valid topic string and at least one participant ID
    When the client POSTs to /sessions
    Then the response contains a session_id and status "pending"
    And a background workflow task is started

  Scenario: Session completes with a final report
    Given a session is running with valid participants
    When the ADK workflow reaches the Synthesizer node
    Then the session status transitions to "completed"
    And a FinalReport is written into session state
```

### `.schema.yaml` files

Describe the shape of a data object. Fields include type, nullability, default values, and merge semantics for fields that are written by parallel ADK nodes (fan-in merge rules).

```yaml
# domain: session
# maps-to: backend/models/state.py::FocusGroupState
schema: FocusGroupState
fields:
  session_id:
    type: str
    nullable: false
  topic:
    type: str
    nullable: false
  status:
    type: str
    nullable: false
    enum: [pending, running, completed, error]
  citations:
    type: list[dict]
    nullable: false
    merge: append
  scores:
    type: dict
    nullable: false
    merge: shallow-merge
  quarantine_flag:
    type: bool
    nullable: false
    default: false
  stream_events:
    type: list[dict]
    nullable: false
    merge: append
```

### `.contract.yaml` files

Describe HTTP API endpoints. Each file covers one endpoint. Fields include method, path, request body fields (with type, required, constraints), response body by status code, and error codes.

```yaml
# domain: session
# maps-to: backend/api/sessions.py
endpoint: POST /sessions
request:
  topic:
    type: str
    required: true
  participant_ids:
    type: list[str]
    required: true
    min_items: 1
    max_items: 5
  security_test_mode:
    type: bool
    required: false
    default: false
response:
  201:
    session_id:
      type: str
      format: uuid
    status:
      type: str
      enum: [pending]
  422: validation error — malformed request body
```

---

## README Agent Consumption Rules

The `specs/README.md` defines four hard rules for any AI agent consuming specs:

1. Read the domain folder for your assigned domain before writing or modifying any code.
2. If a spec conflicts with existing code, the spec wins — flag the discrepancy and fix the code.
3. Do not modify a spec to match existing code; modify the spec only if the requirement has genuinely changed, and document why.
4. When adding a new feature, write or update the relevant spec first, then implement.

---

## Domains and Coverage

### `session/` — Session Lifecycle
- Covers: session creation, background workflow execution, status transitions (pending → running → completed → error), final report population
- Maps to: `backend/api/sessions.py`, `backend/models/state.py`, `backend/models/schemas.py`

### `agents/` — Persona Behavior
- Covers: all 5 persona definitions as machine-readable YAML, the three agent phases (independent evaluation, discussion, voting), scoring dimension weights
- Maps to: `backend/agents/personas.py`, `backend/agents/nodes/participant.py`

### `stream/` — SSE Streaming
- Covers: SSE connection lifecycle, event sequence, event type contracts (phase_change, agent_message, score_update, done, error), nullable field rules, no-manual-reconnect constraint
- Maps to: `backend/api/stream.py`, `flutter_app/lib/data/sse_client.dart`, `flutter_app/lib/models/`

### `security/` — Plugin Behavior
- Covers: Blue Team tool-call counting per node, trust score deduction rules, threshold, Green Team quarantine gate, `security_test_mode` flag
- Maps to: `backend/plugins/blue_team_plugin.py`, `backend/plugins/green_team_plugin.py`

### `workflow/` — ADK Graph Topology
- Covers: node names, node types (participant, moderator, synthesizer, join), phase groupings, fan-out edges, fan-in edges, `rerun_on_resume` constraint
- Maps to: `backend/agents/graph.py`

---

## What This System Does Not Cover

- Frontend widget layout or UI behavior — specs govern system behavior, not visual design
- Export format internals (PDF/DOCX byte structure) — too implementation-specific to be useful as a behavioral spec
- Test step definitions — specs are documentation-only; no `behave` runner, no step files
- Deployment or environment configuration

---

## Implementation Artifacts

The implementation produces these files:

| File | Description |
|------|-------------|
| `specs/README.md` | Entry point and agent consumption rules |
| `specs/session/session-lifecycle.feature` | Session state machine in Gherkin |
| `specs/session/session-state.schema.yaml` | FocusGroupState schema |
| `specs/session/session-api.contract.yaml` | POST /sessions + GET /sessions/{id} |
| `specs/agents/persona-behavior.feature` | Agent phase behavior (eval, discuss, vote) |
| `specs/agents/personas.schema.yaml` | All 5 persona definitions |
| `specs/stream/sse-streaming.feature` | SSE connection and event sequence |
| `specs/stream/stream-event.schema.yaml` | StreamEvent schema with nullable rules |
| `specs/security/plugin-behavior.feature` | Blue/Green plugin behavior |
| `specs/security/trust-score.schema.yaml` | Trust score fields and thresholds |
| `specs/workflow/graph-topology.schema.yaml` | ADK graph node and edge definitions |
