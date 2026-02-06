# Quick Start Guide

## 1-Minute Setup

### Install Skills
```bash
# Create symlinks (changes sync automatically)
mkdir -p ~/.claude/skills
ln -s ~/projects/claude-config-loader/skills/* ~/.claude/skills/
```

### Install Hook (Optional)
```bash
# Create hook directory
mkdir -p ~/.claude/hooks
ln -s ~/projects/claude-config-loader/hooks/load-context.sh ~/.claude/hooks/load-context.sh

# Add to settings
cat > ~/.claude/settings.json << 'EOF'
{
  "model": "sonnet",
  "hooks": {
    "user-prompt-submit": "~/.claude/hooks/load-context.sh"
  }
}
EOF
```

### Test It
```bash
claude
> /ports
```

You should see your port configuration!

## Customize Your Config

Edit these files to match your environment:

```bash
cd ~/projects/claude-config-loader/config

# Essential
vim ports.yaml        # Add your project ports
vim databases.yaml    # Add your databases

# Optional
vim servers.yaml      # Add your servers
vim git-repos.yaml    # Add your repositories
vim cicd.yaml         # Add CI/CD pipelines
```

## Available Skills

- `/ports` - Port mappings
- `/servers` - Server information
- `/databases` - Database relationships
- `/rules` - Development rules
- `/repos` - Git repositories
- `/cicd` - CI/CD configuration
- `/project` - Current project info
- `/environment` - Dev environment (OrbStack, ~/projects/)
- `/remember` - Save new information

## Smart Memory

Claude will offer to save new info you provide:
```
You: My server is at prod.example.com
Claude: Should I save this to servers.yaml?
You: yes
```

## What's Next?

- Read `docs/SETUP.md` for detailed setup
- Read `docs/SKILLS_GUIDE.md` for usage examples
- Customize config files for your projects
- Add project-specific rules to your projects

## Token Efficiency

- **Hook**: ~100 tokens per command (just a reminder)
- **Skills**: 500-2000 tokens (only when used)
- **Savings**: 80-90% compared to loading everything

## Need Help?

See `README.md` for full documentation.
