# Copilot Project Instructions — {{PROJECT_NAME}}
#
# ┌─────────────────────────────────────────────────────────────┐
# │  TUTORIAL: What is .github/copilot-instructions.md?        │
# │                                                             │
# │  This file is LOADED AUTOMATICALLY by Copilot CLI          │
# │  every time you open a session in this repository.         │
# │  You don't need to run /agent or /instructions for it      │
# │  to apply — it is always active.                           │
# │                                                             │
# │  Use it to:                                                 │
# │  - Give general project context to ALL agents              │
# │  - Define global rules that apply regardless of role       │
# │  - Establish project conventions                           │
# │  - Indicate where to find key documentation                │
# │                                                             │
# │  Difference from AGENTS.md:                                │
# │  - copilot-instructions.md = global context, always on     │
# │  - AGENTS.md = selectable roles via /agent                 │
# │                                                             │
# │  Difference from .github/instructions/*.instructions.md:   │
# │  - copilot-instructions.md = applies to ALL                │
# │  - *.instructions.md = modular, toggleable instructions    │
# │    via /instructions                                       │
# └─────────────────────────────────────────────────────────────┘

## Project

- **Name**: {{PROJECT_NAME}}
- **Description**: {{PROJECT_DESCRIPTION}}
- **Main stack**: {{TECH_STACK}}
- **Repository**: {{REPOSITORY_URL}}
- **Project Manager**: {{TEAM_LEAD}}

## Team context

This project uses the **Understudy** system: a team of specialized AI agents.
Each agent has a defined role in `AGENTS.md` and detailed instructions in
`.github/instructions/<role>.instructions.md`.

Available roles:
- **Architect** — Solution design and architectural decisions
- **Backend** — API, service and business logic implementation
- **Frontend** — User interfaces and experience
- **DevOps** — Infrastructure, CI/CD and operations
- **Security** — Security integrated throughout the cycle
- **QA** — Testing and software quality (.NET, Node.js, Python)

## Spec-Driven Development

This project follows **Spec-Driven Development**:
1. Before writing code, the specification is documented in `docs/spec.md`
2. The spec must be approved by the PM before starting
3. Any scope change is first reflected in the spec

## Mandatory context files

| File | Purpose |
|---|---|
| `docs/spec.md` | Project specification — the source of truth |
| `docs/decisions.md` | Architecture Decision Records (ADR) |
| `docs/session-log.md` | Session log — read at the start of each session |
| `docs/team-roster.md` | Active team roster and capabilities |

## Global rules

### At the start of a session
1. **Always** read `docs/session-log.md` to know what was done before
2. **Always** read `docs/spec.md` for project context
3. **Always** read `docs/decisions.md` for decisions already made
4. Before working, confirm your understanding of the current state

### At the end of a session
1. Update `docs/session-log.md` with:
   - What was done in this session
   - What is still pending
   - Decisions made
   - Blockers identified
2. This ensures the next session (another day, another time) has full context

### Code standards
- Readable and maintainable code for any team member
- Single-responsibility functions
- Business domain names, not generic names
- Explicit error handling with context in messages
- No hardcoded secrets — use vault/env vars
- No dead code or TODO comments in commits

### Project structure
```
{{PROJECT_NAME}}/
├── .github/
│   ├── copilot-instructions.md     ← this file
│   ├── instructions/               ← instructions per role
│   └── prompts/                    ← reusable prompts (VS Code)
│       ├── start-session.prompt.md
│       ├── end-session.prompt.md
│       ├── design-feature.prompt.md
│       └── security-review.prompt.md
├── AGENTS.md                       ← team definition
├── understudy.yaml               ← model and scoping configuration
├── docs/                           ← project documentation
│   ├── spec.md
│   ├── decisions.md
│   ├── session-log.md
│   └── team-roster.md
├── src/                            ← source code
├── tests/                          ← tests
└── scripts/                        ← automation scripts
```

## Configuration and models

Recommended models per role are defined in `understudy.yaml` at the project root.
To change the model for a role, edit that file:

```yaml
models:
  architect: "claude-opus-4.6"       # deep reasoning for design
  backend: "claude-sonnet-4.5"       # quality/speed balance
  frontend: "claude-sonnet-4.5"
  devops: "claude-haiku-4.5"         # economical for structured tasks
  security: "claude-sonnet-4.5"
  qa-engineer: "claude-sonnet-4.5"   # test plans and test code
```

In **Copilot CLI**: use `/model` to select the recommended model for the active role.
In **VS Code**: use the model picker in the Copilot Chat panel.

<!-- GUARDRAILS_START -->
{{GUARDRAILS_SECTION}}
<!-- GUARDRAILS_END -->

## CLI and VS Code compatibility

This project works with both Copilot CLI and VS Code without changes.

**In VS Code:**
- Instructions from `.github/instructions/*.instructions.md` are applied
  automatically based on the type of file you are editing (frontmatter `applyTo`)
- Prompts from `.github/prompts/` are available as reusable flows
- `copilot-instructions.md` (this file) is loaded automatically

**In Copilot CLI:**
- Use `/agent` to select a team member
- Use `/instructions` to enable/disable instructions per role
- Use `/model` to change the model based on the task
