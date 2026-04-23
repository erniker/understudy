# 📚 Tutorial: Understudy — One AI, Every Role

> Complete guide to deploying and using specialized AI agents.
> A single assistant that puts on the hat of whatever role you need.
> Compatible with GitHub Copilot CLI, VS Code, Claude Code and Cursor.

---

## Chapter 1: Fundamental concepts

### 1.1 What is an agent in Copilot CLI?

An agent is a **specialized personality** that Copilot adopts.
Instead of talking to a "generic assistant", you talk to a
Solutions Architect, a Backend Developer, or a Security Expert.

Each agent has:
- **Domain knowledge**: Knows about their specific area
- **Behavior rules**: Follows defined standards
- **Communication style**: Produces structured output for their role
- **Team interaction**: Knows when to consult another agent

### 1.2 Where are they defined?

#### In GitHub Copilot CLI / VS Code

| File | Scope | Loading | Purpose |
|---|---|---|---|
| `AGENTS.md` | Repo root / cwd | Automatic, selectable with `/agent` | Define team agents |
| `.github/copilot-instructions.md` | Project | Automatic, always active | Global project context + critical guardrails |
| `.github/instructions/*.instructions.md` | Project | Automatic, toggleable with `/instructions` | Detailed per-role instructions |
| `.github/instructions/guardrails.instructions.md` | Project | Automatic (applyTo: `**`) | Full guardrails for all agents |
| `~/.copilot/copilot-instructions.md` | User | Automatic, always active | Global personal preferences |

#### In Claude Code

| File | Scope | Loading | Purpose |
|---|---|---|---|
| `CLAUDE.md` | Project root | Automatic, always active | Global context + critical guardrails |
| `.claude/agents/*.md` | Project | Invocable by name | Agents per role (with model and tools in frontmatter) |
| `.claude/commands/*.md` | Project | Invocable with `/project:name` | Reusable commands (start-session, etc.) |
| `.claude/settings.json` | Project | Automatic | Permissions (deny) and hooks |
| `.claude/hooks/*.sh` | Project | Automatic (via settings.json) | Scripts for guardrails |

#### In Cursor

| File | Scope | Loading | Purpose |
|---|---|---|---|
| `.cursor/rules/understudy-global.mdc` | Project | Automatic (`alwaysApply: true`) | Global project rules |
| `.cursor/rules/guardrails.mdc` | Project | Automatic (`alwaysApply: true`) | Security guardrails |
| `.cursor/agents/*.md` | Project | Invocable from Agent panel | Agents per role (with model in frontmatter) |

### 1.3 Multi-agents and sub-agents

**Multi-agents** = Having several agents defined and switching between them with `/agent`.
**Sub-agents** = Copilot can launch internal agents (via the task tool) that work
in parallel on independent subtasks.

Example multi-agent flow:
```
You: /agent Architect → "Design the customer API"
Architect: [produces design with ADR + OpenAPI spec]

You: /agent Backend → "Implement the API according to the Architect's design"
Backend: [reads docs/decisions.md, implements following the contract]

You: /agent Security → "Review the implementation"
Security: [analyzes code, reports findings]
```

Example of parallel sub-agents:
```
You: "Implement the login feature frontend and backend simultaneously"
Copilot: [launches sub-agent Backend and sub-agent Frontend in parallel]
         [each works independently following the Architect's contracts]
```

---

## Chapter 2: Spec-Driven Development

### 2.1 Why spec-first?

Without a clear specification:
- Each agent interprets requirements in their own way
- Time is wasted re-doing work
- Decisions have no documented foundation

With spec-first:
- All agents read the same source of truth (`docs/spec.md`)
- The Architect designs against concrete requirements
- Backend and Frontend implement against defined contracts
- Security knows which assets to protect

### 2.2 Spec-driven flow

```
1. PM writes docs/spec.md (business requirements)
       ↓
2. /agent Architect refines the spec (technical questions)
       ↓
3. PM approves the refined spec
       ↓
4. Architect produces design + API contracts
       ↓
5. Security validates threat model
       ↓
6. Backend + Frontend implement in parallel
       ↓
7. QA designs test plan and writes tests
       ↓
8. DevOps prepares infra + CI/CD
       ↓
9. Security does final review
```

### 2.3 The spec as a contract

The spec is NOT static documentation. It is a **living contract**:
- If the PM changes requirements → update the spec first
- If the Architect discovers constraints → update the spec
- All agents constantly reference it

---

## Chapter 3: Persistence between sessions

### 3.1 The problem

Copilot CLI **has no memory between sessions**. Every time you open a new session,
the agent starts from scratch. This means:
- Spending tokens re-explaining context
- Risk of inconsistent decisions
- Loss of progress

### 3.2 The solution: context files

Understudy uses three files as "persistent memory":

**`docs/spec.md`** — What needs to be done
- Source of truth for requirements
- Read at the start of each session
- Updated when scope changes

**`docs/decisions.md`** — What was decided and why
- Architectural decision records (ADR)
- Avoids re-discussing decisions already made
- Each ADR explains context, alternatives and consequences

**`docs/session-log.md`** — What was done and what remains
- Chronological session log
- Read at start: "what was done yesterday?"
- Updated at end: "what did we do today?"
- Includes pending items and blockers

### 3.3 Session protocol

**When STARTING a session:**
```
You: "Read docs/session-log.md, docs/spec.md and docs/decisions.md
     to get up to speed on the project"
```

**When ENDING a session:**
```
You: "Update docs/session-log.md with what we did today,
     what is still pending and decisions made"
```

This costs a few tokens and saves MANY in the next session.

---

## Chapter 4: The Wizard

### 4.1 What does it do?

The wizard (`wizard.sh`) automates Understudy deployment:

1. Asks you for project details (name, stack, PM, etc.)
2. Asks you for guardrails mode (split or embedded)
3. Asks you which platforms to deploy (Copilot, Claude Code, Cursor)
4. Creates the entire directory structure
5. Generates the files for each platform with the project data
6. Optionally initializes git
7. Gives you instructions on how to start according to the platform

### 4.2 Usage

```bash
# Full deployment
./wizard.sh

# Add member (e.g.: Data Engineer)
./wizard.sh --add-member

# Create custom role
./wizard.sh --create-role
```

### 4.3 Integration in existing projects

The wizard not only creates new projects — it also **integrates into existing projects**
without touching any file that already exists:

```bash
# Example: your React project already exists in ./my-app
./wizard.sh
# → Name: my-app
# → Base directory: .
# → The wizard detects that my-app/ already exists
# → Shows detected stack and asks if it should integrate
```

The wizard operates in **3 modes**:

| Mode | When | What it does |
|---|---|---|
| 🆕 **New** | Folder does not exist | Creates everything from scratch |
| 🔄 **Integration** | Folder has a project | Adds Understudy without touching existing files |
| ⚠️ **Re-deployment** | Already has Understudy (AGENTS.md / CLAUDE.md / .cursor/agents) | Only adds missing files |

### 4.4 Stack detection and monorepos

When it finds an existing project, the wizard **scans up to 3 levels deep**
to detect technologies. It recognizes:

- **.NET**: `*.csproj`, `*.sln` (with project name)
- **Node.js**: `package.json` in subdirectories
- **React / Vue / Angular**: detects the framework inside `package.json`
- **Python**: `requirements.txt`, `pyproject.toml`, `setup.py`, `Pipfile`
- **Terraform**: `*.tf`
- **Docker**: `Dockerfile` (counts how many), `docker-compose.yml`

When it detects **more than 2 independent projects**, it labels it as a **Monorepo**:

```
🔍 Existing project detected

  Detected stack:   Monorepo: .NET(2) + Node.js + React(2) + Python + Terraform + Docker

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

The detected stack is used as a **default value** that you can accept or modify.

### 4.5 Extensibility

The `roles/` directory contains additional role templates.
You can create any role you need:

- Data Engineer → `roles/data-engineer.instructions.md`
- Technical Writer → `roles/tech-writer.instructions.md`
- ML Engineer → `roles/ml-engineer.instructions.md`
- Performance Engineer → `roles/perf-engineer.instructions.md`

The wizard has an interactive option to create roles from scratch.

---

## Chapter 5: Configuration and Override

### 5.1 The understudy.yaml file

Understudy uses a YAML configuration file to control:
- **Models per role**: Which model is recommended for each agent
- **Scoping (applyTo)**: In VS Code, which files activate which instructions
- **Session behavior**: Auto-read context, auto-update log

### 5.2 Priority hierarchy

```
Wizard defaults (hardcoded)
    ↓ overridden by
Global understudy.yaml (next to wizard.sh)
    ↓ overridden by
Project understudy.yaml (at repo root)
```

This allows:
- Having corporate defaults in the global system
- Per-project overrides (e.g.: "this project uses Opus for Security")

### 5.3 Override example

```yaml
# my-fintech-project/understudy.yaml
models:
  architect: "claude-opus-4.6"    # keep default
  security: "claude-opus-4.6"     # override: more reasoning for fintech
  backend: "claude-sonnet-4"      # override: use Sonnet 4 instead of 4.5
```

### 5.4 Guardrails configuration

Guardrails are configured in `understudy.yaml`:

```yaml
guardrails:
  mode: "split"   # "split" or "embedded"
```

| Mode | What it does |
|---|---|
| `split` (recommended) | Critical guardrails always in `copilot-instructions.md` + full `guardrails.instructions.md` file with details and examples |
| `embedded` | Only critical guardrails embedded in `copilot-instructions.md` (lighter, without separate file) |

The mode is selected during deployment with the wizard and can be changed by editing the config.

### 5.5 Platform configuration

The wizard supports deployment to one or multiple platforms:

```yaml
platforms:
  copilot: true    # GitHub Copilot CLI / VS Code
  claude: true     # Claude Code
```

If you only use one platform, set `false` for the other. The wizard also
allows selecting the platform during interactive deployment.

---

## Chapter 6: Guardrails — Team protection

### 6.1 What are guardrails?

Guardrails are **non-negotiable security and behavior limits** that all
Understudy agents must respect. They are not suggestions — they are hard constraints.

They protect against:
- Leaks of secrets or sensitive data in code or logs
- Destructive operations without PM confirmation
- Production changes without change control
- Code without spec, without tests, or without review
- Scope violations between agents

### 6.2 The 8 categories

| # | Category | What it protects | Example |
|---|---|---|---|
| 1 | 🛡️ **Security** | No secrets, input validation | "NEVER hardcode API keys" |
| 2 | 🎯 **Scope** | File ownership per agent | "Backend does not modify React components without justification" |
| 3 | 📋 **Process** | Spec-first, documented decisions | "Don't code without approved spec (except bugfixes)" |
| 4 | 💥 **Destructive** | Confirmation before deleting | "Before `terraform destroy`: explain what, why, impact" |
| 5 | 🔒 **Data/PII** | No real data in code/tests | "Use synthetic data, never real PII" |
| 6 | 🏗️ **Quality** | Self-review, tests, naming | "Self-review before presenting, explicit error handling" |
| 7 | ⚠️ **Environments** | Promotion order, IaC | "dev → test → acc → eng → prd, never skip" |
| 8 | 📝 **Documentation** | ADRs, session-log, spec | "Update session-log at the end of each session" |

### 6.3 How they are applied

Guardrails are applied in **two layers**:

1. **Critical guardrails** — Embedded in `copilot-instructions.md` (always active).
   Compact version with the most important rules: security, destructive, data, environments.

2. **Full guardrails** — File `.github/instructions/guardrails.instructions.md`
   with all 8 detailed categories, examples, ownership tables and enforcement section.
   In VS Code it auto-applies to all files (`applyTo: "**"`).

### 6.4 Valid exceptions

Guardrails are strict but not dogmatic. There are legitimate exceptions:

| Rule | Valid exception |
|---|---|
| Spec-first | Bugfixes, emergencies, dependency CVEs, config changes |
| Scope/ownership | Cross-cutting change with justification (e.g.: security fix) |
| Mandatory tests | Documentation, config, metadata — appropriate validation instead of unit tests |

### 6.5 Enforcement

If a user or project instruction contradicts the guardrails:
1. The agent prioritizes the guardrails
2. Explains to the PM which rule would be violated
3. Proposes a safe alternative
4. Documents the incident in session-log

The only way to deactivate a guardrail is for the PM to do so explicitly
in `understudy.yaml`.

---

## Chapter 7: Usage in Claude Code

### 7.1 Generated files

When you deploy for Claude Code, the wizard generates:

| File | Function |
|---|---|
| `CLAUDE.md` | Global instructions (always loaded, equivalent to `copilot-instructions.md`) |
| `.claude/agents/*.md` | One agent per role with frontmatter (name, model, tools) |
| `.claude/commands/*.md` | Commands invocable with `/project:name` |
| `.claude/settings.json` | Deny permissions (protects .env, keys) + hooks wiring |
| `.claude/hooks/guardrails-check.sh` | PreToolUse hook that blocks destructive operations |

### 7.2 Differences from Copilot

| Concept | Copilot | Claude Code |
|---|---|---|
| Separate agents | AGENTS.md + .instructions.md | `.claude/agents/` (all-in-one) |
| Global instructions | `copilot-instructions.md` | `CLAUDE.md` |
| Reusable prompts | `.github/prompts/` | `.claude/commands/` |
| Guardrails enforcement | Instructions only | Instructions + hooks + settings.json deny |
| Model per agent | Text recommendation | Frontmatter `model:` in each agent |

### 7.3 Available commands

| Command | Purpose |
|---|---|
| `/project:start-session` | Load context when starting a session |
| `/project:end-session` | Update session-log when closing |
| `/project:design-feature` | Design a feature with the Architect |
| `/project:security-review` | Security review of current changes |

### 7.4 Guardrails in Claude Code

Guardrails work in **3 layers** in Claude Code:

1. **CLAUDE.md**: Critical guardrails embedded (always loaded)
2. **settings.json deny**: Protects sensitive files (.env, keys, secrets)
3. **hooks/guardrails-check.sh**: PreToolUse hook that blocks destructive commands
   (rm -rf, terraform destroy, kubectl delete, DROP TABLE, etc.)

### 7.5 Dual Copilot + Claude usage

If you deploy both platforms, each has its own files but
they share the documentation (`docs/`), the config (`understudy.yaml`) and the
team standards. You can use both simultaneously in the same project.

---

## Chapter 8: Usage in VS Code

### 8.1 What works the same?

| File | CLI | VS Code |
|---|---|---|
| `.github/copilot-instructions.md` | ✅ Auto-loaded | ✅ Auto-loaded |
| `.github/instructions/*.instructions.md` | ✅ Toggleable | ✅ Auto-applies by applyTo |
| `.github/instructions/guardrails.instructions.md` | ✅ Toggleable | ✅ Auto-applies to all (`**`) |
| `AGENTS.md` | ✅ `/agent` | ✅ Read as context |
| `docs/*.md` | ✅ Read by agents | ✅ Read by agents |

### 8.2 What is different?

**Frontmatter `applyTo`**: In VS Code, each `.instructions.md` has a YAML frontmatter:
```yaml
---
applyTo: "src/components/**,**/*.tsx"
---
```
When you edit a `.tsx` file, VS Code automatically applies the Frontend instructions.
You don't need to do `/instructions` manually.

**Prompt files**: VS Code supports `.github/prompts/*.prompt.md` — reusable prompts
that you can invoke from Copilot Chat. The wizard deploys 4 prompts:

| Prompt | Purpose |
|---|---|
| `start-session.prompt.md` | Load context when starting |
| `end-session.prompt.md` | Update session-log when closing |
| `design-feature.prompt.md` | Design a feature with the Architect |
| `security-review.prompt.md` | Security review of changes |

### 8.3 Model selection in VS Code

In VS Code, you change models from the model picker in the Copilot Chat UI
(dropdown in the corner of the chat panel). The `understudy.yaml` and the
instructions include the model recommendation — but selection is manual.

---

## Chapter 9: Usage in Cursor

### 9.1 Configuration

Cursor uses two complementary systems:

| Component | Location | Loading | Purpose |
|---|---|---|---|
| **Agents** | `.cursor/agents/*.md` | Agent panel | Specialized agents per role |
| **Rules** | `.cursor/rules/*.mdc` | Automatic | Global rules and guardrails |

### 9.2 How do rules work?

Rules use MDC format (Markdown + YAML frontmatter):

```yaml
---
description: "Rule description"
alwaysApply: true
---
# Rule content in Markdown
```

Types of rules:
- **Always** (`alwaysApply: true`): Loaded in every session, like global instructions
- **Auto Attached** (with `globs`): Loaded when you edit files matching the pattern
- **Agent Requested** (only `description`): The agent decides whether to load them based on context
- **Manual**: Only loaded if you invoke them explicitly

Understudy deploys two "Always" rules:
- `understudy-global.mdc` — Global project instructions
- `guardrails.mdc` — Security guardrails

### 9.3 How do agents work?

Agents have frontmatter with `name`, `description` and `model`:

```yaml
---
name: architect
description: "Understudy Solutions Architect"
model: auto
---
# Agent instructions
```

They are invoked from the **Agent panel** in Cursor. Each agent has its own
recommended model configured in the frontmatter.

### 9.4 Differences from other platforms

| Aspect | Copilot | Claude Code | Cursor |
|---|---|---|---|
| Agent invocation | `/agent` | By name | Agent panel |
| Global instructions | `copilot-instructions.md` | `CLAUDE.md` | `.cursor/rules/*.mdc` |
| Guardrails | `.instructions.md` + embedded | `CLAUDE.md` + hooks | `guardrails.mdc` |
| Commands/Prompts | `.github/prompts/` | `.claude/commands/` | N/A |
| File protection | N/A | `settings.json` deny | N/A |

---

## Chapter 10: Cost optimization (tokens)

### 5.1 Model selection by task

| Task | Recommended model | Why |
|---|---|---|
| Architectural design | Claude Opus | Deep reasoning, complex decisions |
| Backend implementation | Claude Sonnet | Good quality/speed/cost balance |
| Frontend implementation | Claude Sonnet | Same |
| Testing / QA | Claude Sonnet | Test plans and test code |
| DevOps scripts | Claude Haiku | Structured tasks, more economical |
| Security review | Claude Sonnet/Opus | Depends on complexity |
| Quick questions | Claude Haiku | Minimum cost |

Cambia de modelo en cualquier momento con `/model`.

### 5.2 Reducing tokens with persistent context

- Use `docs/session-log.md` instead of re-explaining
- Use `/compact` if the conversation gets too long
- Ask the agent to read specific files, not "the whole project"

### 5.3 Sub-agents vs sequential sessions

- **Sub-agents**: Copilot internally launches agents that work in parallel.
  Useful when Backend and Frontend can progress independently.
- **Sequential sessions**: You switch agent with `/agent` and work one at a time.
  Useful when you need close supervision of each step.

---

## Chapter 11: Cheat Sheet

### Essential Copilot CLI commands

| Command | What it does |
|---|---|
| `/agent` | Select a team agent |
| `/instructions` | Enable/disable modular instructions |
| `/model` | Change model (Opus, Sonnet, Haiku) |
| `/compact` | Compress history to save tokens |
| `/diff` | Review changes made |
| `/context` | View token usage for the session |

### Claude Code commands

| Command | What it does |
|---|---|
| `/project:start-session` | Load project context |
| `/project:end-session` | Close session and update logs |
| `/project:design-feature` | Design a feature with the Architect |
| `/project:security-review` | Security review of changes |

### Cursor

In Cursor there are no text commands like in Copilot CLI or Claude Code.
Interaction is done through the UI:

| Action | How |
|---|---|
| Invoke an agent | Agent panel → select agent (architect, backend, etc.) |
| Global rules | Loaded automatically — no action required |
| Guardrails | Loaded automatically from `.cursor/rules/guardrails.mdc` |

### Wizard commands

| Command | What it does |
|---|---|
| `./wizard.sh` | Interactive deployment (new or integration) |
| `./wizard.sh --add-member` | Add an extra member (Data Engineer, etc.) |
| `./wizard.sh --create-role` | Create a custom role from scratch |
| `./wizard.sh --help` | Show help |

> The wizard automatically detects if the directory already contains a project
> (Node.js, .NET, Python, monorepo, etc.) and offers **integration mode**.

### Useful phrases for the PM

```
"Read docs/session-log.md and get up to speed"
"Design the solution for [requirement] following the spec"
"Implement [feature] according to the Architect's contract"
"Review the Backend code from a security perspective"
"Update session-log.md with what we did today"
"What risks do you see in this architecture?"
"Reason step by step before designing the solution"
```

### Typical session flow

**With Copilot CLI:**
```bash
# 1. Open Copilot CLI in the project
cd my-project && copilot

# 2. Get up to speed
"Read session-log.md, spec.md and decisions.md for context"

# 3. Work with the appropriate agent
/agent Architect   # to design
/agent Backend     # to implement APIs
/agent Frontend    # to implement UI
/agent QA          # for tests and quality
/agent DevOps      # for infra and CI/CD
/agent Security    # for security review

# 4. When done
"Update session-log.md with a summary of this session"
```

**With Claude Code:**
```bash
# 1. Open Claude Code in the project
cd my-project && claude

# 2. Get up to speed
/project:start-session

# 3. Work — invoke agents by name or use commands
/project:design-feature    # to design
/project:security-review   # for security review

# 4. When done
/project:end-session
```

**With Cursor:**
```bash
# 1. Open Cursor in the project
cd my-project && cursor .

# 2. Rules are loaded automatically — review session-log.md
"Read docs/session-log.md and get up to speed"

# 3. Invoke agents from the Agent panel
# → architect, backend, frontend, devops, security, qa-engineer

# 4. When done
"Update docs/session-log.md with what we did today"
```
