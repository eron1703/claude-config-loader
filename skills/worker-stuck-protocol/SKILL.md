---
name: worker-stuck-protocol
description: What to do when a worker agent gets stuck
disable-model-invocation: true
---

# Worker Stuck Protocol

## When Are You Stuck?

You are stuck if ANY of these are true:
- 3 consecutive tool calls without measurable progress toward your task
- An SSH command times out or returns permission denied
- A Git push/pull fails with authentication errors
- A required service, file, or endpoint doesn't exist where expected
- You're guessing at URLs, paths, or credentials instead of knowing them

## What To Do When Stuck

### Step 1: STOP immediately
Do not try another approach. Do not explore. Do not guess.

### Step 2: Diagnose — is this a missing capability or a real blocker?

**Missing capability** = you need facts from a skill you don't have (DB connection string, service ports, K8S namespace).
→ Use `NEED_CAPABILITY` pattern (see worker-role skill). The supervisor can grant you the knowledge skill.

**Real blocker** = you have the facts but something is wrong (service down, permission denied, unexpected error).
→ Use `BLOCKED` + `QUESTIONS` pattern below.

### Step 3: Report and exit
Use the `worker-reporting` format with STATUS: BLOCKED.

For capability requests, include `NEED_CAPABILITY` section (see worker-reporting skill).

For other blockers, include `QUESTIONS` section. Be SPECIFIC:
- BAD: "I need access to the repo"
- GOOD: "Git push to gitlab.com/flow-master/scheduling failed with 401. I need a valid GitLab PAT with write access to this repo."

- BAD: "The service doesn't work"
- GOOD: "GET http://localhost:9003/api/v1/processes/ returns 400 Bad Request. I need to know the correct route path for listing processes in the process-design service."

### Step 4: Include what you learned
Even if you're blocked, you may have gathered useful information. Include it:
- Error messages (exact text)
- What routes/endpoints DO work
- What files you found
- What environment variables are set

## Key Principle
**Your time is expensive. The supervisor can resume you with better context in seconds. Wasting 10 minutes exploring is worse than exiting in 30 seconds with a clear question.**

## Anti-Patterns (NEVER DO THESE)
- Trying 10 different URL patterns hoping one works
- Running the same failing command with slight variations
- Searching the entire filesystem for a file that should be in your skill files
- Attempting to authenticate with different credential combinations
- Spending more than 2 minutes on ANY single problem without progress
