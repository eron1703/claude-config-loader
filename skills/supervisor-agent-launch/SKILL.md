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

## Skill Loading Matrix

### Typical Combinations (starting point — add more as needed)

| Agent Role | Role Skill | Typical Knowledge Skills |
|-----------|-----------|------------------------|
| **Coder** | worker-role-coder | worker-gitlab + task-specific (flowmaster-backend, etc.) |
| **Infra** | worker-role-infra | worker-ssh, worker-k8s, worker-services |
| **Tester** | worker-role-tester | worker-services, worker-ssh, testing (test-rig) |
| **Frontend** | worker-role-frontend | worker-frontend, worker-gitlab |
| **Database** | worker-role-database | worker-database, worker-services |

### All Available Knowledge Skills (pick any combination per task)

| Skill | Content | Use When |
|-------|---------|----------|
| `worker-ssh` | SSH hosts, keys, timeout patterns | Any server access |
| `worker-gitlab` | PAT, repo URLs, clone/push | Any git operations |
| `worker-k8s` | Namespaces, kubectl, registry, ClusterIPs | K8S deployments |
| `worker-database` | ArangoDB + PostgreSQL + Redis connections | DB operations |
| `worker-api-gateway` | Nginx → Gateway → Service routing chain | API routing issues |
| `worker-frontend` | Next.js repo, build args, auth creds | Frontend work |
| `worker-services` | All 29 services: port, health, stack | Service lookups |
| `testing` | test-rig CLI, TDD workflow, CI patterns | Running tests |
| `flowmaster-overview` | System architecture, core concepts | Architecture context |
| `flowmaster-backend` | 13 services + 3 apps, APIs, endpoints | Backend dev |
| `flowmaster-database` | ArangoDB schema, collections, relationships | Schema work |
| `flowmaster-environment` | Service env vars, ports, config | Config/deploy |
| `flowmaster-frontend` | UI components, patterns, integration | Frontend dev |
| `flowmaster-server` | Server infra, CI/CD, deployment | DevOps |
| `flowmaster-tools` | MCP tools, integrations, SDX | Integrations |

The supervisor decides which knowledge skills each agent needs based on the task. More skills = more context but also more tokens. Pick the minimum set needed.

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
# Launch 5 work agents + 1 timer = 6 total
Task(description="Fix process-design routes", model=haiku, run_in_background=true,
  prompt="[TASK]: Add GET /api/v1/processes route to process-design service
  [ROLE]: infra
  [SCOPE]: SSH to demo server, check current routes, add missing endpoint, verify with curl
  READ THESE SKILLS FIRST:
  1. ~/.claude/skills/worker-role/SKILL.md
  2. ~/.claude/skills/worker-reporting/SKILL.md
  3. ~/.claude/skills/worker-stuck-protocol/SKILL.md
  4. ~/.claude/skills/worker-role-infra/SKILL.md
  5. ~/.claude/skills/worker-ssh/SKILL.md
  6. ~/.claude/skills/worker-k8s/SKILL.md
  7. ~/.claude/skills/worker-services/SKILL.md
  [ACCEPTANCE]: curl http://localhost:9003/api/v1/processes/ returns 200 with JSON")

# Plus 4 more work agents... Plus 1 timer agent
```

## Anti-Patterns
- NEVER launch an agent without skill references in the prompt
- NEVER launch fewer than 3 work agents for multi-task operations
- NEVER use `block=true` (default) for work agents — always background
- NEVER forget the timer agent
- NEVER launch an agent with vague scope ("fix the service" — BAD)
