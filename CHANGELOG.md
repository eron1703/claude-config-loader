# Changelog

## Version 1.1.0 - 2026-02-06

### Added
- **`/remember` skill** - Smart memory system that saves new information to appropriate config files
- **`/environment` skill** - Load development environment details (OrbStack, ~/projects/, etc.)
- **Environment configuration** - New `config/environment.yaml` with system setup details
- **Project templates** - Templates for project-specific instructions
  - `CLAUDE_INSTRUCTIONS_TEMPLATE.md` - General project instructions
  - `SUPERVISOR_MODE_TEMPLATE.md` - Supervisor agent mode instructions
- **Remember guide** - Complete documentation for using the /remember skill
- **Pre-filled configuration** - All config files now have real project data

### Changed
- **Updated config files** with actual project information:
  - Added flowmaster project to ports, databases, repos
  - Added OrbStack and ~/projects/ information
  - Added Docker/OrbStack safety warnings
- **Enhanced hook** - Now mentions /environment and /remember skills
- **Updated install script** - Installs new environment and remember skills
- **Improved documentation** - Updated README and QUICKSTART with new features

### Security
- **Credential protection** - /remember skill warns against saving actual passwords/API keys
- **Reference-based storage** - Encourages saving references to password managers

## Version 1.0.0 - 2026-02-06

### Added
- Initial release
- 7 core skills: ports, servers, databases, rules, repos, cicd, project
- Configuration system with YAML files
- Hook system for context reminders
- Complete documentation
- Automated installation script
- Progressive disclosure approach for token efficiency
