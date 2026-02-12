# PORT_REGISTRY.md - Canonical Port Registry for FlowMaster & All Services

**Version:** 1.0
**Last Updated:** 2026-02-12
**Status:** Canonical Single Source of Truth

---

## Overview

This document serves as the **definitive, single source of truth** for all port assignments across FlowMaster and associated infrastructure. All conflicts have been identified and resolved with canonical assignments.

## Conflict Resolution Summary

| Conflict | Port(s) | Services | Resolution |
|----------|---------|----------|-----------|
| **H1: Port 9006 Conflict** | 9006 | Human Task Service vs AI Agent Orchestration | Assign: Human Task Service = 9006, AI Agent Service = 9007 |
| **H2: Port 9014 Conflict** | 9014 | Process Analytics vs External Integration | Assign: Process Analytics = 9014, External Integration = 9015 |
| **H3: Port 9000 Conflict** | 9000 | API Gateway (multiple) | Assign: FlowMaster API Gateway = 9000, Resolver Backend = separate (9000 local only) |
| **H4: Port 3001 Conflict** | 3001 | Engage App vs Employee Frontend vs Manager App | Assign: Engage Frontend = 3010, Employee App = 3001, Manager App = 3005 |

---

## FlowMaster 29 Microservices - Complete Port Assignments

### Core Services (13 Original)

#### Group 1: Process Management (Ports 9002-9003)
| # | Service | Port | Tech | Database | Status | Notes |
|---|---------|------|------|----------|--------|-------|
| 1 | Document Intelligence | 9002 | Python/FastAPI | ArangoDB | Active | R01-R02: Entity extraction, embeddings |
| 2 | Process Design Service | 9003 | Python/FastAPI | ArangoDB | Active | R03-R20: Process definitions, versioning |

#### Group 2: Execution & Workflow (Ports 9005-9010)
| # | Service | Port | Tech | Database | Status | Notes |
|---|---------|------|------|----------|--------|-------|
| 3 | Execution Engine | 9005 | Python/FastAPI | PostgreSQL + Redis | Active | R21-R24: Task orchestration, state management |
| 4 | Human Task Service | **9006** | Python/FastAPI | ArangoDB + Redis | Active | R24: Human-in-the-loop, approvals, forms |
| 5 | AI Agent Service | **9007** | Python + Express | PostgreSQL + Redis + ArangoDB | Active | Central LLM/agent orchestrator |
| 6 | Scheduling Service | 9008 | Python/FastAPI | PostgreSQL | Active | R25-R29: Cron triggers, time-based automation |
| 7 | Notification Service | 9009 | Python/FastAPI | PostgreSQL | Active | R23-final: Email, SMS, push with retry |
| 8 | WebSocket Gateway | 9010 | Node.js/TypeScript | Redis | Active | Real-time communication, Socket.io |

#### Group 3: Infrastructure (Ports 9013 & Auth Services)
| # | Service | Port | Tech | Database | Status | Notes |
|---|---------|------|------|----------|--------|-------|
| 9 | Event Bus | 9013 | Python/FastAPI + Kafka | Kafka | Active | Event streaming, schema validation, replay |
| 10 | API Gateway | 9000 | Python/FastAPI | Redis + ArangoDB | Active | Single entrypoint, dynamic routing, rate limiting |
| 11 | Service Registry | 8001 | Python/FastAPI | In-memory | Active | Service discovery, health monitoring |
| 12 | Authentication Service | 8002 | Python/FastAPI | PostgreSQL | Active | JWT/OAuth, RBAC/ABAC |
| 13 | SSO Service | N/A | (Enterprise) | N/A | Demo Server | OAuth/SAML integration |

### New Services (6 Built Feb 2026)

#### Group 4: Analytics & Integration (Ports 9014-9015)
| # | Service | Port | Tech | Database | Status | Notes |
|---|---------|------|------|----------|--------|-------|
| 14 | Process Analytics | **9014** | Python/FastAPI | PostgreSQL | Active | R48-R50: Performance metrics, bottleneck detection |
| 15 | External Integration | **9015** | Python/FastAPI | PostgreSQL | Active | R51-R53: Connectors, webhook management |

#### Group 5: Advanced Features (Ports 8014-8021)
| # | Service | Port | Tech | Database | Status | Notes |
|---|---------|------|------|----------|--------|-------|
| 16 | Legal Entity Service | 8014 | Python/FastAPI | PostgreSQL | Active | R66-R68: Org structure, relationships |
| 17 | Business Rules Engine | 8018 | Python/FastAPI | PostgreSQL | Active | R69-R72: DMN decision tables |
| 18 | Process Views | 8019 | Python/FastAPI | PostgreSQL | Active | R57-R59: Flow visualization |
| 19 | Process Versioning | 8020 | Python/FastAPI | PostgreSQL | Active | R60-R62: Version management, diff, branching |
| 20 | Process Linking | 8021 | Python/FastAPI | PostgreSQL | Active | R63-R65: Cross-process dependencies |

#### Group 6: Marketplace & AI Features
| # | Service | Port | Tech | Database | Status | Notes |
|---|---------|------|------|----------|--------|-------|
| 21 | BAC Marketplace | 9015 | Python/FastAPI | PostgreSQL | Active | R73-R76: Publish, download, share processes |
| 22 | Agent Service | 9016 | Python/FastAPI | PostgreSQL | Active | R36-R38, R45-R47: Agent personas, skills |
| 23 | Prompt Engineering | 8012 | Python/FastAPI | PostgreSQL | Active | R39-R41: Prompt templates, versioning |
| 24 | Knowledge Hub | 8009 | Python/FastAPI | PostgreSQL | Active | R42-R44, R46: RAG, knowledge management |
| 25 | DXG Service | 9011 | Python/FastAPI | Redis | Active | R34-R35: Dynamic Experience Generator |

### Frontend & UI Applications (5 Services)

| # | Service | Port | Tech | Status | Notes |
|---|---------|------|------|--------|-------|
| 26 | Frontend | 3000 | Next.js/React/TS | Active | Main admin UI, process management |
| 27 | Engage App | **3001** | Next.js/React/TS | Active | R25-R29, R45: Employee task execution with DXG |
| 28 | Manager App | 3005 | Next.js/React/TS | Active | R30-R33: Agent escalation dashboard |
| 29 | Process Designer | 3002 | Next.js/React/TS | Active | R77-R79: Visio-quality BPMN editor |
| 30 | FlowMaster MCP | 9000 | Python/FastAPI | Active | R54-R56: Unified MCP gateway |

---

## Detailed Port Assignment Table (Chronological by Port)

### Ports 3000-3099 (Frontend Development Servers)

| Port | Service | Project | Container | Status |
|------|---------|---------|-----------|--------|
| 3000 | Frontend | flowmaster | frontend | Running |
| 3001 | Engage App | flowmaster | engage-frontend | Running |
| 3002 | Process Designer | flowmaster | process-designer | Running |
| 3005 | Manager App | flowmaster | manager-app | Running |
| 3006 | DXG Frontend | dxg | dxg-frontend | Local dev |
| 3010 | Engage Frontend | engage | engage-frontend | Local dev |
| 3011 | SDX Frontend | sdx | sdx-frontend | Local dev |

### Ports 5432-5439 (PostgreSQL Databases)

| Port | Service | Project | Status | Notes |
|------|---------|---------|--------|-------|
| 5432 | PostgreSQL Core | engage | Local | General PostgreSQL |
| 5433 | FlowMaster Auth DB | flowmaster | Demo Server | Authentication data |
| 5434 | Documentation | documentation | Local | Workflow data |
| 5435 | FlowMaster Global DB | flowmaster | Demo Server | Shared data |
| 5436 | Air Cargo DB | flowmaster | Demo Server | Specialized data |
| 5437 | Employee DB | flowmaster | Demo Server | Employee data |
| 5438 | DXG DB | dxg | Local | DXG data |
| 5439 | NetBox DB | resolver | Local | Network inventory |

### Ports 6379-6383 (Redis Cache)

| Port | Service | Project | Status | Notes |
|------|---------|---------|--------|-------|
| 6379 | Redis Default | engage, documentation | Local | General cache |
| 6380 | FlowMaster Message | flowmaster | Demo Server | Message queue |
| 6381 | DXG Cache | dxg | Local | DXG cache |
| 6383 | FlowMaster Cache | flowmaster | Demo Server | Session cache |

### Ports 8000-8099 (Backend APIs & Services)

| Port | Service | Type | Status | Notes |
|------|---------|------|--------|-------|
| 8000 | Claude Pod Health | health | K3S | LiteLLM proxy health |
| 8001 | Service Registry | core | Active | Service discovery |
| 8002 | Authentication | core | Active | Auth service |
| 8004 | Guard Mobile Backend | special | Active | Mobile backend |
| 8005 | DXG Backend | special | Local | DXG API |
| 8006 | Notification (doc) | reference | — | Documentation only |
| 8009 | Knowledge Hub | core | Active | RAG, knowledge management |
| 8010 | Integration Hub | special | Active | External integrations |
| 8011 | SDX MCP Server | special | Demo Server | 40 tools loaded |
| 8012 | Plane MCP Server | special | Demo Server | Project management |
| 8013 | Claude Pod Health | health | K3S | Health endpoint |
| 8014 | Legal Entity Service | core | Active | Org structure |
| 8018 | Business Rules | core | Active | DMN decision tables |
| 8019 | Process Views | core | Active | Process visualization |
| 8020 | Process Versioning | core | Active | Version management |
| 8021 | Process Linking | core | Active | Cross-process deps |
| 8080 | NetBox UI | special | Local | Network analysis |
| 8083 | Plane Web UI | special | Demo Server | Project mgmt UI |
| 8099 | Agent Chat | special | Demo Server | K3S agent chat |

### Ports 8529-8532 (ArangoDB)

| Port | Service | Project | Status | Notes |
|------|---------|---------|--------|-------|
| 8529 | ArangoDB Main | shared | Demo Server | resolver, commander, documentation |
| 8530 | ArangoDB Web UI | shared | Demo Server | Web interface for 8529 |
| 8531 | FlowMaster ArangoDB | flowmaster | Demo Server | Dedicated instance |
| 8532 | FlowMaster ArangoDB Web | flowmaster | Demo Server | Web UI for 8531 |

### Ports 9000-9099 (Microservices & Gateway)

| Port | Service | Component | Status | Notes |
|------|---------|-----------|--------|-------|
| **9000** | **API Gateway** | **Core** | **Active** | Single entrypoint, dynamic routing |
| 9001 | Auth Service (doc) | reference | — | Documentation reference (see 8002) |
| 9002 | Document Intelligence | Core | Active | Entity extraction, embeddings |
| 9003 | Process Design | Core | Active | Process definitions |
| 9004 | (Reserved) | — | — | Future use |
| 9005 | Execution Engine | Core | Active | Task orchestration |
| **9006** | **Human Task Service** | **Core** | **Active** | Human-in-the-loop, approvals |
| **9007** | **AI Agent Service** | **Core** | **Active** | LLM orchestrator (NEWLY ASSIGNED) |
| 9008 | Scheduling Service | Core | Active | Cron triggers |
| 9009 | Notification Service | Core | Active | Email, SMS, push |
| 9010 | WebSocket Gateway | Core | Active | Real-time communication |
| 9011 | DXG Service | Special | Active | Dynamic Experience Generator |
| 9012 | (Reserved) | — | — | Future use |
| 9013 | Event Bus | Core | Active | Event streaming, Kafka |
| **9014** | **Process Analytics** | **Core** | **Active** | Performance metrics (NEWLY ASSIGNED) |
| **9015** | **External Integration** | **Core** | **Active** | Webhook management (NEWLY ASSIGNED) |
| 9016 | Agent Service | Core | Active | Agent personas, skills |
| 9017-9099 | (Reserved) | — | — | Future expansion |

---

## Conflict Resolution Documentation

### Conflict H1: Port 9006 - Human Task Service vs AI Agent Orchestration

**Problem:**
- Human Task Service: R24 requires port 9006 for human approvals/forms
- AI Agent Orchestration: Originally proposed for port 9006 for central LLM routing

**Resolution:**
- ✅ **Human Task Service: Port 9006** (primary function: human-in-the-loop tasks)
- ✅ **AI Agent Service: Port 9007** (central LLM orchestrator, originally 9006)

**Rationale:** Human Task Service was deployed first on port 9006. AI Agent Service is a newer orchestrator that can use the adjacent port.

**Impact:** Update AI Agent Service to listen on 9007 in all configurations.

---

### Conflict H2: Port 9014 - Process Analytics vs External Integration

**Problem:**
- Process Analytics: R48-R50 metrics and dashboards
- External Integration: R51-R53 webhooks and connectors

**Resolution:**
- ✅ **Process Analytics: Port 9014** (primary: dashboards, bottleneck detection)
- ✅ **External Integration: Port 9015** (webhooks, connectors, integration hub)

**Rationale:** Sequential assignment maintains logical port grouping for related services.

**Impact:** External Integration moves from 9014 to 9015 in all docker-compose and configs.

---

### Conflict H3: Port 9000 - API Gateway

**Problem:**
- FlowMaster API Gateway: Primary entrypoint (9000)
- Resolver Backend: Also uses 9000 locally
- Documentation: References 9000 as generic gateway port

**Resolution:**
- ✅ **FlowMaster API Gateway: Port 9000** (canonical on demo server)
- ✅ **Resolver Backend: Port 9000** (local only, isolated Docker network)
- ✅ **Documentation references updated to clarify context**

**Rationale:** Services run in isolation. Resolver only runs locally; FlowMaster on demo server.

**Impact:** No code changes needed; clarify in docker-compose that these are network-isolated.

---

### Conflict H4: Port 3001 - Engage App vs Employee Frontend vs Manager App

**Problem:**
- Engage App: Originally requested port 3001
- Employee App: Also attempting port 3001
- Manager App: Conflict with both

**Resolution:**
- ✅ **Engage App (Employee Task Execution): Port 3001** (per requirements R25-R29)
- ✅ **Manager App (Escalation Dashboard): Port 3005** (per requirements R30-R33)
- ✅ **Process Designer: Port 3002** (per requirements R77-R79)

**Rationale:** Engage App is primary employee-facing app and gets the standard port. Manager App moved to adjacent port. These are discrete applications with separate concerns.

**Impact:** Update docker-compose and nginx routing for port assignments.

---

## Master Port Allocation Map

### By Service Type

#### Core Microservices (Ports 9000-9016)
```
9000 - API Gateway (entrypoint)
9002 - Document Intelligence
9003 - Process Design
9005 - Execution Engine
9006 - Human Task Service
9007 - AI Agent Service
9008 - Scheduling
9009 - Notifications
9010 - WebSocket Gateway
9011 - DXG Service
9013 - Event Bus
9014 - Process Analytics
9015 - External Integration
9016 - Agent Service
```

#### Authentication & Infrastructure (Ports 8001-8004)
```
8001 - Service Registry
8002 - Authentication Service
8004 - Guard Mobile Backend
```

#### Supporting Services (Ports 8009-8021)
```
8009 - Knowledge Hub
8010 - Integration Hub (general)
8011 - SDX MCP Server
8012 - Plane MCP Server
8014 - Legal Entity Service
8018 - Business Rules Engine
8019 - Process Views
8020 - Process Versioning
8021 - Process Linking
```

#### Frontends (Ports 3000-3006)
```
3000 - Main Frontend
3001 - Engage App (Employee Tasks)
3002 - Process Designer
3005 - Manager App
3006 - DXG Frontend
```

#### Databases (Ports 5433-5439, 6380-6383, 8529-8532)
```
PostgreSQL: 5433-5439
Redis: 6380-6383
ArangoDB: 8529-8532
```

---

## Docker Compose Configuration Requirements

### Service Configuration Template

```yaml
services:
  # Core API Gateway
  flowmaster-api-gateway:
    ports:
      - "9000:9000"
    environment:
      - PORT=9000
      - SERVICE_NAME=api-gateway

  # Human Task Service
  flowmaster-human-task-service:
    ports:
      - "9006:9006"
    environment:
      - PORT=9006
      - SERVICE_NAME=human-task-service

  # AI Agent Service (NEWLY ASSIGNED)
  flowmaster-ai-agent-service:
    ports:
      - "9007:9007"  # NEW PORT ASSIGNMENT
    environment:
      - PORT=9007
      - SERVICE_NAME=ai-agent-service

  # Process Analytics (NEWLY ASSIGNED)
  flowmaster-process-analytics:
    ports:
      - "9014:9014"  # NEW ASSIGNMENT
    environment:
      - PORT=9014
      - SERVICE_NAME=process-analytics

  # External Integration (NEWLY ASSIGNED)
  flowmaster-external-integration:
    ports:
      - "9015:9015"  # NEW ASSIGNMENT
    environment:
      - PORT=9015
      - SERVICE_NAME=external-integration

  # Engage App (Employee Frontend)
  engage-app:
    ports:
      - "3001:3000"  # Container runs on 3000, external 3001
    environment:
      - NEXT_PUBLIC_API_PORT=9000

  # Manager App
  manager-app:
    ports:
      - "3005:3000"  # Container runs on 3000, external 3005
    environment:
      - NEXT_PUBLIC_API_PORT=9000
```

---

## Service-to-Service Communication

### Internal Communication (Docker Container Names)

Services communicate via container names on the internal network:

```
API Gateway → authentication:8002
API Gateway → human-task-service:9006
API Gateway → ai-agent-service:9007
API Gateway → process-design:9003
Execution Engine → event-bus:9013
DXG Service → execution-engine:9005
Process Analytics → execution-engine:9005
External Integration → event-bus:9013
WebSocket Gateway → event-bus:9013 (via Redis)
```

### External Communication (Localhost/IP)

Clients and external services use port mappings:

```
http://localhost:9000  → API Gateway
http://localhost:3001  → Engage App
http://localhost:3005  → Manager App
http://65.21.153.235:9000  → Demo Server API Gateway
```

---

## Nginx Reverse Proxy Configuration

### Location Mappings

```nginx
# Port 80/443 → Service Routing
/api/v1/          → 9000 (API Gateway)
/tasks/           → 9006 (Human Task Service)
/agents/          → 9007 (AI Agent Service)
/analytics/       → 9014 (Process Analytics)
/integrations/    → 9015 (External Integration)
/processes/       → 9003 (Process Design)
/executions/      → 9005 (Execution Engine)
/notifications/   → 9009 (Notification Service)
/ws/              → 9010 (WebSocket Gateway)
/events/          → 9013 (Event Bus)
/rules/           → 8018 (Business Rules)
/entities/        → 8014 (Legal Entity)
/knowledge/       → 8009 (Knowledge Hub)
/app/             → 3001 (Engage App)
/manager/         → 3005 (Manager App)
/designer/        → 3002 (Process Designer)
```

---

## Health Check Endpoints

Each service should expose health check endpoints on its assigned port:

```
GET http://localhost:9000/health     → API Gateway
GET http://localhost:9006/health     → Human Task Service
GET http://localhost:9007/health     → AI Agent Service
GET http://localhost:9014/health     → Process Analytics
GET http://localhost:9015/health     → External Integration
GET http://localhost:8002/health     → Authentication
GET http://localhost:9013/health     → Event Bus
```

---

## Port Availability Verification

### Check Port Status

```bash
# List all FlowMaster services and ports
lsof -i :9000 -i :9006 -i :9007 -i :9014 -i :9015 -i :8001 -i :8002

# Verify specific port
lsof -i :9006

# Test connectivity
curl http://localhost:9006/health
curl http://localhost:9007/health
curl http://localhost:9014/health
curl http://localhost:9015/health
```

---

## Migration Guide

### For Services Moving to New Ports

#### AI Agent Service: 9006 → 9007

1. Update `docker-compose.yml`:
   ```yaml
   ports:
     - "9007:9007"  # Changed from 9006
   ```

2. Update environment variables:
   ```
   PORT=9007
   ```

3. Update service registry entries

4. Update inter-service references in other services

5. Update nginx routing

#### External Integration Service: 9014 → 9015

1. Update `docker-compose.yml`:
   ```yaml
   ports:
     - "9015:9015"  # Changed from 9014
   ```

2. Update environment variables:
   ```
   PORT=9015
   ```

3. Update webhook endpoints pointing to this service

4. Update API documentation

---

## Future Port Planning

### Reserved Ranges

- **9004**: Reserved for future core service
- **9012**: Reserved for future core service
- **9017-9099**: Available for expansion

### Expansion Strategy

- If adding services: Use next available port in range
- Document new services in this registry immediately
- Notify team of changes via commit message
- Update nginx routing when adding new services

---

## Verification Checklist

- [ ] All 29 services assigned unique ports
- [ ] No port conflicts in master table
- [ ] Docker-compose reflects canonical ports
- [ ] Health check endpoints verified
- [ ] Nginx routing updated
- [ ] Service registry updated
- [ ] Inter-service communication verified
- [ ] External APIs documented
- [ ] Conflict resolutions documented
- [ ] Team notified of changes

---

## References

**Related Documentation:**
- `/Users/benjaminhippler/.claude/skills/claude-config-loader/config/ports.yaml` - Legacy port config
- `/Users/benjaminhippler/.claude/skills/flowmaster-backend/skill.md` - Backend service architecture
- `/srv/projects/flowmaster/docker-compose.integration.yml` - Production deployment
- `~/projects/flowmaster/docker-compose.yml` - Local development

**Last Reviewed:** 2026-02-12
**Canonical Source:** `/Users/benjaminhippler/.claude/skills/flowmaster-backend/PORT_REGISTRY.md`
