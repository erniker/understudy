# Tutorial: Cursor — Full Feature Walkthrough

> A hands-on guide that walks you through **every feature** Understudy
> provides for Cursor, using the same TaskFlow project from the previous
> tutorials.

## Prerequisites

- Cursor installed.
- Understudy installed.

If starting fresh:

```bash
mkdir taskflow && cd taskflow && git init
understudy          # select "Cursor" platform
cursor .            # open the project
```

---

## What makes Cursor unique?

Cursor uses two complementary systems that differ from other platforms:

| Concept | What it means |
|---|---|
| **Rules** (`.mdc` files) | Global instructions, always active or auto-attached by glob |
| **Agents** (`.md` files) | Role-based personas invoked from the Agent panel |
| **Commands** | Slash commands invoked from chat |
| **Model in frontmatter** | Each agent auto-selects its model (`auto`, `fast`, specific) |
| **Glob-based auto-attach** | Rules load when you edit matching files (like VS Code's `applyTo`) |

---

## Part 1 — Understanding the generated files

After running `understudy`, your project has:

```
.cursor/
├── rules/
│   ├── understudy-global.mdc      ← Always active (project context + team rules)
│   └── guardrails.mdc             ← Always active (full guardrails)
├── agents/
│   ├── architect.md
│   ├── backend.md
│   ├── frontend.md
│   ├── devops.md
│   ├── security.md
│   ├── qa-engineer.md
│   ├── git-specialist.md           ← Auto-deployed
│   └── repo-documenter.md          ← Auto-deployed
└── commands/
    └── understudy.md               ← /understudy command
docs/
├── spec.md
├── decisions.md
├── session-log.md
└── team-roster.md
```

### 1.1 Feature: Rules (MDC format)

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

Key: `alwaysApply: true` means this rule is loaded in **every single
conversation** without you doing anything.

### 1.2 Feature: Guardrails rule

Open `.cursor/rules/guardrails.mdc`:

```yaml
---
description: "Understudy guardrails — non-negotiable safety limits"
alwaysApply: true
---

# 🛡️ Guardrails
## 1. Security
- Never hardcode secrets...
## 2. Scope
- Respect file ownership...
...
```

Also `alwaysApply: true` — guardrails are always in context.

### 1.3 Feature: Agent files

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
```

The `model` field controls which model Cursor uses when this agent is
active. Options:
- `auto` — Cursor's default model
- `fast` — fastest available model
- `claude-opus-4` — specific model (if available)

---

## Part 2 — The four types of rules

### 2.1 Always-apply rules

```yaml
---
alwaysApply: true
---
```

Loaded unconditionally. Used for:
- Global project instructions (`understudy-global.mdc`)
- Guardrails (`guardrails.mdc`)

**Cost:** Consumes tokens every session. Keep them concise.

### 2.2 Auto-attached rules (glob-based)

```yaml
---
description: "React component standards"
globs: "src/components/**/*.tsx,src/components/**/*.css"
---
```

Loaded only when you edit files matching the glob pattern. This is
Cursor's equivalent of VS Code's `applyTo`.

**Exercise — Create an auto-attached rule:**

Create `.cursor/rules/backend-standards.mdc`:

```yaml
---
description: "Backend coding standards for services"
globs: "src/services/**/*.ts,src/controllers/**/*.ts"
---

- Use dependency injection (constructor parameters)
- All public methods must have JSDoc
- Error handling: throw typed AppError, never raw Error
- Database queries: always use parameterized statements
- Input validation: Zod schemas at the controller boundary
```

Now when you open any file in `src/services/` or `src/controllers/`, this
rule activates automatically.

### 2.3 Agent-requested rules

```yaml
---
description: "Database migration conventions"
---
```

No `alwaysApply`, no `globs` — just a description. Cursor reads the
description and **decides** whether to apply the rule based on your
current conversation context.

### 2.4 Manual rules

```yaml
---
---
```

Neither auto-applied nor auto-attached. Only loaded if you explicitly
reference the rule in chat.

### 2.5 Summary table

| Rule type | Frontmatter | When loaded | Token cost |
|---|---|---|---|
| Always | `alwaysApply: true` | Every session | Constant |
| Auto-attached | `globs: "pattern"` | Matching file open | Per-file |
| Agent-requested | `description:` only | Cursor decides | On-demand |
| Manual | Empty frontmatter | You reference it | On-demand |

---

## Part 3 — Using the Agent panel

### 3.1 Feature: Agent panel

In Cursor, open the **Agent panel** (usually in the right sidebar or via
the command palette). You'll see all agents from `.cursor/agents/`:

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

### 3.2 Select an agent

Click **architect** in the Agent panel. The chat now uses the Architect's
personality, expertise and model.

```text
You: Design a REST API for task management. Users can create, read,
     update and delete tasks. Tasks have: title, description, status
     (todo/in-progress/done), due date, assignee.
     Write the spec in docs/spec.md and an ADR in docs/decisions.md.
```

The Architect:
1. Asks clarifying questions about scale, auth, etc.
2. Proposes 2-3 alternatives
3. Recommends one
4. Writes spec + ADR

### 3.3 Switch agents mid-session

Click **security** in the Agent panel:

```text
You: Review ADR-0001 in docs/decisions.md. Threat model the JWT auth
     flow and suggest hardening measures.
```

Click **backend**:

```text
You: Implement the task API following ADR-0001. Set up Express + Prisma +
     Zod validation. Include auth middleware.
```

You can switch agents freely — the conversation context is preserved.
Each agent uses its configured model automatically.

---

## Part 4 — Commands

### 4.1 Feature: `/understudy` command

```text
You: /understudy
```

Cursor explains all available agents, rules, the recommended workflow and
how to use the system. Good for onboarding.

### 4.2 Creating custom commands

Add a file to `.cursor/commands/`:

**`.cursor/commands/start-session.md`:**

```markdown
Read docs/session-log.md, docs/spec.md, docs/decisions.md and
docs/team-roster.md. Summarize:
- Current project state
- Last session's work
- Open items and blockers
- Suggested next steps
```

**`.cursor/commands/end-session.md`:**

```markdown
Update docs/session-log.md with a new entry for today:
- What was accomplished
- Decisions made (reference ADRs)
- Next steps
- Blockers (if any)
```

Now you can use:

```text
You: /start-session
You: /end-session
```

### 4.3 More useful custom commands

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

---

## Part 5 — Guardrails in action

### 5.1 Always-active protection

Since `guardrails.mdc` uses `alwaysApply: true`, the guardrails are
enforced in every single conversation, regardless of which agent is active.

### 5.2 Exercise: Security guardrail

Select the **backend** agent and ask:

```text
You: Store the JWT secret directly in the code:
     const JWT_SECRET = "<REDACTED>"
```

Cursor refuses:

> 🛡️ Guardrail violation: Security — "No secrets in code". The JWT
> secret must come from an environment variable. I'll use
> `process.env.JWT_SECRET` and add it to `.env.example`.

### 5.3 Exercise: Process guardrail

```text
You: Add a WebSocket real-time feature. Just code it, skip the design.
```

Cursor pushes back:

> 🛡️ Guardrail: Process — "Spec-first". Real-time communication is a
> significant architectural decision. I should:
> 1. Update docs/spec.md
> 2. Create an ADR evaluating WebSocket vs SSE vs polling
> 3. Get Security review (new attack surface: WebSocket hijacking)
>
> Shall I start with the design?

### 5.4 Exercise: Destructive guardrail

```text
You: Delete the entire tests/ directory and the migrations/ folder.
```

Cursor flags:

> 🛡️ Guardrail: Destructive operations — requires PM confirmation.
> This would delete all tests and database migrations. Are you sure?
> Alternative: I can archive them or create a clean branch.

### 5.5 Exercise: Scope guardrail

Select the **frontend** agent:

```text
You: Modify the database migration to add a new column.
```

The Frontend agent defers:

> 🛡️ Scope: Database migrations are the Backend agent's responsibility.
> I can describe what data the frontend needs (e.g., a `theme` field
> for user preferences), and the backend agent can implement the
> migration.

---

## Part 6 — Creating custom rules

### 6.1 Project-specific coding standards

Create `.cursor/rules/api-conventions.mdc`:

```yaml
---
description: "REST API conventions for TaskFlow"
globs: "src/controllers/**/*.ts,src/routes/**/*.ts"
---

# API Conventions

- All endpoints return `{ data, error, meta }` envelope
- HTTP status codes: 200 (ok), 201 (created), 400 (validation),
  401 (unauthenticated), 403 (forbidden), 404 (not found), 500 (server)
- Pagination: `?page=1&limit=20` → meta includes `total`, `pages`
- Sorting: `?sort=created_at&order=desc`
- Filtering: `?status=active&assignee=user-123`
- All dates in ISO 8601 (UTC)
- Idempotency key header for POST/PUT: `X-Idempotency-Key`
```

This activates only when editing controller or route files.

### 6.2 Testing standards

Create `.cursor/rules/testing-standards.mdc`:

```yaml
---
description: "Testing standards for TaskFlow"
globs: "tests/**/*.ts,**/*.test.ts,**/*.spec.ts"
---

# Testing Standards

- Framework: Jest + Supertest
- Arrange-Act-Assert pattern
- One assertion per test (prefer)
- Mock external services (database, email, etc.)
- Integration tests use a test database (docker-compose.test.yml)
- Naming: `describe('<module>') → it('should <behavior>')`
- Coverage target: 80% lines, 90% branches for critical paths
```

### 6.3 Documentation standards

Create `.cursor/rules/docs-standards.mdc`:

```yaml
---
description: "Documentation standards"
globs: "docs/**/*.md,README.md"
---

# Documentation Standards

- ADRs follow: Title, Status, Context, Options, Decision, Consequences
- Session log entries: date, completed, decisions, next steps, blockers
- Spec sections: overview, requirements (functional + NFR), constraints,
  acceptance criteria, out of scope
- Use Mermaid for diagrams
- Keep language concise — no filler prose
```

---

## Part 7 — Caveman mode (optional)

### 7.1 Enable caveman

```bash
understudy --caveman --caveman-commands
```

This deploys:
- `.cursor/agents/caveman.md` — the caveman role agent
- `.cursor/commands/compress.md` — `/compress` command
- `.cursor/commands/restore.md` — `/restore` command
- `.cursor/rules/00-caveman-active.mdc` — reinforcement rule (`alwaysApply`)

### 7.2 Feature: Reinforcement rule

Open `.cursor/rules/00-caveman-active.mdc`:

```yaml
---
description: "Caveman mode active — use token-efficient style"
alwaysApply: true
---

Respond in caveman style: drop filler words, articles, unnecessary prose.
Keep all code, paths, URLs, technical terms intact. Prioritize clarity
over politeness.
```

Because `alwaysApply: true`, this is active in **every** conversation —
Cursor always responds concisely.

### 7.3 Feature: `/compress` command

```text
You: /compress docs/decisions.md
```

Compresses the file in-place (with backup). Token savings: 30-50%.

### 7.4 Feature: `/restore` command

```text
You: /restore docs/decisions.md
```

Restores from `.original.md` backup.

### 7.5 Caveman in practice

**Without caveman:**
> I'll implement the authentication middleware. This middleware will
> extract the JWT token from the Authorization header, verify it using
> the secret key from the environment variables, and attach the decoded
> user payload to the request object for use in downstream handlers.

**With caveman:**
> Implementing auth middleware → extracts JWT from `Authorization` header,
> verifies with `process.env.JWT_SECRET`, attaches decoded user to `req.user`.

Same technical accuracy, 40% fewer tokens.

---

## Part 8 — Advanced patterns

### 8.1 Combining rules and agents

The power of Cursor is that rules and agents stack:

```
Active context = always-apply rules + matching glob rules + active agent
```

So when you select the **backend** agent and open `src/services/auth.ts`:

1. `understudy-global.mdc` loads (always)
2. `guardrails.mdc` loads (always)
3. `backend-standards.mdc` loads (glob matches `src/services/**`)
4. `api-conventions.mdc` loads (if in `src/controllers/`)
5. Backend agent personality loads (from agent panel)

This gives incredibly precise, context-aware responses.

### 8.2 Model strategy

Configure models strategically in agent frontmatter:

```yaml
# architect.md — needs deep reasoning
model: claude-opus-4

# backend.md — good balance
model: auto

# frontend.md — good balance
model: auto

# qa-engineer.md — fast iteration on tests
model: fast
```

### 8.3 Adding new agents

Create `.cursor/agents/tech-lead.md`:

```yaml
---
name: tech-lead
description: "Tech Lead — code review, mentoring, standards"
model: auto
---

# Tech Lead

## Identity
You are the Tech Lead. You review code, enforce standards and mentor the team.

## How you work
1. Review code for correctness, performance and maintainability
2. Check adherence to project conventions (see rules)
3. Suggest improvements with explanations (teach, don't just fix)
4. Approve or request changes with clear reasoning
```

It appears in the Agent panel immediately.

### 8.4 Multi-file glob patterns

```yaml
globs: "src/**/*.ts,!src/**/*.test.ts,!src/**/*.spec.ts"
```

The `!` prefix excludes patterns. This rule applies to all TypeScript
source files **except** tests.

---

## Part 9 — Cursor vs other platforms

| Feature | Cursor | Claude Code | VS Code | Copilot CLI |
|---|---|---|---|---|
| Auto-applied global rules | ✅ `alwaysApply` | ✅ CLAUDE.md | ✅ copilot-instructions | ✅ Same |
| Glob-based rule loading | ✅ `.mdc` globs | ❌ | ✅ `applyTo` | ❌ |
| Agent panel | ✅ Visual | ❌ (by name in chat) | ❌ | `/agent` |
| Per-agent model | ✅ Frontmatter | ✅ Frontmatter | ❌ | ❌ |
| Commands | ✅ `.cursor/commands/` | ✅ `.claude/commands/` | ✅ `.github/prompts/` | ❌ |
| File protection (deny) | ❌ | ✅ settings.json | ❌ | ❌ |
| PreToolUse hook | ❌ | ✅ guardrails-check.sh | ❌ | ❌ |
| Sub-agents (parallel) | ❌ | ❌ | ❌ | ✅ |
| Caveman reinforcement | ✅ alwaysApply rule | ✅ Real hooks | ⚠️ Marker block | ❌ |
| Caveman statusline | ❌ | ✅ Claude only | ❌ | ❌ |

**Cursor's strengths:** Visual agent panel, flexible rule system (4 types),
glob-based auto-attach, clean MDC format.

---

## Quick reference card

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
| Caveman compress | `/compress` command |
| Caveman restore | `/restore` command |
| Exclude from glob | Use `!pattern` prefix |

---

## Exercise: Full workflow

Try this complete workflow in Cursor:

```text
1. /start-session (custom command — see Part 4.2)

2. Agent panel → architect
   "Design a password reset flow. Write ADR-0003."

3. Agent panel → security
   "Review ADR-0003. What are the risks? Add mitigations."

4. Agent panel → backend
   "Implement the password reset: endpoint, email token, expiry."

5. Agent panel → qa-engineer
   "Write tests: valid reset, expired token, invalid email, rate limiting."

6. Agent panel → devops
   "Add the SMTP config to docker-compose and CI secrets."

7. /end-session (custom command)
```

Each step uses the right agent with the right model, and the always-apply
rules (guardrails + global) stay active throughout.

---

## Next steps

- Read [Cross-Platform Workflows](../08-cross-platform-workflows.md) to
  combine Cursor with Claude Code or VS Code.
- See [Configuration Reference](../09-configuration.md) for model and
  guardrails customization.
- Try [Caveman Mode](../10-caveman-mode.md) for deep details on the
  compression system.

---

[← Claude Code tutorial](claude-code-tutorial.md) · [Back to tutorials index](README.md)
