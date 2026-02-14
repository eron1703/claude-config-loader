---
name: run-planning
description: End-to-end workflow for planning and executing a development run. Creates run repo, manages requirements, runs ARB, generates specs, creates work items, and coordinates merges between change requests.
disable-model-invocation: false
---

# Run Planning Skill

**Complete workflow for planning and executing a FlowMaster development run.**

This skill synthesizes the build-method, spec-writing, arb-preparation, and new-project-playbook skills into a single, reusable process for managing development runs from requirements to deployment.

---

## Overview

A "run" is a batch of related changes developed and deployed together. Each run follows this sequence:

```
[KICK]    Create run repo, set up structure
[COLLECT] Gather requirements from stakeholders
[SPEC]    Write detailed requirement specs
[CHECK]   Run ARB, resolve conflicts, approve changes
[BUILD]   Generate work items, spawn agents, build in parallel
[MERGE]   Integrate changes between CRs on the run
```

---

## 1. KICK: Create Run Repository

### Repository Naming

Pattern: `{project}-run-{NNN}` where:
- `{project}` = project name (e.g., `commander`, `flowmaster`)
- `{NNN}` = zero-padded run number (e.g., `001`, `002`, `042`)

Examples: `commander-run-001`, `flowmaster-run-002`, `flowmaster-run-042`

### Create Repository

```bash
# Create on GitLab
cd ~/projects
mkdir {project}-run-{NNN}
cd {project}-run-{NNN}
git init
git remote add origin git@gitlab.com:flow-master/{project}-run-{NNN}.git

# Create repository structure
mkdir -p requirements/{epic-01,epic-02,epic-03}
mkdir -p specs
mkdir -p work-items
mkdir -p arb/{baseline,changes,analysis}
mkdir -p existing-specs
mkdir -p evidence

# Create README
cat > README.md << 'EOF'
# {Project} Run {NNN}

**Status**: Requirements Collection
**Started**: {date}
**Target Completion**: {date}

## Structure

- `requirements/` — Raw requirements in REQ-XX format (one per epic)
- `specs/` — Detailed specs generated from requirements (created after ARB)
- `work-items/` — Work items in WI-REQ-N format (created after specs)
- `arb/` — Architecture Review Board analysis and decisions
- `existing-specs/` — Copy of relevant specs from previous runs (baseline reference)
- `evidence/` — Test results, screenshots, verification artifacts

## Status Legend

- **New Work**: Not yet implemented
- **Mostly Done**: Partial implementation exists
- **Complete**: Fully implemented, tested, deployed

## Workflow

1. [COLLECT] All stakeholders write requirements in `requirements/epic-XX/REQ-YY.md`
2. [SPEC] Run ARB to analyze baseline, detect conflicts, approve changes
3. [CHECK] Generate detailed specs from approved requirements
4. [BUILD] Generate work items, create Plane issues, spawn agents
5. [MERGE] Merge changes on develop branch, test integration
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
.env
*.pyc
__pycache__/
.DS_Store
node_modules/
.vscode/
.idea/
EOF

# Initial commit
git add .
git commit -m "chore: Initialize run repository structure"
git push -u origin main
```

### Repository Structure

```
{project}-run-{NNN}/
├── README.md                    # Run overview and status
├── requirements/                # Requirements from stakeholders
│   ├── epic-01/
│   │   ├── SUMMARY.md          # Epic overview, dependency graph, metrics
│   │   ├── REQ-01.md           # Requirement 1
│   │   ├── REQ-02.md           # Requirement 2
│   │   └── ...
│   ├── epic-02/
│   │   ├── SUMMARY.md
│   │   └── ...
│   └── ...
├── specs/                       # Detailed specs (generated after ARB)
│   ├── SC-REQ-01.md            # Sub-component specs
│   ├── SC-REQ-02.md
│   └── ...
├── work-items/                  # Work items (generated from specs)
│   ├── WI-REQ-01-01.md         # Work item per component
│   ├── WI-REQ-01-02.md
│   └── ...
├── arb/                         # ARB analysis output
│   ├── ARB-REPORT.md           # Main ARB decision document
│   ├── baseline/               # Current state analysis
│   │   ├── SVC-*.md            # Service baselines
│   │   ├── DB-*.md             # Database baselines
│   │   └── RUNTIME-ISSUES.md   # Infrastructure issues
│   ├── changes/                # Change request analysis
│   │   ├── CR-REQ-01.md
│   │   └── ...
│   └── analysis/               # Impact and conflict analysis
│       ├── impact-matrix.md
│       ├── conflict-matrix.md
│       └── structural-changes.md
├── existing-specs/              # Baseline specs from previous runs
│   └── ...
└── evidence/                    # Test results, screenshots, verification
    ├── REQ-01/
    │   ├── step-1.png
    │   ├── console.log
    │   └── ...
    └── ...
```

---

## 2. COLLECT: Requirements Collection

### Requirements Format (REQ-XX.md)

Every requirement follows the spec-writing skill format:

```markdown
# REQ-{number}: {Title}

## Requirement
{1-3 paragraphs. State what must be built. Be explicit about scope boundaries.
If the original requirement came from user feedback, quote it, then expand.}

## Current State
{Table or prose describing what exists today. Include:
- Asset names, completion percentages, locations
- Service ports, running status
- What is 0% / not built / not specced}

## Gap Analysis
{Table format preferred:}
| Gap | Severity | Description |
|-----|----------|-------------|
| ... | Critical/High/Medium/Low | ... |

## Design

### Architecture
{ASCII architecture diagram showing:
- Services and their ports
- Data flow arrows
- Database collections
- Component placement within services}

### Data Model (ArangoDB)
{For each collection, show schema with field types}

### Components
{Summary table:}
| # | Component | Service | Purpose |
|---|-----------|---------|---------|

### Sub-Components
{One section per component — full sub-component spec format}

## Work Items
{Table or numbered list}

## Test Plan
{Organized by test type: unit, integration, E2E, acceptance criteria}
```

See the `/spec-writing` skill for complete format details.

### Epic SUMMARY.md Format

Each epic directory must contain a `SUMMARY.md`:

```markdown
# Epic {N}: {Epic Name} - Requirements Summary

## Overview
{2-3 sentences describing the epic scope.}
{Origin note, e.g., "Origin: User feedback session 2026-02-12"}
{Services involved with port numbers}

## Requirements Index

| REQ | Title | Status | Priority | Files |
|-----|-------|--------|----------|-------|
| REQ-{N} | {Title} | {New Work|Mostly Done|...} | {Critical|High|Medium|Low} | [REQ-{N}.md](REQ-{N}.md) |

## Dependency Graph
```
REQ-{A} ({Title})
  |
  +---> REQ-{B} ({Title}) -- {relationship description}
```

## Recommended Execution Order

### Wave 1: {Phase Name}
1. **REQ-{N}**: {Why this goes first, what it unblocks}

### Wave 2: {Phase Name}
2. **REQ-{N}**: {What this depends on, what it builds}

## Metrics Summary

| Metric | Count |
|--------|-------|
| Total requirements | {N} |
| Total components | {N} |
| Total work items | {N} |
| Total test cases | {N} |
| API endpoints specified | {N} |
| ArangoDB collections | {N} |

## Cross-Cutting Concerns

### ArangoDB Collections (New or Modified)

| Collection | REQ | Purpose |
|------------|-----|---------|
| {name} | REQ-{N} | {purpose} |

### Integration Points

| From | To | Integration |
|------|-----|-------------|
| {Service/REQ} | {Service/REQ} | {How they connect} |
```

### Collection Workflow

1. **Stakeholders write requirements** in their own branches
2. **Each developer** creates `epic-XX/REQ-YY.md` following the spec-writing format
3. **Submit MR** to run repo main branch
4. **Supervisor reviews** for format compliance and completeness
5. **Merge** into run repo main branch
6. **STOP** — No spec work until ALL requirements collected from ALL stakeholders

### Quality Gates

Before proceeding to ARB:
- [ ] All stakeholders confirmed requirements complete
- [ ] Every requirement follows REQ-XX format
- [ ] Every epic has SUMMARY.md with dependency graph
- [ ] All requirements merged to run repo main branch
- [ ] No "TBD" or "TODO" in any requirement
- [ ] Gap analysis present in every requirement
- [ ] Architecture diagrams present where needed

---

## 3. CHECK: Architecture Review Board (ARB)

### Run ARB Analysis

Invoke the `/arb-preparation` skill to analyze the collected requirements:

```bash
# From the run repository root
/arb-preparation
```

The ARB skill will:
1. **Collect baseline** from GitLab MAIN branches (source of truth)
2. **Overlay runtime state** from dev-01 server
3. **Analyze database state** (ArangoDB, PostgreSQL, Redis)
4. **Inventory change requests** from requirements
5. **Perform impact analysis** (services, APIs, database, structure)
6. **Detect conflicts** between change requests
7. **Generate ARB report** with recommendations

### ARB Output Format (Shortened)

The ARB report uses a **shortened, decision-focused format** (~3 pages max):

```markdown
# Architecture Review Board Report
**Run**: {runXXX}
**Date**: {date}

## Executive Summary
{2-3 paragraphs: total changes, total services affected, key decisions needed}

## Decisions Required

| # | Decision | Options | Recommendation | Impact |
|---|----------|---------|----------------|--------|
| 1 | {decision question} | A: {opt} / B: {opt} / C: {opt} | {recommended} | {affected CRs, services, collections} |
| 2 | ... | ... | ... | ... |

## Conflicts

| CR-A | CR-B | Conflict | Resolution |
|------|------|----------|------------|
| CR-01 | CR-06 | Both modify same collection schema | Sequence CR-01 first (Wave 1), CR-06 second (Wave 2) |
| ... | ... | ... | ... |

## Execution Order

### Wave 1: {Phase Name}
| CRs | Rationale |
|-----|-----------|
| CR-01, CR-03, CR-05 | {Why these go first, what they unblock} |

### Wave 2: {Phase Name}
| CRs | Rationale |
|-----|-----------|
| CR-06, CR-09 | {What these depend on from Wave 1} |

## Per-CR Summary

| CR | Type | Services | DB Changes | Breaking? | Verdict |
|----|------|----------|-----------|-----------|---------|
| CR-01 | FEATURE | process-design (9003) | Add 2 collections | No | APPROVE (Wave 1) |
| CR-06 | STRUCTURAL | Merge human-task → engage | Modify 5 collections | Yes | APPROVE WITH CONDITIONS (Wave 2, requires CR-01) |
| CR-09 | ENHANCEMENT | frontend (3000) | None | No | APPROVE (Wave 1) |
| CR-15 | STRUCTURAL | Replace process-manager with process-design | Remove 3 collections | Yes | DEFER (too risky, needs separate run) |

## Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | Service merge breaks existing clients | Medium | High | Add adapter layer, maintain old endpoints for 1 sprint |

## Next Steps
1. ARB reviews and makes decisions on structural changes
2. Approved CRs proceed to spec generation
3. Deferred CRs move to next run
4. Generate detailed specs incorporating ARB decisions
```

**Key differences from full ARB format**:
- **Decision-focused**: Decisions table up front, not buried
- **Conflicts explicit**: Matrix shows what conflicts and how to resolve
- **Execution order clear**: Wave-based sequencing, not just dependencies
- **Per-CR verdict**: Single table with approve/defer/reject per CR
- **~3 pages max**: Focused on actionable decisions, not baseline documentation

### ARB Review and Approval

1. **ARB reviews** the report (human team)
2. **Make decisions** on structural changes, conflicts, execution order
3. **Document decisions** in ARB-REPORT.md
4. **Update CR verdicts**: APPROVE, APPROVE WITH CONDITIONS, DEFER, REJECT
5. **Finalize wave assignments**: Which CRs in which waves

### Post-ARB Actions

- **APPROVED CRs** → Proceed to spec generation (next phase)
- **DEFERRED CRs** → Move to next run repository
- **REJECTED CRs** → Archive with rationale
- **APPROVED WITH CONDITIONS** → Document conditions, assign to wave

---

## 4. SPEC: Generate Detailed Specs

### Generate Specs from Requirements

For each approved requirement:

1. **Read the requirement** (REQ-XX.md)
2. **Incorporate ARB decisions** (structural changes, execution wave, dependencies)
3. **Expand sub-components** following the spec-writing skill format
4. **Write detailed specs** in `specs/SC-REQ-XX.md`

### Spec Format (SC-REQ-N)

Follow the sub-component format from the spec-writing skill:

```markdown
#### SC-{REQ}-{number}: {Component Name}

- **Name**: `PascalCase` or `kebab-case` identifier
- **Purpose**: {Single sentence — what this component does}
- **Service**: {Exact service name and port}

**Inputs**:
| Name | Type | Source |
|------|------|--------|
| {name} | {type} | {source component} |

**Outputs**:
| Name | Type | Consumed By |
|------|------|-------------|
| {name} | {type} | {consumer component} |

**Contract**:
{Full API contract or interface definition}

**Authorization**: {Who can call this}

**Logic Steps**:
1. {Step 1}
2. {Step 2}

**Test Cases**:
| ID | Test | Expected | Type |
|----|------|----------|------|
| T-{REQ}-{comp}-{N} | {test} | {expected} | {Unit|Integration|E2E} |
```

### Self-Contained Rule

**CRITICAL**: Each spec must be 100% self-contained. An agent reading ONLY that spec must be able to build the component without any other context.

**FORBIDDEN**:
- "See REQ-XX for details"
- "As described in the architecture section"
- "Refer to the data model"
- "See also SC-YY-ZZ"

**REQUIRED**:
- Every field type defined inline
- Every API contract fully specified
- Every dependency explicitly stated
- Every error code and message documented

### Quality Checklist (Before BUILD)

Run through the spec-writing skill Quality Checklist:

- [ ] Every component has Name, Purpose, Service
- [ ] Every component has Inputs (with source) and Outputs (with consumer)
- [ ] Every component has Contract (API, interface, or event)
- [ ] Every component has Authorization field
- [ ] Every component has numbered Logic Steps
- [ ] Every component has Test Cases table (test-rig parseable)
- [ ] Every work item has explicit dependencies or "None"
- [ ] Every work item states its service/codebase
- [ ] No "see also" or cross-references to other specs
- [ ] All data models show field types and constraints
- [ ] All API endpoints show request/response schemas and error codes
- [ ] All event-driven interactions have Event Contract
- [ ] Test plan includes unit, integration, E2E sections

**STOP. DO NOT PROCEED to work item generation until every checkbox passes.**

---

## 5. BUILD: Generate Work Items

### Work Item Format (WI-REQ-N)

Work items are **1:1 with Plane issues**. Each work item is a self-contained build task.

```markdown
### WI-{REQ}-{number}: {Title}

{1-3 sentences describing what to build.}

- **Input**: {What codebase/service to modify, port number}
- **Output**: {What the deliverable is — endpoint, component, migration, tests}
- **Dependencies**: {Explicit WI IDs this depends on, or "None"}
- **Authorization**: {Who can access}
- **Priority**: {P0|P1|P2}
- **Service**: {Service name and port}

**Deliverables**:
1. {Specific file or endpoint created}
2. {Test file with coverage >= 80%}
3. {Evidence: screenshots, logs, test output}

**Acceptance Criteria**:
- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] test-rig passes all tests
- [ ] No console errors or warnings
```

### Work Item Generation

From each sub-component spec, generate one or more work items:

1. **One work item per component** (typical case)
2. **Multiple work items** for complex components (split by concern)
3. **Infrastructure work items** for new services, DB collections, CI/CD
4. **Migration work items** for data migrations or breaking changes

### Work Item Table

Create a master work item table in `work-items/INDEX.md`:

```markdown
# Work Items Index

| ID | Title | REQ | Service | Priority | Dependencies | Status |
|----|-------|-----|---------|----------|--------------|--------|
| WI-01-01 | Agent Document Collection | REQ-01 | agent-service (8000) | P0 | None | Not Started |
| WI-01-02 | Create Agent API Endpoint | REQ-01 | agent-service (8000) | P0 | WI-01-01 | Not Started |
| WI-06-01 | Merge Engage → Human Tasks | REQ-06 | engage (9006) | P1 | WI-01-02 | Not Started |
```

### Create Plane Issues

For each work item:

```bash
plane issues create \
  --title "WI-{REQ}-{N}: {Title}" \
  --description "$(cat work-items/WI-{REQ}-{N}.md)" \
  --priority "{high|medium|low}" \
  --label "service:{service-name}" \
  --label "type:{api|frontend|migration|infrastructure}" \
  --label "wave:{wave-number}"

# Link dependencies
plane issues link {issue_id} --blocks {dependent_issue_id}
```

### Agent Checkout Protocol

Agents check out Plane issues, not raw specs:

```bash
# Agent picks up work
plane issues update {issue_id} \
  --assignee {agent_id} \
  --state "in_progress" \
  --label "agent:{agent-name}" \
  --label "env:{environment}"

# Agent reports done
plane issues update {issue_id} \
  --state "in_review" \
  --comment "Done. Evidence: {test output, screenshots, logs}"
```

See the `/new-project-playbook` skill for full agent tracking protocol.

---

## 6. MERGE: Integration Between CRs

### Branch Strategy

Each change request (CR) gets its own feature branch:

```
main
  └── develop
        ├── feature/CR-01-agent-assignments
        ├── feature/CR-06-merge-engage-human-tasks
        └── feature/CR-09-frontend-dense-split-view
```

### Per-CR Development

1. **Create feature branch** from `develop`
2. **All work items for that CR** merge into the CR's feature branch
3. **Test integration** within the CR (all components work together)
4. **MR to develop** when CR is complete

### Wave-Based Merging

ARB defines execution waves. Merge CRs wave-by-wave:

**Wave 1** (independent, no conflicts):
```bash
# CR-01, CR-03, CR-05 can merge in parallel
git checkout develop
git merge feature/CR-01-agent-assignments
git merge feature/CR-03-settings-merge
git merge feature/CR-05-frontend-nav

# Test integrated state
test-rig run integration --parallel --yes
```

**Wave 2** (depends on Wave 1):
```bash
# Wait for Wave 1 to merge and deploy
# Then merge Wave 2 CRs
git checkout develop
git merge feature/CR-06-merge-engage-human-tasks
git merge feature/CR-09-frontend-dense-split-view

# Test integrated state
test-rig run integration --parallel --yes
```

### Conflict Resolution

If ARB identified a conflict between CR-A and CR-B:

1. **Soft conflict**: Coordinate merge order (sequence in same wave)
2. **Hard conflict**: Rework one CR to accommodate the other (may require re-spec)

### Integration Testing

After each wave merge:

```bash
# Run full integration test suite
test-rig run integration --parallel --headless --yes

# Run E2E tests for affected user journeys
test-rig run e2e --filter "journey:agent-assignment" --headless --yes

# Verify no regressions
test-rig run regression --compare baseline --yes
```

### Deployment

After all CRs merged to `develop`:

```bash
# Auto-deploy to dev environment (CI/CD handles this on push)
git push origin develop

# Manual deploy to staging (after smoke tests on dev)
git checkout staging
git merge develop
git push origin staging

# Manual deploy to production (after full UAT on staging)
git checkout main
git merge staging
git push origin main
```

---

## 7. Overall Run Flow Summary

### Full Pipeline

```
[KICK]
├─ Create run repo: {project}-run-{NNN}
├─ Initialize structure: requirements/, specs/, work-items/, arb/, evidence/
└─ Commit and push to GitLab

[COLLECT]
├─ Stakeholders write requirements in epic-XX/REQ-YY.md
├─ Each requirement follows spec-writing format
├─ Create epic SUMMARY.md with dependency graphs
├─ Submit MRs to run repo main branch
└─ STOP when all stakeholders confirm complete

[CHECK]
├─ Run /arb-preparation skill
├─ ARB analyzes baseline (GitLab MAIN + runtime state + DB state)
├─ ARB catalogs change requests from requirements
├─ ARB performs impact analysis (services, APIs, DB, structure)
├─ ARB detects conflicts and sequences CRs into waves
├─ ARB produces decision report (shortened format, ~3 pages)
├─ Human ARB reviews and makes decisions
├─ Update CR verdicts: APPROVE / DEFER / REJECT
└─ STOP when ARB decisions finalized

[SPEC]
├─ For each APPROVED CR, generate detailed specs
├─ Incorporate ARB decisions (wave, dependencies, structural changes)
├─ Expand sub-components following spec-writing format
├─ Each spec is 100% self-contained (no cross-references)
├─ Run through spec-writing Quality Checklist
└─ STOP when all specs pass Quality Checklist

[BUILD]
├─ Generate work items (WI-REQ-N) from specs
├─ Create Plane issues (1:1 with work items)
├─ Link dependencies between issues
├─ Spawn agent armada (3-12 agents)
├─ Agents check out Plane issues
├─ Each agent: Read spec → test-rig generate → write tests → RED → implement → GREEN → report done
└─ Supervisor tracks progress in Plane

[MERGE]
├─ Create feature branch per CR
├─ Merge work items into CR feature branch
├─ Test integration within each CR
├─ Merge CRs to develop wave-by-wave (per ARB execution order)
├─ Run integration tests after each wave
├─ Deploy: develop → staging → main
└─ DONE
```

### Timeline Example

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| KICK | 1 hour | Run repo created, structure ready |
| COLLECT | 1-3 days | All requirements in repo, epics summarized |
| CHECK (ARB) | 1-2 days | ARB report, decisions made, waves assigned |
| SPEC | 2-5 days | All specs written, quality-checked |
| BUILD | 3-10 days | All work items complete, Plane issues closed |
| MERGE | 1-3 days | All CRs merged, deployed to staging |
| **TOTAL** | **8-24 days** | Full run delivered to production |

---

## 8. ARB Shortened Format (Detailed)

The ARB report focuses on **actionable decisions**, not exhaustive baseline documentation.

### Template

```markdown
# ARB Report — {Project} Run {NNN}

**Date**: {date}
**Baseline**: GitLab MAIN branches as of {date}
**Runtime**: {server} as of {date}

---

## Executive Summary

{2-3 paragraphs}
- Total CRs: {N}, Total services affected: {N}, Total DB collections affected: {N}
- {N} structural changes (merges, splits, new services)
- {N} conflicts requiring sequencing
- {N} decision points for ARB

---

## Decisions Required

| # | Decision | Options | Recommendation | Impact |
|---|----------|---------|----------------|--------|
| 1 | Merge human-task and engage services? | A: Merge into unified engage service<br>B: Keep separate, add shared DB collections<br>C: Do nothing | **A (Merge)** — Reduces complexity, aligns with unified task model | CRs: CR-06<br>Services: human-task (9006), engage (9015)<br>Collections: Merge 5 collections into engage_tasks |
| 2 | Replace process-manager with enhanced process-design? | A: Full replacement in this run<br>B: Gradual migration over 2 runs<br>C: Keep both, deprecate process-manager later | **B (Gradual)** — Too risky for single run, phase out old endpoints over time | CRs: CR-15, CR-16, CR-17<br>Services: process-manager (9004), process-design (9003)<br>Breaking: All process-manager clients |

---

## Conflicts

| CR-A | CR-B | Conflict | Resolution |
|------|------|----------|------------|
| CR-01 (Agent Assignments) | CR-06 (Merge Engage/HumanTask) | Both add collections to engage service | **Sequence**: CR-01 first (Wave 1), CR-06 second (Wave 2). CR-06 will see CR-01's collections and build on them. |
| CR-09 (Frontend DenseSplitView) | CR-12 (Frontend Nav Redesign) | Both modify same navigation component | **Coordinate**: Assign same agent or adjacent agents. Build CR-09 first (simpler), CR-12 adapts. |
| CR-15 (Replace ProcessManager) | CR-18 (Process Linking) | CR-18 assumes process-manager still exists | **Hard conflict**: Defer CR-15 to next run. Too risky. CR-18 proceeds with process-manager in place. |

---

## Execution Order

### Wave 1: Foundation (5 CRs)
| CRs | Services | DB Changes | Rationale |
|-----|----------|-----------|-----------|
| CR-01, CR-03, CR-05, CR-09, CR-10 | agent-service, settings, frontend, process-design | Add 6 collections | Independent, no conflicts. Unblocks Wave 2. |

### Wave 2: Integration (3 CRs)
| CRs | Services | DB Changes | Rationale |
|-----|----------|-----------|-----------|
| CR-06, CR-12, CR-18 | engage, frontend, process-design | Modify 8 collections | Depends on Wave 1 foundations. |

### Wave 3: Structural (Deferred)
| CRs | Services | DB Changes | Rationale |
|-----|----------|-----------|-----------|
| CR-15, CR-16, CR-17 | process-manager, process-design | Remove 3 collections, merge 5 | Too risky for this run. Move to Run 003. |

---

## Per-CR Summary

| CR | Type | Services | DB Changes | Breaking? | Verdict |
|----|------|----------|-----------|-----------|---------|
| CR-01 | FEATURE | agent-service (8000) | Add: agents, agent_assignments (2 collections) | No | **APPROVE** (Wave 1) |
| CR-03 | STRUCTURAL | settings → flowmaster-backend | Merge: settings into flowmaster_settings collection | No (settings was standalone) | **APPROVE** (Wave 1) |
| CR-05 | ENHANCEMENT | frontend (3000) | None | No | **APPROVE** (Wave 1) |
| CR-06 | STRUCTURAL | Merge human-task → engage | Modify: 5 collections (human_tasks → engage_tasks) | Yes (API endpoints change) | **APPROVE WITH CONDITIONS** (Wave 2, requires CR-01) |
| CR-09 | FEATURE | frontend (3000) | None | No | **APPROVE** (Wave 1) |
| CR-10 | INFRASTRUCTURE | process-design (9003) | Add: process_templates collection | No | **APPROVE** (Wave 1) |
| CR-12 | ENHANCEMENT | frontend (3000) | None | No | **APPROVE** (Wave 2, coordinate with CR-09) |
| CR-15 | STRUCTURAL | Replace process-manager with process-design | Remove: 3 collections, merge 5 | **Yes (high risk)** | **DEFER to Run 003** |
| CR-16 | STRUCTURAL | Merge process-views → process-design | Remove: process_views service | Yes | **DEFER to Run 003** (part of CR-15 effort) |
| CR-17 | STRUCTURAL | Merge process-versioning → process-design | Remove: process_versioning service | Yes | **DEFER to Run 003** (part of CR-15 effort) |
| CR-18 | FEATURE | process-design (9003) | Add: process_links edge collection | No | **APPROVE** (Wave 2) |

---

## Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | Service merge (CR-06) breaks existing clients | Medium | High | Add adapter layer in engage service. Maintain old human-task endpoints for 1 sprint (deprecate in Run 003). |
| 2 | Database migration (CR-06) loses data | Low | Critical | Dry-run migration on staging. Backup before migration. Rollback plan documented. |
| 3 | Disk full on dev-01 during build | Medium | Medium | Clean up orphaned volumes before run starts. Monitor disk during build. |

---

## Next Steps

1. ARB reviews this report and confirms decisions
2. Approved CRs (Wave 1, Wave 2) proceed to spec generation
3. Deferred CRs (Wave 3) move to Run 003 repository
4. Generate detailed specs incorporating ARB decisions
5. Generate work items from specs
6. Create Plane issues and spawn agent armada
```

**Total length**: ~3 pages focused on decisions, not 20+ pages of baseline documentation.

---

## 9. Execution Checklist

Use this checklist to track run progress:

### KICK
- [ ] Run repository created on GitLab
- [ ] Directory structure initialized
- [ ] README.md written with run overview
- [ ] Initial commit and push

### COLLECT
- [ ] All stakeholders identified
- [ ] Epic structure defined
- [ ] Requirements templates shared with stakeholders
- [ ] All requirements submitted (MRs to run repo)
- [ ] All requirements follow REQ-XX format
- [ ] All epics have SUMMARY.md
- [ ] All requirements merged to run repo main

### CHECK
- [ ] ARB analysis initiated (/arb-preparation skill)
- [ ] Baseline collected (GitLab MAIN + runtime + DB)
- [ ] Change requests cataloged
- [ ] Impact analysis complete
- [ ] Conflicts detected and documented
- [ ] Execution waves defined
- [ ] ARB report written (shortened format)
- [ ] Human ARB review complete
- [ ] Decisions documented
- [ ] CR verdicts assigned (APPROVE/DEFER/REJECT)

### SPEC
- [ ] Specs generated for all APPROVED CRs
- [ ] ARB decisions incorporated
- [ ] All specs follow sub-component format
- [ ] All specs 100% self-contained
- [ ] Quality Checklist passed for every spec

### BUILD
- [ ] Work items generated from specs
- [ ] Plane project created
- [ ] Plane issues created (1:1 with work items)
- [ ] Dependencies linked in Plane
- [ ] Agent armada spawned
- [ ] All Plane issues assigned and in progress
- [ ] All Plane issues completed with evidence

### MERGE
- [ ] Feature branches created per CR
- [ ] Work items merged into CR branches
- [ ] Integration tests pass per CR
- [ ] Wave 1 CRs merged to develop
- [ ] Wave 1 integration tests pass
- [ ] Wave 2 CRs merged to develop
- [ ] Wave 2 integration tests pass
- [ ] Develop deployed to dev environment
- [ ] Staging merged and deployed
- [ ] Production merged and deployed (manual gate)

---

## 10. Common Patterns

### Small Run (1-3 Requirements)

- 1 epic, 1-3 requirements
- ARB analysis lightweight (may skip if no structural changes)
- Single wave execution
- 1-3 agents
- Timeline: 3-7 days

### Medium Run (4-10 Requirements)

- 2-3 epics, 4-10 requirements
- ARB analysis required
- 2 waves execution
- 3-8 agents
- Timeline: 8-15 days

### Large Run (11+ Requirements)

- 3+ epics, 11+ requirements
- Full ARB analysis with detailed conflict resolution
- 3+ waves execution
- 8-12 agents
- Timeline: 15-30 days

### Emergency Hotfix Run

- Skip COLLECT phase (single requirement)
- Skip ARB (unless structural)
- Direct to SPEC and BUILD
- Single agent or pair
- Timeline: 1-2 days

---

## 11. Integration with Other Skills

| Skill | Relationship |
|-------|-------------|
| `/build-method` | Defines the overall methodology; run-planning implements it end-to-end |
| `/spec-writing` | Defines requirement and sub-component format; run-planning uses it in COLLECT and SPEC |
| `/arb-preparation` | Defines ARB analysis; run-planning invokes it in CHECK phase |
| `/new-project-playbook` | Defines Plane setup and agent tracking; run-planning uses it in BUILD phase |
| `/flowmaster-overview` | Provides service registry for baseline analysis |
| `/test-rig` | Used by agents for TDD workflow during BUILD |

---

## 12. Forbidden Patterns

| Anti-Pattern | Why It Breaks |
|--------------|---------------|
| Building before ARB | Conflicts discovered mid-build waste agent time |
| Skipping COLLECT phase | Incomplete requirements lead to re-work |
| Specs with cross-references | Agent can't build from spec alone |
| Merging CRs out of wave order | Conflicts manifest as broken tests or runtime errors |
| Work items without Plane issues | No agent tracking, no visibility |
| Deploying without integration tests | Regressions slip to production |

---

## 13. Success Criteria

A run is successful when:

- [ ] All APPROVED CRs delivered and deployed
- [ ] All integration tests pass
- [ ] No regressions in existing functionality
- [ ] All Plane issues closed with evidence
- [ ] DEFERRED CRs documented in next run repo
- [ ] Post-run retrospective complete

---

## End of Run Planning Skill

This skill synthesizes build-method, spec-writing, arb-preparation, and new-project-playbook into a single, repeatable workflow for managing FlowMaster development runs from planning through deployment.
