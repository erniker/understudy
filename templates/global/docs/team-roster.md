# 🎭 Team Roster — {{PROJECT_NAME}}

> Record of the active team on this project.
> This repo uses the **global** Understudy team (deployed once via
> `understudy --global`) rather than project-specific agent files — this
> file exists so ADRs and session logs can reference team members by name.

## Core team (available globally, not deployed to this repo)

| Code name | Role | Where it lives |
|---|---|---|
| **Architect** | Solutions Architect | Claude: `~/.claude/agents/architect.md` · Copilot: VS Code profile · Cursor: User Rules |
| **Backend** | Backend Developer | Claude: `~/.claude/agents/backend.md` · Copilot: VS Code profile · Cursor: User Rules |
| **Frontend** | Frontend Developer | Claude: `~/.claude/agents/frontend.md` · Copilot: VS Code profile · Cursor: User Rules |
| **DevOps** | DevOps Engineer | Claude: `~/.claude/agents/devops.md` · Copilot: VS Code profile · Cursor: User Rules |
| **Security** | Security Expert | Claude: `~/.claude/agents/security.md` · Copilot: VS Code profile · Cursor: User Rules |
| **QA** | QA Engineer | Claude: `~/.claude/agents/qa.md` · Copilot: VS Code profile · Cursor: User Rules |

## Extended team

<!-- Rows added via "understudy --global --add-member" go here -->

| Code name | Role | Status |
|---|---|---|
| <!-- new members here --> | | |

## Want project-specific agents instead?

If you need per-repo customization (different models per role, `apply_to`
scoping tailored to this repo's stack, project-specific instructions instead
of the shared global ones), run `understudy --here` in this repo — it
deploys the full per-project agent set on top of what's already here,
without losing anything.

## Model configuration

Recommended models per role were set when `understudy --global` ran. See
`~/.claude/agents/*.md` frontmatter (Claude) or ask the agent directly for
the Copilot/Cursor model in use.
