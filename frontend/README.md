<!-- generated-by: gsd-doc-writer -->
# Synthetic Market Intelligence Platform — Flutter Web Frontend

Flutter Web frontend for the AI Focus Group platform. Streams real-time AI agent discussions via Server-Sent Events (SSE), displays live scoring, and exports executive reports as PDF or DOCX.

This is the `frontend/` package within the monorepo. See the [root README](../README.md) for full-stack setup.

## Prerequisites

- Flutter SDK with Dart `^3.11.5`
- Chrome (required for Flutter Web development)
- The backend FastAPI server running on `http://localhost:8000` (backend CORS is hardcoded to `http://localhost:8080` for the Flutter origin)

## Installation

```bash
cd frontend
flutter pub get
```

## Running

```bash
flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000
```

The `--web-port=8080` flag is required. The backend CORS allowlist is hardcoded to that port.

`API_BASE` must point to the running FastAPI backend. Change the value if the backend is on a different host or port.

## Build

```bash
flutter build web --dart-define=API_BASE=http://localhost:8000
```

Output is written to `build/web/`.

## Other Commands

| Command | Description |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter analyze` | Run static analysis |
| `flutter test` | Run the test suite |
| `flutter build web --dart-define=API_BASE=...` | Production web build |

## Architecture

### State management

Riverpod (`flutter_riverpod ^3.3.2`) is used throughout. The central state machine lives in `lib/state/session_notifier.dart` (`SessionNotifier extends Notifier<FocusGroupState>`). All SSE event parsing and session lifecycle transitions are handled there — do not implement ad-hoc SSE parsing in widgets.

### Data layer

- `lib/data/sse_client.dart` — consumes the backend SSE stream using the browser's native `EventSource` via `package:web` and `dart:js_interop`. One connection per session; closes on `done`/`error` events.
- `lib/data/api_client.dart` — REST calls to the backend. Base URL is injected via `--dart-define=API_BASE` (see `lib/app/config.dart`).

### Models

`lib/models/` contains hand-written Dart models with `fromJson` constructors. `StreamEvent` fields `agent_id`, `agent_name`, and `scores` are nullable because `done`/`error` events omit them.

### Export

Client-side report generation in `lib/export/`:

- `pdf_builder.dart` — PDF export using the `pdf ^3.12.0` and `printing ^5.14.3` packages.
- `docx_builder.dart` — DOCX export using hand-rolled OOXML zipped with `archive ^4.0.9`.

Both export paths must remain functional.

## Key Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | `^3.3.2` | State management |
| `http` | `^1.6.0` | REST API calls |
| `web` | `^1.1.1` | Browser EventSource for SSE |
| `pdf` | `^3.12.0` | PDF report generation |
| `printing` | `^5.14.3` | PDF rendering and download |
| `archive` | `^4.0.9` | DOCX (OOXML) packaging |
