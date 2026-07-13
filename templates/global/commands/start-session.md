---
name: start-session
description: "Start work session — load project context if this repo has it"
---

Check whether this repository has been localized with Understudy:

- If `docs/spec.md`, `docs/decisions.md`, `docs/session-log.md` and
  `docs/team-roster.md` exist, read all four to understand the current state,
  then give me a summary of:
  - Last session: what was done and what is still pending
  - Overall project status
  - Recommended next steps

  Also compare the project name/description recorded in `docs/spec.md`'s
  "Executive summary" section against `package.json`, `README.md` and
  `git remote` in the current state of the repo. If they look out of date
  (e.g. the project was renamed), mention it and suggest updating that
  section of `docs/spec.md`.
- If they don't exist, tell me this repository hasn't been localized with
  Understudy yet, and ask whether I want to run `localize-project` now to
  get full spec/ADR/session-log tracking for this specific repo. If I
  decline, proceed without them.
