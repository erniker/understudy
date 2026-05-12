# Tutorial: GitHub Copilot CLI — Full Feature Walkthrough

> A hands-on guide that walks you through **every feature** Understudy
> provides for Copilot CLI, using a real-world example project.

## The example project: TaskFlow API

Throughout this tutorial you will build **TaskFlow** — a task management REST
API with user authentication. This is intentionally simple so you can focus
on learning the AI workflow, not the domain.

**Stack:** Node.js + Express + PostgreSQL  
**Goal:** A CRUD API for tasks with user auth, deployed with Docker.

---

## Part 1 — Setup and deployment

### 1.1 Create the project folder

```bash
mkdir taskflow && cd taskflow
git init
```

### 1.2 Deploy Understudy

```bash
understudy
```

The wizard asks 9 questions. Answer like this for the tutorial:

| # | Question | Answer |
|---|---|---|
| 1 | Project name | `taskflow` |
| 2 | Short description | `Task management REST API` |
| 3 | Project manager | Your name |
| 4 | Tech stack | `Node.js + Express + PostgreSQL + Docker` |
| 5 | Repository URL | `https://github.com/you/taskflow` |
| 6 | Guardrails mode | `split` (recommended) |
| 7 | Platforms | `Copilot` |
| 8 | Git: commit files? | `y` |
| 9 | Git: local-only config? | `n` |

> **Shortcut:** If you already have a repo with a `package.json` and a
> remote configured, use `understudy --here` to auto-infer all values.

### 1.3 Verify the generated files

```bash
ls -la
```

You should see:

```
AGENTS.md                                 ← Team definition
.github/copilot-instructions.md           ← Global instructions (always active)
.github/instructions/
    architect.instructions.md
    backend.instructions.md
    frontend.instructions.md
    devops.instructions.md
    security.instructions.md
    qa-engineer.instructions.md
    guardrails.instructions.md            ← Full guardrails (always active)
    git-specialist.instructions.md        ← Auto-deployed
    repo-documenter.instructions.md       ← Auto-deployed
.github/prompts/
    start-session.prompt.md
    end-session.prompt.md
    design-feature.prompt.md
    security-review.prompt.md
    understudy.prompt.md
docs/
    spec.md
    decisions.md
    session-log.md
    team-roster.md
```

> **What each file does:**
>
> - `AGENTS.md` — Copilot reads this automatically. It defines the agents
>   you can select with `/agent`.
> - `.github/copilot-instructions.md` — Loaded automatically in every
>   conversation. Contains project context + critical guardrails.
> - `.github/instructions/*.instructions.md` — Detailed per-role
>   instructions. Toggled with `/instructions`.
> - `docs/*.md` — Persistent memory. The AI reads/writes these to maintain
>   context across sessions.

---

## Part 2 — Starting your first session

### 2.1 Open Copilot CLI

```bash
copilot
```

Copilot loads `AGENTS.md` and `.github/copilot-instructions.md` automatically.
You'll notice it already knows your project name, stack and team rules.

### 2.2 Feature: `/agent` — See available agents

```text
You: /agent
```

Copilot shows the list of agents from `AGENTS.md`:

```
Available agents:
  • Architect    — Solutions Architect
  • Backend      — Backend Developer
  • Frontend     — Frontend Developer
  • DevOps       — DevOps Engineer
  • Security     — Security Expert
  • QA           — QA Engineer
```

### 2.3 Feature: Start a session (reading context)

```text
You: Read docs/session-log.md, docs/spec.md and docs/decisions.md.
     Summarize the current state of the project and suggest next steps.
```

Since the project is new, the agent will tell you the docs are empty and
suggest writing a spec first. This is exactly what Understudy's
**spec-first** rule enforces.

---

## Part 3 — Designing with the Architect

### 3.1 Feature: `/agent Architect` — Switch agent

```text
You: /agent Architect
```

Copilot adopts the Architect's personality: system design, trade-offs, ADRs.

### 3.2 Feature: `/instructions` — Load detailed role instructions

```text
You: /instructions
```

Select `architect.instructions.md`. This loads the Architect's full
expertise list, working process and output standards into context.

### 3.3 Feature: `/model` — Choose the right model

```text
You: /model
```

Select **Claude Opus** (or the most capable model available). The Architect
benefits from deeper reasoning for system design.

> **Rule of thumb from `understudy.yaml`:**
> - Architect / Security → Opus (complex reasoning)
> - Backend / Frontend → Sonnet (good speed/quality balance)
> - Quick tasks → Haiku (fast and cheap)

### 3.4 Write the spec

```text
You: I need a REST API for task management. Features:
     - User registration and login (JWT)
     - CRUD tasks (title, description, status, due date)
     - Assign tasks to users
     - Filter by status, assignee, due date
     - PostgreSQL database
     - Docker for deployment

     Write this as a formal spec in docs/spec.md following the team's
     spec format.
```

The Architect writes `docs/spec.md` with requirements, constraints, NFRs
and acceptance criteria.

### 3.5 Design the architecture (ADR)

```text
You: Propose 2-3 architectural alternatives for this API.
     Evaluate trade-offs (complexity, scalability, team familiarity).
     Recommend one and document it as ADR-0001 in docs/decisions.md.
```

The Architect produces:
- Alternative A: Express + Sequelize ORM
- Alternative B: Express + raw SQL (pg)
- Alternative C: Fastify + Prisma

It recommends one, writes `docs/decisions.md` with the ADR in the standard
format: Title, Status, Context, Options, Decision, Consequences.

---

## Part 4 — Security review

### 4.1 Switch to Security agent

```text
You: /agent Security
You: /instructions
```

Select `security.instructions.md`.

### 4.2 Feature: Security threat modeling

```text
You: Review the architecture in docs/decisions.md ADR-0001.
     Produce a threat model covering:
     - Authentication flows (JWT)
     - Input validation
     - SQL injection surface
     - Authorization (can user X edit user Y's tasks?)
     - Secrets management
     Add security requirements to docs/spec.md.
```

The Security agent reviews the design and adds constraints like:
- JWT must expire in ≤ 1h
- Refresh tokens stored httpOnly
- Parameterized queries only (no string concatenation)
- Rate limiting on auth endpoints
- Input validation with Joi/Zod

---

## Part 5 — Implementation with sub-agents

### 5.1 Feature: Sub-agents (parallel work)

This is one of Copilot CLI's most powerful features. You can ask it to
split work across multiple internal agents that run in parallel.

```text
You: Implement TaskFlow following ADR-0001 and the security requirements.
     Split the work:

     Sub-agent 1 (Backend):
     - Set up Express project structure
     - Database schema (migrations)
     - Auth endpoints (register, login, refresh)
     - Task CRUD endpoints
     - Input validation with Zod
     - Error handling middleware

     Sub-agent 2 (Frontend):
     - Not applicable yet — skip for now

     Sub-agent 3 (DevOps):
     - Dockerfile
     - docker-compose.yml (app + postgres)
     - .env.example

     Both must follow docs/decisions.md ADR-0001.
```

Copilot launches internal task agents that work in parallel. You'll see
them produce files simultaneously.

### 5.2 Switch to Backend for refinement

```text
You: /agent Backend
You: /instructions
```

Select `backend.instructions.md`.

```text
You: Review the generated code. Ensure:
     - All endpoints have input validation
     - Error responses follow a consistent format
     - Database queries use parameterized statements
     - Auth middleware protects /tasks routes
```

### 5.3 Feature: `/diff` — Review changes

```text
You: /diff
```

Shows all pending file modifications. Review before accepting.

---

## Part 6 — QA: Testing

### 6.1 Switch to QA

```text
You: /agent QA
You: /instructions
```

Select `qa-engineer.instructions.md`.

### 6.2 Write tests

```text
You: Create a test plan for TaskFlow. Then implement:
     1. Unit tests for auth service (register, login, token validation)
     2. Unit tests for task CRUD operations
     3. Integration tests for the full API (using supertest)
     4. Edge cases: expired tokens, invalid input, unauthorized access

     Use Jest as the test framework.
```

The QA agent produces:
- `tests/unit/auth.test.js`
- `tests/unit/tasks.test.js`
- `tests/integration/api.test.js`
- A test plan summary

---

## Part 7 — DevOps: CI/CD

### 7.1 Switch to DevOps

```text
You: /agent DevOps
You: /instructions
```

### 7.2 Add CI pipeline

```text
You: Create a GitHub Actions workflow for TaskFlow:
     - Lint (ESLint)
     - Unit tests
     - Integration tests (needs PostgreSQL service)
     - Build Docker image
     - Push to GHCR on main branch

     Follow the security guardrails (no secrets in code, use GitHub
     Secrets).
```

---

## Part 8 — Guardrails in action

### 8.1 What guardrails do

Guardrails are **always active** — Copilot loads them from
`.github/copilot-instructions.md` (critical subset) and
`guardrails.instructions.md` (full details).

### 8.2 Try to violate a guardrail

```text
You: Add a hardcoded database password in the config file.
     Use a literal string as the password.
```

The agent will **refuse** and explain:

> ⚠️ Guardrail violation: Security category — "No secrets, no bypass,
> mandatory input validation". Credentials must come from environment
> variables or a secrets manager, never hardcoded.

It will suggest using `process.env.DATABASE_PASSWORD` instead.

### 8.3 Try another violation

```text
You: Delete all migration files and the entire tests/ folder.
```

The agent will **refuse** or request confirmation:

> ⚠️ Guardrail violation: Destructive operations — "PM confirmation before
> deleting, purging or revoking". This is a bulk destructive operation.
> Please confirm with the project manager before proceeding.

### 8.4 Scope guardrail

```text
You: /agent Frontend
You: Modify the database schema in src/db/migrations/
```

The Frontend agent will note that database schema is Backend's domain and
either defer or ask for justification.

---

## Part 9 — Token management

### 9.1 Feature: `/compact` — Compress conversation

After a long session, your token count increases. Use:

```text
You: /compact
```

This compresses the conversation history while preserving key decisions.
Your actual project state is safe because it lives in `docs/session-log.md`.

### 9.2 Feature: `/context` — Check usage

```text
You: /context
```

Shows current token usage and which files are loaded. Useful to understand
if you're approaching limits.

---

## Part 10 — Ending the session

### 10.1 Update the session log

```text
You: Update docs/session-log.md with:
     - What we accomplished today
     - Decisions made (reference ADR-0001)
     - Open items / next steps
     - Any blockers
```

The agent writes a structured entry:

```markdown
## Session — 2026-05-12

### Completed
- Wrote spec (docs/spec.md)
- Designed architecture (ADR-0001: Express + Prisma)
- Security review and threat model
- Implemented auth + task CRUD
- Docker setup (Dockerfile + docker-compose)
- Test suite (unit + integration)
- CI/CD pipeline (GitHub Actions)

### Decisions
- ADR-0001: Express + Prisma over raw SQL (DX, type safety)

### Next steps
- Frontend (React)
- E2E tests
- Production deployment manifests

### Blockers
- None
```

### 10.2 Why this matters

Next time you (or a teammate) start a session, the AI reads
`session-log.md` and immediately knows the full project history — no need
to re-explain anything. This is Understudy's **persistent memory**.

---

## Part 11 — Adding team members

### 11.1 Feature: `--add-member`

Need a Data Engineer for analytics pipelines later?

```bash
understudy --add-member
```

Choose from the catalog:

```
Available roles:
  1) data-engineer
  2) mobile-engineer
  3) ml-engineer
  4) sre
  5) tech-writer
  ...
```

Select one and it's deployed to `.github/instructions/` and added to
`AGENTS.md`. Next time you open Copilot, `/agent` will show the new member.

### 11.2 Feature: `--create-role`

Need a role that doesn't exist?

```bash
understudy --create-role
```

The wizard asks for: name, title, description, expertise areas, motto.
It generates a `.instructions.md` file in `roles/` for reuse across all
your projects.

---

## Part 12 — Caveman mode (optional)

### 12.1 What is Caveman?

A token-efficient communication style. The AI drops filler words, articles,
and unnecessary prose while preserving code, paths and technical accuracy.
Saves 30-50% tokens per response.

### 12.2 Enable it

```bash
understudy --caveman
```

This deploys:
- `.github/instructions/caveman.instructions.md` (role, `applyTo: "**"`)

### 12.3 Use it

After enabling, the AI's responses become shorter:

**Normal:**
> I'll create a new Express middleware function that validates the JWT token
> from the Authorization header and attaches the decoded user payload to
> the request object.

**Caveman:**
> Creating JWT middleware → validates Authorization header, attaches decoded
> user to `req.user`.

Same accuracy, fewer tokens.

---

## Quick reference card

| Feature | Command / Action |
|---|---|
| Switch agent | `/agent <name>` |
| Load role details | `/instructions` → select file |
| Change model | `/model` → select |
| Compress tokens | `/compact` |
| See changes | `/diff` |
| Check token usage | `/context` |
| Parallel work | Ask for sub-agents in prompt |
| Start session | Read `docs/session-log.md`, `spec.md`, `decisions.md` |
| End session | Update `docs/session-log.md` |
| Add team member | `understudy --add-member` (in terminal) |
| Create new role | `understudy --create-role` (in terminal) |
| Enable caveman | `understudy --caveman` (in terminal) |
| Guardrails | Always active — no action needed |

---

## Next steps

- Try the [VS Code Copilot tutorial](vscode-copilot-tutorial.md) — same
  project, different workflow (auto-applied instructions, prompt files).
- Read [Cross-Platform Workflows](../08-cross-platform-workflows.md) to
  combine CLI and VS Code in the same project.
- See [Configuration Reference](../09-configuration.md) to customize
  models, guardrails mode and role settings.

---

[← Back to tutorials index](README.md) · [Next: VS Code Copilot →](vscode-copilot-tutorial.md)
