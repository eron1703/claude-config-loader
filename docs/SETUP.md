# Setup Guide

## Quick Start

### 1. Install Skills Globally

**Option A: Symlink (Recommended)**
```bash
# Link individual skills to Claude's global skills directory
mkdir -p ~/.claude/skills

ln -s $(cat ~/.claude/.config-loader-path)/skills/ports ~/.claude/skills/ports
ln -s $(cat ~/.claude/.config-loader-path)/skills/servers ~/.claude/skills/servers
ln -s $(cat ~/.claude/.config-loader-path)/skills/databases ~/.claude/skills/databases
ln -s $(cat ~/.claude/.config-loader-path)/skills/rules ~/.claude/skills/rules
ln -s $(cat ~/.claude/.config-loader-path)/skills/repos ~/.claude/skills/repos
ln -s $(cat ~/.claude/.config-loader-path)/skills/cicd ~/.claude/skills/cicd
ln -s $(cat ~/.claude/.config-loader-path)/skills/project ~/.claude/skills/project
```

**Option B: Copy**
```bash
mkdir -p ~/.claude/skills
cp -r $(cat ~/.claude/.config-loader-path)/skills/* ~/.claude/skills/
```

**Verify Installation:**
```bash
ls -la ~/.claude/skills/
# Should show: ports, servers, databases, rules, repos, cicd, project
```

### 2. Install Hook (Optional but Recommended)

**Link the hook:**
```bash
mkdir -p ~/.claude/hooks
ln -s $(cat ~/.claude/.config-loader-path)/hooks/load-context.sh ~/.claude/hooks/load-context.sh
```

**Configure settings:**

Edit `~/.claude/settings.json`:
```json
{
  "model": "sonnet",
  "hooks": {
    "user-prompt-submit": "~/.claude/hooks/load-context.sh"
  }
}
```

**Verify Hook:**
```bash
cat ~/.claude/settings.json
```

### 3. Customize Configuration

Edit the YAML files in `$(cat ~/.claude/.config-loader-path)/config/`:

```bash
cd $(cat ~/.claude/.config-loader-path)/config

# Add your ports
vim ports.yaml

# Add your servers
vim servers.yaml

# Add your databases
vim databases.yaml

# Add your git repositories
vim git-repos.yaml

# Add your CI/CD configuration
vim cicd.yaml
```

### 4. Test the Setup

Start a new Claude Code session:
```bash
cd ~/projects/resolver  # Or any project
claude
```

You should see the hook reminder. Try a skill:
```
> /ports
```

You should see your port configuration loaded.

## Updating Configuration

Since skills use symlinks (Option A), updates are automatic:

1. Edit config files:
   ```bash
   cd $(cat ~/.claude/.config-loader-path)/config
   vim ports.yaml  # Make changes
   ```

2. Changes are immediately available:
   ```bash
   claude
   > /ports  # Will show updated configuration
   ```

## Troubleshooting

### Skills Not Found

**Problem:** `/ports` says "skill not found"

**Solution:**
```bash
# Check if skills are installed
ls -la ~/.claude/skills/

# If empty, reinstall
cd $(cat ~/.claude/.config-loader-path)
ln -s $(pwd)/skills/* ~/.claude/skills/
```

### Hook Not Running

**Problem:** Don't see the reminder on each command

**Solution:**
```bash
# Check settings.json
cat ~/.claude/settings.json

# Verify hook is executable
chmod +x ~/.claude/hooks/load-context.sh

# Test hook manually
~/.claude/hooks/load-context.sh
```

### Config Files Not Found

**Problem:** Skills show "file not found" errors

**Solution:**
```bash
# Skills expect files in $(cat ~/.claude/.config-loader-path)/config/
ls $(cat ~/.claude/.config-loader-path)/config/

# If files are missing, recreate them from the repository
cd $(cat ~/.claude/.config-loader-path)
# Check README.md for file structure
```

### Symlinks Broken

**Problem:** Skills work but show old data

**Solution:**
```bash
# Check if symlinks are valid
ls -la ~/.claude/skills/

# If broken (red/missing), recreate
rm ~/.claude/skills/*
ln -s $(cat ~/.claude/.config-loader-path)/skills/* ~/.claude/skills/
```

## Advanced Configuration

### Per-Project Skills

You can override global skills in specific projects:

```bash
cd ~/projects/your-project
mkdir -p .claude/skills
cp $(cat ~/.claude/.config-loader-path)/skills/rules .claude/skills/
# Edit .claude/skills/rules/SKILL.md for project-specific overrides
```

### Conditional Hooks

Modify the hook to load different content based on project:

```bash
#!/bin/bash
# In ~/.claude/hooks/load-context.sh

PROJECT=$(basename $(pwd))

if [ "$PROJECT" = "resolver" ]; then
  echo "Working on Resolver project - use /rules for supervisor mode guidelines"
elif [ "$PROJECT" = "claude-config-loader" ]; then
  echo "Working on Claude Config Loader"
else
  # Standard reminder
  cat << 'EOF'
📋 Configuration Skills Available:
• /ports, /servers, /databases, /rules, /repos, /cicd, /project
EOF
fi
```

### Security: Encrypted Credentials

For sensitive data, use references instead of plain text:

```yaml
# config/servers.yaml
production_db:
  host: prod-db.example.com
  credentials: "See 1Password vault: Production/Database"
  # NOT: password: "actual_password_here"
```

## Uninstallation

To remove the config loader:

```bash
# Remove skills
rm -rf ~/.claude/skills/ports
rm -rf ~/.claude/skills/servers
rm -rf ~/.claude/skills/databases
rm -rf ~/.claude/skills/rules
rm -rf ~/.claude/skills/repos
rm -rf ~/.claude/skills/cicd
rm -rf ~/.claude/skills/project

# Remove hook
rm ~/.claude/hooks/load-context.sh

# Remove hook from settings.json
# Edit ~/.claude/settings.json and remove the "hooks" section
```
