# 3. Platform Capability Matrix

A single glance at what each platform can do out of the box after running
`wizard.sh`.

| Capability | GitHub Copilot CLI | VS Code Copilot | Claude Code | Cursor |
|---|:---:|:---:|:---:|:---:|
| Always-on project instructions | ✅ `copilot-instructions.md` | ✅ `copilot-instructions.md` | ✅ `CLAUDE.md` | ✅ `.cursor/rules/*.mdc` (alwaysApply) |
| Role instructions loaded automatically | ⚠️ Manual via `/instructions` | ✅ Auto by `applyTo` glob | ✅ Per-agent file | ✅ Per-agent file |
| Global guardrails always active | ✅ In `copilot-instructions.md` (+ file) | ✅ `applyTo: "**"` | ✅ `CLAUDE.md` + hook | ✅ `guardrails.mdc` |
| Agent selection | ✅ `/agent <name>` | ✅ Chat + role instructions | ✅ Invoke `.claude/agents/<name>` | ✅ Agent panel |
| Reusable prompts / slash commands | ❌ | ✅ `.github/prompts/*.prompt.md` | ✅ `/project:<command>` | ⚠️ Not native (use rules) |
| Sub-agents in parallel | ✅ Task tool | ✅ Task tool | ✅ Task tool | ⚠️ Limited |
| File protection (deny list) | ❌ | ❌ | ✅ `settings.json` deny | ❌ |
| Pre-execution safety hook | ❌ | ❌ | ✅ `hooks/guardrails-check.sh` | ❌ |
| Per-agent recommended model | ⚠️ Manual (`/model`) | ⚠️ Manual (model picker) | ✅ Frontmatter `model:` | ✅ Frontmatter `model:` |
| Persistent cross-session memory | ✅ via `docs/*.md` | ✅ via `docs/*.md` | ✅ via `docs/*.md` | ✅ via `docs/*.md` |
| Existing project integration | ✅ | ✅ | ✅ | ✅ |
| Monorepo stack detection | ✅ | ✅ | ✅ | ✅ |

Legend: ✅ supported, ⚠️ partial/manual, ❌ not available.

## How to choose a platform

- **Terminal-centric, SSH/remote**: Copilot CLI.
- **IDE, rich editor integration, file-scoped behavior**: VS Code Copilot.
- **Maximum safety (hooks + deny list) and long-running design work**: Claude Code.
- **Full-IDE AI-first experience with agents panel**: Cursor.

You can deploy to several platforms at once — they all share the same
`docs/*.md`, roles catalog and `understudy.yaml`, so the team mental model is
identical everywhere.

---

Per-platform guides:

- [GitHub Copilot CLI](platforms/copilot-cli.md)
- [VS Code Copilot](platforms/vscode-copilot.md)
- [Claude Code](platforms/claude-code.md)
- [Cursor](platforms/cursor.md)
