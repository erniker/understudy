# Cursor

Cursor uses two complementary systems: **rules** (global, always-on or
auto-attached) and **agents** (invoked from the Agent panel).

## Setup

Prerequisites:

- Cursor installed.
- Deploy Understudy with Cursor selected:

```bash
./wizard.sh
# → Platforms: select "Cursor"
```

Generated files:

```
.cursor/rules/understudy-global.mdc     # Always-apply global project rules
.cursor/rules/guardrails.mdc            # Always-apply guardrails
.cursor/agents/<role>.md                # One agent per role
docs/spec.md, decisions.md, session-log.md, team-roster.md
```

Open the project:

```bash
cursor .
```

## How rules work

Cursor rules use **MDC** (Markdown + YAML frontmatter) in `.cursor/rules/`:

```yaml
---
description: "Global Understudy project instructions — always active"
alwaysApply: true
---
# markdown body
```

Types of rules:

| Type | Frontmatter | When it loads |
|---|---|---|
| Always | `alwaysApply: true` | Every session, unconditionally |
| Auto-attached | `globs: "src/**/*.tsx"` | When you edit matching files |
| Agent-requested | `description:` only | Cursor decides based on context |
| Manual | Neither | Only if you reference it |

Understudy ships **two Always rules**: global project rules and full
guardrails.

## How agents work

Each agent under `.cursor/agents/` has frontmatter like:

```yaml
---
name: architect
description: "Solutions Architect — Understudy"
model: auto
---
```

Open the **Agent panel** in Cursor and pick the agent you need. The model
configured in the frontmatter is used automatically (e.g. `auto`, `fast`,
or a specific model name).

## Example session

```text
# 1) Start of day — Cursor auto-loads rules
Chat: Read docs/session-log.md, docs/spec.md and docs/decisions.md
      and tell me where we are.

# 2) Design with the architect agent
Agent panel → architect
Chat: Design the customer API. Produce an ADR in docs/decisions.md.

# 3) Implement with the backend agent
Agent panel → backend
Chat: Implement ADR-0007 and add unit tests.

# 4) Security review
Agent panel → security
Chat: Review the implementation and report findings.

# 5) End of day
Chat: Update docs/session-log.md with today's work, decisions
      and pending items.
```

## Creating your own rules

Add a new `.mdc` file in `.cursor/rules/`, for example:

```yaml
---
description: "React component style guide"
globs: "src/components/**/*.tsx"
---
- Prefer function components and hooks.
- Name files in PascalCase; one component per file.
- Use the Button from ui-kit for all actions.
```

It will auto-attach when you edit matching files.

## Tips specific to Cursor

- Cursor has no slash-command system — for repeatable flows, create rules
  that describe the procedure (e.g. a "release checklist" rule the agent
  reads).
- You can combine agents: switch between architect → backend → security
  without losing the docs/ context.
- `alwaysApply: true` is powerful but costs tokens — keep those rules
  tight.

---

Other platforms: [Copilot CLI](copilot-cli.md) · [VS Code Copilot](vscode-copilot.md) · [Claude Code](claude-code.md)

Next: [Cross-Platform Workflows](../08-cross-platform-workflows.md)
