# User Instructions — Externalized Company Brain

> Living document tracking all process directives. These instructions will be imported into Commander as the company's externalized operational knowledge.

## Source Control & Infrastructure
- All active projects live on GitLab (gitlab.com/flow-master group). Retire GitHub for active development.
- SSH protocol for git operations, HTTPS for API calls
- Every project gets its own repo, no monorepos

## Build Methodology
- Follow the KICK → COLLECT → SPEC → CHECK → BUILD cycle
- KICK: Define the run scope and create the run repo
- COLLECT: Gather requirements in REQ-XX format
- SPEC: Generate sub-component specs (SC-REQ-N format)
- CHECK: Run Architecture Review Board (ARB) — shortened format, actionable decisions only
- BUILD: Spawn agent armada, build to spec, verify E2E

## Run Planning
- Dedicated repo per run, named `{project}-run-{NNN}` (e.g., commander-run-001)
- Structure: requirements/ → existing-specs/ → specs/ → work-items/ → arb/
- Merge between CRs within a run
- Work items map 1:1 to Plane issues

## ARB Reports
- Short and actionable — focus on decisions and conflicts, not baseline documentation
- ~3 pages max per report
- Format: Decisions table → Conflicts table → Execution Order → Per-CR Summary
- Primary purpose: resolve conflicts between change requests
- For greenfield/new features, baseline IS the existing codebase — don't document it separately

## Quality Standards
- "Don't build frontend bullshit that doesn't do anything"
- Everything must show REAL data, verified end-to-end
- Test outcomes, not components
- No mocks in production code
- Proof required: screenshots, logs, command output
- TDD: specs → tests → code → refactor

## Naming Conventions
- Run repos: `{project}-run-{NNN}`
- Requirements: `REQ-{NN}` (e.g., REQ-01, REQ-02)
- Specs: `SC-REQ-{N}` (sub-component of requirement N)
- Work items: `WI-REQ-{N}` (work item for requirement N)
- Change requests: `CR-{NNN}`

## Process Evolution
- Track all instructions → eventually becomes Commander's externalized brain
- Instructions are additive — new directives extend, not replace
- When instructions conflict, latest wins
- This document is the source of truth until Commander can self-manage it

---
*Last updated: 2026-02-14*
*Maintained by: Claude Code (supervised by Benjamin Hippler)*
