import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env", override=True)  # must run before importing modules that configure the GenAI client

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .api.sessions import router as sessions_router
from .api.stream import router as stream_router

app = FastAPI(title="AI Focus Group", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000", "http://127.0.0.1:3000",   # Next.js (legacy)
        "http://localhost:8080", "http://127.0.0.1:8080",   # Flutter web (flutter run --web-port=8080)
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(sessions_router)
app.include_router(stream_router)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/personas")
async def list_personas():
    from .agents.personas import PERSONAS
    return {
        pid: {
            "id": p["id"],
            "name": p["name"],
            "role": p["role"],
            "communication_style": p["communication_style"],
        }
        for pid, p in PERSONAS.items()
    }
