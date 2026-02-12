# NGINX DNS Migration Plan: H3 - Hardcoded ClusterIPs

**Document Version**: 1.0
**Date Created**: 2026-02-12
**Priority**: P1 (Critical Infrastructure)
**Status**: Ready for Implementation
**Complexity**: Medium (1 day)

---

## Executive Summary

### The Problem

Nginx is currently configured with hardcoded Kubernetes ClusterIPs for service routing. ClusterIPs are ephemeral identifiers that change whenever:
- Pods are restarted
- Services are recreated
- Node failovers occur
- Deployments are updated

This causes system outages requiring manual Nginx configuration updates after each pod restart.

### The Solution

Replace hardcoded ClusterIPs with DNS-based service discovery using Kubernetes-native service names. This provides automatic failover and eliminates manual intervention.

### Expected Outcomes

- ✅ Automatic pod restart resilience (no manual config updates)
- ✅ Simplified deployment workflow
- ✅ Reduced downtime during rolling updates
- ✅ Built-in health checking and failover
- ✅ Production-ready infrastructure

---

## Current State Analysis

### Affected Services

The following Nginx routes currently use hardcoded ClusterIPs:

```
Internet → Nginx (port 80) → K3S ClusterIPs
  ├── / → frontend service (10.43.x.x:3000)
  ├── /api/ → api-gateway service (10.43.x.x:9000)
  └── /ws/ → websocket-gateway service (10.43.x.x:9010)
```

### Current Nginx Configuration (from documentation)

**File Location**: `/etc/nginx/sites-enabled/flowmaster`

The current configuration pattern shows:

```nginx
# PROBLEMATIC CONFIGURATION (CURRENT)
upstream frontend_backend {
    server 10.43.185.219:3000;  # Changes on pod restart!
}

upstream api_gateway_backend {
    server 10.43.193.134:9000;  # Changes on pod restart!
}

upstream websocket_gateway_backend {
    server 10.43.43.253:9010;   # Changes on pod restart!
}
```

### Known ClusterIP History

| Service | Namespace | Current ClusterIP | Previous IPs | Notes |
|---------|-----------|------------------|-------------|-------|
| frontend-nextjs | flowmaster | 10.43.185.219 | 10.43.206.17 | Prod→Dev migration |
| api-gateway | flowmaster | 10.43.193.134 | 10.43.7.174 | Prod→Dev migration |
| websocket-gateway | flowmaster | 10.43.43.253 | 10.43.34.82 | Prod→Dev migration |

**Evidence**: Multiple IP sets documented across skills, indicating multiple service recreations.

### Impact Assessment

**Current Issues**:
1. Every pod restart invalidates Nginx config
2. Manual discovery required (`kubectl get svc`)
3. Manual config update required (`vi /etc/nginx/sites-enabled/flowmaster`)
4. Nginx reload required (`systemctl reload nginx`)
5. Downtime during pod restart cycle (5-10 minutes)
6. Risk of stale config causing 502 Gateway errors

**Risk Score**: HIGH (8/10)
- Occurs frequently (pod restarts are common)
- Requires manual intervention (error-prone)
- Causes user-visible downtime
- Breaks during cluster scaling operations

---

## DNS-Based Service Discovery Solution

### How Kubernetes DNS Works

K3S (Kubernetes) provides built-in DNS for service discovery:

```
Service Name: <service-name>.<namespace>.svc.cluster.local
Example:      frontend.flowmaster.svc.cluster.local
```

**Key Benefits**:
- Automatically resolves to current ClusterIP
- Works across pod restarts
- Handles pod IP changes transparently
- Built-in load balancing across pods
- No configuration changes needed

### DNS Resolution Path

```
1. Nginx requests: frontend.flowmaster.svc.cluster.local
   ↓
2. K3S CoreDNS service intercepts request
   ↓
3. CoreDNS queries etcd for current ClusterIP
   ↓
4. Returns current ClusterIP (automatically updated)
   ↓
5. Nginx connects to current IP
   ↓
6. Pod restarts → CoreDNS returns new ClusterIP automatically
```

### Service Discovery Timeout Handling

DNS results are cached by Nginx. To ensure fresh lookups:

```nginx
# Use variables for dynamic resolution
set $upstream frontend.flowmaster.svc.cluster.local;
proxy_pass http://$upstream:3000;

# Nginx will re-resolve on each request when using variables
```

---

## Updated Nginx Configuration

### Template 1: Basic DNS Configuration (Recommended)

**File**: `/etc/nginx/sites-enabled/flowmaster`

```nginx
# FlowMaster Nginx Configuration - DNS-Based Service Discovery
# Updated: 2026-02-12
# This configuration uses Kubernetes DNS for automatic service discovery

# Resolver configuration - K3S CoreDNS
resolver 10.43.0.10 valid=10s;  # K3S default CoreDNS IP
resolver_timeout 5s;

# Variables for service discovery (enables dynamic resolution)
set $frontend_service "frontend.flowmaster.svc.cluster.local";
set $api_gateway_service "api-gateway.flowmaster.svc.cluster.local";
set $websocket_service "websocket-gateway.flowmaster.svc.cluster.local";

# ============================================
# FRONTEND SERVICE
# ============================================

server {
    listen 80;
    server_name _;

    # Root path → Frontend service
    location / {
        proxy_pass http://$frontend_service:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Next.js specific headers
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;

        # Timeouts for Next.js (longer for SSR)
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;

        # Health check endpoint
        access_log /var/log/nginx/frontend-access.log;
        error_log /var/log/nginx/frontend-error.log;
    }

    # ============================================
    # API GATEWAY SERVICE
    # ============================================

    location /api/ {
        proxy_pass http://$api_gateway_service:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Preserve /api/ prefix in request
        proxy_set_header X-Original-Path $request_uri;

        # API timeouts (shorter for REST)
        proxy_connect_timeout 10s;
        proxy_send_timeout 20s;
        proxy_read_timeout 20s;

        # API specific options
        proxy_buffering off;  # Stream responses (important for large payloads)
        proxy_request_buffering off;

        # Health check endpoint
        access_log /var/log/nginx/api-gateway-access.log;
        error_log /var/log/nginx/api-gateway-error.log;
    }

    # ============================================
    # WEBSOCKET SERVICE
    # ============================================

    location /ws/ {
        proxy_pass http://$websocket_service:9010;

        # WebSocket upgrade headers (CRITICAL)
        proxy_set_header Connection "Upgrade";
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket timeouts (must be long-lived)
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;

        # WebSocket buffering must be disabled
        proxy_buffering off;
        proxy_request_buffering off;

        # Health check endpoint
        access_log /var/log/nginx/websocket-access.log;
        error_log /var/log/nginx/websocket-error.log;
    }

    # ============================================
    # HEALTH CHECK ENDPOINT
    # ============================================

    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # ============================================
    # ERROR PAGES
    # ============================================

    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
```

### Template 2: Advanced Configuration with Upstream Blocks (Alternative)

**File**: `/etc/nginx/sites-enabled/flowmaster`

```nginx
# FlowMaster Nginx Configuration - Advanced DNS with Upstream Blocks
# This version uses explicit upstream definitions for better control

# Resolver configuration - K3S CoreDNS
resolver 10.43.0.10 valid=10s;
resolver_timeout 5s;

# DNS resolver must be set to use variable-based service names
set $dns_resolver "10.43.0.10";

# Upstream definitions with DNS (requires resolver directive)
upstream frontend {
    server frontend.flowmaster.svc.cluster.local:3000;

    # Keep-alive connections for efficiency
    keepalive 32;
}

upstream api_gateway {
    server api-gateway.flowmaster.svc.cluster.local:9000;

    # Enable connection pooling
    keepalive 32;
}

upstream websocket_gateway {
    server websocket-gateway.flowmaster.svc.cluster.local:9010;

    # WebSocket connections need longer keep-alive
    keepalive 64;
}

server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";  # Preserve keep-alive
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API Gateway
    location /api/ {
        proxy_pass http://api_gateway;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket
    location /ws/ {
        proxy_pass http://websocket_gateway;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

---

## Health Check Implementation

### Option 1: Nginx Health Check (Passive)

```nginx
# In upstream block
upstream api_gateway {
    server api-gateway.flowmaster.svc.cluster.local:9000 max_fails=3 fail_timeout=30s;

    # Mark server down after 3 failures within 30s window
}
```

**Behavior**:
- Nginx monitors responses from upstream
- After 3 consecutive failures → marks server as down
- Stops sending requests for 30 seconds
- Automatically attempts recovery

### Option 2: Active Health Checks (Requires Nginx Plus)

For open-source Nginx, use Kubernetes liveness probes instead:

```yaml
# In Kubernetes Service definition
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: flowmaster
spec:
  ports:
  - name: http
    port: 9000
    targetPort: 9000
    protocol: TCP
  selector:
    app: api-gateway
  type: ClusterIP

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: flowmaster
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: api-gateway
        livenessProbe:
          httpGet:
            path: /health
            port: 9000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 9000
          initialDelaySeconds: 5
          periodSeconds: 3
```

**Behavior**:
- Kubernetes removes unhealthy pods from service
- Nginx DNS resolves only to healthy pods
- No manual intervention needed

### Option 3: Load Balancing with Multiple Pods

```yaml
# Scale deployment to multiple pods
kubectl scale deployment api-gateway --replicas=3 -n flowmaster
```

Nginx automatically load balances across all pod IPs returned by DNS.

---

## Migration Procedure

### Pre-Migration Checklist

- [ ] Backup current Nginx configuration
- [ ] Document current ClusterIPs
- [ ] Verify K3S CoreDNS is running
- [ ] Test DNS resolution from Nginx pod
- [ ] Schedule migration during maintenance window
- [ ] Notify stakeholders
- [ ] Prepare rollback plan

### Step 1: Verify K3S CoreDNS

```bash
# SSH to demo server
ssh server

# Check CoreDNS pod
kubectl get pods -n kube-system | grep coredns

# Get CoreDNS ClusterIP
kubectl get svc -n kube-system kube-dns
# Expected output should show IP (typically 10.43.0.10)

# Verify DNS resolution from inside cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup frontend.flowmaster.svc.cluster.local 10.43.0.10
# Should resolve to frontend service ClusterIP
```

### Step 2: Get Current Service Details

```bash
# Get current ClusterIPs and service info
kubectl get svc -n flowmaster -o wide

# Example output:
# NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
# frontend               ClusterIP   10.43.185.219    <none>        3000/TCP   45d
# api-gateway            ClusterIP   10.43.193.134    <none>        9000/TCP   45d
# websocket-gateway      ClusterIP   10.43.43.253     <none>        9010/TCP   45d

# Get service DNS names
kubectl get svc -n flowmaster -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
# Output:
# frontend
# api-gateway
# websocket-gateway
```

### Step 3: Create Updated Nginx Configuration

**On demo server**:

```bash
# Backup current config
sudo cp /etc/nginx/sites-enabled/flowmaster \
        /etc/nginx/sites-enabled/flowmaster.backup.$(date +%Y%m%d_%H%M%S)

# Verify backup created
sudo ls -la /etc/nginx/sites-enabled/flowmaster.backup.*
```

**Create new configuration** (use Template 1 from above):

```bash
# Create temporary file
cat > /tmp/flowmaster-new.conf << 'EOF'
# [Copy Template 1 content here]
EOF

# Validate syntax
sudo nginx -t -c /tmp/flowmaster-new.conf

# If valid, deploy
sudo cp /tmp/flowmaster-new.conf /etc/nginx/sites-enabled/flowmaster

# Verify again
sudo nginx -t
```

### Step 4: Test DNS Resolution

**From Nginx container/pod**:

```bash
# Get Nginx pod name
kubectl get pods -n kube-system | grep nginx
# or
ps aux | grep nginx  # If running on host

# Test DNS from Nginx
nslookup frontend.flowmaster.svc.cluster.local 10.43.0.10
nslookup api-gateway.flowmaster.svc.cluster.local 10.43.0.10
nslookup websocket-gateway.flowmaster.svc.cluster.local 10.43.0.10

# All should resolve successfully
```

### Step 5: Reload Nginx

```bash
# Check current status
sudo systemctl status nginx

# Reload configuration (graceful restart)
sudo systemctl reload nginx

# Verify reload succeeded
sudo systemctl status nginx

# Check logs for errors
sudo tail -f /var/log/nginx/error.log
```

### Step 6: Verify Service Connectivity

```bash
# Test frontend connectivity
curl -v http://localhost/
# Expected: 200 OK from frontend

# Test API gateway connectivity
curl -v http://localhost/api/health
# Expected: 200 OK from api-gateway

# Test WebSocket connectivity
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  http://localhost/ws/
# Expected: 101 Switching Protocols or 400 (connection rejected is OK for health check)

# Check Nginx access logs
sudo tail -f /var/log/nginx/frontend-access.log
sudo tail -f /var/log/nginx/api-gateway-access.log
sudo tail -f /var/log/nginx/websocket-access.log
```

### Step 7: Verify No Hardcoded IPs

```bash
# Verify no hardcoded IPs remain
sudo grep -n "10\\.43\\." /etc/nginx/sites-enabled/flowmaster
# Expected: No output (no matches)

# Verify DNS names are in use
sudo grep -n "svc\\.cluster\\.local" /etc/nginx/sites-enabled/flowmaster
# Expected: Multiple matches showing DNS names
```

---

## Testing Verification Steps

### Test 1: Pod Restart Resilience

**Objective**: Verify Nginx continues working after pod restart

```bash
# Get frontend pod name
FRONTEND_POD=$(kubectl get pods -n flowmaster -l app=frontend \
  -o jsonpath='{.items[0].metadata.name}')

# Note: Verify connectivity works BEFORE restart
curl http://localhost/ -w "\nStatus: %{http_code}\n"

# Restart the pod (force delete to simulate crash)
kubectl delete pod $FRONTEND_POD -n flowmaster

# Wait for pod to restart
sleep 10
kubectl get pods -n flowmaster | grep frontend

# Verify connectivity AFTER restart (should work immediately)
curl http://localhost/ -w "\nStatus: %{http_code}\n"
# Should still return 200 OK without Nginx config changes

# Check Nginx logs - should show ongoing traffic
sudo tail -20 /var/log/nginx/frontend-access.log
```

### Test 2: Service Scaling

**Objective**: Verify load balancing works with multiple pod replicas

```bash
# Scale frontend to 3 replicas
kubectl scale deployment frontend --replicas=3 -n flowmaster

# Wait for pods to start
sleep 15
kubectl get pods -n flowmaster | grep frontend

# Generate traffic and watch load distribution
for i in {1..100}; do
  curl -s http://localhost/ > /dev/null
  sleep 0.1
done

# Check access logs - should show requests distributed across pod IPs
sudo tail -30 /var/log/nginx/frontend-access.log | \
  cut -d' ' -f1 | sort | uniq -c
# Should show multiple different upstream IPs

# Scale back to 1
kubectl scale deployment frontend --replicas=1 -n flowmaster
```

### Test 3: DNS Resolution Timing

**Objective**: Verify DNS is resolving correctly with proper TTL

```bash
# Monitor DNS queries (on host)
sudo tcpdump -i any 'udp port 53' -v | grep "svc.cluster.local"

# In another terminal, generate traffic
for i in {1..10}; do
  curl -s http://localhost/ > /dev/null
done

# tcpdump should show DNS queries for svc.cluster.local names
```

### Test 4: Failover Behavior

**Objective**: Verify graceful degradation when service is unavailable

```bash
# Create test scenario: mark API gateway pod as not ready
kubectl patch deployment api-gateway -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"api-gateway","livenessProbe":{"httpGet":{"path":"/nonexistent"}}}]}}}}' \
  -n flowmaster

# Wait for pod to be marked as not ready
sleep 10

# Verify service removes unhealthy pod
kubectl get endpoints api-gateway -n flowmaster

# Nginx should handle this gracefully
# Either: 1) Direct to another healthy pod if replicas > 1
#        2) Return 502 error if no healthy pods
curl -v http://localhost/api/health

# Restore pod health
kubectl rollout undo deployment api-gateway -n flowmaster
```

### Test 5: Load Testing

**Objective**: Verify performance is acceptable with DNS resolution

```bash
# Install Apache Bench if not available
sudo apt-get install -y apache2-utils

# Baseline test (small concurrent load)
ab -n 1000 -c 10 http://localhost/

# Results should show:
# - Requests per second: similar or better than IP-based
# - Failed requests: 0
# - Mean time per request: <100ms (depends on frontend response time)

# Stress test (higher load)
ab -n 10000 -c 50 http://localhost/

# Should handle without degradation
```

---

## Monitoring and Observability

### Nginx Metrics to Monitor

```nginx
# Add status module to nginx config (optional, requires recompile for OSS)
# For existing Nginx, use log-based monitoring

# Log format for analysis
log_format upstream_log '$remote_addr - $remote_user [$time_local] '
                        '"$request" $status $body_bytes_sent '
                        '"$http_referer" "$http_user_agent" '
                        'upstream: $upstream_addr '
                        'response_time: $upstream_response_time';

access_log /var/log/nginx/upstream.log upstream_log;
```

### Key Metrics to Track

1. **DNS Resolution Time**: `$upstream_response_time` in logs
2. **Upstream Connection Failures**: Error logs
3. **502/503 Error Rate**: Should be 0 after migration
4. **Request Latency**: Should match or improve
5. **Failed Requests**: Monitor and alert on increase

### Alerting Rules

```yaml
# Prometheus alerts (if using)
- alert: NginxUpstreamDown
  expr: nginx_upstream_requests_failed > 0
  for: 1m
  annotations:
    summary: "Nginx upstream connection failed"

- alert: NginxHighErrorRate
  expr: rate(nginx_requests_total{status=~"5.."}[5m]) > 0.01
  for: 5m
  annotations:
    summary: "Nginx error rate > 1%"

- alert: NginxDNSResolutionFail
  expr: nginx_upstream_dns_failures > 0
  for: 1m
  annotations:
    summary: "DNS resolution failed for upstream"
```

---

## Rollback Procedure

### If Something Goes Wrong

**Quick Rollback (within 1 hour)**:

```bash
# Restore backup configuration
sudo cp /etc/nginx/sites-enabled/flowmaster.backup.YYYYMMDD_HHMMSS \
        /etc/nginx/sites-enabled/flowmaster

# Reload Nginx
sudo nginx -t
sudo systemctl reload nginx

# Verify working
curl http://localhost/ -w "\nStatus: %{http_code}\n"
```

**Rollback Verification**:

```bash
# Check config contains hardcoded IPs (should match pre-migration)
sudo grep "10\\.43\\." /etc/nginx/sites-enabled/flowmaster

# Check service connectivity
curl http://localhost/api/health
curl http://localhost/

# Review logs
sudo tail -20 /var/log/nginx/error.log
```

### Known Issues and Fixes

| Issue | Symptom | Fix |
|-------|---------|-----|
| DNS not resolving | `502 Bad Gateway` | Verify CoreDNS IP in resolver directive (default: 10.43.0.10) |
| Slow resolution | High latency initially | Increase `valid` parameter in resolver (10s is default) |
| Connection refused | Services unreachable | Verify K3S services are running: `kubectl get svc -n flowmaster` |
| Nginx won't reload | Syntax error | Run `sudo nginx -t` to see specific error |
| Intermittent 502 errors | Services flaky | Increase `fail_timeout` and reduce `max_fails` |

---

## Implementation Checklist

- [ ] **Pre-Migration**
  - [ ] Read this document completely
  - [ ] Review current Nginx config
  - [ ] Backup current configuration
  - [ ] Verify K3S CoreDNS is running
  - [ ] Schedule maintenance window
  - [ ] Notify team

- [ ] **Execution**
  - [ ] SSH to demo server
  - [ ] Create backup: `cp flowmaster flowmaster.backup`
  - [ ] Update Nginx configuration with DNS names
  - [ ] Run syntax check: `sudo nginx -t`
  - [ ] Reload Nginx: `sudo systemctl reload nginx`
  - [ ] Verify connectivity: `curl http://localhost/`
  - [ ] Check logs for errors

- [ ] **Verification**
  - [ ] Test 1: Pod restart resilience ✓
  - [ ] Test 2: Service scaling ✓
  - [ ] Test 3: DNS resolution timing ✓
  - [ ] Test 4: Failover behavior ✓
  - [ ] Test 5: Load testing ✓
  - [ ] Monitor metrics for 24 hours

- [ ] **Documentation**
  - [ ] Update deployment docs
  - [ ] Document new DNS service names
  - [ ] Add troubleshooting guide
  - [ ] Update team wiki/runbooks
  - [ ] Archive old ClusterIP documentation

- [ ] **Post-Migration**
  - [ ] Set up monitoring alerts
  - [ ] Review logs for anomalies
  - [ ] Update disaster recovery plan
  - [ ] Communicate completion to team
  - [ ] Schedule knowledge transfer session

---

## Additional Resources

### K3S Documentation

- **K3S Service Discovery**: https://kubernetes.io/docs/concepts/services-networking/service/
- **CoreDNS Configuration**: https://coredns.io/
- **Kubernetes DNS**: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

### Nginx Documentation

- **Nginx Upstream Module**: http://nginx.org/en/docs/http/ngx_http_upstream_module.html
- **Nginx DNS Resolver**: http://nginx.org/en/docs/http/ngx_http_core_module.html#resolver
- **Nginx Proxy Module**: http://nginx.org/en/docs/http/ngx_http_proxy_module.html

### Related Infrastructure Issues

- **H1**: Port Collisions (BLOCKER) - See ARCHITECTURE_FIX_PLAN.md
- **H2**: Shared ArangoDB Without Isolation - See ARCHITECTURE_FIX_PLAN.md
- **H4**: Zero Service Contract Testing - See ARCHITECTURE_FIX_PLAN.md

---

## Configuration Migration Comparison

### Before (Hardcoded ClusterIPs)

```nginx
upstream api_gateway {
    server 10.43.193.134:9000;
}
```

**Problems**:
- ❌ Breaks on pod restart
- ❌ Manual discovery required
- ❌ Downtime on updates
- ❌ Multiple IPs to track

### After (DNS-Based)

```nginx
resolver 10.43.0.10 valid=10s;
set $api_gateway_service "api-gateway.flowmaster.svc.cluster.local";

location /api/ {
    proxy_pass http://$api_gateway_service:9000;
    # ... rest of config
}
```

**Benefits**:
- ✅ Automatic pod restart handling
- ✅ Single DNS name per service
- ✅ Zero downtime on updates
- ✅ Built-in service discovery
- ✅ Production-ready

---

## Task Completion Criteria

This task (H3 - Nginx ClusterIPs) is COMPLETE when:

1. ✅ Nginx configuration updated with DNS names
2. ✅ No hardcoded ClusterIPs remain (grep returns no results)
3. ✅ All 5 verification tests pass
4. ✅ Services remain accessible after pod restart
5. ✅ Monitoring and alerts configured
6. ✅ Documentation updated
7. ✅ Team trained on new configuration

---

## Appendix: Quick Reference

### Service DNS Names

| Service | DNS Name | Port | Namespace |
|---------|----------|------|-----------|
| Frontend | frontend.flowmaster.svc.cluster.local | 3000 | flowmaster |
| API Gateway | api-gateway.flowmaster.svc.cluster.local | 9000 | flowmaster |
| WebSocket | websocket-gateway.flowmaster.svc.cluster.local | 9010 | flowmaster |

### Common Commands

```bash
# Get current ClusterIPs
kubectl get svc -n flowmaster -o wide

# Test DNS resolution
nslookup frontend.flowmaster.svc.cluster.local 10.43.0.10

# Check Nginx status
sudo systemctl status nginx

# Reload Nginx
sudo systemctl reload nginx

# View Nginx error log
sudo tail -f /var/log/nginx/error.log

# Verify configuration syntax
sudo nginx -t
```

### Emergency Contacts

- **Nginx Issues**: Check logs at `/var/log/nginx/`
- **K3S Issues**: Check K3S logs: `journalctl -u k3s -f`
- **DNS Issues**: Check CoreDNS: `kubectl logs -n kube-system -l k8s-app=kube-dns`

---

## Sign-Off

**Prepared by**: Claude Code (AI Assistant)
**Reviewed by**: [Pending User Review]
**Approved by**: [Pending User Approval]
**Implementation Date**: [To be scheduled]

---

**End of Document**
