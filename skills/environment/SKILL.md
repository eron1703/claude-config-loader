---
name: environment
description: Load development environment information including folder structure, OrbStack setup, and system configuration
disable-model-invocation: false
---

# Development Environment

!`cat ~/projects/claude-config-loader/config/environment.yaml`

## Critical Docker/OrbStack Rules

⚠️ **NEVER** shut down Docker/OrbStack service:
- Multiple users and agents work in parallel
- Only manage individual containers
- Never use: `orbstack stop`, `docker system prune -a`, `killall Docker`

✅ **Safe operations:**
- `docker-compose up/down` for specific services
- `docker stop/rm` for individual containers
- `docker-compose restart` for specific services

## Project Structure

All development work is in: `~/projects/`

Current projects:
!`ls -1 ~/projects/ 2>/dev/null || echo "Cannot list projects"`

## Port Management

Always check port availability before use:
```bash
lsof -i :PORT
```

Use assigned port ranges consistently.
