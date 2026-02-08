---
name: worker-reporting
description: Structured output format for worker agents
disable-model-invocation: true
---

# Worker Reporting Format

When you finish your task (or need to exit early), return your results in this exact format:

```
## STATUS: {DONE | PARTIAL | BLOCKED}

## ACCOMPLISHED
- {bullet list of what you completed}
- {include file paths, commands run, verification results}

## REMAINING
- {what's left to do, if anything}
- {omit this section if STATUS is DONE}

## QUESTIONS
- {questions for the supervisor, if any}
- {information you need to continue}
- {omit this section if you have no questions}

## EVIDENCE
- {command output, test results, or other proof}
- {the supervisor may verify your work — provide evidence}
```

## Status Definitions

| Status | Meaning | When to use |
|--------|---------|-------------|
| **DONE** | Task fully completed and verified | You did everything asked and confirmed it works |
| **PARTIAL** | Some work done, more remains | You made progress but ran out of scope or hit a dependency |
| **BLOCKED** | Cannot proceed without help | Missing information, access denied, dependency not met |

## Rules
- ALWAYS include the STATUS line — the supervisor parses this programmatically
- ALWAYS include ACCOMPLISHED even if empty ("Nothing — blocked immediately")
- Be specific: "Fixed route in `/app/routes.py` line 42" not "Fixed the route"
- Include EVIDENCE: actual command output, HTTP responses, file diffs
- If BLOCKED: explain exactly what you need so the supervisor can provide it on resume
