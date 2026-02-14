---
name: flowmaster-backend
description: "FlowMaster backend: 29 deployed services, REST APIs, Event Bus patterns, MCP integration"
disable-model-invocation: false
---

# FlowMaster Backend Architecture & APIs

> **SNAPSHOT: 2026-02-08 11:00 Dubai Time (07:00 UTC) — likely changing soon**

## Overview

FlowMaster is a modular microservices platform with **29 services deployed and running** on K3S (dev-01 server 65.21.153.235). All 79 requirements (R01-R79) have code deployed. **ALL services are UNTESTED** — no integration, health check, or e2e testing performed.

Each service owns its database and communicates via Event Bus (async) and REST APIs (sync).

---

## 13 Original Core Services

### 1. Process Design Service (Port 9003)
**Purpose:** Design, version, and manage process definitions
**Tech:** Python/FastAPI, ArangoDB
**Image:** r03 | **Reqs:** R03-R20
**Key Endpoints:**
- `POST /processes` — Create process definition
- `GET /processes/{id}` — Retrieve process
- `PUT /processes/{id}` — Update process
- `POST /processes/{id}/publish` — Publish version
- `GET /processes/{id}/versions` — List versions

### 2. Execution Engine (Port 9005)
**Purpose:** Execute processes, orchestrate tasks, manage state
**Tech:** Python/FastAPI, PostgreSQL + Redis
**Image:** r21-r24 | **Reqs:** R21-R24
**Key Endpoints:**
- `POST /executions` — Start execution
- `GET /executions/{id}` — Get execution state
- `PUT /executions/{id}/pause` — Pause
- `PUT /executions/{id}/resume` — Resume
- `GET /executions/{id}/history` — Event history

### 3. Human Task Service (Port 9006)
**Purpose:** Human-in-the-loop tasks for approvals, forms, decisions
**Tech:** Python/FastAPI, ArangoDB + Redis
**Image:** r24 | **Reqs:** R24
**Key Endpoints:**
- `POST /tasks` — Create task
- `GET /tasks/{id}` — Get task details
- `PUT /tasks/{id}/assign` — Assign
- `PUT /tasks/{id}/respond` — Submit response

### 4. AI Agent Orchestration (Port 9007)
**Purpose:** Central LLM/agent orchestrator with routing, caching, metering
**Tech:** Python + Express.js, PostgreSQL + Redis + ArangoDB
**Image:** latest
**Key Endpoints:**
- `POST /agents/{id}/invoke` — Call LLM
- `POST /agents/{id}/stream` — Stream response
**Port Assignment Note:** Canonical registry assigns port 9007 (conflict resolution H1)

### 5. Document Intelligence (Port 9002)
**Purpose:** Document → structured data, embeddings, searchable content
**Tech:** Python/FastAPI, ArangoDB
**Image:** r01 | **Reqs:** R01-R02
**Key Endpoints:**
- `POST /documents/upload` — Upload document
- `POST /documents/{id}/extract` — Extract entities

### 6. Authentication Service (Port 8002)
**Purpose:** JWT/OAuth auth with RBAC/ABAC
**Tech:** Python/FastAPI, PostgreSQL
**Image:** ghcr.io latest
**Key Endpoints:**
- `POST /auth/login` — Authenticate
- `POST /auth/refresh` — Refresh token
- `GET /auth/validate` — Validate token

### 7. API Gateway (Port 9000)
**Purpose:** Single entrypoint, dynamic routing, rate limiting
**Tech:** Python/FastAPI (NOT Node.js), Redis + ArangoDB
**Image:** latest
**Key Endpoints:** `*` (dynamic proxy routing)

### 8. Event Bus (Port 9013)
**Purpose:** Reliable event streaming with schema validation & replay
**Tech:** Python/FastAPI + Kafka
**Image:** latest
**Key Endpoints:**
- `POST /events` — Publish event
- `POST /subscriptions` — Subscribe
- `GET /events/replay` — Replay from timestamp

### 9. WebSocket Gateway (Port 9010)
**Purpose:** Real-time communication, presence, streaming
**Tech:** Node.js/TypeScript, Socket.io + Redis
**Image:** 8ef0412c (4 restarts)
**Key Endpoints:** `WS /connect`, `WS /channels/{id}/subscribe`

### 10. Notification Service (Port 9009)
**Purpose:** Email, SMS, push with templating & retry
**Tech:** Python/FastAPI, PostgreSQL
**Image:** r23-final
**Key Endpoints:**
- `POST /notifications/send` — Send notification
- `GET /notifications/{id}` — Get status

### 11. Scheduling Service (Port 9008)
**Purpose:** Cron triggers, time-based automation
**Tech:** Python/FastAPI, PostgreSQL (APScheduler)
**Image:** 192c806d
**Key Endpoints:**
- `POST /schedules` — Create schedule
- `POST /schedules/{id}/execute` — Trigger now

### 12. Service Registry (Port 8001)
**Purpose:** Service discovery and health monitoring
**Tech:** Python/FastAPI
**Image:** ghcr.io latest

### 13. SSO Service
**Purpose:** OAuth/SAML enterprise authentication
**Status:** Working on demo server (no dedicated repo)

---

## 6 New Services (Built Feb 2026)

### 14. Process Analytics (Port 9014)
**Purpose:** Process performance metrics, bottleneck detection
**Tech:** Python/FastAPI
**Image:** latest | **Reqs:** R48-R50
**Key Endpoints:**
- `GET /analytics/processes/{id}` — Process metrics
- `GET /analytics/dashboard` — Overview dashboard
- `POST /analytics/reports` — Generate report

### 15. External Integration (Port 9015)
**Purpose:** External system connectors, webhook management
**Tech:** Python/FastAPI
**Image:** r51-fix3 | **Reqs:** R51-R53
**Key Endpoints:**
- `POST /integrations` — Register integration
- `POST /integrations/{id}/execute` — Execute connector
- `POST /webhooks` — Register webhook
**Port Assignment Note:** Canonical registry assigns port 9015 (conflict resolution H2)

### 16. FlowMaster MCP Server (Port 9000)
**Purpose:** Unified MCP gateway for AI agent access to FlowMaster + SDX
**Tech:** Python/FastAPI
**Image:** latest | **Reqs:** R54-R56
**Key Endpoints:** MCP protocol (tool listing, tool execution)
**Note:** Shares port with API Gateway (9000) when proxied through nginx

### 17. Legal Entity Service (Port 8014)
**Purpose:** Organizational structure, legal entities, relationships
**Tech:** Python/FastAPI
**Image:** r66-fix | **Reqs:** R66-R68
**Key Endpoints:**
- `POST /entities` — Create legal entity
- `GET /entities/{id}` — Get entity
- `GET /entities/{id}/relationships` — Get relationships

### 18. Business Rules Engine (Port 8018)
**Purpose:** DMN-style decision tables, rule evaluation
**Tech:** Python/FastAPI
**Image:** r69-fix | **Reqs:** R69-R72
**Key Endpoints:**
- `POST /rules` — Create rule set
- `POST /rules/{id}/evaluate` — Evaluate rules
- `GET /rules/{id}/versions` — Rule versions

### 19. BAC Marketplace (Port 9016)
**Purpose:** Process marketplace — publish, download, share processes
**Tech:** Python/FastAPI
**Image:** r73 | **Reqs:** R73-R76
**Key Endpoints:**
- `POST /marketplace/publish` — Publish process
- `GET /marketplace/search` — Search marketplace
- `POST /marketplace/{id}/install` — Install process
**Port Assignment Note:** Uses 9016; Agent Service uses 9016 (see port registry for clarification)

---

## 3 Rebuilt/Revived Services

### 20. Agent Service (Port 9016)
**Purpose:** Agent personas, skills, learning from feedback
**Tech:** Python/FastAPI
**Image:** r36-r47 | **Reqs:** R36-R38, R45-R47
**Key Endpoints:**
- `POST /agents` — Create agent persona
- `POST /agents/{id}/learn` — Submit learning data
- `GET /agents/{id}/skills` — Get agent skills

### 21. Prompt Engineering (Port 8012)
**Purpose:** Prompt templates, versioning, dynamic assembly
**Tech:** Python/FastAPI
**Image:** r39 | **Reqs:** R39-R41
**Key Endpoints:**
- `POST /prompts` — Create template
- `POST /prompts/{id}/render` — Render with context
- `GET /prompts/{id}/versions` — Template versions

### 22. Knowledge Hub (Port 8009)
**Purpose:** RAG, knowledge management, agent data access
**Tech:** Python/FastAPI (revived from 38K lines internal-data-hub)
**Image:** r42-r46 | **Reqs:** R42-R44, R46
**Key Endpoints:**
- `POST /knowledge/query` — RAG query
- `POST /knowledge/ingest` — Ingest documents
- `POST /api/v1/feedback` — Feedback capture (R45)

---

## 7 Frontend & Companion Apps

### 23. Frontend (Port 3000)
**Purpose:** Main admin UI, process management
**Tech:** Next.js, React, TypeScript
**Image:** ea2a29b

### 24. Engage App (Port 3001)
**Purpose:** Employee task execution with DXG + AI chat
**Tech:** Next.js, React, TypeScript
**Image:** r27-r45 | **Reqs:** R25-R29, R45
**Key Features:** DXG briefing, analytics widgets, AI chat, feedback capture

### 25. Manager App (Port 3005)
**Purpose:** Agent escalation handling dashboard
**Tech:** Next.js, React, TypeScript
**Image:** r30 | **Reqs:** R30-R33
**Port Assignment Note:** Canonical registry assigns port 3005 (conflict resolution H4)

### 26. Process Designer (Port 3002)
**Purpose:** Visio-quality drag-and-drop BPMN editor
**Tech:** Next.js, React, TypeScript, ReactFlow
**Image:** r77 | **Reqs:** R77-R79
**Key Features:** Swimlane views, inline AI assistant, drag-and-drop

### 27. DXG Service (Port 9011)
**Purpose:** Dynamic Experience Generator — AI-powered UI from workflow context
**Tech:** Python/FastAPI
**Image:** r34-r35 | **Reqs:** R34-R35
**Key Endpoints:**
- `POST /api/v1/analyze/{task_id}` — Context analysis
- `POST /api/v1/smart-form/{task_id}` — Pre-filled form
- `POST /api/v1/briefing/{task_id}` — Case summary

### 28. Process Views (Port 8019)
**Purpose:** Flow chart views, process visualization
**Tech:** Python/FastAPI
**Image:** r57-fix | **Reqs:** R57-R59

### 29. Process Versioning (Port 8020)
**Purpose:** Process version management, diff, branching
**Tech:** Python/FastAPI
**Image:** r60-fix | **Reqs:** R60-R62

### 30. Process Linking (Port 8021)
**Purpose:** Cross-process dependencies and linking
**Tech:** Python/FastAPI
**Image:** r63 | **Reqs:** R63-R65

---

## Cross-Service Patterns

### Authentication
All API calls must include:
```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
X-Service-Name: {serviceName} (service-to-service)
```

### Database Connectivity
- Each service owns its database
- Cross-service data via Event Bus (async) or REST APIs (sync)
- Shared infrastructure: ArangoDB (port 8529), PostgreSQL, Redis

### Service Structure (Standard)
```
src/
├── api/            # HTTP controllers
├── core/           # Business logic
├── domain/         # Entity models
├── infra/
│   ├── db/         # Database repository
│   ├── messaging/  # Event Bus integration
│   ├── cache/      # Redis adapter
│   └── http/       # External service clients
├── config/         # Environment & DI
├── security/       # Auth/RBAC
└── utils/          # Helpers
```

---

## Testing Status: ALL UNTESTED

**What was done:**
- Code written for all 79 requirements
- Docker images built (macOS arm64 → linux/amd64 cross-compile)
- Images transferred via docker save/gzip/scp/docker load
- Pushed to K3S local registry
- Pod status confirmed Running via kubectl

**What was NOT done:**
- No HTTP health check verification
- No integration testing
- No end-to-end workflow testing
- No database schema verification
- No API contract testing
- Code NOT pushed to GitLab

---

## Source Control
- **Primary:** GitLab (`flow-master` group, private)
- **Mirror:** GitHub (`HCB-Consulting-ME` org)

---

## Port Registry & Conflict Resolution

**IMPORTANT:** All port assignments have been canonicalized in PORT_REGISTRY.md to resolve conflicts:

### Conflicts Resolved

| Issue | Resolution | Status |
|-------|-----------|--------|
| **H1: Port 9006** | Human Task Service (9006) + AI Agent Service (9007) | ✅ Resolved |
| **H2: Port 9014** | Process Analytics (9014) + External Integration (9015) | ✅ Resolved |
| **H3: Port 9000** | API Gateway (9000) canonical assignment | ✅ Resolved |
| **H4: Port 3001** | Engage App (3001) + Manager App (3005) + Designer (3002) | ✅ Resolved |

### Quick Port Reference

**Core Services:**
- `9000` - API Gateway (entrypoint)
- `9002` - Document Intelligence
- `9003` - Process Design
- `9005` - Execution Engine
- `9006` - Human Task Service
- `9007` - AI Agent Service (NEW ASSIGNMENT)
- `9008` - Scheduling
- `9009` - Notifications
- `9010` - WebSocket Gateway
- `9011` - DXG Service
- `9013` - Event Bus
- `9014` - Process Analytics
- `9015` - External Integration (NEW ASSIGNMENT)
- `9016` - Agent Service

**Authentication & Infrastructure:**
- `8001` - Service Registry
- `8002` - Authentication
- `8009` - Knowledge Hub
- `8014` - Legal Entity Service
- `8018` - Business Rules Engine
- `8019` - Process Views
- `8020` - Process Versioning
- `8021` - Process Linking

**Frontends:**
- `3000` - Main Frontend
- `3001` - Engage App
- `3002` - Process Designer
- `3005` - Manager App

**See PORT_REGISTRY.md for complete details**

---

## When to Use This Skill

1. **Building MCP server interactions** with FlowMaster APIs
2. **Designing process workflows** — Process Design Service
3. **Handling execution logic** — Execution Engine
4. **Human tasks** — approval flows
5. **AI/LLM integration** — AI Agent Service (9007)
6. **Real-time updates** — WebSocket Gateway
7. **Authentication** — JWT patterns
8. **Event-driven architecture** — Event Bus topics
9. **Document processing** — Document Intelligence
10. **Process analytics** — dashboards and metrics (9014)
11. **External integrations** — connectors and webhooks (9015)
12. **Business rules** — DMN decision tables
13. **Process marketplace** — BAC publish/download

---

## Documentation References

- **PORT_REGISTRY.md** - Canonical port assignments (THIS FILE'S COMPANION)
- **CONFLICT RESOLUTIONS** - See PORT_REGISTRY.md sections H1-H4
- **Service Updates Needed:**
  - AI Agent Service: Update to port 9007
  - External Integration: Update to port 9015
  - Manager App: Update to port 3005
