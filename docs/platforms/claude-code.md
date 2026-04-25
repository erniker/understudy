# Claude Code

Claude Code has the richest enforcement layer: it combines instruction
files, per-agent models, a permission deny list and a pre-execution hook.

## Setup

Prerequisites:

- Anthropic account and the `claude` CLI installed.
- Deploy Understudy with Claude Code selected:

```bash
./wizard.sh
# → Platforms: select "Claude Code"
```

Generated files:

```
CLAUDE.md                                    # Always-on global instructions + critical guardrails
.claude/agents/<role>.md                     # One agent per role (name, description, model, tools)
.claude/commands/<name>.md                   # Slash commands (/project:<name>)
.claude/settings.json                        # deny rules (e.g. .env, secrets) + hook wiring
.claude/hooks/guardrails-check.sh            # PreToolUse hook: blocks destructive ops
docs/spec.md, decisions.md, session-log.md, team-roster.md
```

Open the project:

```bash
cd your-project
claude
```

## How loading works

| File | Loaded when |
|---|---|
| `CLAUDE.md` | Every session, always |
| `.claude/agents/<role>.md` | You invoke the agent by name |
| `.claude/commands/<name>.md` | You run `/project:<name>` |
| `.claude/settings.json` | Automatically — enforces permission deny and wires hooks |
| `.claude/hooks/guardrails-check.sh` | Before every tool call (PreToolUse) |

## Built-in slash commands

| Command | Purpose |
|---|---|
| `/project:start-session` | Load `docs/*.md` and summarize state |
| `/project:end-session` | Update `docs/session-log.md` with today's work |
| `/project:design-feature` | Architect-driven design with ADR |
| `/project:security-review` | Focused security review of current changes |

Plus Claude's native commands: `/model`, `/compact`, `/agents` (list), etc.

## Invoking agents

Each role has its own file with a frontmatter like:

```yaml
---
name: architect
description: "Solutions Architect — designs systems, evaluates trade-offs"
model: claude-opus-4.6
tools: [read, edit, bash]
---
```

Invoke agents by name inside Claude Code:

```text
You: Use the architect agent to design the customer API.
You: Use the backend agent to implement it following the ADR.
You: Use the security agent to review the implementation.
```

The model in the frontmatter is honored automatically, so the Architect can
use Opus while Backend uses Sonnet without you switching models manually.

## Safety layers

Claude Code enforces three independent layers:

1. **Instructions** — `CLAUDE.md` + per-agent files (same as Copilot).
2. **Permission deny** (`settings.json`) — Claude refuses to read/write
   files matching the deny list (e.g. `.env`, `secrets/*`, keys).
3. **PreToolUse hook** (`hooks/guardrails-check.sh`) — Runs before every
   tool call and blocks destructive commands (`rm -rf`, `terraform
   destroy`, `kubectl delete`, `DROP TABLE`, etc.) unless explicitly
   confirmed.

The hook is wired via `settings.json`. You can extend its patterns by
editing the script.

## Example: feature with Claude Code

```text
# 1) Load context
/project:start-session

# 2) Design
/project:design-feature
→ Claude asks about the feature, proposes alternatives, adds an ADR.

# 3) Implement with the Backend agent
Use the backend agent to implement ADR-0007. Update tests.

# 4) Security review
/project:security-review

# 5) DevOps wraps up
Use the devops agent to add CI and Terraform for the new service.

# 6) Close the session
/project:end-session
```

## Adding a new command

Drop a file under `.claude/commands/`:

```markdown
---
name: weekly-report
description: "Summarize the week from session-log.md"
---

Read docs/session-log.md for the last 7 days and produce a stakeholder-level
report with: achievements, risks, blockers and next steps.
```

It's immediately invocable as `/project:weekly-report`.

## Tips specific to Claude Code

- If a hook blocks an operation you actually want, confirm it explicitly in
  chat; don't disable the hook unless you truly need to.
- Keep sensitive files in the deny list — even `cat` will refuse to read
  them.
- Use the session-log protocol religiously; Claude's deep reasoning shines
  when context is accurate.

---

Other platforms: [Copilot CLI](copilot-cli.md) · [VS Code Copilot](vscode-copilot.md) · [Cursor](cursor.md)

Next: [Cross-Platform Workflows](../08-cross-platform-workflows.md)
