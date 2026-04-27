# 🎭 Team Roster — {{PROJECT_NAME}}

> Record of the active team on this project.
> The wizard generates this file automatically when deploying Understudy.
> Update it if you add or change team members.

## Core team

| Code name | Role | Instructions file | Status |
|---|---|---|---|
| **Architect** | Solutions Architect | `.github/instructions/architect.instructions.md` | ✅ Active |
| **Backend** | Backend Developer | `.github/instructions/backend.instructions.md` | ✅ Active |
| **Frontend** | Frontend Developer | `.github/instructions/frontend.instructions.md` | ✅ Active |
| **DevOps** | DevOps Engineer | `.github/instructions/devops.instructions.md` | ✅ Active |
| **Security** | Security Expert | `.github/instructions/security.instructions.md` | ✅ Active |
| **QA** | QA Engineer | `.github/instructions/qa-engineer.instructions.md` | ✅ Active |

## Extended team (added via wizard)

<!-- The wizard adds rows here when invoking "Add team member" -->

| Code name | Role | Instructions file | Status |
|---|---|---|---|
| <!-- new members here --> | | | |

## How to activate an agent

### In Copilot CLI
1. Open Copilot CLI in the project directory
2. Use `/agent` to select a team member
3. Or activate its instructions with `/instructions`
4. Use `/model` to select the recommended model (see `understudy.yaml`)

### In VS Code
1. Instructions are applied automatically based on the file you are editing
   (configured via `applyTo` frontmatter in each `.instructions.md`)
2. Reusable prompts are in `.github/prompts/` — invoke them from Copilot Chat
3. Use the model picker to select the recommended model for the task

## Model configuration

Recommended models per agent are in `understudy.yaml` at the project root.
Edit that file to change models without touching the instructions.

```yaml
models:
  architect: "claude-opus-4.6"    # deep reasoning
  backend: "claude-sonnet-4.5"    # quality/speed balance
  devops: "claude-haiku-4.5"      # economical for infra
  qa-engineer: "claude-sonnet-4.5" # test plans and tests
```

## How to add a member

Run the wizard with the add member option:
```bash
understudy --add-member
```
If you are using a manual clone of Understudy instead of the installed
command, run `./wizard.sh --add-member`.

Or copy a template from `roles/` to `.github/instructions/` and register it here.
