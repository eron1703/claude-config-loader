# Claude Pod - Remote Claude Code Installation

## Quick Access

**One-Click Connection (Recommended):**
- **Mac**: Double-click `connect-claude-pod.command`
- **Windows**: Double-click `connect-claude-pod.bat`

**Manual SSH Connection:**
```bash
ssh dev-01-root "kubectl exec -it -n claude-pod deployment/claude-pod -- bash"
```

## Setup (One-Time)

Place SSH private key at:
- **Mac/Linux**: `~/.ssh/id_ed25519_demo`
- **Windows**: `C:\Users\YourUsername\.ssh\id_ed25519_demo`

Get key from:
```bash
glab variable get SSH_PRIVATE_KEY --group flow-master
```

## What's Inside

- **Claude Code 2.1.37** - Full CLI with all features
- **test-rig 1.0.0** - Testing orchestration framework
- **40 Skills** - Auto-loaded from claude-config-loader
- **LiteLLM Proxy** - AI model routing for cost savings

## Model Routing (Cost Optimization)

```yaml
claude-3-5-sonnet → Grok-3 ($0.70/1M tokens)   # 77% cheaper
claude-3-opus     → Gemini 2.5 Flash ($3.50/1M) # 12% cheaper
claude-haiku      → Gemini 2.5 Flash ($3.50/1M) # Actually more expensive!
```

**Cost Tracking:**
```bash
# Inside pod
curl http://litellm-proxy:4000/spend/tags
```

## Deployment Info

- **Server**: dev-01 (65.21.153.235)
- **Namespace**: `claude-pod`
- **Platform**: K3S (Kubernetes)
- **Replicas**: 1-8 (auto-scales with HPA)
- **Resources**: 500m-2000m CPU, 1Gi-4Gi memory per pod
- **Deployment**: Auto-deploy on push to main (GitLab CI/CD)

## Health Check

```bash
# From dev-01
kubectl get pods -n claude-pod
kubectl logs -f -n claude-pod deployment/claude-pod

# From pod
claude --version  # Should show 2.1.37
test-rig --version  # Should show 1.0.0
ls ~/.claude/skills/  # Should show 40 skills
```

## Troubleshooting

**Pod not responding:**
```bash
kubectl rollout restart deployment/claude-pod -n claude-pod
```

**Skills not loaded:**
```bash
kubectl delete pod -n claude-pod -l app.kubernetes.io/name=claude-pod
# Wait for pod to restart (init container will reload skills)
```

**LiteLLM not routing:**
```bash
# Inside pod
curl http://litellm-proxy:4000/health
# Check settings
cat ~/.claude/settings.json | grep baseUrl
```

## Repository

- **GitLab**: https://gitlab.com/flow-master/claude-pod
- **CI/CD**: Auto-deploy on main branch
- **Monitoring**: Grafana dashboard (planned)
