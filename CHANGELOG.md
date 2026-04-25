# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
