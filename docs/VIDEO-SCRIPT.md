# Synthetic Market Intelligence Platform — Video Script

**Audience:** Kaggle judges / competition reviewers
**Two versions:** 5-min highlight reel (the submission) + 10-min deep dive (optional / backup)

> **Course concepts shown on camera:** Multi-agent System (ADK) · MCP Server · Agent Skills / Agents CLI · Security Features. The 5-min cut demonstrates all four — three is the minimum the rubric requires.

---

## VERSION 1: 5-Minute Highlight Reel *(this is the ≤5-min YouTube submission)*

*Lead with output. Show, then tell. One tight code segment, one terminal segment, one security beat.*

**Target timing:** 5:00 hard cap. Rehearse to land at ~4:50 so you have margin.

| Segment | Time | Beat |
|---|---|---|
| 1 | 0:00–0:28 | Hook |
| 2 | 0:28–2:15 | Live demo |
| 3 | 2:15–3:20 | ADK workflow graph |
| 4 | 3:20–3:58 | MCP server + Agents CLI |
| 5 | 3:58–4:38 | Agentic security |
| 6 | 4:38–5:00 | Outro |

---

### SEGMENT 1 — Hook (0:00–0:28)

**[SCREEN: Full running app at `http://localhost:8080` — all three panels visible]**

> "What if you could get structured, diverse, critical feedback on any idea in under three minutes — from five distinct expert perspectives — with a scored, exportable report at the end?
>
> This is the Synthetic Market Intelligence Platform: a multi-agent system on Google ADK and Gemini 2.5, where AI personas don't just answer — they debate independently, disagree, and vote blind."

---

### SEGMENT 2 — Live Demo (0:28–2:15)

**[SCREEN: Topic input — type "AI-powered meal planning subscription service"]**
**[SCREEN: All five persona cards visible side by side]**

> "I submit a topic and pick up to five personas — Skeptical Investor, Early Adopter, Enterprise CTO, UX Researcher, Growth Marketer. Each has its own biases, a hidden motivation, and its own scoring weights. Marcus the investor weights monetization and market highest; Zoe the early adopter weights innovation. Same idea, different lenses."

**[SCREEN: Click "Start Session" — moderator intro appears in center thread]**

> "The Moderator — Gemini 2.5 Pro with Google Search grounding — opens the panel with real market context."

**[SCREEN: Five agent bubbles streaming in simultaneously — independent phase]**

> "Then all five evaluate independently and in parallel — no agent can see the others yet. That's what keeps the first round honest instead of collapsing into consensus."

**[SCREEN: Moderator follow-up, then discussion bubbles referencing each other]**

> "Only after every independent response is in does the Moderator surface the disagreements and reopen the floor. Now they push back on each other."

**[SCREEN: Right-side score board populating in real time]**

> "Then they vote — privately, across six dimensions — streamed to the board live over Server-Sent Events."

**[SCREEN: Final report card — overall score, category breakdown, consensus, recommendation]**

> "The Synthesizer computes weighted averages, measures consensus with standard deviation, and writes an executive report — strengths, risks, action items, cited sources — exportable as PDF or DOCX right in the browser."

---

### SEGMENT 3 — ADK Workflow Graph (2:15–3:20)

**[SCREEN: `backend/agents/graph.py` — the fan-out loop building parallel nodes]**

> "Under the hood, Google ADK orchestrates a workflow graph. The protocol isn't a prompt — it's the topology."

**[SCREEN: Show this on screen]**

```
moderator_introduce
  → [independent_eval × N]   ← parallel fan-out
  → collect_independent      ← JoinNode barrier
  → moderator_followup
  → [discussion × N]         ← parallel fan-out
  → collect_discussion       ← JoinNode barrier
  → [vote × N]               ← parallel fan-out
  → collect_votes            ← JoinNode barrier
  → synthesizer
```

> "Three fan-out / fan-in cycles. The JoinNode barriers make it structurally impossible for any agent to see round two before every round-one response is collected — so the independent evaluation can't be contaminated, even by accident. The graph builds itself at runtime from whichever personas you selected; adding a persona is one registry entry, no wiring. Gemini 2.5 Flash runs the five participants; 2.5 Pro runs the Moderator and Synthesizer, where reasoning quality matters most. Votes come back as type-safe structured output via a Pydantic schema."

---

### SEGMENT 4 — MCP Server + Agents CLI (3:20–3:58)

**[SCREEN: `backend/mcp_server/server.py` — the `@mcp.tool()` decorators]**

> "The same panel is also published as a Model Context Protocol server. Personas, the weighted-scoring math, and citations — exposed as MCP tools that any host can call. And because the persona data is imported straight from the workflow's own registry, the MCP surface can never drift from what the app uses."

**[SCREEN: Terminal — run `backend/.venv/bin/adk run backend/mcp_client_agent`]**

> "Here it is driven from the Agents CLI — an ADK agent acting as an MCP client, no UI in the loop."

**[SCREEN: Type the prompt, show the tool calls resolve]**

```
List the panel personas, then have Marcus Chen score an idea with
innovation 8, market 6, ux 5, feasibility 7, monetization 4, risk 3.
```

> "It calls `list_personas`, then `score_idea` — returning Marcus's weighted verdict using the exact same math as the in-workflow vote node. One capability surface: the app, Claude Desktop, or the command line."

---

### SEGMENT 5 — Agentic Security (3:58–4:38)

**[SCREEN: `backend/plugins/blue_team_plugin.py` — the `after_tool_callback` trust-score logic]**

> "One more layer: safety as infrastructure, not as a prompt. Two ADK plugins implement intent-drift detection. The Blue Team logs every tool call into an Agent Bill of Materials and runs a session Trust Score starting at 100. Any single node that exceeds ten tool calls — doing far more than its role needs — drops the score by 25."

**[SCREEN: `backend/plugins/green_team_plugin.py` — the `before_tool_callback` quarantine check]**

> "Fall below 50, and the Green Team quarantines the session — it raises before the next tool call and freezes execution cleanly, preserving full state for forensic review. Prompt instructions can drift; plugin enforcement is deterministic."

---

### SEGMENT 6 — Outro (4:38–5:00)

**[SCREEN: Final report scrolling — end on the recommendation / action items]**

> "Google ADK. Gemini 2.5 Pro and Flash. Google Search grounding. An MCP server reachable from the CLI. Two agentic-security plugins. Five agents, three rounds, one synthesized report.
>
> Expensive, slow, inconsistent market research — turned into a reproducible business output in three minutes."

---
---

## VERSION 2: 10-Minute Deep Dive *(optional — for a longer cut or technical audience)*

*Technically rigorous. Show before you tell. Full workflow + code + MCP + security.*

---

### SEGMENT 1 — Hook (0:00–0:45)

**[SCREEN: Open the running app at `http://localhost:8080`]**

> "How do you get diverse, critical feedback on an idea — fast — without scheduling five stakeholder meetings?
>
> This is the Synthetic Market Intelligence Platform. You submit any topic — a product pitch, a business hypothesis, a startup idea — and a panel of five distinct AI personas debates it in real time, scores it across six dimensions, and delivers a synthesized executive report you can export and share.
>
> Let me show you how it works — then we'll go under the hood."

---

### SEGMENT 2 — Starting a Session (0:45–3:00)

**[SCREEN: Full app UI — left panel, center thread, right score panel all visible]**

> "Three panels. Left: topic and persona selection. Center: the live discussion thread. Right: a live score board."

**[SCREEN: Topic input field — type "AI-powered meal planning subscription service"]**

> "I'll enter a topic. Now the personas."

**[SCREEN: All 5 persona cards — pause on each briefly]**

> "Five personas. Each has distinct traits encoded in its system prompt:
>
> Marcus Chen — the Skeptical Investor. Hidden motivation: find the fatal flaw first. Temperature 0.7 — methodical, data-driven. Overweights Monetization and Risk.
>
> Zoe Park — the Early Adopter. Temperature 0.9 — optimistic, trend-chasing. Overweights Innovation.
>
> David Okafor — the Enterprise CTO. Temperature 0.6 — risk-aware, integration-focused. Overweights Feasibility and Risk.
>
> Priya Sharma — the UX Researcher. Temperature 0.8 — empathetic, user-advocate. Overweights UX.
>
> Jordan Ellis — the Growth Marketer. Temperature 0.85 — channel- and metric-focused.
>
> Select all five. Click Start Session."

**[SCREEN: Loading state briefly after "Start Session"]**

> "The backend creates a session UUID, stores state in memory, and queues the ADK workflow as a FastAPI background task. The frontend opens an SSE stream and starts receiving events."

---

### SEGMENT 3 — Watching the Workflow Run (3:00–5:45)

**[SCREEN: Moderator intro appearing in discussion thread]**

> "Phase one: the Moderator — Gemini 2.5 Pro with Google Search grounding — opens the panel. It uses real-world market data to set context."

**[SCREEN: All five independent evaluation bubbles loading simultaneously]**

> "Phase two: independent evaluation. All five personas run simultaneously — they cannot see each other's responses yet. That's the parallel fan-out step. Marcus flags unit economics. Zoe highlights the personalization angle. These responses are genuinely independent — no shared context."

**[SCREEN: Moderator follow-up questions appearing]**

> "Phase three: the Moderator reads round one and writes targeted follow-up questions — probing the points of disagreement, not summarizing what it heard."

**[SCREEN: Discussion phase — agent bubbles referencing other agents' positions]**

> "Phase four: discussion. Now personas see each other's round-one assessments. Marcus pushes back on Zoe's optimism. David raises a procurement concern nobody surfaced in round one. The responses are richer because they're reactive."

**[SCREEN: Right-side score panel — numbers populating dimension by dimension]**

> "Phase five: blind voting. Each persona privately scores across six dimensions — Innovation, Market, UX, Feasibility, Monetization, Risk. These arrive as structured JSON via Gemini's `output_schema` mode with a Pydantic `ScoreSet` model. Type-safe, validated, no hallucinated field names."

**[SCREEN: Full final report card — weighted score, category breakdown, consensus confidence, key concerns, recommendation]**

> "Phase six: synthesis. Gemini 2.5 Pro computes weighted averages using each persona's scoring weights, calculates standard deviation to quantify consensus confidence, and writes an executive summary: key concerns, key strengths, action items, overall sentiment, and a final recommendation."

---

### SEGMENT 4 — ADK Graph Architecture (5:45–7:15)

**[SCREEN: `backend/agents/graph.py` — top of file, function signature and imports]**

> "The orchestration lives in `backend/agents/graph.py`. Google ADK provides the workflow primitive — a directed graph of async nodes."

**[SCREEN: Highlight the dynamic node generation loop — show `_p=p` default argument clearly]**

> "For each participant, we generate a node at runtime. The closure captures the persona with `_p=p` as a default argument — the standard fix for Python's loop-variable capture problem."

**[SCREEN: JoinNode / barrier section in graph.py]**

> "After each parallel phase, a JoinNode acts as a barrier — all persona nodes must complete before the workflow advances. Three fan-out / fan-in cycles total, and the barriers make early responses structurally unreachable until the round closes."

**[SCREEN: Show this topology on screen]**

```
moderator_introduce
  → [independent_eval × N]   ← parallel fan-out
  → collect_independent      ← JoinNode barrier
  → moderator_followup
  → [discussion × N]         ← parallel fan-out
  → collect_discussion       ← JoinNode barrier
  → [vote × N]               ← parallel fan-out
  → collect_votes            ← JoinNode barrier
  → synthesizer
```

---

### SEGMENT 5 — Personas & State (7:15–8:15)

**[SCREEN: `backend/agents/personas.py` — one full persona definition: system prompt, temperature, scoring_weights dict]**

> "Each persona is a typed record: a system prompt encoding personality and hidden motivation, a Gemini temperature, and a scoring-weights dict across all six dimensions. The weights aren't normalized — they're relative multipliers, roughly 0.5 to 2.0, that differ meaningfully per persona. Synthesis divides the weighted total by the sum of the weights, so each persona's priorities genuinely reshape its verdict. That's what makes the weighted synthesis non-trivial."

**[SCREEN: `backend/models/state.py` — FocusGroupState TypedDict with Annotated list fields]**

> "Session state is a TypedDict threaded through the ADK workflow. `stream_events`, `citations`, and the response lists use `Annotated[list, operator.add]` for append semantics — partial outputs from parallel nodes combine without overwriting. No race conditions."

---

### SEGMENT 6 — MCP Server + Agents CLI (8:15–9:05)

**[SCREEN: `backend/mcp_server/server.py` — `FastMCP` init and the `@mcp.tool()` functions]**

> "The in-process workflow is great for the bundled UI, but it locks the panel inside one Python process. So the project also ships a Model Context Protocol server. Five tools — `list_personas`, `get_persona`, `score_idea`, `record_citation`, `list_citations` — plus two resources. Persona data is imported straight from the same registry the workflow uses, so the MCP surface can never drift from the app. `score_idea` reuses the exact vote-node math; citations persist to a JSON store since an MCP client has no ADK session state."

**[SCREEN: Terminal — `backend/.venv/bin/adk run backend/mcp_client_agent`, then the prompt]**

```
List the panel personas, then have Marcus Chen score an idea with
innovation 8, market 6, ux 5, feasibility 7, monetization 4, risk 3.
```

> "`backend/mcp_client_agent/` is a minimal ADK agent that connects as an MCP client over stdio and runs from the terminal. On the first tool call it spawns the server as a subprocess, lists its tools, calls `list_personas` then `score_idea`, and returns Marcus's weighted verdict — the same panel, reached through a standard CLI host instead of the browser."

---

### SEGMENT 7 — SSE, Frontend State & Security (9:05–10:15)

**[SCREEN: `backend/api/stream.py` — the `_event_generator` async function, history replay section]**

> "Live updates go over Server-Sent Events. The generator first replays the full session history on every connect — so reconnecting is safe and idempotent."

**[SCREEN: `frontend/lib/state/session_notifier.dart` — the `_applyEvent` method]**

> "On the Flutter side, a single Riverpod Notifier owns all session state. Every event routes through `_applyEvent` — updating the thread, the score board, or triggering the final-report fetch. One state owner, no ad-hoc widget state."

**[SCREEN: `backend/plugins/blue_team_plugin.py` — trust-score deduction logic]**

> "And two ADK plugins add agentic security. Blue Team logs tool calls into an Agent Bill of Materials and runs a Trust Score from 100 — any node past ten calls drops it by 25."

**[SCREEN: `backend/plugins/green_team_plugin.py` — `before_tool_callback` quarantine check]**

> "Below 50, Green Team quarantines: it raises before the next tool call, halts execution, and preserves state for forensics. Wired directly into the ADK plugin lifecycle — not bolted on."

---

### SEGMENT 8 — Export & Outro (10:15–10:45)

**[SCREEN: Completed session — "Download PDF" and "Download DOCX" buttons visible]**

> "Export is fully client-side. PDF via the `pdf` and `printing` packages. DOCX via hand-rolled OOXML zipped with the `archive` package. No server round-trip."

**[SCREEN: Downloaded PDF open — report with scores, concerns, recommendations]**
**[SCREEN: Repo root in terminal — `ls` showing directory structure]**

> "Google ADK. Gemini 2.5 Pro and Flash. Google Search grounding. Pydantic structured output. An MCP server reachable from the Agents CLI. FastAPI, Flutter Web, Riverpod. Two agentic-security plugins.
>
> Five agents. Three rounds. One synthesized report."

---

## Screenshots / Screen-Capture Checklist

| # | What to Capture | Where | 5-min | 10-min |
|---|---|---|:---:|:---:|
| 1 | Full app — all three panels visible | `http://localhost:8080` | ✓ | ✓ |
| 2 | All 5 persona cards | Left panel | ✓ | ✓ |
| 3 | Topic input with text | Left panel | ✓ | ✓ |
| 4 | Moderator intro in thread | Center panel | ✓ | ✓ |
| 5 | 5 agent bubbles loading simultaneously | Center panel | ✓ | ✓ |
| 6 | Moderator follow-up questions | Center panel | ✓ | ✓ |
| 7 | Discussion phase — agents referencing each other | Center panel | ✓ | ✓ |
| 8 | Score panel updating live | Right panel | ✓ | ✓ |
| 9 | Final report card — score + categories + recommendation | Center panel | ✓ | ✓ |
| 10 | `graph.py` — fan-out loop with `_p=p` capture | Code editor | ✓ | ✓ |
| 11 | `graph.py` — JoinNode barrier | Code editor |  | ✓ |
| 12 | `mcp_server/server.py` — `@mcp.tool()` functions | Code editor | ✓ | ✓ |
| 13 | Terminal — `adk run backend/mcp_client_agent` + tool calls | Terminal | ✓ | ✓ |
| 14 | `personas.py` — one persona definition | Code editor |  | ✓ |
| 15 | `state.py` — FocusGroupState TypedDict | Code editor |  | ✓ |
| 16 | `stream.py` — SSE event generator | Code editor |  | ✓ |
| 17 | `session_notifier.dart` — `_applyEvent` | Code editor |  | ✓ |
| 18 | `blue_team_plugin.py` — trust score logic | Code editor | ✓ | ✓ |
| 19 | `green_team_plugin.py` — quarantine check | Code editor | ✓ | ✓ |
| 20 | Export buttons on completed session | App UI |  | ✓ |
| 21 | Downloaded PDF open with report | PDF viewer |  | ✓ |
| 22 | `ls` of repo root | Terminal |  | ✓ |

---

> **Recording tips:**
> - Run a full session **before** recording so you know the output for your chosen topic. "AI-powered meal planning subscription service" generates good disagreement between Marcus and Zoe and is concrete enough for judges to follow without domain knowledge.
> - For Segment 4 (MCP/CLI), pre-run `adk run` once so the model and subprocess are warm — the first tool call can be slow to spawn the server.
> - The 5-min cut is the actual submission (Kaggle caps YouTube videos at 5 minutes). Rehearse to ~4:50 so a slow live session doesn't push you over.
> - If a live run risks running long on camera, record the demo (Segment 2) separately and cut to it — narration timing stays under your control.
