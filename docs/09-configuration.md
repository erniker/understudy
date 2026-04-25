# 9. Configuration Reference (`understudy.yaml`)

`understudy.yaml` controls models, platforms, guardrails and session
behavior. There is a priority chain:

```
Wizard defaults (hardcoded)
    ↓ overridden by
Global understudy.yaml next to wizard.sh
    ↓ overridden by
Project understudy.yaml at repo root
```

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
```

## Fields

| Field | Purpose |
|---|---|
| `project.*` | Metadata used by templates (name, PM) |
| `platforms.*` | Toggle Copilot / Claude / Cursor deployment |
| `models.<role>` | Recommended model per role (shown to the user; applied directly in Claude and Cursor agents) |
| `guardrails.mode` | `split` = dedicated guardrails file; `embedded` = critical rules only |
| `session.*` | Hints used in `start-session` / `end-session` prompts |

## Reapplying changes

After editing `understudy.yaml`, re-run the wizard to regenerate the
affected files. Existing customizations in your repo are preserved unless
the file is one of the Understudy-owned templates.

---

Next: [Troubleshooting and FAQ](10-troubleshooting.md)
