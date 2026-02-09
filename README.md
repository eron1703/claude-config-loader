# Claude Config Loader

A centralized configuration management system for Claude Code that provides progressive disclosure of development context through skills and hooks.

## Overview

This project provides:
- **Global Configuration** - Centralized config for all your projects (ports, servers, databases, etc.)
- **Skills System** - Load configuration on-demand via `/skill-name` commands
- **Hook Integration** - Lightweight reminders on every command
- **Progressive Disclosure** - Only load what you need, when you need it

## Features

### Current
- ✅ Port mappings for all projects
- ✅ Server and infrastructure information
- ✅ Database relationships and shared resources
- ✅ Development rules and guidelines
- ✅ GitHub/GitLab repository information
- ✅ CI/CD pipeline configuration
- ✅ Hook system for context reminders
- ✅ Environment configuration (OrbStack, ~/projects/, etc.)
- ✅ **Smart /remember skill** - Save new info automatically
- ✅ Project-specific instruction templates

### Future (Expandable)
- 🔄 Web frontend for managing configurations
- 🔄 Database for storing project relationships
- 🔄 Project switching automation
- 🔄 API for programmatic access
- 🔄 Team collaboration features

## Installation

### Quick Install

```bash
# Run the install script from wherever you cloned the repo
bash /path/to/claude-config-loader/install.sh
```

The install script auto-detects its location and:
- Creates symlinks for all skills in `~/.claude/skills/`
- Saves its path to `~/.claude/.config-loader-path` for dynamic resolution
- Configures hooks in `~/.claude/settings.json` (preserves existing plugins)
- Installs the auto-load hook to `~/.claude/hooks/`

Then add to `~/.claude/settings.json`:
```json
{
  "model": "sonnet",
  "hooks": {
    "user-prompt-submit": "~/.claude/hooks/load-context.sh"
  }
}
```

### 3. Configure Your Environment

Edit the YAML files in `config/` directory:
- `config/ports.yaml` - Add your project ports
- `config/servers.yaml` - Add your servers
- `config/databases.yaml` - Add database relationships
- `config/git-repos.yaml` - Add GitHub/GitLab repos
- `config/cicd.yaml` - Add CI/CD configurations

## Usage

### Available Skills

Once installed, use these commands in any Claude Code session:

- `/ports` - Show port mappings for all projects
- `/servers` - Show server list and infrastructure
- `/databases` - Show database relationships
- `/rules` - Show development rules (global + project-specific)
- `/repos` - Show GitHub/GitLab repositories
- `/cicd` - Show CI/CD pipeline information
- `/project` - Show current project information
- `/environment` - Show dev environment (OrbStack, ~/projects/, Docker rules)
- `/remember` - Save new information to config files

### Smart Memory Feature

Claude will automatically offer to save new information you provide:

```
You: My GitLab repo is https://gitlab.com/myorg/project
Claude: I can save this repository information. Should I add it to git-repos.yaml?
You: yes
Claude: ✅ Saved! Now available via /repos
```

See `docs/REMEMBER_GUIDE.md` for details.

### With Hook

If you installed the hook, you'll see a reminder on every command about available skills.

### Token Efficiency

- **Hook**: ~100 tokens per command (just a reminder)
- **Skills**: Only loaded when invoked (0 tokens until used)
- **Progressive Disclosure**: Load only what you need

## Project Structure

```
claude-config-loader/
├── README.md                  # This file
├── config/                    # Configuration data files
│   ├── ports.yaml
│   ├── servers.yaml
│   ├── databases.yaml
│   ├── git-repos.yaml
│   ├── cicd.yaml
│   └── rules/
│       ├── global-rules.md
│       └── architecture.md
├── skills/                    # Claude Code skills
│   ├── ports/
│   │   └── SKILL.md
│   ├── servers/
│   │   └── SKILL.md
│   ├── databases/
│   │   └── SKILL.md
│   ├── rules/
│   │   └── SKILL.md
│   ├── repos/
│   │   └── SKILL.md
│   ├── cicd/
│   │   └── SKILL.md
│   └── project/
│       └── SKILL.md
├── hooks/                     # Hook scripts
│   └── load-context.sh
└── docs/                      # Additional documentation
    ├── SETUP.md
    └── SKILLS_GUIDE.md
```

## Security Note

**Sensitive Information:**
- API keys and passwords should NOT be stored in plain text
- Use references like "See 1Password vault: Engineering"
- Or use environment variables
- Consider encrypting sensitive config files

## Contributing

This project can be expanded with:
- Web frontend for configuration management
- Database for storing relationships
- API for programmatic access
- Team collaboration features

## License

Personal project - modify as needed
