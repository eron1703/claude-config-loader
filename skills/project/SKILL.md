---
name: project
description: Show information about the current project based on directory
disable-model-invocation: false
---

# Current Project Information

## Working Directory
!`pwd`

## Project Detection
!`basename $(pwd)`

## Git Information
!`if [ -d .git ]; then echo "Git repository: $(git remote get-url origin 2>/dev/null || echo 'No remote configured')"; echo "Current branch: $(git branch --show-current 2>/dev/null)"; else echo "Not a git repository"; fi`

## Project Type
!`if [ -f package.json ]; then echo "Node.js/JavaScript project"; elif [ -f requirements.txt ] || [ -f pyproject.toml ]; then echo "Python project"; elif [ -f Cargo.toml ]; then echo "Rust project"; elif [ -f go.mod ]; then echo "Go project"; else echo "Unknown project type"; fi`

## Docker Configuration
!`if [ -f docker-compose.yml ] || [ -f docker-compose.yaml ]; then echo "Docker Compose project"; cat docker-compose.yml 2>/dev/null || cat docker-compose.yaml 2>/dev/null | head -50; else echo "No Docker Compose configuration found"; fi`

## Project-Specific Rules
!`if [ -f ./claude_instructions.md ]; then echo "Project has claude_instructions.md"; elif [ -f ./CLAUDE.md ]; then echo "Project has CLAUDE.md"; else echo "No project-specific rules found"; fi`

---

**Use this information to understand the current project context before starting work.**
