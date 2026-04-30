# 2. Quick Start

Works the same way on Linux, macOS and Windows (Git Bash or WSL).

## Install

**One-liner (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

Then open a new terminal so the `understudy` command is available.

Unless noted otherwise, the commands in the rest of this guide assume you are
using the installed `understudy` command.

**Manual (git clone):**

```bash
git clone https://github.com/erniker/understudy.git
cd understudy
chmod +x wizard.sh
# if you use a manual clone, replace `understudy` with `./wizard.sh`
```

## Deploy in a project

```bash
# Run from anywhere — the wizard asks where to deploy
understudy
#  → Asks project name, stack, PM, platforms (Copilot / Claude / Cursor),
#    guardrails mode (split/embedded), local-only mode (keep AI config and/or
#    session memory out of git) and optional team members.
#  → Detects existing projects and offers integration mode.

# Then open your AI tool in the generated project
copilot           # GitHub Copilot CLI
# or open VS Code with Copilot enabled
claude            # Claude Code
cursor .          # Cursor
```

### Zero-question deploy (`--here`)

If you're already inside an existing repository, skip the questions and let
Understudy infer everything from the working tree:

```bash
cd /path/to/your/repo
understudy --here          # shows inferred settings, asks one confirmation
understudy --here --yes    # fully unattended, no prompts at all
```

Inferred from the repo: project name (folder / `package.json`), description
(`package.json` or first paragraph of `README.md`), stack (Node / React /
.NET / Python / Terraform / Docker / Shell …), repository URL (`git remote`)
and PM (`git config user.name`). Sensible defaults are used for non-inferable
choices (`split` guardrails, all three platforms, files committed).

The wizard prints a numbered summary of all 9 settings (the same questions
the interactive wizard asks) and offers three answers at the confirmation
prompt:

- **`Y`** — deploy with the inferred values (default).
- **`n`** — cancel.
- **`e`** — enter the editor: type the field number (`1`-`9`), provide a new
  value, and repeat. When ready, type `d` to deploy or `q` to quit.

For full control, run without `--here` to launch the interactive wizard.

## What just happened

- Files were generated only for the platforms you selected.
- `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md` and
  `docs/team-roster.md` were scaffolded.
- Guardrails were deployed according to `understudy.yaml → guardrails.mode`
  (`split` keeps them in a dedicated file, `embedded` inlines critical rules).
- If you opted into local-only mode, the affected paths were appended to the
  project's `.gitignore` (see [Configuration → Local-only mode](09-configuration.md#local-only-mode)).
- Optional roles were auto-deployed: `git-specialist` and `repo-documenter`
  are always included, and `shell-scripting` is added when shell scripts are
  detected.
- Nothing else in your repository was modified.

## First session, step by step

1. Open your AI tool in the project.
2. Ask the assistant to read the context files:

   ```
   Read docs/spec.md, docs/decisions.md and docs/session-log.md
   and summarize the current state of the project.
   ```

   On VS Code and Claude Code there are ready-made prompts/commands for this
   (see the per-platform pages).
3. Switch to the role you need (see per-platform pages).
4. At the end of the session, ask:

   ```
   Update docs/session-log.md with what we did today,
   what is pending and any new decisions.
   ```

## Extending the team

```bash
understudy --add-member       # pick from roles/ — deploys to all active platforms
understudy --create-role      # interactive wizard to design a new role
```

Roles created with `--create-role` are stored in `roles/` and will be
available in every future deployment.

## Optional: caveman mode (token-efficient)

If you want shorter, denser AI replies and a smaller context bill, opt into
[caveman mode](11-caveman-mode.md):

```bash
understudy --caveman          # add the caveman role at deploy time
understudy --add-member caveman   # add it to an existing deployment
```

For the prose Understudy itself generates, the bundled compress script can
shrink Markdown in place (preserving code, paths, URLs and GUARDRAILS):

```bash
modules/caveman/bin/understudy-compress docs/spec.md     # writes docs/spec.original.md backup
modules/caveman/bin/understudy-compress --restore docs/spec.md
```

Full rationale, intensity levels, safety gates and the
[evals harness](../modules/caveman/evals/README.md) live in chapter 11.

## Update Understudy

Every time you invoke `understudy`, it checks if a newer release exists and can
prompt you to update immediately.

```bash
# Re-run the installer to get the latest version
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash

# Or pin to a specific version
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash -s -- --version v1.2.0

# Disable auto-check (useful for CI/offline)
export UNDERSTUDY_SKIP_UPDATE_CHECK=1
```

---

Next: [Platform Capability Matrix](03-platform-comparison.md)
