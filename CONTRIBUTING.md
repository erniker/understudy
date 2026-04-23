# Contribution Guide — Understudy

Thank you for wanting to contribute to Understudy. This document explains how we work:
code conventions, commits, versioning, changelogs and the pull request process.

---

## Table of Contents

1. [Getting started](#1-getting-started)
2. [Reporting bugs and proposing features](#2-reporting-bugs-and-proposing-features)
3. [Git workflow](#3-git-workflow)
4. [Commit conventions](#4-commit-conventions)
5. [Versioning and tags](#5-versioning-and-tags)
6. [CHANGELOG maintenance](#6-changelog-maintenance)
7. [Pull request process](#7-pull-request-process)
8. [Local CI before opening a PR](#8-local-ci-before-opening-a-pr)
9. [Adding or modifying roles](#9-adding-or-modifying-roles)
10. [Code of conduct](#10-code-of-conduct)

---

## 1. Getting started

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/<your-username>/understudy.git
cd understudy

# 3. Add the original repo as upstream
git remote add upstream https://github.com/erniker/understudy.git

# 4. Keep your fork in sync before each contribution
git fetch upstream
git rebase upstream/main
```

There are no build dependencies. The only requirement to run the wizard is bash ≥ 4.
On macOS install an updated bash with `brew install bash`.

---

## 2. Reporting bugs and proposing features

Use the GitHub **issue templates**:

- 🐛 **Bug report** — for incorrect behavior or errors
- ✨ **Feature request** — for proposing new functionality

Before opening an issue, search if a similar one already exists in
[Issues](https://github.com/erniker/understudy/issues).

---

## 3. Git workflow

### Branches

| Pattern | Purpose |
|---|---|
| `feat/<description>` | New functionality |
| `fix/<description>` | Bug fix |
| `docs/<description>` | Documentation only |
| `refactor/<description>` | Refactoring without behavior change |
| `chore/<description>` | Maintenance tasks (deps, CI, etc.) |
| `release/v<X.Y.Z>` | Release preparation branch |

```bash
# Create working branch
git checkout -b feat/add-platform-engineer-role

# ... work ...

# Sync before opening PR
git fetch upstream
git rebase upstream/main
```

### Merge policy

- PRs are integrated with **squash merge** into `main`.
- Each commit in `main` represents a complete logical change.
- No direct merge to `main` without a PR (except maintainers on critical fixes).

---

## 4. Commit conventions

We use **Conventional Commits** ([spec](https://www.conventionalcommits.org/en/v1.0.0/)).

### Format

```
<type>[optional scope]: <short description in imperative>

[optional body — explains WHAT and WHY, not how]

[optional footer — refs to issues, breaking changes]
```

### Valid types

| Type | When to use |
|---|---|
| `feat` | New user-facing functionality |
| `fix` | Bug fix |
| `docs` | Documentation-only changes |
| `refactor` | Refactoring without external behavior change |
| `test` | Adding or fixing tests |
| `ci` | Changes to CI/CD or automation scripts |
| `chore` | Maintenance changes (no production code impact) |
| `perf` | Performance improvements |

### Breaking changes

If the change breaks backward compatibility, add `!` after the type or a `BREAKING CHANGE:` footer:

```
feat!: change roles/ structure — directory now requires frontmatter

BREAKING CHANGE: Files in roles/ without YAML frontmatter are no longer valid.
Run `./wizard.sh --migrate` to update existing roles.
```

### Examples

```
feat(wizard): add --upgrade flag to update existing deployments
fix(wizard): detect monorepo when package.json is in subdirectory
docs(tutorial): add chapter on Windows/WSL usage
ci: add bats integration tests
chore: bump markdownlint-cli2-action to v17
```

---

## 5. Versioning and tags

We follow **Semantic Versioning** ([semver.org](https://semver.org/spec/v2.0.0.html)):
`MAJOR.MINOR.PATCH`

| Component | When it increments |
|---|---|
| `MAJOR` | Incompatible change with previous versions (breaking change) |
| `MINOR` | New functionality compatible with previous versions |
| `PATCH` | Bug fix compatible with previous versions |

While the project is at version `0.x.y`, MINOR may contain breaking changes
(this is the pre-1.0 SemVer convention).

### How to create a release tag

Only maintainers create tags. The process is:

```bash
# 1. Make sure you're on main and in sync
git checkout main
git pull upstream main

# 2. Update the version in CHANGELOG.md (see section 6)

# 3. Commit the CHANGELOG
git add CHANGELOG.md
git commit -m "chore: release v0.2.0"

# 4. Create an annotated tag (not lightweight)
git tag -a v0.2.0 -m "Release v0.2.0

Summary of main changes:
- feat: new functionality X
- fix: fix for Y"

# 5. Push the commit and the tag
git push upstream main
git push upstream v0.2.0
```

### Tag rules

- **Always annotated** (`-a`), never lightweight — they include date, author and message.
- Format: `v` + semver number → `v0.1.0`, `v1.0.0`, `v1.2.3`.
- The tag message summarizes the main changes (it's not a complete CHANGELOG).
- A tag always points to the `chore: release vX.Y.Z` commit.
- **Never delete or move a published tag** — if there's an error, create a new patch.

---

## 6. CHANGELOG maintenance

`CHANGELOG.md` follows the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

### Structure

```markdown
## [Unreleased]

### Added
- Description of new functionality.

### Changed
- Description of change to existing functionality.

### Deprecated
- Functionality that will be removed in the next major.

### Removed
- Removed functionality.

### Fixed
- Fixed bug.

### Security
- Fixed vulnerability.
```

### Rules

1. **Always keep an `[Unreleased]` section** at the top to accumulate changes
   from work in progress. Never leave it empty — if there are no changes, the section doesn't exist.

2. **When releasing**, rename `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD` and add
   a new empty `[Unreleased]` section above.

3. **One entry = one logical change**. Don't aggregate multiple changes in one line.

4. **Write for the user**, not the developer. Explain the impact,
   not the implementation details.

5. **Don't include commit hashes** — the CHANGELOG is for humans, not machines.

### Who updates the CHANGELOG

- The PR author updates `[Unreleased]` with their change before requesting review.
- The maintainer updates the section when doing the release.

### Full cycle example

```markdown
# State during development (before release)
## [Unreleased]

### Added
- `--upgrade` flag to update existing deployments.

### Fixed
- Incorrect monorepo detection when package.json is in a subdirectory.

# State after release v0.2.0
## [Unreleased]

## [0.2.0] - 2026-05-15

### Added
- `--upgrade` flag to update existing deployments.

### Fixed
- Incorrect monorepo detection when package.json is in a subdirectory.
```

---

## 7. Pull request process

### Before opening the PR

- [ ] The branch is in sync with `upstream/main` (rebase, not merge).
- [ ] `CHANGELOG.md` has an entry under `[Unreleased]`.
- [ ] Local CI passes (see section 8).
- [ ] Commits follow Conventional Commits.

### When opening the PR

- Fill out the complete template — don't delete sections.
- Reference the related issue with `Closes #NNN` or `Fixes #NNN`.
- If the PR is a **draft**, explicitly mark it as Draft.

### Review

- At least **1 approval** from a maintainer to merge.
- Review comments are resolved with a new commit or response, not silently.
- The author squashes/rebases to clean up "fix review" commits before the final merge.

### Merge

- Maintainers merge with **Squash and merge**.
- The final commit message in main follows Conventional Commits.

---

## 8. Local CI before opening a PR

The CI runs three checks. You can run them locally to avoid waiting for the workflow:

```bash
# ShellCheck (install with: brew install shellcheck / apt install shellcheck)
shellcheck -e SC2155 -e SC1091 -e SC2034 -e SC2154 wizard.sh
find templates -name "*.sh" -exec shellcheck -e SC2155 -e SC1091 {} \;

# Bash syntax validation
bash -n wizard.sh
find templates -name "*.sh" -exec bash -n {} \;

# Markdown lint (install with: npm install -g markdownlint-cli2)
markdownlint-cli2 "README.md" "docs/**/*.md"
```

---

## 9. Adding or modifying roles

Optional roles live in `roles/`. Follow the structure of existing roles:

```
roles/
  my-role.instructions.md   ← role instructions for Copilot/VS Code
```

Each file has YAML frontmatter with `applyTo` and the body in Markdown.
See `roles/data-engineer.instructions.md` as a reference.

If the new role makes sense for the general community, open a PR.
If it's very domain-specific, keep it in your fork or in a local `roles/`.

---

## 10. Code of conduct

This project is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you agree to its terms.

---

Questions? Open a [Discussion](https://github.com/erniker/understudy/discussions) on GitHub.
