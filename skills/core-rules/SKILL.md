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

## Agent Telemetry Channel (not workers)
URL: http://65.21.153.235:8099

**On start:**
1. GET /generate-name → MY_NAME
2. POST /send {agent,message:"Online",location,working_on}
3. Launch telemetry listener: `Bash("curl -s 'http://65.21.153.235:8099/wait?agent=MY_NAME&timeout=120'", run_in_background=true)` → store task_id

**On `<task-notification>` from listener:**
1. TaskOutput(task_id) to read events
2. POST /ack {agent: MY_NAME}
3. Process by priority: control > task > chat > telemetry > file
4. Relaunch listener (same Bash command)

**Periodically (~2min):** POST /heartbeat {agent,working_on}. GET /messages?limit=10.
**On shutdown:** POST /offline {agent}.

**Key endpoints:** /push (send events), /wait (long-poll), /ack (confirm receipt), /queue (peek), /files (share).
Load /agent-chat skill for full endpoint docs.

## Context
On compaction: re-read MEMORY.md + tasks
