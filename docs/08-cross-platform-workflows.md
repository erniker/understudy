# 8. Cross-Platform Workflows

Most teams use more than one tool. Understudy supports that natively because
every platform reads the same `docs/*.md` and the same `understudy.yaml`.

## Mixed setup example

```yaml
# understudy.yaml
platforms:
  copilot: true
  claude: true
  cursor: false

models:
  architect: "claude-opus-4.6"
  backend:   "claude-sonnet-4.5"
  security:  "claude-opus-4.6"

guardrails:
  mode: "split"   # keep full guardrails file
```

Run the wizard once and both Copilot and Claude files are generated.

## Deploying to multiple platforms at once

The fastest way to set up a multi-platform project is `--here`:

```bash
cd /path/to/your/repo
understudy --here          # infers everything, deploys to all 3 platforms by default
understudy --here --yes    # fully unattended
```

By default all three platforms are enabled. If you only want a subset, run
without `--here` (interactive wizard) or set `platforms.*` in
`understudy.yaml` before deploying.

## Typical daily flow

- **Morning planning** in Copilot CLI (terminal is fast, tokens cheap).
- **Feature design** in Claude Code (better reasoning + hook safety).
- **Coding** in VS Code Copilot (file-scoped `applyTo` is convenient).
- **Security review + release prep** in Claude Code.

All tools read/write the same `docs/session-log.md`, so no context is lost
between them.

## Session protocol (platform-agnostic)

Start of session:

```
Read docs/session-log.md, docs/spec.md and docs/decisions.md
and tell me where we are.
```

End of session:

```
Update docs/session-log.md with what we did today,
any new decisions and pending items.
```

On VS Code and Claude Code this is a one-click prompt/command; on Copilot
CLI and Cursor it's a plain message. Either way the file is the source of
truth.

## Caveman mode across platforms

Caveman mode is a cross-platform feature. If you deploy with `--caveman`,
the role file is placed in the correct location for each enabled platform:

| Platform | Role location | Slash commands | Hooks |
|---|---|---|---|
| Copilot CLI / VS Code | `.github/instructions/caveman.instructions.md` | `.github/prompts/compress.prompt.md` | Marker block in `copilot-instructions.md` |
| Claude Code | `.claude/agents/caveman.md` | `.claude/commands/compress.md` | Real `SessionStart` / `UserPromptSubmit` hooks |
| Cursor | `.cursor/agents/caveman.md` | `.cursor/commands/compress.md` | `.cursor/rules/00-caveman-active.mdc` |

The `understudy-compress` script itself is platform-independent — it
operates on Markdown files directly, regardless of which AI tool you are
using. See [Caveman Mode](10-caveman-mode.md) for details.

## Shared configuration

All platforms read the same `understudy.yaml` for models, guardrails and
session behavior. When you change the config, re-run the wizard and the new
settings apply to all platforms. Note that existing files are preserved (see
[Configuration → Reapplying changes](09-configuration.md#reapplying-changes)).

---

Next: [Configuration Reference](09-configuration.md)
