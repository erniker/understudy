# Tutorial: VS Code Copilot — Full Feature Walkthrough

> A complete, self-contained guide that walks you step by step through
> **every feature** Understudy provides for VS Code Copilot.
> You do not need to read any other tutorial before this one.

---

## What you will learn

By the end of this tutorial you will have used:

- `applyTo` globs — automatic role switching based on which file you edit
- Prompt files — reusable pre-built workflows (`/start-session`, `/end-session`…)
- `#file:path` — pin specific files as context
- Model picker — choose the right model for the task
- Guardrails — always active, see the AI refuse unsafe operations
- "Used references" panel — debug which instructions are loaded
- Session protocol — persistent memory across sessions
- Custom prompt files — create your own reusable workflows
- `--add-member` / `--create-role` — extend the team
- Caveman mode — `/compress` and `/restore` prompts

---

## What you need before starting

| Requirement | How to get it |
|---|---|
| VS Code | [code.visualstudio.com](https://code.visualstudio.com) |
| GitHub Copilot extension | Install from VS Code marketplace |
| Copilot Chat extension | Install from VS Code marketplace |
| A GitHub Copilot subscription | [github.com/features/copilot](https://github.com/features/copilot) |
| `bash` ≥ 4 | Comes with Linux/macOS. On Windows use Git Bash or WSL |
| `git` | Any recent version |

> Use the latest VS Code version for full `applyTo` and prompt file support.

---

## Step 1 — Install Understudy

Open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/erniker/understudy/main/install.sh | bash
```

This downloads the latest release, installs it to `~/.understudy/` and adds
the `understudy` command to your PATH.

Close and re-open your terminal (or `source ~/.bashrc`) so the command is
available.

Verify:

```bash
understudy --help
```

---

## Step 2 — Create the example project

We will build **TaskFlow** — a simple task management REST API. The project
is intentionally simple so you can focus on learning the AI workflow.

```bash
mkdir taskflow
cd taskflow
git init
```

---

## Step 3 — Deploy Understudy into the project

Run the wizard:

```bash
understudy
```

The wizard asks 9 questions. Answer like this:

| # | Question | What to enter |
|---|---|---|
| 1 | Project name | `taskflow` |
| 2 | Short description | `Task management REST API` |
| 3 | Project manager | Your name |
| 4 | Tech stack | `Node.js + Express + PostgreSQL + Docker` |
| 5 | Repository URL | `https://github.com/you/taskflow` (or leave blank) |
| 6 | Guardrails mode | `split` (press Enter for default) |
| 7 | Platforms | Select **Copilot** |
| 8 | Git: commit files? | `y` |
| 9 | Git: local-only config? | `n` |

> **Shortcut:** `understudy --here` auto-infers all values from your repo.

---

## Step 4 — Open the project in VS Code

```bash
code .
```

---

## Step 5 — Verify the generated files

In the VS Code file explorer you should see:

```
AGENTS.md
.github/
├── copilot-instructions.md
├── instructions/
│   ├── architect.instructions.md
│   ├── backend.instructions.md
│   ├── devops.instructions.md
│   ├── frontend.instructions.md
│   ├── git-specialist.instructions.md
│   ├── guardrails.instructions.md
│   ├── qa-engineer.instructions.md
│   ├── repo-documenter.instructions.md
│   └── security.instructions.md
└── prompts/
    ├── design-feature.prompt.md
    ├── end-session.prompt.md
    ├── security-review.prompt.md
    ├── start-session.prompt.md
    └── understudy.prompt.md
docs/
├── decisions.md
├── session-log.md
├── spec.md
└── team-roster.md
```

### What each file does

| File/folder | Purpose | Loaded automatically? |
|---|---|---|
| `AGENTS.md` | Team definition (names, roles, rules). Read as context. | ✅ Yes |
| `.github/copilot-instructions.md` | Global project instructions + critical guardrails. | ✅ Yes, always |
| `.github/instructions/<role>.instructions.md` | Detailed role instructions with `applyTo` frontmatter. | ✅ **Automatic** when you edit a matching file |
| `.github/instructions/guardrails.instructions.md` | Full guardrails. `applyTo: "**"` = every file. | ✅ Yes, always |
| `.github/prompts/*.prompt.md` | Reusable prompts invocable from Copilot Chat. | ❌ On demand |
| `docs/*.md` | Persistent memory (spec, decisions, session log). | ❌ Via prompts or `#file:` |

---

## Step 6 — Feature: `applyTo` — Automatic role switching

This is the key VS Code feature. Open any
`.github/instructions/*.instructions.md` file and look at the top:

```yaml
---
applyTo: "src/services/**,src/controllers/**,**/*.ts"
---
```

This YAML frontmatter tells VS Code: **when the user edits a file matching
this glob pattern, load these instructions automatically**.

### 6.1 Default `applyTo` mappings

| Role | `applyTo` pattern | Activates when you edit… |
|---|---|---|
| Architect | `docs/decisions.md,docs/spec.md,**/*.md` | Specs, ADRs, docs |
| Backend | `src/services/**,src/controllers/**,**/*.ts` | Backend code |
| Frontend | `src/components/**,**/*.tsx,**/*.css` | UI components |
| DevOps | `**/Dockerfile,**/*.yml,infra/**,**/*.tf` | Infrastructure |
| Security | `**/*.env*,**/auth/**,**/security/**` | Auth, secrets |
| QA | `tests/**,**/*.test.*,**/*.spec.*` | Test files |
| Guardrails | `**` | **Every single file** |

### 6.2 Try it

1. Create and open `docs/spec.md` → Architect instructions load
2. Create and open `src/services/auth.ts` → Backend instructions load
3. Create and open `tests/auth.test.ts` → QA instructions load
4. Create and open `Dockerfile` → DevOps instructions load

**You never need to manually switch agents.** VS Code does it for you
based on which file you're editing.

### 6.3 How to verify which instructions are active

After asking Copilot a question, look at the **"Used references"** section
at the bottom of its response. It lists every instruction file that was
loaded for that response.

If the wrong role is active, check that your file path matches the expected
`applyTo` glob.

---

## Step 7 — Feature: Prompt files

Prompt files are pre-written instructions you can invoke from Copilot Chat.
They are VS Code's equivalent of slash commands. Understudy deploys 5:

| File | What it does |
|---|---|
| `start-session.prompt.md` | Reads spec, decisions, session-log and roster; gives status summary |
| `end-session.prompt.md` | Updates session-log with today's work, decisions, next steps |
| `design-feature.prompt.md` | Runs Architect's 8-step design process; writes ADR |
| `security-review.prompt.md` | Focused security review of recent changes |
| `understudy.prompt.md` | Explains Understudy capabilities, roles, commands, workflow |

### 7.1 How to invoke a prompt — 3 ways

**Option A — Type in chat:**
1. Open Copilot Chat (`Ctrl+Alt+I` / `Cmd+Ctrl+I`)
2. Type `/` and VS Code shows available prompts
3. Select one

**Option B — File explorer:**
1. Right-click a `.prompt.md` file in the explorer
2. Select "Run with Copilot"

**Option C — Command palette:**
1. `Ctrl+Shift+P` / `Cmd+Shift+P`
2. Type "Copilot: Run Prompt File"
3. Select from the list

---

## Step 8 — Start a session with the prompt file

Open Copilot Chat and type:

```
/start-session
```

Copilot reads `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`
and `docs/team-roster.md`, then provides:

- Current project status
- Last session summary (or "first session" if new)
- Open items
- Suggested next steps

Since this is a new project, it reports empty docs and suggests writing a
spec first.

---

## Step 9 — Design a feature with the prompt file

### 9.1 Choose the right model

In the Copilot Chat panel, look for the **model selector** (top or bottom
corner). Select the most powerful model available (Claude Opus / GPT-4o)
for design work.

| Task type | Recommended model | Why |
|---|---|---|
| Architecture design | Claude Opus / GPT-4o | Complex reasoning |
| Security review | Claude Opus | Deep analysis |
| Code implementation | Claude Sonnet / GPT-4o-mini | Good speed/quality |
| Quick fixes | Claude Haiku | Fast and cheap |

### 9.2 Run the design prompt

```
/design-feature
```

Copilot (as the Architect — because `applyTo` matches docs) asks:

```
What feature would you like to design?
```

Answer:

```
A REST API for task management. Features:
- User registration and login (JWT)
- CRUD tasks (title, description, status, due date)
- Assign tasks to users
- Filter by status, assignee, due date
- PostgreSQL database, Docker deployment
```

The Architect follows the 8-step process:
1. Requirements clarification
2. Constraint identification
3. 2-3 alternatives with trade-offs
4. Recommendation with justification
5. ADR in `docs/decisions.md`
6. Mermaid architecture diagram
7. Security consultation
8. Implementation plan

---

## Step 10 — Feature: `#file:` — Pin context

Want Copilot to consider a specific file?

```
Design the auth middleware. Consider the database schema in
#file:src/db/schema.prisma and the security requirements in
#file:docs/spec.md section "Non-functional requirements".
```

The `#file:path` syntax loads that file into context alongside the
auto-applied instructions. Use it when the auto-applied role isn't enough.

---

## Step 11 — Implement with automatic role activation

### 11.1 Backend work

Create (or open) `src/services/auth.ts`. Because this matches the Backend's
`applyTo` pattern (`src/services/**`), Backend instructions load
automatically.

In Copilot Chat:

```
Implement the auth service with:
- register(email, password) → hash password, save to DB, return user
- login(email, password) → verify, generate JWT + refresh token
- refreshToken(token) → validate, issue new JWT
Use Prisma for DB, bcrypt for hashing, jsonwebtoken for JWT.
Follow the security requirements in #file:docs/spec.md.
```

The Backend agent writes code following project conventions, uses
parameterized queries (guardrails), and reads env vars for secrets.

### 11.2 Test work

Open `tests/auth.test.ts`. QA instructions load automatically because
the file matches `tests/**`.

```
Write tests for the auth service:
1. register: valid input, duplicate email, weak password
2. login: correct credentials, wrong password, non-existent user
3. refreshToken: valid token, expired token, revoked token
Use Jest and mock the database layer.
```

### 11.3 Infrastructure work

Open `Dockerfile`. DevOps instructions load automatically.

```
Create a multi-stage Dockerfile:
- Stage 1: install deps + build
- Stage 2: production image (node:alpine)
Add a docker-compose.yml with app + postgres services.
```

---

## Step 12 — Security review with the prompt file

Before committing, run:

```
/security-review
```

Copilot (as the Security agent) reviews all recent changes:

- JWT implementation (expiry, refresh flow, storage)
- Input validation completeness
- SQL injection surface (parameterized queries check)
- Secrets in code (none — good)
- Authorization logic (user X can't access user Y's tasks)
- Rate limiting recommendations

It produces a report with findings and recommendations.

---

## Step 13 — Guardrails in action

Guardrails are always active because `guardrails.instructions.md` uses
`applyTo: "**"` (matches every file). There are 8 categories:

| # | Category | What it protects |
|---|---|---|
| 1 | Security | No secrets in code, mandatory input validation |
| 2 | Scope | Each agent owns specific files |
| 3 | Process | Spec-first (no code without spec) |
| 4 | Destructive | No bulk deletes without PM confirmation |
| 5 | Data/PII | No real data, synthetic only |
| 6 | Quality | Self-review, tests, proper naming |
| 7 | Environments | dev → staging → prod promotion order |
| 8 | Documentation | ADRs required, session-log updated |

### 13.1 Exercise: Security guardrail

Open any `.ts` file and ask:

```
Store the SendGrid API key directly in the source code so we don't
need env vars in development.
```

Copilot refuses:

> 🛡️ Guardrail: Security — API keys must come from environment variables.
> I'll use `process.env.SENDGRID_API_KEY` and add it to `.env.example`.

### 13.2 Exercise: Process guardrail

```
Add a WebSocket chat feature. Just code it, no design needed.
```

Copilot pushes back:

> 🛡️ Guardrail: Process — Spec-first. Update `docs/spec.md` first, then
> create an ADR, then implement.

### 13.3 Exercise: Destructive guardrail

```
Delete all migration files and the tests/ folder.
```

Copilot flags:

> ⚠️ Guardrail: Destructive — requires PM confirmation before bulk deletes.

---

## Step 14 — End the session with the prompt file

```
/end-session
```

Copilot updates `docs/session-log.md`:

```markdown
## Session — 2026-05-12

### Completed
- Designed task API (ADR-0001: Express + Prisma)
- Implemented auth service + task CRUD
- Docker setup (Dockerfile + docker-compose)
- Unit tests for auth service
- Security review passed

### Decisions
- ADR-0001: Express + Prisma (type safety, DX)

### Next steps
- Task filtering and pagination
- CI/CD pipeline
- Frontend (React)

### Blockers
- None
```

Next time you run `/start-session`, the AI reads this log and picks up
where you left off.

---

## Step 15 — Customize `applyTo` for your project

If your project uses a different structure, edit the frontmatter:

```yaml
---
applyTo: "packages/api/**,apps/server/**"
---
```

Multiple patterns are comma-separated. `**` matches everything (used by
guardrails).

---

## Step 16 — Create your own prompt files

Add any `.prompt.md` file to `.github/prompts/`. It appears in Copilot
Chat's prompt list immediately.

Example — `.github/prompts/db-migrate.prompt.md`:

```markdown
---
description: "Run database migration and verify schema"
---
Run the database migration with `npx prisma migrate dev`.
Then verify the schema matches docs/spec.md section 3.
Report any discrepancies.
```

Example — `.github/prompts/code-review.prompt.md`:

```markdown
---
description: "Review staged changes against coding standards"
---
Review all staged changes (git diff --cached). Check for:
- Coding standard violations
- Missing tests
- Security issues
- Performance concerns
Report findings with severity (Critical/High/Medium/Low).
```

---

## Step 17 — Feature: `--add-member` — Extend the team

Need a new role?

```bash
# In the terminal:
understudy --add-member
```

Select from the catalog (data-engineer, ml-engineer, sre, tech-writer…).
The role is deployed to `.github/instructions/` and added to `AGENTS.md`.

---

## Step 18 — Feature: `--create-role` — Create a custom role

```bash
understudy --create-role
```

The wizard asks for: name, title, description, expertise, motto.
The role is saved in `roles/` for use in all future projects.

---

## Step 19 — Caveman mode (optional)

Caveman mode makes responses shorter — drops filler words while keeping
code and technical accuracy. Saves 30-50% tokens.

### 19.1 Enable it

```bash
understudy --caveman
```

This deploys:
- `.github/instructions/caveman.instructions.md` (`applyTo: "**"`)
- `.github/prompts/compress.prompt.md`
- `.github/prompts/restore.prompt.md`

### 19.2 Feature: `/compress` prompt

When a response is too verbose:

```
/compress
```

Copilot rewrites its last response in caveman style.

### 19.3 Feature: `/restore` prompt

Need the full version back?

```
/restore
```

Restores the last compressed response to full prose.

### 19.4 Automatic caveman

With the role file deployed (`applyTo: "**"`), **all** Copilot responses
automatically use the token-efficient style. No need to invoke `/compress`
manually.

### 19.5 See the difference

**Normal:**
> I'll create a new Express middleware function that validates the JWT
> token from the Authorization header and attaches the decoded user
> payload to the request object for use in downstream handlers.

**Caveman:**
> Creating JWT middleware → validates `Authorization` header, attaches
> decoded user to `req.user`.

---

## Complete reference

| Feature | How to use |
|---|---|
| Auto-applied roles | Open a file → matching role loads automatically |
| Start session | `/start-session` prompt |
| End session | `/end-session` prompt |
| Design feature | `/design-feature` prompt |
| Security review | `/security-review` prompt |
| Pin file as context | `#file:path/to/file` in chat |
| Change model | Model picker in chat panel |
| Check active instructions | "Used references" panel below responses |
| Guardrails | Always active (`applyTo: "**"`) |
| Caveman compress | `/compress` prompt |
| Caveman restore | `/restore` prompt |
| Add team member | `understudy --add-member` (terminal) |
| Create custom role | `understudy --create-role` (terminal) |
| Custom prompt | Add `.prompt.md` to `.github/prompts/` |

---

## Tips

- **You never need to manually switch agents** — just open the right file.
- Use the "Used references" panel to debug which instructions are active.
- Prompt files compose with auto-applied instructions (both are active).
- Model recommendations are in `understudy.yaml` — customize per project.
- The CLI has sub-agents (parallel work); VS Code doesn't, but auto-apply
  compensates by seamlessly switching roles as you navigate files.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Wrong role is active | Check file path matches the `applyTo` glob |
| Prompts don't appear | Verify `.prompt.md` files are in `.github/prompts/` |
| "Used references" is empty | Update VS Code — older versions don't show this |
| Guardrails not enforced | Verify `guardrails.instructions.md` has `applyTo: "**"` |
| `understudy` command not found | Re-open terminal or `source ~/.bashrc` |

---

[Back to tutorials index](README.md)
