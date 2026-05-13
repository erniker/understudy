# 📖 Understudy Tutorials

Hands-on, step-by-step guides that walk you through **every feature**
Understudy provides on each platform. All tutorials use the same example
project (TaskFlow — a task management API) so you can compare workflows
side by side.

## Available tutorials

| # | Platform | What you'll learn |
|---|---|---|
| 1 | [GitHub Copilot CLI](copilot-cli-tutorial.md) | `/agent`, `/instructions`, `/model`, sub-agents, `/compact`, guardrails, session flow, `--add-member`, caveman |
| 2 | [VS Code Copilot](vscode-copilot-tutorial.md) | Auto-applied `applyTo` instructions, prompt files, `#file:` context, model picker, guardrails, caveman compress/restore |
| 3 | [Claude Code](claude-code-tutorial.md) | Agents, slash commands, deny list, PreToolUse hook, per-agent model, statusline, caveman |
| 4 | [Cursor](cursor-tutorial.md) | Rules (MDC), agent panel, 4 rule types, glob auto-attach, commands, guardrails, caveman |

## The example project: TaskFlow

All tutorials build the same project so you can see how the same task
flows differently across platforms:

- **TaskFlow** — a REST API for task management
- **Stack:** Node.js + Express + PostgreSQL + Docker
- **Features:** User auth (JWT), CRUD tasks, assignment, filtering

## How to use these tutorials

1. Pick the platform you use most and follow its tutorial start to finish.
2. If you use multiple platforms, read the
   [Cross-Platform Workflows](../08-cross-platform-workflows.md) chapter
   after completing at least one tutorial.
3. Each tutorial is self-contained — you don't need to do them in order.

## Prerequisites

- Understudy installed (`curl -fsSL ... | bash`, or `irm ... | iex` on Windows PowerShell, or manual clone)
- The AI tool for your chosen platform installed and configured
- A terminal with `bash ≥ 4` (for the wizard; on Windows, Git for Windows provides it — the PowerShell installer sets this up automatically)
