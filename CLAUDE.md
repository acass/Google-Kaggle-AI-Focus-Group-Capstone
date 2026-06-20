# CLAUDE.md

Quick reference for commands, styling, and coding guidelines in the AI Focus Group project.

## 🚀 Running the Project

### Backend (FastAPI + Google ADK)
- **Start Backend**: `cd backend && uvicorn main:app --reload`
- **Dependencies**: `cd backend && pip install -r requirements.txt`
- **Environment**: Copy `backend/.env.example` to `backend/.env` and add `GEMINI_API_KEY`.

### Frontend (Next.js 16 + React 19)
- **Start Frontend**: `cd frontend && npm run dev`
- **Install Dependencies**: `cd frontend && npm install`
- **Lint**: `cd frontend && npm run lint`
- **Build**: `cd frontend && npm run build`

---

## 🛠️ Code Conventions & Guidelines

### Python (Backend)
- Use type hints wherever possible.
- Use `pydantic` models for JSON request/response validation.
- Run async calls for Gemini SDK (`await client.aio.models.generate_content(...)`).
- Capture loop variables using default arguments (e.g. `_p=p`) in dynamically generated node functions.

### TypeScript / React (Frontend)
- Use React 19 standards and Next.js 16 conventions.
- Prefix interactive files with `"use client"`.
- Use the central hook `useFocusGroup` for managing session states and Server-Sent Events (SSE).
- PDF and Word report generation must be executed client-side via `jspdf` and `docx` in `frontend/app/utils/exportReport.ts`.
