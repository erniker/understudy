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
  backend:   "claude-sonnet-4.6"
  security:  "claude-opus-4.6"

guardrails:
  mode: "split"   # keep full guardrails file
```

Run the wizard once and both Copilot and Claude files are generated.

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

---

Next: [Configuration Reference](09-configuration.md)
