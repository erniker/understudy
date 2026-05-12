# Tutorial: VS Code Copilot — Full Feature Walkthrough

> A hands-on guide that walks you through **every feature** Understudy
> provides for VS Code Copilot, using the same TaskFlow project from the
> CLI tutorial.

## Prerequisites

- VS Code with **GitHub Copilot** and **Copilot Chat** extensions installed.
- Latest VS Code (for `applyTo` globs and prompt file support).
- Understudy already deployed with the Copilot platform selected.

If you followed the [Copilot CLI tutorial](copilot-cli-tutorial.md), your
project already has all the files. If starting fresh:

```bash
mkdir taskflow && cd taskflow && git init
understudy          # select Copilot platform
code .              # open in VS Code
```

---

## What's different from Copilot CLI?

| Aspect | Copilot CLI | VS Code Copilot |
|---|---|---|
| Role activation | Manual (`/agent`, `/instructions`) | **Automatic** via `applyTo` globs |
| Prompts | Not available | ✅ `.github/prompts/*.prompt.md` |
| Context pinning | Tell the agent to read files | `#file:path` in chat |
| Model selection | `/model` command | Picker in chat panel corner |
| Guardrails | Always loaded | Always loaded (same) |
| File editing | Agent writes files | Agent edits inline in editor |

The key advantage: **you never need to manually switch agents**. VS Code
applies the right role instructions based on which file you're editing.

---

## Part 1 — Understanding auto-applied instructions

### 1.1 Feature: `applyTo` globs

Open any `.github/instructions/*.instructions.md` file. Each has a YAML
frontmatter like:

```yaml
---
applyTo: "src/services/**,src/controllers/**,**/*.ts"
---
```

This means: when you open or edit a file matching that glob, VS Code
**automatically** loads that role's instructions into the Copilot context.

### 1.2 Default `applyTo` mappings

| Role | `applyTo` pattern | Activates when editing... |
|---|---|---|
| Architect | `docs/decisions.md,docs/spec.md,**/*.md` | Specs, ADRs, docs |
| Backend | `src/services/**,src/controllers/**,**/*.ts` | Backend code |
| Frontend | `src/components/**,**/*.tsx,**/*.css` | UI code |
| DevOps | `**/Dockerfile,**/*.yml,infra/**,**/*.tf` | Infrastructure |
| Security | `**/*.env*,**/auth/**,**/security/**` | Auth and secrets |
| QA | `tests/**,**/*.test.*,**/*.spec.*` | Test files |
| Guardrails | `**` | **Every file** (always active) |

### 1.3 Try it: automatic role switching

1. Open `docs/spec.md` → Architect instructions load.
2. Open `src/services/auth.ts` → Backend instructions load.
3. Open `tests/auth.test.ts` → QA instructions load.
4. Open `Dockerfile` → DevOps instructions load.

You can verify which instructions are loaded: open Copilot Chat and look at
the **"Used references"** panel at the bottom of a response.

---

## Part 2 — Using prompt files

### 2.1 Feature: Reusable prompts (`.github/prompts/`)

VS Code Copilot supports prompt files — pre-written instructions you can
invoke from the chat. Understudy deploys 5:

| File | What it does |
|---|---|
| `start-session.prompt.md` | Reads spec, decisions, session-log and roster; gives status summary |
| `end-session.prompt.md` | Updates session-log with today's work, decisions, next steps |
| `design-feature.prompt.md` | Runs Architect's 8-step design process; writes ADR |
| `security-review.prompt.md` | Focused security review of recent changes |
| `understudy.prompt.md` | Explains what Understudy is, available roles, how to use them |

### 2.2 How to invoke a prompt

**Option A — Type in chat:**  
Open Copilot Chat (`Ctrl+Alt+I` / `Cmd+Ctrl+I`) and type `/`. VS Code shows
available prompts. Select one.

**Option B — File explorer:**  
Right-click a `.prompt.md` file → "Run with Copilot".

**Option C — Command palette:**  
`Ctrl+Shift+P` → "Copilot: Run Prompt File" → select from list.

### 2.3 Exercise: Start a session

Invoke the **start-session** prompt:

```
/start-session
```

Copilot reads `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`
and `docs/team-roster.md`, then provides:

- Current project state
- Last session summary
- Open items
- Suggested next steps

This replaces the manual "read these files" you would do in the CLI.

---

## Part 3 — Designing a feature

### 3.1 Feature: `design-feature` prompt

Invoke:

```
/design-feature
```

Copilot (acting as the Architect) will ask clarifying questions:

```
What feature would you like to design?
```

Answer:

```
Add a notification system: email users when a task is assigned to them
or when a task's due date is approaching (24h before).
```

The Architect follows the 8-step process:
1. Requirements clarification
2. Constraint identification
3. Alternative proposals (2-3)
4. Trade-off evaluation
5. Recommendation
6. ADR documentation
7. Mermaid diagram
8. Security consultation

The result is written to `docs/decisions.md` as ADR-0002.

### 3.2 Feature: `#file:` — Pin context

Want Copilot to consider a specific file while designing?

```text
Design the notification queue. Consider the existing auth flow in
#file:src/services/auth.ts and the database schema in
#file:src/db/schema.prisma.
```

The `#file:path` syntax tells Copilot to load that file into context.
Useful when the auto-applied instructions aren't enough.

---

## Part 4 — Implementation with automatic role activation

### 4.1 Backend work

Open (or create) `src/services/notifications.ts`. Because this matches the
Backend's `applyTo` pattern, Copilot automatically uses the Backend agent's
expertise.

In the Chat panel:

```text
Implement the notification service following ADR-0002.
Requirements:
- Queue notifications when tasks are assigned
- Check for approaching due dates (cron job)
- Send emails via SendGrid
- Use environment variables for API keys
```

The Backend agent:
- Writes code following the project's conventions
- Uses parameterized queries
- Reads environment variables (respecting guardrails)
- Follows the error handling patterns from the existing codebase

### 4.2 Test work

Now open `tests/notifications.test.ts`. Because this matches the QA
agent's `applyTo` pattern, Copilot switches to the QA perspective.

```text
Write tests for the notification service. Cover:
- Task assignment triggers notification
- Due date notification fires 24h before
- Email service failure is handled gracefully
- Duplicate notifications are prevented
```

The QA agent writes idiomatic Jest tests with proper mocking.

### 4.3 Infrastructure work

Open `docker-compose.yml`. DevOps instructions activate.

```text
Add a Redis service for the notification queue.
Update the app service to connect to Redis.
```

DevOps adds the service following Docker best practices.

---

## Part 5 — Security review

### 5.1 Feature: `security-review` prompt

Before committing, run the security review:

```
/security-review
```

Copilot (as the Security agent) reviews your recent changes and checks:

- API key handling (SendGrid key in env vars, not code)
- Input validation on notification payloads
- Rate limiting on email sends
- SQL injection (parameterized queries)
- PII in logs (no email addresses in plaintext logs)

It produces a report with findings and recommendations.

### 5.2 Feature: Guardrails — always active

Try asking Copilot to do something dangerous while editing any file:

```text
Store the SendGrid API key directly in the source code so we don't
need env vars in development.
```

Copilot refuses:

> 🛡️ This violates the Security guardrail: "No secrets, no bypass". API
> keys must come from environment variables. I'll use `process.env.SENDGRID_API_KEY`
> and add the variable to `.env.example`.

The guardrails are in `.github/instructions/guardrails.instructions.md`
with `applyTo: "**"` — active on every single file.

---

## Part 6 — Model selection

### 6.1 Feature: Model picker

In the Copilot Chat panel, look at the **model selector** (usually in the
top or bottom corner of the chat).

Recommended models by task:

| Task | Model | Why |
|---|---|---|
| Architecture design | Claude Opus / GPT-4o | Complex reasoning |
| Code implementation | Claude Sonnet / GPT-4o-mini | Good speed/quality |
| Quick fixes, formatting | Claude Haiku / GPT-4o-mini | Fast, cheap |
| Security review | Claude Opus | Deeper analysis |

### 6.2 When to switch

- Before invoking `design-feature` → switch to Opus.
- During implementation → Sonnet is fine.
- For a quick rename or formatting → Haiku.

These recommendations come from `understudy.yaml`:

```yaml
models:
  architect: "claude-opus-4"
  backend: "claude-sonnet-4"
  frontend: "claude-sonnet-4"
  devops: "claude-sonnet-4"
  security: "claude-opus-4"
  qa: "claude-sonnet-4"
```

---

## Part 7 — Ending the session

### 7.1 Feature: `end-session` prompt

When you're done working:

```
/end-session
```

Copilot updates `docs/session-log.md` with:

```markdown
## Session — 2026-05-12

### Completed
- Designed notification system (ADR-0002)
- Implemented notification service (src/services/notifications.ts)
- Added Redis to docker-compose
- Wrote tests (unit + integration)
- Security review passed

### Decisions
- ADR-0002: Redis queue + SendGrid for notifications

### Next steps
- Implement email templates
- Add notification preferences (opt-out)
- E2E tests for notification flow

### Blockers
- None
```

### 7.2 Why this matters

Tomorrow, when you (or a colleague) invoke `/start-session`, the AI
reads this log and immediately picks up where you left off. No need to
re-explain anything. This is Understudy's **persistent memory**.

---

## Part 8 — Caveman mode (optional)

### 8.1 Enable caveman

```bash
understudy --caveman
```

This deploys:
- `.github/instructions/caveman.instructions.md` (with `applyTo: "**"`)
- `.github/prompts/compress.prompt.md`
- `.github/prompts/restore.prompt.md`

### 8.2 Feature: `/compress` prompt

When a Copilot response is too verbose:

```
/compress
```

Copilot rewrites its last response in caveman style — dropping filler
words, keeping code/paths/URLs intact. Saves 30-50% tokens.

### 8.3 Feature: `/restore` prompt

Need the full version back?

```
/restore
```

Copilot restores the last compressed response to full natural language.

### 8.4 Automatic caveman

With the role file deployed (`applyTo: "**"`), **all** Copilot responses
automatically use the token-efficient style. No need to invoke `/compress`
manually.

---

## Part 9 — Advanced tips

### 9.1 Customizing `applyTo` for your project

If your project uses a non-standard structure, edit the frontmatter:

```yaml
---
applyTo: "packages/api/**,apps/server/**"
---
```

Multiple patterns are comma-separated. `**` matches everything.

### 9.2 Checking which instructions are active

After any Copilot response, expand the **"Used references"** section at
the bottom. It shows which instruction files were loaded.

If the wrong role is active, check that your file matches the expected
`applyTo` glob.

### 9.3 Combining with Copilot CLI

You can use both in the same project:
- VS Code for interactive coding with auto-applied roles.
- CLI for longer planning sessions, sub-agents and parallel work.

Both read the same files (`AGENTS.md`, `.github/`, `docs/`), so session
history is shared.

### 9.4 Creating your own prompt files

Add any `.prompt.md` file to `.github/prompts/`:

```markdown
---
description: "Run database migration and verify schema"
---
Run the database migration with `npx prisma migrate dev`.
Then verify the schema matches docs/spec.md section 3.
Report any discrepancies.
```

It will appear in Copilot Chat's prompt list immediately.

---

## Quick reference card

| Feature | How to use |
|---|---|
| Auto-applied roles | Open a file → matching role loads automatically |
| Start session | `/start-session` prompt |
| End session | `/end-session` prompt |
| Design feature | `/design-feature` prompt |
| Security review | `/security-review` prompt |
| Pin file as context | `#file:path/to/file` in chat |
| Change model | Model picker in chat panel |
| Check active instructions | "Used references" panel |
| Guardrails | Always active (`applyTo: "**"`) |
| Caveman compress | `/compress` prompt |
| Caveman restore | `/restore` prompt |
| Add team member | `understudy --add-member` (terminal) |
| Custom prompt | Add `.prompt.md` to `.github/prompts/` |

---

## Comparison: What you do differently vs CLI

| Workflow step | In CLI | In VS Code |
|---|---|---|
| Start session | Manually ask to read docs | `/start-session` prompt |
| Switch role | `/agent <name>` | Open a matching file (automatic) |
| Load role details | `/instructions` | Automatic via `applyTo` |
| Design | Tell the Architect | `/design-feature` prompt |
| Security review | `/agent Security` + ask | `/security-review` prompt |
| End session | Tell agent to update log | `/end-session` prompt |
| Compress tokens | `/compact` | `/compress` prompt (caveman) |

---

## Next steps

- Try the [Claude Code tutorial](claude-code-tutorial.md) — hooks, deny
  lists, slash commands.
- Read [Cross-Platform Workflows](../08-cross-platform-workflows.md) if
  you use both VS Code and CLI.
- Explore [Configuration Reference](../09-configuration.md) to tweak
  model assignments and guardrails mode.

---

[← Copilot CLI tutorial](copilot-cli-tutorial.md) · [Back to tutorials index](README.md) · [Next: Claude Code →](claude-code-tutorial.md)
