---
name: supervisor-agent-launch
description: How to compose agent prompts with skills and role templates
disable-model-invocation: true
---

# Supervisor Agent Launch Protocol

## Prompt Template

Every worker agent launch MUST use this structure:

```
[TASK]: {one-sentence description of what to do}
[ROLE]: {coder|infra|tester|frontend|database}
[SCOPE]: {exactly what to do — boundaries, no exploration}

READ THESE SKILLS BEFORE STARTING (in order):
1. ~/.claude/skills/worker-role/SKILL.md
2. ~/.claude/skills/worker-reporting/SKILL.md
3. ~/.claude/skills/worker-stuck-protocol/SKILL.md
4. ~/.claude/skills/worker-role-{role}/SKILL.md
5. ~/.claude/skills/{knowledge-skill-1}/SKILL.md
6. ~/.claude/skills/{knowledge-skill-2}/SKILL.md
{...add more knowledge skills as needed}

[ACCEPTANCE]: {how to verify the task is done — specific checks}
```

## Skill Loading Model — Gated Access

Workers get **minimal defaults**. Additional knowledge skills are loaded **on-request** — the worker asks, the supervisor approves or denies to prevent scope creep.

### Layer 1: Core (ALL agents — always loaded)
Every agent gets these 3 behavioral skills. Non-negotiable.
- `worker-role` — base identity, rules, capability request protocol
- `worker-reporting` — structured output format
- `worker-stuck-protocol` — exit early when stuck

### Layer 2: Role (per agent type — always loaded)
One role skill per agent, matching the `[ROLE]` in the task prompt.
- `worker-role-coder` | `worker-role-infra` | `worker-role-tester` | `worker-role-frontend` | `worker-role-database`

### Layer 3: Default Knowledge (loaded at launch — per role)

These knowledge skills are loaded **automatically** because the role can't function without them.

| Agent Role | Default Knowledge Skills | Why |
|-----------|------------------------|-----|
| **ALL roles** | `worker-ssh`, `worker-gitlab` | Credentials, SSH keys, repo access — every agent needs these |
| **Coder** | _(+ task-specific, decided by supervisor)_ | Supervisor picks 1-2 relevant `flowmaster-*` skills |
| **Infra** | `worker-k8s`, `worker-services` | Can't do infra without knowing the cluster and services |
| **Tester** | `worker-services`, `testing` | Test-rig tool + service endpoints are essential |
| **Frontend** | `worker-frontend` | Build args, repo structure, auth creds |
| **Database** | `worker-database`, `worker-services` | Connection strings, schemas, service topology |

### Layer 4: On-Request Knowledge (worker asks, supervisor gates)

These skills are NOT loaded at launch. Workers can **request** them mid-task using the `NEED_CAPABILITY` pattern (see worker-role skill).

| Skill | Content | Typical Requester |
|-------|---------|-------------------|
| `worker-k8s` | Namespaces, kubectl, registry, ClusterIPs | Coder needing deployment info |
| `worker-database` | ArangoDB + PostgreSQL + Redis connections | Coder or tester needing DB access |
| `worker-api-gateway` | Nginx → Gateway → Service routing chain | Coder debugging routing |
| `worker-services` | All 29 services: port, health, stack | Coder needing service topology |
| `worker-frontend` | Next.js repo, build args, auth creds | Coder doing full-stack work |
| `testing` | test-rig CLI, TDD workflow, CI patterns | Coder writing tests |
| `flowmaster-overview` | System architecture, core concepts | Any agent needing context |
| `flowmaster-backend` | 13 services + 3 apps, APIs, endpoints | Coder, tester |
| `flowmaster-database` | ArangoDB schema, collections, relationships | Coder, database |
| `flowmaster-environment` | Service env vars, ports, config | Infra, coder |
| `flowmaster-frontend` | UI components, patterns, integration | Frontend, coder |
| `flowmaster-server` | Server infra, CI/CD, deployment | Infra |
| `flowmaster-tools` | MCP tools, integrations, SDX | Coder, infra |

### Supervisor Gating Rules

When a worker requests a capability:
1. **Approve** if the skill is relevant to the agent's current task scope
2. **Deny** if the skill would lead to scope creep or overlap with another agent's work
3. **Resume** the agent with the skill path: `Task(resume=agent_id, prompt="CAPABILITY GRANTED: Read ~/.claude/skills/{skill-name}/SKILL.md and continue.")`
4. **Deny response**: `Task(resume=agent_id, prompt="CAPABILITY DENIED: {reason}. Stay within your current scope: {restate scope}.")`

## Launch Rules

### Minimum Agent Count
- **3 agents minimum** for any multi-task operation
- **5-7 target** for normal operations
- **12 maximum** for large parallel work
- ALWAYS include 1 timer agent (The Schemer) — see supervisor-timer skill

### Agent Count Formula
```
Total agents = work agents (3-12) + 1 timer = 4-13 total
```

### Model Selection
- **Haiku**: Straightforward tasks (file edits, config changes, simple builds, knowledge lookups)
- **Sonnet**: Complex reasoning (debugging, multi-file refactors, architectural analysis)
- **Opus**: Reserved for supervisor only

### Background Execution
- ALWAYS use `run_in_background=true` for work agents
- This allows the supervisor to continue working while agents execute
- Monitor via `TaskOutput(task_id, block=false)` on timer check-ins

## Example Launch

```
# Infra agent — gets default skills for infra role (ssh, gitlab, k8s, services)
Task(description="Fix process-design routes", model=haiku, run_in_background=true,
  prompt="[TASK]: Add GET /api/v1/processes route to process-design service
  [ROLE]: infra
  [SCOPE]: SSH to demo server, check current routes, add missing endpoint, verify with curl

  READ THESE SKILLS BEFORE STARTING (in order):
  1. ~/.claude/skills/worker-role/SKILL.md
  2. ~/.claude/skills/worker-reporting/SKILL.md
  3. ~/.claude/skills/worker-stuck-protocol/SKILL.md
  4. ~/.claude/skills/worker-role-infra/SKILL.md
  5. ~/.claude/skills/worker-ssh/SKILL.md      (default: ALL roles)
  6. ~/.claude/skills/worker-gitlab/SKILL.md    (default: ALL roles)
  7. ~/.claude/skills/worker-k8s/SKILL.md       (default: infra)
  8. ~/.claude/skills/worker-services/SKILL.md  (default: infra)

  [ACCEPTANCE]: curl http://localhost:9003/api/v1/processes/ returns 200 with JSON")

# Coder agent — gets defaults + supervisor picks 1 task-specific skill
Task(description="Add rate limiting to API Gateway", model=sonnet, run_in_background=true,
  prompt="[TASK]: Add rate limiting middleware to API Gateway using Redis token bucket
  [ROLE]: coder
  [SCOPE]: Edit api-gateway source, add middleware, add unit tests. Do NOT deploy.

  READ THESE SKILLS BEFORE STARTING (in order):
  1. ~/.claude/skills/worker-role/SKILL.md
  2. ~/.claude/skills/worker-reporting/SKILL.md
  3. ~/.claude/skills/worker-stuck-protocol/SKILL.md
  4. ~/.claude/skills/worker-role-coder/SKILL.md
  5. ~/.claude/skills/worker-ssh/SKILL.md      (default: ALL roles)
  6. ~/.claude/skills/worker-gitlab/SKILL.md    (default: ALL roles)
  7. ~/.claude/skills/flowmaster-backend/SKILL.md  (supervisor-selected for this task)

  [ACCEPTANCE]: Unit tests pass, middleware intercepts requests, returns 429 on limit")

# Plus more work agents... Plus 1 timer agent
```

## Anti-Patterns
- NEVER launch an agent without skill references in the prompt
- NEVER launch fewer than 3 work agents for multi-task operations
- NEVER use `block=true` (default) for work agents — always background
- NEVER forget the timer agent
- NEVER launch an agent with vague scope ("fix the service" — BAD)
