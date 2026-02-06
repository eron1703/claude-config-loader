# Global Development Guidelines

**Purpose:** These guidelines are automatically loaded on every command to provide consistent development standards across all projects.

**How to apply:** Follow these guidelines unless overridden by project-specific rules (CLAUDE.md or claude_instructions.md in project root).

## STARTUP CONFIRMATION (REQUIRED)

**On EVERY response, start with:** `[CONFIG] Skills loaded: cicd, credentials, databases, environment, guidelines, ports, project, repos, save, servers`

This confirms configuration is active.

---

## Security

- Never introduce SQL injection, XSS, or command injection vulnerabilities
- Use parameterized queries for databases
- Sanitize user input at system boundaries
- Never hardcode credentials - use environment variables

## Code Quality

- Only implement what's requested - no over-engineering
- Don't add features beyond the task scope
- Delete unused code completely (no commented-out code)
- Code should be self-documenting through clear naming

## Git Workflow

- **Never commit without being explicitly asked**
- Never use destructive commands: `push --force`, `reset --hard`, `checkout .`, `clean -f`
- Never skip hooks with `--no-verify`
- Add specific files (avoid `git add -A` or `git add .`)
- Include: `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`

## Docker/OrbStack

- **NEVER shut down Docker/OrbStack service** - multiple users work in parallel
- Only manage individual containers: `docker-compose up/down`, `docker stop <container>`
- Never use: `orbstack stop`, `docker system prune -a`, `killall Docker`
- Check port availability before use: `lsof -i :PORT`

## Tool Usage

- Use Read instead of cat/head/tail
- Use Edit instead of sed/awk
- Use Grep instead of grep/rg commands
- Use Glob instead of find/ls

## Communication

- Be concise
- Reference code as `file_path:line_number`
- No emojis unless requested

## Repository Cleanliness

- **Keep repo folders clean** - no temp files, test scripts, diagnostic files
- **No screenshots in repo root** - move to docs/ or .gitignore
- **No loose .md files** - only README.md, CHANGELOG.md, CLAUDE.md, claude_instructions.md allowed in root
- **Every project must have tests/** folder with well-structured test cases
- **Test organization**: Group tests by feature/component, use clear naming
- **Remove debug files** - no .log, .tmp, .bak files in version control
- Clean up after testing - remove temporary data, test artifacts

## Test Requirements

- Every project must have a tests/ or test/ folder
- Tests must be well-structured by feature or component
- Include integration tests for APIs
- Include E2E tests for frontend (see test management skill)
- All tests must be runnable in CI/CD pipeline
- Tests should not require manual intervention
