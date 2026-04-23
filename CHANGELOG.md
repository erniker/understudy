# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `CONTRIBUTING.md`: full contribution guide with commit conventions
  (Conventional Commits), semantic versioning, tags process and CHANGELOG maintenance.
- `.github/PULL_REQUEST_TEMPLATE.md`: PR template with standard checklist.
- `.github/ISSUE_TEMPLATE/bug_report.yml`: structured form for reporting bugs.
- `.github/ISSUE_TEMPLATE/feature_request.yml`: structured form for proposing features.
- `CODE_OF_CONDUCT.md`: Contributor Covenant v2.1 in English.
- `SECURITY.md`: responsible vulnerability disclosure policy.
- `docs/assets/social-preview.html` + `docs/assets/social-preview.png`:
  1280×640 banner for the repository *social preview* on GitHub,
  with ASCII logo (ANSI Shadow) in cyan→violet gradient and role pills.

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
