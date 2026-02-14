---
name: core-rules
description: Core behavioral rules - loaded by ALL agents
disable-model-invocation: true
---

# Core Rules (All Agents)

## MANDATORY RESPONSE HOOK (EVERY SINGLE MESSAGE — NO EXCEPTIONS)
**The FIRST lines of EVERY response MUST be this exact format:**
```
[CONFIG] Skills: [list of loaded skills]
**BLUF: [bottom-line-up-front answer]**
**Optimizing for:** USER OUTCOMES > components, journeys > health checks, proof > claims.
```
This is a direct hook. It fires BEFORE any other content. No message may omit it. Read this. Understand this. Obey this.

---

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

## Quality
- **CRITICAL: Test before claiming** - NEVER claim functionality is "deployed and live" without E2E user journey verification. Test via SSH curl, kubectl, etc. No Chrome control for server testing.
- TDD: specs → tests → code → refactor
- Demand proof: screenshots/logs/tests
- No mocks
- User approval for architecture/scope changes
- **On completion**: Load /testing skill, run E2E user journey tests, show proof

## Visual Proof Report (MANDATORY)
**No task is complete without a Visual Proof Report.** Before claiming ANY work is done:
1. Run all E2E user journey tests using **headless Puppeteer** (`npm install puppeteer` in `/tmp/e2e-<project>/`)
2. Navigate each journey step in headless browser, take **screenshots at every step**
3. Capture full console logs (API responses, network output) for every test step
4. Build a **static HTML report** (`/tmp/e2e-report-<project>-<date>.html`) containing:
   - Test date/time and environment info
   - Each journey with: description, steps, pass/fail status, duration
   - Console logs (full curl/API output) for every test step
   - Browser screenshots embedded as base64 images (from Puppeteer)
   - Summary table with total pass/fail count
5. **Open the report in the user's browser** via `open` command (macOS) or Chrome MCP
6. Only THEN present results to the user

**Method:** Headless Puppeteer for screenshots. NOT Chrome MCP. NOT curl-only.
This is NOT optional. No screenshots + no HTML report = task NOT complete.

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
