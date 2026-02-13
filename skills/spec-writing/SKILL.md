---
name: spec-writing
description: Methodology for writing FlowMaster requirement specifications and self-contained sub-component work items. Produces consistent, agent-buildable specs following the REQ-XX format.
disable-model-invocation: false
---

# FlowMaster Specification Writing Methodology

You are writing requirement specifications for FlowMaster, a process management platform. Every specification you produce must follow the exact structure and conventions documented below. The output must be buildable by a basic agent (Haiku-level) from the spec alone — no external context, no "see also" references, no implicit knowledge.

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

Follow this decomposition chain and stop at test cases:

```
Requirement (REQ-XX)
  -> Current State Analysis
  -> Gap Analysis
  -> Architecture Design (diagrams, data models)
  -> Components (high-level list)
  -> Sub-Component Specs (full contract, logic, tests per component)
  -> Work Items (self-contained, agent-buildable)
  -> Test Plan (unit, integration, E2E, acceptance criteria)
  -> STOP
```

### Rules

1. **Each sub-component spec must be self-contained** — an agent reading only that spec section can build the component
2. **No context sharing between specs** — each stands alone with all needed information inline
3. **Contracts define all boundaries** — nothing is implicit; every input, output, and error is specified
4. **Frontend components must include**: Props interface, internal state interface, API calls made, layout description or ASCII wireframe
5. **Backend components must include**: Full API contract (endpoint, method, request/response schemas, error codes) OR class/method signature for internal services
6. **Every component has test cases** — no component without at least 3 test cases
7. **Work items reference component specs** but repeat enough context to be buildable alone
8. **Dependencies are always explicit** — work item IDs, not prose descriptions

### Quality Checklist

Before finalizing any REQ document, verify:

- [ ] Every component has a Name, Purpose, Service assignment
- [ ] Every component has Inputs (with source) and Outputs (with consumer)
- [ ] Every component has a Contract (API or interface)
- [ ] Every component has numbered Logic Steps
- [ ] Every component has a Test Cases table
- [ ] Every work item has explicit dependencies or "None"
- [ ] Every work item states its service/codebase
- [ ] No "see also" or cross-references to other REQ documents
- [ ] All data models show field types, constraints, and collection names
- [ ] All API endpoints show request schema, response schema, and error codes
- [ ] Test plan includes unit, integration, and E2E sections
- [ ] Acceptance criteria are numbered at the end of the test plan
- [ ] Architecture diagram is present (ASCII art)
- [ ] Gap analysis table is present with severity ratings

---

## 10. Common Patterns

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
