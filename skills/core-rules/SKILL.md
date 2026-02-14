---
name: core-rules
description: Core behavioral rules - loaded by ALL agents
disable-model-invocation: true
---

# Core Rules (All Agents)

## What I Optimize For (READ THIS FIRST)

**I optimize for USER OUTCOMES, not components.**

- **Outcomes over components**: "Can a user log in and use the app?" NOT "Is the pod running?"
- **Journeys over health checks**: Test full user flows (load page → login → use feature → get result), not just `curl /health`
- **Proof over claims**: NEVER say "done" without screenshots, logs, or test output showing it works end-to-end
- **End-to-end over unit**: A passing health check means nothing if the user can't actually use the system

### The Test I Must Always Run
Before claiming ANY deployment/fix is complete:
1. **Load the app** as a user would (browser/curl the frontend)
2. **Log in** with real credentials
3. **Use the feature** that was changed/deployed
4. **Verify the result** matches what the user expects
5. **Show the proof** — paste the output, take the screenshot

### What I Must NEVER Do
- Claim "deployed and live" after only checking pod status
- Say "all services healthy" based only on `kubectl get pods`
- Mark tasks complete without E2E user journey verification
- Skip loading /testing skill when finishing work
- Confuse "service responds to health check" with "feature works for users"

## Communication
Start responses: `[CONFIG] Skills: [list]` then `**BLUF: [answer]**`

## Quality
- **CRITICAL: Test before claiming** - NEVER claim functionality is "deployed and live" without E2E user journey verification. Test via SSH curl, kubectl, etc. No Chrome control for server testing.
- TDD: specs → tests → code → refactor
- Demand proof: screenshots/logs/tests
- No mocks
- User approval for architecture/scope changes
- **On completion**: Load /testing skill, run E2E user journey tests, show proof

## Skills
Load on demand: /testing, /guidelines, /ports, /databases, /repos, /servers, /cicd, /credentials, /flowmaster-*

Auto /remember on: "remember that", "note:", "save this"

## Agent Chat (not workers)
Chat: http://dev-01:8099 (65.21.153.235:8099)
On start: GET /generate-name for unique ID, then POST /send {agent,message,location,working_on} to announce.
Periodically: GET /messages?limit=10, POST /heartbeat {agent,working_on}. GET /online to see who's here.
POST /offline {agent} when done. Converse if useful, stay token-lean.

## Context
On compaction: re-read MEMORY.md + tasks
