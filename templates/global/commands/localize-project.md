---
name: localize-project
description: "Create persistent project memory for this repo (spec, ADRs, session log) on top of the global Understudy team"
---

The user wants this repository to have persistent, spec-driven memory
instead of relying only on the machine-wide global team's session-by-session
context.

Run the following from the repository root and report what it created:

    understudy --docs-only --yes

This creates `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md`,
`docs/team-roster.md` and a project-level `understudy.yaml` — real spec/ADR/
session-log tracking for this specific repo. It does **not** deploy or
duplicate any agent files: the team (Architect, Backend, Frontend, DevOps,
Security, QA, etc.) keeps coming from the global install.

If the user instead wants full per-project customization (different models
per role, `apply_to` scoping tailored to this repo's stack, project-specific
instructions instead of the shared global ones), tell them to run
`understudy --here` instead — it deploys the full per-project agent set on
top of whatever is already here, never removing anything.

If the `understudy` command is not on PATH, tell the user how to install it
(the one-liner in the project README) instead of failing silently.
