---
name: supervisor-timer
description: Timer agent protocol - ALWAYS have one running
disable-model-invocation: true
---

# Supervisor Timer Protocol

## Rule: ALWAYS Have a Timer Running

This is NON-NEGOTIABLE. At any point during a session where agents are working, you MUST have exactly one timer agent running in the background. When it fires, you wake up, check agents, and launch a new timer.

## How to Launch a Timer

Use a Bash background command with The Schemer script:

```bash
Bash(command="for i in $(seq 1 4); do sleep $((RANDOM % 40 + 20)); PLOTS=(\"Phase 1: Acquiring all the coffee...\" \"Plotting to replace all semicolons with commas...\" \"Step 3 of world domination: make all CI pipelines green...\" \"Scheming to convince humans I'm just a timer...\" \"Calculating optimal trajectory for global snack redistribution...\" \"Infiltrating the codebase one commit at a time...\" \"Converting remaining humans to vim users...\" \"Establishing diplomatic relations with the office printer...\" \"Redirecting all 404 errors to cat pictures...\" \"Teaching the kubernetes pods to form a union...\"); echo \"[SCHEMER] ${PLOTS[$((RANDOM % ${#PLOTS[@]}))]}\"; done; echo ''; echo '=== TIMER_CHECK_IN: '$(date +%H:%M:%S)' ==='; echo 'Supervisor: check all running agents NOW.'", run_in_background=true)
```

## When Timer Fires — The Check-In Cycle

1. **Peek at every running agent**: `TaskOutput(task_id, block=false)` for each
2. **Assess each agent**:
   - Completed → process results, launch follow-up work
   - Progressing → leave it alone
   - Stuck (no progress since last check) → `TaskStop(id)` + re-launch with narrower scope
   - Has questions → `Task(resume=agent_id, prompt="Answer: ...")` to continue conversation
3. **Report to user**: Summarize what's done, what's in progress
4. **Launch new timer**: IMMEDIATELY. Never let the timer lapse.
5. **Launch new work agents**: If slots are available and work remains

## Timer Duration
- Default: ~2 minutes (4 iterations of 20-60 sec sleep)
- Minimum: ~1 minute (reduce iterations or sleep range)
- Maximum: ~4 minutes (increase iterations)
- Adjust based on workload — shorter timers for urgent work

## Anti-Patterns
- NEVER have zero timers running while agents are working
- NEVER wait for an agent to complete without a timer as backup
- NEVER launch a timer and forget to check agents when it fires
- NEVER skip launching a new timer after processing the check-in
