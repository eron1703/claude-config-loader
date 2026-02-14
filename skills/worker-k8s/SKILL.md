---
name: worker-k8s
description: K3S cluster configuration, kubectl patterns, and registry information
disable-model-invocation: true
---

# Worker K8S Knowledge

## K3S Cluster on Dev Server (65.21.153.235)

### Cluster Info
- **Type**: K3S (single-node Kubernetes)
- **Namespaces**:
  - `flowmaster` - Production deployments
  - `flowmaster-test` - Test environment
  - `flowmaster-dev` - Development environment
  - `databases-test` - Shared databases

### Access Pattern
Always SSH first, then run kubectl on the remote server:
```bash
ssh dev-01-root "kubectl -n flowmaster get pods"
ssh dev-01-root "kubectl -n flowmaster describe pod <pod-name>"
```

## Local Docker Registry

### Registry Details
- **URL**: localhost:30500 (accessible from dev-01 only)
- **Type**: K3S NodePort registry
- **Authentication**: None (private network)

### Image Build and Push Workflow
```bash
# 1. Build image on dev-01
docker build --platform linux/amd64 -t localhost:30500/flowmaster/<name>:<tag> .

# 2. Push to registry
docker push localhost:30500/flowmaster/<name>:<tag>

# 3. Deploy/update in K8S
kubectl set image -n flowmaster deploy/<name> <name>=localhost:30500/flowmaster/<name>:<tag>
```

## Kubectl Common Commands

### Pod Management
```bash
# List pods
ssh dev-01-root "kubectl -n flowmaster get pods"

# Describe pod
ssh dev-01-root "kubectl describe pod -n flowmaster <pod-name>"

# Check logs
ssh dev-01-root "kubectl logs -n flowmaster deploy/<service> --tail=50"

# Get logs from specific pod
ssh dev-01-root "kubectl logs -n flowmaster <pod-name> --tail=100"
```

### Deployment Management
```bash
# List deployments
ssh dev-01-root "kubectl -n flowmaster get deploy"

# Update image
ssh dev-01-root "kubectl set image -n flowmaster deploy/<name> <name>=localhost:30500/flowmaster/<name>:<tag>"

# Restart deployment
ssh dev-01-root "kubectl rollout restart -n flowmaster deploy/<name>"

# Check deployment status
ssh dev-01-root "kubectl -n flowmaster describe deploy <name>"
```

### ConfigMaps
```bash
# List ConfigMaps
ssh dev-01-root "kubectl get cm -n flowmaster"

# View specific ConfigMap
ssh dev-01-root "kubectl get cm gateway-config -n flowmaster -o yaml"

# Edit ConfigMap
ssh dev-01-root "kubectl edit cm gateway-config -n flowmaster"
```

### Service Discovery
```bash
# List services
ssh dev-01-root "kubectl -n flowmaster get svc"

# Get service endpoints
ssh dev-01-root "kubectl -n flowmaster get endpoints"
```

## Health Checks

### Via kubectl exec
```bash
ssh dev-01-root "kubectl exec -n flowmaster deploy/<name> -- wget -qO- http://localhost:<port>/health"
```

### Common Health Endpoints
- Most services: `/health`
- API Gateway: `/health`
- WebSocket Gateway: `/health`

## Key ClusterIP Endpoints (Hardcoded)
**WARNING**: These IPs are hardcoded and will change if services are recreated.

- **Frontend**: 10.43.185.219:3000 (frontend-nextjs deployment)
- **API Gateway**: 10.43.193.134:9000 (api-gateway deployment)
- **WebSocket Gateway**: 10.43.43.253:9010 (websocket-gateway deployment)

These are used in Nginx config: `/etc/nginx/sites-enabled/flowmaster`

## Image Pull Policy
- All K3S deployments have `imagePullPolicy: Always`
- This ensures latest image from registry is always pulled
- Requires local registry or external registry to be available

## Key Facts
- All kubectl commands must be run via SSH on dev-01
- Local registry (localhost:30500) is K3S NodePort
- ClusterIP endpoints are hardcoded (document them if services are recreated)
- Always use `-n flowmaster` namespace for production services
