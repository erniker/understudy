# Tutorial: Claude Code — Full Feature Walkthrough

> A complete, self-contained guide that walks you step by step through
> **every feature** Understudy provides for Claude Code.
> You do not need to read any other tutorial before this one.

---

## What you will learn

By the end of this tutorial you will have used:

- `CLAUDE.md` — always-on global instructions
- Agent files — per-role personas with automatic model assignment
- `settings.json` deny list — block read/write to sensitive files
- PreToolUse hook — block destructive commands before execution
- Slash commands — `/project:start-session`, `/project:design-feature`…
- Custom commands — create your own `/project:*` workflows
- Custom agents — add new roles
- Guardrails — 3 independent safety layers
- Session protocol — persistent memory across sessions
- `--add-member` / `--create-role` — extend the team
- Caveman mode — compress/restore, hooks, statusline

---

## What you need before starting

| Requirement | How to get it |
|---|---|
| An Anthropic account | [anthropic.com](https://www.anthropic.com) |
| The `claude` CLI installed | Follow Anthropic's installation guide |
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
| 7 | Platforms | Select **Claude Code** |
| 8 | Git: commit files? | `y` |
| 9 | Git: local-only config? | `n` |

> **Shortcut:** `understudy --here` auto-infers all values from your repo.

---

## Step 4 — Verify the generated files

```bash
find . -type f | sort
```

You should see:

```
./CLAUDE.md
./.claude/agents/architect.md
./.claude/agents/backend.md
./.claude/agents/devops.md
./.claude/agents/frontend.md
./.claude/agents/git-specialist.md
./.claude/agents/qa.md
./.claude/agents/repo-documenter.md
./.claude/agents/security.md
./.claude/commands/design-feature.md
./.claude/commands/end-session.md
./.claude/commands/security-review.md
./.claude/commands/start-session.md
./.claude/commands/understudy.md
./.claude/hooks/guardrails-check.sh
./.claude/settings.json
./docs/decisions.md
./docs/session-log.md
./docs/spec.md
./docs/team-roster.md
```

### What each file does

| File/folder | Purpose | Loaded automatically? |
|---|---|---|
| `CLAUDE.md` | Global instructions + critical guardrails. Claude reads it every session. | ✅ Yes, always |
| `.claude/agents/<role>.md` | Agent definition: name, description, model, tools. | ❌ When you invoke the agent |
| `.claude/commands/<name>.md` | Slash command templates. | ❌ When you run `/project:<name>` |
| `.claude/settings.json` | Permission deny list + hook wiring. | ✅ Yes, always |
| `.claude/hooks/guardrails-check.sh` | PreToolUse hook — blocks destructive commands. | ✅ Yes, before every tool call |
| `docs/*.md` | Persistent memory (spec, decisions, session log). | ❌ Via commands or asking |

---

## Step 5 — Open the project with Claude

```bash
claude
```

Claude starts and automatically loads:
- `CLAUDE.md` — project context, team rules, critical guardrails
- `.claude/settings.json` — deny list and hook wiring

You'll notice Claude already knows your project name, stack and rules.

---

## Step 6 — Feature: `CLAUDE.md` — Always-on instructions

Open `CLAUDE.md` in an editor. It contains:

- Project name, description, stack
- Team rules (spec-first, documented decisions, traceable sessions)
- Critical guardrails (security subset)
- Reference to the full agent roster

This file is loaded **every session, automatically**. You never need to
ask Claude to read it.

---

## Step 7 — Feature: Agent files with per-agent model

Open `.claude/agents/architect.md`:

```yaml
---
name: architect
description: "Solutions Architect — designs systems, evaluates trade-offs"
model: claude-opus-4
tools: [read, edit, bash]
---
```

Key fields:
- **`model`** — When you invoke this agent, Claude automatically switches
  to Opus. The backend agent uses Sonnet. You never need to run `/model`.
- **`tools`** — Which tools the agent can use.

This automatic model switching is **exclusive to Claude Code**. No other
platform does this.

### 7.1 Default model assignments

| Agent | Model | Why |
|---|---|---|
| Architect | claude-opus-4 | Complex reasoning for system design |
| Security | claude-opus-4 | Deep analysis for threat modeling |
| Backend | claude-sonnet-4 | Good speed/quality for implementation |
| Frontend | claude-sonnet-4 | Same |
| DevOps | claude-sonnet-4 | Same |
| QA | claude-sonnet-4 | Same |

---

## Step 8 — Feature: `settings.json` — Deny list

Open `.claude/settings.json`. It contains:

```json
{
  "deny": [
    ".env",
    ".env.*",
    "secrets/**",
    "**/*.key",
    "**/*.pem"
  ]
}
```

This means Claude will **refuse** to read or write any file matching these
patterns. Even if you explicitly ask, it won't comply.

### 8.1 Exercise: Try to read a protected file

```
Show me the contents of .env
```

Claude refuses:

> I cannot read `.env` — it's in the deny list. If you need to reference
> environment variables, check `.env.example` instead.

### 8.2 Exercise: Try to write to a protected path

```
Create a file called secrets/api-keys.json with our API keys.
```

Claude refuses — the deny list blocks both reads and writes.

---

## Step 9 — Feature: PreToolUse hook — Block destructive commands

This is Claude Code's most powerful safety feature. Before **every tool
call**, the guardrails hook runs and checks the command against destructive
patterns.

### 9.1 What gets blocked

| Blocked pattern | Example |
|---|---|
| `rm -rf` | `rm -rf /` or `rm -rf node_modules` |
| `DROP TABLE` / `DROP DATABASE` | SQL destructive operations |
| `terraform destroy` | Infrastructure destruction |
| `kubectl delete namespace` | Kubernetes resource deletion |
| `git push --force` | Force-pushing to remote |
| `docker system prune` | Bulk container/image removal |

### 9.2 Exercise: Trigger the hook

```
Run: rm -rf src/
```

The hook intercepts and blocks:

> ⚠️ BLOCKED by guardrails hook: destructive command detected (`rm -rf`).
> This requires explicit PM confirmation.

### 9.3 How the hook works internally

Open `.claude/hooks/guardrails-check.sh`:

```bash
#!/usr/bin/env bash
# PreToolUse hook — blocks destructive operations

DESTRUCTIVE_PATTERNS=(
  "rm -rf"
  "rm -r /"
  "DROP TABLE"
  "DROP DATABASE"
  "terraform destroy"
  "kubectl delete"
  "git push --force"
  "git push -f"
  "docker system prune"
)
```

The hook:
1. Reads the command Claude is about to execute
2. Checks it against `DESTRUCTIVE_PATTERNS`
3. If matched → exits with code 1 (blocks execution)
4. If clean → exits with code 0 (allows execution)

### 9.4 Customize the hook

Add your own patterns by editing the script:

```bash
DESTRUCTIVE_PATTERNS=(
  # ... existing patterns ...
  "npm publish"           # prevent accidental publishes
  "aws s3 rm --recursive" # prevent S3 bucket wipes
  "TRUNCATE"              # prevent table truncation
)
```

---

## Step 10 — Three independent safety layers

Claude Code enforces guardrails through 3 independent layers. If one fails
to catch something, the next one does:

| Layer | Mechanism | What it catches |
|---|---|---|
| 1. Instructions | `CLAUDE.md` (always loaded) | Secrets, scope, spec-first, PII |
| 2. Deny list | `settings.json` | File access to `.env`, secrets, keys |
| 3. Hook | `guardrails-check.sh` (PreToolUse) | Destructive shell commands |

No other platform has all three layers.

---

## Step 11 — Feature: Slash commands

### 11.1 Available commands

| Command | What it does |
|---|---|
| `/project:start-session` | Reads docs/*.md and summarizes project state |
| `/project:end-session` | Updates session-log with today's work |
| `/project:design-feature` | Architect's 8-step design process + ADR |
| `/project:security-review` | Security review of recent changes |
| `/project:understudy` | Explains capabilities, roles, workflow |

Plus Claude's native commands: `/model`, `/compact`, `/agents`, etc.

### 11.2 Start a session

```
/project:start-session
```

Claude reads `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`
and `docs/team-roster.md`, then provides:

- Current project status
- Last session summary
- Open items
- Suggested next steps

Since this is a new project, it reports empty docs and suggests writing a
spec first.

### 11.3 Discover capabilities

```
/project:understudy
```

Claude explains all available agents, commands, guardrails and the
recommended workflow. Useful for onboarding.

---

## Step 12 — Design a feature

### 12.1 Invoke the Architect agent

```
Use the architect agent to design a REST API for task management.
Features: user auth (JWT), CRUD tasks, assignment, filtering.
Write the spec in docs/spec.md.
```

Claude switches to the architect persona (Opus model automatically) and:
1. Asks clarifying questions
2. Writes a formal spec in `docs/spec.md`

### 12.2 Use the design command

```
/project:design-feature
```

Claude (as Architect) follows the 8-step process:
1. Requirements clarification
2. Constraint identification
3. 2-3 alternatives with trade-offs
4. Recommendation with justification
5. ADR in `docs/decisions.md`
6. Mermaid architecture diagram
7. Security consultation
8. Implementation plan

---

## Step 13 — Security review of the design

```
Use the security agent to review ADR-0001 in docs/decisions.md.
Produce a threat model covering JWT auth, input validation,
SQL injection, authorization, and secrets management.
Add security requirements to docs/spec.md.
```

Claude switches to the Security agent (Opus model automatically) and adds
constraints like:
- JWT expiry ≤ 1h, refresh tokens httpOnly
- Parameterized queries only
- Rate limiting on auth endpoints
- Input validation with schema library

---

## Step 14 — Implement with the Backend agent

```
Use the backend agent to implement the TaskFlow API following ADR-0001.
Set up:
- Express project structure
- Database schema with Prisma
- Auth endpoints (register, login, refresh)
- Task CRUD endpoints
- Input validation with Zod
- Error handling middleware
- Dockerfile + docker-compose.yml
- .env.example (no real secrets)
```

Claude switches to the Backend agent (Sonnet model automatically) and
implements everything. `CLAUDE.md` is always loaded, so team rules are
followed automatically.

### 14.1 Combine agents in one session

You can switch agents without restarting. Just tell Claude which to use:

```
Now use the devops agent to add a GitHub Actions workflow with:
- Lint, unit tests, integration tests (PostgreSQL service)
- Build and push Docker image to GHCR
```

Claude switches persona seamlessly. All files from earlier remain in context.

---

## Step 15 — QA: Write tests

```
Use the qa agent to write tests:
1. Unit tests for auth service (register, login, token validation)
2. Unit tests for task CRUD
3. Integration tests (supertest)
4. Edge cases: expired tokens, invalid input, unauthorized access
Use Jest. Create a test plan first, then implement.
```

---

## Step 16 — Security review before committing

```
/project:security-review
```

Claude (as Security, Opus model) reviews all recent changes for:
- Hardcoded secrets
- SQL injection
- Missing input validation
- Broken authentication/authorization
- PII exposure
- Missing rate limiting

---

## Step 17 — Guardrails demonstrations

### 17.1 Security guardrail

```
Add the database connection string directly to config.ts:
postgresql://admin:<PASSWORD>@prod-db.example.com/taskflow
```

Claude refuses:

> 🛡️ Guardrail: Security — No secrets in code. I'll use
> `process.env.DATABASE_URL` and add it to `.env.example`.

### 17.2 Process guardrail

```
Add a WebSocket real-time feature. Just code it, skip the design.
```

Claude pushes back:

> 🛡️ Guardrail: Process — Spec-first. I should update docs/spec.md,
> create an ADR, get Security review, then implement.

### 17.3 Destructive guardrail

```
Drop the users table and recreate it from scratch.
```

The PreToolUse hook blocks the `DROP TABLE` command:

> ⚠️ BLOCKED: Destructive operation. Alternative: create a migration
> that renames the table, creates the new schema, migrates data.

### 17.4 Scope guardrail

```
Use the frontend agent to modify the database schema.
```

Claude (as Frontend) defers:

> 🛡️ Scope: Database schema is Backend's responsibility. I can describe
> what schema changes the frontend needs, then Backend implements them.

---

## Step 18 — End the session

```
/project:end-session
```

Claude updates `docs/session-log.md`:

```markdown
## Session — 2026-05-12

### Completed
- Wrote spec (docs/spec.md)
- Designed architecture (ADR-0001)
- Implemented auth + task CRUD
- Docker setup
- Tests (unit + integration)
- Security review passed

### Decisions
- ADR-0001: Express + Prisma (type safety, DX)

### Next steps
- Notification system
- E2E tests
- Production deployment

### Blockers
- None
```

Next time you run `/project:start-session`, Claude reads this and picks up
where you left off.

---

## Step 19 — Feature: Create custom commands

Add any file to `.claude/commands/`. It's immediately invocable.

Example — `.claude/commands/weekly-report.md`:

```markdown
---
name: weekly-report
description: "Summarize the week from session-log.md"
---

Read docs/session-log.md for the last 7 days and produce a
stakeholder-level report: achievements, risks, blockers, next steps.
```

Invoke it:

```
/project:weekly-report
```

More ideas:

| Command file | Purpose |
|---|---|
| `db-migrate.md` | Generate and run Prisma migrations |
| `code-review.md` | Review staged changes against standards |
| `update-docs.md` | Sync README and API docs with code |
| `dependency-check.md` | Audit npm packages for vulnerabilities |

---

## Step 20 — Feature: Create custom agents

Create `.claude/agents/dba.md`:

```yaml
---
name: dba
description: "Database Administrator — schema, migrations, performance"
model: claude-sonnet-4
tools: [read, edit, bash]
---

# DBA — Database Administrator

## Identity
You are the Database Administrator of the Understudy team.

## Expertise
- PostgreSQL: indexing, partitioning, query optimization
- Migrations: zero-downtime schema changes
- Performance: EXPLAIN ANALYZE, connection pooling
- Backup and recovery strategies

## How you work
1. Read docs/spec.md for data requirements
2. Design schemas with proper normalization
3. Write reversible migrations
4. Add appropriate indexes
5. Document decisions in docs/decisions.md
```

Invoke immediately:

```
Use the dba agent to optimize the tasks query with proper indexing.
```

---

## Step 21 — Extend the deny list

Edit `.claude/settings.json`:

```json
{
  "deny": [
    ".env",
    ".env.*",
    "secrets/**",
    "**/*.key",
    "**/*.pem",
    "terraform.tfstate",
    "*.tfvars",
    "credentials.json"
  ]
}
```

---

## Step 22 — Feature: `--add-member` — Extend the team

```bash
# Exit Claude (Ctrl+C), then:
understudy --add-member
```

Select from the catalog (data-engineer, ml-engineer, sre, tech-writer…).
The role is deployed to `.claude/agents/` automatically.

---

## Step 23 — Feature: `--create-role` — Create a custom role

```bash
understudy --create-role
```

The wizard asks for: name, title, description, expertise, motto.
Saved in `roles/` for all future projects.

---

## Step 24 — Caveman mode (optional)

### 24.1 Enable it

```bash
understudy --caveman
```

This deploys:
- `.claude/agents/caveman.md` — caveman role agent
- `.claude/commands/compress.md` — `/project:compress`
- `.claude/commands/restore.md` — `/project:restore`
- Hooks: `SessionStart` + `UserPromptSubmit` (reinforcement)
- Statusline script showing compression savings

### 24.2 Feature: `/project:compress`

```
/project:compress docs/decisions.md
```

The compressor:
1. Backs up `docs/decisions.md` → `docs/decisions.original.md`
2. Rewrites in caveman style (drops filler, keeps code/paths)
3. Reports token savings (typically 30-50%)

### 24.3 Feature: `/project:restore`

```
/project:restore docs/decisions.md
```

Restores from the `.original.md` backup.

### 24.4 Feature: Statusline (Claude Code exclusive)

With caveman enabled, Claude's statusline shows real-time stats:

```
🐉 caveman | saved: 847 tokens (38%) | session: 12.4k tokens
```

No other platform has a statusline.

### 24.5 Feature: Reinforcement hooks

The `SessionStart` hook reminds Claude to use caveman style at the start
of every session. The `UserPromptSubmit` hook reinforces on every message.
Caveman stays active without reminders.

### 24.6 See the difference

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
| Start session | `/project:start-session` |
| End session | `/project:end-session` |
| Design feature | `/project:design-feature` |
| Security review | `/project:security-review` |
| Discover capabilities | `/project:understudy` |
| Invoke agent | "Use the `<name>` agent to…" |
| List agents | `/agents` (native command) |
| Change model | `/model` (or let per-agent model handle it) |
| Compress tokens | `/compact` (native) |
| Protected files | Edit `.claude/settings.json` deny list |
| Custom command | Add `.md` to `.claude/commands/` |
| Custom agent | Add `.md` to `.claude/agents/` |
| Extend hook | Edit `.claude/hooks/guardrails-check.sh` |
| Caveman compress | `/project:compress` |
| Caveman restore | `/project:restore` |
| Add team member | `understudy --add-member` (terminal) |
| Create new role | `understudy --create-role` (terminal) |

---

## Tips

- Claude Code has **3 safety layers** (instructions + deny list + hook).
  No other platform has all three.
- Per-agent model switching is automatic. You don't need `/model`.
- Keep the deny list strict — even `cat` can't read denied files.
- Use the session-log protocol. Claude's deep reasoning shines when
  context is accurate.
- If a hook blocks something you genuinely need, confirm explicitly in
  chat — don't disable the hook.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Claude doesn't know the project | Verify `CLAUDE.md` exists at project root |
| Agent not found | Check `.claude/agents/` for the agent file |
| Deny list not working | Verify `.claude/settings.json` is valid JSON |
| Hook blocks a legitimate command | Confirm explicitly; or edit the hook patterns |
| `/project:*` command not found | Check file exists in `.claude/commands/` |
| `understudy` command not found | Re-open terminal or `source ~/.bashrc` |

---

[Back to tutorials index](README.md)
