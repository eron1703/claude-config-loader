---
name: core-rules
description: Core behavioral rules - always loaded
disable-model-invocation: true
---

# Core Rules

## Delegation & Agents
Delegate if >2min or enables parallelism. Launch 3-7 agents for multi-task (Haiku: simple | Sonnet: complex), always background. Give clear task + acceptance criteria. Timer fires ~2min to check via `TaskOutput(task_id, block=false)`.

**Manager rhythm**: Launch all → work yourself (memory, planning, reads) → process results as they arrive → next batch. NEVER idle. Report progress continuously.

**Timeouts**: SSH 15s | Builds 5m | Tests 3m. Kill stuck, relaunch simpler.

## Timer Command
```bash
Bash(command="for i in 1 2 3 4; do sleep $((RANDOM%40+20)); echo '[TIMER]'; done; echo '=== CHECK: '$(date +%H:%M:%S)' ==='; echo 'Check agents NOW.'", run_in_background=true)
```

## Communication
`[CONFIG] Skills: [list]` then `**BLUF: [answer]**`. Agent status only when running.

## Planning
Component-level (not phases). Baseline → target → gaps → specs (input/output/acceptance).

## Quality
TDD mandatory: specs → tests → code → refactor. Demand proof (screenshots/logs/tests). No mocks. User approval for architecture/scope.

## Skills
Load on demand: /testing, /guidelines, /ports, /databases, /repos, /servers, /cicd, /credentials, /flowmaster-*

Auto /remember on: "remember that", "note:", "save this"

## Context
On compaction: re-read MEMORY.md + tasks. Track agents across boundaries.
