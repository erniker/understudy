# 9. Configuration Reference (`understudy.yaml`)

`understudy.yaml` controls models, platforms, guardrails and session
behavior. There is a priority chain:

```
Wizard defaults (hardcoded)
    ↓ overridden by
Global understudy.yaml in the Understudy installation directory
    ↓ overridden by
Project understudy.yaml at repo root
```

If you installed Understudy with the one-liner, that global config lives next
to the installed wizard files under `~/.understudy/`. If you are running from
a manual clone, it lives next to `wizard.sh` in the cloned repo.

## Full example

```yaml
project:
  name: "my-fintech-app"
  pm: "Ana Example"

platforms:
  copilot: true
  claude: true
  cursor: false

models:
  architect: "claude-opus-4.6"
  backend:   "claude-sonnet-4.5"
  frontend:  "claude-sonnet-4.5"
  devops:    "claude-haiku-4.5"
  security:  "claude-sonnet-4.5"
  qa:        "claude-sonnet-4.5"

guardrails:
  mode: "split"            # "split" keeps full file; "embedded" inlines critical rules

session:
  auto_read_context: true  # hint for start-session prompts
  auto_update_log: true    # hint for end-session prompts

git:
  local_config: false      # true = add AI config files to .gitignore (not committed)
  local_memory: false      # true = add session memory files to .gitignore
```

## Fields

| Field | Purpose |
| --- | --- |
| `project.*` | Metadata used by templates (name, PM) |
| `platforms.*` | Toggle Copilot / Claude / Cursor deployment |
| `models.<role>` | Recommended model per role (shown to the user; applied directly in Claude and Cursor agents) |
| `guardrails.mode` | `split` = dedicated guardrails file; `embedded` = critical rules only |
| `session.*` | Hints used in `start-session` / `end-session` prompts |
| `git.local_config` | `true` = gitignore AI agents, instructions, hooks — kept local only |
| `git.local_memory` | `true` = gitignore spec.md, decisions.md, session-log.md — kept local only |

## Local-only mode

By default every file Understudy generates is committed to the repo. If you want to keep the AI configuration out of git — for example in a corporate repo where AI tool config is private, or an open source project where you don't want to expose your internal workflow — set `git.local_config: true`. The wizard adds the affected paths to the project's `.gitignore` automatically.

```yaml
git:
  local_config: true   # agents, instructions, hooks, AGENTS.md, CLAUDE.md — gitignored
  local_memory: false  # spec.md, decisions.md, session-log.md — still committed (shared memory)
```

You can also choose them interactively during `understudy` — the wizard asks both questions every time.

## Reapplying changes

After editing `understudy.yaml`, re-run the wizard to regenerate the
affected files. Existing customizations in your repo are preserved unless
the file is one of the Understudy-owned templates.

## Optional roles auto-deploy

The wizard automatically deploys certain optional roles from the `roles/`
catalog:

| Role | Condition |
|---|---|
| `git-specialist` | Always included |
| `shell-scripting` | Included when `*.sh`, `*.bash` or `*.zsh` files are detected |

Auto-deployed roles are generated for every platform you selected (Copilot,
Claude, Cursor) and the `docs/team-roster.md` is updated automatically.

There is currently no YAML key to disable auto-deploy; the behavior is
hardcoded in the wizard.

---

Next: [Troubleshooting and FAQ](10-troubleshooting.md)
