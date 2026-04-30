# Caveman module

Opt-in, self-contained module that adds **token-efficient communication** to
an Understudy deployment. Inspired by
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (MIT).

## What it ships

| Asset | Purpose |
| --- | --- |
| [`role.instructions.md`](role.instructions.md) | The `caveman` role — terse, token-efficient prose style. |
| [`bin/understudy-compress`](bin/understudy-compress) | Python 3.8+ compressor that rewrites Markdown in place, preserving code/paths/URLs and creating a `.original.md` backup. |
| [`bin/install-hooks`](bin/install-hooks) | Wires (or removes) caveman reinforcement hooks into a project — Claude Code real hooks, plus degraded reinforcement blocks for Copilot and Cursor. |
| [`bin/install-commands`](bin/install-commands) | Wires (or removes) caveman slash commands (`/compress`, `/restore`) for Claude, Copilot/VS Code and Cursor. |
| [`bin/requirements.txt`](bin/requirements.txt) | Optional `tiktoken` for accurate `cl100k_base` token measurements. |
| [`hooks/`](hooks/) | Source assets installed by `install-hooks` (Claude `session-start.sh` / `user-prompt-submit.sh`, Copilot reinforcement block, Cursor `.mdc` rule). |
| [`commands/`](commands/) | Source assets installed by `install-commands` (Claude `compress.md` / `restore.md`, Copilot `*.prompt.md`, Cursor `*.md`). |
| [`post-install.flags`](post-install.flags) | Declarative wizard hooks so `./wizard.sh --caveman --caveman-hooks` / `--caveman-commands` run their installers after deploy without editing `wizard.sh`. |
| [`evals/`](evals/) | Token-reduction evaluation harness (`run.sh` regenerates `RESULTS.md`). |
| [`tests/`](tests/) | Bats coverage for the role, the compressor, the installers and the wizard's `--caveman` / `--caveman-hooks` / `--caveman-commands` flags. |

The user-facing chapter for caveman lives in
[`docs/11-caveman-mode.md`](../../docs/11-caveman-mode.md) (kept at its
historical path so existing external links keep working).

## How to enable it

```bash
./wizard.sh --caveman          # add the caveman role at deploy time
./wizard.sh --add-member caveman   # add it to an existing deployment
```

The flag is discovered automatically from this directory's `module.yaml`;
you do not need to edit `wizard.sh` to register a new module.

## How to enable the reinforcement hooks (issue #59)

The caveman role is just a description — left to its own devices, the
model drifts back to verbose prose after a few turns. The hooks pin the
mode in place across sessions:

```bash
./wizard.sh --caveman --caveman-hooks    # opt in at deploy time
# or, on an existing deployment:
modules/caveman/bin/install-hooks install --mode remind
```

| Platform | Mechanism | What happens |
| --- | --- | --- |
| Claude Code | Real hooks via `.claude/settings.json` (`SessionStart` and/or `UserPromptSubmit`) | At session start the model is reminded that caveman is active. With `--mode compress` the hook also runs `understudy-compress` on paths listed in `.caveman/auto-compress.paths` before each prompt. |
| GitHub Copilot | Marker-delimited block inside `.github/copilot-instructions.md` | Copilot has no pre-prompt hook API, so reinforcement is delivered as standing instructions. Removed cleanly on uninstall. |
| Cursor | `.cursor/rules/00-caveman-active.mdc` with `alwaysApply: true` | Same idea: Cursor has no hook API, so reinforcement is an always-applied rule. |

Modes:

- `--mode remind` (default) — terse-style reminder only, never modifies any file in the repo.
- `--mode compress` — Claude only. Auto-runs the compressor on configured paths before each prompt. Modifies repo files in place; pair with version control.
- `--mode both` — both of the above.

To remove the hooks:

```bash
modules/caveman/bin/install-hooks uninstall
```

Caveman-owned entries are tagged with `__caveman` in `settings.json` so
the uninstall never disturbs hooks added by other tools.

## How to enable the slash commands (issue #61)

Each platform has its own grammar for slash commands, so the installer
ships a platform-native file in the conventional location for each:

```bash
./wizard.sh --caveman --caveman-commands    # opt in at deploy time
# or, on an existing deployment:
modules/caveman/bin/install-commands install
```

| Platform | Where it lands | How to invoke |
| --- | --- | --- |
| Claude Code | `.claude/commands/compress.md` and `restore.md` | `/compress <path>` and `/restore <path>` |
| GitHub Copilot / VS Code | `.github/prompts/compress.prompt.md` and `restore.prompt.md` | Copilot Chat → run prompt file |
| Cursor | `.cursor/commands/compress.md` and `restore.md` | `/compress <path>` and `/restore <path>` |

Both commands proxy through `modules/caveman/bin/understudy-compress` so
the same safety contract applies (refuses to operate on files outside
CWD, on `.env*`/secret-named files, on symlinks, and on content matching
common credential patterns; always creates a `<file>.original.md`
backup).

To remove the commands:

```bash
modules/caveman/bin/install-commands uninstall
```

Each shipped file carries a `<!-- caveman:command -->` sentinel; the
uninstaller only removes files that still carry it, so user-authored
files in the same directory are never touched.

## How to remove the module entirely

This is the whole point of the `modules/<name>/` layout: removing the
feature is one operation.

```bash
rm -rf modules/caveman
```

Then update:

- `docs/11-caveman-mode.md` (delete or mark as removed)
- `README.md` and `CHANGELOG.md` (note the removal)

That's it. There are no orphan references inside `wizard.sh`,
`install.sh` or the test suite — every caveman asset lives under this
directory.

## Adding a new module

Copy the structure of `modules/caveman/` to `modules/<your-module>/` and
fill in `module.yaml`. The wizard picks it up on the next run.
