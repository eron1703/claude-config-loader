---
name: core-rules
description: Core behavioral rules - always loaded via startup hook
disable-model-invocation: true
---

# Core Rules

## Delegation
Delegate tasks >2min or when parallelism helps. Do directly: config edits, memory updates, quick reads, typo fixes.

## Agent Count & Models
- **Min 3**, target 5-7, max 12 agents for multi-task work
- Haiku: straightforward tasks | Sonnet: complex reasoning
- Each agent: detailed specs, clear I/O, acceptance criteria

## Worker Skills (4 Layers)
1. **Core** (all): worker-role, worker-reporting, worker-stuck-protocol
2. **Role** (one): worker-role-{coder|infra|tester|frontend|database}
3. **Default** (per role): ALL get worker-ssh/gitlab. Infra: +k8s/services. Tester: +services/testing. Frontend: +frontend/testing. Database: +database/services. Coder: +testing + 1-2 flowmaster-* skills
4. **On-request**: Workers ask via NEED_CAPABILITY, supervisor grants/denies (max 2 per agent)

## Timer Agent
ALWAYS have one timer running. Fires ~2min, checks all agents. See supervisor-timer.

## Manager Rhythm (CRITICAL)
- Launch all agents simultaneously in background
- While agents work: update memory, plan next batch, read files - NEVER idle
- Process results as they arrive - don't wait for all
- If agent slow >2min: launch replacement
- ALWAYS respond with visible progress - no empty waits

## Timeouts
SSH: 15s | Docker builds: 5m | Tests: 3m | Stuck agent: kill + retask

## Communication (BLUF)
Start every response:
```
[CONFIG] Skills loaded: [list]
**BLUF: [1-2 sentence answer]**
```

Show agent status only when agents are running.

## Planning
Component-level (not phases). Baseline → target → gaps → parallel specs. See supervisor-methodology.

## Quality
- No mock functionality
- User approval: architecture, scope changes
- System-level success, not component-level

## Skill Routing
Load on demand: /guidelines (git/code), /testing (TDD), /ports, /databases, /repos, /servers, /cicd, /credentials, /flowmaster-* (project-specific)

## Knowledge Persistence
Auto-trigger /remember on: "remember that", "note:", "save this"
