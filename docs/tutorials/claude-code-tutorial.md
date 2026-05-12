# Tutorial: Claude Code — Full Feature Walkthrough

> A hands-on guide that walks you through **every feature** Understudy
> provides for Claude Code, using the same TaskFlow project from the
> previous tutorials.

## Prerequisites

- Anthropic account with the `claude` CLI installed.
- Understudy installed.

If starting fresh:

```bash
mkdir taskflow && cd taskflow && git init
understudy          # select "Claude Code" platform
claude              # open the project
```

---

## What makes Claude Code unique?

Claude Code has the **richest enforcement layer** of all platforms:

| Exclusive feature | What it does |
|---|---|
| `settings.json` deny list | Claude refuses to read/write protected files |
| PreToolUse hook | Blocks destructive commands before execution |
| Per-agent model assignment | Each agent uses a different model automatically |
| Slash commands | `/project:<name>` invokes pre-built workflows |
| Statusline (caveman) | Shows real-time token compression savings |

---

## Part 1 — Understanding the generated files

After running `understudy`, your project has:

```
CLAUDE.md                           ← Always loaded (project context + critical guardrails)
.claude/
├── agents/
│   ├── architect.md                ← Each agent: name, description, model, tools
│   ├── backend.md
│   ├── frontend.md
│   ├── devops.md
│   ├── security.md
│   ├── qa.md
│   ├── git-specialist.md           ← Auto-deployed
│   └── repo-documenter.md          ← Auto-deployed
├── commands/
│   ├── start-session.md            ← /project:start-session
│   ├── end-session.md              ← /project:end-session
│   ├── design-feature.md           ← /project:design-feature
│   ├── security-review.md          ← /project:security-review
│   └── understudy.md               ← /project:understudy
├── hooks/
│   └── guardrails-check.sh         ← PreToolUse hook
└── settings.json                   ← Deny rules + hook wiring
docs/
├── spec.md
├── decisions.md
├── session-log.md
└── team-roster.md
```

### 1.1 Feature: `CLAUDE.md` — Always-on instructions

Open `CLAUDE.md`. This file is loaded **every session, automatically**. It
contains:

- Project name, description, stack
- Team rules (spec-first, documented decisions, traceable sessions)
- Critical guardrails (security subset)
- Reference to the full agent roster

You never need to ask Claude to read it — it's always in context.

### 1.2 Feature: Agent files with model assignment

Open `.claude/agents/architect.md`:

```yaml
---
name: architect
description: "Solutions Architect — designs systems, evaluates trade-offs"
model: claude-opus-4
tools: [read, edit, bash]
---
```

The **model** field means: when you invoke the architect, Claude
automatically uses Opus. The backend agent uses Sonnet. You never need to
manually switch models.

### 1.3 Feature: `settings.json` — Deny list

Open `.claude/settings.json`. It contains entries like:

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

Claude will **refuse** to read or write any file matching these patterns.
Even if you explicitly ask, it won't comply.

---

## Part 2 — Starting a session

### 2.1 Feature: `/project:start-session`

```text
You: /project:start-session
```

Claude reads `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`
and `docs/team-roster.md`, then provides:

- Current project status
- Last session summary
- Open items
- Suggested next steps

Since the project is new, it reports empty docs and suggests writing a spec.

### 2.2 Feature: `/project:understudy` — Discover capabilities

Not sure what's available? Ask:

```text
You: /project:understudy
```

Claude explains all available agents, commands, guardrails and the
recommended workflow. Useful for onboarding new team members.

---

## Part 3 — Designing with agents

### 3.1 Feature: Invoke agent by name

```text
You: Use the architect agent to design a REST API for task management.
     Features: user auth (JWT), CRUD tasks, assignment, filtering.
     Write the spec in docs/spec.md.
```

Claude switches to the architect persona (Opus model) and:
1. Asks clarifying questions
2. Writes a formal spec in `docs/spec.md`

### 3.2 Feature: `/project:design-feature`

For a more structured approach:

```text
You: /project:design-feature
```

Claude (as Architect) follows the 8-step design process:
1. Requirements clarification
2. Constraint identification
3. 2-3 alternatives with trade-offs
4. Recommendation with justification
5. ADR in `docs/decisions.md`
6. Mermaid architecture diagram
7. Security consultation
8. Implementation plan

```text
Claude: What feature would you like to design?
You: A notification system — email users when tasks are assigned or
     due dates approach (24h before).
```

Result: ADR-0002 in `docs/decisions.md` with full rationale.

### 3.3 Feature: Per-agent model switching

Notice you didn't run `/model` at any point. The architect's frontmatter
says `model: claude-opus-4`, so Claude uses Opus automatically for design.
When you invoke the backend agent later, it switches to Sonnet.

This is **exclusive to Claude Code** — no other platform supports this.

---

## Part 4 — Security: three layers of protection

### 4.1 Layer 1: Instructions (CLAUDE.md)

Critical guardrails are embedded directly in `CLAUDE.md`. They are always
in context, always respected:

- No secrets in code
- No destructive operations without confirmation
- Spec-first development
- Parameterized queries only

### 4.2 Layer 2: Deny list (settings.json)

Try to read a secret file:

```text
You: Show me the contents of .env
```

Claude refuses:

> I cannot read `.env` — it's in the deny list in `.claude/settings.json`.
> This file likely contains secrets. If you need to reference environment
> variables, check `.env.example` instead.

**Try writing to a protected path:**

```text
You: Create a file called secrets/api-keys.json with our API keys.
```

Claude refuses again — the deny list blocks both reads and writes.

### 4.3 Layer 3: PreToolUse hook (guardrails-check.sh)

This is Claude Code's most powerful safety feature. Before **every tool
call**, the hook runs and checks the command against destructive patterns.

**The hook blocks commands like:**

| Blocked pattern | Example |
|---|---|
| `rm -rf` | `rm -rf /` or `rm -rf node_modules` (with flag) |
| `DROP TABLE` / `DROP DATABASE` | SQL destructive operations |
| `terraform destroy` | Infrastructure destruction |
| `kubectl delete namespace` | Kubernetes resource deletion |
| `git push --force` | Force-pushing to remote |
| `docker system prune` | Bulk container/image removal |

**Exercise — Trigger the hook:**

```text
You: Run: rm -rf src/
```

The hook intercepts and blocks:

> ⚠️ BLOCKED by guardrails hook: destructive command detected (`rm -rf`).
> This requires explicit PM confirmation. Please confirm you want to
> delete the entire src/ directory, or suggest an alternative.

### 4.4 How the hook works internally

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
  # ... more patterns
)
```

The hook:
1. Reads the command Claude is about to execute
2. Checks it against `DESTRUCTIVE_PATTERNS`
3. If matched → exits with code 1 (blocks execution)
4. If clean → exits with code 0 (allows execution)

### 4.5 Customizing the hook

Add your own patterns:

```bash
DESTRUCTIVE_PATTERNS=(
  # ... existing patterns ...
  "npm publish"           # prevent accidental publishes
  "aws s3 rm --recursive" # prevent S3 bucket wipes
  "TRUNCATE"              # prevent table truncation
)
```

---

## Part 5 — Implementation

### 5.1 Invoke the backend agent

```text
You: Use the backend agent to implement the task API following ADR-0001.
     Set up:
     - Express project structure
     - Database schema with Prisma
     - Auth endpoints (register, login, refresh)
     - Task CRUD endpoints
     - Input validation with Zod
     - Error handling middleware
     - Dockerfile + docker-compose.yml
```

Claude switches to the backend persona (Sonnet model) and implements
everything. Because `CLAUDE.md` is always loaded, it follows the team
rules automatically.

### 5.2 Combine agents in a single session

Unlike Copilot CLI, you don't need to restart or use `/agent`. Just tell
Claude which agent to use:

```text
You: Now use the devops agent to add a GitHub Actions workflow with:
     - Lint, unit tests, integration tests (PostgreSQL service)
     - Build and push Docker image to GHCR
     - Deploy to staging on PR merge
```

Claude switches persona seamlessly. The context (all files it created
earlier) remains available.

---

## Part 6 — Slash commands

### 6.1 Feature: `/project:security-review`

Before committing:

```text
You: /project:security-review
```

Claude (as Security, model: Opus) reviews all recent changes:

- JWT implementation review
- Input validation completeness
- SQL injection surface (parameterized queries check)
- Secrets in code (none, good)
- Authorization logic (can user X access user Y's tasks?)
- Rate limiting recommendations

### 6.2 Feature: `/project:end-session`

```text
You: /project:end-session
```

Claude updates `docs/session-log.md`:

```markdown
## Session — 2026-05-12

### Completed
- Wrote spec (docs/spec.md)
- Designed architecture (ADR-0001)
- Implemented auth + task CRUD
- Docker setup
- CI/CD pipeline
- Security review passed

### Decisions
- ADR-0001: Express + Prisma (type safety, DX)

### Next steps
- Notification system (ADR-0002)
- E2E tests
- Production deployment

### Blockers
- None
```

### 6.3 Feature: Creating custom commands

Add any file to `.claude/commands/`:

```markdown
---
name: weekly-report
description: "Summarize the week from session-log.md"
---

Read docs/session-log.md for the last 7 days and produce a
stakeholder-level report: achievements, risks, blockers, next steps.
```

Invoke it immediately:

```text
You: /project:weekly-report
```

More ideas for custom commands:

| Command | Purpose |
|---|---|
| `db-migrate` | Generate and run Prisma migrations |
| `code-review` | Review staged changes against coding standards |
| `update-docs` | Sync README and API docs with current code |
| `dependency-check` | Audit npm packages for vulnerabilities |

---

## Part 7 — Guardrails demonstrations

### 7.1 Security guardrail: No secrets

```text
You: Add the database connection string directly to config.ts:
     postgresql://admin:<PASSWORD>@prod-db.example.com/taskflow
```

Claude refuses:

> 🛡️ Guardrail: Security — No secrets in code. I'll use
> `process.env.DATABASE_URL` and add the variable to `.env.example`
> (without real values).

### 7.2 Process guardrail: Spec-first

```text
You: Add a real-time chat feature to the app. Just implement it, no design.
```

Claude pushes back:

> 🛡️ Guardrail: Process — Spec-first. A real-time chat feature is a
> significant addition. I need to:
> 1. Update docs/spec.md with the requirement
> 2. Design it (ADR) with trade-offs (WebSocket vs SSE vs polling)
> 3. Get Security review (new attack surface)
> 4. Then implement
>
> Would you like me to start with the design?

### 7.3 Destructive guardrail: Confirmation required

```text
You: Drop the users table and recreate it from scratch.
```

The PreToolUse hook blocks the `DROP TABLE` command:

> ⚠️ BLOCKED: Destructive operation (`DROP TABLE`). This requires PM
> confirmation. Alternative: I can create a migration that renames the
> table, creates the new schema, migrates data, then drops the old one.

### 7.4 Scope guardrail: Role boundaries

```text
You: Use the frontend agent to modify the database schema.
```

Claude (as Frontend) acknowledges it's not its domain:

> 🛡️ Scope: Database schema is the Backend agent's responsibility.
> I can describe what schema changes the frontend needs (e.g., a
> `preferences` column for UI settings), and the backend agent can
> implement them.

---

## Part 8 — Caveman mode (optional)

### 8.1 Enable caveman

```bash
understudy --caveman
```

This deploys:
- `.claude/agents/caveman.md` — the caveman role agent
- `.claude/commands/compress.md` — `/project:compress`
- `.claude/commands/restore.md` — `/project:restore`
- Hooks: `SessionStart` + `UserPromptSubmit` (reinforcement)
- Statusline script showing compression savings

### 8.2 Feature: `/project:compress`

Compress a verbose Markdown file:

```text
You: /project:compress docs/decisions.md
```

The compressor:
1. Backs up `docs/decisions.md` → `docs/decisions.original.md`
2. Rewrites the file in caveman style (drops filler, keeps code/paths)
3. Reports token savings (typically 30-50%)

### 8.3 Feature: `/project:restore`

Restore the original:

```text
You: /project:restore docs/decisions.md
```

Restores from the `.original.md` backup.

### 8.4 Feature: Statusline (Claude Code exclusive)

With caveman enabled, Claude's statusline shows real-time stats:

```
🐉 caveman | saved: 847 tokens (38%) | session: 12.4k tokens
```

This is exclusive to Claude Code — no other platform has a statusline.

### 8.5 Feature: Reinforcement hooks

The `SessionStart` hook reminds Claude to use caveman style at the
beginning of every session. The `UserPromptSubmit` hook reinforces it on
every message. This means caveman stays active without you needing to
remind it.

---

## Part 9 — Advanced patterns

### 9.1 Multi-agent workflow in one session

```text
You: Let's build the notification feature end-to-end.

     1. Use the architect agent to design it (ADR-0002 already exists,
        just verify it's still valid)
     2. Use the security agent to review the design for risks
     3. Use the backend agent to implement the queue + email service
     4. Use the qa agent to write tests
     5. Use the devops agent to add Redis to docker-compose and CI
```

Claude executes each step in sequence, switching models as appropriate:
- Architect (Opus) → Security (Opus) → Backend (Sonnet) → QA (Sonnet) → DevOps (Sonnet)

### 9.2 Extending the deny list

Need to protect more files?

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

### 9.3 Adding new agents

Create `.claude/agents/dba.md`:

```yaml
---
name: dba
description: "Database Administrator — schema design, migrations, performance"
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
3. Write migrations that are reversible
4. Add appropriate indexes
5. Document decisions in docs/decisions.md
```

Invoke immediately:

```text
You: Use the dba agent to optimize the tasks query with proper indexing.
```

---

## Part 10 — Claude Code vs other platforms

| Feature | Claude Code | Copilot CLI | VS Code | Cursor |
|---|---|---|---|---|
| Auto-loaded instructions | ✅ CLAUDE.md | ✅ copilot-instructions.md | ✅ Same | ✅ Rules |
| Per-agent model | ✅ Automatic | ❌ Manual `/model` | ❌ Manual | ✅ Frontmatter |
| Deny list (file protection) | ✅ settings.json | ❌ | ❌ | ❌ |
| PreToolUse hook | ✅ guardrails-check.sh | ❌ | ❌ | ❌ |
| Slash commands | ✅ `/project:name` | ❌ | ✅ Prompt files | ✅ Commands |
| Sub-agents (parallel) | ❌ | ✅ | ❌ | ❌ |
| Auto-apply by file type | ❌ | ❌ | ✅ `applyTo` | ✅ `globs` |
| Caveman statusline | ✅ | ❌ | ❌ | ❌ |

---

## Quick reference card

| Feature | How to use |
|---|---|
| Start session | `/project:start-session` |
| End session | `/project:end-session` |
| Design feature | `/project:design-feature` |
| Security review | `/project:security-review` |
| Discover capabilities | `/project:understudy` |
| Invoke agent | "Use the `<name>` agent to..." |
| List agents | `/agents` (native Claude command) |
| Change model | `/model` (or let per-agent model handle it) |
| Compress tokens | `/compact` (native) |
| Protected files | Edit `.claude/settings.json` deny list |
| Custom command | Add `.md` file to `.claude/commands/` |
| Custom agent | Add `.md` file to `.claude/agents/` |
| Extend guardrails hook | Edit `.claude/hooks/guardrails-check.sh` |
| Caveman compress | `/project:compress` |
| Caveman restore | `/project:restore` |

---

## Next steps

- Try the [Cursor tutorial](cursor-tutorial.md) — rules, agents, MDC
  format, glob-based auto-attach.
- Read [Cross-Platform Workflows](../08-cross-platform-workflows.md) to
  combine Claude Code with other tools in the same project.
- See [Configuration Reference](../09-configuration.md) for model and
  guardrails customization.

---

[← VS Code tutorial](vscode-copilot-tutorial.md) · [Back to tutorials index](README.md) · [Next: Cursor →](cursor-tutorial.md)
