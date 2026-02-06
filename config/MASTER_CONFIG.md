# Global Development Configuration

**This is loaded automatically on every Claude Code session.**

---

## Environment

- **Workspace:** All projects in `~/projects/`
- **User:** benjaminhippler
- **Container Platform:** OrbStack (NOT Docker Desktop)
- **Shell:** bash

---

## Critical Rules: Docker/OrbStack

⚠️ **NEVER shut down Docker/OrbStack service:**
- Multiple users/agents work in parallel on this machine
- NEVER use: `orbstack stop`, `docker system prune -a`, `killall Docker`
- ONLY manage individual containers: `docker-compose up/down`, `docker stop <container>`

---

## Port Mappings

```
resolver:
  - backend: 9000
  - frontend: 3001
  - arangodb: 8529 (web UI: 8530)

flowmaster:
  - backend: 9001
  - frontend: 3002
  - arangodb: 8529 (shared with resolver)

Port Ranges:
  - Backend APIs: 9000-9099
  - Frontend: 3000-3099
  - Check availability: lsof -i :PORT
```

---

## Database Shared Resources

**ArangoDB (localhost:8529):**
- resolver → database: flow_resolver
- flowmaster → database: flowmaster
- Web UI: http://localhost:8530

**Important:** Projects share the ArangoDB instance but use separate databases.

---

## Project Structure

All projects: `~/projects/`
```
~/projects/
├── resolver/              (Incident analysis system)
├── flowmaster/            (Workflow orchestration)
├── claude-config-loader/  (This config system)
└── [your other projects]
```

---

## Development Rules

1. **Security:** Never introduce SQL injection, XSS, command injection
2. **Simplicity:** No over-engineering, only implement what's requested
3. **No scope creep:** Don't add features beyond the task
4. **Git commits:** Only when explicitly requested
5. **Never:** Use destructive git commands without explicit permission
6. **Docker:** Only manage individual containers, never the service
7. **Ports:** Use consistent ports, check availability before use
8. **Multi-user:** Other agents/users work in parallel, don't interfere

---

## Project-Specific Instructions

**If a project has `claude_instructions.md` or `CLAUDE.md`, read it for project-specific rules.**

---

## Saving New Information

When the user provides new infrastructure information (repos, servers, ports, etc.):
1. Offer to save it to the appropriate config file
2. Use Edit tool to update: `~/projects/claude-config-loader/config/[appropriate-file].yaml`
3. Confirm what was saved

Example files:
- `config/ports.yaml` - Port mappings
- `config/servers.yaml` - Server information
- `config/git-repos.yaml` - Repository URLs
- `config/databases.yaml` - Database details
