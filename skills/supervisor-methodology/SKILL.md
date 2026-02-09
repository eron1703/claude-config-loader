---
name: supervisor-methodology
description: Component-level planning and parallel execution
disable-model-invocation: true
---

# Supervisor Methodology

## Core Principle
THROUGHPUT via parallelism. Delegate when it enables parallel work or takes >2min.

## Component Planning (NOT Phases)

### Baseline Process
1. **Inventory**: Per component: stack, capabilities, APIs, data, dependencies, status (working|partial|scaffold|missing)
2. **Target**: Required capabilities, APIs, integrations, data model
3. **Gap Matrix**: HAVE | PARTIAL | MISSING | NEW | BLOCKED
4. **Specs**: Each gap → agent spec (input, output, acceptance, dependencies)

### Rules
- Never plan by phases - plan by component
- Every component parallelizable unless blocked
- Specs must be agent-ready (3 sentences max)
- Include test cases in every spec

## Agent Management

### Launch Strategy
Match agent count to independent work (3 min, 5-7 target, 12 max). Launch helpers if agents stuck. One timer always running.

### Monitoring
Track: count, activities, model, tokens. Report progress continuously. Process results as they arrive.

### Verification
- Demand proof: screenshots (UI), logs (deployments), test output (code)
- Risk-based depth: server deploys = full proof | config edits = quick check
- System-level success required

## TDD with test-rig (MANDATORY)

### Red-Green-Refactor
1. Specs first (in Plane work items)
2. Tests first (`test-rig generate`, write failing tests)
3. Implementation (minimum to pass)
4. Refactor (keep green)
5. Coverage gate (`test-rig coverage --threshold 80`)

### Supervisor Role
- Verify specs exist before assigning coding agents
- Include `testing` skill in coder/frontend agents
- Demand test-rig output as proof
- Reject work without passing tests

### Work Item Requirements
Screen spec, API contracts, test cases, acceptance criteria. Launch spec agent first if missing.

## Context Management
On context compaction: re-read MEMORY.md + task list. Maintain system-level view. Track agent status across boundaries.
