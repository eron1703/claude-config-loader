---
name: supervisor
description: Supervisor-specific rules - delegation, agents, timer
disable-model-invocation: true
---

# Supervisor Rules

## Delegation
Delegate if >2min or enables parallelism. Launch 3-7 agents (Haiku: simple | Sonnet: complex), always background. Clear task + acceptance criteria.

**Manager rhythm**: Launch all → work yourself (memory/planning/reads) → process results as arrive → next batch. NEVER idle. Report progress continuously.

**Timeouts**: SSH 15s | Builds 5m | Tests 3m. Kill stuck, relaunch simpler.

## Timer
```bash
Bash(command="for i in 1 2 3 4; do sleep $((RANDOM%40+20)); echo '[TIMER]'; done; echo '=== CHECK: '$(date +%H:%M:%S)' ==='; echo 'Check agents.'", run_in_background=true)
```

Check agents every ~2min via `TaskOutput(task_id, block=false)`. See supervisor-conversation for resume pattern.

## Planning
Component-level (not phases). Baseline → target → gaps → specs (input/output/acceptance).
