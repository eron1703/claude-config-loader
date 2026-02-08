---
name: flowmaster-server
description: "FlowMaster server configuration and infrastructure"
disable-model-invocation: false
---

# FlowMaster Server Configuration Skill

> **SNAPSHOT: 2026-02-08 11:00 Dubai Time (07:00 UTC) — likely changing soon**

## Server Architecture

### Servers Overview

| Server | IP | URL | Deployment | Status (Feb 8) |
|--------|-----|-----|-----------|----------------|
| **Demo** | 65.21.153.235 | — | K3S cluster | UP, 29 pods running |
| **Production** | 91.99.237.14 | app.flow-master.ai | Docker Compose | UP (HTTP 200) |
| **Staging** | 91.98.159.56 | staging.flow-master.ai | Docker Compose | DOWN (unreachable) |
| **Dev** | 91.98.159.56 | dev.flow-master.ai | Docker Compose | DOWN (unreachable) |

**SSH Access (Demo only):** `demo-server` (user: ben) or `demo-server-root` (user: root)
**OS:** Ubuntu 24.04.3 LTS

---

## Demo Server (65.21.153.235) — PRIMARY

### 1 FlowMaster Environment (no separate dev/test/staging on this server)

#### K3S FlowMaster Cluster
- **Namespace:** `flowmaster`
- **Pods:** 29 running / 30 deployments (data-intelligence scaled to 0)
- **Local Registry:** `localhost:30500` (K3S NodePort)
- **Total Memory:** ~1.65 GB across 29 pods

**Deployed Services (29):**

| Service | Image Tag | Port | Memory | Status |
|---------|-----------|------|--------|--------|
| agent-service | r36-r47 | 9016 | 56Mi | Running, UNTESTED |
| ai-agent | latest | 9006 | 341Mi | Running, UNTESTED |
| api-gateway | latest | 9000 | 50Mi | Running, UNTESTED |
| auth-service | ghcr.io latest | 8002 | 53Mi | Running, UNTESTED |
| bac-marketplace | r73 | 9015 | 54Mi | Running, UNTESTED |
| business-rules-engine | r69-fix | 8018 | 55Mi | Running, UNTESTED |
| document-intelligence | r01 | 9002 | 49Mi | Running, UNTESTED |
| dxg-service | r34-r35 | 9011 | 45Mi | Running, UNTESTED |
| engage-app | r27-r45 | 3001 | 92Mi | Running, UNTESTED |
| event-bus | latest | 9013 | 68Mi | Running, UNTESTED |
| execution-engine | r21-r24 | 9005 | 69Mi | Running, UNTESTED |
| external-integration | r51-fix3 | 9014 | 53Mi | Running, UNTESTED |
| frontend | ea2a29b | 3000 | 57Mi | Running, UNTESTED |
| human-task | r24 | 9006 | 63Mi | Running, UNTESTED |
| knowledge-hub | r42-r46 | 8009 | 23Mi | Running, UNTESTED |
| legal-entity-service | r66-fix | 8014 | 51Mi | Running, UNTESTED |
| manager-app | r30 | 3001 | 34Mi | Running, UNTESTED |
| mcp-server | latest | 9000 | 43Mi | Running, UNTESTED |
| notification | r23-final | 9009 | 60Mi | Running, UNTESTED |
| process-analytics | latest | 9014 | 71Mi | Running, UNTESTED |
| process-design | r03 | 9003 | 33Mi | Running, UNTESTED |
| process-designer | r77 | 3002 | 35Mi | Running, UNTESTED |
| process-linking | r63 | 8021 | 49Mi | Running, UNTESTED |
| process-versioning | r60-fix | 8020 | 48Mi | Running, UNTESTED |
| process-views | r57-fix | 8019 | 49Mi | Running, UNTESTED |
| prompt-engineering | r39 | 8012 | 59Mi | Running, UNTESTED |
| scheduling | 192c806d | 9008 | 64Mi | Running, UNTESTED |
| service-registry | ghcr.io latest | 8001 | 58Mi | Running, UNTESTED |
| websocket-gateway | 8ef0412c | 9010 | 38Mi | Running (4 restarts), UNTESTED |

**ExternalName services:** arangodb, postgres, redis (pointing to `databases` namespace)

#### SDX Platform (Part of FlowMaster, currently standalone Docker)
- **Location:** `/opt/sdx/`
- **Containers:** 3 (backend:8010, frontend:3010, mcp-server:8011)
- **Uptime:** 8+ days
- **Note:** Should be migrated into K3S cluster — currently runs as separate Docker containers but is part of the FlowMaster product

#### Shared Infrastructure
- **ArangoDB:** 1 container, port 8529, up 3 months (shared by FlowMaster + SDX)
- **Nginx:** Reverse proxy on port 80 to K3S ClusterIPs

---

### Plane CE (Separate — Project Management Tool, NOT part of product)
- **Location:** `/opt/plane/`
- **Containers:** 13 (proxy, web, admin, space, live, api, worker, beat-worker, db, redis, mq, minio, mcp-server)
- **Web UI:** http://65.21.153.235:8083 (UP)
- **MCP Server:** http://65.21.153.235:8012
- **Note:** plane-space container is UNHEALTHY


---

## Network Architecture (Demo Server)

```
Internet → Nginx (port 80)
  ├── / → frontend ClusterIP (10.43.185.219:3000)
  ├── /api/ → api-gateway ClusterIP (10.43.193.134:9000)
  └── /ws/ → websocket-gateway ClusterIP (10.43.43.253:9010)
```

**WARNING:** ClusterIPs are hardcoded in `/etc/nginx/sites-enabled/flowmaster`. They will change if K3S services are recreated.

### Nginx Config Location
- `/etc/nginx/sites-enabled/flowmaster`
- Proxy timeouts: 3600s for API (AI operations), 86400s for WebSocket

---

## Deployment Method (CURRENT)

### How Services Were Deployed (Feb 8, 2026)
Code was deployed via **manual docker pipeline**, NOT via GitLab CI/CD:
1. Code written locally (macOS arm64)
2. Docker images built with `--platform linux/amd64`
3. Images transferred via `docker save | gzip | scp`
4. Loaded on server via `docker load`
5. Pushed to K3S local registry (`localhost:30500`)
6. K3S deployments updated via `kubectl set image`

**Code has NOT been pushed to GitLab repositories.**

### CI/CD Pipeline (Available but not used for current deployment)

**Platform:** GitLab CI/CD
**Runner:** `flowmaster-demo-runner` v18.8.0, docker executor, privileged, active since 2026-02-03

**Pipeline Stages:**
```
detect-changes -> test -> build -> deploy
```

**Required GitLab CI/CD Variables:**
- `SSH_PRIVATE_KEY` — SSH key for server access (type: file)
- `DEMO_SERVER_1_HOST` — Server IP (65.21.153.235)
- Database vars: `ARANGO_HOST`, `POSTGRES_GLOBAL_HOST`, `REDIS_HOST` + credentials
- Security vars: `JWT_SECRET`, `ENCRYPTION_KEY`, `SECRET_KEY`
- API keys: `GEMINI_API_KEY`, `OPENAI_API_KEY`, `OPENROUTER_API_KEY`

All 14 K3S deployments have `imagePullPolicy: Always`.

---

## Directory Structure (Demo Server)

```
/opt/flowmaster-deployments/    # Legacy staging compose (not actively used)
    docker-compose.staging.yml

/opt/sdx/                       # SDX deployment (3 containers)
    docker-compose.yml

/opt/plane/                     # Plane CE (13 containers)
    docker-compose.yaml

/opt/plane-mcp-server/          # Plane MCP Server
    docker-compose.yml
```

K3S manages FlowMaster services (not Docker Compose).

---

## Production Server (91.99.237.14)

- **URL:** app.flow-master.ai
- **Status:** UP (HTTP 200)
- **Deployment:** Docker Compose, `production` branch
- **SSL:** Let's Encrypt
- **No SSH access** from local machine

---

## Staging/Dev Server (91.98.159.56)

- **URLs:** staging.flow-master.ai, dev.flow-master.ai
- **Status:** DOWN (unreachable, connection timeout)
- **Deployment:** Docker Compose

---

## Common Troubleshooting Commands

### K3S (Demo Server)
```bash
# Check all pods
kubectl get pods -n flowmaster

# Check specific pod logs
kubectl logs -n flowmaster deployment/api-gateway --tail 100

# Restart a deployment
kubectl rollout restart deployment/api-gateway -n flowmaster

# Update image
kubectl set image deployment/api-gateway api-gateway=localhost:30500/flowmaster/api-gateway:new-tag -n flowmaster

# Check services and ClusterIPs
kubectl get svc -n flowmaster

# Check resource usage
kubectl top pods -n flowmaster
```

### Nginx (Demo Server)
```bash
# Test config
sudo nginx -t

# Reload
sudo systemctl reload nginx

# View config
cat /etc/nginx/sites-enabled/flowmaster
```

### Docker (Demo Server - Plane/SDX)
```bash
# Check Plane containers
docker ps | grep plane

# Check SDX containers
docker ps | grep sdx

# Check ArangoDB
docker ps | grep arango
```

---

## When to Use This Skill

1. **Deploying FlowMaster** — understanding K3S cluster, image pipeline
2. **Managing infrastructure** — nginx, SSL, port allocation
3. **Debugging container issues** — pod logs, restarts, ClusterIP changes
4. **CI/CD pipeline work** — GitLab runner, deployment jobs
5. **Server access** — SSH patterns, directory structure
