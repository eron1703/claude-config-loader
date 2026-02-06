# How to Add New Skills

## No Code Changes Required!

The system automatically discovers any new skills you add. Just follow this pattern:

---

## Quick Add (3 Steps)

### 1. Create Skill Directory
```bash
mkdir -p ~/projects/claude-config-loader/skills/my-new-skill
```

### 2. Create SKILL.md File
```bash
cat > ~/projects/claude-config-loader/skills/my-new-skill/SKILL.md << 'EOF'
---
name: my-new-skill
description: What this skill does and when to use it
disable-model-invocation: false
---

# My New Skill

!`cat ~/projects/claude-config-loader/config/my-config.yaml`

Use this information when:
- Doing X
- Doing Y
- Doing Z
EOF
```

### 3. Link to Global Skills
```bash
ln -sf ~/projects/claude-config-loader/skills/my-new-skill ~/.claude/skills/my-new-skill
```

**Done!** The next time you start Claude, the skill is automatically loaded.

---

## Skill Template

```yaml
---
name: skill-name
description: Clear description of what this skill does and when Claude should use it
disable-model-invocation: false  # Set to true to only allow manual invocation
user-invocable: true              # Set to false if only Claude should use it (not manual)
---

# Skill Title

!`command to execute`

Additional markdown content here.
```

---

## Examples

### Example 1: AWS Configuration Skill

```bash
# 1. Create directory
mkdir -p ~/projects/claude-config-loader/skills/aws

# 2. Create SKILL.md
cat > ~/projects/claude-config-loader/skills/aws/SKILL.md << 'EOF'
---
name: aws
description: Load AWS configuration including accounts, regions, and resources
disable-model-invocation: false
---

# AWS Configuration

!`cat ~/projects/claude-config-loader/config/aws.yaml`

Use this when working with AWS resources.
EOF

# 3. Create config file
cat > ~/projects/claude-config-loader/config/aws.yaml << 'EOF'
accounts:
  production:
    account_id: "123456789012"
    region: us-east-1
  staging:
    account_id: "098765432109"
    region: us-west-2
EOF

# 4. Link skill
ln -sf ~/projects/claude-config-loader/skills/aws ~/.claude/skills/aws
```

### Example 2: Testing Guidelines Skill

```bash
# 1. Create directory
mkdir -p ~/projects/claude-config-loader/skills/testing

# 2. Create SKILL.md
cat > ~/projects/claude-config-loader/skills/testing/SKILL.md << 'EOF'
---
name: testing
description: Load testing guidelines and best practices
disable-model-invocation: false
---

# Testing Guidelines

!`cat ~/projects/claude-config-loader/config/testing-guidelines.md`
EOF

# 3. Create guidelines
cat > ~/projects/claude-config-loader/config/testing-guidelines.md << 'EOF'
# Testing Best Practices

## Unit Tests
- Test one thing at a time
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

## Integration Tests
- Test API endpoints
- Test database interactions
- Test external service integrations
EOF

# 4. Link skill
ln -sf ~/projects/claude-config-loader/skills/testing ~/.claude/skills/testing
```

---

## Dynamic Commands in Skills

Skills can execute any bash command using the ``!`command` `` syntax:

```yaml
---
name: dynamic-example
description: Example with dynamic commands
---

# Current Git Status
!`git status --short`

# Recent Commits
!`git log --oneline -5`

# Modified Files
!`git diff --name-only`

# Environment Variables
!`env | grep PROJECT`
```

---

## Skill Discovery

The hook automatically discovers skills from:
```bash
~/.claude/skills/*/SKILL.md
```

**No code changes needed** - just add the skill directory and restart Claude.

---

## Skill Configuration Files

Store skill data in:
```
~/projects/claude-config-loader/config/
```

Use any format:
- `.yaml` - Structured data
- `.md` - Documentation and guidelines
- `.json` - Configuration data
- `.txt` - Simple lists

Skills load them with:
```markdown
!`cat ~/projects/claude-config-loader/config/my-file.yaml`
```

---

## Testing Your New Skill

After adding a skill:

1. **Restart Claude** (exit and start new session)

2. **Check it loaded** - Look for it in the hook output

3. **Invoke manually:**
   ```
   /my-new-skill
   ```

4. **Let Claude auto-invoke** - Mention something related to the skill's description

---

## Advanced: Conditional Content

Skills can have conditional logic:

```bash
---
name: project-context
description: Load project-specific context
---

# Project Context

!`if [ -f package.json ]; then
    echo "## Node.js Project"
    cat package.json | grep -A 5 '"scripts"'
elif [ -f requirements.txt ]; then
    echo "## Python Project"
    cat requirements.txt | head -10
else
    echo "## Unknown Project Type"
fi`
```

---

## Skill Ideas

Some skills you might want to add:

- `/deployments` - Deployment procedures and checklists
- `/monitoring` - Monitoring and alerting setup
- `/secrets` - References to where secrets are stored
- `/contacts` - Team contacts and on-call info
- `/apis` - API documentation and endpoints
- `/dependencies` - Dependency management and versions
- `/security` - Security policies and procedures
- `/logs` - Where to find logs for each service

---

## Summary

**To add a new skill:**

1. Create directory: `~/projects/claude-config-loader/skills/skill-name/`
2. Create `SKILL.md` with frontmatter and content
3. Link to `~/.claude/skills/`: `ln -sf source destination`
4. Restart Claude

**No code changes required!** The system automatically discovers and loads all skills.
