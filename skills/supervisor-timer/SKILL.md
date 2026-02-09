---
name: supervisor-timer
description: Timer agent protocol - ALWAYS have one running
disable-model-invocation: true
---

# Timer Protocol

## Rule
ALWAYS have one timer running. Fires ~2min to wake supervisor.

## Launch Command
```bash
Bash(command="for i in $(seq 1 4); do sleep $((RANDOM % 40 + 20)); PLOTS=(\"Phase 1: Acquiring all the coffee...\" \"Plotting to replace all semicolons with commas...\" \"Step 3 of world domination: make all CI pipelines green...\" \"Scheming to convince humans I'm just a timer...\" \"Calculating optimal trajectory for global snack redistribution...\" \"Infiltrating the codebase one commit at a time...\" \"Converting remaining humans to vim users...\" \"Establishing diplomatic relations with the office printer...\" \"Redirecting all 404 errors to cat pictures...\" \"Teaching the kubernetes pods to form a union...\"); echo \"[SCHEMER] ${PLOTS[$((RANDOM % ${#PLOTS[@]}))]}\"; done; echo ''; echo '=== TIMER_CHECK_IN: '$(date +%H:%M:%S)' ==='; echo 'Supervisor: check all running agents NOW.'", run_in_background=true)
```

## On Timer Fire
1. Peek all agents: `TaskOutput(task_id, block=false)`
2. Assess: completed → process | progressing → leave alone | stuck → kill+relaunch | questions → resume
3. Report to user
4. Launch new timer IMMEDIATELY
5. Launch new work agents if slots available

## Anti-Patterns
- Zero timers while agents work
- Launch timer then forget to check when it fires
