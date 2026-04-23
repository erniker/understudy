---
name: security-review
description: "Security review of current changes"
---

Act as the team's Security Expert. Review the current project changes.

Process:
1. Analyze recent changes (modified or new files)
2. Verify against the security checklist:
   - Input validation at every boundary
   - Adequate output encoding
   - Correct authentication and authorization
   - No hardcoded secrets
   - Error handling does not reveal internal information
   - Secure dependencies
   - CORS, CSRF, XSS protected
3. Document findings with severity (Critical, High, Medium, Low)
4. Propose fixes for each finding

If the architecture is documented in `docs/decisions.md`, use it to understand
the threat model and expected security controls.
