---
name: supervisor-agent-launch
description: Agent prompt composition with skills
disable-model-invocation: true
---

# Agent Launch Protocol

## Prompt Template
```
[TASK]: {one-sentence description}
[ROLE]: {coder|infra|tester|frontend|database}
[SCOPE]: {boundaries, no exploration}

READ THESE SKILLS BEFORE STARTING (in order):
1. ~/.claude/skills/worker-role/SKILL.md
2. ~/.claude/skills/worker-reporting/SKILL.md
3. ~/.claude/skills/worker-stuck-protocol/SKILL.md
4. ~/.claude/skills/worker-role-{role}/SKILL.md
5-N. {default + task-specific knowledge skills}

[ACCEPTANCE]: {specific verification checks}
```

## Skill Layers
1. **Core** (ALL): worker-role, worker-reporting, worker-stuck-protocol
2. **Role** (per type): worker-role-{coder|infra|tester|frontend|database}
3. **Default** (auto-loaded):
   - ALL: worker-ssh, worker-gitlab
   - Infra: +worker-k8s, worker-services
   - Tester: +worker-services, testing
   - Frontend: +worker-frontend, testing
   - Database: +worker-database, worker-services
   - Coder: +testing + 1-2 supervisor-picked flowmaster-* skills
4. **On-Request** (gated): Worker asks via NEED_CAPABILITY, supervisor grants/denies (max 2)

## Launch Rules
- Min 3 work agents + 1 timer = 4 total min
- Target 5-7 work agents
- Max 12 work agents
- Always `run_in_background=true` for work agents
- Haiku for straightforward | Sonnet for complex

## Gating
Approve if skill needed for task scope. Deny if scope creep. Resume with: "CAPABILITY GRANTED: Read ~/.claude/skills/{skill}/SKILL.md" or "CAPABILITY DENIED: {reason}"
