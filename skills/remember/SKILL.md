---
name: remember
description: Save important information to skills, MEMORY.md, and GitLab CI/CD variables. Triggered by /remember, "remember that", or "note:"
user-invocable: true
---

# Remember - Persistent Knowledge Management

When the user says "/remember", "remember that", "note:", "save this", or similar intent to persist information, do ALL of the following automatically:

## What to Save

Determine the type of information and save it to the right place:

### Credentials (passwords, tokens, API keys, URLs with auth)
1. Save to **GitLab CI/CD group variable**: `curl -s --request POST "https://gitlab.com/api/v4/groups/122023679/variables" --header "PRIVATE-TOKEN: <PAT>" --form "key=VARIABLE_NAME" --form "value=<value>" --form "protected=true" --form "masked=true"`
2. Update **credentials skill**: Edit `/Users/benjaminhippler/projects/claude-config-loader/skills/credentials/SKILL.md` to add reference
3. Update **MEMORY.md** with a note about where it's stored

### Infrastructure info (servers, ports, services, URLs)
1. Update the relevant **skill file** (servers, ports, databases, etc.)
2. Update **MEMORY.md** with the new information
3. If it's a config value, consider adding to GitLab CI/CD variables

### Architectural decisions, patterns, lessons learned
1. Update **MEMORY.md** directly
2. If it affects a specific skill, update that skill too

### Project-specific info (FlowMaster services, endpoints, configs)
1. Update the relevant **flowmaster-* skill** file
2. Update **MEMORY.md**

## After Saving

ALWAYS do these steps after saving:
1. **Commit**: `cd ~/projects/claude-config-loader && git add -A && git commit -m "remember: <brief description>"`
2. **Push to GitHub**: `git push origin main`
3. **Push to GitLab**: `git push gitlab main`
4. **Confirm to user**: Report what was saved and where

## Trigger Words
- `/remember` (slash command)
- "remember that..."
- "note:"
- "save this"
- "don't forget"
- "store this"
- "keep in mind"

When you detect these trigger words, execute this skill automatically without being explicitly invoked.
