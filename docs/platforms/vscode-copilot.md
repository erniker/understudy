# VS Code Copilot

VS Code Copilot reads the same `AGENTS.md` and `.github/` tree as the CLI,
but adds **auto-applied per-file instructions** and **reusable prompt
files**.

## Setup

Prerequisites:

- VS Code with the GitHub Copilot and Copilot Chat extensions installed.
- Ideally the latest VS Code so prompt files and `applyTo` globs are honored.

Deploy Understudy:

```bash
./wizard.sh
# → Platforms: select "Copilot"
```

Same files as the CLI, with an important difference: every
`.github/instructions/<role>.instructions.md` has a YAML frontmatter like:

```yaml
---
applyTo: "src/components/**,**/*.tsx"
---
```

When you open or edit a matching file, VS Code auto-applies that role's
instructions — you don't need to toggle anything.

Guardrails are always active because they use `applyTo: "**"`.

## Using the Copilot Chat panel

- Open Copilot Chat (`Ctrl+Alt+I` / `Cmd+Ctrl+I`).
- The model picker is in the chat panel's corner — select the model
  suggested in `understudy.yaml` for the task (Opus for design, Sonnet for
  implementation, Haiku for quick edits).
- Mention files with `#file:path/to/file` to pin context.
- To behave like a specific role, either open a file that matches its
  `applyTo` or ask in chat:

  ```
  Act as the Backend agent (see AGENTS.md and
  .github/instructions/backend.instructions.md).
  ```

## Prompt files

The wizard deploys four ready-to-use prompts under `.github/prompts/`:

| Prompt | Purpose |
|---|---|
| `start-session.prompt.md` | Loads `spec.md`, `decisions.md`, `session-log.md`, `team-roster.md` and gives a status summary |
| `end-session.prompt.md` | Updates `session-log.md` with today's work, decisions and pending items |
| `design-feature.prompt.md` | Runs the Architect's 8-step design process and writes an ADR |
| `security-review.prompt.md` | Performs a focused security review of recent changes |

In Copilot Chat, start typing `/` or the prompt name and VS Code will offer
them as attachments. You can also right-click a prompt file and run it.

## Example: start → work → end

```text
# Morning
Prompt: start-session
→ Copilot summarizes state and suggests next steps.

# Design something new
Prompt: design-feature
→ Copilot asks clarifying questions, proposes alternatives, writes ADR.

# Implement — simply open the target files
Open src/services/CustomerLookup.ts
→ Backend instructions auto-apply (applyTo glob).
Chat: Implement the endpoint per ADR-0005.

# Security check before merging
Prompt: security-review

# End of day
Prompt: end-session
```

## Scoping instructions with `applyTo`

If you create a new role or move code around, edit the role's frontmatter so
VS Code applies the right persona:

```yaml
---
applyTo: "services/customers/**,services/orders/**/*.cs"
---
```

Multiple patterns are comma-separated. `**` matches everything (used by
guardrails).

## Tips specific to VS Code Copilot

- Use prompt files for anything you repeat; they compose with the active
  role instructions.
- If behavior seems wrong, open the Chat's "Used references" panel to see
  which instruction files are loaded.
- Model recommendations live in `understudy.yaml`; the picker is manual, so
  keep the suggested model in mind.

---

Other platforms: [Copilot CLI](copilot-cli.md) · [Claude Code](claude-code.md) · [Cursor](cursor.md)

Next: [Cross-Platform Workflows](../08-cross-platform-workflows.md)
