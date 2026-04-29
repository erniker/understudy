# 🎭 Understudy — One AI, Every Role

> A system that configures specialized AI agents in any project.
> One assistant, multiple roles: Architect, Backend, Frontend, DevOps, Security, QA.
> Compatible with **GitHub Copilot CLI**, **VS Code**, **Claude Code** and **Cursor**.

## Installation

**One-liner** (Linux, macOS, Windows Git Bash / WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

This downloads the latest release, installs it to `~/.understudy/` and adds the
`understudy` command to your PATH.

**Specific version:**

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash -s -- --version v1.0.0
```

**Manual (clone):**

```bash
git clone https://github.com/erniker/understudy.git
cd understudy
chmod +x wizard.sh
```

> See [install options](#install-options) for `--dir`, `--no-path` and `--uninstall`.

## Quick Start

```bash
# Deploy Understudy in any project
cd /path/to/your/project
understudy
# → Choose platforms: Copilot, Claude Code, Cursor

# Then open your AI tool
claude            # Claude Code
copilot           # GitHub Copilot CLI
cursor .          # Cursor
```

### Zero-question deploy (`--here`)

Already inside an existing repo and don't want to answer the wizard's
questions? Use `--here` — Understudy infers project name, description,
stack, repository URL and PM from the files in your working directory:

```bash
cd /path/to/your/project
understudy --here          # shows inferred values, asks one confirmation
understudy --here --yes    # fully unattended, no prompts
```

What gets inferred:

- **Project name** — from the folder name or root `package.json`
- **Description** — from `package.json` or the first paragraph of `README.md`
- **Stack** — Node.js / React / Vue / Angular / .NET / Python / Terraform / Docker / Shell
- **Repository URL** — from `git remote get-url origin`
- **PM** — from `git config user.name`

The wizard prints a numbered summary of all 9 settings (the same questions
the interactive wizard asks) and offers three options at the confirmation
prompt:

- **`Y`** — deploy with the inferred settings (default).
- **`n`** — cancel.
- **`e`** — edit any field interactively. You enter the field number
  (`1`-`9`), provide a new value, and repeat until satisfied. Then `d` to
  deploy or `q` to quit.

Defaults applied for non-inferable choices: `split` guardrails, all three
platforms enabled, files committed to the repo. Run without `--here` for
the full interactive wizard if you need to customize them.

### Install options

| Flag | Description |
|---|---|
| `--version <tag>` | Install a specific version (e.g. `v1.2.0`) |
| `--dir <path>` | Custom install directory (default: `~/.understudy`) |
| `--no-path` | Skip PATH setup |
| `--uninstall` | Remove Understudy from the system |

### Automatic update checks

When you run `understudy`, it checks for a new release on GitHub.
If a newer version exists, it asks whether you want to update now.

To disable this check (for CI or offline environments):

```bash
export UNDERSTUDY_SKIP_UPDATE_CHECK=1
```

## What is this?

A system that automatically generates all the configuration needed for
**GitHub Copilot CLI**, **VS Code**, **Claude Code** and **Cursor** to work as a complete development team:

| Member | Role | Expertise |
|---|---|---|
| 🏛️ **Architect** | Solutions Architect | System design, APIs, databases, cloud |
| ⚙️ **Backend** | Backend Developer | .NET, Node.js, C#, TypeScript, Python, Bash |
| 🎨 **Frontend** | Frontend Developer | React, TypeScript, UX/UI, accessibility |
| 🚀 **DevOps** | DevOps Engineer | Azure, AWS, Docker, K8s, Terraform, CI/CD |
| 🔒 **Security** | Security Expert | OWASP, threat modeling, compliance, IAM |
| 🧪 **QA** | QA Engineer | Testing .NET, Node.js, Python, E2E, contract testing |

## Key Concepts

### 1. AGENTS.md — "Who is the team"
A file at the project root that defines agents selectable with `/agent` in Copilot CLI.
Each agent has a name, role, expertise and behavioral rules.

### 2. .github/copilot-instructions.md — "Project rules"
Global instructions that Copilot loads **automatically** in every session.
Defines project context, conventions and workflow.

### 3. .github/instructions/*.instructions.md — "How each member works"
Modular instruction files per role. Activated with `/instructions`
or loaded alongside the corresponding agent. They contain the detailed personality,
code standards and checklists for each member.

### 4. Parallel sub-agents — "Divide and conquer"
Copilot CLI can launch sub-agents (task tool) that work in parallel.
Ideal for Backend and Frontend to implement simultaneously while
DevOps prepares the infrastructure.

### 5. Context files — "Memory between sessions"
The files `docs/session-log.md`, `docs/spec.md` and `docs/decisions.md`
act as persistent memory. At the start of each session the agent reads them;
at the end, it updates them. This saves tokens and avoids repeating information.

### 6. 🛡️ Guardrails — "What we NEVER do"
Security and behavioral limits that all agents respect.
They cover 8 categories: security, scope, process, destructive operations,
data/PII, quality, environments and documentation. They are **non-negotiable** and
deployed automatically with the wizard.

### 7. 🔒 Local-only mode — "Keep AI config out of git"
Optional. The wizard can append the generated AI config (`AGENTS.md`,
`CLAUDE.md`, `.github/instructions/`, `.claude/`, `.cursor/`…) and/or the
session memory files (`docs/spec.md`, `docs/decisions.md`,
`docs/session-log.md`) to the project's `.gitignore` so they stay local.
Useful in corporate repos where AI tool config is private, or open source
projects where you don't want to expose your internal workflow. Toggle with
`git.local_config` / `git.local_memory` in `understudy.yaml` — see
[docs/09-configuration.md](docs/09-configuration.md#local-only-mode).

## Guardrails

Guardrails protect the team from:
- Secrets or sensitive data leaks
- Destructive operations without confirmation
- Production changes without change control
- Code without spec, without tests, or without review
- Scope violations between agents

### Deployment modes

| Mode | Description |
|---|---|
| 🔀 **split** (recommended) | Critical guardrails always active in `copilot-instructions.md` + full details file in `guardrails.instructions.md` |
| 📦 **embedded** | Only critical guardrails embedded in `copilot-instructions.md` (lighter, no separate file) |

### Split vs Embedded: practical differences

| Aspect | 🔀 split | 📦 embedded |
|---|---|---|
| **Enforcement level** | Critical guardrails are always active **and** full guardrails are available in a dedicated file | Only critical guardrails are always active |
| **Visibility** | Higher: team can review complete guardrails in `guardrails.instructions.md` | Lower: only the reduced set is visible in global instructions |
| **Maintenance** | Easier to evolve full guardrails without bloating global instructions | Simpler file structure, but less room for detailed policies |
| **Best for** | Regulated teams, larger repos, multi-agent workflows, stricter governance | Small/fast projects, lightweight setups, teams that want minimal overhead |
| **Trade-off** | More files and a bit more structure | Less explicit coverage of non-critical rules |

**Rule of thumb:**
- Choose **split** when you want stronger governance, better auditability and clearer team alignment.
- Choose **embedded** when speed and simplicity matter more than policy depth.

The mode is selected during the wizard and can be changed by editing `understudy.yaml`:

```yaml
guardrails:
  mode: "split"   # "split" or "embedded"
```

### Categories

| # | Category | What it protects |
|---|---|---|
| 1 | 🛡️ Security | No secrets, no bypass, mandatory input validation |
| 2 | 🎯 Scope | File ownership per agent, justification required to cross boundaries |
| 3 | 📋 Process | Spec-first (with exceptions for bugfixes/emergencies), documented decisions |
| 4 | 💥 Destructive | PM confirmation before deleting, purging or revoking |
| 5 | 🔒 Data/PII | No real data, synthetic data in tests, GDPR |
| 6 | 🏗️ Quality | Self-review, appropriate tests, naming, error handling |
| 7 | ⚠️ Environments | Promotion order dev→prd, mandatory IaC, no manual changes |
| 8 | 📝 Documentation | ADRs, session-log, updated spec |

## System Structure

```
understudy/
├── wizard.sh                    # 🧙 The wizard — deploys Understudy
├── install.sh                   # 📦 One-liner curl installer
├── run_tests.sh                 # 🧪 Local test runner
├── understudy.yaml              # ⚙️ Global configuration
├── templates/                   # 📋 Base templates
│   ├── AGENTS.md                # Copilot: team definition
│   ├── CLAUDE.md                # Claude: global instructions
│   ├── .github/                 # Copilot / VS Code
│   │   ├── copilot-instructions.md
│   │   ├── instructions/
│   │   │   ├── architect.instructions.md
│   │   │   ├── backend.instructions.md
│   │   │   ├── frontend.instructions.md
│   │   │   ├── devops.instructions.md
│   │   │   ├── security.instructions.md
│   │   │   ├── qa-engineer.instructions.md
│   │   │   └── guardrails.instructions.md
│   │   └── prompts/
│   │       ├── start-session.prompt.md
│   │       ├── end-session.prompt.md
│   │       ├── design-feature.prompt.md
│   │       └── security-review.prompt.md
│   ├── .claude/                 # Claude Code
│   │   ├── agents/
│   │   │   ├── architect.md, backend.md, frontend.md
│   │   │   ├── devops.md, security.md, qa.md
│   │   ├── commands/
│   │   │   ├── start-session.md, end-session.md
│   │   │   ├── design-feature.md, security-review.md
│   │   ├── hooks/
│   │   │   └── guardrails-check.sh
│   │   └── settings.json
│   ├── .cursor/                 # Cursor
│   │   ├── agents/
│   │   │   ├── architect.md, backend.md, frontend.md
│   │   │   ├── devops.md, security.md, qa-engineer.md
│   │   └── rules/
│   │       ├── understudy-global.mdc
│   │       └── guardrails.mdc
│   └── docs/
│       ├── spec.md
│       ├── decisions.md
│       ├── session-log.md
│       └── team-roster.md
├── roles/                       # 🎭 Optional roles catalog
│   ├── data-engineer.instructions.md
│   ├── git-specialist.instructions.md
│   ├── mobile-engineer.instructions.md
│   ├── ml-engineer.instructions.md
│   ├── repo-documenter.instructions.md
│   ├── shell-scripting.instructions.md
│   ├── tech-writer.instructions.md
│   └── sre.instructions.md
├── tests/                       # 🧪 bats test suite
│   ├── unit/                    # config_read, detect, deploy_file, guardrails
│   ├── hooks/                   # guardrails-check.sh tests
│   ├── integration/             # end-to-end wizard deployment
│   ├── fixtures/                # fake project structures
│   └── lib/helpers.bash         # shared test helpers
└── docs/                        # 📚 Documentation
    ├── README.md                    # Index
    ├── 01-introduction.md
    ├── 02-quick-start.md
    ├── 03-platform-comparison.md
    ├── platforms/
    │   ├── copilot-cli.md
    │   ├── vscode-copilot.md
    │   ├── claude-code.md
    │   └── cursor.md
    ├── 08-cross-platform-workflows.md
    ├── 09-configuration.md
    └── 10-troubleshooting.md
```

## Documentation

Full docs live under [`docs/`](docs/README.md) and are organized so they can be
published as a static site without restructuring.

| Section | Contents |
|---|---|
| [Introduction and Core Concepts](docs/01-introduction.md) | Mental model, agents, spec-driven development, persistent memory, guardrails, roles catalog, generated files |
| [Quick Start](docs/02-quick-start.md) | Install, first session, extending the team |
| [Platform Capability Matrix](docs/03-platform-comparison.md) | What each tool supports out of the box |
| [GitHub Copilot CLI](docs/platforms/copilot-cli.md) | Setup, commands, full feature flow, sub-agents, tips |
| [VS Code Copilot](docs/platforms/vscode-copilot.md) | `applyTo` globs, prompt files, start → work → end flow |
| [Claude Code](docs/platforms/claude-code.md) | Agents, slash commands, deny list, PreToolUse hook, adding commands |
| [Cursor](docs/platforms/cursor.md) | Rules (MDC), agent panel, creating your own rules |
| [Cross-Platform Workflows](docs/08-cross-platform-workflows.md) | Mixed setups and the shared session protocol |
| [Configuration Reference](docs/09-configuration.md) | Full `understudy.yaml` reference |
| [Troubleshooting and FAQ](docs/10-troubleshooting.md) | Common issues, model choice, reporting bugs |

## Wizard Commands

| Command | Description |
|---|---|
| `understudy` | Full interactive deployment |
| `understudy --here` | Deploy in the current directory using values inferred from the repo (numbered summary, editable with `e`) |
| `understudy --here --yes` | Same as `--here` but skip the confirmation prompt (fully unattended) |
| `understudy --add-member` | Add a team member (data engineer, QA, etc.) |
| `understudy --create-role` | Create a custom role from scratch |
| `understudy --help` | Show help |

> If you installed manually via `git clone`, replace `understudy` with `./wizard.sh`.

## Integration into Existing Projects and Monorepos

The wizard automatically detects existing projects and adapts:

| Scenario | Behavior |
|---|---|
| 🆕 Folder doesn't exist | Creates new project with full structure |
| 🔄 Existing project | Integrates Understudy without touching existing files |
| ⚠️ Already has Understudy | Re-deploy: only adds missing files |

### Automatic Stack Detection

The wizard scans up to 3 levels deep to detect technologies:

| Technology | Marker | Example |
|---|---|---|
| .NET | `*.csproj`, `*.sln` | `.NET: services/api-customers (ApiCustomers)` |
| Node.js | `package.json` (without React/Vue/Angular) | `Node.js: services/api-notifications` |
| React | `package.json` with `"react"` | `React: frontend/web-app` |
| Vue | `package.json` with `"vue"` | `Vue: frontend/admin` |
| Angular | `package.json` with `"@angular/core"` | `Angular: frontend/portal` |
| Python | `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile` | `Python: services/ml-scoring` |
| Terraform | `*.tf` | `Terraform: infra/terraform` |
| Docker | `Dockerfile`, `docker-compose.yml` | `Docker: 4 Dockerfiles` |
| Shell | `*.sh`, `*.bash`, `*.zsh` | `Shell` (auto-adds shell-scripting role) |

### Monorepo Support

When 2+ independent projects are detected, the stack is labeled as **Monorepo**:

```
Monorepo: .NET(2) + Node.js + React(2) + Python + Terraform + Docker

Components found:
  • .NET: services/api-customers (ApiCustomers)
  • .NET: services/api-policies (ApiPolicies)
  • React: frontend/web-app
  • Node.js: services/api-notifications
  • Python: services/ml-scoring
  • Terraform: infra/terraform
  • Docker: 4 Dockerfiles
  • Docker Compose: ./
```

The detected stack is pre-filled as the default value, saving you time during setup.

## Recommended Workflow

```
PM writes spec.md
        │
        ▼
   /agent Architect ──── designs solution ──── docs/decisions.md
        │
        ▼
   /agent Security ───── threat model
        │
        ├──────────────────────┐
        ▼                      ▼
   /agent Backend         /agent Frontend
   (implements APIs)      (implements UI)
        │                      │
        └──────────┬───────────┘
                   ▼
             /agent QA
        (test plan + tests)
                   │
                   ▼
            /agent DevOps
        (infra + CI/CD + deploy)
                   │
                   ▼
            /agent Security
          (final review)
                   │
                   ▼
        session-log.md updated
```

## How to Add New Roles

The `roles/` folder is the **official optional roles catalog** for the system. The 6 core roles (Architect, Backend, Frontend, DevOps, Security, QA) are always deployed from `templates/`; roles in `roles/` are additional and you choose them.

**Included optional roles:**

| Role | When to use it |
|---|---|
| � **caveman** | Token-efficient prose. Drops fillers; keeps code/paths/URLs. Opt-in via `--caveman`. See [Caveman Mode](docs/11-caveman-mode.md). |
| �📊 **data-engineer** | ETL/ELT pipelines, data warehouses, streaming, data governance |
| 🌿 **git-specialist** | Git workflows, branch policies, PR hygiene, release discipline |
| 📱 **mobile-engineer** | iOS/Android apps, React Native, Flutter |
| 🤖 **ml-engineer** | ML models, MLOps, LLMs, RAG, responsible AI |
| 📖 **repo-documenter** | Codebase understanding, architecture docs, onboarding guides |
| 🐚 **shell-scripting** | Bash/sh automation, cross-platform scripting, ShellCheck best practices |
| 📝 **tech-writer** | Technical documentation, API docs, tutorials, Diataxis |
| 🧭 **sre** | SLOs, observability, incident response, chaos engineering |

**Auto-deploy:** The wizard always includes `git-specialist` and
`repo-documenter`. If shell scripts (`*.sh`, `*.bash`, `*.zsh`) are detected
in your project, `shell-scripting` is added automatically. All are deployed to
every platform you selected (Copilot, Claude, Cursor).

**How to add more:**

1. **From the existing catalog**: `understudy --add-member` → choose from menu (works with Copilot, Claude and Cursor projects)
2. **Create a new one**: `understudy --create-role` → saved in `roles/` for reuse
3. **Manual**: create a file `name.instructions.md` in `roles/` following the existing format

> Roles you create with `--create-role` are stored in `roles/` and will be available for **all your future Understudy deployments**, not just the current project.

## Tips for Project Managers

- Use **Claude Opus** (`/model`) for the Architect — better reasoning for design
- Use **Claude Sonnet** for Backend/Frontend — good speed/quality balance
- Use **Claude Haiku** for quick DevOps tasks — economical and efficient
- Always ask to update `session-log.md` at the end of each session
- The spec is sacred: if scope changes, update the spec first

> These defaults are in `understudy.yaml`. Edit it in your project to customize.

## Configuration and Override

The system uses an `understudy.yaml` configuration file with priority hierarchy:

```
1. Wizard defaults (built-in)                    ← lowest priority
2. ~/.understudy/understudy.yaml (installed)     ← global defaults
   OR understudy.yaml next to wizard.sh (cloned) ← if installed manually
3. understudy.yaml in the project                ← per-project override (highest)
```

Example override: your project needs Opus for Security because it's fintech:
```yaml
# my-project/understudy.yaml
models:
  security: "claude-opus-4.6"   # override: more reasoning for fintech
platforms:
  copilot: true
  claude: true                  # or false if you only use one platform
  cursor: true
guardrails:
  mode: "embedded"              # override: only critical guardrails for lighter project
```

## Compatibility: Copilot CLI + VS Code + Claude Code + Cursor

Understudy works on **all four platforms** — choose one or all during deployment:

| Feature | Copilot CLI | VS Code | Claude Code | Cursor |
|---|---|---|---|---|
| Global instructions | ✅ Auto-loaded | ✅ Auto-loaded | ✅ CLAUDE.md | ✅ `.cursor/rules/` |
| Role instructions | ✅ `/instructions` | ✅ Auto-applies by `applyTo` | ✅ `.claude/agents/` | ✅ `.cursor/agents/` |
| Guardrails | ✅ Auto + `/instructions` | ✅ Auto-applies (`**`) | ✅ CLAUDE.md + hooks | ✅ `guardrails.mdc` |
| Agent selection | `/agent` | Chat with context | Invoke by name | Agent panel |
| Reusable prompts | N/A | ✅ `.github/prompts/` | ✅ `/project:command` | N/A |
| Team definition | ✅ AGENTS.md | ✅ AGENTS.md | ✅ `.claude/agents/` | ✅ `.cursor/agents/` |
| File protection | N/A | N/A | ✅ `settings.json` deny | N/A |
| Security hooks | N/A | N/A | ✅ `.claude/hooks/` | N/A |

### In VS Code
- Instructions are applied **automatically** based on the file you're editing
  (thanks to the `applyTo` frontmatter in each `.instructions.md`)
- Prompts in `.github/prompts/` are available as reusable prompts
- Use "Start Session" and "End Session" prompts for the context flow

### In Claude Code
- `CLAUDE.md` is loaded automatically when you open the project
- Agents are in `.claude/agents/` — invoke them by name
- Commands are in `.claude/commands/` — use them with `/project:name`
- The guardrails hook blocks destructive operations automatically
- `settings.json` protects sensitive files (.env, keys, secrets)

### In Cursor
- Global rules (`.cursor/rules/`) are applied **automatically** in every session
- Agents are in `.cursor/agents/` — invoke them from the Agent panel
- Guardrails are in `.cursor/rules/guardrails.mdc` — always active
- Each agent has its model configured in the frontmatter (`auto`, `fast`, or a specific model)

### Files by platform

**Copilot / VS Code:**
```
.github/copilot-instructions.md        → Always active (includes critical guardrails)
.github/instructions/*.instructions.md → By file type (applyTo)
.github/instructions/guardrails.instructions.md → Always active (applyTo: "**")
.github/prompts/*.prompt.md            → Invocable from Copilot Chat
AGENTS.md                              → Read as context
```

**Claude Code:**
```
CLAUDE.md                              → Always active (includes critical guardrails)
.claude/agents/*.md                    → Agents by role (with frontmatter)
.claude/commands/*.md                  → Commands (/project:name)
.claude/settings.json                  → Permissions and hooks
.claude/hooks/guardrails-check.sh      → Hook PreToolUse
```

**Cursor:**
```
.cursor/agents/*.md                    → Agents by role (with frontmatter)
.cursor/rules/understudy-global.mdc        → Global rules (always active)
.cursor/rules/guardrails.mdc          → Guardrails (always active)
```

## Contributing

Contributions are welcome. Read the [contribution guide](CONTRIBUTING.md) before
opening a PR — it includes commit conventions, versioning, CHANGELOG maintenance
and the review process.

To report bugs or propose improvements use the [issue templates](https://github.com/erniker/understudy/issues/new/choose).
To report security vulnerabilities, see the [security policy](SECURITY.md).

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md) as its code of conduct.

## Acknowledgments

- **Caveman mode** (the `caveman` role and the `understudy-compress` script)
  is inspired by [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) —
  thanks to its author for the original idea of token-efficient AI prose and for
  open-sourcing the prompt patterns that informed our port. See
  [docs/11-caveman-mode.md](docs/11-caveman-mode.md) for what we adapted and
  what we intentionally did not ship.
