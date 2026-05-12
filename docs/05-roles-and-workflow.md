# 5. Roles & Spec-Driven Development

This chapter explains how Understudy's role system works and the
spec-driven workflow that ties everything together.

## How roles work

Every Understudy deployment ships 6 **core roles** plus any **optional
roles** you select. Each role is a Markdown file with:

- **Identity** — who the agent is, their code name and motto
- **Expertise** — specific technologies and domains
- **How they work** — step-by-step process including context files
- **Standards** — code quality, naming, error handling rules
- **Team interaction** — which agents they receive from and deliver to

### Core roles (always deployed)

| Role | Code name | Focus |
|---|---|---|
| 🏛️ Architect | Architect | System design, APIs, databases, trade-offs, ADRs |
| ⚙️ Backend | Backend | Services, business logic, data contracts |
| 🎨 Frontend | Frontend | UI, accessibility, UX, state management |
| 🚀 DevOps | DevOps | CI/CD, containers, IaC, cloud, deploys |
| 🔒 Security | Security | Threat modeling, input validation, secrets, OWASP |
| 🧪 QA | QA | Test plans, unit/integration/E2E, quality gates |

### Optional roles (from `roles/`)

| Role | When to use |
|---|---|
| 📊 data-engineer | ETL/ELT, warehouses, streaming, data governance |
| 🌿 git-specialist | Git workflows, branch policies, PR hygiene |
| 📱 mobile-engineer | iOS, Android, React Native, Flutter |
| 🤖 ml-engineer | ML models, MLOps, LLMs, RAG, responsible AI |
| 📖 repo-documenter | Codebase understanding, architecture docs, onboarding |
| 🐚 shell-scripting | Bash/sh automation, cross-platform scripting |
| 📝 tech-writer | Technical docs, API reference, tutorials |
| 🧭 sre | SLOs, observability, incidents, chaos engineering |
| 🐉 caveman | Token-efficient prose (opt-in, see [chapter 10](10-caveman-mode.md)) |

### Auto-deployed roles

The wizard includes some optional roles automatically:

| Role | Condition |
|---|---|
| `git-specialist` | Always included |
| `repo-documenter` | Always included |
| `shell-scripting` | Included when `*.sh`, `*.bash` or `*.zsh` files are detected |

### Adding and creating roles

```bash
# Pick from the existing catalog
understudy --add-member

# Create a brand new role from scratch
understudy --create-role
```

`--create-role` walks you through an interactive wizard that asks for the
role name, title, description, areas of expertise and a motto. The
resulting file is saved in `roles/` and is available for every future
deployment — not just the current project.

### Role file format

Every role file (`.instructions.md`) follows the same structure:

```markdown
# Role Title — Role Title Instructions

## Identity
You are the Role Title of the Understudy team. Your code name is **RoleName**.
Description of what you do.
Your motto: "..."

## Expertise
- Technology 1
- Technology 2

## How you work
1. Read docs/spec.md
2. Consult docs/decisions.md
3. ...

## Standards
- Clean code
- Error handling
- ...

## Team interaction
- ← Architect: You receive design decisions
- → Security: You consult on security
- ← PM: You resolve requirements questions
```

You can create role files manually — just follow this format and place them
in `roles/`.

## How roles are deployed per platform

The same role file is adapted to each platform's format:

| Platform | Where the role lives | How it's activated |
|---|---|---|
| Copilot CLI | `.github/instructions/<role>.instructions.md` | `/instructions` toggle |
| VS Code | `.github/instructions/<role>.instructions.md` | Auto-applied by `applyTo` glob |
| Claude Code | `.claude/agents/<role>.md` (with YAML frontmatter: name, model, tools) | Invoke the agent by name |
| Cursor | `.cursor/agents/<role>.md` (with YAML frontmatter: name, model) | Agent panel |

The wizard handles the conversion automatically. For Claude and Cursor, it
wraps the role content in a frontmatter block with the recommended model
from `understudy.yaml`.

## The `applyTo` system (VS Code)

In VS Code, each role's `.instructions.md` has a YAML frontmatter:

```yaml
---
applyTo: "src/api/**,src/application/**"
---
```

When you open or edit a file that matches the glob, VS Code auto-applies
that role's instructions. This means you don't have to switch roles
manually — the right persona activates based on what you're editing.

Default `applyTo` patterns (configurable in `understudy.yaml → roles.*`):

| Role | Default `applyTo` |
|---|---|
| Architect | `docs/**` |
| Backend | `src/api/**,src/application/**,src/domain/**,src/infrastructure/**` |
| Frontend | `src/components/**,src/features/**,src/hooks/**,src/ui/**,**/*.tsx,**/*.jsx` |
| DevOps | `infra/**,pipelines/**,docker/**,.github/workflows/**,**/*.tf` |
| Security | _(empty — manual activation only)_ |
| QA | `tests/**,**/*.test.*,**/*.spec.*,**/*Tests*/**` |
| Guardrails | `**` _(always active on every file)_ |

## Spec-Driven Development

Spec-Driven Development is Understudy's workflow model. The idea is
simple: **agree on what to build before building it**.

### The spec lifecycle

```
1. PM writes initial requirements
        │
        ▼
2. Architect designs solution
   (proposes alternatives, writes ADR)
        │
        ▼
3. Security reviews the design
   (threat model, authZ, PII)
        │
        ▼
4. PM approves the spec
        │
   ┌────┴────┐
   ▼         ▼
5. Backend   Frontend
   implements API    implements UI
   │         │
   └────┬────┘
        ▼
6. QA writes and runs tests
        │
        ▼
7. DevOps deploys
        │
        ▼
8. Security does final review
        │
        ▼
9. Session log updated
```

### The three context files

These files are Understudy's **persistent memory** — they survive between
sessions and keep every agent aligned:

| File | Purpose | Updated by |
|---|---|---|
| `docs/spec.md` | Requirements and scope (living contract) | PM + Architect |
| `docs/decisions.md` | ADR log — what was decided and why | All agents (mainly Architect) |
| `docs/session-log.md` | What was done, what's pending | Whoever ends the session |

A fourth file, `docs/team-roster.md`, tracks which agents are active in the
project and where their files live.

### Session protocol

**Start of session:**

```
Read docs/session-log.md, docs/spec.md and docs/decisions.md
and tell me where we are.
```

On VS Code this is the `start-session.prompt.md` prompt. On Claude Code,
`/project:start-session`. On Copilot CLI and Cursor, paste the message.

**End of session:**

```
Update docs/session-log.md with what we did today,
any new decisions and pending items.
```

On VS Code: `end-session.prompt.md`. On Claude Code:
`/project:end-session`.

### ADR format (Architecture Decision Records)

When a decision is made, the agent records it in `docs/decisions.md`:

```markdown
## ADR-0005: Use PostgreSQL for customer data

**Date:** 2026-05-12
**Status:** Approved
**Context:** We need a relational store for customer records with ACID guarantees.
**Decision:** PostgreSQL 16 with pgvector for future embedding search.
**Alternatives considered:**
- MongoDB — rejected (schema flexibility not needed, ACID harder)
- MySQL — rejected (pgvector not available)
**Consequences:** Backend needs pg driver; DevOps adds PG to Terraform.
```

### When is spec not required?

The guardrails define four exceptions where code can be written without a
full approved spec:

1. **Bugfixes** — corrections of errors in existing code
2. **Emergencies** — production hotfixes (document post-mortem)
3. **Dependencies/CVE** — vulnerability updates
4. **Config/metadata** — minor configuration changes

In all cases, document what you did in `docs/session-log.md`.

## Sub-agents (parallel work)

On platforms that support it (Copilot CLI, VS Code, Claude Code), you can
launch parallel sub-agents:

```
Implement the login feature end to end. Use one sub-agent for Backend
(API + tests) and another for Frontend (form + tests). Both must follow
docs/decisions.md ADR-0005.
```

The AI splits the work into independent tasks that run in parallel and
converge their results. This reduces wall time when pieces are independent
(e.g. Backend API and Frontend form can be built simultaneously).

---

Next: [Cross-Platform Workflows](08-cross-platform-workflows.md)
