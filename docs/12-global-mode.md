# 12. Global Mode — machine-wide install (`--global`)

`understudy --global` seeds a default Understudy team **once per machine**,
so every repository you open already has agents, guardrails and commands
available — no need to run the wizard in each project. It is meant for a
developer (or a team) adopting Understudy as their default AI stack.

## The core guarantee: nothing is lost

Global mode is **strictly additive**. `understudy`, `understudy --here`,
`--add-member` and `--create-role` behave exactly as before — nothing about
per-project deployment changed. If you run `understudy --here` in a specific
repository after installing globally:

- Claude Code and VS Code both resolve **project-level files first** — a
  project's own `CLAUDE.md` / `.claude/agents/*.md` / `.github/instructions/`
  take precedence over the global ones of the same name.
- Cursor's per-project `.cursor/rules/` and `.cursor/agents/` are completely
  independent of the global paste block.

So the global team is a floor, not a ceiling: it gives every repo a working
default team, and per-project `understudy --here` still gives you full
customization (models, `apply_to` scoping, spec-gating, team roster, ADRs)
exactly like today.

## What gets deployed, per platform

| Platform | Support | What `--global` does |
|---|---|---|
| **Claude Code** | Full | Writes `~/.claude/{CLAUDE.md,agents/,commands/,hooks/,settings.json}` — a first-class, native global scope. |
| **GitHub Copilot / VS Code** | Best-effort | Writes instructions/prompts into a `understudy/` folder inside your VS Code user profile, then registers it via the `chat.instructionsFilesLocations` / `chat.promptFilesLocations` user settings. |
| **Cursor** | Manual step + hard-linked agents | Generates a single consolidated file to paste into Settings → Rules → User Rules (**Cursor has no scriptable global rules directory today**), plus one canonical per-role agent file that gets hard-linked (not copied) into any repo you localize with `--docs-only` — see below. |

### Claude Code

Deployed to `~/.claude/`:

```text
~/.claude/
├── CLAUDE.md          ← generic team overview (conditional on docs/spec.md existing per-repo)
├── agents/*.md         ← same agent files used by per-project deploys
├── commands/*.md        ← start-session/end-session/localize-project are global-flavored (see below), the rest unchanged
├── hooks/guardrails-check.sh
└── settings.json        ← hook path is absolute here (project deploys use a relative path)
```

`start-session`/`end-session` check whether the current repository has
`docs/spec.md`/`docs/session-log.md` before assuming they exist, since a
repo you haven't run `understudy --here` in won't have them yet.

### Giving a specific repo persistent memory: `localize-project` / `--docs-only`

There are two distinct things a repo can get on top of the global team, and
Understudy keeps them separate on purpose:

| | Command | What it creates |
|---|---|---|
| **Persistent memory only** | `understudy --docs-only` | `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`, `docs/team-roster.md`, project `understudy.yaml`. **No Claude/Copilot agent files** — those keep coming from the global install. Cursor is the one exception: its `.cursor/agents/*.md` are hard-linked in (not copied), since Cursor has no way to read agents from outside the repo at all. |
| **Full per-project agents** | `understudy --here` | Everything `--docs-only` does, **plus** independent, fully project-owned `CLAUDE.md`/`copilot-instructions.md`/Cursor rules and per-role agent files (real copies, not links) — for when you want different models, `apply_to` scoping, or instructions specific to this repo. |

`--docs-only` is the natural complement to `--global`: you get a shared team
across every repo, but real spec-driven memory (a living contract, ADRs, a
session log) for the specific repos that need it, without duplicating the
agent files that are already available globally.

Two ways to trigger `--docs-only`:

- **Explicitly**: run the `localize-project` command (Claude) or prompt
  (Copilot) — it runs `understudy --docs-only --yes` in the current repo
  and reports what it created.
- **Conversationally**: just tell the agent you want this repo set up for
  real (e.g. "let's set this up properly", "quiero spec-driven aquí") — the
  global instructions tell it to recognize that intent and offer to run
  `localize-project` for you. Cursor has no command file for this (no
  global commands directory), so there it runs `understudy --docs-only --yes`
  directly via its terminal tool instead.

Once a repo has `docs/spec.md`, `start-session` also compares the project
name/description recorded in its "Executive summary" section against the
repo's current `package.json`/`README.md`/`git remote` on every session
start, and flags it if they've drifted (e.g. the project was renamed).

If you later decide you want full per-project agents for a repo you only
`--docs-only`'d, just run `understudy --here` — it builds on top of what's
already there and never removes anything.

#### `shell-scripting` gets auto-detected too

`--global` can't scan any single repo (it deploys once for the whole
machine), so by default it only includes `git-specialist`/`repo-documenter`
— `shell-scripting` is left out unless you passed `--all-roles`. `--docs-only`
closes that gap: it runs the same `*.sh`/`*.bash`/`*.zsh` detection
`--here` already uses, and if the repo you're localizing has scripts, adds
`shell-scripting` **globally** (so every other repo gets it too, not just
this one) and links it into this repo's Cursor agents in the same run — no
need to remember `--all-roles` or `--add-member` ahead of time.

### GitHub Copilot / VS Code

VS Code resolves a per-OS, per-profile user directory:

| OS | Path |
|---|---|
| Linux | `~/.config/Code/User` (or `Code - Insiders`) |
| macOS | `~/Library/Application Support/Code/User` (or `Code - Insiders`) |
| Windows | `%APPDATA%\Code\User` (or `Code - Insiders`) |

Understudy writes into `<profile>/understudy/{instructions,prompts}/` and
then needs to register that folder with VS Code by editing the user
`settings.json` (JSONC — may contain comments), adding:

```jsonc
"chat.instructionsFilesLocations": { "<profile>/understudy/instructions": true },
"chat.promptFilesLocations":       { "<profile>/understudy/prompts": true }
```

This edit is done with **`jq`**, installed temporarily if missing and
removed again at the end of the run — Understudy never leaves a new
dependency on your machine. If `jq` can't be installed (no supported package
manager found, install declined, or a Linux install would need `sudo` in a
non-interactive run), the wizard falls back to printing the exact two lines
above for you to paste in manually
(Command Palette → *"Preferences: Open User Settings (JSON)"*).

A backup of the original `settings.json` is written next to it
(`settings.json.bak-understudy`) and restored automatically by
`understudy --global --uninstall`.

Set `UNDERSTUDY_SKIP_JQ_INSTALL=1` to guarantee the wizard never attempts a
package-manager install, even with `--yes` — it falls straight to the
manual-paste fallback instead. Useful for CI or any environment where you
don't want the wizard touching package managers at all.

### Cursor — manual paste required (platform limitation)

Cursor's "User Rules" exist only as a single free-text field in
**Settings → Rules → User Rules** — there is no filesystem-based global
rules directory today (see the still-open
[feature request on Cursor's forum](https://forum.cursor.com/t/global-cursor-rules-directory/50049)).
This is a hard platform limitation, not something Understudy can script
around safely (Cursor's internal settings storage is not a documented,
stable format to write into directly).

`understudy --global` instead generates a ready-to-paste file at:

```text
~/.understudy-global/cursor-user-rules.md
```

**One-time manual step:**

1. Open Cursor → Settings → Rules → User Rules
2. Paste the contents of `~/.understudy-global/cursor-user-rules.md`

Re-run `understudy --global` any time after changing models, guardrails
mode or roles to refresh this file, then paste it again.

### Selectable per-role Cursor agents, without duplicating content

The paste-block above is Cursor's *always-on* context — it isn't the same
thing as the individually selectable agents (Architect, Backend, ...) you
get in the Agent panel with Claude or Copilot, since Cursor's Agent panel
only reads `.cursor/agents/*.md` **inside a repo**, and there's no global
equivalent to put them in.

`understudy --global` still deploys one canonical copy of each role's
Cursor-formatted agent file to `~/.understudy-global/cursor-agents/`. When
you localize a repo with `understudy --docs-only` (or `localize-project`),
each of those gets **hard-linked** into that repo's `.cursor/agents/` —
not copied. A hard link is a second directory entry pointing at the exact
same file data: editing the role either globally or from inside any linked
repo updates every repo that links to it, with zero drift and zero
duplication to keep in sync.

This needs the repo and `~/.understudy-global/` to be on the **same
filesystem/drive** (a hard-link requirement, not an Understudy choice). If
they aren't — e.g. the repo lives on a different drive than your home
folder — the wizard falls back to a plain copy and tells you so; that copy
won't auto-sync, so re-run `understudy --docs-only` there after editing the
global role to refresh it.

Removing a repo's linked files (e.g. via `understudy --uninstall`) only
removes that repo's directory entry — the shared underlying content and
every other repo linked to it are untouched, exactly like deleting one
shortcut doesn't delete the file it points to.

## CLI reference

```text
understudy --global               Deploy a default team for every project on this machine
understudy --global --yes         Same as --global, skip confirmation prompts
understudy --global --all-roles   Deploy the entire role catalog globally, not just the defaults
understudy --global --add-member  Add an optional role to the global team (Claude + Copilot)
understudy --global --uninstall   Remove everything a --global deploy wrote
```

`--global` reuses the same numbered, editable summary as `--here` — guardrails
mode, platform selection, models and optional roles/modules — minus the
project-identity questions (name, description, stack, repo URL), since there
is no single project at this scope.

By default only `git-specialist` and `repo-documenter` are auto-deployed
alongside the 6 core roles (see [Configuration → Optional roles
auto-deploy](09-configuration.md#optional-roles-auto-deploy)). Pass
`--all-roles` to deploy the full `roles/` catalog (`data-engineer`,
`ml-engineer`, `mobile-engineer`, `sre`, `tech-writer`, `shell-scripting`,
etc.) in one run instead of adding them individually with
`--global --add-member`.

## Guardrails apply everywhere

The Claude Code guardrails hook installed globally
(`~/.claude/hooks/guardrails-check.sh`, wired via `~/.claude/settings.json`)
runs for **every** repository you open, not just Understudy-scaffolded ones.
This is expected: it's the whole point of a machine-wide default — but it is
worth knowing if you work in repos unrelated to Understudy on the same
machine.

## Uninstalling

`understudy --global --uninstall` reads a manifest at
`~/.understudy-global/manifest` — a list of every path Understudy created
during a `--global` run — and removes exactly those files. Anything that
already existed before your `--global` run (e.g. a file you had manually in
`~/.claude/`) is never recorded in the manifest and is therefore never
touched or removed. VS Code `settings.json` files patched via `jq` are
restored from their `.bak-understudy` backup.

## Why global state doesn't live in `~/.understudy`

`~/.understudy` is the Understudy **install payload** (wizard, templates,
roles, modules) — `install.sh` runs `rm -rf ~/.understudy` on every
self-update. Global-deploy bookkeeping (the manifest and the Cursor paste
file) instead lives in the sibling directory `~/.understudy-global/`, which
self-updates never touch.

---

Back to: [Documentation index](README.md)
