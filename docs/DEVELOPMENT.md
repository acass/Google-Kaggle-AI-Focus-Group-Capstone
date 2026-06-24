<!-- generated-by: gsd-doc-writer -->
# Development

This guide covers local development setup, build commands, code style, and contribution workflow for the Synthetic Market Intelligence Platform. The project has two independent runtimes: a Python/FastAPI backend and a Flutter Web frontend.

---

## Local Setup

### Prerequisites

- Python 3.11+ with `venv` or `virtualenv`
- Flutter SDK (Dart SDK `^3.11.5`)
- Chrome browser (required for `flutter run -d chrome`)
- A `GEMINI_API_KEY` from Google AI Studio

### Backend

1. Create and activate the project virtualenv from the repo root:

```bash
python -m venv backend/.venv
source backend/.venv/bin/activate   # Windows: backend\.venv\Scripts\activate
```

2. Install dependencies:

```bash
backend/.venv/bin/pip install -r backend/requirements.txt
```

3. Copy the environment file and add your API key:

```bash
cp backend/.env.example backend/.env
# Edit backend/.env and set GEMINI_API_KEY=<your key>
```

4. Start the development server **from the repo root** (not from inside `backend/`):

```bash
backend/.venv/bin/uvicorn backend.main:app --reload --port 8000
```

> `main.py` uses package-relative imports (`from .api...`). Running `cd backend && uvicorn main:app` will fail with "attempted relative import with no known parent package". Always run from the repo root as `backend.main:app`.
>
> The project virtualenv at `backend/.venv` includes `google-adk>=2.0.0` which provides `google.adk.workflow`. The system Python may have an older ADK that raises `ModuleNotFoundError: No module named 'google.adk.workflow'`.

### Frontend

1. Install Flutter dependencies:

```bash
cd frontend && flutter pub get
```

2. Start the Flutter Web dev server (keep port 8080 — it is in the backend CORS allowlist):

```bash
cd frontend && flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000
```

The `API_BASE` dart-define is read in `frontend/lib/app/config.dart` and passed to `ApiClient`. Do not change the port without also updating the `allow_origins` list in `backend/main.py`.

---

## Build Commands

### Backend

| Command | Description |
|---|---|
| `backend/.venv/bin/uvicorn backend.main:app --reload --port 8000` | Start dev server with auto-reload |
| `backend/.venv/bin/pip install -r backend/requirements.txt` | Install / refresh backend dependencies |
| `backend/.venv/bin/pytest` | Run the full backend test suite |

### Frontend

| Command | Description |
|---|---|
| `cd frontend && flutter pub get` | Install / refresh Dart dependencies |
| `cd frontend && flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000` | Start Flutter Web dev server |
| `cd frontend && flutter analyze` | Run static analysis (flutter_lints) |
| `cd frontend && flutter test` | Run Flutter unit tests |
| `cd frontend && flutter build web --dart-define=API_BASE=http://localhost:8000` | Produce a production web build in `frontend/build/web/` |

---

## Code Style

### Python (Backend)

The backend does not use an automated formatter enforced by CI. Follow these conventions manually:

- **Type hints** — use them on all function signatures and local variables where the type is not obvious.
- **Pydantic models** — all request/response shapes must be defined in `backend/models/schemas.py` as Pydantic v2 models. Do not pass raw dicts across the HTTP boundary.
- **Async Gemini calls** — always use the async client: `await client.aio.models.generate_content(...)`. Never call the sync variant inside an `async def` function.
- **Loop-variable capture** — when generating node functions dynamically (e.g. fan-out per persona in `backend/agents/graph.py`), capture loop variables using default arguments: `lambda state, _p=p: ...` or `def node(state, _p=p):`. Closures that close over a mutable loop variable will all reference the last iteration's value.
- **Module imports** — use relative imports inside the `backend/` package (e.g. `from ..models.state import FocusGroupState`).

### Dart / Flutter (Frontend)

Static analysis is provided by `flutter_lints` via `frontend/analysis_options.yaml` (which includes `package:flutter_lints/flutter.yaml`). Run `flutter analyze` before pushing.

- **State management** — all session state and SSE event folding must live in `frontend/lib/state/session_notifier.dart` (`SessionNotifier`). Do not add ad-hoc SSE parsing or session logic inside widget classes.
- **SSE** — the `SseConnection` class in `frontend/lib/data/sse_client.dart` wraps the browser's native `EventSource` via `package:web` and `dart:js_interop`. One connection per session; the connection is closed when a `done` or `error` event arrives. Do not implement manual reconnect — the backend replays full history on every connect, so reconnecting would duplicate events.
- **REST calls** — route all HTTP calls through `frontend/lib/data/api_client.dart`. Do not construct `http.Client` instances directly in widgets.
- **Nullable stream event fields** — `StreamEvent` fields `agent_id`, `agent_name`, and `scores` are nullable. The `done` and `error` events omit these fields; handle null values wherever these are read.
- **Export builders** — both `pdf_builder.dart` (PDF via `pdf` + `printing` packages) and `docx_builder.dart` (DOCX via hand-rolled OOXML + `archive`) must remain functional. Do not change one without verifying the other still produces valid output.

---

## Key Source Locations

### Backend

| File | Purpose |
|---|---|
| `backend/main.py` | FastAPI app, CORS config, health endpoint, personas endpoint |
| `backend/agents/graph.py` | ADK workflow graph — fan-out/fan-in per phase |
| `backend/agents/personas.py` | All 5 persona definitions (scoring weights, temperatures) |
| `backend/agents/nodes/moderator.py` | Intro and follow-up question nodes (gemini-2.5-pro) |
| `backend/agents/nodes/participant.py` | Independent eval, discussion, and voting nodes (gemini-2.5-flash) |
| `backend/agents/nodes/synthesizer.py` | Final report node (gemini-2.5-pro with `google_search` tool) |
| `backend/agents/tools/citation_tracker.py` | ADK `FunctionTool` for citation tracking (present but not currently passed to any agent node) |
| `backend/api/sessions.py` | Session CRUD, in-memory store (`_sessions`), background task runner |
| `backend/api/stream.py` | SSE streaming endpoint with replay-on-reconnect |
| `backend/models/schemas.py` | Pydantic request/response models |
| `backend/models/state.py` | `TypedDict` state types: `FocusGroupState`, `AgentPersona`, etc. |
| `backend/plugins/blue_team_plugin.py` | AGBOM tracking, trust scoring (threshold: 10 tool calls/node, -25 per excess) |
| `backend/plugins/green_team_plugin.py` | Content safety: quarantine when `trust_score < 50` |

### Frontend

| File | Purpose |
|---|---|
| `frontend/lib/main.dart` | App entry point |
| `frontend/lib/app/config.dart` | Reads `API_BASE` dart-define |
| `frontend/lib/state/session_notifier.dart` | `SessionNotifier` — SSE state machine and event folding |
| `frontend/lib/data/sse_client.dart` | `SseConnection` — native `EventSource` wrapper |
| `frontend/lib/data/api_client.dart` | REST API client |
| `frontend/lib/models/` | Hand-written `fromJson` data models |
| `frontend/lib/export/pdf_builder.dart` | Client-side PDF export |
| `frontend/lib/export/docx_builder.dart` | Client-side DOCX export |

---

## Running Tests

### Backend

Tests live in `backend/tests/` and are discovered automatically via `pytest.ini` (`testpaths = backend/tests`, `pythonpath = .`). Run from the repo root:

```bash
backend/.venv/bin/pytest
```

Individual test files:

```bash
backend/.venv/bin/pytest backend/tests/test_api.py
backend/.venv/bin/pytest backend/tests/test_plugins.py
backend/.venv/bin/pytest backend/tests/test_personas.py
backend/.venv/bin/pytest backend/tests/test_schemas.py
backend/.venv/bin/pytest backend/tests/test_tools.py
```

### Flutter

```bash
cd frontend && flutter test
```

---

## Branch Conventions

No formal branch naming convention is documented. The repository default branch is `main`. A suggested pattern consistent with the commit history:

- `feat/<short-description>` — new features
- `fix/<short-description>` — bug fixes
- `refactor/<short-description>` — refactoring without behavior change

---

## PR Process

No pull request template is present in the repository. Follow these guidelines when submitting changes:

- Run `backend/.venv/bin/pytest` and confirm all backend tests pass before opening a PR.
- Run `cd frontend && flutter analyze` and resolve all analysis warnings before opening a PR.
- Run `cd frontend && flutter test` and confirm all Flutter tests pass.
- Keep PRs focused on a single concern — separate feature work from refactoring.
- Reference the relevant issue number in the PR description if one exists.

---

## Related Docs

- [docs/GETTING-STARTED.md](GETTING-STARTED.md) — prerequisites and first-run instructions
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) — system design and component overview
- [docs/CONFIGURATION.md](CONFIGURATION.md) — environment variables and configuration reference
