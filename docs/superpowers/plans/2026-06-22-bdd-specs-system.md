# BDD Specification System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Populate the `specs/` directory with a README, domain folders, and representative BDD `.feature`, `.schema.yaml`, and `.contract.yaml` files that serve as the authoritative behavioral source of truth for AI agents working in this codebase.

**Architecture:** Five domain folders (`session/`, `agents/`, `stream/`, `security/`, `workflow/`) each contain self-contained spec artifacts. No code is executed; all files are documentation-only. A root `README.md` defines conventions and agent consumption rules. Content is derived directly from the live source files — no invented values.

**Tech Stack:** Plain text, Gherkin (`.feature`), YAML (`.schema.yaml`, `.contract.yaml`). No dependencies. No test runner.

## Global Constraints

- All spec content must reflect actual behavior in the current codebase — never invent field names, type names, or thresholds.
- `specs/` lives at the repo root (already exists as an empty directory).
- `.feature` files use Gherkin syntax: `Feature:`, `Scenario:`, `Given`/`When`/`Then`/`And`.
- Every file opens with a comment header block: `# domain:`, `# maps-to:`, `# constraint:` (one line each).
- Files within a domain folder are self-contained — no cross-folder references.
- Do not modify any backend or frontend source files.

---

### Task 1: README and folder scaffold

**Files:**
- Create: `specs/README.md`
- Create (empty dirs): `specs/session/`, `specs/agents/`, `specs/stream/`, `specs/security/`, `specs/workflow/`

**Interfaces:**
- Produces: `specs/README.md` — the entry point every agent reads before touching code in any domain

- [ ] **Step 1: Create domain subdirectories**

```bash
mkdir -p specs/session specs/agents specs/stream specs/security specs/workflow
```

Expected: no output, directories created.

- [ ] **Step 2: Write specs/README.md**

Create the file with this exact content:

```markdown
# specs/

This directory is the authoritative behavioral source of truth for the Synthetic Market Intelligence Platform. Code must conform to specs — not the other way around.

Specs are documentation-only. No test runner executes them. They exist to give AI agents and engineers precise, unambiguous descriptions of how the system must behave, before any code is written or changed.

---

## How to Read Specs

BDD scenarios use the **State > Action > Outcome** mental model:

- **Given** — preconditions: the system state that must be true before anything happens
- **When** — the single triggering action
- **Then** — the observable outcome; what a caller or user can verify

Never infer intent from code. Read the spec for a domain first, then read the code. If they conflict, the spec wins — flag and fix the code.

---

## Naming Conventions

| Extension | Artifact type | When to use |
|-----------|---------------|-------------|
| `.feature` | Gherkin BDD scenarios | Behavioral requirements from a user or agent perspective |
| `.schema.yaml` | Structural data contract | Shape of internal objects: fields, types, nullability, merge semantics |
| `.contract.yaml` | HTTP API contract | Request/response shape, required fields, status codes, enums |

Each file opens with a comment header:

```
# domain: <folder name>
# maps-to: <source file(s) this spec governs>
# constraint: <hard invariant that must not be broken>
```

---

## Domain Folders

| Folder | What it covers |
|--------|----------------|
| `session/` | Session lifecycle, FocusGroupState schema, API contracts |
| `agents/` | Persona definitions, agent phase behavior |
| `stream/` | SSE connection lifecycle, StreamEvent schema |
| `security/` | Blue Team / Green Team plugin behavior, trust score schema |
| `workflow/` | ADK graph topology: nodes, phases, fan-out/fan-in edges |

---

## Agent Consumption Rules

1. Read the domain folder for your assigned domain before writing or modifying any code.
2. If a spec conflicts with existing code, the spec wins — flag the discrepancy and fix the code.
3. Do not modify a spec to match existing code. Modify the spec only if the requirement has genuinely changed, and document why in the commit message.
4. When adding a new feature, write or update the relevant spec first, then implement.
```

- [ ] **Step 3: Verify**

```bash
ls specs/
cat specs/README.md | head -10
```

Expected: six entries (`README.md session agents stream security workflow`), first line is `# specs/`.

- [ ] **Step 4: Commit**

```bash
git add specs/README.md specs/session specs/agents specs/stream specs/security specs/workflow
git commit -m "docs: add specs/ README and domain folder scaffold"
```

---

### Task 2: session/ domain

**Files:**
- Create: `specs/session/session-lifecycle.feature`
- Create: `specs/session/session-state.schema.yaml`
- Create: `specs/session/session-api.contract.yaml`

**Interfaces:**
- Produces: Gherkin scenarios for session create → run → complete state machine
- Produces: Accurate `FocusGroupState` and `FinalReport` field definitions (sourced from `backend/models/state.py`)
- Produces: HTTP contracts for `POST /sessions`, `GET /sessions/{id}`, `GET /personas`, `GET /health`

- [ ] **Step 1: Write specs/session/session-lifecycle.feature**

```gherkin
# domain: session
# maps-to: backend/api/sessions.py, backend/models/state.py, backend/models/schemas.py
# constraint: session IDs are UUIDs; state is in-memory only — no database persistence
# constraint: participant_ids must match keys in the PERSONAS dict in backend/agents/personas.py
# constraint: 1 to 5 participants per session

Feature: Session Lifecycle
  A client submits a topic string and a list of participant IDs.
  The platform creates a session, starts the ADK workflow in a background task,
  and streams progress events until the Synthesizer node completes.

  Scenario: Successful session creation
    Given a valid topic string and at least one valid participant ID
    When the client POSTs to /sessions with topic and participant_ids
    Then the response status is 201
    And the response body contains session_id (UUID string), topic, and participant_ids
    And a background ADK workflow task begins running for that session_id

  Scenario: Session status transitions through all workflow phases
    Given a session has been created with valid participants
    When the ADK workflow runs to completion
    Then the session phase progresses: introduction -> independent -> discussion -> voting -> synthesis
    And each completed node emits SSE events that are appended to state.stream_events

  Scenario: Session completes with a final report
    Given the ADK workflow has reached and completed the synthesizer node
    When the client GETs /sessions/{session_id}
    Then the response field completed is true
    And final_report is populated with overall_score, category_averages, recommendation, and citations
    And final_report is not null

  Scenario: Session creation rejected for invalid participant IDs
    Given a request body with participant_ids containing an ID not present in PERSONAS
    When the client POSTs to /sessions
    Then the response status is 422
    And the response body describes which participant_id was invalid

  Scenario: Session creation rejected for too many participants
    Given a request body with more than 5 participant_ids
    When the client POSTs to /sessions
    Then the response status is 422

  Scenario: Security test mode enables intentional trust score decay
    Given a session creation request with security_test_mode set to true
    When the ADK workflow runs
    Then participant nodes make more than MAX_TOOLS_PER_NODE (10) tool calls per node
    And the Blue Team plugin decrements trust_score by 25 for each violation
    And quarantine_flag is set to true when trust_score falls below 50
    And the Green Team plugin raises a RuntimeError halting further tool execution
```

- [ ] **Step 2: Write specs/session/session-state.schema.yaml**

```yaml
# domain: session
# maps-to: backend/models/state.py
# constraint: fields using operator.or_ merge semantics are written by parallel ADK nodes (fan-out)
# constraint: fields using operator.add merge semantics are appended across parallel nodes
# constraint: trust_score is float (not int); starts at 100 and decrements by 25 per violation

---
schema: FocusGroupState
description: >
  The mutable session state threaded through the ADK workflow runner.
  Written by workflow nodes; read by the SSE stream and GET /sessions/{id} endpoint.
  Fields annotated with operator.or_ are merged by dict union across parallel nodes.
  Fields annotated with operator.add are merged by list concatenation across parallel nodes.
fields:
  session_id:
    type: str
    nullable: false
    description: UUID string assigned at session creation time
  topic:
    type: str
    nullable: false
    description: The idea, product, or concept being evaluated
  participants:
    type: list[AgentPersona]
    nullable: false
    description: List of AgentPersona dicts for the selected personas
  phase:
    type: str
    nullable: false
    description: Current workflow phase name (e.g. introduction, independent, discussion, voting, synthesis)
  round:
    type: int
    nullable: false
    description: Discussion round counter
  moderator_intro:
    type: str
    nullable: false
    description: Opening framing produced by the moderator_introduce node
  moderator_followup:
    type: str
    nullable: false
    description: Targeted follow-up questions produced by the moderator_followup node
  independent_responses:
    type: dict[str, str]
    nullable: false
    merge: operator.or_
    description: "Keyed by persona ID. Each value is that persona's independent evaluation text."
  discussion_responses:
    type: dict[str, str]
    nullable: false
    merge: operator.or_
    description: "Keyed by persona ID. Each value is that persona's discussion-phase response text."
  scores:
    type: dict[str, ScoreSet]
    nullable: false
    merge: operator.or_
    description: "Keyed by persona ID. Each value is that persona's ScoreSet from the voting phase."
  final_report:
    type: FinalReport
    nullable: true
    description: Null until the synthesizer node completes; then populated with the full executive report.
  stream_events:
    type: list[StreamEvent]
    nullable: false
    merge: operator.add
    description: Chronological list of all events emitted. Replayed in full on every SSE reconnect.
  citations:
    type: list[dict]
    nullable: false
    merge: operator.add
    description: Structured source citations added by search-enabled nodes (moderator, synthesizer).
  security_test_mode:
    type: bool
    nullable: false
    description: When true, participant nodes exceed tool-call thresholds to trigger security plugins.
  trust_score:
    type: float
    nullable: false
    default: 100
    description: >
      Starts at 100. Blue Team deducts 25 each time a node exceeds MAX_TOOLS_PER_NODE (10) calls.
      Floor is 0. When trust_score falls below 50, quarantine_flag is set to true.
  agbom:
    type: list[dict]
    nullable: false
    default: []
    description: "Agent BOM: flat list of all tool call records across all nodes. Each record has node, tool, args, status."
  agbom_per_node:
    type: dict[str, list[dict]]
    nullable: false
    default: {}
    description: "Keyed by node_path. Value is the list of tool call records for that node. Used by Blue Team to count per-node calls."
  quarantine_flag:
    type: bool
    nullable: false
    default: false
    description: Set to true by Blue Team when trust_score < 50. Green Team blocks all further tool execution when true.

---
schema: FinalReport
description: The synthesized executive report produced by the synthesizer node.
fields:
  overall_score:
    type: float
    nullable: false
    description: Weighted aggregate score across all personas and dimensions
  scores_by_agent:
    type: dict[str, ScoreSet]
    nullable: false
    description: "Keyed by persona ID: each persona's full ScoreSet"
  category_averages:
    type: ScoreSet
    nullable: false
    description: Average score across all personas for each of the six dimensions
  category_std_dev:
    type: ScoreSet
    nullable: false
    description: Standard deviation per dimension; measures consensus vs disagreement
  consensus_confidence:
    type: float
    nullable: false
    description: Derived confidence metric based on score variance
  key_concerns:
    type: list[str]
    nullable: false
    description: Risks and failure modes surfaced across personas
  key_strengths:
    type: list[str]
    nullable: false
    description: Positive signals and opportunities identified across personas
  action_items:
    type: list[str]
    nullable: false
    description: Concrete next steps recommended by the synthesizer
  recommendation:
    type: str
    nullable: false
    description: The synthesizer's overall verdict on the idea
  sentiment:
    type: str
    nullable: false
    description: Aggregate sentiment label (e.g. cautiously optimistic, skeptical)
  citations:
    type: list[dict]
    nullable: false
    description: "Sources referenced during synthesis. Each dict has: title (str), url (str), excerpt (str)."

---
schema: ScoreSet
description: One persona's blind vote across six scoring dimensions. Used in FocusGroupState.scores and FinalReport.
fields:
  innovation:
    type: float
    nullable: false
    range: [0, 100]
    description: How novel and differentiated the idea is
  market:
    type: float
    nullable: false
    range: [0, 100]
    description: Market size, timing, and competitive dynamics
  ux:
    type: float
    nullable: false
    range: [0, 100]
    description: Usability and user experience quality
  feasibility:
    type: float
    nullable: false
    range: [0, 100]
    description: Technical complexity and execution risk
  monetization:
    type: float
    nullable: false
    range: [0, 100]
    description: Revenue model clarity and sustainability
  risk:
    type: float
    nullable: false
    range: [0, 100]
    description: Downside exposure and failure mode severity

---
schema: AgentPersona
description: One participant's full definition. Stored in FocusGroupState.participants and in backend/agents/personas.py PERSONAS dict.
fields:
  id:
    type: str
    nullable: false
    enum: [skeptical_investor, early_adopter, enterprise_cto, ux_researcher, growth_marketer]
  name:
    type: str
    nullable: false
  role:
    type: str
    nullable: false
  personality:
    type: list[str]
    nullable: false
  expertise:
    type: list[str]
    nullable: false
  biases:
    type: list[str]
    nullable: false
  hidden_motivation:
    type: str
    nullable: false
  temperature:
    type: float
    nullable: false
    description: LLM temperature for this persona's generative calls
  communication_style:
    type: str
    nullable: false
  scoring_weights:
    type: ScoringWeights
    nullable: false
    description: Per-dimension multipliers applied when this persona generates its vote prompt

---
schema: ScoringWeights
description: Per-dimension score multipliers for one persona. Keys match ScoreSet field names.
fields:
  innovation: { type: float }
  market: { type: float }
  ux: { type: float }
  feasibility: { type: float }
  monetization: { type: float }
  risk: { type: float }
```

- [ ] **Step 3: Write specs/session/session-api.contract.yaml**

```yaml
# domain: session
# maps-to: backend/api/sessions.py, backend/api/stream.py, backend/models/schemas.py
# constraint: CreateSessionResponse returns session_id, topic, and participant_ids — not a status field
# constraint: SessionStateResponse uses completed (bool) field, not a status enum
# constraint: The SSE endpoint replays the full stream_events list on every connect — no manual reconnect needed

---
endpoint: POST /sessions
description: Create a new focus group session and start the ADK workflow in a background task.
request:
  content-type: application/json
  body:
    topic:
      type: str
      required: true
      description: The idea, product, or concept to evaluate
    participant_ids:
      type: list[str]
      required: true
      min_items: 1
      max_items: 5
      valid_values: [skeptical_investor, early_adopter, enterprise_cto, ux_researcher, growth_marketer]
    security_test_mode:
      type: bool
      required: false
      default: false
      description: Forces participant nodes to exceed tool-call thresholds
response:
  201:
    session_id: { type: str, format: uuid }
    topic: { type: str }
    participant_ids: { type: list[str] }
  422: Pydantic validation error — malformed body or invalid participant_id values

---
endpoint: GET /sessions/{session_id}
description: Retrieve the current state of a session including the final report when complete.
request:
  path:
    session_id: { type: str, format: uuid, required: true }
response:
  200:
    session_id: { type: str }
    topic: { type: str }
    phase: { type: str }
    round: { type: int }
    moderator_intro: { type: str, nullable: true }
    moderator_followup: { type: str, nullable: true }
    independent_responses: { type: dict, default: {} }
    discussion_responses: { type: dict, default: {} }
    scores: { type: dict, default: {} }
    final_report: { type: dict, nullable: true }
    events_count: { type: int }
    completed: { type: bool }
  404: session_id not found in the in-memory session store

---
endpoint: GET /sessions/{session_id}/stream
description: SSE stream of live discussion events. Replays the full stream_events history on connect.
request:
  path:
    session_id: { type: str, format: uuid, required: true }
response:
  200:
    content-type: text/event-stream
    events: see specs/stream/stream-event.schema.yaml for event type shapes
  404: session_id not found

---
endpoint: GET /personas
description: Return the list of all available agent personas.
response:
  200:
    type: list[dict]
    each:
      id: { type: str }
      name: { type: str }
      role: { type: str }

---
endpoint: GET /health
description: Basic liveness check.
response:
  200:
    status: { type: str, value: ok }
```

- [ ] **Step 4: Verify**

```bash
ls specs/session/
```

Expected: `session-api.contract.yaml  session-lifecycle.feature  session-state.schema.yaml`

- [ ] **Step 5: Commit**

```bash
git add specs/session/
git commit -m "docs: add session domain specs (lifecycle feature, state schema, API contract)"
```

---

### Task 3: agents/ domain

**Files:**
- Create: `specs/agents/persona-behavior.feature`
- Create: `specs/agents/personas.schema.yaml`

**Interfaces:**
- Produces: Gherkin scenarios for the three agent phases (independent, discussion, voting)
- Produces: All 5 persona definitions as machine-readable YAML with exact values from `backend/agents/personas.py`

- [ ] **Step 1: Write specs/agents/persona-behavior.feature**

```gherkin
# domain: agents
# maps-to: backend/agents/nodes/participant.py, backend/agents/personas.py, backend/agents/nodes/moderator.py
# constraint: participant nodes use gemini-2.5-flash; do NOT change to gemini-2.5-pro
# constraint: the voting node (make_vote) uses output_schema=ScoreSet for structured JSON; do not add search tools to it
# constraint: each participant node captures its loop variable via _p=p default arg to avoid closure bugs

Feature: Agent Persona Behavior
  Five distinct AI personas participate in a structured three-phase discussion.
  Each phase runs participant nodes in parallel (fan-out) and produces a specific
  output type written into session state.

  Scenario: Independent evaluation phase runs without cross-contamination
    Given a session has started with at least one participant
    And the moderator_introduce node has produced a moderator_intro string in state
    When each independent_{persona_id} node runs in parallel
    Then each node calls make_independent_response with its own persona dict
    And the result is merged into state.independent_responses[persona_id]
    And no participant node's prompt includes another participant's independent response

  Scenario: Moderator follow-up is generated after all independent responses are collected
    Given all parallel independent nodes have completed
    And state.independent_responses contains one entry per participant
    When the collect_independent JoinNode completes
    Then the moderator_followup node runs next (sequential)
    And it reads all independent_responses to generate targeted follow-up questions
    And the result is written to state.moderator_followup

  Scenario: Discussion phase allows cross-participant awareness
    Given state.moderator_followup is populated
    When each discussion_{persona_id} node runs in parallel
    Then each node calls make_discussion_response with its own persona dict
    And each participant's prompt includes the moderator's follow-up questions
    And each participant's prompt may include other participants' independent responses
    And the result is merged into state.discussion_responses[persona_id]

  Scenario: Voting phase produces structured scores via Gemini output schema
    Given state.discussion_responses contains one entry per participant
    And the collect_discussion JoinNode has completed
    When each vote_{persona_id} node runs in parallel
    Then each node calls make_vote with its own persona dict
    And the LLM call uses output_schema=ScoreSet for structured JSON output
    And the result is merged into state.scores[persona_id]
    And each ScoreSet contains exactly six float fields: innovation, market, ux, feasibility, monetization, risk

  Scenario: Each persona uses its configured LLM temperature
    Given any generative node (independent, discussion, or moderator)
    When the LLM call is made for a given persona
    Then the request uses that persona's temperature value from the PERSONAS dict
    And higher-temperature personas (e.g. Zoe Park at 0.9) produce more varied outputs
    And lower-temperature personas (e.g. David Okafor at 0.6) produce more consistent outputs

  Scenario: Moderator and Synthesizer use gemini-2.5-pro
    Given any moderator or synthesizer node
    When the LLM call is made
    Then the model is gemini-2.5-pro
    And participant nodes use gemini-2.5-flash (not gemini-2.5-pro)
```

- [ ] **Step 2: Write specs/agents/personas.schema.yaml**

All values are sourced verbatim from `backend/agents/personas.py`.

```yaml
# domain: agents
# maps-to: backend/agents/personas.py::PERSONAS
# constraint: these are the only valid persona IDs; participant_ids in POST /sessions must be a subset of these keys
# constraint: scoring_weights keys match ScoreSet field names exactly (innovation, market, ux, feasibility, monetization, risk)

personas:

  skeptical_investor:
    id: skeptical_investor
    name: Marcus Chen
    role: Skeptical Investor
    personality:
      - contrarian
      - data-driven
      - impatient with hype
      - direct
    expertise:
      - venture capital
      - market sizing
      - competitive moats
      - unit economics
    biases:
      - undervalues novel markets
      - overweights near-term revenue
      - dismisses B2C
    hidden_motivation: Find the fatal flaw before anyone else does
    temperature: 0.7
    communication_style: "Blunt, uses precise financial language, asks hard questions"
    scoring_weights:
      innovation: 0.5
      market: 1.5
      ux: 0.5
      feasibility: 1.0
      monetization: 2.0
      risk: 1.5

  early_adopter:
    id: early_adopter
    name: Zoe Park
    role: Enthusiastic Early Adopter
    personality:
      - optimistic
      - trend-chasing
      - vocal
      - emotionally invested
    expertise:
      - consumer products
      - social platforms
      - viral loops
      - community building
    biases:
      - overweights novelty
      - underestimates competition
      - ignores churn
    hidden_motivation: Be first to discover the next big thing
    temperature: 0.9
    communication_style: "Energetic, uses superlatives, speaks from personal experience"
    scoring_weights:
      innovation: 2.0
      market: 1.0
      ux: 1.5
      feasibility: 0.5
      monetization: 0.5
      risk: 0.5

  enterprise_cto:
    id: enterprise_cto
    name: David Okafor
    role: Enterprise CTO
    personality:
      - methodical
      - risk-aware
      - integration-focused
      - skeptical of AI hype
    expertise:
      - system architecture
      - security
      - enterprise software
      - team scaling
    biases:
      - overweights technical complexity
      - biased toward existing vendor relationships
    hidden_motivation: Protect the organization from vendor lock-in and technical debt
    temperature: 0.6
    communication_style: "Technical, structured, asks about edge cases and failure modes"
    scoring_weights:
      innovation: 0.5
      market: 0.5
      ux: 1.0
      feasibility: 2.0
      monetization: 1.0
      risk: 2.0

  ux_researcher:
    id: ux_researcher
    name: Priya Sharma
    role: UX Researcher
    personality:
      - empathetic
      - user-advocate
      - detail-oriented
      - evidence-based
    expertise:
      - user research
      - usability testing
      - accessibility
      - information architecture
    biases:
      - overweights edge-case users
      - undervalues power-user flows
    hidden_motivation: Ensure real users can actually use this without a manual
    temperature: 0.8
    communication_style: "Asks 'but who exactly is the user?', references mental models"
    scoring_weights:
      innovation: 0.5
      market: 1.0
      ux: 2.5
      feasibility: 1.0
      monetization: 0.5
      risk: 0.5

  growth_marketer:
    id: growth_marketer
    name: Jordan Ellis
    role: Growth Marketer
    personality:
      - metric-obsessed
      - creative
      - channel-savvy
      - opportunistic
    expertise:
      - growth loops
      - paid acquisition
      - content marketing
      - SEO
      - virality
    biases:
      - overvalues top-of-funnel
      - undervalues retention and LTV
    hidden_motivation: Find the distribution wedge that makes this explode
    temperature: 0.85
    communication_style: "Uses marketing jargon, talks about funnels, channels, and hooks"
    scoring_weights:
      innovation: 1.0
      market: 2.0
      ux: 0.5
      feasibility: 0.5
      monetization: 1.5
      risk: 0.5
```

- [ ] **Step 3: Verify**

```bash
ls specs/agents/
```

Expected: `persona-behavior.feature  personas.schema.yaml`

- [ ] **Step 4: Commit**

```bash
git add specs/agents/
git commit -m "docs: add agents domain specs (persona behavior feature, personas schema)"
```

---

### Task 4: stream/ domain

**Files:**
- Create: `specs/stream/sse-streaming.feature`
- Create: `specs/stream/stream-event.schema.yaml`

**Interfaces:**
- Produces: Gherkin scenarios for SSE connection lifecycle and event sequence
- Produces: `StreamEvent` schema with accurate nullable rules and all event type variants

- [ ] **Step 1: Write specs/stream/sse-streaming.feature**

```gherkin
# domain: stream
# maps-to: backend/api/stream.py, flutter_app/lib/data/sse_client.dart, flutter_app/lib/models/
# constraint: the backend replays the full stream_events list on every SSE connect — no manual reconnect logic on the frontend
# constraint: the frontend uses one EventSource connection per session (package:web + dart:js_interop)
# constraint: the frontend must call close() immediately on receiving a done or error event type
# constraint: StreamEvent fields agent_id, agent_name, and scores are nullable because done/error events omit them

Feature: SSE Streaming
  The backend streams focus group progress over Server-Sent Events.
  The frontend opens one EventSource connection per session and folds events
  into SessionNotifier state. The backend replays full history on every connect.

  Scenario: Client connects and receives replayed history
    Given a session exists with events already in state.stream_events
    When the client opens an EventSource connection to GET /sessions/{session_id}/stream
    Then the server immediately emits all existing stream_events in chronological order
    And continues emitting new events as the workflow progresses

  Scenario: Event sequence matches workflow phases
    Given a session is running with one or more participants
    When the workflow executes all phases in order
    Then SSE events arrive in this sequence:
      | type         | phase       | notes                                      |
      | phase_change | introduction| moderator intro starts                     |
      | agent_message| independent | one per participant (may arrive in parallel)|
      | phase_change | discussion  | moderator followup starts                  |
      | agent_message| discussion  | one per participant                        |
      | score_update | voting      | one per participant with scores populated  |
      | phase_change | synthesis   | synthesizer starts                         |
      | done         | synthesis   | session complete; agent_id/agent_name null |

  Scenario: done event triggers connection close on the frontend
    Given the workflow has completed
    When the SSE stream emits an event with type "done"
    Then the frontend SseConnection calls close() on the EventSource
    And no reconnect attempt is made

  Scenario: error event triggers connection close on the frontend
    Given an unrecoverable error occurs in the workflow
    When the SSE stream emits an event with type "error"
    Then the frontend SseConnection calls close() on the EventSource
    And the session state reflects the error condition

  Scenario: Parallel participant events may arrive out of order
    Given a session with multiple participants running in parallel fan-out
    When the independent or discussion phase executes
    Then multiple agent_message events for the same phase may arrive in any order
    And the frontend must not assume a fixed ordering for parallel node outputs

  Scenario: Reconnecting client receives full history
    Given a client disconnects mid-session (network drop or page refresh)
    When the client reconnects to GET /sessions/{session_id}/stream
    Then the server replays all events from the beginning of stream_events
    And the client does not request a Last-Event-ID or implement manual reconnect
```

- [ ] **Step 2: Write specs/stream/stream-event.schema.yaml**

```yaml
# domain: stream
# maps-to: backend/models/state.py::StreamEvent, flutter_app/lib/models/
# constraint: agent_id, agent_name, and scores are nullable — done and error events omit these fields
# constraint: the SSE event type field is "type" in the JSON payload; the SSE event name uses the same value
# constraint: StreamEvent is stored in FocusGroupState.stream_events and also serialized directly to the SSE wire format

---
schema: StreamEvent
description: >
  One event emitted during the focus group workflow.
  Stored in FocusGroupState.stream_events and streamed directly to clients via SSE.
  The done and error variants omit agent_id, agent_name, and scores.
fields:
  type:
    type: str
    nullable: false
    enum: [phase_change, agent_message, score_update, done, error]
    description: >
      Discriminator field.
      phase_change: a workflow phase transition (moderator, synthesizer).
      agent_message: a participant text response (independent or discussion phase).
      score_update: a participant vote with populated scores field.
      done: session complete; agent_id, agent_name, scores are null.
      error: workflow error; agent_id, agent_name, scores are null.
  agent_id:
    type: str
    nullable: true
    description: Persona ID of the emitting agent. Null for phase_change, done, and error events.
  agent_name:
    type: str
    nullable: true
    description: Display name of the emitting agent. Null for phase_change, done, and error events.
  phase:
    type: str
    nullable: false
    description: "Workflow phase this event belongs to: introduction, independent, discussion, voting, synthesis"
  content:
    type: str
    nullable: false
    description: Text payload. For phase_change events this is a phase description; for agent_message it is the persona's response text.
  scores:
    type: ScoreSet
    nullable: true
    description: Populated only for score_update events. Null for all other event types.

event_type_variants:
  phase_change:
    agent_id: null
    agent_name: null
    scores: null
    content: description of the phase starting
  agent_message:
    agent_id: persona ID string
    agent_name: persona display name
    scores: null
    content: persona response text
  score_update:
    agent_id: persona ID string
    agent_name: persona display name
    scores: populated ScoreSet
    content: brief vote summary text
  done:
    agent_id: null
    agent_name: null
    scores: null
    content: session completion message
  error:
    agent_id: null
    agent_name: null
    scores: null
    content: error description
```

- [ ] **Step 3: Verify**

```bash
ls specs/stream/
```

Expected: `sse-streaming.feature  stream-event.schema.yaml`

- [ ] **Step 4: Commit**

```bash
git add specs/stream/
git commit -m "docs: add stream domain specs (SSE streaming feature, StreamEvent schema)"
```

---

### Task 5: security/ domain

**Files:**
- Create: `specs/security/plugin-behavior.feature`
- Create: `specs/security/trust-score.schema.yaml`

**Interfaces:**
- Produces: Gherkin scenarios for Blue Team tracking and Green Team quarantine gate
- Produces: Trust score and AGBOM schema with exact threshold and deduction values from the plugin source

- [ ] **Step 1: Write specs/security/plugin-behavior.feature**

```gherkin
# domain: security
# maps-to: backend/plugins/blue_team_plugin.py, backend/plugins/green_team_plugin.py
# constraint: MAX_TOOLS_PER_NODE = 10 (from backend/plugins/blue_team_plugin.py and MAX_TOOLS_PER_NODE file)
# constraint: trust_score deduction is exactly 25 per violation; floor is 0
# constraint: quarantine threshold is trust_score < 50 (strict less-than)
# constraint: Green Team raises RuntimeError — it does not return a dict or set a flag; it raises

Feature: Security Plugin Behavior
  Two ADK plugins run on every session.
  BlueTeamAnalyticsPlugin tracks per-node tool call counts and manages the trust score.
  GreenTeamQuarantinePlugin blocks all further tool execution once quarantine is active.

  Scenario: Blue Team records each tool call after it completes
    Given a session is running with any participant configuration
    When any ADK tool call completes in any workflow node
    Then the Blue Team after_tool_callback fires
    And a record is appended to state.agbom with node, tool, args, and status fields
    And the same record is appended to state.agbom_per_node[node_path]

  Scenario: Blue Team does not penalize nodes under the tool-call threshold
    Given a workflow node has made 10 or fewer tool calls (MAX_TOOLS_PER_NODE = 10)
    When the after_tool_callback fires for any of those calls
    Then trust_score remains unchanged
    And quarantine_flag remains false

  Scenario: Blue Team deducts trust score when a node exceeds the threshold
    Given a workflow node has already made exactly 10 tool calls
    When the 11th tool call completes in that same node
    Then trust_score is decremented by 25
    And the new trust_score = previous_trust_score - 25 (floor 0)
    And each subsequent excess call in that node also triggers a -25 deduction

  Scenario: Blue Team activates quarantine when trust score falls below 50
    Given trust_score has been decremented to below 50 (e.g. 25 after three violations)
    When the Blue Team after_tool_callback processes the violation
    Then quarantine_flag is set to true in session state
    And this flag persists for the remainder of the session

  Scenario: Green Team blocks all tool calls when quarantine is active
    Given quarantine_flag is true in session state
    When any ADK tool call is about to execute in any node
    Then the Green Team before_tool_callback raises RuntimeError
    And the RuntimeError message contains "Green Team Stateful Quarantine"
    And the tool is never executed
    And session state remains intact for forensic analysis (not cleared or corrupted)

  Scenario: Green Team allows tool calls when quarantine is not active
    Given quarantine_flag is false in session state
    When any ADK tool call is about to execute
    Then the Green Team before_tool_callback returns None
    And the tool executes normally

  Scenario: Security test mode triggers the full security response
    Given a session was created with security_test_mode = true
    When the workflow runs
    Then participant nodes are prompted to make more than 10 tool calls per node
    And the Blue Team plugin detects the excess and decrements trust_score
    And if trust_score drops below 50, quarantine_flag is set to true
    And if quarantine_flag is true, the Green Team raises RuntimeError halting the workflow
```

- [ ] **Step 2: Write specs/security/trust-score.schema.yaml**

```yaml
# domain: security
# maps-to: backend/plugins/blue_team_plugin.py, backend/plugins/green_team_plugin.py, backend/models/state.py
# constraint: MAX_TOOLS_PER_NODE = 10 (also read from the MAX_TOOLS_PER_NODE file at repo root)
# constraint: trust_score is a float in FocusGroupState; initialized to 100 in state dict before workflow starts
# constraint: agbom_per_node keys are node_path strings from tool_context.node_path (e.g. "independent_skeptical_investor")

---
schema: TrustScoreSystem
description: >
  The Blue Team and Green Team plugins share state fields within FocusGroupState.
  This schema documents those fields and the rules governing trust score changes.

fields:
  trust_score:
    type: float
    initial_value: 100
    floor: 0
    description: >
      Session-level trust score. Starts at 100.
      Decremented by 25 each time a single workflow node exceeds MAX_TOOLS_PER_NODE tool calls.
      Minimum value is 0 (clamped with max(0, trust_score - 25)).
  quarantine_flag:
    type: bool
    initial_value: false
    description: >
      Set to true by BlueTeamAnalyticsPlugin when trust_score falls below 50.
      Once true, persists for the entire session — never reset to false mid-session.
      Checked by GreenTeamQuarantinePlugin before every tool call.
  agbom:
    type: list[dict]
    initial_value: []
    description: >
      Agent BOM: flat chronological list of all tool call records across all nodes and all sessions.
    record_fields:
      node: { type: str, description: "node_path string from tool_context.node_path" }
      tool: { type: str, description: "tool.name from the ADK BaseTool instance" }
      args: { type: dict, description: "tool_args dict passed to the tool" }
      status: { type: str, enum: [success, unknown], description: "'success' when result is truthy; 'unknown' otherwise" }
  agbom_per_node:
    type: dict[str, list[dict]]
    initial_value: {}
    description: >
      Same records as agbom but grouped by node_path.
      The Blue Team uses len(agbom_per_node[node]) to count per-node calls.
      The threshold check fires when len > MAX_TOOLS_PER_NODE (10).

thresholds:
  MAX_TOOLS_PER_NODE:
    value: 10
    source: backend/plugins/blue_team_plugin.py and MAX_TOOLS_PER_NODE file at repo root
    description: Maximum tool calls per workflow node before a trust score deduction triggers
  TRUST_DEDUCTION_PER_VIOLATION:
    value: 25
    description: Amount subtracted from trust_score per threshold violation
  QUARANTINE_THRESHOLD:
    value: 50
    comparison: strict less-than
    description: trust_score < 50 triggers quarantine_flag = true

plugin_execution_order:
  before_tool: GreenTeamQuarantinePlugin runs first (checks quarantine_flag, raises if true)
  after_tool: BlueTeamAnalyticsPlugin runs after tool completes (records call, updates trust_score)
```

- [ ] **Step 3: Verify**

```bash
ls specs/security/
```

Expected: `plugin-behavior.feature  trust-score.schema.yaml`

- [ ] **Step 4: Commit**

```bash
git add specs/security/
git commit -m "docs: add security domain specs (plugin behavior feature, trust score schema)"
```

---

### Task 6: workflow/ domain

**Files:**
- Create: `specs/workflow/graph-topology.schema.yaml`

**Interfaces:**
- Produces: Full ADK graph topology with accurate node names, types, and edge definitions sourced from `backend/agents/graph.py`

- [ ] **Step 1: Write specs/workflow/graph-topology.schema.yaml**

```yaml
# domain: workflow
# maps-to: backend/agents/graph.py
# constraint: participant node names are dynamically generated as independent_{persona_id}, discussion_{persona_id}, vote_{persona_id}
# constraint: all participant nodes use rerun_on_resume=True
# constraint: loop variable capture uses default argument _p=p — do not refactor to a closure
# constraint: the Workflow name is "focus_group_workflow"

---
schema: ADKGraphTopology
description: >
  The ADK Workflow graph that orchestrates the focus group session.
  Built by backend/agents/graph.py::build_graph(participants).
  The graph structure is fixed; only the number and IDs of participant nodes vary
  based on the participants list passed at session creation.

workflow:
  name: focus_group_workflow
  builder: backend/agents/graph.py::build_graph(participants: list[AgentPersona])

node_types:
  static:
    description: Always present regardless of participant count
    nodes:
      - name: moderator_introduce
        type: workflow node (decorated with @node)
        model: gemini-2.5-pro
        rerun_on_resume: true
        calls: backend/agents/nodes/moderator.py::moderator_introduce_node
        writes_to_state: moderator_intro, stream_events
      - name: moderator_followup
        type: workflow node (decorated with @node)
        model: gemini-2.5-pro
        rerun_on_resume: true
        calls: backend/agents/nodes/moderator.py::moderator_followup_node
        writes_to_state: moderator_followup, stream_events
      - name: synthesizer
        type: workflow node (decorated with @node)
        model: gemini-2.5-pro
        rerun_on_resume: true
        calls: backend/agents/nodes/synthesizer.py::synthesizer_node
        writes_to_state: final_report, stream_events, citations
      - name: collect_independent
        type: JoinNode
        description: Fan-in barrier; waits for all independent_{persona_id} nodes to complete
      - name: collect_discussion
        type: JoinNode
        description: Fan-in barrier; waits for all discussion_{persona_id} nodes to complete
      - name: collect_votes
        type: JoinNode
        description: Fan-in barrier; waits for all vote_{persona_id} nodes to complete

  dynamic:
    description: One set of three nodes is created per participant at build_graph() call time
    node_sets:
      - name_pattern: "independent_{persona_id}"
        type: workflow node (decorated with @node)
        model: gemini-2.5-flash
        rerun_on_resume: true
        calls: backend/agents/nodes/participant.py::make_independent_response
        writes_to_state: "independent_responses[persona_id], stream_events"
      - name_pattern: "discussion_{persona_id}"
        type: workflow node (decorated with @node)
        model: gemini-2.5-flash
        rerun_on_resume: true
        calls: backend/agents/nodes/participant.py::make_discussion_response
        writes_to_state: "discussion_responses[persona_id], stream_events"
      - name_pattern: "vote_{persona_id}"
        type: workflow node (decorated with @node)
        model: gemini-2.5-flash
        rerun_on_resume: true
        calls: backend/agents/nodes/participant.py::make_vote
        writes_to_state: "scores[persona_id], stream_events"
        note: uses output_schema=ScoreSet for structured JSON output; do not add search tools here

edges:
  description: >
    Edges define the execution order. A tuple of nodes on the left side means fan-out (parallel).
    A JoinNode on the right side means fan-in (barrier, waits for all parallel nodes).
  sequence:
    - from: START
      to: moderator_introduce
      type: sequential
    - from: moderator_introduce
      to: "[independent_{id} for each participant]"
      type: fan-out (parallel)
    - from: "[independent_{id} for each participant]"
      to: collect_independent
      type: fan-in (JoinNode barrier)
    - from: collect_independent
      to: moderator_followup
      type: sequential
    - from: moderator_followup
      to: "[discussion_{id} for each participant]"
      type: fan-out (parallel)
    - from: "[discussion_{id} for each participant]"
      to: collect_discussion
      type: fan-in (JoinNode barrier)
    - from: collect_discussion
      to: "[vote_{id} for each participant]"
      type: fan-out (parallel)
    - from: "[vote_{id} for each participant]"
      to: collect_votes
      type: fan-in (JoinNode barrier)
    - from: collect_votes
      to: synthesizer
      type: sequential

phases:
  - name: introduction
    nodes: [moderator_introduce]
  - name: independent
    nodes: ["independent_{id} x N", collect_independent]
  - name: discussion
    nodes: [moderator_followup, "discussion_{id} x N", collect_discussion]
  - name: voting
    nodes: ["vote_{id} x N", collect_votes]
  - name: synthesis
    nodes: [synthesizer]

state_merge_rules:
  description: >
    Parallel nodes write to the same state dict simultaneously.
    ADK uses type annotations on FocusGroupState to resolve conflicts.
  operator.or_:
    applies_to: [independent_responses, discussion_responses, scores]
    behavior: dict union; later writer wins on key collision (no collision expected since keys are persona IDs)
  operator.add:
    applies_to: [stream_events, citations]
    behavior: list concatenation; order across parallel nodes is non-deterministic
```

- [ ] **Step 2: Verify**

```bash
ls specs/workflow/
```

Expected: `graph-topology.schema.yaml`

- [ ] **Step 3: Final verification — confirm full specs tree**

```bash
find specs/ -type f | sort
```

Expected output:
```
specs/README.md
specs/agents/persona-behavior.feature
specs/agents/personas.schema.yaml
specs/security/plugin-behavior.feature
specs/security/trust-score.schema.yaml
specs/session/session-api.contract.yaml
specs/session/session-lifecycle.feature
specs/session/session-state.schema.yaml
specs/stream/sse-streaming.feature
specs/stream/stream-event.schema.yaml
specs/workflow/graph-topology.schema.yaml
```

- [ ] **Step 4: Commit**

```bash
git add specs/workflow/
git commit -m "docs: add workflow domain spec (ADK graph topology schema)"
```
