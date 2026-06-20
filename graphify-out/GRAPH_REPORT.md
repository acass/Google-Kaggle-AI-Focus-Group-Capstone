# Graph Report - .  (2026-06-20)

## Corpus Check
- Corpus is ~8,489 words - fits in a single context window. You may not need a graph.

## Summary
- 197 nodes · 298 edges · 25 communities (14 shown, 11 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.64)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Frontend UI Components|Frontend UI Components]]
- [[_COMMUNITY_Backend Agent Orchestration|Backend Agent Orchestration]]
- [[_COMMUNITY_Project Architecture & Concepts|Project Architecture & Concepts]]
- [[_COMMUNITY_Frontend Package Dependencies|Frontend Package Dependencies]]
- [[_COMMUNITY_TypeScript Configuration|TypeScript Configuration]]
- [[_COMMUNITY_Workflow Graph Builder|Workflow Graph Builder]]
- [[_COMMUNITY_SSE Stream API|SSE Stream API]]
- [[_COMMUNITY_App Layout & Fonts|App Layout & Fonts]]
- [[_COMMUNITY_Report Export Utilities|Report Export Utilities]]
- [[_COMMUNITY_Document Export Libraries|Document Export Libraries]]
- [[_COMMUNITY_ESLint Configuration|ESLint Configuration]]
- [[_COMMUNITY_Next.js Config|Next.js Config]]
- [[_COMMUNITY_PostCSS Config|PostCSS Config]]
- [[_COMMUNITY_File UI Icon|File UI Icon]]
- [[_COMMUNITY_Globe UI Icon|Globe UI Icon]]
- [[_COMMUNITY_Next.js Logo Asset|Next.js Logo Asset]]
- [[_COMMUNITY_Vercel Logo Asset|Vercel Logo Asset]]
- [[_COMMUNITY_Window UI Icon|Window UI Icon]]
- [[_COMMUNITY_React 19|React 19]]
- [[_COMMUNITY_Tailwind CSS v4|Tailwind CSS v4]]
- [[_COMMUNITY_Project Quick Reference|Project Quick Reference]]

## God Nodes (most connected - your core abstractions)
1. `compilerOptions` - 16 edges
2. `AI Focus Group` - 13 edges
3. `build_graph()` - 11 edges
4. `StreamEvent` - 9 edges
5. `Developer Guidelines (AGENTS.md)` - 9 edges
6. `ScoreSet` - 8 edges
7. `CreateSessionResponse` - 7 edges
8. `SessionStateResponse` - 7 edges
9. `FinalReport` - 7 edges
10. `FocusGroupState` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Frontend Developer Guidelines (AGENTS.md)` --references--> `Developer Guidelines (AGENTS.md)`  [EXTRACTED]
  frontend/AGENTS.md → AGENTS.md
- `Gemini 2.5 Pro (Moderator/Synthesizer)` --conceptually_related_to--> `Synthesis / Report Generation Phase`  [INFERRED]
  AGENTS.md → README.md
- `Gemini 2.5 Flash (Participants)` --conceptually_related_to--> `Independent Evaluation Phase`  [INFERRED]
  AGENTS.md → README.md
- `Parallel Fan-out Workflow (ADK)` --conceptually_related_to--> `Blind Voting Phase`  [INFERRED]
  AGENTS.md → README.md
- `Parallel Fan-out Workflow (ADK)` --conceptually_related_to--> `Independent Evaluation Phase`  [INFERRED]
  AGENTS.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Focus Group Discussion Protocol** — concept_independent_eval, concept_moderated_followup, concept_open_discussion, concept_blind_voting, concept_synthesis [EXTRACTED 1.00]

## Communities (25 total, 11 thin omitted)

### Community 0 - "Frontend UI Components"
Cohesion: 0.10
Nodes (27): Home(), AGENT_COLORS, AgentBubble(), getInitials(), PHASE_COLORS, PHASE_LABELS, Props, DiscussionThread() (+19 more)

### Community 1 - "Backend Agent Orchestration"
Cohesion: 0.13
Nodes (27): get_persona(), create_session(), get_session(), _run_session(), FocusGroupState, FocusGroupState, AgentPersona, FocusGroupState (+19 more)

### Community 2 - "Project Architecture & Concepts"
Cohesion: 0.11
Nodes (24): Backend Python Dependencies, AI Focus Group, Blind Voting Phase, FastAPI, Gemini 2.5 Flash (Participants), Gemini 2.5 Pro (Moderator/Synthesizer), Google ADK (Agent Development Kit), Independent Evaluation Phase (+16 more)

### Community 3 - "Frontend Package Dependencies"
Cohesion: 0.08
Nodes (23): dependencies, docx, jspdf, next, react, react-dom, devDependencies, eslint (+15 more)

### Community 4 - "TypeScript Configuration"
Cohesion: 0.10
Nodes (19): compilerOptions, allowJs, esModuleInterop, incremental, isolatedModules, jsx, lib, module (+11 more)

### Community 5 - "Workflow Graph Builder"
Cohesion: 0.36
Nodes (10): build_graph(), AgentPersona, AgentPersona, FocusGroupState, _build_persona_context(), make_discussion_response(), make_independent_response(), make_vote() (+2 more)

### Community 6 - "SSE Stream API"
Cohesion: 0.31
Nodes (5): _event_generator(), get_or_create_queue(), push_event(), stream_session(), Queue

### Community 7 - "App Layout & Fonts"
Cohesion: 0.40
Nodes (3): geistMono, geistSans, metadata

### Community 8 - "Report Export Utilities"
Cohesion: 0.80
Nodes (4): capitalize(), exportAsDocx(), exportAsPdf(), formattedDate()

### Community 9 - "Document Export Libraries"
Cohesion: 0.67
Nodes (3): docx Library (Client-side Word), PDF/DOCX Report Export, jsPDF (Client-side PDF)

## Knowledge Gaps
- **85 isolated node(s):** `AgentPersona`, `Workflow`, `ScoreSet`, `FocusGroupState`, `AgentPersona` (+80 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `build_graph()` connect `Workflow Graph Builder` to `Backend Agent Orchestration`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `StreamEvent` (e.g. with `CreateSessionRequest` and `CreateSessionResponse`) actually correct?**
  _`StreamEvent` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `AgentPersona`, `Workflow`, `ScoreSet` to the rest of the system?**
  _85 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Frontend UI Components` be split into smaller, more focused modules?**
  _Cohesion score 0.1021021021021021 - nodes in this community are weakly interconnected._
- **Should `Backend Agent Orchestration` be split into smaller, more focused modules?**
  _Cohesion score 0.13333333333333333 - nodes in this community are weakly interconnected._
- **Should `Project Architecture & Concepts` be split into smaller, more focused modules?**
  _Cohesion score 0.11231884057971014 - nodes in this community are weakly interconnected._
- **Should `Frontend Package Dependencies` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._