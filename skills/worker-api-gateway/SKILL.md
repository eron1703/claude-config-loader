---
name: worker-api-gateway
description: API Gateway routing, Nginx configuration, and request flow patterns
disable-model-invocation: true
---

# Worker API Gateway Knowledge

## Request Flow Chain

```
Browser → Nginx (port 80) → API Gateway (port 9000) → Backend Service
```

## Nginx Configuration

**Location**: `/etc/nginx/sites-enabled/flowmaster` on demo server (65.21.153.235)

### Nginx Routes
- **`/`** → frontend-nextjs ClusterIP (10.43.185.219:3000)
- **`/api/`** → api-gateway ClusterIP (10.43.193.134:9000) — **preserves /api/ prefix**
- **`/ws/`** → websocket-gateway ClusterIP (10.43.43.253:9010)

### Critical Behavior
Nginx **preserves the `/api/` prefix** when proxying to the API Gateway:
- Browser request: `GET /api/v1/processes`
- Gateway receives: `GET /api/v1/processes` (prefix intact)
- Gateway rewrites per routing rules (see below)

## API Gateway Routing

**Tech Stack**: Python/FastAPI (NOT Node.js)
**Port**: 9000
**Health Endpoint**: `/health`

### Routing Rules
Gateway routes are stored in **ConfigMap**: `gateway-config` (routes.yaml)

**Routing Pattern**:
```
/v1/{service}/* → rewrites to /api/v1/{path} on target service
```

**Example Routes**:
```yaml
- path: /v1/process-design/*
  target: process-design:9003
  rewrite: /api/v1/processes/$1

- path: /v1/execution/*
  target: execution-engine:9005
  rewrite: /api/v1/execution/$1

- path: /v1/scheduling/*
  target: scheduling:9008
  rewrite: /api/v1/schedules/$1
```

### Request Flow Example
1. **Browser**: `GET /api/v1/processes`
2. **Nginx**: Proxies to `api-gateway:9000/api/v1/processes`
3. **Gateway**: Receives `/api/v1/processes`, matches route `/v1/process-design/*`
4. **Gateway**: Rewrites to `/api/v1/processes` and proxies to `process-design:9003`
5. **Backend**: `process-design` handles `/api/v1/processes`

## ConfigMap Management

### View Current Routes
```bash
ssh demo-server-root "kubectl get cm gateway-config -n flowmaster -o yaml"
```

### View Just routes.yaml
```bash
ssh demo-server-root "kubectl get cm gateway-config -n flowmaster -o jsonpath='{.data.routes\.yaml}'"
```

### Edit Routes
```bash
ssh demo-server-root "kubectl edit cm gateway-config -n flowmaster"
```

### Restart Gateway After Changes
```bash
ssh demo-server-root "kubectl rollout restart -n flowmaster deploy/api-gateway"
```

## ClusterIP Endpoints (Hardcoded in Nginx)

**WARNING**: These are hardcoded and will change if services are recreated.

- **Frontend**: 10.43.185.219:3000
- **API Gateway**: 10.43.193.134:9000
- **WebSocket Gateway**: 10.43.43.253:9010

### If Services Are Recreated
1. Run: `kubectl -n flowmaster get svc`
2. Find new ClusterIPs for frontend, api-gateway, websocket-gateway
3. Update `/etc/nginx/sites-enabled/flowmaster`
4. Reload Nginx: `systemctl reload nginx`

## Gateway Configuration Files

**ConfigMap Data Keys**:
- `routes.yaml` - Service routing rules
- `middleware.yaml` - Request/response middleware (if present)
- `auth.yaml` - Authentication/authorization rules (if present)

## Health Check

### Gateway Health
```bash
ssh demo-server-root "kubectl exec -n flowmaster deploy/api-gateway -- wget -qO- http://localhost:9000/health"
```

### Check Gateway Logs
```bash
ssh demo-server-root "kubectl logs -n flowmaster deploy/api-gateway --tail=50"
```

## Debugging Routes

### If Route Not Working
1. Check Nginx config: `ssh demo-server-root "cat /etc/nginx/sites-enabled/flowmaster"`
2. Check gateway logs: `kubectl logs -n flowmaster deploy/api-gateway`
3. Check ConfigMap: `kubectl get cm gateway-config -n flowmaster -o yaml`
4. Verify backend service is running: `kubectl -n flowmaster get pods | grep <service-name>`
5. Test directly to backend: `kubectl port-forward -n flowmaster svc/<service-name> 9003:9003`

## Key Facts
- Gateway is FastAPI (Python), not Node.js
- Nginx preserves `/api/` prefix in the proxying step
- Routes in ConfigMap control actual backend service mapping
- ClusterIPs are hardcoded and brittle (document if changed)
- Always restart gateway after ConfigMap changes
- WebSocket traffic goes through dedicated websocket-gateway service
