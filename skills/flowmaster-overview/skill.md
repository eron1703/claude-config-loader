---
name: flowmaster-overview
description: FlowMaster system overview and architecture
disable-model-invocation: false
---

# FlowMaster Microservices Platform Overview

> **SNAPSHOT: 2026-02-08 11:00 Dubai Time (07:00 UTC) — likely changing soon**

## Executive Summary

FlowMaster is a **microservices-based business process automation platform** for designing, executing, and monitoring workflows with AI integration. As of Feb 8 2026, **29 services are deployed and running** on a K3S Kubernetes cluster (demo server 65.21.153.235), covering all 79 requirements (R01-R79). Code is deployed but **ALL services are UNTESTED** — no integration, e2e, or health check testing has been performed.

**Source Control**: GitLab `flow-master` group (primary), mirrored to GitHub `HCB-Consulting-ME`.
**Code locations**: ~/projects/documentation (stale copies), ~/projects/flowmaster/ (working dir, not a git repo).

---

## Deployed Services (29 Running Pods — K3S)

### Core Business Logic (13 services)

| Service | Port | Tech | Status |
|---------|------|------|--------|
| **Process Design** | 9003 | Python/FastAPI | Running, UNTESTED |
| **Execution Engine** | 9005 | Python/FastAPI | Running, UNTESTED |
| **Human Task** | 9006 | Python/FastAPI | Running, UNTESTED |
| **AI Agent Orchestration** | 9006 | Python/FastAPI | Running, UNTESTED |
| **Document Intelligence** | 9002 | Python/FastAPI | Running, UNTESTED |
| **Authentication** | 8002 | Python/FastAPI | Running, UNTESTED |
| **API Gateway** | 9000 | Python/FastAPI | Running, UNTESTED |
| **Event Bus** | 9013 | Python/FastAPI+Kafka | Running, UNTESTED |
| **WebSocket Gateway** | 9010 | Node.js/TypeScript | Running (4 restarts), UNTESTED |
| **Notification** | 9009 | Python/FastAPI | Running, UNTESTED |
| **Scheduling** | 9008 | Python/FastAPI | Running, UNTESTED |
| **Service Registry** | 8001 | Python/FastAPI | Running, UNTESTED |
| **SSO** | — | Integrated w/ Auth | Working on demo |

### New Services (6, built Feb 2026)

| Service | Port | Requirements | Status |
|---------|------|-------------|--------|
| **Process Analytics** | 9014 | R48-R50 | Running, UNTESTED |
| **External Integration** | 9014 | R51-R53 | Running, UNTESTED |
| **MCP Server** | 9000 | R54-R56 | Running, UNTESTED |
| **Legal Entity** | 8014 | R66-R68 | Running, UNTESTED |
| **Business Rules Engine** | 8018 | R69-R72 | Running, UNTESTED |
| **BAC Marketplace** | 9015 | R73-R76 | Running, UNTESTED |

### Rebuilt/Revived Services (3)

| Service | Port | Requirements | Status |
|---------|------|-------------|--------|
| **Agent Service** | 9016 | R36-R47 | Running, UNTESTED |
| **Prompt Engineering** | 8012 | R39-R41 | Running, UNTESTED |
| **Knowledge Hub** | 8009 | R42-R46 | Running, UNTESTED |

### Frontend & Companion Apps (7)

| Service | Port | Requirements | Status |
|---------|------|-------------|--------|
| **Frontend (Next.js)** | 3000 | — | Running, UNTESTED |
| **Engage App** | 3001 | R25-R29, R45 | Running, UNTESTED |
| **Manager App** | 3001 | R30-R33 | Running, UNTESTED |
| **Process Designer** | 3002 | R77-R79 | Running, UNTESTED |
| **DXG Service** | 9011 | R34-R35 | Running, UNTESTED |
| **Process Views** | 8019 | R57-R59 | Running, UNTESTED |
| **Process Versioning** | 8020 | R60-R62 | Running, UNTESTED |
| **Process Linking** | 8021 | R63-R65 | Running, UNTESTED |

### Data Intelligence
- Scaled to 0 replicas (replaced by Process Analytics)

---

## Architecture & Data Patterns

### Deployment Model (CURRENT)
**K3S Kubernetes** on demo server (65.21.153.235):
- 29 pods in `flowmaster` namespace
- Local Docker registry: `localhost:30500`
- Images deployed via `docker save/gzip/scp/docker load` (NOT via CI/CD pipelines)
- Code NOT pushed to GitLab repos yet

### Network Architecture (Demo Server)
```
Internet → Nginx (port 80) → K3S ClusterIPs
  / → frontend (10.43.185.219:3000)
  /api/ → api-gateway (10.43.193.134:9000)
  /ws/ → websocket-gateway (10.43.43.253:9010)
```
WARNING: ClusterIPs are hardcoded in nginx config, will change if services recreated.

### Synchronous Communication
**HTTP REST via API Gateway** (port 9000):
- Frontend → API Gateway → Services
- Service-to-service calls (sync where needed)
- JWT validation at gateway + service level

### Asynchronous Communication
**Kafka Event Bus**:
- Services publish domain events (e.g., `task.created`, `execution.completed`)
- Event Bus routes via subscriptions (webhook delivery)

### Real-Time Streaming
**WebSocket (Socket.io) + Redis**:
- WebSocket Gateway (port 9010)
- Services publish to Redis channels
- Gateway broadcasts to connected clients

### Databases
- **ArangoDB**: Process definitions, task graphs (shared container, port 8529, 3 months uptime)
- **PostgreSQL**: Auth, executions, scheduling, notifications
- **Redis**: Caching, pub/sub, session management

---

## Key Concepts

### Process Explorer vs. Process Designer
- **Process Explorer**: Full experience - browse processes, view analytics, manage data
- **Process Designer**: Visual drag-and-drop editor (R77) that sits INSIDE the Explorer

### Architectural Decisions (D1-D18)
- **D1**: SSO KEEP (working on demo server)
- **D3**: Notification + Communication MERGE
- **D4**: AI Agent Service = Agent Orchestration
- **D5**: Learning Management → Agent Service (BUILT)
- **D6**: Prompt Engineering KEEP SEPARATE (BUILT)
- **D7**: Internal Data Hub = Knowledge Hub (REVIVED)
- **D8**: Observability SKIP FOR NOW
- **D9**: Permissions enhancement SKIP FOR NOW
- **D10**: SDX is MOST CRITICAL integration
- **D11**: DXG + Engage REPLACE human task execution UI
- **D12**: Process Explorer ≠ Process Designer
- **D13**: SDX REST-only internally; MCP via unified FlowMaster MCP Server
- **D14**: Agent learning from Engage feedback → Knowledge Hub → Agent Service loop
- **D15**: Process Analytics replaces empty Data Intelligence
- **D16**: BAC = process marketplace
- **D17**: Business Rules = first-class DMN-style objects
- **D18**: Process Designer = Visio-quality drag-and-drop with swimlanes + inline AI

---

## Deployment Servers

| Server | IP | URL | Status (Feb 8) |
|--------|-----|-----|----------------|
| **Demo** | 65.21.153.235 | — | UP, K3S, 29 pods |
| **Production** | 91.99.237.14 | app.flow-master.ai | UP (HTTP 200), Docker Compose |
| **Staging** | 91.98.159.56 | staging.flow-master.ai | DOWN (unreachable) |
| **Dev** | 91.98.159.56 | dev.flow-master.ai | DOWN (unreachable) |

---

## Tech Stack Summary

**Backend**: 11/13 core services Python/FastAPI, 2 Node.js/TypeScript
**Frontend**: Next.js, React, TypeScript, Radix UI (shadcn/ui), TailwindCSS
**Source Control**: GitLab (primary), GitHub (mirror)
**Container Orchestration**: K3S (demo), Docker Compose (prod/staging/dev)
**CI/CD**: GitLab CI, runner `flowmaster-demo-runner` v18.8.0

---

## Requirements Coverage (79 total)

All 79 requirements (R01-R79) have code written and deployed as Docker images.
**NONE are integration-tested.** See deployment-snapshot-20260208.md for full mapping.

---

## When to Use This Skill

1. **System Architecture**: Understanding service topology, communication patterns
2. **Service Dependencies**: Which services interact and how
3. **Technology Decisions**: Tech stack, databases, messaging
4. **Integration Planning**: Designing APIs or workflows
5. **Deployment Status**: What's running where
6. **Stakeholder Communication**: High-level system explanations

### Related Skills
- `flowmaster-backend` — API endpoints, service contracts
- `flowmaster-server` — Infrastructure, deployment, CI/CD
- `flowmaster-frontend` — UI components, patterns
- `flowmaster-database` — ArangoDB schema, collections
- `flowmaster-environment` — Service env vars, ports, config
- `flowmaster-tools` — MCP tools, integrations, SDX
