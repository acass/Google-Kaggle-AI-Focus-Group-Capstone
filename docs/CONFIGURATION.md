<!-- generated-by: gsd-doc-writer -->
# Configuration

This document covers all configuration options for the Synthetic Market Intelligence Platform — environment variables for the backend, compile-time defines for the Flutter frontend, CORS settings, and the hardcoded persona configuration.

---

## Environment Variables

The backend uses `python-dotenv` to load environment variables from `backend/.env` at startup (via `load_dotenv` in `backend/main.py`). Copy the example file before first run:

```bash
cp backend/.env.example backend/.env
```

| Variable | Required | Default | Description |
|---|---|---|---|
| `GEMINI_API_KEY` | Required | — | Google Gemini API key. Obtain from https://aistudio.google.com/app/apikey |

No other environment variables are defined in `backend/.env.example`. The application will fail to authenticate with the Gemini API if `GEMINI_API_KEY` is absent or invalid.

### Required setting

`GEMINI_API_KEY` must be set before starting the backend. The Google GenAI client reads it at import time. If it is missing the backend will start but all focus group session requests will fail with an authentication error from the Gemini API.

---

## Frontend Dart Defines

The Flutter frontend has no `.env` file. Configuration is passed as `--dart-define` flags at build or run time. These values are compiled into the application binary.

| Define | Required | Default | Description |
|---|---|---|---|
| `API_BASE` | Optional | `http://localhost:8000` | Base URL for the FastAPI backend. Consumed by `flutter_app/lib/app/config.dart`. |

**Development run example:**

```bash
flutter run -d chrome --web-port=8080 --dart-define=API_BASE=http://localhost:8000
```

**Production build example:**

```bash
flutter build web --dart-define=API_BASE=https://your-backend-url
```
<!-- VERIFY: Replace https://your-backend-url with the actual deployed backend URL -->

The default value `http://localhost:8000` is set directly in `flutter_app/lib/app/config.dart` using `String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000')`. No define is needed for local development unless the backend runs on a different port.

---

## CORS Configuration

CORS is configured in `backend/main.py` using FastAPI's `CORSMiddleware`. The allowlist is hardcoded — there is no environment variable to override it at runtime.

**Allowed origins:**

| Origin | Purpose |
|---|---|
| `http://localhost:3000` | Legacy (Next.js prototype, no longer active) |
| `http://127.0.0.1:3000` | Legacy (loopback alias) |
| `http://localhost:8080` | Flutter web (`flutter run --web-port=8080`) |
| `http://127.0.0.1:8080` | Flutter web (loopback alias) |

The Flutter frontend must run on port 8080. Using any other port will cause all API requests to be blocked by the browser's CORS policy.

All methods and all headers are permitted (`allow_methods=["*"]`, `allow_headers=["*"]`). Credentials are allowed (`allow_credentials=True`).

To add a new allowed origin (e.g., a staging domain), edit the `allow_origins` list in `backend/main.py`.

---

## AI Model Configuration

Model names are hardcoded in the agent node files. There is no environment variable to override them.

| Agent role | Model | Source file |
|---|---|---|
| Moderator (intro and follow-up) | `gemini-2.5-pro` | `backend/agents/nodes/moderator.py` |
| Synthesizer | `gemini-2.5-pro` | `backend/agents/nodes/synthesizer.py` |
| Participants (all five personas) | `gemini-2.5-flash` | `backend/agents/nodes/participant.py` |

To change a model, edit the `model=` argument on the `LlmAgent(...)` constructor in the relevant node file.

---

## Persona Configuration

Personas are defined in `backend/agents/personas.py` as a hardcoded Python dictionary (`PERSONAS`). There is no external config file or database — changes require editing the source file directly.

Five personas ship with the platform:

| ID | Name | Role | LLM Temperature |
|---|---|---|---|
| `skeptical_investor` | Marcus Chen | Skeptical Investor | 0.7 |
| `early_adopter` | Zoe Park | Enthusiastic Early Adopter | 0.9 |
| `enterprise_cto` | David Okafor | Enterprise CTO | 0.6 |
| `ux_researcher` | Priya Sharma | UX Researcher | 0.8 |
| `growth_marketer` | Jordan Ellis | Growth Marketer | 0.85 |

Each persona carries per-category scoring weights used during the voting phase. The six scoring categories are: `innovation`, `market`, `ux`, `feasibility`, `monetization`, and `risk`. Weights are floating-point multipliers applied to raw 0-10 scores.

To add a persona, append a new entry to the `PERSONAS` dict in `backend/agents/personas.py` following the `AgentPersona` TypedDict schema defined in `backend/models/state.py`.

---

## Session State

The backend holds all focus group session state in memory (Python dicts). There is no database, cache layer, or persistent store. All session data is lost when the backend process restarts. This is by design for the current iteration — no database configuration is required.

---

## Per-Environment Overrides

There are no `.env.development`, `.env.production`, or `.env.test` files. The only supported mechanism for per-environment variation is:

- **Backend**: replace the value of `GEMINI_API_KEY` in `backend/.env` (or inject it via the deployment platform's secret manager).
- **Frontend**: pass a different `--dart-define=API_BASE=...` value at build time for each target environment.
- **CORS**: edit the `allow_origins` list in `backend/main.py` before deploying to a new environment.
<!-- VERIFY: Confirm whether a staging or production CORS origin needs to be added to backend/main.py -->
