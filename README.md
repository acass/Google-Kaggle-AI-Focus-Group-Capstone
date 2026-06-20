# AI Focus Group

A synthetic research panel powered by role-based AI agents. Submit any idea, product, or concept and watch a structured panel of distinct AI personas debate, critique, score, and synthesize it — in real time.

<img width="1487" height="825" alt="AI Focus Group" src="https://github.com/user-attachments/assets/f0356da1-bf63-4829-9cd7-22b932632a35" />

## What It Does

Instead of asking a single AI "what do you think?", AI Focus Group convenes a panel of five opinionated agents, each with a unique background, bias set, hidden motivation, and scoring lens. They run through a structured discussion protocol:

1. **Independent evaluation** — each agent reacts without seeing the others' responses (prevents groupthink)
2. **Moderated follow-up** — a Moderator agent surfaces disagreements and asks targeted follow-up questions
3. **Open discussion** — participants respond to each other's critiques
4. **Blind voting** — each agent scores the idea privately across six dimensions
5. **Synthesis** — a dedicated Synthesizer agent reads the full discussion and produces an executive report
6. **Report Export** — users can export the generated executive report in professional PDF or editable DOCX formats directly from the UI

The result is far more useful than a single AI opinion: you get structured disagreement, diverse risk analysis, a consensus score, and actionable recommendations.

---

## Example Personas

| Name | Role | Hidden Motivation |
|---|---|---|
| Marcus Chen | Skeptical Investor | Find the fatal flaw before anyone else does |
| Zoe Park | Enthusiastic Early Adopter | Be first to discover the next big thing |
| David Okafor | Enterprise CTO | Protect against vendor lock-in and technical debt |
| Priya Sharma | UX Researcher | Ensure real users can use this without a manual |
| Jordan Ellis | Growth Marketer | Find the distribution wedge that makes this explode |

Each persona has its own personality traits, expertise domain, known biases, LLM temperature, and weighted scoring criteria.

---

## Scoring Dimensions

Each participant scores the idea across six categories, weighted by their persona:

- **Innovation** — how novel and differentiated
- **Market Potential** — size, timing, and competitive dynamics
- **UX** — usability and user experience quality
- **Feasibility** — technical complexity and execution risk
- **Monetization** — revenue model clarity and sustainability
- **Risk** — downside exposure and failure modes

The Synthesizer aggregates scores into an overall viability rating plus a standard deviation that signals how much consensus (or healthy disagreement) exists.

---

## Stack

**Backend**
- Python 3.11+
- [FastAPI](https://fastapi.tiangolo.com/) — REST API + SSE streaming
- [Google ADK](https://adk.dev/) — multi-agent workflow orchestration with parallel fan-out
- [Google GenAI](https://pypi.org/project/google-genai/) — Gemini 2.5 Pro (Moderator and Synthesizer) & Gemini 2.5 Flash (Participants)
- Server-Sent Events for real-time discussion streaming

**Frontend**
- [Next.js 16](https://nextjs.org/) + React 19
- [Tailwind CSS v4](https://tailwindcss.com/)
- TypeScript
- [jsPDF](https://github.com/parallax/jsPDF) — Client-side PDF report generation
- [docx](https://docx.js.org/) — Client-side Word document (.docx) report generation

---

## Project Structure

```
AI Focus Group/
├── backend/
│   ├── agents/
│   │   ├── graph.py          # ADK Workflow state machine (fan-out/fan-in per phase)
│   │   ├── personas.py       # All 5 agent persona definitions
│   │   └── nodes/
│   │       ├── moderator.py  # Introduction + follow-up question generation
│   │       ├── participant.py # Independent, discussion, and voting responses
│   │       └── synthesizer.py # Final report generation
│   ├── api/
│   │   ├── sessions.py       # Session creation and management
│   │   └── stream.py         # SSE streaming endpoint
│   ├── models/
│   │   ├── schemas.py        # Pydantic request/response models
│   │   └── state.py          # State types
│   ├── main.py               # FastAPI app + CORS
│   └── requirements.txt
└── frontend/
    ├── app/
    │   ├── components/
    │   │   ├── TopicInput.tsx      # Left panel — topic submission
    │   │   ├── DiscussionThread.tsx # Center — live agent messages
    │   │   ├── ScorePanel.tsx      # Right panel — live scores
    │   │   ├── AgentBubble.tsx     # Individual agent message card
    │   │   └── FinalReport.tsx     # Synthesizer report display
    │   ├── hooks/
    │   │   └── useFocusGroup.ts    # SSE client + session state
    │   ├── utils/
    │   │   └── exportReport.ts     # PDF and DOCX export utilities
    │   └── page.tsx
    ├── package.json
    └── tsconfig.json
```

---

## Getting Started

### Prerequisites

- Python 3.11+
- Node.js 18+
- A [Google Gemini API key](https://aistudio.google.com/app/apikey)

### Backend

```bash
cd backend

# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY

# Start the API server
uvicorn main:app --reload
```

The API will be available at `http://localhost:8000`. Health check: `GET /health`.

### Frontend

```bash
cd frontend

# Install dependencies
npm install

# Start the dev server
npm run dev
```

Open `http://localhost:3000`.

---

## How to Use

1. Enter any topic, idea, product concept, or pitch in the left panel
2. Select which personas to include (defaults to all five)
3. Click **Start Session**
4. Watch the agents debate in real time in the center panel
5. Monitor live scores updating in the right panel
6. Read the Synthesizer's final report at the bottom when the session completes

---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/sessions` | Create a new focus group session |
| `GET` | `/sessions/{id}` | Get session details and final report |
| `GET` | `/sessions/{id}/stream` | SSE stream of discussion events |
| `GET` | `/personas` | List all available personas |
| `GET` | `/health` | Health check |

---

## Environment Variables

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Your Gemini API key (required) |

---

## License

MIT
