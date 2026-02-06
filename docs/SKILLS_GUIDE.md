# Skills Usage Guide

## Available Skills

### `/ports`
**Purpose:** Load port mappings for all projects

**When to use:**
- Configuring docker-compose files
- Setting up service URLs
- Troubleshooting connection issues
- Adding new services
- Checking for port conflicts

**Example:**
```
You: I need to connect the frontend to the backend API
Claude: Let me check the ports
[Invokes /ports]
Claude: The resolver backend is on port 9000, frontend on 3001
```

---

### `/servers`
**Purpose:** Load server information and infrastructure details

**When to use:**
- Deploying applications
- Configuring SSH access
- Troubleshooting server issues
- Setting up new infrastructure
- Accessing production/staging environments

**Example:**
```
You: Deploy the app to staging
Claude: Let me check the server configuration
[Invokes /servers]
Claude: Connecting to staging server at staging-api.example.com...
```

---

### `/databases`
**Purpose:** Load database relationships and schema information

**When to use:**
- Working with database migrations
- Understanding data relationships
- Configuring database connections
- Troubleshooting data issues
- Understanding which projects share databases

**Example:**
```
You: Add a new collection for user profiles
Claude: Let me check the database structure
[Invokes /databases]
Claude: The resolver uses ArangoDB on localhost:8529...
```

---

### `/rules`
**Purpose:** Load development rules and guidelines (global + project-specific)

**When to use:**
- Starting work on a project
- Need coding standards reference
- Understanding workflow requirements
- Making architectural decisions

**Example:**
```
You: Start working on the authentication feature
Claude: Let me load the development rules
[Invokes /rules]
Claude: Following the security guidelines, I'll use JWT tokens...
```

**Note:** This skill loads:
1. Global rules (all projects)
2. Architecture guidelines (stack-specific)
3. Project-specific rules (from `claude_instructions.md` or `CLAUDE.md`)

---

### `/repos`
**Purpose:** Load GitHub/GitLab repository information

**When to use:**
- Cloning repositories
- Setting up git remotes
- Creating pull requests
- Understanding repository structure
- Configuring CI/CD pipelines

**Example:**
```
You: Create a PR for this feature
Claude: Let me check the repository information
[Invokes /repos]
Claude: Creating PR for resolver at github.com/yourorg/resolver...
```

---

### `/cicd`
**Purpose:** Load CI/CD pipeline configuration and deployment information

**When to use:**
- Setting up CI/CD pipelines
- Configuring GitHub Actions / GitLab CI
- Troubleshooting deployment issues
- Managing secrets and environment variables
- Understanding deployment workflows

**Example:**
```
You: Why is the CI pipeline failing?
Claude: Let me check the CI/CD configuration
[Invokes /cicd]
Claude: The pipeline runs lint, test, and build stages...
```

---

### `/project`
**Purpose:** Show information about the current project

**When to use:**
- Understanding current project context
- Switching between projects
- Checking project configuration
- Verifying git status

**Example:**
```
You: What project am I in?
Claude: Let me check
[Invokes /project]
Claude: You're in the resolver project, branch: main...
```

**Shows:**
- Working directory
- Git repository and branch
- Project type (Node.js, Python, etc.)
- Docker configuration
- Project-specific rules

---

## Usage Patterns

### Manual Invocation (By You)

Simply type the skill name:
```
> /ports

> /rules

> /databases
```

### Automatic Invocation (By Claude)

Claude will automatically invoke skills when it detects the need:

```
You: What port is the backend on?
Claude: [Automatically invokes /ports]
Claude: The resolver backend is on port 9000
```

Claude decides to invoke a skill based on the `description` field in the skill's frontmatter.

### Progressive Disclosure

Skills load information only when needed:

```
You: Add a new API endpoint
Claude: [Doesn't load ports yet]
Claude: Creating endpoint at /api/users...

You: Now configure docker-compose to expose this
Claude: [Invokes /ports to check available ports]
Claude: Using port 9000 for the backend...
```

## Combining Skills

You can use multiple skills in sequence:

```
You: Deploy the new feature to staging
Claude: [Invokes /rules to check deployment workflow]
Claude: [Invokes /servers to get staging server info]
Claude: [Invokes /cicd to check deployment pipeline]
Claude: Deploying to staging following the CI/CD process...
```

## Customizing Skills

### Edit Configuration

Skills read from YAML files in `config/`:

```bash
cd ~/projects/claude-config-loader/config
vim ports.yaml  # Changes immediately available
```

### Override for Specific Projects

Create project-specific overrides:

```bash
cd ~/projects/your-project
mkdir -p .claude/skills/rules
cp ~/projects/claude-config-loader/skills/rules/SKILL.md .claude/skills/rules/
# Edit to add project-specific rules
```

### Create New Skills

Follow the pattern:

```bash
mkdir -p ~/projects/claude-config-loader/skills/my-skill
cat > ~/projects/claude-config-loader/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: When to use this skill
disable-model-invocation: false
---

# My Skill Content

!`cat ~/projects/claude-config-loader/config/my-config.yaml`
EOF

# Link to global skills
ln -s ~/projects/claude-config-loader/skills/my-skill ~/.claude/skills/my-skill
```

## Token Efficiency

### Without Skills (Old Approach)
Load everything on every command:
- **Cost:** 2000-5000 tokens per command
- **Problem:** Wastes tokens on irrelevant info

### With Skills (New Approach)
Load only what you need:
- **Hook cost:** ~100 tokens (just reminder)
- **Skill cost:** ~500-2000 tokens (only when invoked)
- **Savings:** 80-90% reduction in token usage

### Example Comparison

**Scenario:** Working on frontend, need to connect to API

**Without skills:**
- Loads all config: ports, servers, databases, rules, repos, CI/CD
- Total: ~4000 tokens
- Used: ports only (~500 tokens)
- Wasted: ~3500 tokens

**With skills:**
- Hook reminder: 100 tokens
- Invokes /ports: 500 tokens
- Total: 600 tokens
- Savings: 85%

## Best Practices

1. **Let Claude decide** - Skills have descriptions that help Claude know when to use them
2. **Manual override** - If Claude doesn't invoke automatically, you can invoke manually
3. **Keep config updated** - Changes are immediately available through symlinks
4. **Use project-specific overrides** - When a project has unique requirements
5. **Reference sensitive data** - Never store actual passwords/API keys

## Troubleshooting

### Skill Not Working

```bash
# Check if skill exists
ls ~/.claude/skills/

# Test skill manually
cat ~/.claude/skills/ports/SKILL.md

# Check config file
cat ~/projects/claude-config-loader/config/ports.yaml
```

### Wrong Information Loaded

```bash
# Verify which config file is being used
# Check the !`cat ...` line in SKILL.md
cat ~/.claude/skills/ports/SKILL.md

# Update the config file
vim ~/projects/claude-config-loader/config/ports.yaml
```

### Skill Not Auto-Invoked

The skill's `description` field determines when Claude uses it automatically. Edit the skill:

```bash
vim ~/.claude/skills/ports/SKILL.md
# Update the description in the frontmatter
```
