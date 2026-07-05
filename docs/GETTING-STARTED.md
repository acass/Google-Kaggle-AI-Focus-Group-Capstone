<!-- generated-by: gsd-doc-writer -->
# Getting Started

This guide walks you through setting up and running the Synthetic Market Intelligence Platform (AI Focus Group) locally for the first time.

## Prerequisites

The following tools must be installed before you begin:

- **Python >= 3.11** — the backend uses `google-adk>=2.0.0`, which requires Python 3.11 or later.
- **Flutter SDK (stable channel)** — the frontend is a Flutter web application. Install from [flutter.dev](https://flutter.dev/docs/get-started/install).
- **Google Gemini API key** — obtain one at [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey).
- **Chrome browser** — Flutter web development runs against Chrome (`flutter run -d chrome`).

Verify your environment before continuing:

```bash
python3 --version   # must be 3.11 or higher
flutter --version   # must be on stable channel
```

---

## Installation Steps

### 1. Clone the repository

```bash
git clone <repository-url>
cd Agentic-Focus-Group
```

### 2. Set up the backend

All backend commands run from the **repo root** (not from inside `backend/`). The `main.py` entry point uses package-relative imports (`from .api.sessions import ...`), so running `cd backend && uvicorn main:app` will fail with "attempted relative import with no known parent package".

```bash
# Create and activate the project virtualenv
python3 -m venv backend/.venv

# Install backend dependencies
backend/.venv/bin/pip install -r backend/requirements.txt

# Configure environment variables
cp backend/.env.example backend/.env
```

Open `backend/.env` and replace the placeholder with your Gemini API key:

```
GEMINI_API_KEY=your-key-here
```

### 3. Set up the frontend

```bash
cd frontend
flutter pub get
cd ..
```

---

## First Run

Open two terminal windows — one for the backend and one for the frontend.

**Terminal 1 — Start the backend (from repo root):**

```bash
backend/.venv/bin/uvicorn backend.main:app --reload --port 8000
```

The backend is ready when you see `Application startup complete`. Confirm with:

```bash
curl http://localhost:8000/health
# {"status":"ok"}
```

**Terminal 2 — Start the frontend:**

```bash
cd frontend
flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000
```

Chrome will open automatically at `http://localhost:8080`. The platform is ready to use.

---

## Optional: Run the MCP Server

The project also ships a Model Context Protocol server that exposes the same panel to MCP hosts (Claude Desktop, the Google ADK Agents CLI, or another ADK agent). It reuses the backend dependencies you already installed — the `mcp` package is included in `backend/requirements.txt`. Run it **from the repo root** so the package-relative imports resolve:

```bash
# stdio transport (Claude Desktop / Agents CLI)
backend/.venv/bin/python -m backend.mcp_server.server

# streamable HTTP on :8765
backend/.venv/bin/python -m backend.mcp_server.server --http
```

To drive it from the terminal via the Agents CLI:

```bash
export GEMINI_API_KEY=...   # the client agent's Gemini model
backend/.venv/bin/adk run backend/mcp_client_agent
```

See [MCP-SERVER.md](MCP-SERVER.md) for the full tool/resource surface and client wiring.

---

## Common Setup Issues

**Wrong Python or missing `google.adk.workflow` module**

The system Python may have an older version of `google-adk` that does not include `google.adk.workflow`. Always invoke uvicorn through the project virtualenv:

```bash
# Correct
backend/.venv/bin/uvicorn backend.main:app --reload --port 8000

# Incorrect — may use system Python with wrong ADK version
uvicorn backend.main:app --reload --port 8000
```

**"Attempted relative import with no known parent package" error**

This error occurs when uvicorn is run from inside the `backend/` directory. Run it from the repo root only:

```bash
# Correct — run from repo root
backend/.venv/bin/uvicorn backend.main:app --reload --port 8000

# Incorrect — do not cd into backend first
cd backend && uvicorn main:app --reload --port 8000
```

**Frontend cannot reach the backend (CORS errors)**

The backend CORS allowlist in `backend/main.py` is hardcoded to `http://localhost:8080`. The Flutter web port must be `8080` and the `API_BASE` dart-define must match the running backend URL:

```bash
# Correct — port 8080 matches the CORS allowlist
flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000

# Incorrect — port 3001 is not in the CORS allowlist
flutter run -d chrome --web-port=3001 --dart-define=API_BASE=http://localhost:8000
```

**Missing `GEMINI_API_KEY`**

If the backend starts but API calls return errors, verify that `backend/.env` exists and contains a valid key. The `.env.example` file shows the expected format:

```
GEMINI_API_KEY=AIza...
```

**Sessions lost after backend restart**

Session state is stored in memory only. Restarting the backend clears all active sessions. This is expected behavior in development — start a new focus group session from the frontend after each backend restart.

---

## Next Steps

- See [ARCHITECTURE.md](ARCHITECTURE.md) for a map of backend services, agents, and frontend data flow.
- See [CONFIGURATION.md](CONFIGURATION.md) for all environment variables and configuration options.
- See [DEVELOPMENT.md](DEVELOPMENT.md) for build commands, code style, and contribution workflow.
- See [TESTING.md](TESTING.md) for how to run backend and Flutter tests.
- See [MCP-SERVER.md](MCP-SERVER.md) for exposing the panel over the Model Context Protocol.
