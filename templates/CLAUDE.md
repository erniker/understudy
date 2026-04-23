# {{PROJECT_NAME}} — Project Instructions

## Project

- **Name**: {{PROJECT_NAME}}
- **Description**: {{PROJECT_DESCRIPTION}}
- **Main stack**: {{TECH_STACK}}
- **Repository**: {{REPOSITORY_URL}}
- **Project Manager**: {{TEAM_LEAD}}

## Team context

This project uses the **Understudy** system: a team of specialized AI agents.
Each agent has a defined role in `.claude/agents/` with detailed instructions.

Available roles:
- **architect** — Solution design and architectural decisions
- **backend** — API, service and business logic implementation
- **frontend** — User interfaces and experience
- **devops** — Infrastructure, CI/CD and operations
- **security** — Security integrated throughout the cycle
- **qa** — Testing and software quality

To activate an agent, invoke it by name in Claude Code.

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
├── .claude/
│   ├── agents/                    ← agents per role
│   ├── commands/                  ← reusable commands
│   ├── hooks/                     ← guardrails hooks
│   └── settings.json              ← permissions and configuration
├── CLAUDE.md                      ← this file
├── understudy.yaml              ← model and scoping configuration
├── docs/                          ← project documentation
│   ├── spec.md
│   ├── decisions.md
│   ├── session-log.md
│   └── team-roster.md
├── src/                           ← source code
├── tests/                         ← tests
└── scripts/                       ← automation scripts
```

## Configuration and models

Recommended models per role are defined in `understudy.yaml` at the project root.
Each agent in `.claude/agents/` has its model configured in the frontmatter.

```yaml
models:
  architect: "claude-opus-4.6"       # deep reasoning for design
  backend: "claude-sonnet-4.5"       # quality/speed balance
  frontend: "claude-sonnet-4.5"
  devops: "claude-haiku-4.5"         # economical for structured tasks
  security: "claude-sonnet-4.5"
  qa-engineer: "claude-sonnet-4.5"   # test plans and test code
```

## Available commands

Use `/project:command-name` to run predefined commands:
- `/project:start-session` — Load project context at startup
- `/project:end-session` — Close session and update logs
- `/project:design-feature` — Design a new feature with the Architect
- `/project:security-review` — Security review of current changes

<!-- GUARDRAILS_START -->
{{GUARDRAILS_SECTION}}
<!-- GUARDRAILS_END -->
