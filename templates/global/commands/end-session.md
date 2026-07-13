---
name: end-session
description: "Close session — update log if this repo tracks one"
---

Check whether `docs/session-log.md` exists in this repository:

- If it exists, add a new entry at the top with:
  1. **Date**: Today's date
  2. **Active agents**: Which roles participated
  3. **What was done**: Summary of this session's achievements
  4. **Decisions made**: If decisions were made, reference the ADR in
     `docs/decisions.md`
  5. **Pending**: What remains to be done for the next session
  6. **Blockers**: If there is anything preventing progress

  Make the entry detailed enough that any agent can resume work next session
  without needing to re-explain context.
- If it does not exist, summarize what was done in this session in the chat
  instead, and mention that running `localize-project` in this repo would
  give it persistent session-log tracking across sessions.

Either way, remind the user that this is a good point to close this chat
and start a new one: `start-session` picks up full context from what you
just wrote (or from this global team, if this repo has no session log yet),
and a fresh chat costs less (tokens, time) than continuing a long one.
