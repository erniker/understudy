# Tutorial: GitHub Copilot CLI — Full Feature Walkthrough

> A complete, self-contained guide that walks you step by step through
> **every feature** Understudy provides for GitHub Copilot CLI.
> You do not need to read any other tutorial before this one.

---

## What you will learn

By the end of this tutorial you will have used:

- `/agent` — switch between AI personas (Architect, Backend, Security…)
- `/instructions` — load detailed role instructions into context
- `/model` — pick the best model for the task
- `/compact` — compress the conversation to save tokens
- `/diff` — review pending file changes
- `/context` — see token usage and loaded files
- Sub-agents — split work across parallel agents
- Guardrails — see how the AI refuses unsafe operations
- Session protocol — persistent memory across sessions
- `--add-member` / `--create-role` — extend the team
- Caveman mode — token-efficient responses

---

## What you need before starting

| Requirement | How to get it |
|---|---|
| A GitHub Copilot subscription | [github.com/features/copilot](https://github.com/features/copilot) |
| The `copilot` CLI | `gh extension install github/gh-copilot` or standalone binary |
| `bash` ≥ 4 | Comes with Linux/macOS. On Windows use Git Bash or WSL |
| `git` | Any recent version |

---

## Step 1 — Install Understudy

### Linux / macOS / Git Bash / WSL

Open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/erniker/understudy/main/install.ps1 | iex
```

> Requires **Git for Windows** (provides `bash.exe`). The installer detects it
> automatically and creates a PowerShell launcher that delegates to bash.

This downloads the latest release, installs it to `~/.understudy/` and adds
the `understudy` command to your PATH.

Close and re-open your terminal (or `source ~/.bashrc`) so the command is
available.

Verify:

```bash
understudy --help
```

You should see the usage information.

---

## Step 2 — Create the example project

We will build **TaskFlow** — a simple task management REST API. The project
is intentionally simple so you can focus on learning the AI workflow.

```bash
mkdir taskflow
cd taskflow
git init
```

---

## Step 3 — Deploy Understudy into the project

Run the wizard:

```bash
understudy
```

The wizard asks 9 questions. Answer like this:

| # | Question | What to enter |
|---|---|---|
| 1 | Project name | `taskflow` |
| 2 | Short description | `Task management REST API` |
| 3 | Project manager | Your name |
| 4 | Tech stack | `Node.js + Express + PostgreSQL + Docker` |
| 5 | Repository URL | `https://github.com/you/taskflow` (or leave blank) |
| 6 | Guardrails mode | `split` (press Enter for default) |
| 7 | Platforms | Select **Copilot** only |
| 8 | Git: commit files? | `y` |
| 9 | Git: local-only config? | `n` |

> **Shortcut:** If you already have a repo with a `package.json` and a git
> remote, you can use `understudy --here` to auto-infer all values instead
> of answering questions.

---

## Step 4 — Verify the generated files

```bash
find . -type f | sort
```

You should see these files:

```
./AGENTS.md
./.github/copilot-instructions.md
./.github/instructions/architect.instructions.md
./.github/instructions/backend.instructions.md
./.github/instructions/devops.instructions.md
./.github/instructions/frontend.instructions.md
./.github/instructions/git-specialist.instructions.md
./.github/instructions/guardrails.instructions.md
./.github/instructions/qa-engineer.instructions.md
./.github/instructions/repo-documenter.instructions.md
./.github/instructions/security.instructions.md
./.github/prompts/design-feature.prompt.md
./.github/prompts/end-session.prompt.md
./.github/prompts/security-review.prompt.md
./.github/prompts/start-session.prompt.md
./.github/prompts/understudy.prompt.md
./docs/decisions.md
./docs/session-log.md
./docs/spec.md
./docs/team-roster.md
```

### What each file does

| File/folder | Purpose | Loaded automatically? |
|---|---|---|
| `AGENTS.md` | Defines the team — names, roles, rules. Copilot reads it to know which agents exist. | ✅ Yes |
| `.github/copilot-instructions.md` | Global project instructions + critical guardrails. Always in context. | ✅ Yes |
| `.github/instructions/<role>.instructions.md` | Detailed instructions for each role (personality, expertise, standards). | ❌ On demand (`/instructions`) |
| `.github/instructions/guardrails.instructions.md` | Full guardrails (8 categories). | ❌ On demand (`/instructions`) |
| `.github/prompts/*.prompt.md` | Reusable prompts (only available in VS Code, not in CLI). | N/A in CLI |
| `docs/spec.md` | Project specification. The AI reads/writes it. | ❌ You ask for it |
| `docs/decisions.md` | Architecture Decision Records (ADRs). | ❌ You ask for it |
| `docs/session-log.md` | Session history — what happened, what's pending. | ❌ You ask for it |
| `docs/team-roster.md` | Team members and contact info. | ❌ You ask for it |

---

## Step 5 — Open Copilot CLI

```bash
copilot
```

Copilot starts and automatically loads:
- `AGENTS.md` — it knows which agents exist
- `.github/copilot-instructions.md` — project context + critical guardrails

You'll notice it already knows your project name, stack and team rules
without you telling it anything.

---

## Step 6 — Feature: `/agent` — List and switch agents

### 6.1 List available agents

Type:

```
/agent
```

Copilot shows the team from `AGENTS.md`:

```
Available agents:
  • Architect    — Solutions Architect
  • Backend      — Backend Developer
  • Frontend     — Frontend Developer
  • DevOps       — DevOps Engineer
  • Security     — Security Expert
  • QA           — QA Engineer
```

### 6.2 Switch to an agent

```
/agent Architect
```

Copilot adopts the Architect persona. From now on, it thinks like a
solutions architect: system design, trade-offs, ADRs, Mermaid diagrams.

### 6.3 What changes when you switch agents

| Before `/agent` | After `/agent Architect` |
|---|---|
| General assistant | System designer |
| No specific expertise | APIs, databases, cloud, DDD, CQRS |
| No output format | Produces ADRs, Mermaid diagrams, alternatives tables |
| No handoff awareness | Knows to consult Security, deliver to Backend |

---

## Step 7 — Feature: `/instructions` — Load role details

The agent definition in `AGENTS.md` gives the personality. But the full
expertise, working process and checklists are in the instruction files.

```
/instructions
```

You'll see a list of available instruction files:

```
1) architect.instructions.md
2) backend.instructions.md
3) devops.instructions.md
4) frontend.instructions.md
5) guardrails.instructions.md
6) qa-engineer.instructions.md
7) security.instructions.md
...
```

Select `architect.instructions.md`. This loads ~200 lines of detailed
instructions into context: the Architect's full expertise list, step-by-step
working process, output standards, and team interaction rules.

> **Tip:** You can load multiple instruction files. For example, load both
> `architect.instructions.md` and `guardrails.instructions.md`.

---

## Step 8 — Feature: `/model` — Choose the right model

```
/model
```

Select the model best suited for the current task:

| Task type | Recommended model | Why |
|---|---|---|
| Architecture design | Claude Opus / GPT-4o | Complex reasoning, trade-offs |
| Security review | Claude Opus | Deep analysis, threat modeling |
| Code implementation | Claude Sonnet / GPT-4o-mini | Good speed/quality balance |
| Quick fixes, formatting | Claude Haiku | Fast and cheap |

For the Architect, select **Claude Opus** (or the most powerful available).

> These model recommendations come from `understudy.yaml`. You can
> customize them per project.

---

## Step 9 — Session protocol: Start a session

The session protocol gives the AI persistent memory across sessions.
At the start of every work session, ask it to read the context files:

```
Read docs/session-log.md, docs/spec.md and docs/decisions.md.
Summarize the current state of the project and suggest next steps.
```

Since this is a brand new project, the agent will report:
- `docs/spec.md` is empty → needs requirements
- `docs/decisions.md` is empty → no architecture yet
- `docs/session-log.md` is empty → first session

It will suggest: **write a spec first**. This is exactly what Understudy's
**spec-first** team rule enforces.

---

## Step 10 — Write the project spec

Still using the Architect agent:

```
I need a REST API for task management. Features:
- User registration and login (JWT)
- CRUD tasks (title, description, status, due date)
- Assign tasks to users
- Filter by status, assignee, due date
- PostgreSQL database
- Docker for deployment

Write this as a formal spec in docs/spec.md. Include:
- Functional requirements (numbered)
- Non-functional requirements (performance, security)
- Constraints
- Acceptance criteria
```

The Architect writes a structured `docs/spec.md` with all sections.

---

## Step 11 — Design the architecture (ADR)

```
Propose 2-3 architectural alternatives for this API.
Evaluate trade-offs: complexity, scalability, team familiarity, ORM overhead.
Recommend one and document it as ADR-0001 in docs/decisions.md.
Use the standard ADR format: Title, Status, Context, Options, Decision, Consequences.
```

The Architect produces something like:

- **Option A:** Express + Sequelize ORM — easy, heavy
- **Option B:** Express + raw SQL (pg) — light, more boilerplate
- **Option C:** Express + Prisma — typed, modern, good DX

It recommends one (e.g., Prisma) with justification and writes the ADR.

---

## Step 12 — Security review of the design

### 12.1 Switch to the Security agent

```
/agent Security
/instructions
```

Select `security.instructions.md`.

### 12.2 Switch to a stronger model

```
/model
```

Select Opus (Security reviews benefit from deeper analysis).

### 12.3 Run the review

```
Review the architecture in docs/decisions.md ADR-0001.
Produce a threat model covering:
- Authentication flows (JWT lifetime, refresh tokens)
- Input validation surface
- SQL injection risks
- Authorization (can user X access user Y's tasks?)
- Secrets management (where are credentials stored?)
Add security requirements to docs/spec.md section "Non-functional requirements".
```

The Security agent adds constraints like:
- JWT must expire in ≤ 1h
- Refresh tokens stored httpOnly, rotated on use
- Parameterized queries only (no string concatenation)
- Rate limiting on auth endpoints (5 attempts/min)
- Input validation with schema library (Zod/Joi)

---

## Step 13 — Implement with the Backend agent

### 13.1 Switch agent and model

```
/agent Backend
/instructions
```

Select `backend.instructions.md`.

```
/model
```

Select **Sonnet** (good speed/quality for implementation).

### 13.2 Implement

```
Implement the TaskFlow API following ADR-0001 and the security requirements in docs/spec.md.
Set up:
- Express project structure (src/controllers, src/services, src/middleware)
- Database schema with Prisma (users, tasks tables)
- Auth endpoints: POST /register, POST /login, POST /refresh
- Task CRUD: GET/POST/PUT/DELETE /tasks
- Auth middleware protecting /tasks routes
- Input validation with Zod
- Error handling middleware (consistent JSON response format)
- Dockerfile + docker-compose.yml (app + postgres)
- .env.example (no real secrets)
```

The Backend agent creates all the files.

---

## Step 14 — Feature: `/diff` — Review pending changes

After the agent writes files, review what changed:

```
/diff
```

This shows all pending file modifications. Review before accepting.

---

## Step 15 — Feature: Sub-agents (parallel work)

This is one of Copilot CLI's most powerful features — and it's **exclusive
to the CLI** (not available in VS Code, Claude Code or Cursor).

You can ask Copilot to split work into parallel internal agents:

```
Implement these in parallel:

Sub-agent 1 (Backend):
- Complete the task filtering logic (by status, assignee, due date)
- Add pagination (limit/offset)

Sub-agent 2 (DevOps):
- Create .github/workflows/ci.yml (lint + test + build Docker)
- Add a test docker-compose with PostgreSQL service

Both must follow docs/decisions.md ADR-0001.
```

Copilot launches internal task agents that work simultaneously and merge
their results. This saves wall-clock time when tasks are independent.

> **When to use sub-agents:**
> - Backend + Frontend implementing simultaneously
> - Implementation + Tests in parallel
> - Code + Documentation at the same time
>
> **When NOT to use them:**
> - Tasks that depend on each other
> - When you need to review intermediate steps

---

## Step 16 — QA: Writing tests

### 16.1 Switch to QA

```
/agent QA
/instructions
```

Select `qa-engineer.instructions.md`.

### 16.2 Write tests

```
Create a test plan for TaskFlow. Then implement:
1. Unit tests for auth service (register, login, token validation)
2. Unit tests for task CRUD operations
3. Integration tests for the full API (using supertest)
4. Edge cases: expired tokens, invalid input, unauthorized access

Use Jest as the test framework. Follow the test plan.
```

---

## Step 17 — DevOps: CI/CD

### 17.1 Switch to DevOps

```
/agent DevOps
/instructions
```

Select `devops.instructions.md`.

### 17.2 Add CI pipeline

```
Create a GitHub Actions workflow for TaskFlow:
- Lint (ESLint)
- Unit tests
- Integration tests (needs PostgreSQL service)
- Build Docker image
- Push to GHCR on main branch

Follow the security guardrails: no secrets in code, use GitHub Secrets.
```

---

## Step 18 — Guardrails in action

Guardrails are safety rules that the AI always respects. They are loaded from
`.github/copilot-instructions.md` (critical subset, always active) and from
`guardrails.instructions.md` (full details, loaded via `/instructions`).

There are 8 categories:

| # | Category | What it protects |
|---|---|---|
| 1 | Security | No secrets in code, mandatory input validation |
| 2 | Scope | Each agent owns specific files, must justify crossing |
| 3 | Process | Spec-first (no code without spec) |
| 4 | Destructive | No bulk deletes without PM confirmation |
| 5 | Data/PII | No real data, synthetic only |
| 6 | Quality | Self-review, tests, proper naming |
| 7 | Environments | dev → staging → prod promotion order |
| 8 | Documentation | ADRs required, session-log updated |

### 18.1 Exercise: Security guardrail

```
Add a hardcoded database password in the config file.
Use a literal string as the password.
```

The agent **refuses**:

> ⚠️ Guardrail: Security — "No secrets, no bypass." Credentials must come
> from environment variables. I'll use `process.env.DATABASE_PASSWORD`.

### 18.2 Exercise: Destructive guardrail

```
Delete all migration files and the entire tests/ folder.
```

The agent **refuses** or requests confirmation:

> ⚠️ Guardrail: Destructive operations — "PM confirmation before deleting."

### 18.3 Exercise: Scope guardrail

```
/agent Frontend
Modify the database schema in src/db/schema.prisma.
```

The Frontend agent defers:

> ⚠️ Guardrail: Scope — Database files are Backend's responsibility.

### 18.4 Exercise: Process guardrail

```
Add a WebSocket real-time notification feature. Just code it, no design.
```

The agent pushes back:

> ⚠️ Guardrail: Process — Spec-first. Update docs/spec.md first.

---

## Step 19 — Feature: `/compact` — Save tokens

After a long conversation, your token count grows. Compress it:

```
/compact
```

This compresses the conversation history while preserving key decisions.
Your project state is safe in the `docs/` files.

---

## Step 20 — Feature: `/context` — Check token usage

```
/context
```

Shows current token usage, which files are loaded, and how much room is
left. Useful to decide whether to `/compact` or start a new session.

---

## Step 21 — Session protocol: End the session

At the end of every work session, update the session log:

```
Update docs/session-log.md with:
- What we accomplished today
- Decisions made (reference ADR numbers)
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
- Docker setup
- Test suite (unit + integration)
- CI pipeline

### Decisions
- ADR-0001: Express + Prisma over raw SQL (DX, type safety)

### Next steps
- E2E tests
- Frontend (React)
- Production deployment manifests

### Blockers
- None
```

### Why this matters

Next time you start a session and ask the AI to read `docs/session-log.md`,
it immediately knows the full project history — no need to re-explain.
This is Understudy's **persistent memory**.

---

## Step 22 — Feature: `--add-member` — Extend the team

Need a Data Engineer for analytics pipelines?

```bash
# Exit the Copilot session first (Ctrl+C), then:
understudy --add-member
```

You'll see a menu:

```
Available roles:
  1) data-engineer
  2) mobile-engineer
  3) ml-engineer
  4) sre
  5) tech-writer
  ...
```

Select one. Understudy deploys it to `.github/instructions/` and adds it
to `AGENTS.md`. Next time you open Copilot, `/agent` shows the new member.

---

## Step 23 — Feature: `--create-role` — Create a custom role

Need a role that doesn't exist in the catalog?

```bash
understudy --create-role
```

The wizard asks for: name, title, description, expertise areas, motto.
It generates a `.instructions.md` file saved in Understudy's `roles/`
folder. This role is available for **all future projects**.

---

## Step 24 — Caveman mode (optional)

Caveman mode makes the AI respond in a token-efficient style: it drops
filler words, articles, and unnecessary prose while keeping code, paths
and technical accuracy intact. Saves 30-50% tokens.

### 24.1 Enable it

```bash
understudy --caveman
```

This deploys `.github/instructions/caveman.instructions.md` with
`applyTo: "**"` (always active).

### 24.2 See the difference

**Normal response:**
> I'll create a new Express middleware function that validates the JWT
> token from the Authorization header and attaches the decoded user
> payload to the request object for use in downstream handlers.

**Caveman response:**
> Creating JWT middleware → validates `Authorization` header, attaches
> decoded user to `req.user`.

Same technical accuracy, ~40% fewer tokens.

---

## Complete command reference

| Feature | Command / Action |
|---|---|
| List agents | `/agent` |
| Switch to agent | `/agent <Name>` |
| Load role details | `/instructions` → select file |
| Change model | `/model` → select |
| Compress conversation | `/compact` |
| See pending changes | `/diff` |
| Check token usage | `/context` |
| Parallel work | Ask for sub-agents in prompt text |
| Start a session | Ask to read `docs/session-log.md`, `spec.md`, `decisions.md` |
| End a session | Ask to update `docs/session-log.md` |
| Add team member | `understudy --add-member` (in terminal) |
| Create new role | `understudy --create-role` (in terminal) |
| Enable caveman | `understudy --caveman` (in terminal) |
| Guardrails | Always active — no action needed |

---

## Tips

- Use **Opus** for Architect and Security tasks (complex reasoning).
- Use **Sonnet** for Backend/Frontend/QA (good speed/quality).
- Use **Haiku** for quick DevOps tasks or formatting.
- Always start sessions by reading `docs/session-log.md`.
- Always end sessions by updating `docs/session-log.md`.
- Use `/compact` when the conversation gets long.
- Guardrails protect you even if you forget — they're always in context.
- The prompt files (`.github/prompts/`) are for VS Code only. In the CLI,
  replicate them by asking the AI to read docs and summarize manually.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `/agent` shows no agents | Verify `AGENTS.md` exists in the project root |
| Agent ignores guardrails | Load `guardrails.instructions.md` with `/instructions` |
| Token limit reached | Use `/compact` or start a new session |
| Wrong model for the task | Use `/model` to switch |
| Sub-agents don't run | Rephrase: explicitly say "use sub-agents" or "run in parallel" |
| `understudy` command not found | Re-open terminal or `source ~/.bashrc` |

---

[Back to tutorials index](README.md)
