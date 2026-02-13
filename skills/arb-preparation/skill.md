---
name: arb-preparation
description: Architecture Review Board preparation — combined impact analysis of all change requests against the existing codebase baseline (MAIN). Produces ARB-ready documentation for merge/architecture decisions.
user-invocable: true
---

# ARB Preparation Skill

Prepare documentation for Architecture Review Board decisions by performing a combined impact analysis of all change requests (from a `runXXX` requirements repository) against the existing codebase baseline (MAIN branches of all services).

---

## 1. Purpose

The ARB preparation skill produces a single, comprehensive **Change Impact Report** that:

1. Documents the **baseline state** of every service (what is deployed today on MAIN)
2. Catalogs **all change requests** from the run repository (e.g., `run001`)
3. Performs a **combined impact analysis** — how each change affects existing services, other changes, and the overall architecture
4. Identifies **structural changes** — service merges, splits, new services, service removals, DB schema changes
5. Highlights **conflicts and dependencies** between change requests
6. Produces an **ARB decision matrix** — what to approve, defer, or reject

The output is an ARB-ready document that enables the team to make informed architectural decisions before any code is written.

---

## 2. Inputs

### Required
- **Run repository path**: Local path to the `runXXX` requirements repo (e.g., `~/run001`)
- **GitLab access**: Access to the FlowMaster GitLab group (https://gitlab.com/flow-master/) — MAIN branches are the baseline source of truth
- **Service registry**: List of all services with their repos, ports, and current state (load `flowmaster-backend` skill)

### Optional
- **SSH access to dev-01**: For runtime state overlay (container health, nginx config, network state) — supplements but does NOT replace the GL codebase baseline
- **Previous ARB decisions**: Any prior ARB output to build on
- **Priority overrides**: User-specified priority for specific requirements

---

## 3. Execution Steps

### Phase 1: Baseline Collection

**Goal**: Document "as-built today" for every service using the **MAIN branch on GitLab** as the source of truth. The MAIN branch represents what is (or should be) deployed.

#### 1a. Codebase Baseline (Primary — from GitLab MAIN branches)

```
For each service in the service registry:
  1. Clone or fetch the MAIN branch from GitLab (see repos skill for URLs)
     - Primary repo: https://gitlab.com/flow-master/{service-repo}
     - Fallback: local checkout at ~/projects/flowmaster (if GL unavailable)
  2. Read the MAIN branch code — this IS the baseline
  3. Extract:
     - Service name, port, framework
     - API endpoints (routes/controllers — scan for @app.get, @app.post, router.* patterns)
     - Database collections/tables used (scan for db.collection, CREATE TABLE, AQL queries)
     - Inter-service dependencies (imports, HTTP client calls, event bus publishers/subscribers)
     - Frontend routes/pages (scan for Route components, page directories)
     - Docker/infrastructure config (Dockerfile, docker-compose service definition)
     - Environment variables required (scan for os.getenv, process.env)
  4. Produce a Baseline Service Card (see Section 5)
```

**Tools**: `git clone --branch main --depth 1` for GL repos, Glob/Read/Grep for code analysis.

**Output**: `baseline/` directory with one `SVC-{name}.md` per service.

#### 1b. Runtime State Overlay (Secondary — from dev-01 SSH)

**Purpose**: Capture runtime-specific state that code alone cannot reveal. This is additive — it supplements the codebase baseline, not replaces it.

```
Via SSH to dev-01 (65.21.153.235):
  1. Container health: docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  2. Nginx configuration: sudo nginx -T (upstream blocks, location blocks, SSL certs)
  3. Docker networks: docker network ls + inspect (network fragmentation issues)
  4. Docker volumes: docker volume ls (persistent data locations)
  5. Cron jobs: crontab -l + ls /etc/cron.d/ (scheduled tasks)
  6. Systemd services: systemctl list-units --type=service --state=running
  7. SSL certificates: ls /etc/letsencrypt/live/ (cert expiry dates)
  8. Disk usage: df -h /srv/ (capacity constraints)
```

**What to flag from runtime overlay**:
- Services in code but NOT running → "Not Deployed" status
- Services running but NOT in code → "Orphan Container" warning
- Network fragmentation (multiple bridge networks instead of unified) → infrastructure risk
- Unhealthy containers → stability risk for dependent services
- Missing environment variables → deployment gap
- Nginx routing mismatches (upstream defined but container dead) → routing risk

**Output**: Annotate each `SVC-{name}.md` with a `## Runtime State` section. Create `baseline/RUNTIME-ISSUES.md` for cross-cutting infrastructure concerns.

#### 1c. Database Baseline

**Goal**: Document the current state of ALL databases used by FlowMaster services.

```
For each database instance:
  1. ArangoDB (port 8529):
     - List all databases: GET /_api/database
     - For each database, list collections: GET /_api/collection
     - For each collection: record type (document/edge), approximate count, indexes
     - List all graphs: GET /_api/gharial
     - List all ArangoSearch views: GET /_api/view
     - Check replication/backup config
  2. PostgreSQL (port 5432):
     - List all databases: \l
     - For each database, list schemas and tables: \dt for each schema
     - Record row counts, indexes, foreign keys
     - Check connection pool settings (max_connections)
     - Check replication status
  3. Redis (port 6379, 6380, 6383):
     - List all keys by pattern: KEYS * (or SCAN for production)
     - Record memory usage: INFO memory
     - Check persistence config (RDB/AOF)
     - Identify which service owns which key prefix

For each collection/table:
  1. Document the schema (fields, types, constraints)
  2. Identify the owning service (which service writes to it)
  3. Identify consumers (which services read from it)
  4. Record approximate size and growth rate
  5. Flag shared collections (multiple writers = risk)
```

**Output**: `baseline/DB-ARANGODB.md`, `baseline/DB-POSTGRESQL.md`, `baseline/DB-REDIS.md`

**Database Service Card Template** (`DB-{type}.md`):

```markdown
# DB-{type}: {Database Display Name}

## Overview
- **Type**: ArangoDB|PostgreSQL|Redis
- **Port**: {port}
- **Version**: {version}
- **Container**: {container name}
- **Data Directory**: {volume mount path}

## Databases/Keyspaces
| Database | Owner Service | Collections/Tables | Size (approx) |
|----------|--------------|-------------------|----------------|

## Collections/Tables Detail
| Name | Type | Owner | Readers | Record Count | Indexes |
|------|------|-------|---------|-------------|---------|

## Shared Data (Risk Areas)
| Collection/Table | Writers | Readers | Conflict Risk |
|-----------------|---------|---------|---------------|

## Backup & Recovery
- **Backup Schedule**: {schedule or "none"}
- **Retention**: {days}
- **Recovery Tested**: {yes/no/unknown}
```

### Phase 2: Change Request Inventory

**Goal**: Catalog every change request from the run repository.

```
For each requirement file (REQ-XX.md) in the run repo:
  1. Read the requirement, current state, gap analysis
  2. Extract:
     - REQ ID and title
     - Epic membership
     - Affected services (from architecture section)
     - Affected DB collections (new, modified, removed)
     - Affected API endpoints (new, modified, removed)
     - Affected frontend pages/components
     - Structural changes (service merges, splits, new services)
     - Component count, work item count
     - Dependencies on other REQs
     - Priority and severity
  3. Classify the change type:
     - FEATURE: New capability
     - ENHANCEMENT: Improvement to existing capability
     - STRUCTURAL: Service architecture change (merge, split, new, remove)
     - MIGRATION: Data or API migration
     - BUGFIX: Correction of existing behavior
     - INFRASTRUCTURE: Deployment, CI/CD, monitoring changes
  4. Produce a Change Request Card (see Section 5)
```

**Output**: `changes/` directory with one `CR-{REQ-ID}.md` per change request.

### Phase 3: Impact Analysis

**Goal**: Determine how each change affects the baseline and other changes.

#### 3a. Per-Change Impact

```
For each Change Request:
  1. Map affected services to baseline service cards
  2. For each affected service:
     - List endpoints that will be added/modified/removed
     - List DB collections that will be added/modified/removed
     - List inter-service dependencies that will change
     - Identify breaking changes (API contract changes, removed endpoints)
     - Identify non-breaking changes (additive endpoints, new collections)
  3. Calculate impact score:
     - Services affected count
     - Breaking changes count
     - New dependencies introduced
     - DB schema changes
     - Frontend route changes
```

#### 3b. Cross-Change Conflict Detection

```
For each pair of Change Requests:
  1. Check for overlapping service modifications
  2. Check for conflicting DB schema changes (same collection, different changes)
  3. Check for conflicting API changes (same endpoint, different contracts)
  4. Check for dependency cycles (CR-A needs CR-B, CR-B needs CR-A)
  5. Check for structural conflicts:
     - Two CRs modifying a service that another CR wants to merge/remove
     - New service created by CR-A that CR-B doesn't account for
  6. Classify conflicts:
     - HARD CONFLICT: Cannot coexist without resolution
     - SOFT CONFLICT: Can coexist with coordination
     - DEPENDENCY: Must be sequenced
     - SYNERGY: Changes complement each other
```

#### 3c. Structural Impact Analysis

```
For each STRUCTURAL change request:
  1. Map the current service topology
  2. Map the proposed service topology after this change
  3. Identify:
     - Services being merged → which endpoints consolidate?
     - Services being split → which endpoints move where?
     - New services → what are their boundaries?
     - Services being removed → what happens to their consumers?
  4. Assess ripple effects:
     - Docker compose changes
     - Nginx/routing changes
     - Inter-service communication changes
     - Frontend API client changes
     - Database ownership changes
     - CI/CD pipeline changes
```

**Output**: `analysis/` directory with impact matrices and conflict reports.

### Phase 4: ARB Report Generation

**Goal**: Produce the final ARB decision document.

```
1. Aggregate all impact analyses
2. Build the Change Impact Matrix (services × changes)
3. Build the Conflict Matrix (changes × changes)
4. Build the Structural Change Map (before/after topology)
5. Produce recommended execution waves (sequencing)
6. Identify decision points requiring ARB input
7. Write the ARB Report (see Section 5)
```

**Output**: `ARB-REPORT.md` in the run repository root.

---

## 4. Decision Framework

### Impact Scoring

| Factor | Weight | Scoring |
|--------|--------|---------|
| Services affected | 25% | 1-3: Low, 4-7: Medium, 8+: High |
| Breaking changes | 25% | 0: None, 1-2: Low, 3+: High |
| DB schema changes | 20% | Additive: Low, Modify: Medium, Remove: High |
| Structural changes | 20% | None: 0, Merge/Split: High, New service: Medium |
| Cross-change conflicts | 10% | 0: None, Soft: Low, Hard: High |

### Recommendation Categories

| Category | Criteria | Action |
|----------|----------|--------|
| **APPROVE** | Low impact, no conflicts, clear scope | Proceed to spec refinement |
| **APPROVE WITH CONDITIONS** | Medium impact, soft conflicts | Proceed after conflict resolution |
| **DEFER** | High impact, hard conflicts with approved items | Postpone to next run |
| **REQUIRES DISCUSSION** | Structural changes, architectural decisions | ARB must decide direction |
| **REJECT** | Conflicts with strategic direction, infeasible | Do not proceed |

---

## 5. Output Formats

### Baseline Service Card (`SVC-{name}.md`)

```markdown
# SVC-{name}: {Service Display Name}

## Overview
- **Port**: {port}
- **Framework**: {FastAPI|React|Node.js|...}
- **Status**: {Healthy|Unhealthy|Not Deployed}
- **Repo**: {GitLab path or local path}
- **Docker Container**: {container name}

## API Surface
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/... | ... |

## Database Collections
| Collection | Type | Record Count (approx) |
|------------|------|----------------------|
| {name} | Document|Edge | {count or "unknown"} |

## Dependencies
### Consumes (calls out to)
| Service | Endpoint/Event | Purpose |
|---------|---------------|---------|

### Consumed By (called by)
| Service | Endpoint/Event | Purpose |
|---------|---------------|---------|

## Frontend Routes (if applicable)
| Route | Component | Description |
|-------|-----------|-------------|

## Infrastructure
- Docker Compose: {file and service name}
- Nginx Config: {upstream/location block}
- Environment Variables: {count}
```

### Change Request Card (`CR-{REQ-ID}.md`)

```markdown
# CR-{REQ-ID}: {Title}

## Classification
- **Type**: {FEATURE|ENHANCEMENT|STRUCTURAL|MIGRATION|BUGFIX|INFRASTRUCTURE}
- **Epic**: {Epic N: Name}
- **Priority**: {Critical|High|Medium|Low}
- **Severity of Gap**: {from gap analysis}

## Scope
### Services Affected
| Service | Change Type | Impact |
|---------|------------|--------|
| {name} | Add|Modify|Remove|Merge|Split | {description} |

### Database Changes
| Collection | Action | Details |
|------------|--------|---------|
| {name} | Create|Modify|Remove | {what changes} |

### API Changes
| Service | Endpoint | Action | Breaking? |
|---------|----------|--------|-----------|
| {name} | {path} | Add|Modify|Remove | Yes|No |

### Frontend Changes
| Page/Component | Action | Details |
|----------------|--------|---------|
| {name} | Add|Modify|Remove | {what changes} |

### Structural Changes
{Description of any service merges, splits, new services, removals}

## Dependencies
- **Depends on**: {CR-XX, CR-YY or "None"}
- **Blocks**: {CR-XX, CR-YY or "None"}
- **Conflicts with**: {CR-XX (type: HARD|SOFT) or "None"}

## Metrics
| Metric | Count |
|--------|-------|
| Components | {N} |
| Work Items | {N} |
| Test Cases | {N} |
| New Endpoints | {N} |
| Modified Endpoints | {N} |
| New Collections | {N} |
```

### ARB Report (`ARB-REPORT.md`)

```markdown
# Architecture Review Board Report
**Run**: {runXXX}
**Date**: {date}
**Prepared by**: {agent name}

## Executive Summary
{2-3 paragraphs: total changes, total services affected, key structural decisions needed}

## Baseline Snapshot
| Service | Port | Status | Endpoints | Collections |
|---------|------|--------|-----------|-------------|
| {name} | {port} | {status} | {count} | {count} |

**Total**: {N} services, {N} endpoints, {N} collections

## Change Requests Overview
| CR | Title | Type | Priority | Services | Impact Score |
|----|-------|------|----------|----------|-------------|
| CR-{ID} | {title} | {type} | {priority} | {count} | {Low|Medium|High} |

**Total**: {N} change requests, {N} components, {N} work items

## Change Impact Matrix
{Services (rows) × Change Requests (columns) — cells show: Add/Modify/Remove/None}

| Service | CR-01 | CR-06 | CR-09 | ... |
|---------|-------|-------|-------|-----|
| process-design | Modify | - | - | ... |
| human-task | - | Merge | - | ... |
| frontend | Add | Modify | Modify | ... |

## Conflict Matrix
{Change Requests × Change Requests — cells show conflict type}

| | CR-01 | CR-06 | CR-09 | ... |
|-|-------|-------|-------|-----|
| CR-01 | - | Soft | None | ... |
| CR-06 | Soft | - | None | ... |

## Structural Changes

### Service Topology: Current State
```
{ASCII diagram of current service architecture}
```

### Service Topology: Proposed Target State
```
{ASCII diagram showing merges, splits, new services, removals}
```

### Structural Decision Points
| # | Decision | Options | Recommendation | Affected CRs |
|---|----------|---------|----------------|---------------|
| 1 | {decision needed} | {A, B, C} | {recommended} | CR-XX, CR-YY |

## Database Impact Summary
### New Collections
| Collection | Owner Service | Created By |
|------------|--------------|------------|

### Modified Collections
| Collection | Current Owner | Changes | Affected CRs |
|------------|--------------|---------|---------------|

### Removed Collections
| Collection | Current Owner | Migration Plan | Affected CRs |
|------------|--------------|----------------|---------------|

## Recommended Execution Waves

### Wave 1: {Phase Name}
| CR | Title | Rationale |
|----|-------|-----------|
| CR-{ID} | {title} | {why this goes first} |

### Wave 2: {Phase Name}
| CR | Title | Depends On |
|----|-------|-----------|
| CR-{ID} | {title} | {Wave 1 CRs it depends on} |

{Continue for all waves}

## ARB Decisions Required

### Decision 1: {Title}
- **Context**: {what needs to be decided}
- **Options**:
  - A: {option description} — Impact: {assessment}
  - B: {option description} — Impact: {assessment}
- **Recommendation**: {which option and why}
- **Affected CRs**: {list}

{Repeat for each decision}

## Recommendations Summary

| CR | Recommendation | Conditions | Wave |
|----|---------------|------------|------|
| CR-{ID} | APPROVE|APPROVE WITH CONDITIONS|DEFER|REQUIRES DISCUSSION|REJECT | {conditions if any} | {wave #} |

## Risk Register
| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|------------|
| 1 | {risk description} | Low|Medium|High | Low|Medium|High | {mitigation strategy} |

## Next Steps
1. ARB reviews this document
2. ARB makes decisions on structural decision points
3. Approved CRs proceed to spec refinement (run `/spec-writing` skill)
4. Deferred CRs move to next run
5. New specs are written incorporating ARB decisions
```

---

## 6. Agent Execution Guide

### When Invoked

The agent executing this skill should:

1. **Load context**: Read `flowmaster-overview`, `flowmaster-backend`, `flowmaster-database` skills for service registry
2. **Locate the run repo**: Confirm path exists, read README.md and all requirement files
3. **Collect codebase baseline (Phase 1a)**: Clone/fetch MAIN branches from GitLab for each service — this is the primary baseline
4. **Collect runtime overlay (Phase 1b)**: SSH to dev-01 for container health, nginx config, network state — this supplements the codebase baseline
5. **Collect database baseline (Phase 1c)**: Query ArangoDB, PostgreSQL, Redis for current schema state
6. **Process requirements (Phase 2)**: Read every REQ-XX.md in the run repo
7. **Perform analysis (Phase 3)**: Execute impact analysis as described above
8. **Write output (Phase 4)**: Create the output files in the run repo under `arb/` directory

### Directory Structure Created

```
runXXX/
├── arb/
│   ├── ARB-REPORT.md          ← Main ARB document
│   ├── baseline/
│   │   ├── SVC-process-design.md
│   │   ├── SVC-execution-engine.md
│   │   ├── SVC-human-task.md
│   │   ├── ... (one per service)
│   │   ├── DB-ARANGODB.md     ← ArangoDB schema baseline
│   │   ├── DB-POSTGRESQL.md   ← PostgreSQL schema baseline
│   │   ├── DB-REDIS.md        ← Redis state baseline
│   │   └── RUNTIME-ISSUES.md  ← Cross-cutting infra concerns from dev-01
│   ├── changes/
│   │   ├── CR-REQ-01.md
│   │   ├── CR-REQ-06.md
│   │   └── ... (one per requirement)
│   └── analysis/
│       ├── impact-matrix.md
│       ├── conflict-matrix.md
│       ├── structural-changes.md
│       └── database-impact.md ← Database-specific impact analysis
├── requirements/               ← Existing (unchanged)
├── existing-specs/             ← Existing (unchanged)
├── specs/                      ← Empty (populated after ARB)
└── work-items/                 ← Empty (populated after ARB)
```

### Parallelization Strategy

- **Phase 1a** (Codebase): Spawn one sub-agent per service to clone GL MAIN and extract baseline (parallel)
- **Phase 1b** (Runtime): Single agent SSHs to dev-01 for container/nginx/network state (parallel with 1a)
- **Phase 1c** (Database): Single agent queries ArangoDB + PostgreSQL + Redis for schema state (parallel with 1a)
- **Phase 2**: Spawn one sub-agent per epic for change request inventory (parallel, can start during Phase 1)
- **Phase 3**: Sequential — requires Phase 1 + 2 outputs
- **Phase 4**: Sequential — requires Phase 3 output

### Key Rules

1. **Never modify the run repo's requirements** — they are the source of truth
2. **All output goes into `arb/` directory** — keep it separate from specs
3. **Flag unknowns explicitly** — if baseline data is missing, say so (don't guess)
4. **Cross-reference by ID** — use CR-{REQ-ID} and SVC-{name} consistently
5. **Structural changes get special attention** — service merges/splits are the highest-risk items
6. **The ARB report is for humans** — write clearly, use tables, avoid jargon
7. **Include the "do nothing" option** — for every structural decision, include the option of keeping current state

---

## 7. FlowMaster Context

### Current Service Registry (as of 2026-02)

| Service | Port | Status |
|---------|------|--------|
| API Gateway | 9000 | Healthy |
| Auth Service | 9001 | Healthy |
| Process Design | 9003 | Unhealthy |
| Execution Engine | 9005 | Unhealthy |
| Human Task | 9006 | Healthy |
| Communication | 9011 | Healthy |
| Audit & Compliance | 9012 | Healthy |
| Process Analytics | 9014 | Unhealthy |
| Service Registry | 9020 | Healthy |
| Process Linking | 8021 | Healthy |
| Process Versioning | 8020 | Starting |
| Process Views | 8019 | Starting |
| Rules Engine | 8018 | Unhealthy |
| Legal Entity | 8014 | Unhealthy |
| Prompt Engineering | 8022 | Unhealthy |
| External Integration | 9024 | Unhealthy |
| WebSocket Gateway | 9010 | Unhealthy |
| Document Intelligence | 9002 | Healthy |
| Frontend (Next.js) | 3000 | Healthy |

### Known Structural Changes in run001

Based on requirements already collected:
- **REQ-06**: Merge Engage and Human Tasks into unified model
- **REQ-07**: Merge Settings into FlowMaster (absorb standalone service)
- **REQ-08**: Merge Case Management into FlowMaster
- **REQ-15**: Replace Process Manager with enhanced Process Design
- **REQ-16-17-18**: Consolidate Process Views, Versioning, Linking into Process Design

These structural changes are the primary drivers for the ARB process.

### Run001 Repository

- **Location**: `~/run001`
- **GitLab**: `git@gitlab.com:flow-master/run001.git`
- **Structure**: 53 requirements across 8 epics
- **Epics**: Integrations, Architecture, Process Management, UX/Frontend, Data & Legacy, Agents & Org, Infrastructure, Gaps from Code Review (REQ-91 to REQ-102)

---

## 8. Integration with Other Skills

| Skill | Relationship |
|-------|-------------|
| `spec-writing` | ARB output feeds into spec writing — approved CRs get full specs |
| `flowmaster-overview` | Provides service registry and architecture context |
| `flowmaster-backend` | Provides detailed service API contracts for baseline |
| `flowmaster-database` | Provides collection schemas for baseline |
| `flowmaster-frontend` | Provides frontend route/component inventory for baseline |
| `build-method` | ARB is the [CHECK] gate before [BUILD] phase |
| `new-project-playbook` | If ARB creates new services, use this for setup |
