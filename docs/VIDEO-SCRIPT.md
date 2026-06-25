# AI Focus Group — Video Script

**Audience:** Kaggle judges / competition reviewers  
**Two versions:** 5-min highlight reel + 10-min deep dive

---

## VERSION 1: 5-Minute Highlight Reel

*Lead with output. Show, then tell. Keep code to one tight segment.*

---

### SEGMENT 1 — Hook (0:00–0:30)

**[SCREENSHOT: Full running app at `http://localhost:8080` — all three panels visible]**

> "What if you could get structured, diverse, critical feedback on any idea in under three minutes — from five distinct expert perspectives — with a scored, exportable report at the end?
>
> This is the AI Focus Group: a multi-agent platform built on Google ADK and Gemini 2.5, where AI personas don't just answer — they debate, disagree, and vote."

---

### SEGMENT 2 — Live Demo (0:30–2:30)

**[SCREENSHOT: Topic input — type "AI-powered meal planning subscription service"]**

**[SCREENSHOT: All five persona cards visible side by side]**

> "I submit a topic and select up to five personas. Each is a distinct expert archetype — Skeptical Investor, Early Adopter, Enterprise CTO, UX Researcher, Growth Marketer — each with unique biases, hidden motivations, and scoring weights."

**[SCREENSHOT: Click "Start Session" — moderator intro message appears in center thread]**

> "The Moderator — running on Gemini 2.5 Pro with Google Search grounding — opens the panel. Then all five personas evaluate independently and in parallel."

**[SCREENSHOT: Multiple agent bubbles streaming in simultaneously — independent phase]**

**[SCREENSHOT: Right-side score panel beginning to populate]**

> "Three rounds: independent eval, moderated discussion, and blind voting across six dimensions. The score board updates in real time via Server-Sent Events."

**[SCREENSHOT: Final report card — overall score, category breakdown, recommendation text visible]**

> "The Synthesizer computes weighted averages, measures consensus confidence, and delivers an executive report — exportable as PDF or DOCX, right in the browser."

---

### SEGMENT 3 — Architecture (2:30–4:00)

**[SCREENSHOT: `backend/agents/graph.py` — the fan-out loop creating parallel nodes]**

> "Under the hood: Google ADK orchestrates a directed workflow graph. Three fan-out / fan-in cycles run persona agents in parallel — coordinated by JoinNodes acting as barriers. Gemini 2.5 Flash handles the five concurrent participants; Gemini 2.5 Pro handles the Moderator and Synthesizer where quality matters most."

**[SCREENSHOT: Display this topology on screen]**

```
START → moderator_introduce
  → [independent_{persona} × N]   ← parallel fan-out
  → collect_independent (barrier)
  → moderator_followup
  → [discussion_{persona} × N]    ← parallel fan-out
  → collect_discussion (barrier)
  → [vote_{persona} × N]          ← parallel fan-out
  → collect_votes (barrier)
  → synthesizer → END
```

> "The graph is constructed at runtime based on which personas are selected. Nodes use Google Search for grounding, and voting uses Gemini's structured output mode with a Pydantic schema for type-safe scores."

---

### SEGMENT 4 — Innovation Callout (4:00–4:40)

**[SCREENSHOT: `backend/plugins/blue_team_plugin.py` — the `after_tool_callback` trust score logic, ~10 lines]**

> "One innovation beyond the core workflow: agentic security. Two ADK plugins implement intent drift detection. The Blue Team tracks tool call counts per node. Exceed ten calls on any single node and the trust score drops. Below fifty, the Green Team quarantines the session — halting all tool execution while preserving state for forensic analysis. Agentic safety built into the orchestration layer."

---

### SEGMENT 5 — Outro (4:40–5:00)

**[SCREENSHOT: Final report scrolling — end on recommendation / action items text]**

> "Google ADK. Gemini 2.5 Pro and Flash. Google Search grounding. Flutter Web. Five agents. Three rounds. One synthesized report.
>
> This is what structured multi-agent reasoning looks like in practice."

---

---

## VERSION 2: 10-Minute Deep Dive

*Technically rigorous. Show before you tell. Full workflow + code + security.*

---

### SEGMENT 1 — Hook (0:00–0:45)

**[SCREENSHOT: Open the running app at `http://localhost:8080`]**

> "How do you get diverse, critical feedback on an idea — fast — without scheduling five stakeholder meetings?
>
> This is an AI Focus Group. You submit any topic — a product pitch, a business hypothesis, a startup idea — and a panel of five distinct AI personas debates it in real time, scores it across six dimensions, and delivers a synthesized executive report you can export and share.
>
> Let me show you how it works — then we'll go under the hood."

---

### SEGMENT 2 — Starting a Session (0:45–3:00)

**[SCREENSHOT: Full app UI — left panel, center thread, right score panel all visible]**

> "Three panels. Left: topic and persona selection. Center: the live discussion thread. Right: a live score board."

**[SCREENSHOT: Topic input field — type "AI-powered meal planning subscription service"]**

> "I'll enter a topic. Now the personas."

**[SCREENSHOT: All 5 persona cards — pause on each briefly]**

> "Five personas. Each has distinct traits encoded in their system prompt:
>
> Marcus Chen — the Skeptical Investor. Hidden motivation: find the fatal flaw first. Temperature 0.7 — methodical, data-driven. Overweights Risk and Monetization.
>
> Zoe Park — the Early Adopter. Temperature 0.9 — optimistic, trend-chasing. Overweights Innovation.
>
> David Okafor — the Enterprise CTO. Temperature 0.6 — risk-aware, integration-focused. Skeptical of AI hype.
>
> Priya Sharma — the UX Researcher. Temperature 0.8 — empathetic, user-advocate. Overweights edge cases.
>
> Jordan Ellis — the Growth Marketer. Temperature 0.85 — metric-obsessed, channel-focused. Overvalues top-of-funnel.
>
> Select all five. Click Start Session."

**[SCREENSHOT: Loading state briefly after "Start Session"]**

> "The backend creates a session UUID, stores state in memory, and queues the ADK workflow as a FastAPI background task. The frontend opens an SSE stream and starts receiving events."

---

### SEGMENT 3 — Watching the Workflow Run (3:00–6:00)

**[SCREENSHOT: Moderator intro appearing in discussion thread]**

> "Phase one: the Moderator — Gemini 2.5 Pro with Google Search grounding — opens the panel. It uses real-world market data to set context."

**[SCREENSHOT: All five independent evaluation bubbles loading simultaneously]**

> "Phase two: independent evaluation. All five personas run simultaneously — they cannot see each other's responses yet. That's the parallel fan-out step. Marcus flags unit economics. Zoe highlights the personalization angle. These responses are genuinely independent — no shared context."

**[SCREENSHOT: Moderator follow-up questions appearing]**

> "Phase three: the Moderator reads round one and writes targeted follow-up questions — probing the points of disagreement, not summarizing what it heard."

**[SCREENSHOT: Discussion phase — agent bubbles referencing other agents' positions]**

> "Phase four: discussion. Now personas see each other's round-one assessments. Marcus pushes back on Zoe's optimism. David raises a procurement concern nobody surfaced in round one. The responses are richer in this round because they're reactive."

**[SCREENSHOT: Right-side score panel — numbers populating dimension by dimension]**

> "Phase five: blind voting. Each persona privately scores across six dimensions — Innovation, Market Potential, UX, Feasibility, Monetization, Risk. These arrive as structured JSON via Gemini's `output_schema` mode with a Pydantic `ScoreSet` model. Type-safe, validated, no hallucinated field names."

**[SCREENSHOT: Full final report card — weighted score, category breakdown, consensus confidence, key concerns, recommendation]**

> "Phase six: synthesis. Gemini 2.5 Pro computes weighted averages using each persona's scoring weights, calculates standard deviation to quantify consensus confidence, and writes an executive summary: key concerns, key strengths, action items, overall sentiment, and a final recommendation."

---

### SEGMENT 4 — ADK Graph Architecture (6:00–7:45)

**[SCREENSHOT: `backend/agents/graph.py` — top of file, function signature and imports]**

> "The orchestration lives in `backend/agents/graph.py`. Google ADK provides the workflow primitive — a directed acyclic graph of async nodes."

**[SCREENSHOT: Highlight the dynamic node generation loop — show `_p=p` default argument clearly]**

> "For each participant, we generate a node at runtime. The closure captures the persona with `_p=p` as a default argument — the standard fix for Python's loop-variable capture problem. Each node is decorated with `@node` and `rerun_on_resume=True`."

**[SCREENSHOT: JoinNode / barrier section in graph.py]**

> "After each parallel phase, a JoinNode acts as a barrier — all persona nodes must complete before the workflow advances. Three fan-out / fan-in cycles total."

**[SCREENSHOT: Show this topology on screen]**

```
START → moderator_introduce
  → [independent_{persona} × N]   ← parallel fan-out
  → collect_independent (barrier)
  → moderator_followup
  → [discussion_{persona} × N]    ← parallel fan-out
  → collect_discussion (barrier)
  → [vote_{persona} × N]          ← parallel fan-out
  → collect_votes (barrier)
  → synthesizer → END
```

---

### SEGMENT 5 — Personas & State (7:45–8:45)

**[SCREENSHOT: `backend/agents/personas.py` — one full persona definition: system prompt, temperature, scoring_weights dict]**

> "Each persona is a data class: system prompt encoding personality and hidden motivation, a Gemini temperature, and a scoring weights dict for all six dimensions. The weights sum to 1.0 per persona and differ meaningfully — that's what makes the weighted synthesis non-trivial."

**[SCREENSHOT: `backend/models/state.py` — FocusGroupState TypedDict with Annotated list fields]**

> "Session state is a TypedDict threaded through the ADK workflow. `stream_events` and `citations` use `Annotated[list, operator.add]` for append semantics — partial outputs from parallel nodes combine without overwriting. Score dicts use merge semantics. No race conditions."

---

### SEGMENT 6 — SSE & Frontend State (8:45–9:30)

**[SCREENSHOT: `backend/api/stream.py` — the `_event_generator` async function, showing the history replay section]**

> "The frontend receives live updates via Server-Sent Events. The generator first replays the full session history on every connect — reconnecting is safe and idempotent, no extra client-side state management needed."

**[SCREENSHOT: `frontend/lib/state/session_notifier.dart` — the `_applyEvent` method]**

> "On the Flutter side, a single Riverpod Notifier owns all session state. Every SSE event routes through `_applyEvent` — which updates the thread, populates the score board, or triggers the final report fetch on completion. One state owner. No ad-hoc widget state."

---

### SEGMENT 7 — Security Plugins (9:30–10:15)

**[SCREENSHOT: `backend/plugins/blue_team_plugin.py` — `after_tool_callback` with trust score deduction logic]**

> "Two ADK plugins add agentic security. Blue Team implements intent drift detection — tracking per-node tool call counts. Any node exceeding ten calls: trust score drops by 25 points, floor zero."

**[SCREENSHOT: `backend/plugins/green_team_plugin.py` — `before_tool_callback` checking quarantine flag]**

> "Green Team enforces the quarantine. Before every tool call, it checks the flag. If quarantine is active, it raises a RuntimeError — halting all further tool execution immediately. Session state is fully preserved for forensic analysis. This isn't bolted on after the fact — it's wired directly into the ADK plugin lifecycle."

---

### SEGMENT 8 — Export & Outro (10:15–10:45)

**[SCREENSHOT: Completed session — "Download PDF" and "Download DOCX" buttons visible]**

> "Export is fully client-side. PDF via the `pdf` and `printing` packages. DOCX via hand-rolled OOXML zipped with the `archive` package. No server round-trip."

**[SCREENSHOT: Downloaded PDF open — report with scores, concerns, recommendations visible]**

**[SCREENSHOT: Repo root in terminal — `ls` showing directory structure]**

> "Google ADK. Gemini 2.5 Pro and Flash. Google Search grounding. Pydantic structured output. FastAPI. Flutter Web. Riverpod. Two agentic security plugins.
>
> Five agents. Three rounds. One synthesized report."

---

## Screenshots Checklist

| # | What to Capture | Where |
|---|---|---|
| 1 | Full app — all three panels visible | `http://localhost:8080` |
| 2 | All 5 persona cards | Left panel |
| 3 | Topic input with text | Left panel |
| 4 | Moderator intro in thread | Center panel |
| 5 | 5 agent bubbles loading simultaneously | Center panel |
| 6 | Moderator follow-up questions | Center panel |
| 7 | Discussion phase — agents referencing each other | Center panel |
| 8 | Score panel updating live | Right panel |
| 9 | Final report card — score + categories + recommendation | Center panel |
| 10 | `graph.py` — fan-out loop with `_p=p` capture | Code editor |
| 11 | `graph.py` — JoinNode barrier | Code editor |
| 12 | `personas.py` — one persona definition | Code editor |
| 13 | `state.py` — FocusGroupState TypedDict | Code editor |
| 14 | `stream.py` — SSE event generator | Code editor |
| 15 | `session_notifier.dart` — `_applyEvent` | Code editor |
| 16 | `blue_team_plugin.py` — trust score logic | Code editor |
| 17 | `green_team_plugin.py` — quarantine check | Code editor |
| 18 | Export buttons on completed session | App UI |
| 19 | Downloaded PDF open with report | PDF viewer |
| 20 | `ls` of repo root | Terminal |

---

> **Recording tip:** Run a full session before recording so you know the output for your chosen topic. "AI-powered meal planning subscription service" generates good disagreement between Marcus and Zoe and is concrete enough for judges to follow without domain knowledge.
