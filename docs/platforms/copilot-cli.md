# GitHub Copilot CLI

Copilot CLI runs in your terminal and reads project files from the current
working directory.

## Setup

Prerequisites:

- A GitHub Copilot subscription.
- The `copilot` CLI installed (`gh extension install github/gh-copilot` or
  the standalone `copilot` binary — see GitHub docs).
- `bash ≥ 4` to run `wizard.sh`.

Deploy Understudy into your project:

```bash
cd your-project
/path/to/understudy/wizard.sh
# → Platforms: select "Copilot"
```

After the wizard finishes, your repo will contain:

```
AGENTS.md
.github/copilot-instructions.md
.github/instructions/*.instructions.md   # one per role + guardrails
.github/prompts/*.prompt.md              # reusable prompts
docs/spec.md, decisions.md, session-log.md, team-roster.md
```

Optionally, add personal preferences that apply to every project:

```
~/.copilot/copilot-instructions.md
```

## Files Copilot CLI consumes

| File | When it's loaded |
|---|---|
| `.github/copilot-instructions.md` | Automatically, always active |
| `.github/instructions/guardrails.instructions.md` | Always active (full guardrails) |
| `.github/instructions/<role>.instructions.md` | On demand with `/instructions` |
| `AGENTS.md` | Automatically — lists the team and behaviors; used by `/agent` |
| `docs/*.md` | On demand when the agent reads them |

## Core commands

| Command | Purpose |
|---|---|
| `/agent <name>` | Switch to an agent defined in `AGENTS.md` (e.g. `Architect`, `Backend`) |
| `/instructions` | Toggle extra instruction files (per-role detail) |
| `/model` | Change the model for the current session (e.g. Opus, Sonnet, Haiku) |
| `/compact` | Compress conversation history to save tokens |
| `/diff` | Show pending file changes |
| `/context` | Show token usage and loaded context |

## Example: a full feature flow

```text
# 1) Start by loading context
You: Read docs/session-log.md, docs/spec.md and docs/decisions.md
     and tell me where we are.

# 2) Switch to the Architect to design
You: /agent Architect
You: We need a customer lookup API. Propose two designs with trade-offs,
     recommend one and add an ADR to docs/decisions.md.

# 3) Get a security review of the design
You: /agent Security
You: Review the proposed design. Threat model, PII, authZ.

# 4) Implement in parallel using sub-agents
You: Launch sub-agents: Backend implements the API, Frontend implements
     the customer search form. Follow the Architect's ADR.

# 5) QA writes tests
You: /agent QA
You: Produce a test plan and write unit + integration tests.

# 6) DevOps adds CI and infra
You: /agent DevOps
You: Add a GitHub Actions workflow and the Terraform for the new service.

# 7) End the session
You: Update docs/session-log.md with what we did today,
     open items and decisions taken.
```

## Sub-agents (parallel work)

You don't invoke sub-agents directly — you tell Copilot CLI to split the
work.

```text
You: Implement the login feature end to end. Use one sub-agent for Backend
     (API + tests) and another for Frontend (form + tests). Both must follow
     docs/decisions.md ADR-0005.
```

Copilot launches internal task agents that run in parallel and converge
their results. Useful when pieces are independent and reduce total wall
time.

## Tips specific to Copilot CLI

- `AGENTS.md` is the source of truth for which agents exist — edit it to
  change agent names, expertise blurbs or rules.
- Use `/compact` when a conversation gets long; you keep the context in
  `docs/session-log.md` anyway.
- The CLI has no prompt files like VS Code — write common requests once and
  save them in your own `NOTES.md` if you reuse them.

---

Other platforms: [VS Code Copilot](vscode-copilot.md) · [Claude Code](claude-code.md) · [Cursor](cursor.md)

Next: [Cross-Platform Workflows](../08-cross-platform-workflows.md)
