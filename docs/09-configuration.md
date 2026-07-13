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

This chain is about **wizard defaults**, not deployment scope. It applies the
same way whether you deploy per-project (`understudy --here`), machine-wide
(`understudy --global`), or just persistent per-repo memory on top of a
global install (`understudy --docs-only`) — see
[Global Mode](12-global-mode.md) for the latter two. A project's own
`understudy.yaml` always overrides the global defaults regardless of which
mode originally deployed that project.

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
  qa-engineer: "claude-sonnet-4.5"

roles:
  architect:
    enabled: true
    apply_to: "docs/**"
  backend:
    enabled: true
    apply_to: "src/api/**,src/application/**,src/domain/**,src/infrastructure/**"
  frontend:
    enabled: true
    apply_to: "src/components/**,src/features/**,src/hooks/**,src/ui/**,**/*.tsx,**/*.jsx"
  devops:
    enabled: true
    apply_to: "infra/**,pipelines/**,docker/**,.github/workflows/**,**/*.tf"
  security:
    enabled: true
    apply_to: ""
  qa-engineer:
    enabled: true
    apply_to: "tests/**,**/*.test.*,**/*.spec.*,**/*Tests*/**"

guardrails:
  mode: "split"            # "split" keeps full file; "embedded" inlines critical rules

spec:
  require_before_coding: true  # block coding until spec.md is approved

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
| `models.<role>` | Recommended model per role (shown to the user; applied directly in Claude and Cursor agents). Role key is `qa-engineer` (not `qa`) |
| `roles.<role>.enabled` | `true` = the wizard deploys this role; `false` = skip it |
| `roles.<role>.apply_to` | Glob pattern for VS Code auto-applied instructions. When you edit a file matching this pattern, the role's instructions activate automatically. Empty = manual activation only |
| `guardrails.mode` | `split` = dedicated guardrails file; `embedded` = critical rules only |
| `spec.require_before_coding` | `true` = agents are instructed to block coding until `docs/spec.md` is approved (exceptions: bugfixes, emergencies, CVEs, config) |
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

After editing `understudy.yaml`, re-run the wizard to regenerate the affected files.

### How the wizard handles existing files

The wizard uses a **skip-if-exists** strategy: if a target file already
exists in your project, it is **never overwritten**. Only missing files are
created. This means:

- Changing `models.*` or `roles.*.apply_to` in `understudy.yaml` **does not
  retroactively update** agent files that were already deployed. The new
  values only take effect for files created in future runs.
- The **one exception** is the guardrails block: `inject_guardrails_block`
  replaces the content between `<!-- GUARDRAILS_START -->` and
  `<!-- GUARDRAILS_END -->` markers inside `copilot-instructions.md`,
  `CLAUDE.md` and `guardrails.mdc`, regardless of whether the file already
  existed.

### Step-by-step process

1. **Edit `understudy.yaml`** in your project root with your new configuration.
2. **Re-run the wizard** from your project directory:
   ```bash
   understudy --here
   # or if installed via clone:
   ./wizard.sh --here
   ```
3. **Confirm** when prompted to apply the changes.
4. **Review** the output — the wizard logs every file it creates and every
   file it skips (with "already exists, preserving" messages).

### What changes and what doesn't

| Change in YAML | Effect on re-run | To force the update |
| --- | --- | --- |
| `platforms.*` (enable a new platform) | New platform files are created; existing platform files are untouched | — (works automatically) |
| `platforms.*` (disable a platform) | Nothing is deleted; files remain in place | Delete the platform directory manually (`.github/`, `.claude/`, `.cursor/`) |
| `models.<role>` | No effect — existing agent files are preserved with the old model value | Delete the specific agent file and re-run the wizard, or edit the file manually |
| `roles.<role>.apply_to` | No effect — existing `.instructions.md` files keep their old `applyTo` frontmatter | Edit the `applyTo` in the `.instructions.md` file directly |
| `guardrails.mode` | The guardrails block between `GUARDRAILS_START` / `GUARDRAILS_END` markers is refreshed | — (works automatically) |
| `git.local_config` / `git.local_memory` | `.gitignore` block is appended if not already present | — (works automatically; idempotent) |
| `project.name` / `project.pm` | No effect — existing template files keep the old values | Delete `docs/spec.md`, `docs/team-roster.md` etc. and re-run |

### Example: Adding Copilot to an existing Claude-only project

Original config:
```yaml
platforms:
  copilot: false
  claude: true
  cursor: false
```

Updated config:
```yaml
platforms:
  copilot: true      # newly enabled
  claude: true
  cursor: false
```

After running `understudy --here`:
- New Copilot files are created (`AGENTS.md`, `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `.github/prompts/*.prompt.md`)
- Claude files remain exactly as they were
- New optional role files for Copilot (`git-specialist`, `repo-documenter`, `shell-scripting` if applicable)
- `docs/team-roster.md` is updated to include the new roles (only if the role wasn't already listed)

### Example: Changing recommended models

If you change the model for a role:
```yaml
models:
  backend: "claude-opus-4.6"      # was claude-sonnet-4.5
```

The wizard **will not** update the existing `backend.instructions.md` or `.claude/agents/backend.md` because those files already exist. To apply the new model:

1. **Option A** — Edit the file directly:
   - Copilot: edit the `{{MODEL_BACKEND}}` placeholder value in `.github/instructions/backend.instructions.md`
   - Claude: edit the `model:` field in `.claude/agents/backend.md` frontmatter
   - Cursor: edit the `model:` field in `.cursor/agents/backend.md` frontmatter

2. **Option B** — Delete and regenerate:
   ```bash
   # Delete the specific file(s)
   rm .github/instructions/backend.instructions.md
   rm .claude/agents/backend.md
   rm .cursor/agents/backend.md
   # Re-run the wizard
   understudy --here
   ```

### What is NEVER touched

- Your source code, `package.json`, CI workflows, database migrations
- Any file not in the Understudy-owned list (see [Introduction → Files Understudy produces](01-introduction.md))
- Existing Understudy files that were already deployed

### Troubleshooting regeneration

**Files don't reflect the new YAML values:**
- This is expected — the wizard skips existing files. Delete the file you want to regenerate and re-run.

**The guardrails block didn't update:**
- Ensure the `<!-- GUARDRAILS_START -->` and `<!-- GUARDRAILS_END -->` markers are still present in the file. If you deleted them, the wizard cannot find the block to replace.

**Need a full reset of all Understudy files:**
```bash
# From the project root — prompts for confirmation, shows what it will
# remove, and never touches anything outside the list below.
understudy --uninstall
# Re-run the wizard for a clean deploy
understudy --here
```

`understudy --uninstall` removes exactly the same paths the manual reset used
to require:

```text
AGENTS.md, CLAUDE.md, understudy.yaml
.github/instructions, .github/prompts, .github/copilot-instructions.md
.claude
.cursor/agents, .cursor/commands, .cursor/rules
docs/spec.md, docs/decisions.md, docs/session-log.md, docs/team-roster.md
```

Your source code, `package.json`, CI workflows and any file not in that list
are never touched. Use `understudy --uninstall --yes` to skip the
confirmation prompt. For the machine-wide install, see `understudy --global
--uninstall` in [Global Mode](12-global-mode.md).

**If you lose a customization:**
- Check your git history: `git log -p path/to/file`
- Restore from git: `git checkout path/to/file`

## Optional roles auto-deploy

The wizard automatically deploys certain optional roles from the `roles/`
catalog:

| Role | Condition |
|---|---|
| `git-specialist` | Always included |
| `repo-documenter` | Always included |
| `shell-scripting` | Included when `*.sh`, `*.bash` or `*.zsh` files are detected |

Auto-deployed roles are generated for every platform you selected (Copilot,
Claude, Cursor) and the `docs/team-roster.md` is updated automatically.

There is currently no YAML key to disable auto-deploy; the behavior is
hardcoded in the wizard.

`understudy --global` can't run this detection itself (it deploys once for
the whole machine, not for any single repo), so it only includes
`git-specialist`/`repo-documenter` by default. `understudy --docs-only` (see
[Global Mode](12-global-mode.md)) fills that gap per repo: it runs the same
`*.sh`/`*.bash`/`*.zsh` detection against the repo you're localizing, and if
it finds scripts, adds `shell-scripting` **globally** (available in every
repo from then on, not just this one) and links it into that repo's Cursor
agents — without you needing `--all-roles` or `--add-member`.

### Deploying the entire catalog at once

Pass `--all-roles` to skip the defaults above and deploy every role under
`roles/` in one run — useful if you don't want to add specialists one at a
time with `--add-member`:

```bash
understudy --all-roles              # project mode
understudy --global --all-roles     # global mode (see docs/12-global-mode.md)
```

Opt-in modules (e.g. `--caveman`) are unaffected by `--all-roles` — they
change agent behavior rather than adding a specialist, so they still require
their own explicit flag.

## Module system

Understudy supports **opt-in modules** under `modules/<name>/`. Each module
is a self-contained directory with a `module.yaml` manifest that the wizard
discovers automatically — no edits to `wizard.sh` required.

### Module manifest (`module.yaml`)

```yaml
name: caveman
title: "Caveman mode"
description: "Token-efficient communication overlay."
flag: --caveman              # CLI flag exposed by the wizard
default: false               # true = always included; false = opt-in
role_file: role.instructions.md
bin: bin/understudy-compress  # optional executable (chmod +x on install)
status: stable               # stable | experimental | deprecated
```

The wizard registers the flag from the manifest, so `understudy --help`
lists all available modules dynamically.

### Post-install actions (`post-install.flags`)

A module can ship optional post-install automation in a tab-separated
`post-install.flags` file:

```
--caveman-hooks	bin/install-hooks install --mode remind --target {TARGET}	Install reinforcement hooks.
--caveman-commands	bin/install-commands install --target {TARGET}	Install slash commands.
```

When the user passes the flag (e.g. `understudy --caveman --caveman-hooks`),
the wizard runs the command from the module directory after the regular
deploy finishes. The `{TARGET}` token is replaced with the absolute path of
the deployment target.

### Creating your own module

1. Create a directory under `modules/your-module/`
2. Add a `module.yaml` manifest (see format above)
3. Add a `role.instructions.md` following the standard role format
4. Optionally add `post-install.flags` for extra automation
5. The wizard will discover it automatically on the next run

To remove a module, delete its directory. No other files need to be edited.

---

Next: [Caveman Mode](10-caveman-mode.md)
