# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
