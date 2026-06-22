<!-- generated-by: gsd-doc-writer -->
# Architecture

## System Overview

The Synthetic Market Intelligence Platform is a multi-agent AI system that simulates a structured focus group to evaluate business ideas, products, or topics. A user submits a topic via the Flutter Web frontend; the FastAPI backend launches a Google ADK workflow that drives a sequence of LLM-powered agent nodes through distinct conversational phases (introduction, independent evaluation, moderated discussion, blind voting, and synthesis). As each node completes, it appends `StreamEvent` objects to a shared in-memory session state, and a Server-Sent Events endpoint replays the full event history to any connected client in real time. The final output is a structured analyst report with weighted scores across six dimensions and grounded citations from live web search.

## Component Diagram

```mermaid
graph TD
    UI[Flutter Web UI]
    SC[SessionNotifier\nRiverpod]
    AC[ApiClient\nHTTP REST]
    SSE[SseConnection\nEventSource]

    FA[FastAPI App\nbackend/main.py]
    SR[sessions router\napi/sessions.py]
    STR[stream router\napi/stream.py]
    SS[In-memory session store\n_sessions dict]

    WF[ADK Workflow\nagents/graph.py]
    MOD_I[moderator_introduce node]
    P_INDEP[independent_{id} nodes\nfan-out per persona]
    J1[collect_independent\nJoinNode]
    MOD_F[moderator_followup node]
    P_DISC[discussion_{id} nodes\nfan-out per persona]
    J2[collect_discussion\nJoinNode]
    P_VOTE[vote_{id} nodes\nfan-out per persona]
    J3[collect_votes\nJoinNode]
    SYNTH[synthesizer node]

    BT[BlueTeamAnalyticsPlugin\nAGBOM + trust scoring]
    GT[GreenTeamQuarantinePlugin\nstateful quarantine]

    GEMINI_PRO[Gemini 2.5 Pro\nModerator + Synthesizer]
    GEMINI_FLASH[Gemini 2.5 Flash\nParticipant agents]
    GSEARCH[Google Search + url_context\ngrounding tools]

    PDF[pdf_builder.dart\nPDF export]
    DOCX[docx_builder.dart\nDOCX export]

    UI --> SC
    SC --> AC
    SC --> SSE
    AC -->|POST /sessions| SR
    SSE -->|GET /sessions/id/stream| STR
    SR --> SS
    STR --> SS
    SR -->|BackgroundTask| WF
    WF --> MOD_I --> P_INDEP --> J1 --> MOD_F
    MOD_F --> P_DISC --> J2 --> P_VOTE --> J3 --> SYNTH
    WF --> BT
    WF --> GT
    MOD_I --> GEMINI_PRO
    MOD_F --> GEMINI_PRO
    SYNTH --> GEMINI_PRO
    P_INDEP --> GEMINI_FLASH
    P_DISC --> GEMINI_FLASH
    P_VOTE --> GEMINI_FLASH
    MOD_I --> GSEARCH
    MOD_F --> GSEARCH
    P_INDEP --> GSEARCH
    P_DISC --> GSEARCH
    SYNTH --> GSEARCH
    WF -->|stream_events appended| SS
    UI --> PDF
    UI --> DOCX
```

## Data Flow

1. **Session creation.** The Flutter UI calls `POST /sessions` via `ApiClient`. The FastAPI sessions router validates the request (1-5 participants, known persona IDs), initialises a `FocusGroupState` TypedDict in the `_sessions` in-memory dict, sets `_session_complete[session_id] = False`, and enqueues `_run_session` as a FastAPI `BackgroundTask`.

2. **Workflow execution (background).** `_run_session` builds an ADK `Workflow` via `build_graph`, wraps it in an `App` with both plugins attached, and executes it via `InMemoryRunner.run_async`. As each workflow node produces an ADK `Event`, the runner loop merges the node output into the live `_sessions[session_id]` dict, appending to `stream_events` and `citations` and merging `independent_responses`, `discussion_responses`, and `scores`.

3. **SSE streaming.** The Flutter client opens `GET /sessions/{id}/stream` via `SseConnection` (browser-native `EventSource` via `dart:js_interop`). The `_event_generator` coroutine first replays all `stream_events` already in the session state, then polls every 0.5 seconds for new events, yielding them as SSE data frames until `_session_complete` is `True` and all events have been sent, at which point it emits a `done` event and closes the generator.

4. **State machine (frontend).** `SessionNotifier` (Riverpod `Notifier`) listens on the `SseConnection.events` stream and folds each `StreamEvent` into `FocusGroupState`. Events of type `agent_message` and `phase_change` advance the `Phase` enum; `score_update` populates the per-agent `scores` map; `report_complete` transitions to the synthesis phase; `done` sets `completed = true` and triggers a final `GET /sessions/{id}` REST call to fetch the full `FinalReport`.

5. **Report export.** Once a session is complete, the UI can invoke `buildPdf` (`flutter_app/lib/export/pdf_builder.dart`, using the `pdf` + `printing` packages) or the DOCX builder (`flutter_app/lib/export/docx_builder.dart`, using hand-rolled OOXML zipped with `archive`). Both run entirely client-side in the browser.

## Workflow Phases

The ADK `Workflow` in `backend/agents/graph.py` defines the following edge sequence:

| Step | Node(s) | Type | Description |
|------|---------|------|-------------|
| 1 | `moderator_introduce` | Single | Gemini 2.5 Pro writes the panel introduction, performs live web search, records citations |
| 2 | `independent_{id}` (per persona) | Parallel fan-out | Each persona agent (Gemini 2.5 Flash) gives an independent evaluation without seeing others' responses |
| 3 | `collect_independent` | JoinNode | Barrier — waits for all independent responses before proceeding |
| 4 | `moderator_followup` | Single | Gemini 2.5 Pro reviews disagreements across Round 1 and writes 2-3 targeted follow-up questions |
| 5 | `discussion_{id}` (per persona) | Parallel fan-out | Each persona reads all Round 1 responses and the follow-up questions, then responds |
| 6 | `collect_discussion` | JoinNode | Barrier — waits for all discussion responses |
| 7 | `vote_{id}` (per persona) | Parallel fan-out | Each persona scores the topic privately across 6 dimensions (innovation, market, ux, feasibility, monetization, risk) using structured output (`VoteScores` Pydantic model) |
| 8 | `collect_votes` | JoinNode | Barrier — waits for all votes |
| 9 | `synthesizer` | Single | Gemini 2.5 Pro computes weighted averages, std deviations, consensus confidence, and produces a `FinalReport` with citations |

All nodes are decorated with `rerun_on_resume=True` to support ADK session resumption.

## Key Abstractions

| Abstraction | File | Description |
|-------------|------|-------------|
| `FocusGroupState` | `backend/models/state.py` | Central TypedDict threading all session data through the ADK workflow; uses `Annotated[list, operator.add]` for append-safe stream event and citation merging |
| `AgentPersona` | `backend/models/state.py` | TypedDict describing a participant's identity, expertise, biases, temperature, and per-category `ScoringWeights` |
| `FinalReport` | `backend/models/state.py` | TypedDict for the synthesized output: scores by agent, category averages, std deviations, consensus confidence, strengths, concerns, action items, and citations |
| `StreamEvent` | `backend/models/state.py` | Typed event envelope emitted by each node; `type` is one of `agent_message`, `phase_change`, `score_update`, `report_complete`, `error`, or `done` |
| `build_graph` | `backend/agents/graph.py` | Factory that accepts a list of `AgentPersona` objects and returns a configured ADK `Workflow` with all parallel fan-out nodes dynamically generated |
| `BlueTeamAnalyticsPlugin` | `backend/plugins/blue_team_plugin.py` | ADK `BasePlugin` with `after_tool_callback`; maintains a per-node Agent Bill of Materials (AGBOM), deducts 25 points from `trust_score` when a node exceeds `MAX_TOOLS_PER_NODE` (10) calls, and sets `quarantine_flag = True` when score falls below 50 |
| `GreenTeamQuarantinePlugin` | `backend/plugins/green_team_plugin.py` | ADK `BasePlugin` with `before_tool_callback`; raises `RuntimeError` to halt all further tool execution when `quarantine_flag` is `True`, preserving session state for forensic analysis |
| `record_citation_tool` | `backend/agents/tools/citation_tracker.py` | ADK `FunctionTool` that appends `{title, url, excerpt}` dicts to `tool_context.state["citations"]`; available to Moderator and Participant nodes |
| `SessionNotifier` | `flutter_app/lib/state/session_notifier.dart` | Riverpod `Notifier` that owns the frontend state machine; manages SSE lifecycle and folds each `StreamEvent` into `FocusGroupSession` |
| `SseConnection` | `flutter_app/lib/data/sse_client.dart` | Thin wrapper over the browser's native `EventSource` (via `package:web` and `dart:js_interop`); one connection per session, no manual reconnect |

## Directory Structure Rationale

```
Agentic-Focus-Group/
├── backend/                  Python FastAPI application and ADK workflow
│   ├── agents/               Workflow graph, persona definitions, node implementations
│   │   ├── graph.py          Workflow builder — the only place edges are declared
│   │   ├── personas.py       Static registry of the five available AgentPersona profiles
│   │   ├── nodes/            One module per node role (moderator, participant, synthesizer)
│   │   └── tools/            Shared ADK FunctionTools (citation_tracker)
│   ├── api/                  FastAPI routers — sessions (CRUD + background task) and stream (SSE)
│   ├── models/               Pydantic schemas (request/response) and TypedDict state definitions
│   ├── plugins/              ADK BasePlugin subclasses (blue_team, green_team)
│   ├── tests/                pytest test suite
│   ├── main.py               FastAPI app factory, CORS config, router registration
│   └── requirements.txt      Python dependencies (google-adk>=2.0.0, fastapi, sse-starlette, etc.)
├── flutter_app/              Flutter Web frontend
│   └── lib/
│       ├── app/              App-level constants: config.dart (API_BASE dart-define)
│       ├── data/             I/O layer: api_client.dart (HTTP) and sse_client.dart (EventSource)
│       ├── export/           Client-side report generation: pdf_builder.dart, docx_builder.dart
│       ├── models/           Hand-written Dart models with fromJson (StreamEvent, FocusGroupSession, etc.)
│       ├── state/            Riverpod providers and SessionNotifier state machine
│       └── features/         UI feature modules (widgets, screens)
└── docs/                     Project documentation
```

The separation between `agents/nodes/` and `agents/graph.py` is intentional: node logic (prompts, LLM calls, state mutations) is isolated per role, while the workflow topology (fan-out, join, sequencing) is declared solely in `graph.py`. This makes it straightforward to add a new workflow phase without modifying existing node files.
