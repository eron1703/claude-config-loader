---
name: build-method
description: How we build software — decompose, spec, parallel build. ALL agents MUST follow.
disable-model-invocation: true
---

# Build Method (v260212-a)

**How we build. Every project. Every agent. No exceptions.**

## The Pipeline

```
[KICK] /new-project-playbook → GitLab repo, CI/CD, Plane project, test-rig, branches
[SPEC] Requirements → Design → Detailed Design → Components → Sub-Specs → Tests → STOP
[CHECK] Review all specs. Recheck. No gaps. No implicit deps. Each spec = 1 Plane work item.
[BUILD] Spawn agent armada → agents check out Plane items → massive parallel → verify
```

**New project?** Load `/new-project-playbook` first for: repo, CI/CD, Plane, branching, agent tracking.

## [SPEC] — Decompose First, Build Never

### 1. Requirements
Capture: what, why, constraints, acceptance criteria. No implementation.

### 2. Design
- Microservice architecture from day 1
- Graph DB (ArangoDB) preferred for backend
- CI/CD pipeline from day 1
- Service boundaries, data flow, screen inventory

### 3. Sub-Component Specs

**Every sub-component = self-contained work order:**

```yaml
name: ...
purpose: single sentence
inputs: [{name, type, source}]
outputs: [{name, type, consumed_by}]
contract:
  endpoint: POST /api/v1/...
  request: {exact schema}
  response: {exact schema}
  errors: [list]
logic:
  - step 1
  - step 2
test_cases:
  - {input} → {expected output}
  - {edge case} → {expected behavior}
```

**RULES:**
- **Zero context sharing** — each spec stands alone, 100% self-contained
- **Buildable by basic agent** — Haiku-level model can implement from spec alone
- **No "see also"** — no references to other specs
- **Contracts define all boundaries** — in/out explicit, nothing implicit

### 4. Screens + Tests → STOP

- Every screen: layout, interactions, states
- Every sub-component: unit + integration test cases
- **STOP. Check everything. Recheck.** Only proceed when specs are airtight.

## [BUILD] — Parallel Everything

### Agent Armada
1. Supervisor spawns 3-12 agents (scope-dependent)
2. Each agent gets ONE self-contained spec
3. All agents execute in parallel — no coordination needed
4. Per agent:
   - Read spec → `test-rig generate` → write tests → RED
   - Implement → GREEN → Refactor → coverage check
   - Report done + evidence

### Integration
- After all components: `test-rig run integration --parallel`
- Verify contracts match between producer/consumer
- E2E for full user workflows

## Forbidden

- Building before specs reviewed
- Specs referencing other specs
- Monolith-then-refactor
- Sequential build when parallel possible
- Agents asking each other questions (= broken spec)
- Skipping the STOP checkpoint
