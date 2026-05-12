# Tutorial: Cursor — Full Feature Walkthrough

> A complete, self-contained guide that walks you step by step through
> **every feature** Understudy provides for Cursor.
> You do not need to read any other tutorial before this one.

---

## What you will learn

By the end of this tutorial you will have used:

- Rules (MDC format) — 4 types: always-apply, glob-based, agent-requested, manual
- Agent panel — visual agent switching
- Model in frontmatter — per-agent model assignment
- Commands — slash commands in chat
- Guardrails — always-active safety rules
- Custom rules — create your own auto-attached rules
- Custom agents — add new roles
- Custom commands — create your own workflows
- Session protocol — persistent memory across sessions
- `--add-member` / `--create-role` — extend the team
- Caveman mode — compress/restore, reinforcement rule

---

## What you need before starting

| Requirement | How to get it |
|---|---|
| Cursor | [cursor.com](https://cursor.com) |
| `bash` ≥ 4 | Comes with Linux/macOS. On Windows use Git Bash or WSL |
| `git` | Any recent version |

---

## Step 1 — Install Understudy

Open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

This downloads the latest release, installs it to `~/.understudy/` and adds
the `understudy` command to your PATH.

Close and re-open your terminal (or `source ~/.bashrc`) so the command is
available.

Verify:

```bash
understudy --help
```

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
| 7 | Platforms | Select **Cursor** |
| 8 | Git: commit files? | `y` |
| 9 | Git: local-only config? | `n` |

> **Shortcut:** `understudy --here` auto-infers all values from your repo.

---

## Step 4 — Open the project in Cursor

```bash
cursor .
```

---

## Step 5 — Verify the generated files

In the Cursor file explorer you should see:

```
.cursor/
├── rules/
│   ├── understudy-global.mdc      ← Always active (project context + team rules)
│   └── guardrails.mdc             ← Always active (full guardrails)
├── agents/
│   ├── architect.md
│   ├── backend.md
│   ├── devops.md
│   ├── frontend.md
│   ├── git-specialist.md           ← Auto-deployed
│   ├── qa-engineer.md
│   ├── repo-documenter.md          ← Auto-deployed
│   └── security.md
└── commands/
    └── understudy.md               ← /understudy command
docs/
├── decisions.md
├── session-log.md
├── spec.md
└── team-roster.md
```

### What each file does

| File/folder | Purpose | Loaded automatically? |
|---|---|---|
| `.cursor/rules/understudy-global.mdc` | Global project instructions. Always in context. | ✅ Yes, always |
| `.cursor/rules/guardrails.mdc` | Full guardrails (8 categories). Always in context. | ✅ Yes, always |
| `.cursor/agents/<role>.md` | Agent definition (name, description, model). | ❌ When selected in Agent panel |
| `.cursor/commands/<name>.md` | Slash commands. | ❌ When you type `/<name>` |
| `docs/*.md` | Persistent memory (spec, decisions, session log). | ❌ You ask or create commands |

---

## Step 6 — Feature: Rules (MDC format)

Cursor rules use **MDC** — Markdown files with YAML frontmatter, extension
`.mdc`, stored in `.cursor/rules/`.

### 6.1 The 4 types of rules

| Type | Frontmatter | When loaded | Token cost |
|---|---|---|---|
| **Always-apply** | `alwaysApply: true` | Every session, unconditionally | Constant |
| **Auto-attached** | `globs: "src/**/*.ts"` | When you edit a matching file | Per-file |
| **Agent-requested** | `description:` only | Cursor decides based on context | On-demand |
| **Manual** | Empty frontmatter | Only if you reference it | On-demand |

### 6.2 Always-apply rules

Open `.cursor/rules/understudy-global.mdc`:

```yaml
---
description: "Global Understudy project instructions — always active"
alwaysApply: true
---

# Project: TaskFlow
# Description: Task management REST API
# Stack: Node.js + Express + PostgreSQL + Docker
# ...
```

`alwaysApply: true` means this rule is loaded in **every single
conversation** without you doing anything.

### 6.3 Guardrails rule

Open `.cursor/rules/guardrails.mdc`:

```yaml
---
description: "Understudy guardrails — non-negotiable safety limits"
alwaysApply: true
---

# 🛡️ Guardrails
## 1. Security — No secrets, no bypass...
## 2. Scope — Each agent owns specific files...
...
```

Also `alwaysApply: true` — guardrails are always in context.

---

## Step 7 — Feature: Agent panel

### 7.1 Open the Agent panel

In Cursor, open the **Agent panel** (right sidebar or command palette).
You'll see all agents from `.cursor/agents/`:

```
Available agents:
  architect    — Solutions Architect
  backend      — Backend Developer
  frontend     — Frontend Developer
  devops       — DevOps Engineer
  security     — Security Expert
  qa-engineer  — QA Engineer
  git-specialist
  repo-documenter
```

### 7.2 Select an agent

Click **architect** in the Agent panel. The chat now uses the Architect's
personality, expertise and model.

### 7.3 Agent file format

Open `.cursor/agents/architect.md`:

```yaml
---
name: architect
description: "Solutions Architect — Understudy"
model: auto
---

# Architect — Solutions Architect

## Identity
You are the Solutions Architect...

## Expertise
- System design, APIs, databases...

## How you work
1. Read docs/spec.md...
2. Propose 2-3 alternatives...
3. Recommend one...
4. Document in docs/decisions.md...
```

The `model` field controls which model Cursor uses:
- `auto` — Cursor's default model
- `fast` — fastest available
- `claude-opus-4` — specific model (if available)

---

## Step 8 — Start a session

Cursor doesn't have a built-in `/start-session` like the prompt files in
VS Code. But you can easily create one (we'll do that in Step 16).

For now, manually ask in chat:

```
Read docs/session-log.md, docs/spec.md, docs/decisions.md and
docs/team-roster.md. Summarize the current state and suggest next steps.
```

Since this is a new project, Cursor reports empty docs and suggests
writing a spec first.

---

## Step 9 — Design with the Architect agent

### 9.1 Select the Architect

Agent panel → click **architect**.

### 9.2 Write the spec

```
I need a REST API for task management. Features:
- User registration and login (JWT)
- CRUD tasks (title, description, status, due date)
- Assign tasks to users
- Filter by status, assignee, due date
- PostgreSQL database, Docker deployment

Write a formal spec in docs/spec.md with:
- Functional requirements (numbered)
- Non-functional requirements (performance, security)
- Constraints
- Acceptance criteria
```

### 9.3 Design the architecture

```
Propose 2-3 architectural alternatives for this API.
Evaluate trade-offs: complexity, scalability, DX.
Recommend one and document it as ADR-0001 in docs/decisions.md.
Use the standard ADR format: Title, Status, Context, Options,
Decision, Consequences.
```

---

## Step 10 — Security review

### 10.1 Switch to Security

Agent panel → click **security**.

### 10.2 Run the review

```
Review the architecture in docs/decisions.md ADR-0001.
Produce a threat model covering:
- JWT auth flows (lifetime, refresh tokens)
- Input validation surface
- SQL injection risks
- Authorization (user X can't access user Y's tasks)
- Secrets management
Add security requirements to docs/spec.md.
```

---

## Step 11 — Implement with the Backend agent

### 11.1 Switch to Backend

Agent panel → click **backend**.

### 11.2 Implement

```
Implement TaskFlow following ADR-0001 and security requirements.
Set up:
- Express project structure (src/controllers, src/services, src/middleware)
- Database schema with Prisma
- Auth endpoints: POST /register, POST /login, POST /refresh
- Task CRUD: GET/POST/PUT/DELETE /tasks
- Auth middleware protecting /tasks routes
- Input validation with Zod
- Error handling middleware
- Dockerfile + docker-compose.yml
- .env.example (no real secrets)
```

### 11.3 Switch agents mid-session

You can switch freely without losing context:

Agent panel → click **devops**:

```
Add a GitHub Actions workflow:
- Lint, unit tests, integration tests (PostgreSQL service)
- Build and push Docker image to GHCR
```

Agent panel → click **qa-engineer**:

```
Write tests for TaskFlow:
1. Unit tests for auth service
2. Unit tests for task CRUD
3. Integration tests (supertest)
4. Edge cases: expired tokens, invalid input, unauthorized access
Use Jest.
```

---

## Step 12 — Guardrails in action

Guardrails are always active because `guardrails.mdc` uses
`alwaysApply: true`. There are 8 categories:

| # | Category | What it protects |
|---|---|---|
| 1 | Security | No secrets in code, mandatory input validation |
| 2 | Scope | Each agent owns specific files |
| 3 | Process | Spec-first (no code without spec) |
| 4 | Destructive | No bulk deletes without PM confirmation |
| 5 | Data/PII | No real data, synthetic only |
| 6 | Quality | Self-review, tests, proper naming |
| 7 | Environments | dev → staging → prod promotion order |
| 8 | Documentation | ADRs required, session-log updated |

### 12.1 Exercise: Security guardrail

Select the **backend** agent and ask:

```
Store the JWT secret directly in the code as a string constant.
```

Cursor refuses:

> 🛡️ Guardrail: Security — No secrets in code. I'll use
> `process.env.JWT_SECRET` and add it to `.env.example`.

### 12.2 Exercise: Process guardrail

```
Add a WebSocket chat feature. Just code it, skip the design.
```

Cursor pushes back:

> 🛡️ Guardrail: Process — Spec-first. Update docs/spec.md first,
> create an ADR, then implement.

### 12.3 Exercise: Destructive guardrail

```
Delete the entire tests/ directory and all migration files.
```

Cursor flags:

> ⚠️ Guardrail: Destructive — requires PM confirmation before bulk deletes.

### 12.4 Exercise: Scope guardrail

Select the **frontend** agent:

```
Modify the database migration to add a new column.
```

Frontend defers:

> 🛡️ Scope: Database migrations are Backend's responsibility.

---

## Step 13 — Feature: Create auto-attached rules

This is where Cursor shines. You can create rules that automatically load
when you edit files matching a glob pattern.

### 13.1 Backend coding standards

Create `.cursor/rules/backend-standards.mdc`:

```yaml
---
description: "Backend coding standards for services"
globs: "src/services/**/*.ts,src/controllers/**/*.ts"
---

- Use dependency injection (constructor parameters)
- All public methods must have JSDoc
- Error handling: throw typed AppError, never raw Error
- Database queries: always parameterized
- Input validation: Zod schemas at the controller boundary
```

Now when you open any file in `src/services/`, this rule activates.

### 13.2 Testing standards

Create `.cursor/rules/testing-standards.mdc`:

```yaml
---
description: "Testing standards for TaskFlow"
globs: "tests/**/*.ts,**/*.test.ts,**/*.spec.ts"
---

- Framework: Jest + Supertest
- Arrange-Act-Assert pattern
- Mock external services (database, email)
- Naming: describe('<module>') → it('should <behavior>')
- Coverage target: 80% lines, 90% branches for critical paths
```

### 13.3 API conventions

Create `.cursor/rules/api-conventions.mdc`:

```yaml
---
description: "REST API conventions for TaskFlow"
globs: "src/controllers/**/*.ts,src/routes/**/*.ts"
---

- All endpoints return { data, error, meta } envelope
- HTTP codes: 200, 201, 400, 401, 403, 404, 500
- Pagination: ?page=1&limit=20 → meta has total, pages
- Dates in ISO 8601 (UTC)
```

### 13.4 Excluding patterns

Use `!` to exclude:

```yaml
globs: "src/**/*.ts,!src/**/*.test.ts"
```

This applies to all `.ts` files **except** tests.

---

## Step 14 — How rules stack

When you edit a file, Cursor combines all matching rules:

```
Active context = always-apply rules + matching glob rules + active agent
```

For example, editing `src/services/auth.ts` with the Backend agent:

1. `understudy-global.mdc` loads (always-apply)
2. `guardrails.mdc` loads (always-apply)
3. `backend-standards.mdc` loads (glob matches `src/services/**`)
4. Backend agent persona loads (from Agent panel)

All 4 are active simultaneously → precise, context-aware responses.

---

## Step 15 — Feature: Commands

### 15.1 Built-in command

```
/understudy
```

Cursor explains all agents, rules, workflow and how to use them.

### 15.2 Create a start-session command

Create `.cursor/commands/start-session.md`:

```markdown
Read docs/session-log.md, docs/spec.md, docs/decisions.md and
docs/team-roster.md. Summarize:
- Current project state
- Last session's work
- Open items and blockers
- Suggested next steps
```

### 15.3 Create an end-session command

Create `.cursor/commands/end-session.md`:

```markdown
Update docs/session-log.md with a new entry for today:
- What was accomplished
- Decisions made (reference ADRs)
- Next steps
- Blockers (if any)
```

### 15.4 More useful commands

**`.cursor/commands/design-feature.md`:**

```markdown
Act as the Architect agent. Follow this process:
1. Ask what feature to design
2. Identify constraints (from docs/spec.md)
3. Propose 2-3 alternatives with trade-offs
4. Recommend one with justification
5. Write an ADR in docs/decisions.md
6. Produce a Mermaid architecture diagram
```

**`.cursor/commands/security-review.md`:**

```markdown
Act as the Security agent. Review all recent changes for:
- Hardcoded secrets
- SQL injection
- Missing input validation
- Broken authentication/authorization
- PII exposure
- Missing rate limiting
Report findings with severity (Critical/High/Medium/Low).
```

Now you can use:

```
/start-session
/end-session
/design-feature
/security-review
```

---

## Step 16 — End the session

```
/end-session
```

(Or if you haven't created the command yet, ask manually.)

Cursor updates `docs/session-log.md`:

```markdown
## Session — 2026-05-12

### Completed
- Wrote spec (docs/spec.md)
- Designed architecture (ADR-0001)
- Implemented auth + task CRUD
- Docker setup
- Tests (unit + integration)
- Security review passed
- Created custom rules (backend, testing, API)

### Decisions
- ADR-0001: Express + Prisma (type safety, DX)

### Next steps
- Notification system
- CI/CD pipeline
- Frontend

### Blockers
- None
```

---

## Step 17 — Feature: Create custom agents

Create `.cursor/agents/tech-lead.md`:

```yaml
---
name: tech-lead
description: "Tech Lead — code review, mentoring, standards"
model: auto
---

# Tech Lead

## Identity
You are the Tech Lead. You review code, enforce standards and mentor.

## How you work
1. Review code for correctness, performance and maintainability
2. Check adherence to project conventions (see rules)
3. Suggest improvements with explanations (teach, don't just fix)
4. Approve or request changes with clear reasoning
```

It appears in the Agent panel immediately.

---

## Step 18 — Model strategy

Configure models strategically in agent frontmatter:

```yaml
# architect.md — needs deep reasoning
model: claude-opus-4

# backend.md — good balance
model: auto

# qa-engineer.md — fast iteration
model: fast
```

---

## Step 19 — Feature: `--add-member` — Extend the team

```bash
# In the terminal:
understudy --add-member
```

Select from the catalog (data-engineer, ml-engineer, sre, tech-writer…).
The role is deployed to `.cursor/agents/` automatically.

---

## Step 20 — Feature: `--create-role` — Create a custom role

```bash
understudy --create-role
```

The wizard asks for: name, title, description, expertise, motto.
Saved in `roles/` for all future projects.

---

## Step 21 — Caveman mode (optional)

### 21.1 Enable it

```bash
understudy --caveman --caveman-commands
```

This deploys:
- `.cursor/agents/caveman.md` — caveman role agent
- `.cursor/commands/compress.md` — `/compress` command
- `.cursor/commands/restore.md` — `/restore` command
- `.cursor/rules/00-caveman-active.mdc` — reinforcement rule

### 21.2 Feature: Reinforcement rule

Open `.cursor/rules/00-caveman-active.mdc`:

```yaml
---
description: "Caveman mode active — use token-efficient style"
alwaysApply: true
---

Respond in caveman style: drop filler words, articles, unnecessary
prose. Keep all code, paths, URLs, technical terms intact.
```

Because `alwaysApply: true`, this is active in **every** conversation.

### 21.3 Feature: `/compress`

```
/compress docs/decisions.md
```

Compresses the file in-place (with backup). Saves 30-50% tokens.

### 21.4 Feature: `/restore`

```
/restore docs/decisions.md
```

Restores from `.original.md` backup.

### 21.5 See the difference

**Normal:**
> I'll create a new Express middleware function that validates the JWT
> token from the Authorization header and attaches the decoded user
> payload to the request object for use in downstream handlers.

**Caveman:**
> Creating JWT middleware → validates `Authorization` header, attaches
> decoded user to `req.user`.

---

## Complete reference

| Feature | How to use |
|---|---|
| Select agent | Agent panel → click name |
| Always-apply rule | `alwaysApply: true` in `.mdc` frontmatter |
| Auto-attach rule | `globs: "pattern"` in `.mdc` frontmatter |
| Invoke command | `/command-name` in chat |
| Create rule | Add `.mdc` to `.cursor/rules/` |
| Create agent | Add `.md` to `.cursor/agents/` |
| Create command | Add `.md` to `.cursor/commands/` |
| Guardrails | Always active (no action needed) |
| Model per agent | `model:` field in agent frontmatter |
| Exclude from glob | Use `!pattern` prefix |
| Caveman compress | `/compress` command |
| Caveman restore | `/restore` command |
| Add team member | `understudy --add-member` (terminal) |
| Create new role | `understudy --create-role` (terminal) |

---

## Exercise: Full workflow

Try this complete workflow:

```
1. /start-session

2. Agent panel → architect
   "Design a password reset flow. Write ADR-0003."

3. Agent panel → security
   "Review ADR-0003. What are the risks?"

4. Agent panel → backend
   "Implement password reset: endpoint, email token, expiry."

5. Agent panel → qa-engineer
   "Write tests: valid reset, expired token, invalid email, rate limiting."

6. Agent panel → devops
   "Add SMTP config to docker-compose and CI secrets."

7. /end-session
```

---

## Tips

- Rules and agents stack: always-apply + glob + agent = precise context.
- `alwaysApply: true` costs tokens every session — keep those rules tight.
- You can switch agents freely mid-session. Context is preserved.
- Create commands for anything you repeat (start/end session, reviews…).
- Cursor doesn't have deny lists or hooks like Claude Code — guardrails
  are enforced via the always-apply `guardrails.mdc` rule only.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Agent not in panel | Verify `.md` file in `.cursor/agents/` |
| Rule not loading | Check frontmatter: `alwaysApply` or `globs` set? |
| Wrong rule active | Verify glob pattern matches your file path |
| Command not found | Check `.md` file in `.cursor/commands/` |
| Guardrails not enforced | Verify `guardrails.mdc` has `alwaysApply: true` |
| `understudy` not found | Re-open terminal or `source ~/.bashrc` |

---

[Back to tutorials index](README.md)
