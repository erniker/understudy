# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.1] - 2026-05-05

### Added

- **`/understudy` slash command** (#74):
  New built-in command across all three platforms that explains understudy
  capabilities, available roles, commands, persistent memory files,
  recommended workflow, and configuration options. Works as
  `@workspace /understudy` in VS Code Copilot, `/project:understudy`
  in Claude Code, and `/understudy` in Cursor. The wizard now also
  deploys a `.cursor/commands/` directory (previously Cursor had no
  commands support).

## [0.8.0] - 2026-04-30

### Added

- **Caveman compression-savings statusline** (closes #60):
  `modules/caveman/bin/install-statusline` adds an opt-in Claude Code
  statusline that walks every `*.original.md` backup left by the
  compressor and reports cumulative byte savings as
  `caveman: N files | -X bytes (-Y%)`. The statusline script is
  read-only, exits 0 in every branch (so the line never disappears on
  error), and skips backup files whose live counterpart was deleted.
  Statusline is intentionally Claude-only because Copilot and Cursor do
  not expose a statusline API. The `statusLine` entry in
  `.claude/settings.json` is tagged with `__caveman: true` so uninstall
  only clears the field if it is still owned by caveman. The wizard
  exposes the new automation via
  `./wizard.sh --caveman --caveman-statusline`, registered
  declaratively from `modules/caveman/post-install.flags`.
- **Caveman slash commands** (closes #61):
  `modules/caveman/bin/install-commands` ships a `/compress` and a
  `/restore` slash command in each platform's native location:
  `.claude/commands/*.md` for Claude Code,
  `.github/prompts/*.prompt.md` for GitHub Copilot / VS Code, and
  `.cursor/commands/*.md` for Cursor. Each shipped file carries a
  `<!-- caveman:command -->` sentinel; uninstall only removes files that
  still carry it, so a user who overrides one with their own version
  will see their file preserved. The wizard exposes the new automation
  via `./wizard.sh --caveman --caveman-commands`, registered
  declaratively from `modules/caveman/post-install.flags`.
- **Caveman reinforcement hooks** (closes #59):
  `modules/caveman/bin/install-hooks` wires terse-style reinforcement
  into a project on opt-in. On Claude Code it installs real hooks via
  `.claude/settings.json` (`SessionStart` reminder and, with
  `--mode compress`, an opt-in `UserPromptSubmit` hook that runs
  `understudy-compress` on paths listed in
  `.caveman/auto-compress.paths` before each prompt). On GitHub Copilot
  and Cursor — neither of which expose a pre-prompt hook API — the
  installer drops a marker-delimited reinforcement block inside
  `.github/copilot-instructions.md` and an always-applied
  `.cursor/rules/00-caveman-active.mdc` rule respectively.
  Caveman-owned entries are tagged with `__caveman` in `settings.json`
  so reinstall is idempotent and uninstall never touches hooks added by
  other tools (e.g. the existing guardrails `PreToolUse` hook).
  The wizard exposes the new automation via
  `./wizard.sh --caveman --caveman-hooks`; the flag is registered
  declaratively from `modules/caveman/post-install.flags` so other
  modules can ship the same kind of opt-in automation without editing
  `wizard.sh`.

### Changed

- **Modules layout**: caveman is now a self-contained module under
  `modules/caveman/` (closes #67). The compressor moved from
  `scripts/understudy-compress` to
  `modules/caveman/bin/understudy-compress`; the role file, bats tests
  (`role.bats`, `compress.bats`, `deploy.bats`) and the evals harness
  all live alongside under the same directory, together with a
  `module.yaml` manifest. `wizard.sh` now discovers optional modules
  dynamically by scanning `modules/*/module.yaml`, so adding or
  removing an opt-in feature no longer requires edits scattered across
  `wizard.sh`, `tests/`, `roles/` and `scripts/` — a single
  `rm -rf modules/<name>` (plus tidy-up of CHANGELOG/README mentions)
  is enough to drop a module. `install.sh` and the CI workflows
  (`evals-smoke.yml`, `evals.yml`, `tests.yml`) were updated to the
  new path. Users running the `understudy-compress` launcher installed
  by `install.sh` are unaffected; only callers that referenced the
  previous relative path inside the repo need to update it.

### Added

- **Evals smoke workflow** (`.github/workflows/evals-smoke.yml`):
  runs `./tests/evals/run.sh` on PRs that touch the compressor or the
  harness, surfaces the results in the job summary, and emits a workflow
  warning if caveman compression on `docs/` stops reducing tokens.
  Uses the word-count fallback (no `tiktoken` install) so the job stays
  fast. The companion issue #43 covers regenerating `RESULTS.md` with
  real `tiktoken` numbers.
- **Evals workflow with real `tiktoken`** (`.github/workflows/evals.yml`):
  manual (`workflow_dispatch`) and weekly (Mon 06:00 UTC) job that
  installs `tiktoken`, runs the harness with `cl100k_base`, fails if
  `RESULTS.md` does not declare `cl100k_base`, and uploads it as a
  workflow artifact. Non-blocking, not a required PR check. Local
  recipes for `uv` / `python -m venv` / `pipx` are documented in
  `tests/evals/README.md`.
- **Release date guard**: `.github/workflows/release.yml` now validates
  that the date in `## [X.Y.Z] - YYYY-MM-DD` is within ±1 day (UTC) of
  the release run, so a forgotten CHANGELOG date bump fails the workflow
  instead of shipping silently with the wrong date.
- **Caveman integration coverage**: `tests/integration/deploy_caveman.bats`
  runs the full wizard with `--caveman` against Copilot/Claude/Cursor
  combinations and asserts the role files materialise with correct
  frontmatter, so a regression that breaks caveman deploy on a single
  platform is now caught by CI.

### Changed

- **Release tarball is now built with `git archive`** instead of an
  explicit `tar -czf <list>`. The set of dev-only paths to omit lives
  in `.gitattributes` (`export-ignore`), so adding a new top-level
  runtime directory no longer requires a coordinated workflow change —
  the tarball stays in sync with the repo tree automatically. This
  closes the regression class that produced the v0.6.1 hotfix
  (`scripts/` was missing from v0.6.0). Closes #45.
- **Caveman roadmap is now discoverable**: the Deferred items in
  `docs/11-caveman-mode.md` § Not shipped are tracked as labelled
  (`caveman`) issues — hooks (#59), statusline (#60), and slash
  commands (#61) — and the table in the doc links to each one.
- **PR template check is now lenient**: the `Pull request template`
  job in `.github/workflows/ci.yml` matches required H2 sections
  case-insensitively and tolerates trailing punctuation or emojis
  (e.g. `## How to Test 🧪`). Minor formatting differences no longer
  silently fail the gate. Documented in `CONTRIBUTING.md` §7, along
  with the `gh pr edit` retrigger gotcha (close+reopen the PR or push
  a new commit).
- `CONTRIBUTING.md` §6: documents the `### Breaking Changes` subsection
  in the `[Unreleased]` block and ties it to the `feat!:` /
  `BREAKING CHANGE:` footer convention from §4. Listed first in each
  release block so downstream consumers see breakage before additions.
- `run_tests.sh`: prints an informational notice if `python3` is missing
  and exports `UNDERSTUDY_NO_PYTHON=1` so any future Python-dependent
  test can gate on it cleanly instead of failing with an opaque "command
  not found". Documented in `CONTRIBUTING.md` §8.

## [0.7.0] - 2026-04-29

### Added

- **Caveman evals harness** under `tests/evals/`:
  - `dogfood.py` — runs `scripts/understudy-compress` against any Markdown
    tree and reports per-file token reduction.
  - `three_arms.py` — measures input-token cost for three context bundles
    (no-caveman / role / role+compress) using the same fixture task.
  - `measure.py` — uses `tiktoken` (`cl100k_base`) when available, falls
    back to whitespace word count and labels its method honestly.
  - `run.sh` — orchestrator that regenerates `tests/evals/RESULTS.md` with
    sections delimited by HTML markers, so re-runs produce diffable output.
  - `RESULTS.md` — committed snapshot from this repo (terse `templates/docs/`,
    prose-heavy `docs/`, three-arm context measurement).

### Documentation

- Added an `Acknowledgments` section to `README.md` thanking
  [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) for
  inspiring caveman mode, and reinforced the upstream credit in the chapter
  intro of [docs/11-caveman-mode.md](docs/11-caveman-mode.md).
- `docs/02-quick-start.md`: new "Optional: caveman mode" subsection so the
  feature is discoverable from the quick start, not only from the index.
- `CONTRIBUTING.md`: added `caveman_role.bats` and `compress.bats` to the
  test-location table and documented the opt-in `tests/evals/` harness.
- `docs/11-caveman-mode.md`: marked the token evaluation harness as
  **Shipped** in the "Not shipped" table (it now lives at `tests/evals/`),
  and removed the dead reference to internal workspace memory.
- `docs/README.md`: clarified that file names keep their historical numeric
  prefix and added a sub-link from the chapter index to the evals harness.
- Fixed a corrupted emoji in the `README.md` optional-roles table (the
  `caveman` row now renders the dragon emoji correctly).

## [0.6.1] - 2026-04-29

### Fixed

- Release tarball was missing `scripts/` (the `understudy-compress` Python
  script and `requirements.txt` shipped in v0.6.0). The release workflow's
  explicit file list did not include `scripts/`, so users installing v0.6.0
  via the published tarball received the caveman role but not the compress
  script. v0.6.1 adds `scripts/` to the tarball and makes
  `scripts/understudy-compress` executable on install. Users on v0.6.0
  should re-run the installer one-liner to get the script.

## [0.6.0] - 2026-04-29

### Added

- **Caveman mode** — token-efficient AI collaboration, ported from
  [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) and
  adapted to Understudy's multi-platform model. Two surfaces:
  - **Optional `caveman` role** (`roles/caveman.instructions.md`) deployed
    to Copilot, Claude Code and Cursor. Opt-in via `./wizard.sh --caveman`
    or `./wizard.sh --add-member caveman`. Three intensity levels: lite,
    full (default), ultra. Preserves code, paths, URLs, GUARDRAILS markers,
    ADRs and `docs/decisions.md` byte-identically.
  - **`scripts/understudy-compress`** — Python 3.8+ Markdown compressor.
    Stdlib only by default; optional `tiktoken` for exact token counts via
    interactive prompt or `--yes`. `--dry-run` and `--restore` supported.
    Backup at `<file>.original.md`. Hard safety gates: refuses symlinks,
    files outside CWD, sensitive filenames (`.env`, `*secret*`,
    `*credential*`, `*private_key*`, `id_rsa`, `*.pem`, `*.key`, `*.p12`,
    `*.pfx`) and sensitive content (PEM blocks, AWS keys, GitHub PATs,
    JWTs, Slack tokens, `password=`, `api_key=`).
  - **`scripts/requirements.txt`** declaring optional `tiktoken` dep.
  - 12 new bats tests for the role (`tests/unit/caveman_role.bats`) and
    20 for the compress script (`tests/unit/compress.bats`).

### Documentation

- New chapter [Caveman Mode](docs/11-caveman-mode.md) with platform support
  matrix, intensity levels, safety gates, deferred-features rationale and
  honest disclaimer about output-only token effects.
- Platform comparison matrix updated with two new rows (caveman role,
  compress script) — supported on all four platforms.
- Docs index updated to link chapter 11.

### Notes

- Hooks, statuslines, slash commands and the wenyan post-processor from
  upstream are intentionally **not** ported. Rationale and revisit
  conditions documented in chapter 11 and in repository memory.

## [0.5.5] - 2026-04-29

### Fixed

- Auto-update prompt now actually waits for the user to answer. v0.5.4
  prevented silent auto-update by defaulting to `N` on EOF, but in
  environments where the script's stdin is closed by an outer wrapper
  the prompt received an instant EOF and resolved to `N` without giving
  the user a chance to type. `check_for_updates` now reads the answer
  directly from `/dev/tty`, so any buffered or closed stdin cannot
  pre-answer the prompt. If no controlling terminal is available the
  wizard skips the update with an explicit warning instead of guessing.

## [0.5.4] - 2026-04-28

### Fixed

- Auto-update prompt could trigger an unattended update. The "New
  Understudy version available — do you want to update now?" prompt used
  `confirm` with a `[Y/n]` default of "yes" *and* treated empty/EOF input
  as confirmation, so any environment that silently closed stdin (some
  PowerShell wrappers, non-interactive launchers, certain `bash -c`
  invocations) auto-accepted the update without the user pressing
  anything.
  - `confirm` now takes an explicit second argument for the default and
    only returns success on an explicit `y`/`yes` answer or when the
    default itself is `Y`. Empty input or EOF resolves to the provided
    default.
  - The auto-update call now passes `"N"` as the default so the prompt is
    rendered as `[y/N]` and any unanswered case continues with the
    installed version. Manual updates via the installer one-liner are
    unaffected.

## [0.5.3] - 2026-04-28

### Fixed

- Release tarball was missing `templates/.github/` (Copilot templates) due to
  an over-broad `--exclude='.github'` flag in the release workflow that also
  matched the nested `templates/.github/` directory. As a result, installs of
  v0.5.0–v0.5.2 via the published tarball failed at deploy time with
  `Missing Copilot template: .github/copilot-instructions.md`. The packaging
  step now only excludes the temporary archive itself; the explicit list of
  paths already keeps unwanted top-level dirs (`.git`, `.github`, `tests`)
  out of the tarball.

## [0.5.2] - 2026-04-28

### Changed

- `--here` Inferred settings summary now lists all 9 fields the manual wizard
  asks (project name, description, tech stack, repository URL, PM, guardrails
  mode, platforms, AI config visibility, session memory visibility) plus the
  target directory.
- The confirmation prompt in `--here` mode now accepts `e` (edit) in addition
  to `Y`/`n`. Choosing `e` opens an interactive editor where each inferred
  field can be modified by number before deploying (`d` to deploy, `q` to
  quit).

## [0.5.1] - 2026-04-28

### Added

- `--here` flag: deploy Understudy directly in the current directory using
  values inferred from the repository (project name from folder/`package.json`,
  description from `package.json` or `README.md`, stack/components from
  existing files, repository URL from `git remote`, PM from `git config`).
  Combine with `--yes` (or `-y`) to skip the confirmation prompt for fully
  unattended deploys (`./wizard.sh --here --yes`).
- README description fallback in `detect_existing_project()`: when no
  `package.json` description is available, the first paragraph of `README.md`
  is used (badges, blockquotes and headings are skipped).

## [0.5.0] - 2026-04-28

### Added

- New optional roles: **git-specialist** (Git workflows, branch policies, PR hygiene),
  **repo-documenter** (codebase understanding, architecture docs, onboarding guides)
  and **shell-scripting** (Bash/sh automation, cross-platform scripting, ShellCheck).
- Auto-deploy of optional roles: `git-specialist` and `repo-documenter` are always
  included; `shell-scripting` is added automatically when `*.sh`/`*.bash`/`*.zsh`
  files are detected in the project.
- Shell detection in `detect_existing_project()`: scans for `*.sh`, `*.bash`,
  `*.zsh` files and adds "Shell" to the detected stack.
- Multi-platform support for optional roles: `--add-member` and auto-deploy
  now generate role files for all active platforms (Copilot, Claude, Cursor)
  with proper frontmatter.

### Fixed

- `DETECTED_STACK` unbound variable crash when deploying to a new (empty)
  directory where `detect_existing_project()` was never called.
- Portable `sed`/`awk` usage for macOS (BSD) compatibility in team-roster
  updates and role title-casing.

## [0.4.4] - 2026-04-28

### Fixed

- `CHANGELOG.md`: added missing entries for v0.4.1, v0.4.2 and v0.4.3.
  Without these, `read_local_version()` always returned `v0.4.0` from the
  installed tarball, causing `check_for_updates()` to loop infinitely after
  a successful update.

## [0.4.3] - 2026-04-28

### Fixed

- `install.sh`: fixed banner padding with platform-independent calculation.
  Bash counts emoji width differently per platform (1 char on Linux/macOS,
  2 chars on Git Bash/Windows). Separated emoji from text in the padding
  formula so the result is consistent across all platforms.

## [0.4.2] - 2026-04-28

### Fixed

- `install.sh`: improved bash shell config detection — checks `.bash_profile`
  first (used by macOS login shells) before falling back to `.bashrc` (Linux).

## [0.4.1] - 2026-04-28

### Fixed

- `install.sh`: first attempt at aligning release banner (partial fix).

## [0.4.0] - 2026-04-28

### Added

- **Automatic update check**: `wizard.sh` now queries the GitHub Releases API at
  startup. If a newer version is available it asks the user whether to update
  immediately (runs the installer one-liner and re-executes the wizard).
  Skipped automatically in non-interactive runs (stdin not a tty) and in
  development clones (`.git` present next to `wizard.sh`). Can be suppressed
  with `export UNDERSTUDY_SKIP_UPDATE_CHECK=1`.
- `tests/unit/update_check.bats`: 8 unit tests for `read_local_version` and
  `version_is_newer` (major / minor / patch / equal / lower / prerelease).

### Changed

- `README.md`: added "Local-only mode" key concept so the v0.3.0 feature is
  visible from the project entry page.
- `docs/01-introduction.md`: noted that the wizard can append paths to
  `.gitignore` when local-only mode is enabled.
- `docs/02-quick-start.md`: updated the wizard question summary to include
  the local-only mode prompts.
- `docs/README.md`: linked the new "Local-only mode" subsection from the
  configuration entry in the docs index.

## [0.3.0] - 2026-04-27

### Added

- **Local-only mode**: two new wizard questions and `git.local_config` /
  `git.local_memory` keys in `understudy.yaml` — lets users keep AI config
  or session memory files out of git (appended to project `.gitignore`).
  Platform-aware: only gitignores files from selected platforms.
- `tests/unit/deploy_gitignore.bats`: 21 new unit tests for the new feature.
- `tests/unit/normalize_path.bats`: 14 cross-OS tests for path normalization.

### Fixed

- `deploy_file()`: replaced 18 `sed -i` calls with one portable `sed` + temp
  file, fixing macOS BSD sed incompatibility that broke all placeholder tests.
- `inject_guardrails_block()`: replaced `awk -v content=` with FNR==NR pattern,
  fixing macOS awk rejection of multiline `-v` strings.
- `ask()`: added `read -e` (readline) so arrow keys work in all terminals.
- `normalize_path()`: converts Windows paths (`C:/...` → `/c/...`) entered in
  Git Bash; shows OS-aware hint in the base-directory prompt.
- shellcheck: added SC2153 exclusion (false positive for eval-assigned vars).

### Changed

- `docs/03-platform-comparison.md` and all platform pages: added missing
  `Next:` navigation links so readers can follow the doc sequence.
- `docs/09-configuration.md`: added `git.*` fields; documented local-only mode.
- `docs/10-troubleshooting.md`: expanded integration mode FAQ; added
  "I don't want AI config in my repo" entry.
- `understudy.yaml`: removed non-existent `gpt-5.4` model from comments.

## [0.2.1] - 2026-04-27

### Fixed

- `wizard.sh`: replaced Bash 4-only lowercase expansion (`${var,,}`) in
  interactive confirmations/platform prompts with a Bash 3.2-compatible
  conversion helper, fixing integration flow on macOS runners.

### Changed

- `.github/workflows/ci.yml`: added a required PR body validation job that
  enforces core sections from `.github/PULL_REQUEST_TEMPLATE.md` and requires
  at least one selected item in `Type of change`.
- `README.md`: expanded documentation for Guardrails deployment modes with a
  practical `split` vs `embedded` comparison and selection rule-of-thumb.

## [0.2.0] - 2026-04-25

### Added

- `tests/`: bats-core test suite with 122 tests across 4 suites — unit tests
  for `config_read`, `detect_existing_project`, `deploy_file` and
  `inject_guardrails_block`; hook tests for `guardrails-check.sh`; and
  end-to-end integration tests for the full wizard deployment.
- `run_tests.sh`: local test runner with suite filtering (`unit`, `hooks`,
  `integration`, or `all`).
- `install.sh`: one-liner curl installer — downloads the latest GitHub Release,
  installs to `~/.understudy/`, creates the `understudy` command in
  `~/.local/bin/` and configures PATH. Supports `--version`, `--dir`,
  `--no-path` and `--uninstall`.
- `.github/workflows/tests.yml`: CI workflow that runs the bats suite on
  Ubuntu and macOS for every push and PR, plus shellcheck linting.
- `.github/workflows/release.yml`: CI workflow that publishes a GitHub Release
  automatically when a `vX.Y.Z` tag is pushed — extracts notes from
  `CHANGELOG.md` and attaches the release tarball.
- `CONTRIBUTING.md` section 8: contributor guide for the test suite —
  installation, running, test layout, anatomy, where to add tests, checklist,
  and two worked examples (new hook pattern, new platform).
- `CONTRIBUTING.md`: full contribution guide with commit conventions
  (Conventional Commits), semantic versioning, tags process and CHANGELOG maintenance.
- `.github/PULL_REQUEST_TEMPLATE.md`: PR template with standard checklist.
- `.github/ISSUE_TEMPLATE/bug_report.yml`: structured form for reporting bugs.
- `.github/ISSUE_TEMPLATE/feature_request.yml`: structured form for proposing features.
- `CODE_OF_CONDUCT.md`: Contributor Covenant v2.1 in English.
- `SECURITY.md`: responsible vulnerability disclosure policy.
- `docs/assets/social-preview.html` + `docs/assets/social-preview.png`:
  1280×640 banner for the repository *social preview* on GitHub.

### Fixed

- `wizard.sh`: replaced bare `main "$@"` call with a `BASH_SOURCE` guard so
  the file can be sourced by the test suite without triggering an interactive
  session.

### Changed

- `README.md`: new Installation section with one-liner, version pinning, and
  flag reference; Quick Start updated to use the `understudy` command.
- `CONTRIBUTING.md` section 5: release process expanded with CI automation
  explanation, tarball contents table, and step-by-step maintainer flow.
- `.gitignore`: extended with secrets (`*.key`, `*.pem`, `.env`), test
  artifacts, wizard-generated project directories, and `/.claude/`.

## [0.1.0] - 2026-04-22

### Added
- First public release of the Understudy system.
- `wizard.sh`: interactive wizard with automatic stack detection and monorepo support
  (up to 3 levels deep).
- `understudy.yaml`: global configuration with override hierarchy
  (system → project).
- 6 deployable core roles: Architect, Backend, Frontend, DevOps, Security, QA.
- Optional roles catalog: data-engineer, mobile-engineer, ml-engineer,
  tech-writer, sre.
- Compatibility with 3 platforms: GitHub Copilot CLI / VS Code,
  Claude Code, Cursor.
- Guardrails in `split` (recommended) or `embedded` modes.
- 8 guardrail categories: security, scope, process, destructive operations,
  data/PII, quality, environments, documentation.
- ASCII art banner (ANSI Shadow font) with cyan→violet gradient.
- CI with ShellCheck, bash syntax validation and markdown lint.
- MIT License.
