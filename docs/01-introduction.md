# 1. Introduction and Core Concepts

Understudy is a project scaffolding system that turns a single AI assistant
(Copilot, Claude, Cursor) into a full software team with well-defined roles,
standards and guardrails.

Instead of talking to a generic assistant, you talk to specialized **agents**:
Architect, Backend, Frontend, DevOps, Security, QA — plus optional members like
Mobile, Data, ML, SRE and Tech Writer.

## The mental model

```
You (Product Manager)
        │
        ▼
  One AI assistant ── wears the hat of ──►  Architect / Backend / Frontend / …
        │                                         │
        └── reads and writes ──► docs/ (spec, decisions, session-log)
                                 AGENTS.md / CLAUDE.md / .cursor/…
                                 guardrails (always on)
```

## Key concepts in one paragraph each

**Agent.** A specialized persona the assistant adopts. Each agent has domain
knowledge, behavior rules, a communication style and a known scope. You pick
an agent (or the assistant picks one) depending on the task.

**Spec-Driven Development.** Before writing code, you agree on a spec
(`docs/spec.md`). The Architect uses it to design; Backend and Frontend use
it to implement; QA uses it to test. The spec is a living contract, not
paperwork.

**Persistent memory.** AI sessions don't remember previous conversations.
Understudy uses three files as external memory:

- `docs/spec.md` — what needs to be done
- `docs/decisions.md` — what was decided and why (ADRs)
- `docs/session-log.md` — what was done and what is pending

**Guardrails.** Non-negotiable safety and behavior rules (no secrets, no
destructive ops without confirmation, no production changes without change
control, spec-first, etc.). They are deployed automatically and, on Claude
Code, enforced by a hook that blocks dangerous commands.

**Wizard.** After installation, you run Understudy with the `understudy`
command. Under the hood it launches the same deployment wizard (`wizard.sh`),
which asks a handful of questions and generates all the platform-specific
files (Copilot, Claude, Cursor) with your project data already filled in. It
also integrates into existing projects without touching your code, and detects
monorepos automatically. If you are using a manual `git clone`, run
`./wizard.sh` from the cloned repo instead.

**Roles catalog.** The 6 core roles always ship (Architect, Backend,
Frontend, DevOps, Security, QA). Optional roles live in `roles/` and you can
add more with `understudy --add-member` or create your own with
`understudy --create-role`. If you are using a manual clone, replace
`understudy` with `./wizard.sh`.

## The 6 core roles

| Role | Focus |
|---|---|
| 🏛️ Architect | System design, APIs, databases, trade-offs, ADRs |
| ⚙️ Backend | Services, business logic, data contracts |
| 🎨 Frontend | UI, accessibility, UX, state management |
| 🚀 DevOps | CI/CD, containers, IaC, cloud, deploys |
| 🔒 Security | Threat modeling, input validation, secrets, OWASP |
| 🧪 QA | Test plans, unit/integration/E2E, quality gates |

## Optional roles (`roles/`)

| Role | When to use |
|---|---|
| 📊 data-engineer | ETL/ELT, warehouses, streaming, data governance |
| 🌿 git-specialist | Git workflows, branch policies, PR hygiene, release discipline |
| 📱 mobile-engineer | iOS, Android, React Native, Flutter |
| 🤖 ml-engineer | ML/LLMs, RAG, MLOps, responsible AI |
| 🐚 shell-scripting | Bash/sh automation, cross-platform scripting, ShellCheck |
| 📝 tech-writer | Docs, API reference, tutorials, Diataxis |
| 🧭 sre | SLOs, observability, incidents, chaos engineering |

> **Auto-deploy:** `git-specialist` is always included when you run the wizard.
> `shell-scripting` is added automatically when `*.sh`, `*.bash` or `*.zsh`
> files are detected in your project.

## Files Understudy produces

```
your-project/
├── AGENTS.md                     # Team definition (Copilot CLI + VS Code)
├── CLAUDE.md                     # Claude global instructions
├── understudy.yaml               # Project-level config and overrides
├── docs/
│   ├── spec.md                   # Requirements (living contract)
│   ├── decisions.md              # ADR log
│   ├── session-log.md            # Cross-session memory
│   └── team-roster.md            # Active team for this project
├── .github/
│   ├── copilot-instructions.md   # Always-on instructions for Copilot
│   ├── instructions/             # Role files (+ guardrails)
│   └── prompts/                  # Reusable prompts (start/end session, etc.)
├── .claude/
│   ├── agents/                   # One file per role with model in frontmatter
│   ├── commands/                 # /project:<name> slash commands
│   ├── hooks/guardrails-check.sh # Blocks destructive operations
│   └── settings.json             # Permissions + hook wiring
└── .cursor/
    ├── agents/                   # Role agents (Agent panel)
    └── rules/                    # Global rules + guardrails (always-on)
```

If you enable **local-only mode** during the wizard, Understudy also appends
the affected paths to the project's `.gitignore` so AI config and/or session
memory stay out of git. See
[Configuration → Local-only mode](09-configuration.md#local-only-mode).

---

Next: [Quick Start](02-quick-start.md)
