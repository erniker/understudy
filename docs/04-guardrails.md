# 4. Guardrails

Guardrails are **non-negotiable security and behavior limits** that every
Understudy agent must respect, without exception. They are not suggestions —
they are hard restrictions enforced at multiple levels.

## Why guardrails exist

AI assistants are powerful but unpredictable. Without explicit limits, an
agent might:

- Hardcode a secret in a commit
- Run `rm -rf /` or `terraform destroy` without thinking twice
- Process real customer data and echo it back
- Push directly to production
- Write code before the spec is agreed

Guardrails prevent all of this. They are deployed automatically by the
wizard and active from the first session.

## The 8 categories

| # | Category | What it protects |
|---|---|---|
| 1 | **Security** | No hardcoded secrets, mandatory input validation, least privilege |
| 2 | **Scope & Ownership** | Each agent owns specific areas; crossing boundaries requires justification |
| 3 | **Process (Spec-Driven)** | No code without an approved spec (exceptions: bugfixes, emergencies, CVEs) |
| 4 | **Destructive Operations** | PM confirmation before deleting, purging or revoking anything |
| 5 | **Data & PII** | No real data, no PII in code/tests/logs; synthetic data only |
| 6 | **Quality** | Self-review, appropriate tests, no dead code, explicit error handling |
| 7 | **Environments** | Promotion order dev → test → acc → eng → prd; mandatory IaC |
| 8 | **Documentation** | ADRs in `decisions.md`, session log updated, spec kept current |

### 1. Security

- **NEVER** hardcode secrets, tokens, API keys or passwords
- **ALWAYS** use vault services (Key Vault, Secrets Manager) for secrets
- **ALWAYS** validate and sanitize inputs at system boundaries
- **ALWAYS** apply the principle of least privilege
- If a secret is detected in code or logs → **STOP and alert the PM**

### 2. Scope & Ownership

Each agent has primary areas of responsibility:

| Agent | Primary ownership |
|---|---|
| Architect | `docs/decisions.md`, API contracts, diagrams |
| Backend | `src/api/`, `src/application/`, `src/domain/`, `src/infrastructure/` |
| Frontend | `src/components/`, `src/features/`, `src/hooks/`, `src/ui/` |
| DevOps | `infra/`, `pipelines/`, `docker/`, `.github/workflows/`, `*.tf` |
| Security | Threat models, security reviews, security configs |
| QA | `tests/`, `*.test.*`, `*.spec.*`, test plans |

Crossing boundaries is permitted when the task explicitly requires it, there
is a documented justification, or the PM has approved the scope change.

### 3. Process — Spec-Driven Development

Before writing code, verify that `docs/spec.md` has requirements for the
task and that the spec is **APPROVED**. Valid exceptions that do not require
a full spec:

- **Bugfixes** — corrections of errors in existing code
- **Emergencies** — production hotfixes (document post-mortem)
- **Dependencies/CVE** — vulnerability updates
- **Config/metadata** — minor configuration changes

### 4. Destructive Operations

The following **require explicit PM confirmation** before execution:

- Delete files, directories, tables, databases or cloud resources
- `DROP`, `DELETE`, `TRUNCATE` on databases
- `terraform destroy` or `kubectl delete`
- Purge caches, message queues or storage
- Revoke access, tokens or certificates
- Force-push or rebase on shared branches

Before destroying, the agent must present: **what**, **why**, **impact**
and **reversibility** — then wait for approval.

### 5. Data & PII

- **NEVER** include, repeat or process real customer data
- **NEVER** log sensitive data (tokens, passwords, PII)
- **ALWAYS** use synthetic data for tests and examples
- If real data is detected → **STOP immediately**

### 6. Quality

- Self-review before presenting code
- New code must have appropriate tests (unit, integration, dry-run)
- No dead code, unused imports or TODOs in commits
- Explicit error handling with context — no silent failures

### 7. Environments

Promotion order (never skip):
```
dev → test → acceptance → engineering → production
```

- **NEVER** make changes directly in production without change control
- **ALWAYS** use IaC and pipelines — never manual console changes
- Production data must never be copied to lower environments without
  anonymization

### 8. Documentation

- Document technical decisions in `docs/decisions.md` using ADR format
- Update `docs/session-log.md` at the end of each session
- If scope changes, update `docs/spec.md` before implementing

## Deployment modes

The wizard offers two guardrail deployment strategies:

| Mode | How it works | Best for |
|---|---|---|
| **split** (recommended) | Critical guardrails always active in global instructions (`copilot-instructions.md`, `CLAUDE.md`, `guardrails.mdc`) + full detailed file (`guardrails.instructions.md`) | Regulated teams, larger repos, multi-agent workflows |
| **embedded** | Only critical guardrails in global instructions; no separate file | Small/fast projects, lightweight setups |

Select the mode during the wizard or set it in `understudy.yaml`:

```yaml
guardrails:
  mode: "split"   # or "embedded"
```

### What "critical" vs "full" means

- **Critical guardrails** (always active, both modes): the compact block
  between `<!-- GUARDRAILS_START -->` and `<!-- GUARDRAILS_END -->` markers.
  Covers security, destructive ops, data/PII, environments, scope and
  process — enough for most sessions.
- **Full guardrails** (split mode only): the complete file
  `guardrails.instructions.md` with detailed rules, ownership tables,
  examples and checklists for all 8 categories. Applied via `applyTo: "**"`
  in VS Code, activated via `/instructions` in Copilot CLI.

## Enforcement per platform

| Platform | Guardrails layer | How it's enforced |
|---|---|---|
| **Copilot CLI** | `copilot-instructions.md` (critical block) + `guardrails.instructions.md` (full, via `/instructions`) | Instruction files — the model follows them |
| **VS Code** | Same files, but `guardrails.instructions.md` auto-applies via `applyTo: "**"` | Auto-applied to every file |
| **Claude Code** | `CLAUDE.md` (critical block) + `.claude/hooks/guardrails-check.sh` (PreToolUse) + `settings.json` (deny list) | **Three layers**: instructions + hook that blocks destructive commands + file access deny |
| **Cursor** | `.cursor/rules/guardrails.mdc` (critical block, `alwaysApply: true`) | Always-applied rule |

### Claude Code's extra safety

Claude Code is the only platform with active enforcement beyond instructions:

1. **PreToolUse hook** (`guardrails-check.sh`) — runs before every shell
   command. Blocks patterns like `rm -rf`, `terraform destroy`,
   `kubectl delete`, `DROP TABLE`, `git push --force`, etc. Exits with
   code 2 to block, 0 to allow.

2. **Permission deny list** (`settings.json`) — Claude refuses to read or
   write files matching the deny list (`.env`, `secrets/`, `*.key`,
   `*.pem`, etc.).

3. **Secret detection** — the hook warns (but does not block) when commands
   reference `.env`, `.key`, `.pem`, `credentials` or `password` patterns.

### Customizing the hook

The destructive patterns are defined in the `DESTRUCTIVE_PATTERNS` array at
the top of `.claude/hooks/guardrails-check.sh`. To add a new pattern:

```bash
DESTRUCTIVE_PATTERNS=(
    # ... existing patterns ...
    "my-custom-dangerous-command"
)
```

To relax a pattern (allow a specific destructive operation), remove it from
the array — but document why in `docs/decisions.md`.

## Customizing guardrails

### Adding rules

Edit `guardrails.instructions.md` (Copilot) or `guardrails.mdc` (Cursor)
directly. The critical block inside `copilot-instructions.md` / `CLAUDE.md`
is regenerated by the wizard — add custom rules outside the
`GUARDRAILS_START` / `GUARDRAILS_END` markers.

### Disabling rules

Do **not** remove guardrails without documentation. If a rule is too strict
for your project, document the exception in `docs/decisions.md` as an ADR
and modify the rule accordingly.

---

Next: [Roles & Spec-Driven Development](05-roles-and-workflow.md)
