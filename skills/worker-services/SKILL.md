---
name: worker-services
description: Complete catalog of 29 FlowMaster services with ports, health endpoints, and tech stack
disable-model-invocation: true
---

# Worker Services Knowledge

## FlowMaster Services Catalog

| Service | Port | Health Endpoint | Stack | Notes |
|---------|------|----------------|-------|-------|
| **api-gateway** | 9000 | `/health` | Python/FastAPI | Routes requests to backend services; ConfigMap-driven |
| **auth-service** | 8002 | `/health` | Node.js/Prisma | RBAC only, no user login; PostgreSQL backend |
| **ai-agent** | 9001 | `/health` | Python/FastAPI | AI agent orchestration; ArangoDB collections |
| **process-design** | 9003 | `/health` | Node.js | Process CRUD operations; BPMN storage |
| **execution-engine** | 9005 | `/health` | Python/FastAPI | Executes process instances; state management |
| **human-task** | 9006 | `/health` | Node.js | Task assignment and management |
| **scheduling** | 9008 | `/api/v1/schedules` | Node.js | Schedule management and triggers |
| **notification** | 9009 | `/health` | Node.js | Alerts and notifications delivery |
| **websocket-gateway** | 9010 | `/health` | Node.js | WebSocket proxy for real-time features |
| **event-bus** | 9013 | `/health` | Node.js | Event routing and distribution; requires REDIS_URL |
| **external-integration** | 9014 | `/health` | Python/FastAPI | Webhooks and external connectors |
| **document-intelligence** | 9002 | `/health` | Node.js | Document parsing and processing |
| **service-registry** | 8001 | `/health` | Node.js | Service discovery and health tracking |
| **dxg-service** | 9007 | `/health` | Python/FastAPI | Document generation service |
| **process-analytics** | 9015 | `/health` | Node.js | Process metrics and analytics (replaces data-intelligence) |
| **prompt-engineering** | 9011 | `/health` | Node.js | Prompt management and optimization |
| **knowledge-hub** | 9012 | `/health` | Node.js | RAG/knowledge base; document retrieval |
| **mcp-server** | 9016 | `/health` | Node.js | Unified MCP gateway for external tools |
| **business-rules-engine** | 8013 | `/health` | Node.js | DMN rules evaluation and storage |
| **bac-marketplace** | 8015 | `/health` | Node.js | Business-as-Code process marketplace |
| **legal-entity-service** | 8014 | `/health` | Python/FastAPI | Legal entity and organization management |
| **process-designer** | 9017 | `/health` | Node.js | Visual drag-and-drop process editor |
| **process-versioning** | 9018 | `/health` | Node.js | Version control for processes |
| **process-views** | 9019 | `/health` | Node.js | Saved/custom process views |
| **process-linking** | 9020 | `/health` | Node.js | Cross-process linking and composition |
| **manager-app** | 9021 | `/health` | Node.js | Manager dashboard and controls |
| **engage-app** | 9022 | `/health` | Node.js | Employee task interface |
| **frontend** | 3000 | `/` | Next.js 15 | Main UI; served via Nginx proxy |
| **data-intelligence** | — | — | — | **SCALED TO 0** (replaced by process-analytics) |

## Service Groupings by Function

### Core Infrastructure
- api-gateway (9000)
- service-registry (8001)
- websocket-gateway (9010)

### Authentication & Permissions
- auth-service (8002)

### Process Management
- process-design (9003)
- process-designer (9017)
- process-versioning (9018)
- process-views (9019)
- process-linking (9020)
- execution-engine (9005)

### Task & Workflow
- human-task (9006)
- scheduling (9008)
- event-bus (9013)

### AI & Knowledge
- ai-agent (9001)
- prompt-engineering (9011)
- knowledge-hub (9012)

### Analytics & Rules
- process-analytics (9015)
- business-rules-engine (8013)

### Integration & External
- external-integration (9014)
- mcp-server (9016)
- bac-marketplace (8015)

### Communication & Documents
- notification (9009)
- document-intelligence (9002)
- dxg-service (9007)

### Business & Org
- legal-entity-service (8014)

### Management & User Interface
- manager-app (9021)
- engage-app (9022)
- frontend (3000)

## Service Dependencies

### Databases
- **PostgreSQL**: auth-service (Prisma ORM)
- **ArangoDB**: ai-agent, process-design, execution-engine, knowledge-hub, business-rules-engine, process-analytics
- **Redis**: event-bus, ai-agent, prompt-engineering, scheduling (via REDIS_URL env var)

### Internal Communication
- **Event Bus**: All services publish/subscribe via event-bus:9013
- **Service Registry**: Services register with service-registry:8001
- **API Gateway**: All external requests route through api-gateway:9000

## Health Check Pattern

All services (except frontend) support `/health` endpoint:
```bash
ssh dev-01-root "kubectl exec -n flowmaster deploy/<service> -- wget -qO- http://localhost:<port>/health"
```

Example:
```bash
ssh dev-01-root "kubectl exec -n flowmaster deploy/execution-engine -- wget -qO- http://localhost:9005/health"
```

## Environment Variables (Common)

- **REDIS_URL**: `redis://redis.databases-test.svc.cluster.local:6379` (event-bus, ai-agent, scheduling)
- **DATABASE_URL**: PostgreSQL connection string (auth-service with Prisma)
- **ARANGODB_URL**: `http://arangodb.databases-test.svc.cluster.local:8529` (domain services)
- **API_GATEWAY_URL**: `http://api-gateway:9000` (for service-to-service calls)

## Monitoring & Troubleshooting

### Check All Pods Running
```bash
ssh dev-01-root "kubectl -n flowmaster get pods"
```

### Check Service Status
```bash
ssh dev-01-root "kubectl -n flowmaster describe svc <service-name>"
```

### View Service Logs
```bash
ssh dev-01-root "kubectl logs -n flowmaster deploy/<service-name> --tail=100"
```

### Test Service Connectivity
```bash
ssh dev-01-root "kubectl port-forward -n flowmaster svc/<service-name> <port>:<port>"
# Then: curl http://localhost:<port>/health
```

## Port Allocation Strategy

- **8000-8015**: Infrastructure and authentication (less frequent changes)
- **9000-9022**: Core services and applications (frequently deployed)
- **3000**: Frontend (Next.js standard)

## Key Facts
- 29 active services + 1 scaled to 0 (data-intelligence)
- Tech stack: Mix of Node.js/Express, Python/FastAPI, Next.js
- All K8S deployments have `imagePullPolicy: Always`
- Redis is required for async services (event-bus, scheduling)
- ArangoDB is primary for domain data
- PostgreSQL is for auth/RBAC only (smaller dataset)
- Health checks provide service availability visibility
