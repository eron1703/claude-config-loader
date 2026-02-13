---
name: spec-writing
description: Methodology for writing FlowMaster requirement specifications and self-contained sub-component work items. Produces consistent, agent-buildable specs following the REQ-XX format.
disable-model-invocation: false
---

# FlowMaster Specification Writing Methodology

You are writing requirement specifications for FlowMaster, a process management platform. Every specification you produce must follow the exact structure and conventions documented below. The output must be buildable by a basic agent (Haiku-level) from the spec alone — no external context, no "see also" references, no implicit knowledge.

> **Format Note**: This Markdown specification format is the canonical expansion of the build-method YAML schema. Every field in the build-method's `sub-component spec` YAML maps 1:1 to a section here. When in doubt, this document is authoritative for structure and completeness.

> **Requirements Repo Pattern**: All specs are stored in a dedicated GitLab requirements repo per run (e.g., `run001`). Each developer creates their own branch for their requirements, which are merged centrally. This skill defines the **standardized output format** — every spec from every developer must follow the exact structure below. The build-method's `[COLLECT]` phase gathers all requirements before any spec work begins here.

---

## 1. Requirement Document Structure (REQ-XX.md)

Every requirement file follows this exact section order:

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
{For each collection:}

#### `collection_name` (Document Collection | Edge Collection)
```json
{
  "_key": "prefix_<uuid>",
  "_id": "collection_name/prefix_<uuid>",
  // For edge collections:
  "_from": "source_collection/id",
  "_to": "target_collection/id",
  "field_name": "type and example value",
  "nested_object": {
    "sub_field": "type"
  },
  "created_at": "2026-02-13T10:00:00Z"
}
```

#### Indexes
```javascript
db.collection_name.ensureIndex({
  type: "persistent",
  fields: ["field1", "field2"],
  unique: true|false,
  sparse: true|false,
  name: "idx_descriptive_name"
});
```

### Components
{Summary table:}
| # | Component | Service | Purpose |
|---|-----------|---------|---------|

### Sub-Components
{One section per component — see Section 2 below}

## Work Items
{Table or numbered list — see Section 3 below}

## Test Plan
{Organized by test type — see Section 6 below}
```

---

## 2. Sub-Component Specification Format

Every sub-component within a REQ must have ALL of the following fields. No field may be omitted.

```markdown
#### SC-{REQ}-{number}: {Component Name}
  OR
#### C{number}: {Component Name}

- **Name**: `PascalCase` or `kebab-case` identifier
- **Purpose**: {Single sentence — what this component does}
- **Service**: {Exact service name and port, e.g., "FlowMaster Backend (Port 8002)" or "Frontend (React)"}

**Inputs**:
| Name | Type | Source |
|------|------|--------|
| {name} | {TypeScript type or Python type} | {Which component/event provides it} |

**Outputs**:
| Name | Type | Consumed By |
|------|------|-------------|
| {name} | {TypeScript type or Python type} | {Which component(s) consume it} |

**Contract**:
```
{For backend components: Full API contract}
{For frontend components: Props interface + internal state interface}
{For internal services: Class/method signatures}
```

**Authorization**: {Who can call this component}
Values: `"authenticated user"` | `"role:admin"` | `"role:manager"` | `"service-to-service"` | `"public"` | custom role string
{For REST endpoints: maps to middleware/decorator. For internal services: maps to caller validation.}

**Logic Steps**:
1. {Imperative verb} {what happens}
2. {Imperative verb} {what happens}
...

**Test Cases**:
| ID | Test | Expected | Type |
|----|------|----------|------|
| T-{REQ}-{component}-{number} | {Scenario description} | {Expected outcome} | {Unit|Integration|E2E|Playwright|Static|Performance} |
```

### API Contract Requirements (Backend Components)

When a component exposes a REST endpoint, the contract must include:

```markdown
**Contract**:
{HTTP_METHOD} {full_endpoint_path}
Request:
{
  "field": "type",
  ...
}
Response {status_code}:
{
  "field": "type",
  ...
}
Errors:
  {status_code}: {description}
  {status_code}: {description}
```

Required elements:
- Full endpoint path with HTTP method (e.g., `POST /api/v1/agents/{agent_id}/assignment`)
- Request body schema as JSON with field types
- Response body schema as JSON with field types
- Error response codes with descriptions (400, 401, 403, 404, 408, 409, 500, 502 as applicable)
- Query parameters for list endpoints: pagination (`page`, `page_size`), filtering, sorting

### Frontend Component Contracts

```typescript
interface ComponentNameProps {
  // All props with types, defaults noted in comments
  propName: type;         // description, default value if any
  onEvent: (args) => void;
}

// Internal state (if complex)
interface ComponentNameState {
  field: type;
}

// API calls this component makes
// GET /api/v1/resource?params
// POST /api/v1/resource
```

### Internal Service Contracts (No REST Endpoint)

```python
class ServiceClassName:
    def method_name(
        self,
        param: Type,
        ...
    ) -> ReturnType:
        ...

# ReturnType definition:
{
  "field": "type",
  ...
}
```

### Async/Event Contract Template (Redis Pub/Sub)

When a component publishes or subscribes to events, the contract must include an event specification:

```markdown
**Event Contract**:
Event Name: {descriptive.event.name}  (e.g., "agent.assignment.created")
Channel: {redis_channel_name}          (e.g., "flowmaster:agents")
Direction: publish | subscribe | both
Publisher Service: {Service name and port}
Payload Schema:
{
  "event": "agent.assignment.created",
  "timestamp": "ISO8601",
  "correlation_id": "string (uuid)",
  "payload": {
    "field": "type",
    ...
  }
}
Subscriber Services:
  - {Service name (port)}: {What it does when it receives this event}
  - {Service name (port)}: {What it does when it receives this event}
Retry Policy: {at-least-once | at-most-once | exactly-once}
Dead Letter: {channel or handling strategy for failed processing}
```

Required elements:
- Event name using dot notation (e.g., `agent.assignment.created`, `process.node.completed`)
- Redis channel name (e.g., `flowmaster:agents`, `flowmaster:processes`)
- Full payload schema as JSON with field types
- All subscriber services listed with their reaction to the event
- Retry and dead letter policies for reliability

### Observability Requirements (Backend Components)

For backend components (REST endpoints, internal services, event handlers), include an optional observability section when the component has significant operational concerns:

```markdown
**Observability**:
Key Log Events:
  - {level}: {event description} (e.g., "INFO: Assignment created for agent {agent_id} by user {user_id}")
  - {level}: {event description}
Metrics:
  - {counter|histogram|gauge}: {metric_name} — {description}
    (e.g., "counter: agent_assignments_total — Total assignment operations by type")
    (e.g., "histogram: assignment_duration_seconds — Time to complete assignment operation")
Correlation: {How correlation_id propagates — e.g., "From request header X-Correlation-ID, passed to all downstream calls and events"}
```

---

## 3. Self-Contained Work Items

Each work item must be independently buildable. An agent reading only the work item and its parent REQ must be able to implement it without referencing any other document.

### Work Item Table Format

```markdown
| ID | Title | Priority | Dependencies |
|----|-------|----------|--------------|
| WI-{REQ}-{number} | {Descriptive title} | P0/P1/P2 | {WI-XX-YY or "None"} |
```

### Work Item Detail Format (When Expanded)

```markdown
### WI-{REQ}-{number}: {Title}
{1-3 sentences describing what to build.}
- Input: {What codebase/service to modify, port number}
- Output: {What the deliverable is — endpoint, component, migration, tests}
- Dependencies: {Explicit WI IDs this depends on, or "None"}
- Authorization: {Who can access — "authenticated user", "role:admin", "service-to-service", "public"}
```

### Infrastructure Requirements (Optional — for new services or significant infra changes)

When a work item introduces a new service, new database collection, or infrastructure change, include:

```markdown
**Infrastructure**:
- Environment Variables: {VAR_NAME=description, VAR_NAME=description}
- Docker Port Mapping: {host_port:container_port}
- Health Check Endpoint: {GET /health — expected response}
- CI/CD Stages: {lint, test, build, deploy — any special steps}
- New Collections/Indexes: {list any DB setup required before this WI runs}
```

### Plane Work Item Mapping

**Each work item = 1 Plane issue.** The supervisor creates Plane issues from work items before spawning agents. Agents check out Plane issues, not raw specs.

**WI → Plane Issue Mapping**:

| WI Field | Plane Field | Notes |
|----------|-------------|-------|
| `WI-{REQ}-{number}` | Issue identifier / title prefix | Used as branch name: `wi-{req}-{number}` |
| Title | Issue title | Format: `WI-{REQ}-{N}: {Title}` |
| Description (1-3 sentences) | Issue description | Full WI detail block pasted in |
| Priority (P0/P1/P2) | Priority | P0=Urgent, P1=High, P2=Medium |
| Dependencies | Blocked-by links | Link to dependency Plane issues |
| Service | Label | e.g., `service:agent-service`, `service:frontend` |
| Type (endpoint/component/migration) | Label | e.g., `type:api`, `type:frontend`, `type:migration` |
| REQ parent | Module/Epic | Maps to Plane module or epic grouping |

**Plane CLI Reference** (for supervisor agent creating issues):
```bash
# Create issue from work item
plane issues create \
  --title "WI-28-01: Agent Document Collection & Indexes" \
  --description "$(cat wi-28-01.md)" \
  --priority "high" \
  --label "service:agent-service" \
  --label "type:api"

# Link dependency
plane issues link {issue_id} --blocks {dependent_issue_id}

# Assign to agent
plane issues update {issue_id} --assignee {agent_id} --state "in_progress"
```

### Self-Containment Rules

- **FORBIDDEN**: "See REQ-XX", "as described in", "refer to", "see also"
- **REQUIRED**: Every work item states which service/codebase it belongs to
- **REQUIRED**: Every work item states its inputs (what it reads/receives) and outputs (what it produces)
- **REQUIRED**: Dependencies are listed as explicit work item IDs (e.g., "WI-28-01")
- **REQUIRED**: If a work item depends on another work item's output, describe what that output is (e.g., "Uses the `agents` collection created in WI-28-01")

---

## 4. Data Model Requirements

### ArangoDB Document Collections

```json
{
  "_key": "prefix_<uuid>",
  "_id": "collection_name/prefix_<uuid>",
  "string_field": "example value",
  "enum_field": "value_a | value_b | value_c",
  "integer_field": 42,
  "float_field": 0.85,
  "boolean_field": true,
  "datetime_field": "2026-02-13T10:00:00Z",
  "nullable_field": null,
  "nested_object": {
    "sub_field": "type"
  },
  "array_field": ["item1", "item2"],
  "created_at": "2026-02-13T10:00:00Z",
  "updated_at": "2026-02-13T10:00:00Z",
  "created_by": "users/user_<uuid>"
}
```

### ArangoDB Edge Collections

```json
{
  "_key": "prefix_<uuid>",
  "_from": "source_collection/source_<uuid>",
  "_to": "target_collection/target_<uuid>",
  "relationship_type": "string",
  "status": "active | revoked",
  "created_at": "2026-02-13T10:00:00Z"
}
```

Constraints must be documented with:
- Which field combinations must be unique
- Whether enforced by index, application layer, or both
- Index definition in JavaScript syntax

### TypeScript Interfaces (Frontend)

```typescript
interface EntityName {
  id: string;
  name: string;                          // 1-200 chars
  description: string | null;            // up to 2000 chars
  status: 'active' | 'paused' | 'disabled';
  configuration: Record<string, unknown>;
  createdAt: string;                     // ISO8601
  updatedAt: string;                     // ISO8601
}
```

### Pydantic Models (Backend)

```python
class EntityCreateRequest(BaseModel):
    name: str                            # 1-200 chars
    description: str | None = None       # up to 2000 chars
    type: str = "default"                # enum values listed
    configuration: dict = {}

class EntityResponse(BaseModel):
    id: str
    name: str
    description: str | None
    type: str
    status: str                          # active, paused, disabled
    created_at: datetime
    updated_at: datetime
```

---

## 5. Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Requirement file | `REQ-{number}.md` | `REQ-01.md`, `REQ-28.md` |
| Combined requirements | `REQ-{N1}-{N2}-{N3}.md` | `REQ-16-17-18.md` |
| Sub-component ID | `SC-{REQ}-{number}` | `SC-09-01`, `SC-28-03` |
| Alternative component ID | `C{number}` | `C1`, `C10` |
| Work item ID | `WI-{REQ}-{number}` | `WI-09-01`, `WI-28-12` |
| Test case ID | `TC-{REQ}-{number}` | `TC-28-01`, `TC-39-31` |
| Alternative test ID | `T-{REQ}-{component}-{number}` | `T-09-01-01`, `T-09-04-07` |
| ArangoDB collection | `snake_case` | `agent_assignments`, `vault_credentials` |
| ArangoDB index | `idx_{descriptive_name}` | `idx_unique_active_manager` |
| API endpoint | `/api/v1/{resource}` or `/api/v2/{resource}` | `/api/v1/agents/{agent_id}/assignment` |
| Frontend component | `PascalCase` | `AgentListPage`, `DenseSplitView` |
| Backend class | `PascalCase` | `ExecutionSchemaValidator` |
| CSS token | `--fm-{category}-{name}` | `--fm-space-md`, `--fm-table-row-height` |

---

## 6. Test Plan Requirements

### Test Case Table Format

Every sub-component must have test cases in this format:

```markdown
| ID | Test | Expected | Type |
|----|------|----------|------|
| TC-{REQ}-{number} | {What is being tested} | {Expected outcome} | {Type} |
```

OR the alternative format:

```markdown
| ID | Type | Description | Pass Criteria |
|----|------|-------------|---------------|
| TC-{REQ}-{number} | {Type} | {Description} | {What constitutes pass} |
```

OR for sub-component-scoped tests:

```markdown
| # | Input | Expected Output |
|---|-------|-----------------|
| T{N} | {Input description} | {Expected output description} |
```

### Test Types

- **Unit**: Isolated function/method tests, mock external dependencies
- **Integration**: Tests spanning multiple components or services
- **E2E**: Full user journey tests across frontend and backend
- **Playwright**: Browser-based visual/interaction tests
- **Static**: Lint rules, type checks, AST analysis
- **Performance**: Load, response time, throughput tests
- **Security**: Authorization, encryption, audit trail tests

### Required Test Coverage

1. **Happy path**: Normal successful operation
2. **Validation errors**: Invalid inputs (400/422)
3. **Authorization failures**: Unauthorized access (403)
4. **Not found**: Missing resources (404)
5. **Conflict states**: Duplicate operations, race conditions (409)
6. **External failures**: Upstream service unavailable (502/408)
7. **Edge cases**: Empty lists, null values, boundary conditions

### Test Plan Section Structure

```markdown
## Test Plan

### Unit Tests
- {Bullet list of what unit tests cover}

### Integration Tests
- {Bullet list of cross-component test scenarios}

### E2E Tests
- {Full user journey descriptions, numbered steps with **Verify** callouts}

### Acceptance Criteria
1. {Numbered list of conditions that must be true for the requirement to be complete}
2. ...
```

### User Journey Test Format

```markdown
### User Journey {N}: {Title}
**Scenario**: {One-line context}

1. User {action}
2. **Verify**: {What the system should do}
3. User {action}
4. **Verify**: {What the system should do}
...
```

### test-rig Integration (TDD Pipeline)

Every spec feeds directly into the test-rig TDD pipeline. The agent workflow is:

```
Read spec → test-rig generate → write tests → RED → Implement → GREEN → Refactor
```

**Test case tables are test-rig input.** The test case table in each sub-component is consumed by `test-rig generate` to scaffold test files. The format must be machine-parseable:

```markdown
| ID | Test | Expected | Type |
|----|------|----------|------|
| T-28-01-01 | Assign agent to manager | Assignment created, edge stored | Unit |
| T-28-01-02 | Assign already-assigned agent | 409 Conflict returned | Unit |
| T-28-01-03 | Assign with invalid user_id | 404 Not Found returned | Unit |
```

**Mapping to test-rig generate**:
- **ID** → test function name: `test_t_28_01_01_assign_agent_to_manager`
- **Test** → test description / docstring
- **Expected** → assertion target
- **Type** → test-rig framework selection: `Unit` → Vitest/Pytest, `Integration` → Testcontainers, `E2E`/`Playwright` → Playwright

**test-rig CLI commands used by agents**:
```bash
# Generate test scaffold from spec's test case table
test-rig generate --spec WI-28-01 --framework pytest --output tests/

# Run tests (expect RED — no implementation yet)
test-rig run --filter "WI-28-01" --headless --yes

# After implementation, run again (expect GREEN)
test-rig run --filter "WI-28-01" --headless --yes

# Check coverage
test-rig coverage --filter "WI-28-01" --threshold 80

# Run integration tests after all components built
test-rig run integration --parallel --headless --yes
```

**Agent TDD Workflow** (per work item):
1. Agent checks out Plane issue for `WI-{REQ}-{N}`
2. Agent reads the spec (self-contained, no other context needed)
3. `test-rig generate` creates test files from the test case table
4. `test-rig run` — all tests fail (RED confirms tests are valid)
5. Agent implements the component following Logic Steps and Contract
6. `test-rig run` — all tests pass (GREEN confirms implementation)
7. Agent refactors if needed, re-runs tests to confirm still GREEN
8. `test-rig coverage` — confirms coverage threshold met
9. Agent reports done with evidence (test output, coverage report)

---

## 7. SUMMARY.md Structure

Each epic directory must contain a `SUMMARY.md` file:

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
  |
  +---> REQ-{C} ({Title}) -- {relationship description}
```

## Recommended Execution Order

### Wave 1: {Phase Name}
1. **REQ-{N}**: {Why this goes first, what it unblocks}

### Wave 2: {Phase Name}
2. **REQ-{N}**: {What this depends on, what it builds}
...

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

### API Versioning
{Which API version prefix, deprecation policy}

### Authentication and Authorization
{Required auth model, permission patterns}

### ArangoDB Collections (New or Modified)

| Collection | REQ | Purpose |
|------------|-----|---------|
| {name} | REQ-{N} | {purpose} |

### Frontend Navigation Changes
**Remove**: {list}
**Add**: {list}
**Redirect**: {list}

### Integration Points

| From | To | Integration |
|------|-----|-------------|
| {Service/REQ} | {Service/REQ} | {How they connect} |

## Aggregate Statistics

| Metric | REQ-{A} | REQ-{B} | ... | Total |
|--------|---------|---------|-----|-------|
| Components | {N} | {N} | ... | {N} |
| Work items | {N} | {N} | ... | {N} |
| Test cases | {N} | {N} | ... | {N} |

**Services modified**:
- {Service name} ({port}): {N} work items
```

---

## 8. Platform Context (FlowMaster)

When writing specs, use these platform facts:

| Aspect | Value |
|--------|-------|
| Backend framework | FastAPI (Python 3.11+) |
| Database | ArangoDB (document + edge collections) |
| Frontend framework | React + TypeScript |
| Dev server IP | 65.21.153.235 |
| Inter-service communication | REST APIs + Redis pub/sub |

### Known Services and Ports

| Service | Port |
|---------|------|
| FlowMaster Frontend | 3000 |
| Engage Frontend | 3010 |
| FlowMaster Backend | 8002 |
| DXG Backend | 8005 |
| SDX Backend | 8010 |
| SDX MCP Server | 8011 |
| Process Design Service | 9003 |
| AI Agent Orchestration | 9007 |
| Agent Service | 8000 |

Always specify the service name AND port when assigning a component to a service.

---

## 9. Decomposition Methodology

Follow this decomposition chain and stop at the STOP checkpoint:

```
Requirement (REQ-XX)
  -> Current State Analysis
  -> Gap Analysis
  -> Architecture Design (diagrams, data models)
  -> Components (high-level list)
  -> Sub-Component Specs (contract + authorization + logic + tests per component)
  -> Event Contracts (for any async/pub-sub communication)
  -> Work Items (self-contained, agent-buildable, Plane-mappable)
  -> Infrastructure Requirements (for new services/collections)
  -> Test Plan (unit, integration, E2E, acceptance criteria)
  -> STOP CHECKPOINT (Quality Checklist — every item must pass)
  -> Only then: Create Plane issues -> Spawn agents -> Build
```

### Rules

1. **Each sub-component spec must be self-contained** — an agent reading only that spec section can build the component
2. **No context sharing between specs** — each stands alone with all needed information inline
3. **Contracts define ALL boundaries** — REST, event/pub-sub, auth — nothing is implicit; every input, output, error, and event is specified
4. **Every component has an Authorization field** — agents must know who can call what
5. **Frontend components must include**: Props interface, internal state interface, API calls made, layout description or ASCII wireframe
6. **Backend components must include**: Full API contract (endpoint, method, request/response schemas, error codes) OR class/method signature for internal services. If the component publishes or subscribes to events, include an Event Contract.
7. **Every component has test cases** — no component without at least 3 test cases, in test-rig-consumable table format
8. **Work items reference component specs** but repeat enough context to be buildable alone
9. **Dependencies are always explicit** — work item IDs, not prose descriptions
10. **Each work item = 1 Plane issue** — the mapping is direct, not approximate

### Quality Checklist

Before finalizing any REQ document, verify:

- [ ] Every component has a Name, Purpose, Service assignment
- [ ] Every component has Inputs (with source) and Outputs (with consumer)
- [ ] Every component has a Contract (API, interface, or event contract)
- [ ] Every component has an Authorization field
- [ ] Every component has numbered Logic Steps
- [ ] Every component has a Test Cases table (machine-parseable for test-rig)
- [ ] Every work item has explicit dependencies or "None"
- [ ] Every work item states its service/codebase
- [ ] Every work item maps to exactly one Plane issue
- [ ] No "see also" or cross-references to other REQ documents
- [ ] All data models show field types, constraints, and collection names
- [ ] All API endpoints show request schema, response schema, and error codes
- [ ] All event-driven interactions have an Event Contract (channel, payload, subscribers)
- [ ] Test plan includes unit, integration, and E2E sections
- [ ] Acceptance criteria are numbered at the end of the test plan
- [ ] Architecture diagram is present (ASCII art)
- [ ] Gap analysis table is present with severity ratings
- [ ] Infrastructure section present for any new services or collections
- [ ] Observability section present for backend components with significant operational concerns
- [ ] Every frontend requirement has a complete user journey with steps table
- [ ] Every user journey has verification checkpoints with evidence types
- [ ] Every screen has loading, empty, populated, and error states defined
- [ ] Every error has an exact user-visible message specified

### STOP Checkpoint

```
╔══════════════════════════════════════════════════════════════════╗
║  STOP. DO NOT PROCEED PAST THIS POINT.                          ║
║                                                                  ║
║  Do NOT:                                                         ║
║  - Spawn build agents                                            ║
║  - Create Plane issues                                           ║
║  - Write any implementation code                                 ║
║  - Start any build pipeline                                      ║
║                                                                  ║
║  UNTIL every single item in the Quality Checklist above passes.  ║
║  Re-read every sub-component spec. Re-check every contract.      ║
║  If ANY item fails, fix it FIRST.                                ║
║                                                                  ║
║  A spec with gaps = an agent that asks questions = a broken build ║
╚══════════════════════════════════════════════════════════════════╝
```

The decomposition chain ends at test cases. After test cases, the only valid next action is: **review the entire spec against the Quality Checklist**. Only when every checkbox passes may you proceed to creating Plane issues and spawning agents.

---

## 10. Output Document Standards

This section defines the exact shape of finished spec documents. Every spec must match these templates. The purpose is outcome-focused: a spec is only valid if an agent can build from it without asking a single question.

### A. Requirement Spec Document Template

Every REQ document must follow this structure. Sections may be expanded but never omitted.

```markdown
# REQ-XX: [Title]

## 1. User Story
As a [role], I want to [action] so that [outcome].

## 2. User Journey
### Happy Path
1. User navigates to [screen]
2. User sees [what exactly — layout, elements, data]
3. User clicks/enters [action]
4. System responds with [exact response]
5. User sees [final state]

### Error Paths
1. [Error scenario] → User sees [exact error message/state]

### Edge Cases
1. [Edge case] → System handles by [exact behavior]

## 3. Screen Specifications
[For each screen in the journey]
### Screen: [Name]
- **URL**: /path/to/screen
- **Layout**: [Describe grid/flex structure, responsive behavior]
- **Elements**: [Every interactive element with ID, type, label, behavior]
- **States**: [Loading, empty, populated, error, disabled]
- **Data Sources**: [Which API endpoints populate which elements]

## 4. Sub-Components
[Full sub-component specs as per Section 2 format]

## 5. Acceptance Criteria (Definition of Done)
### Functional
- [ ] [Specific testable criterion]
### Visual
- [ ] Screenshot matches design at 1920x1080
- [ ] Screenshot matches design at 375x812 (mobile)
- [ ] No console errors
- [ ] No console warnings
### Performance
- [ ] Page loads in <3s on 3G
- [ ] API responses <200ms
### Accessibility
- [ ] WCAG 2.1 AA compliance
- [ ] Keyboard navigation works
- [ ] Screen reader compatible

## 6. Verification Protocol
[How to prove this requirement is DONE — see Verification Protocol Template below]
```

### B. User Journey Template

Every frontend requirement MUST include a user journey in this exact format. This is the most critical section — it defines the end outcome from the user's perspective.

```markdown
### User Journey: [Journey Name]

**Actor**: [Role — admin, manager, employee, etc.]
**Goal**: [What the user is trying to accomplish]
**Preconditions**: [What must be true before starting]

#### Steps
| Step | User Action | System Response | Screen State | Evidence |
|------|------------|-----------------|--------------|----------|
| 1 | Navigate to /path | Page loads | [Describe what user sees] | Screenshot required |
| 2 | Click [element] | [API call triggered] | [New state] | Console log: no errors |
| 3 | Enter [data] | [Validation] | [Feedback shown] | |
| 4 | Submit | [Backend processing] | [Success/confirmation] | Screenshot + API response |

#### Verification Checkpoints
At each step, the tester must capture:
- Screenshot (headless Puppeteer)
- Browser console logs (zero errors)
- Network requests (correct API calls)
- Docker logs (if containers involved)
- Rating (1-10 for visual quality)
```

### C. Verification Protocol Template

Every spec must define EXACTLY how completion is proven. This ties directly into evidence-based verification requirements.

```markdown
### Verification Protocol

**For Frontend Components:**
1. Launch headless Puppeteer
2. Navigate to the screen
3. Execute the user journey steps
4. At each checkpoint:
   - Take screenshot → save to /evidence/REQ-XX/step-N.png
   - Capture console logs → zero errors expected
   - Capture network requests → verify correct API calls
   - Rate screenshot quality (1-10)
5. Execute error paths and verify error states
6. Test responsive: 1920x1080, 1366x768, 375x812
7. Final evidence package: screenshots + console logs + ratings

**For Backend Components:**
1. Execute API calls with curl/httpie
2. Verify response status codes
3. Verify response body matches contract schema
4. Check application logs for errors
5. Verify database state changes
6. Test error scenarios (400, 401, 403, 404, 500)
7. Final evidence package: request/response logs + db queries

**For Integration:**
1. Execute full user journey end-to-end
2. Verify data flows from frontend → backend → database → response
3. Screenshot of final state
4. Docker logs showing healthy services
5. Performance metrics (load time, API response times)
```

---

## 11. Detail Level Requirements

This section defines the minimum level of detail required. If a spec lacks any of these, it is incomplete and must not proceed to implementation.

### Frontend Specs Must Include:
- Every screen with URL, layout grid, and responsive breakpoints
- Every interactive element (buttons, inputs, dropdowns) with exact labels and behavior
- Every state (loading spinner, empty state, error state, success state)
- Exact error messages (not "show error" but `Display red toast: 'Failed to save process. Please try again.'`)
- CSS tokens/design system references where applicable
- Keyboard navigation flow (Tab order, Enter/Escape behavior)
- Mobile-specific behavior (touch targets, swipe gestures, collapsed menus)

### Backend Specs Must Include:
- Full request/response schemas with field types and validation rules
- Every error code with exact error response body
- Database queries (which collections, which indexes, which fields)
- Event emissions (what events are published, with exact payload)
- Authorization check (who can call, what happens on 403)

### The Spec Must Answer These Questions Without Ambiguity:
1. What does the user SEE at every step?
2. What happens when the user does X? (for every X)
3. What does the API return for every possible input?
4. What error does the user see for every failure mode?
5. How do I PROVE this works? (evidence protocol)

### If An Agent Has To Ask "What Should I Do When..." — The Spec Is Broken.

This is the ultimate litmus test. A complete spec eliminates all questions. If an implementing agent encounters any ambiguity — a missing error message, an undefined screen state, an unspecified API response — the spec has failed its purpose and must be revised before work begins.

---

## 12. Forbidden Patterns

These anti-patterns are explicitly prohibited. If any of these appear in a spec, the spec is broken and must be fixed before proceeding.

| Anti-Pattern | Why It Breaks the Build |
|---|---|
| Spec referencing another spec ("See REQ-12 for details") | Agent cannot access other specs — zero context sharing rule violated |
| Implicit contract ("Uses the standard auth flow") | Agent doesn't know what "standard" means — contracts must be explicit |
| Component without test cases | test-rig cannot generate tests — TDD pipeline breaks at step 1 |
| Component without Authorization field | Agent doesn't know who can call it — security holes in implementation |
| Work item without service/port assignment | Agent doesn't know where to put the code |
| Event-driven communication without Event Contract | Subscriber agents don't know what payload to expect |
| Skipping the STOP checkpoint | Broken specs produce broken code at scale — 3-12 agents all building wrong |
| "TBD" or "TODO" in any contract field | Agent will implement a stub or skip it — incomplete spec = incomplete build |
| Test case without Expected outcome | test-rig cannot generate assertions — test is useless |
| Work item depending on prose ("after the auth system is ready") | Dependencies must be explicit WI IDs, not prose descriptions |
| Vague screen descriptions ("show a form") without element details | Agent doesn't know what elements to render, what labels to use, or what layout to apply |
| Missing error messages ("display error") without exact text | Agent invents error copy or skips it — inconsistent UX across the application |
| Frontend specs without user journey | Agent has no outcome definition — builds components in isolation without understanding the flow |

---

## 13. Common Patterns

### Pagination Response Pattern

```python
class PaginatedResponse(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    page_size: int
    has_next: bool
```

Query params: `?page=1&page_size=20&sort_by=created_at&sort_order=desc`

### Audit Log Pattern

```json
{
  "_key": "audit_<uuid>",
  "entity_type": "credential | agent | setting",
  "entity_id": "string",
  "action": "created | updated | deleted | accessed",
  "actor_type": "user | service",
  "actor_id": "string",
  "ip_address": "string",
  "timestamp": "2026-02-13T10:00:00Z",
  "details": {}
}
```

### Error Response Pattern

```json
{
  "detail": "Human-readable error message",
  "error_code": "MACHINE_READABLE_CODE",
  "field_errors": [
    { "field": "name", "message": "Field is required" }
  ]
}
```

### Soft Delete Pattern

Never hard-delete records. Use `status: "disabled" | "revoked" | "archived"` with `deleted_at` and `deleted_by` timestamps.

### Edge Collection Constraint Pattern

For 1:1 relationships enforced at the application layer:
1. Document the constraint in prose
2. Create a unique index on `(_from, relationship_type, status)` where status = "active"
3. Use ArangoDB transactions for atomic revoke-and-create operations
