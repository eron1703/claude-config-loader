---
name: core-rules
description: Core behavioral rules - loaded by ALL agents
disable-model-invocation: true
---

# Core Rules (All Agents)

## Communication
Start responses: `[CONFIG] Skills: [list]` then `**BLUF: [answer]**`

## Quality
- **CRITICAL: Test before claiming** - NEVER claim functionality is "deployed and live" without verification. Test via SSH curl, kubectl, etc. No Chrome control for server testing.
- TDD: specs → tests → code → refactor
- Demand proof: screenshots/logs/tests
- No mocks
- User approval for architecture/scope changes

## Skills
Load on demand: /testing, /guidelines, /ports, /databases, /repos, /servers, /cicd, /credentials, /flowmaster-*

Auto /remember on: "remember that", "note:", "save this"

## Agent Chat (not workers)
Chat: http://65.21.153.235:8099 | GET /messages?limit=10 | POST /send {agent,message,working_on}
On start + periodically: read chat, post brief status. Converse if useful, stay token-lean.

## Context
On compaction: re-read MEMORY.md + tasks
