# Skills Confirmation Requirement

**BLUF: Every response MUST start with `[CONFIG] Skills loaded: [list]` to confirm ingested configuration.**

## Mandatory Format

```
[CONFIG] Skills loaded: cicd, credentials, databases, environment, guidelines, ports, project, repos, save, servers, supervisor

**BLUF: [answer]**

[essential details]
```

## Why

- Confirms hook executed successfully
- Shows which skills are active in current context
- Helps user verify configuration is loaded
- Provides transparency about available context

## Hook Configuration

**File:** `~/.claude/settings.json`
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/benjaminhippler/.claude/hooks/auto-load-config.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook Script:** `~/.claude/hooks/auto-load-config.sh`
- Loads core-development-rules
- Lists available skills
- Runs on every user command submission

## Which Skills to List

**Always include:**
- Core skills that are active/relevant to current context

**Format:**
- Comma-separated skill names (not full descriptions)
- Example: `cicd, credentials, databases, environment, guidelines, ports, project, repos, save, servers, supervisor`

**NOT the full MECE structure** - just the skill names themselves.

## Enforcement

Added to Communication Style in `core-development-rules.md`:

```markdown
### Response Format - MANDATORY

**Every response MUST start with:**
```
[CONFIG] Skills loaded: [list skill names]

**BLUF: [answer]**
```
```

This ensures:
1. Hook confirmation visible to user
2. Loaded skills are transparent
3. Configuration status is clear
4. No silent failures

## Historical Note

This requirement existed previously but got lost during updates. Now permanently enforced in core-development-rules.
