---
applyTo: "**"
---
# Understudy — Global Team (machine-wide)

## Scope

This file was installed by `understudy --global` via VS Code's
`chat.instructionsFilesLocations` user setting — it applies to **every**
workspace you open in this VS Code profile, unlike `.github/copilot-instructions.md`
which is scoped to a single repository. A repository's own
`.github/copilot-instructions.md` (deployed by `understudy` or
`understudy --here`) still loads automatically for that repo on top of this.

## Team context

This machine uses the **Understudy** system: a team of specialized AI
agents. Role-specific instructions (`architect`, `backend`, `frontend`,
`devops`, `security`, `qa-engineer`) are deployed alongside this file and
apply automatically based on the file you are editing (`applyTo` glob).

## Spec-Driven Development (per repository)

- **If the current repository has `docs/spec.md`**, treat it as the living
  contract: read it and `docs/decisions.md`/`docs/session-log.md` before
  working, and update `docs/session-log.md` at the end of the session.
- **If it does not**, this repository has not been localized yet. You may
  still work directly, or suggest running the `localize-project` prompt to
  add persistent spec/ADR/session-log tracking for that specific repository
  — the team itself keeps coming from this global install.

## Turning this repo into a persistent project

If the user expresses — in any words — that this repository should have
real, persistent memory rather than relying on session-by-session context
alone (e.g. "let's set this up properly", "guarda esto como proyecto",
"quiero spec-driven aquí"), offer to run the `localize-project` prompt for
them. It creates `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`
and `docs/team-roster.md` for this specific repo, without touching source
code or overwriting anything that already exists. It does **not** deploy
project-specific instruction files — the team keeps coming from this global
install. If the user instead wants per-project customization (different
models per role, `apply_to` scoping, project-specific instructions instead
of these shared global ones), tell them to run `understudy --here` instead.

## Recognizing good stopping points

A long conversation costs more (tokens, time, money) than starting fresh
with a concise summary. Watch for natural stopping points — a feature just
finished with tests passing, a bug fixed and verified, a question fully
answered — and proactively suggest wrapping up:
1. If this repo has `docs/session-log.md`, run `end-session` (or update the
   log yourself) so the next session has a clean handoff. If it doesn't,
   just summarize progress in the chat.
2. Tell the user this is a good point to close this chat and start a new
   one — the next session picks up context from `docs/session-log.md` (if
   this repo has one) or this global team, so nothing important is lost.

Don't interrupt in-progress work to suggest this, and never refuse to keep
going if the user wants to continue — it's a suggestion at natural breaks,
not a requirement.

## Code standards

- Readable and maintainable code for any team member
- Single-responsibility functions
- Business domain names, not generic names
- Explicit error handling with context in messages
- No hardcoded secrets — use vault/env vars
- No dead code or TODO comments in commits

<!-- GUARDRAILS_START -->
{{GUARDRAILS_SECTION}}
<!-- GUARDRAILS_END -->
