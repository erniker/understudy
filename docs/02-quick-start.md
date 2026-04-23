# 2. Quick Start

Works the same way on Linux, macOS and Windows (Git Bash or WSL).

```bash
# 1. Clone Understudy
git clone https://github.com/erniker/understudy.git
cd understudy

# 2. Make the wizard executable
chmod +x wizard.sh

# 3. Run the wizard from the folder where you want your project
./wizard.sh
#  → Asks project name, stack, PM, platforms (Copilot / Claude / Cursor),
#    guardrails mode (split/embedded) and optional team members.
#  → Detects existing projects and offers integration mode.

# 4. Open the tool you use in that project
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
./wizard.sh --add-member       # pick from roles/ (data, ML, mobile, SRE, tech-writer)
./wizard.sh --create-role      # interactive wizard to design a new role
```

Roles created with `--create-role` are stored in `roles/` and will be
available in every future deployment.

---

Next: [Platform Capability Matrix](03-platform-comparison.md)
