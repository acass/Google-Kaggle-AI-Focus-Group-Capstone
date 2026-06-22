# CLAUDE.md

Quick reference for commands, styling, and coding guidelines in the AI Focus Group project.

## 🚀 Running the Project

### Backend (FastAPI + Google ADK)
- **Start Backend**: from the repo root, `backend/.venv/bin/uvicorn backend.main:app --reload --port 8000`
  - Run from the repo root as `backend.main:app` — `main.py` uses package-relative imports, so `cd backend && uvicorn main:app` fails with "attempted relative import with no known parent package".
  - Use the project virtualenv at `backend/.venv` (it has `google-adk>=2.0.0`, which provides `google.adk.workflow`). The system Python may have an older ADK and will fail with `ModuleNotFoundError: No module named 'google.adk.workflow'`.
- **Dependencies**: `backend/.venv/bin/pip install -r backend/requirements.txt`
- **Environment**: Copy `backend/.env.example` to `backend/.env` and add `GEMINI_API_KEY`.

### Frontend (Flutter Web)
- **Start Frontend**: `cd flutter_app && flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000`
  - The backend CORS allowlist (`backend/main.py`) permits `http://localhost:8080`, so keep the Flutter web port at 8080.
- **Install Dependencies**: `cd flutter_app && flutter pub get`
- **Analyze**: `cd flutter_app && flutter analyze`
- **Test**: `cd flutter_app && flutter test`
- **Build**: `cd flutter_app && flutter build web --dart-define=API_BASE=http://localhost:8000`

---

## 🛠️ Code Conventions & Guidelines

### Python (Backend)
- Use type hints wherever possible.
- Use `pydantic` models for JSON request/response validation.
- Run async calls for Gemini SDK (`await client.aio.models.generate_content(...)`).
- Capture loop variables using default arguments (e.g. `_p=p`) in dynamically generated node functions.

### Dart / Flutter (Frontend)
- State management uses **Riverpod** (`flutter_riverpod`). The session state machine and SSE handling live in `flutter_app/lib/state/session_notifier.dart` (the `SessionNotifier`). Do not implement ad-hoc SSE parsing in widgets.
- SSE is consumed via the browser's native `EventSource` through `package:web` + `dart:js_interop` in `flutter_app/lib/data/sse_client.dart`. One connection per session, no manual reconnect (the backend replays history on connect); close on the `done`/`error` event.
- REST calls go through `flutter_app/lib/data/api_client.dart`. The backend base URL is configured via `--dart-define=API_BASE=...` (see `flutter_app/lib/app/config.dart`).
- PDF and Word report generation run client-side in `flutter_app/lib/export/`: PDF via the `pdf` + `printing` packages (`pdf_builder.dart`), DOCX via hand-rolled OOXML zipped with `archive` (`docx_builder.dart`). Keep both export options working.
- Data models are hand-written with `fromJson` in `flutter_app/lib/models/` (StreamEvent fields `agent_id`/`agent_name`/`scores` are nullable because the `done`/`error` events omit them).
