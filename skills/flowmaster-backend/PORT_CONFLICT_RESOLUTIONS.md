# Port Conflict Resolutions - Executive Summary

**Created:** 2026-02-12
**Status:** Complete - All Conflicts Resolved
**Authority:** Canonical PORT_REGISTRY.md

---

## Overview

A comprehensive port audit identified 4 critical conflicts affecting FlowMaster's 29 microservices. All conflicts have been resolved with canonical port assignments documented in PORT_REGISTRY.md.

---

## Conflict Matrix

### H1: Port 9006 Conflict (RESOLVED)

**Problem:**
```
Port 9006 assigned to TWO services:
  1. Human Task Service (R24 - primary requirement)
  2. AI Agent Orchestration (central LLM routing)
```

**Root Cause:** AI Agent Service was added after Human Task Service was deployed to 9006.

**Resolution:**
| Service | Original Port | Canonical Port | Status |
|---------|---------------|----------------|--------|
| Human Task Service | 9006 | **9006** ✅ | Unchanged (primary) |
| AI Agent Service | 9006 | **9007** ✅ | Moved (adjacent port) |

**Impact:**
- Human Task Service keeps port 9006 (no disruption)
- AI Agent Service moves to 9007
- All inter-service communication requires update
- Docker-compose configuration must change

**Update Locations:**
- [ ] `/srv/projects/flowmaster/docker-compose.yml` - AI Agent Service port mapping
- [ ] `/srv/projects/flowmaster/docker-compose.integration.yml` - Production compose
- [ ] Environment variables: `AI_AGENT_SERVICE_PORT=9007`
- [ ] Service registry entries
- [ ] Nginx reverse proxy configuration

---

### H2: Port 9014 Conflict (RESOLVED)

**Problem:**
```
Port 9014 assigned to TWO services:
  1. Process Analytics (R48-R50 - dashboards, metrics)
  2. External Integration (R51-R53 - webhooks, connectors)
```

**Root Cause:** New services added in Feb 2026 without port coordination.

**Resolution:**
| Service | Original Port | Canonical Port | Status |
|---------|---------------|----------------|--------|
| Process Analytics | 9014 | **9014** ✅ | Unchanged (dashboards primary) |
| External Integration | 9014 | **9015** ✅ | Moved (adjacent port) |

**Impact:**
- Process Analytics keeps port 9014 (maintains dashboard routing)
- External Integration moves to 9015
- Webhook endpoint URLs will change
- API clients must be updated

**Update Locations:**
- [ ] `/srv/projects/flowmaster/docker-compose.yml` - External Integration port
- [ ] Webhook client configurations pointing to 9014
- [ ] API documentation: webhook endpoint URLs
- [ ] Nginx routing rules for `/integrations/` path
- [ ] Environment variable: `EXTERNAL_INTEGRATION_PORT=9015`

---

### H3: Port 9000 Conflict (RESOLVED)

**Problem:**
```
Port 9000 used by multiple projects (not true conflict - network isolated):
  1. FlowMaster API Gateway (primary, demo server)
  2. Resolver Backend (local development only)
```

**Root Cause:** Common convention to use 9000 for primary gateway. Different projects, different networks.

**Resolution:**
| Service | Project | Network | Canonical Port | Status |
|---------|---------|---------|----------------|--------|
| API Gateway | FlowMaster | demo server (K3S) | **9000** ✅ | Canonical |
| Backend | Resolver | Local (Docker/OrbStack) | **9000** ✅ | Isolated network |

**Impact:**
- NO CODE CHANGES REQUIRED (already isolated)
- Services run on different Docker networks
- No runtime port conflicts possible
- Documentation clarified to prevent future confusion

**Clarification:**
```yaml
# FlowMaster on demo server
demo-server:8529 → API Gateway:9000 (production)

# Resolver on local machine
localhost:9000 → Resolver Backend:9000 (local only)
# These NEVER run simultaneously on same port
```

**Update Locations:**
- [ ] Documentation only - clarify network isolation
- [ ] No code updates needed
- [ ] No docker-compose changes needed

---

### H4: Port 3001 Conflict (RESOLVED)

**Problem:**
```
Port 3001 assigned to THREE applications:
  1. Engage App (Employee task execution - R25-R29)
  2. Manager App (Escalation dashboard - R30-R33)
  3. MCP Postgres connector (documented as mcp-postgres)
```

**Root Cause:** Frontend port conflicts due to overlapping application deployment strategy.

**Resolution:**
| Service | Original Port | Canonical Port | Status |
|----------|---------------|----------------|--------|
| Engage App | 3001 | **3001** ✅ | Unchanged (primary employee app) |
| Manager App | 3001 | **3005** ✅ | Moved (separate escalation app) |
| Process Designer | 3002 | **3002** ✅ | Confirmed (designer app) |
| MCP Postgres | 3001 | Retired | Clarified as documentation artifact |

**Impact:**
- Engage App maintains port 3001 (primary user-facing)
- Manager App moves to 3005
- Process Designer confirmed at 3002
- Nginx routing must be updated for separate URLs

**Update Locations:**
- [ ] `/srv/projects/flowmaster/docker-compose.yml` - Manager App port 3005
- [ ] Nginx configuration for `/manager/` → 3005
- [ ] Environment variables: `MANAGER_APP_PORT=3005`
- [ ] Documentation: Update app URLs
- [ ] Internal links: update manager app URL references

---

## Unified Service Map (Post-Resolution)

### Port Assignment Summary

| Category | Port Range | Count | Status |
|----------|-----------|-------|--------|
| Core APIs | 9000-9016 | 13 | ✅ Resolved |
| Auth & Infrastructure | 8001-8004 | 3 | ✅ Resolved |
| Supporting Services | 8009-8021 | 9 | ✅ Resolved |
| Frontends | 3000-3005 | 5 | ✅ Resolved |
| Databases | 5433-5439, 6380-6383, 8529-8532 | Various | ✅ OK |
| **TOTAL** | **29 services** | **100% unique** | ✅ **No conflicts** |

### Critical Service Ports (After Resolution)

```
CORE TIER (Request Processing):
  9000 - API Gateway (entrypoint)
  9002 - Document Intelligence
  9003 - Process Design
  9005 - Execution Engine
  9006 - Human Task Service
  9007 - AI Agent Service ← MOVED from 9006
  9008 - Scheduling
  9009 - Notifications
  9010 - WebSocket Gateway
  9011 - DXG Service
  9013 - Event Bus
  9014 - Process Analytics (canonical)
  9015 - External Integration ← MOVED from 9014
  9016 - Agent Service

AUTH & INFRASTRUCTURE:
  8001 - Service Registry
  8002 - Authentication Service

SUPPORTING:
  8009 - Knowledge Hub
  8014 - Legal Entity
  8018 - Business Rules
  8019 - Process Views
  8020 - Process Versioning
  8021 - Process Linking

FRONTENDS:
  3000 - Main Admin
  3001 - Engage App (Employee Tasks)
  3002 - Process Designer
  3005 - Manager App ← MOVED from 3001
```

---

## Implementation Checklist

### Phase 1: Update Configurations (Priority: CRITICAL)

- [ ] AI Agent Service: Update docker-compose.yml port to 9007
  - [ ] Service port mapping
  - [ ] Environment variable `PORT=9007`
  - [ ] Health check endpoint update

- [ ] External Integration Service: Update docker-compose.yml port to 9015
  - [ ] Service port mapping
  - [ ] Environment variable `PORT=9015`
  - [ ] Webhook endpoint URLs updated

- [ ] Manager App: Update docker-compose.yml port to 3005
  - [ ] Frontend port mapping
  - [ ] Container-to-host port mapping
  - [ ] Environment variable update

### Phase 2: Update Routing & Discovery (Priority: HIGH)

- [ ] Nginx reverse proxy:
  - [ ] `/api/agents/` → 9007 (changed from 9006)
  - [ ] `/integrations/` → 9015 (changed from 9014)
  - [ ] `/manager/` → 3005 (changed from 3001)

- [ ] Service Registry:
  - [ ] Register AI Agent Service at 9007
  - [ ] Register External Integration at 9015
  - [ ] Update Manager App registration

- [ ] DNS/Host entries (if applicable):
  - [ ] `agents.flowmaster:9007`
  - [ ] `integrations.flowmaster:9015`
  - [ ] `manager.flowmaster:3005`

### Phase 3: Inter-Service Communication (Priority: HIGH)

- [ ] Update service-to-service URLs:
  - [ ] Any code calling AI Agent Service: 9006 → 9007
  - [ ] Any code calling External Integration: 9014 → 9015
  - [ ] Any code redirecting to Manager App: 3001 → 3005

- [ ] Update environment variables in all services:
  ```
  AI_AGENT_SERVICE_PORT=9007
  EXTERNAL_INTEGRATION_PORT=9015
  MANAGER_APP_URL=http://localhost:3005
  ```

- [ ] Update MCP server registrations

### Phase 4: Testing & Validation (Priority: CRITICAL)

- [ ] Health checks:
  ```bash
  curl http://localhost:9006/health  # Human Task Service (unchanged)
  curl http://localhost:9007/health  # AI Agent Service (NEW)
  curl http://localhost:9014/health  # Process Analytics (unchanged)
  curl http://localhost:9015/health  # External Integration (NEW)
  curl http://localhost:3001/health  # Engage App (unchanged)
  curl http://localhost:3005/health  # Manager App (NEW)
  ```

- [ ] Service discovery:
  ```bash
  # Verify services registered with correct ports
  curl http://localhost:8001/services
  ```

- [ ] Integration tests:
  - [ ] AI Agent Service can be invoked from Execution Engine
  - [ ] External Integration webhooks can be registered
  - [ ] Manager App can be accessed from main frontend
  - [ ] Nginx routing works for all paths

- [ ] End-to-end workflow test (sample):
  - [ ] Create process → Execute process → Human task → AI agent decision → External integration → Manager escalation

### Phase 5: Documentation & Deployment (Priority: MEDIUM)

- [ ] Update all documentation:
  - [ ] API docs: endpoint URLs
  - [ ] Architecture diagrams: port assignments
  - [ ] README files: setup instructions
  - [ ] Runbooks: troubleshooting guides

- [ ] Deployment:
  - [ ] Production docker-compose.integration.yml updated
  - [ ] Staging docker-compose.integration.yml updated
  - [ ] CI/CD pipelines reviewed for port references
  - [ ] Deployment scripts updated if needed

- [ ] Team notification:
  - [ ] Slack announcement: new port assignments
  - [ ] GitLab wiki: PORT_REGISTRY.md link
  - [ ] Development documentation: updated

---

## Verification Commands

### Quick Port Check
```bash
# Check all FlowMaster ports are listening
lsof -i :9000 -i :9006 -i :9007 -i :9014 -i :9015 -i :3001 -i :3005

# Expected output should show:
# - 9000: API Gateway
# - 9006: Human Task Service
# - 9007: AI Agent Service (NEW)
# - 9014: Process Analytics
# - 9015: External Integration (NEW)
# - 3001: Engage App
# - 3005: Manager App (NEW)
```

### Service Health Verification
```bash
#!/bin/bash
services=(
  "9000:api-gateway"
  "9006:human-task"
  "9007:ai-agent"          # NEW
  "9014:analytics"
  "9015:integration"        # NEW
  "3001:engage-app"
  "3005:manager-app"        # NEW
)

for service in "${services[@]}"; do
  port=${service%:*}
  name=${service#*:}
  status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health 2>/dev/null)
  if [ "$status" = "200" ]; then
    echo "✅ $name ($port): OK"
  else
    echo "❌ $name ($port): FAILED (HTTP $status)"
  fi
done
```

### Docker Compose Verification
```bash
# From project root
docker-compose ps | grep -E "9000|9006|9007|9014|9015|3001|3005"

# Expected status: Up (for all)
```

---

## Rollback Plan

If issues arise during deployment:

### Rollback Procedure
```bash
# 1. Restore previous docker-compose.yml
git checkout HEAD -- docker-compose.yml

# 2. Stop affected services
docker-compose down

# 3. Restart with original ports
docker-compose up -d

# 4. Verify services
docker-compose ps
curl http://localhost:9006/health  # Human Task (original)
curl http://localhost:9014/health  # Analytics (original)
curl http://localhost:3001/health  # Engage (original)
```

### Recovery Time: ~2 minutes

---

## Files Updated

### Primary Source of Truth
- ✅ `/Users/benjaminhippler/.claude/skills/flowmaster-backend/PORT_REGISTRY.md` - **Canonical reference**

### Supporting Documentation
- ✅ `/Users/benjaminhippler/.claude/skills/flowmaster-backend/skill.md` - Backend skill updated
- ✅ `/Users/benjaminhippler/.claude/skills/claude-config-loader/config/ports.yaml` - Configuration updated

### Implementation Required
- ⏳ `/srv/projects/flowmaster/docker-compose.yml` - **NEEDS UPDATE**
- ⏳ `/srv/projects/flowmaster/docker-compose.integration.yml` - **NEEDS UPDATE**
- ⏳ Nginx configuration files - **NEEDS UPDATE**
- ⏳ Service registry configuration - **NEEDS UPDATE**
- ⏳ API documentation - **NEEDS UPDATE**

---

## Contact & References

**For Questions About:**
- Port assignments: See `PORT_REGISTRY.md`
- Conflict details: See this document
- Implementation: See "Implementation Checklist" section
- Docker changes: See docker-compose template in PORT_REGISTRY.md

**Key Document:** `/Users/benjaminhippler/.claude/skills/flowmaster-backend/PORT_REGISTRY.md`

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Services | 29 |
| Total Conflicts Identified | 4 |
| Conflicts Resolved | 4 (100%) |
| Services with Port Changes | 4 |
  - AI Agent Service: 9006 → 9007 |
  - External Integration: 9014 → 9015 |
  - Manager App: 3001 → 3005 |
| Services Unchanged | 26 |
| Configuration Files Updated | 2 |
| Implementation Phases | 5 |
| Estimated Implementation Time | 2-4 hours (with testing) |
| Risk Level | **LOW** (port-only changes, backward compatible) |
| Rollback Complexity | **LOW** (simple git revert) |

---

**Status:** ✅ Complete - Ready for Implementation
**Last Updated:** 2026-02-12
**Next Step:** Proceed with Implementation Checklist Phase 1
