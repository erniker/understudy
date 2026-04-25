# 2. Quick Start

Works the same way on Linux, macOS and Windows (Git Bash or WSL).

## Install

**One-liner (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

Then open a new terminal so the `understudy` command is available.

**Manual (git clone):**

```bash
git clone https://github.com/erniker/understudy.git
cd understudy
chmod +x wizard.sh
# use ./wizard.sh instead of understudy in the commands below
```

## Deploy in a project

```bash
# Run from anywhere — the wizard asks where to deploy
understudy
#  → Asks project name, stack, PM, platforms (Copilot / Claude / Cursor),
#    guardrails mode (split/embedded) and optional team members.
#  → Detects existing projects and offers integration mode.

# Then open your AI tool in the generated project
copilot           # GitHub Copilot CLI
# or open VS Code with Copilot enabled
claude            # Claude Code
cursor .          # Cursor
```

## What just happened

- Files were generated only for the platforms you selected.
- `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md` and
  `docs/team-roster.md` were scaffolded.
- Guardrails were deployed according to `understudy.yaml → guardrails.mode`
  (`split` keeps them in a dedicated file, `embedded` inlines critical rules).
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
understudy --add-member       # pick from roles/ (data, ML, mobile, SRE, tech-writer)
understudy --create-role      # interactive wizard to design a new role
```

Roles created with `--create-role` are stored in `roles/` and will be
available in every future deployment.

## Update Understudy

```bash
# Re-run the installer to get the latest version
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash

# Or pin to a specific version
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash -s -- --version v1.2.0
```

---

Next: [Platform Capability Matrix](03-platform-comparison.md)
