<!-- generated-by: gsd-doc-writer -->
# Testing

This document covers test frameworks, commands, file conventions, and CI integration for the Synthetic Market Intelligence Platform.

---

## Test Framework and Setup

The project maintains two independent test suites — one for the Python backend and one for the Flutter frontend.

### Backend (Python)

- **Framework:** pytest 9.1.1 with pytest-asyncio 1.4.0
- **Test runner:** `backend/.venv/bin/pytest`
- **Configuration:** `pytest.ini` at the repo root

`pytest.ini` settings:

```ini
[pytest]
pythonpath = .
testpaths = backend/tests
```

`pythonpath = .` is required so that `backend.` package imports resolve correctly when pytest is run from the repo root.

**Required setup before running backend tests:**

```bash
# Install backend dependencies into the project virtualenv
backend/.venv/bin/pip install -r backend/requirements.txt
```

### Frontend (Dart / Flutter)

- **Framework:** `flutter_test` (bundled with the Flutter SDK)
- **Static analysis:** `flutter analyze` using `flutter_lints ^6.0.0`
- **Test runner:** `flutter test`

**Required setup before running Flutter tests:**

```bash
cd frontend && flutter pub get
```

---

## Running Tests

### Backend tests

Run the full backend suite from the repo root:

```bash
backend/.venv/bin/pytest
```

Run a specific test file:

```bash
backend/.venv/bin/pytest backend/tests/test_api.py
```

Run a specific test by name:

```bash
backend/.venv/bin/pytest backend/tests/test_plugins.py -k "test_blue_team_fires_on_excessive_node_usage"
```

Run with verbose output:

```bash
backend/.venv/bin/pytest -v
```

> Always invoke pytest via `backend/.venv/bin/pytest` from the repo root. Running `python -m pytest` with the system Python or from inside `backend/` may fail with import errors because the project virtualenv and `pythonpath = .` are both required.

### Flutter tests

Run the full Flutter test suite:

```bash
cd frontend && flutter test
```

Run a single test file:

```bash
cd frontend && flutter test test/stream_event_test.dart
```

Run static analysis (recommended before committing frontend changes):

```bash
cd frontend && flutter analyze
```

---

## Writing New Tests

### Backend conventions

- **Location:** `backend/tests/`
- **File naming:** `test_<module>.py` (e.g., `test_api.py`, `test_plugins.py`)
- **Async tests:** Use the `@pytest.mark.asyncio` decorator (provided by `pytest-asyncio`) for coroutine test functions.
- **Shared fixtures:** Defined in `backend/tests/conftest.py`. The `client` fixture (module scope) creates a `fastapi.testclient.TestClient` wrapping `backend.main:app`.

Fixture reference:

| Fixture | Scope | Provides |
|---------|-------|----------|
| `client` | module | `TestClient` for the FastAPI app |

### Flutter conventions

- **Location:** `frontend/test/`
- **File naming:** `<subject>_test.dart` (e.g., `stream_event_test.dart`, `score_set_test.dart`)
- **Groups:** Use `group('ClassName.methodName', () { ... })` to mirror the class and method under test.
- **Imports:** Tests import directly from `package:focus_group/models/` — no test helper library is used.

---

## Test File Inventory

### Backend

| File | What it covers |
|------|----------------|
| `backend/tests/test_api.py` | HTTP endpoint integration tests (health check, persona listing, session creation and retrieval, error cases) |
| `backend/tests/test_plugins.py` | `BlueTeamAnalyticsPlugin` unit tests — verifies quarantine logic triggers only above `MAX_TOOLS_PER_NODE` threshold |
| `backend/tests/test_personas.py` | `get_persona` / `get_all_persona_ids` unit tests — validates all five persona definitions and their required fields |
| `backend/tests/test_schemas.py` | Pydantic model validation for `CreateSessionRequest`, `CreateSessionResponse`, `SessionStateResponse`, `FocusGroupState`, and `FinalReport` |
| `backend/tests/test_tools.py` | `record_citation` tool unit tests — verifies state writes, appends, and ADK `FunctionTool` wrapping |
| `backend/tests/conftest.py` | Shared `client` fixture |

> **Not yet covered by automated tests:** the MCP server (`backend/mcp_server/`) and the Agents CLI client (`backend/mcp_client_agent/`). Note that `backend/mcp_server/server.py` reuses the same `personas.py` registry and scoring math already exercised by `test_personas.py` and `test_tools.py`. Verify the MCP surface manually — see below.

### MCP server smoke check

The MCP server is not part of the pytest suite. To confirm it starts and lists its tools, run it from the repo root and drive it from the Agents CLI:

```bash
# Terminal check: server imports and starts over stdio (Ctrl-C to exit)
backend/.venv/bin/python -m backend.mcp_server.server

# End-to-end: the client agent spawns the server and calls its tools
export GEMINI_API_KEY=...
backend/.venv/bin/adk run backend/mcp_client_agent
# then, at the prompt:
#   List the panel personas, then have Marcus Chen score an idea with
#   innovation 8, market 6, ux 5, feasibility 7, monetization 4, risk 3.
```

A successful run lists all five personas and returns Marcus's weighted verdict — the same scoring math as the in-workflow ADK `vote` node. See [MCP-SERVER.md](MCP-SERVER.md) for details.

### Flutter

| File | What it covers |
|------|----------------|
| `frontend/test/stream_event_test.dart` | `StreamEvent.fromJson` — agent messages, score updates, `done` and `error` events with nullable fields |
| `frontend/test/score_set_test.dart` | `ScoreSet.fromJson`, `ScoreSet.average`, and `orderedEntries` canonical ordering |
| `frontend/test/session_state_response_test.dart` | `SessionStateResponse.fromJson` and `CreateSessionResponse.fromJson` — full parse and missing-field defaults |

---

## Coverage Requirements

No coverage threshold is currently configured. Neither `pytest.ini` nor any coverage configuration file (`.nycrc`, `c8`, `coverageThreshold`) is present in the repository.

To generate a coverage report manually (requires `pytest-cov`):

```bash
backend/.venv/bin/pytest --cov=backend --cov-report=term-missing
```

---

## CI Integration

No CI/CD pipeline (`.github/workflows/`) is currently configured in the repository. Tests must be run locally before merging changes.

Recommended pre-merge checklist:

```bash
# Backend
backend/.venv/bin/pytest -v

# Frontend — analysis then tests
cd frontend && flutter analyze
cd frontend && flutter test
```
