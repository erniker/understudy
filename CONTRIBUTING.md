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
8. [Tests](#8-tests)
9. [Local CI before opening a PR](#9-local-ci-before-opening-a-pr)
10. [Adding or modifying roles](#10-adding-or-modifying-roles)
11. [Code of conduct](#11-code-of-conduct)

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

There are no build dependencies. The wizard requires **bash ≥ 3.2** (compatible with macOS, Linux, and Windows WSL).
To contribute: clone the repo, then run the wizard with `./wizard.sh` or install globally with `./install.sh`.

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
Run `understudy --migrate` to update existing roles (or `./wizard.sh --migrate` if installed manually).
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

### How to publish a release

Pushing a tag triggers `.github/workflows/release.yml` automatically.
The workflow builds the release tarball and publishes a GitHub Release.
Users can then install it with the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

**Steps for maintainers:**

```bash
# 1. Make sure you're on main and in sync
git checkout main
git pull upstream main

# 2. Update CHANGELOG.md: rename [Unreleased] → [X.Y.Z] - YYYY-MM-DD
#    and add a new empty [Unreleased] section above (see section 6)

# 3. Commit the CHANGELOG
git add CHANGELOG.md
git commit -m "chore: release v0.2.0"

# 4. Create an annotated tag (not lightweight)
git tag -a v0.2.0 -m "Release v0.2.0

Summary of main changes:
- feat: new functionality X
- fix: fix for Y"

# 5. Push the commit and the tag — CI takes it from here
git push upstream main
git push upstream v0.2.0
```

After the push, CI will:

1. Extract the `[X.Y.Z]` section from `CHANGELOG.md` as release notes.
2. Validate that the date in `## [X.Y.Z] - YYYY-MM-DD` is within ±1 day
   (UTC) of the release run. The workflow fails otherwise — bump the
   date before re-tagging.
3. Build `understudy-vX.Y.Z.tar.gz` (wizard, templates, roles, docs — no test files).
4. Publish the GitHub Release with the tarball attached.

### What goes in the release tarball

| Included | Excluded |
| --- | --- |
| `wizard.sh`, `install.sh` | `.github/` (CI workflows) |
| `templates/` | `tests/` (test suite) |
| `roles/` | `run_tests.sh` |
| `understudy.yaml` | `*.tar.gz` |
| `docs/`, `README.md`, `CHANGELOG.md`, `LICENSE` | |

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

### Breaking Changes
- Description of a backward-incompatible change. Always listed first.

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

> **Breaking Changes convention.** Any commit landed with `feat!:` /
> `fix!:` / `BREAKING CHANGE:` footer (see §4) MUST add a bullet under
> `### Breaking Changes` in `[Unreleased]`. The subsection is listed
> **before** `### Added` so downstream consumers see breakage first.
> While the project is at `0.x.y`, breaking changes are still allowed in
> a MINOR bump (pre-1.0 SemVer), but they must still be marked.


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
- [ ] All tests pass locally: `./run_tests.sh` (see section 8).
- [ ] New functionality has tests covering the happy path and at least one negative case.
- [ ] Local CI passes (see section 9).
- [ ] Commits follow Conventional Commits.

### When opening the PR

- Fill out the complete template — don't delete sections.
- Reference the related issue with `Closes #NNN` or `Fixes #NNN`.
- If the PR is a **draft**, explicitly mark it as Draft.

### PR template check

The required check **"Pull request template"** validates that the PR
body keeps the H2 sections from `.github/PULL_REQUEST_TEMPLATE.md`
(`## Description`, `## Type of change`, `## What changes?`,
`## How to test`, `## Checklist`) and that at least one box under
`## Type of change` is checked. The match is case-insensitive and
tolerates trailing punctuation or emojis (e.g. `## How to Test 🧪`),
so minor formatting differences do not break the gate.

> **Gotcha — `gh pr edit` does not retrigger workflows.**
> If the check fails because of a body issue, fixing the body with
> `gh pr edit --body-file` will update the PR text but will **not**
> rerun the "Pull request template" job. To retrigger it, close and
> reopen the PR:
>
> ```bash
> gh pr close <NUMBER>
> gh pr reopen <NUMBER>
> ```
>
> Pushing a new commit also retriggers all checks and is the cleanest
> option when you also need to amend the diff.

### Review

- At least **1 approval** from a maintainer to merge.
- Review comments are resolved with a new commit or response, not silently.
- The author squashes/rebases to clean up "fix review" commits before the final merge.

### Merge

- Maintainers merge with **Squash and merge**.
- The final commit message in main follows Conventional Commits.

---

## 8. Tests

The test suite uses **[bats-core](https://github.com/bats-core/bats-core)** — the standard testing framework for bash.
All 122 tests must pass before a PR is merged. CI runs them automatically on Ubuntu and macOS.

### Install bats

```bash
# macOS
brew install bats-core

# Ubuntu / Debian / WSL
sudo apt install bats

# Any platform via npm
npm install -g bats
```

### Run the tests

```bash
# All suites
./run_tests.sh

# One suite at a time
./run_tests.sh unit         # unit tests (config, detection, deploy, guardrails)
./run_tests.sh hooks        # guardrails hook tests
./run_tests.sh integration  # end-to-end deployment tests

# A single file directly
bats tests/unit/config_read.bats
```

### Optional: python3

`run_tests.sh` is pure Bash and does **not** require `python3`. The runner
prints a friendly notice if `python3` is missing and exports
`UNDERSTUDY_NO_PYTHON=1` so any future test that depends on Python can
gate on it cleanly:

```bash
# inside a future python-dependent .bats file
[[ -n "${UNDERSTUDY_NO_PYTHON:-}" ]] && skip "python3 not available"
```

The opt-in `tests/evals/` harness has its own Python requirement and is
not driven by `run_tests.sh` — see the section below.

### Test layout

```
tests/
├── lib/
│   └── helpers.bash                      # Shared setup: sources wizard.sh safely,
│                                         # creates/tears down temp dirs
├── fixtures/
│   ├── configs/                          # YAML files for config_read tests
│   │   ├── full.yaml                     # All keys present
│   │   ├── partial.yaml                  # Only some keys
│   │   └── empty.yaml                    # Empty file (default fallback)
│   ├── fake-node-project/                # React + Node.js project structure
│   ├── fake-dotnet-project/              # .csproj project structure
│   ├── fake-python-project/              # requirements.txt project
│   └── fake-monorepo/                    # React + Node + Terraform + Docker
├── unit/
│   ├── config_read.bats                  # YAML parser: values, defaults, missing files
│   ├── detect_existing_project.bats      # Stack detection: Node/React/Vue/Angular,
│   │                                     # .NET, Python, Terraform, Docker, Monorepo
│   ├── deploy_file.bats                  # Placeholder substitution + file preservation
│   ├── deploy_gitignore.bats             # Local-only mode: .gitignore generation per platform
│   ├── inject_guardrails.bats            # Guardrail injection: split vs embedded modes
│   ├── normalize_path.bats               # Windows/Unix path normalization (Git Bash, WSL)
│   └── update_check.bats                 # Version comparison + local version detection
├── hooks/
│   └── guardrails_check.bats             # Hook blocks destructive commands (exit 2),
│                                         # warns on secrets (exit 0), allows safe ops
└── integration/
    ├── deploy_all_platforms.bats         # Full wizard run: files created, placeholders
    │                                     # replaced, integration mode preserves files
    └── deploy_caveman.bats                # Full wizard run with --caveman: opt-in
                                          # caveman role deploys to all 3 platforms
```

### Anatomy of a test

```bash
#!/usr/bin/env bats
load "../lib/helpers"       # gives you: source_wizard_functions, setup_tmp, teardown_tmp

setup() {
  setup_tmp                 # creates $TEST_TMP — isolated per test, auto-cleaned
  source_wizard_functions   # loads wizard.sh functions without running main()
}

teardown() { teardown_tmp; }

@test "config_read returns the architect model" {
  run config_read "models" "architect" "fallback" "$FIXTURES/configs/full.yaml"
  [ "$status" -eq 0 ]
  [ "$output" = "claude-opus-4.6" ]
}
```

Key conventions:

- `run <command>` captures exit code (`$status`) and stdout (`$output`) without aborting the test.
- Use `[ "$status" -eq 0 ]` for exit code assertions and `[ "$output" = "..." ]` for output.
- Use `[[ "$output" == *"substring"* ]]` for partial matches.
- Each `@test` is fully independent — no shared state between tests.

### Where to put new tests

| What you changed | Where to add tests |
| --- | --- |
| `config_read` or YAML parsing | `tests/unit/config_read.bats` |
| Stack detection (`detect_existing_project`) | `tests/unit/detect_existing_project.bats` |
| Placeholder substitution (`deploy_file`) | `tests/unit/deploy_file.bats` |
| Guardrail injection (`inject_guardrails_block`, `generate_guardrails_critical`) | `tests/unit/inject_guardrails.bats` |
| New destructive pattern in `guardrails-check.sh` | `tests/hooks/guardrails_check.bats` |
| New platform, new files deployed, new wizard flag | `tests/integration/deploy_all_platforms.bats` |
| New fixture needed for detection | `tests/fixtures/` |
| Update checker (`read_local_version`, `version_is_newer`) | `tests/unit/update_check.bats` |
| Path normalization (`normalize_path`) | `tests/unit/normalize_path.bats` |
| Git integration / `.gitignore` generation | `tests/unit/deploy_gitignore.bats` |
| `caveman` role file or wizard wiring | `tests/unit/caveman_role.bats` (unit) and `tests/integration/deploy_caveman.bats` (end-to-end wizard run) |
| `scripts/understudy-compress` (rules, safety gates, restore) | `tests/unit/compress.bats` |

### Caveman evals harness (opt-in)

The directory [`tests/evals/`](../tests/evals/README.md) ships a separate,
opt-in measurement harness for [caveman mode](../docs/11-caveman-mode.md). It
is **not** wired into `./run_tests.sh` and does not gate CI — it produces
human-readable token-reduction numbers in `tests/evals/RESULTS.md`. Run it
manually after changes to the role, the compress script, or the template
fixtures it consumes:

```bash
./tests/evals/run.sh        # regenerates tests/evals/RESULTS.md
```

The harness uses `tiktoken` (cl100k_base) when available and falls back to
whitespace word count otherwise; method is labelled in the output.

### Writing tests for a new feature — checklist

When you add or modify functionality in `wizard.sh` or `guardrails-check.sh`, follow this checklist:

- [ ] **Unit test** for each new function or modified logic branch.
- [ ] **One test per assertion** — don't combine unrelated checks in a single `@test`.
- [ ] **Use `$TEST_TMP`** for any files created during the test, never hardcoded paths.
- [ ] **Add fixtures** to `tests/fixtures/` if your test needs a specific file structure.
- [ ] **Integration test** if you add a new file to the wizard's output (verify it's created and contains expected content).
- [ ] **Negative tests** — test that things that should NOT happen actually don't (e.g., file not overwritten, command not blocked).
- [ ] Run `./run_tests.sh` locally before pushing.

### Example: adding a new destructive pattern to the hook

Say you want the hook to also block `az group delete`:

1. Add the pattern to `guardrails-check.sh`:

   ```bash
   DESTRUCTIVE_PATTERNS=(
       ...
       "az group delete"   # ← new pattern
   )
   ```

2. Add two tests to `tests/hooks/guardrails_check.bats`:

   ```bash
   @test "blocks: az group delete" {
     run bash "$HOOK" "az group delete --name my-rg --yes"
     [ "$status" -eq 2 ]
   }

   @test "allows: az group show (read-only)" {
     run bash "$HOOK" "az group show --name my-rg"
     [ "$status" -eq 0 ]
   }
   ```

3. Run the hook suite to confirm:

   ```bash
   ./run_tests.sh hooks
   ```

### Example: adding a new platform

Say you add support for a `--jetbrains` platform. You'll need:

1. New template files under `templates/.jetbrains/`.
2. A new `deploy_jetbrains()` function in `wizard.sh`.
3. Tests in `tests/integration/deploy_all_platforms.bats`:

   ```bash
   @test "full deploy creates JetBrains config file" {
     run_wizard_noninteractive "myproject" "$TEST_TMP" "Y" "Y" "Y" "Y"
     [ -f "$TEST_TMP/myproject/.jetbrains/understudy.xml" ]
   }
   ```

---

## 9. Local CI before opening a PR

The CI runs three checks. You can run them locally to avoid waiting for the workflow:

```bash
# Run the full test suite first (unit + hooks + integration)
./run_tests.sh

# ShellCheck (install with: brew install shellcheck / apt install shellcheck)
shellcheck -e SC2155 -e SC1091 -e SC2034 -e SC2154 wizard.sh
find templates -name "*.sh" -exec shellcheck -e SC2155 -e SC1091 {} \;

# Bash syntax validation
bash -n wizard.sh
find templates -name "*.sh" -exec bash -n {} \;

# Markdown lint (install with: npm install -g markdownlint-cli2)
markdownlint-cli2 "README.md" "docs/**/*.md"
```

### wizard.sh — rules for contributors

`wizard.sh` runs on **bash 3.2+** (macOS ships 3.2 by default). Three things to keep in mind:

#### 1. No bash 4+ features

| ❌ Avoid | ✅ Use instead |
| --- | --- |
| `${var,,}` (lowercase) | `to_lower "$var"` (helper already defined) |
| `${var^^}` (uppercase) | `echo "$var" \| tr '[:lower:]' '[:upper:]'` |
| `declare -A` (assoc arrays) | parallel indexed arrays |
| `mapfile` / `readarray` | `while IFS= read -r` loop |

#### 2. Portable sed and awk

macOS ships BSD sed and One True AWK — both differ from GNU versions:

- Never use `sed -i "script" file` — BSD sed treats the first arg as backup suffix. Use `sed "script" file > file.tmp && mv file.tmp file` instead.
- Never pass multiline strings via `awk -v var="..."` — use the `FNR==NR` pattern with a temp file instead.

#### 3. Update integration tests when adding wizard questions

`tests/integration/deploy_all_platforms.bats` pipes pre-filled answers to the wizard via stdin. When you add a new `ask()` or `confirm()` call inside `gather_project_info()`, you **must** also add an answer in `run_wizard_noninteractive()` and update its comment. The order of answers must exactly match the order of questions.

### PR body format

The CI validates that your PR body contains these exact headings:

```
## Description
## Type of change
## What changes?
## How to test
## Checklist
```

`Type of change` must also have at least one checked item (`- [x]`). The easiest way to get this right is to use the GitHub PR form which pre-fills the template.

---

## 10. Adding or modifying roles

Optional roles live in `roles/`. Follow the structure of existing roles:

```
roles/
  my-role.instructions.md   ← role instructions (Markdown)
```

Each file has YAML frontmatter with `applyTo` and the body in Markdown.
See `roles/data-engineer.instructions.md` as a reference.

When deployed via `--add-member` or auto-deploy, the wizard generates
platform-specific files for every active platform:

| Platform | Destination | Extra frontmatter |
|---|---|---|
| Copilot | `.github/instructions/<role>.instructions.md` | — |
| Claude | `.claude/agents/<role>.md` | `name`, `description`, `model`, `tools` |
| Cursor | `.cursor/agents/<role>.md` | `name`, `description`, `model` |

If the new role makes sense for the general community, open a PR.
If it's very domain-specific, keep it in your fork or in a local `roles/`.

---

## 11. Code of conduct

This project is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you agree to its terms.

---

Questions? Open a [Discussion](https://github.com/erniker/understudy/discussions) on GitHub.
