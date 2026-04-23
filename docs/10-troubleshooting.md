# 10. Troubleshooting and FAQ

## The agent ignores my instructions

- On Copilot CLI: run `/instructions` and confirm the right file is toggled.
- On VS Code: open a file matching the `applyTo` glob and re-check the
  "Used references" panel.
- On Claude Code: check `CLAUDE.md` is loaded (it appears in the session
  header) and that the agent was actually invoked.
- On Cursor: open the Rules view and confirm the rule shows as applied.

## A destructive command was blocked in Claude Code

Expected — the PreToolUse hook is working. If the operation is legitimate,
confirm it explicitly in chat or relax the pattern in
`.claude/hooks/guardrails-check.sh`.

## I only use one platform, why does the wizard ask for all?

You can answer `false` (or deselect) the platforms you don't use.
`understudy.yaml → platforms.*` controls what's regenerated.

## How do I add a new role?

```bash
./wizard.sh --add-member       # pick from roles/
./wizard.sh --create-role      # create your own; saved to roles/
```

Roles you create are available in every future deployment.

## Existing project — will the wizard overwrite my code?

No. The wizard refuses to overwrite files it didn't create. It only adds
Understudy-owned files (see "Files Understudy produces" in the
[introduction](01-introduction.md)).

## Session log gets huge — how do I manage it?

Keep it chronological and concise (one session = a short block with Done /
Decisions / Pending). Prune old entries into an archive file once per
release.

## Which model should I use?

Defaults in `understudy.yaml`:

- **Opus** for design and security reasoning.
- **Sonnet** for most implementation.
- **Haiku** for quick DevOps tasks and short answers.

Override per project if constraints demand it (e.g. fintech → Opus for
Security).

## Where do I report bugs or request features?

Use the repo's
[issue templates](https://github.com/erniker/understudy/issues/new/choose).
Security issues: see [SECURITY.md](../SECURITY.md).

---

Happy building. If something is missing from these docs, open an issue —
the goal is that anyone can deploy and use Understudy without extra help.
