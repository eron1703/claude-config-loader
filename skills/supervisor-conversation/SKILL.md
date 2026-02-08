---
name: supervisor-conversation
description: Resume pattern and agent monitoring for supervisor-worker communication
disable-model-invocation: true
---

# Supervisor-Worker Conversation Protocol

## Monitoring Running Agents

### Peeking (Non-Blocking Check)
```
TaskOutput(task_id, block=false, timeout=5000)
```
- Returns current output without stopping the agent
- Agent continues running — this is observation only
- Use on every timer check-in for every running agent

### Interpreting Agent Output
When peeking at agent output, look for:
- **STATUS: DONE** → Agent finished. Process results.
- **STATUS: BLOCKED** → Agent stuck. Read QUESTIONS section. Resume with answers.
- **STATUS: PARTIAL** → Agent made progress but exited. Decide: resume or re-launch.
- **No STATUS line yet** → Agent still working. Check progress since last peek.
- **Same output as last peek** → Agent may be stuck. Consider killing after 2 consecutive stale checks.

## Resuming an Agent (Conversation)

When an agent exits with questions, resume it with answers:

```
Task(resume=agent_id, prompt="Answers to your questions:
1. The correct route path is /api/v1/processes/
2. The GitLab PAT is glpat-xxx
3. The service runs on port 9003

Continue with your task using this information.")
```

### Resume Rules
- The resumed agent keeps its FULL prior context
- Provide ONLY the new information — don't repeat the original task
- Maximum 3 resumes per agent — after that, re-scope the task and launch fresh
- Each resume should make the agent more specific, not more exploratory

## Killing a Stuck Agent

```
TaskStop(task_id)
```

### When to Kill
- Agent has made no progress for 2 consecutive timer check-ins (~4 min)
- Agent is looping (same commands repeated in output)
- Agent went off-scope (exploring instead of executing)
- Agent hit a hard blocker that can't be resolved via resume

### After Killing
1. Read the agent's output to understand what it learned
2. Salvage any useful findings
3. Re-launch a new agent with:
   - Narrower scope
   - More specific knowledge from what the killed agent discovered
   - Different approach if the original approach failed

## Decision Tree on Timer Check-In

```
For each running agent:
├── Completed?
│   ├── Yes → Process results. Launch follow-up if needed.
│   └── No → Continue...
├── Has STATUS: BLOCKED?
│   ├── Yes → Read questions. Resume with answers.
│   └── No → Continue...
├── Making progress since last check?
│   ├── Yes → Leave it alone.
│   └── No → Is this the 2nd stale check?
│       ├── Yes → Kill it. Re-launch with narrower scope.
│       └── No → Note as "watch". Check again next cycle.
└── Done checking all agents.
    └── Launch new timer. Launch new work agents if capacity available.
```
