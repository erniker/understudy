# 11. Caveman Mode

> *"Why use many token when few token do trick."* — `modules/caveman/role.instructions.md`

Caveman mode is Understudy's take on token-efficient AI collaboration, inspired
by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) — thanks
to its author for open-sourcing the original idea and prompt patterns. It has
two complementary surfaces:

1. **The `caveman` role** — an opt-in team member that *makes agents speak*
   in a token-efficient style without losing technical accuracy.
2. **The `understudy-compress` script** — *makes the prose Understudy generates
   smaller* so every session loads fewer tokens before the agent says a word.

Both ship in v0.6.0. Hooks, statuslines, slash commands and the wenyan
post-processor from upstream are intentionally **not** ported — see
[Not shipped](#not-shipped) below.

---

## 1. The `caveman` role

`modules/caveman/role.instructions.md` is an optional role with the same shape as
`git-specialist` and `repo-documenter`. It instructs the model to:

- Drop articles, fillers, and hedging phrases.
- Preserve code blocks, paths, URLs, commands, version numbers and dates
  byte-for-byte.
- **Never** compress security warnings, `<!-- GUARDRAILS_START -->` blocks,
  ADRs, `docs/decisions.md`, or session logs.

Three intensity hints you can ask for inline:

| Intensity | Behavior |
| --- | --- |
| `lite`  | Trim filler and articles, keep full sentences. |
| `full`  | Telegraphic prose. Default. |
| `ultra` | Bullets only, no prose. Use sparingly — tradeoffs accuracy. |

### Enable it

```bash
# When deploying:
./wizard.sh --caveman                # convenience flag
# or, after deploy:
./wizard.sh --add-member caveman
```

It is **opt-in only** (unlike `git-specialist`, which auto-deploys). It does
not change the behavior of other team members; you address `caveman` directly
when you want condensed answers.

### Platform support

| Platform | Role file location | Active? |
| --- | --- | :---: |
| GitHub Copilot CLI | `.github/instructions/caveman.instructions.md` | ✅ |
| VS Code Copilot | `.github/instructions/caveman.instructions.md` | ✅ |
| Claude Code | `.claude/agents/caveman.md` (frontmatter `name`, `description`, `model`, `tools`) | ✅ |
| Cursor | `.cursor/agents/caveman.md` | ✅ |

The role works identically on every platform Understudy supports.

---

## 2. The `understudy-compress` script

`modules/caveman/bin/understudy-compress` rewrites a Markdown file in place, removing
filler words and high-frequency low-information phrases while preserving:

- Fenced code blocks (` ``` ` and `~~~`)
- YAML frontmatter
- Inline `code` spans
- URLs, file paths, version numbers and ISO dates
- Markdown links and images
- Template tokens like `{{PROJECT_NAME}}`
- Understudy GUARDRAILS markers and `<!-- new members here -->` anchors
- Headings, horizontal rules, tables, HTML comments
- Original line indentation

### Implementation

The script is **Python ≥ 3.8, stdlib-only by default**. We chose Python over
bash because the bash prototype was unreasonably slow on Git Bash mingw and
brittle around `sed` portability (BSD vs GNU vs mingw stripping control bytes).
Python `re` is one regex engine, portable across CI runners and developer
machines.

> **Note for Windows users**: install Python 3 via
> `scoop install python`, `winget install Python.Python.3.13`, or the
> [official installer](https://www.python.org/downloads/). macOS and modern
> Linux distros ship Python 3.

### Usage

```bash
# Compress a doc (creates <file>.original.md backup, modifies in place)
./modules/caveman/bin/understudy-compress docs/team-roster.md

# Preview without writing
./modules/caveman/bin/understudy-compress --dry-run docs/team-roster.md

# Restore from backup (deletes the .original.md)
./modules/caveman/bin/understudy-compress --restore docs/team-roster.md

# Non-interactive (CI): never prompt
./modules/caveman/bin/understudy-compress --no-install --yes docs/team-roster.md
```

### Optional dependency: `tiktoken`

For exact OpenAI/Anthropic-compatible token counts (using the `cl100k_base`
encoding), install `tiktoken`. The script will offer to install it on first
run; you can also do it manually:

```bash
pip install --user tiktoken
# or
pip install --user -r scripts/requirements.txt
```

Without `tiktoken`, the script falls back to whitespace-delimited word count.
This is the only optional dependency. Use `--no-install` to skip the prompt
in any environment.

> **PEP 668 environments** (Debian/Ubuntu 23.04+, recent Fedora): `pip install
> --user` may be blocked. Use `pipx install tiktoken` or a project venv. The
> script will print a clear hint if pip refuses.

### Safety: things the script refuses

These gates are non-bypassable:

- **Symlinks** — refused outright. Operate on real files only.
- **Files outside the current working directory** — including absolute paths
  that resolve outside CWD.
- **Sensitive filenames** — `.env*`, `*secret*`, `*credential*`,
  `*password*`, `*private_key*`, `id_rsa*`, `*.pem`, `*.key`, `*.p12`, `*.pfx`.
- **Sensitive content** — files containing PEM private-key blocks, AWS access
  key IDs (`AKIA...`), GitHub PATs (`ghp_...`), Slack tokens (`xox[abprs]-`),
  JWTs, `password=...`, `api_key=...`.

When refused, the script exits with code `2` and prints which rule matched.

### What the script preserves vs. compresses

It **never modifies** these regions:

- Inside fenced code blocks
- Inside YAML frontmatter
- Inline `` `code` `` spans, URLs, Markdown links, paths, versions, ISO dates,
  template tokens
- Headings, horizontal rules, table rows, full-line HTML comments
- Lines containing GUARDRAILS markers or `new members here`

It **does compress** prose lines outside the above by removing 13 high-frequency
phrases and 14 filler words (e.g. "in order to" → "to", "it is important to
note that the" → "the", "just", "simply", "really", articles where unambiguous).
The compressor runs idempotently — applying its substitutions until no further
change occurs (max 8 iterations).

### Round-trip guarantee

Every successful compression writes `<file>.original.md` (byte-identical to
the input). `--restore` restores from that backup byte-identically and
removes the backup. The unit test suite (`modules/caveman/tests/compress.bats`)
asserts byte-identical round-trip.

---

## Not shipped

The upstream caveman repo includes features Understudy has chosen **not** to
port (yet). Each was evaluated and consciously deferred:

| Feature | Status | Why deferred |
| --- | --- | --- |
| Pre/post-prompt **hooks** | **Shipped** ([#59](https://github.com/erniker/understudy/issues/59)) | See [Reinforcement hooks](#reinforcement-hooks-issue-59) below. Claude Code uses real hooks; Copilot and Cursor get a degraded equivalent. |
| **Statusline** | Deferred ([#60](https://github.com/erniker/understudy/issues/60)) | Claude-only. Limited cross-platform value. |
| **Slash commands** for compression | **Shipped** ([#61](https://github.com/erniker/understudy/issues/61)) | See [Slash commands](#slash-commands-issue-61) below. Each platform gets a native file in its conventional location. |
| **wenyan** (Classical Chinese post-processor) | Skipped | Out of scope for an English-language ops tool. |
| **Token evaluation harness** | **Shipped** in [`modules/caveman/evals/`](../modules/caveman/evals/README.md) | Dogfood + 3-arm methodology (no-caveman / role / role+compress). Opt-in; not wired into `run_tests.sh`. |

The deferred items above are tracked as labelled (`caveman`) issues so
they are discoverable in the issue tracker. They are open for
discussion, not committed work.

---

## Reinforcement hooks (issue #59)

The caveman role file is just a description, so without reinforcement the
model drifts back to verbose prose after a few turns. The
`modules/caveman/bin/install-hooks` installer pins the mode in place
across sessions. It treats each AI platform separately because their
hook surfaces are not equivalent:

| Platform | Mechanism | What gets installed |
| --- | --- | --- |
| Claude Code | Real hooks via `.claude/settings.json` | A `SessionStart` hook (`--mode remind`, default) and/or a `UserPromptSubmit` hook (`--mode compress`) calling the compressor on paths listed in `.caveman/auto-compress.paths`. |
| GitHub Copilot | No pre-prompt API → marker-delimited block | A reinforcement block inside `.github/copilot-instructions.md` between `<!-- caveman:hooks:start -->` and `<!-- caveman:hooks:end -->`. |
| Cursor | No pre-prompt API → always-applied rule | `.cursor/rules/00-caveman-active.mdc` with `alwaysApply: true`. |

Wire it up at deploy time:

```bash
./wizard.sh --caveman --caveman-hooks       # remind-only, safest default
```

Or against an existing deployment:

```bash
modules/caveman/bin/install-hooks install --mode remind
modules/caveman/bin/install-hooks install --mode compress   # auto-compress, Claude only
modules/caveman/bin/install-hooks install --mode both
```

`--mode compress` modifies repo files in place before each prompt; only
enable it when the project is under version control and you are
comfortable with the compressor's safety contract (see
[Compress-script safety](#compress-script-safety) above).

To remove every reinforcement asset:

```bash
modules/caveman/bin/install-hooks uninstall
```

Caveman-owned entries in `settings.json` are tagged with `__caveman`, so
the uninstaller never touches hooks installed by other tools (for
example the existing `PreToolUse` guardrails hook).

---

## Slash commands (issue #61)

The same compressor can be invoked from inside the AI client through a
platform-native slash command. Each platform exposes commands its own
way, so the installer drops a file in the conventional location for
each:

| Platform | Where it lands | How to invoke |
| --- | --- | --- |
| Claude Code | `.claude/commands/compress.md`, `restore.md` | `/compress <path>` and `/restore <path>` |
| GitHub Copilot / VS Code | `.github/prompts/compress.prompt.md`, `restore.prompt.md` | Run the prompt file from Copilot Chat |
| Cursor | `.cursor/commands/compress.md`, `restore.md` | `/compress <path>` and `/restore <path>` |

Wire it up at deploy time:

```bash
./wizard.sh --caveman --caveman-commands
```

Or against an existing deployment:

```bash
modules/caveman/bin/install-commands install
modules/caveman/bin/install-commands uninstall
```

Each shipped file carries a `<!-- caveman:command -->` sentinel.
Uninstall only removes files that still carry it, so a user who
overrides `compress.md` with their own version will see their file
preserved on uninstall.

The commands are thin wrappers around
`modules/caveman/bin/understudy-compress`, so the same safety contract
applies (refuses files outside CWD, `.env*`/secret-named files,
symlinks, and content matching common credential patterns; always
creates a `<file>.original.md` byte-identical backup).

---

## Honest disclaimer

Caveman mode reduces the **input** tokens an agent reads (via compression) and
the **output** tokens it writes (via the role). It does **not** make the model
"reason in fewer tokens"; the same model with the same context produces the
same answer quality. The win is wall-clock latency, context-window headroom
and bill size — not capability.

If you measure savings, do it with `tiktoken` on the prompts your team
actually uses, not on toy fixtures. Word count is a rough proxy.

---

## Related

- Upstream: [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)
- [Evals harness](../modules/caveman/evals/README.md) — reproducible token-reduction
  numbers for this repo (run `./modules/caveman/evals/run.sh` to regenerate)
- [Configuration reference](09-configuration.md) — adding optional roles
- [Cross-Platform Workflows](08-cross-platform-workflows.md) — using
  `caveman` alongside other team members
