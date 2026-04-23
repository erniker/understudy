# 📋 Project Specification — {{PROJECT_NAME}}
#
# ┌───────────────────────────────────────────────────────────┐
# │  TUTORIAL: Spec-Driven Development                       │
# │                                                           │
# │  This file is THE SOURCE OF TRUTH for the project.       │
# │  No agent writes code without reading this file          │
# │  first. This ensures that:                               │
# │                                                           │
# │  1. All agents work with the same requirements           │
# │  2. Misunderstandings and rework are reduced             │
# │  3. Scope changes are documented here first              │
# │  4. In future sessions, any agent can re-read this       │
# │     spec and resume with full context                    │
# │                                                           │
# │  The PM (you) writes the initial version. The Architect  │
# │  refines it with technical questions. The rest of the    │
# │  team uses it as reference.                              │
# └───────────────────────────────────────────────────────────┘

## 1. Executive summary

**Project name**: {{PROJECT_NAME}}
**Description**: {{PROJECT_DESCRIPTION}}
**Business objective**: (What problem does it solve? For whom?)

## 2. Stakeholders

| Role | Name | Responsibility |
|---|---|---|
| Project Manager | {{TEAM_LEAD}} | Requirements definition and prioritization |
| Product Owner | (TBD) | Business validation |
| End users | (describe) | System usage |

## 3. Functional requirements

### FR-001: (requirement name)
- **Description**: ...
- **Actor**: Who uses this functionality?
- **Main flow**: Step by step of the happy path
- **Alternative flows**: What happens if something fails
- **Acceptance criteria**:
  - [ ] Criterion 1
  - [ ] Criterion 2
- **Priority**: High / Medium / Low

### FR-002: ...
(repeat for each functional requirement)

## 4. Non-functional requirements

| ID | Category | Requirement | Metric |
|---|---|---|---|
| NFR-001 | Performance | API response time | < 200ms p95 |
| NFR-002 | Availability | Uptime | 99.9% |
| NFR-003 | Scalability | Concurrent users | (define) |
| NFR-004 | Security | Authentication | (define method) |
| NFR-005 | Accessibility | Standard | WCAG 2.1 AA |

## 5. Integrations

| External system | Type | Purpose | Protocol |
|---|---|---|---|
| (system) | API / DB / Messaging | (what for) | REST / gRPC / etc. |

## 6. Constraints

- **Technical**: (mandatory stack, regulations, etc.)
- **Timeline**: (deadline, milestones)
- **Budget**: (cloud spend limits, licenses)
- **Organizational**: (available team, mandatory processes)

## 7. Out of scope

Explicitly NOT included in this version:
- (excluded functionality 1)
- (excluded functionality 2)

## 8. Glossary

| Term | Definition |
|---|---|
| (domain term) | (its meaning in this context) |

---

> **Spec status**: DRAFT | UNDER REVIEW | APPROVED
> **Last updated**: {{DATE}}
> **Approved by**: (pending)
