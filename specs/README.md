# specs/

This directory is the authoritative behavioral source of truth for the Synthetic Market Intelligence Platform. Code must conform to specs — not the other way around.

Specs are documentation-only. No test runner executes them. They exist to give AI agents and engineers precise, unambiguous descriptions of how the system must behave, before any code is written or changed.

---

## How to Read Specs

BDD scenarios use the **State > Action > Outcome** mental model:

- **Given** — preconditions: the system state that must be true before anything happens
- **When** — the single triggering action
- **Then** — the observable outcome; what a caller or user can verify

Never infer intent from code. Read the spec for a domain first, then read the code. If they conflict, the spec wins — flag and fix the code.

---

## Naming Conventions

| Extension | Artifact type | When to use |
|-----------|---------------|-------------|
| `.feature` | Gherkin BDD scenarios | Behavioral requirements from a user or agent perspective |
| `.schema.yaml` | Structural data contract | Shape of internal objects: fields, types, nullability, merge semantics |
| `.contract.yaml` | HTTP API contract | Request/response shape, required fields, status codes, enums |

Each file opens with a comment header:

```
# domain: <folder name>
# maps-to: <source file(s) this spec governs>
# constraint: <hard invariant that must not be broken>
```

---

## Domain Folders

| Folder | What it covers |
|--------|----------------|
| `session/` | Session lifecycle, FocusGroupState schema, API contracts |
| `agents/` | Persona definitions, agent phase behavior |
| `stream/` | SSE connection lifecycle, StreamEvent schema |
| `security/` | Blue Team / Green Team plugin behavior, trust score schema |
| `workflow/` | ADK graph topology: nodes, phases, fan-out/fan-in edges |

---

## Agent Consumption Rules

1. Read the domain folder for your assigned domain before writing or modifying any code.
2. If a spec conflicts with existing code, the spec wins — flag the discrepancy and fix the code.
3. Do not modify a spec to match existing code. Modify the spec only if the requirement has genuinely changed, and document why in the commit message.
4. When adding a new feature, write or update the relevant spec first, then implement.
