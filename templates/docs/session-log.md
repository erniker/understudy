# 📓 Session Log — {{PROJECT_NAME}}
#
# ┌───────────────────────────────────────────────────────────┐
# │  TUTORIAL: Persistence between sessions                   │
# │                                                           │
# │  This file is CRITICAL to save tokens and time.           │
# │                                                           │
# │  Every time you work with Copilot CLI, the agent          │
# │  loses its memory when the session closes. BUT if at      │
# │  the end of each session you update this file, the        │
# │  next session can read it and resume without repeating.   │
# │                                                           │
# │  Golden rule:                                             │
# │  - At session START → READ this file                      │
# │  - At session END → UPDATE this file                      │
# │                                                           │
# │  This is what allows working on a project over days       │
# │  or weeks without losing context and without spending     │
# │  tokens re-explaining what was already done.              │
# └───────────────────────────────────────────────────────────┘

---

## Session: YYYY-MM-DD — (short descriptive title)

### Participants
- PM: {{TEAM_LEAD}}
- Active agents: (Architect, Backend, Frontend, DevOps, Security, QA)

### What was done
- (summary of what was accomplished)

### Decisions made
- (key decisions, referencing ADR if applicable)

### Pending for next session
- [ ] (pending task 1)
- [ ] (pending task 2)

### Blockers
- (identified blockers, if any)

### Notes
- (any additional context that helps in the next session)

---

<!-- New sessions are added ABOVE this comment -->
<!-- The most recent log is always first -->
