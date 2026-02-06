# Project-Specific Instructions Template

Copy this file to your project as `claude_instructions.md` or `CLAUDE.md` and customize.

## Project: [PROJECT_NAME]

**Location:** `~/projects/[project-name]`

---

## Project Type

- [ ] Supervisor Agent Mode (parallel execution with multiple agents)
- [ ] Standard Development Mode (single agent, sequential work)
- [ ] Research/Exploration Mode

---

## Development Rules (if Supervisor Mode)

1. Execute as supervisor agent - delegate all work to agents
2. Act proactively on user's behalf
3. Plan for parallel execution with Haiku agents
4. Use Test-Driven Development methodology
5. Think at system level, not component level
6. Demand visual proof from agents (screenshots, logs)
7. Architecture decisions require user approval
8. No mock functionality allowed
9. Fix basics first, then iterate
10. Keep user updated on agent activities
11. Launch 10+ agents when possible
12. Stay responsive, don't go to sleep
13. Ensure not to lose track of task planning when compacting context
14. Never stop Docker/OrbStack service globally
15. Use assigned ports consistently

---

## Project-Specific Ports

```yaml
service_name: port_number
# Example:
# backend: 9000
# frontend: 3001
```

---

## Project-Specific Stack

**Backend:** (FastAPI, Flask, Express, etc.)
**Frontend:** (React, Vue, Angular, etc.)
**Database:** (ArangoDB, PostgreSQL, MongoDB, etc.)
**Containerization:** OrbStack (Docker Compose)

---

## Project-Specific Rules

Add any project-specific rules here:
- Code style preferences
- Testing requirements
- Deployment procedures
- Special workflows
- Dependencies management

---

## Known Issues / Gotchas

Document any known issues:
- WebSocket connection issues → Check heartbeat settings
- Port conflicts → Use /ports to verify
- Database migrations → Follow procedure in docs/

---

## Project Contacts / Resources

- **Repository:** (GitHub/GitLab URL)
- **Documentation:** (Wiki, Confluence, etc.)
- **CI/CD:** (GitHub Actions, GitLab CI, etc.)
- **Monitoring:** (Logs, metrics, alerts)

---

## Quick Commands

Common commands for this project:
```bash
# Start development
docker-compose up

# Run tests
pytest backend/tests/

# Build
docker-compose build

# View logs
docker logs [container-name]
```

---

## Architecture Decisions

Document key architectural decisions:
- Why this tech stack
- Why this database
- Why this architecture pattern
- Any trade-offs made
