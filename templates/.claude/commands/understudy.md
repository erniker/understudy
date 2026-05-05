---
name: understudy
description: "Explain what understudy is, its capabilities, available roles, commands, and how to use the team"
---

You are in a project configured with **understudy** — a system that turns
a single AI assistant into a complete development team with specialized
roles, guardrails, and persistent cross-session memory.

Read the following files (skip any that don't exist) and then answer the
user's question about what understudy provides and how to use it:

1. `AGENTS.md` — team definition and role assignments
2. `docs/team-roster.md` — active team members
3. `understudy.yaml` — project configuration (platforms, models, roles)

Then provide the following overview:

## What is understudy?

Understudy deploys AI team configurations for GitHub Copilot, Claude Code,
and Cursor. Each agent has a defined role, guardrails, and context.

## Available roles

### Core roles (always deployed)
| Role | Focus |
|------|-------|
| **Architect** | System design, APIs, databases, trade-offs, ADRs |
| **Backend** | Services, business logic, data contracts |
| **Frontend** | UI, accessibility, UX, state management |
| **DevOps** | CI/CD, containers, IaC, cloud, deploys |
| **Security** | Threat modeling, input validation, secrets, OWASP |
| **QA Engineer** | Test plans, unit/integration/E2E, quality gates |

### Optional roles (add with `--add-member`)
| Role | Focus |
|------|-------|
| **Data Engineer** | ETL/ELT, warehouses, streaming, data governance |
| **Git Specialist** | Git workflows, branch policies, PR hygiene |
| **ML Engineer** | ML models, MLOps, LLMs, RAG |
| **Mobile Engineer** | iOS/Android, React Native, Flutter |
| **Repo Documenter** | Codebase docs, architecture, onboarding |
| **Shell Scripting** | Bash/sh automation, cross-platform scripts |
| **SRE** | SLOs, observability, incident response |
| **Tech Writer** | API docs, tutorials, Diataxis framework |

## Available slash commands

| Command | What it does |
|---------|-------------|
| `/start-session` | Load project context (session log, spec, decisions) |
| `/end-session` | Summarize work done and update session log |
| `/design-feature` | Architect a new feature with the Architect role |
| `/security-review` | Run a security review on a file or component |
| `/understudy` | This command — explain capabilities |

If **caveman mode** is enabled, also:

| Command | What it does |
|---------|-------------|
| `/compress` | Compress a Markdown file to save tokens |
| `/restore` | Restore a compressed file from backup |

## Persistent memory (cross-session)

| File | Purpose |
|------|---------|
| `docs/spec.md` | Living project requirements |
| `docs/decisions.md` | Architectural Decision Records |
| `docs/session-log.md` | What was done and what's pending |
| `docs/team-roster.md` | Active team members and roles |

## Recommended workflow

1. **Start** — `/start-session` to load context
2. **Spec first** — Write requirements in `docs/spec.md`
3. **Design** — Architect designs, Security reviews threats
4. **Build** — Backend + Frontend implement in parallel
5. **Test** — QA writes and runs tests
6. **Deploy** — DevOps handles infra and CI/CD
7. **End** — `/end-session` to save progress

## Configuration

Project settings live in `understudy.yaml`. You can customize:
- Which platforms to deploy (copilot, claude, cursor)
- Model assignments per role
- Guardrails mode (split vs embedded)
- Session auto-read and auto-update behavior

---

If the user asked a specific question (`$ARGUMENTS`), answer it based on
the context above. If they just invoked `/understudy` without a question,
present the full overview.
