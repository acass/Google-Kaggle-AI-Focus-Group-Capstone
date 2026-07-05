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