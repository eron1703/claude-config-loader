# claude-pod - Containerized Claude Code with Test-Rig

## Quick Connect

**Interactive shell:**
```bash
ssh demo-server-root "kubectl exec -it -n claude-pod deployment/claude-pod -- bash"
```

**Run single command:**
```bash
ssh demo-server-root "kubectl exec -n claude-pod deployment/claude-pod -- <command>"
```

## Deployment Info

- **Location**: demo-server (65.21.153.235)
- **Namespace**: claude-pod
- **Pods**: claude-pod + litellm-proxy
- **GitLab Repo**: https://gitlab.com/flow-master/claude-pod
- **Auto-deploy**: Push to main branch → deploys in ~3 minutes

## What's Included

- **test-rig v1.0.0**: Multi-agent testing framework
- **claude-config-loader**: Skills auto-loaded on startup
- **LiteLLM proxy**: Model routing to Grok-3 and Gemini 2.5 Flash
- **Health checks**: HTTP endpoint on port 8013

## Model Routing (Cost Optimization)

- **Claude Sonnet** → Grok-3 ($0.70/1M tokens)
- **Claude Opus** → Gemini 2.5 Flash ($3.50/1M tokens)
- **Claude Haiku** → Gemini 2.5 Flash ($3.50/1M tokens)

## test-rig Commands

All commands require `--headless` or `--non-interactive` flag:

```bash
test-rig setup --yes                           # Initialize test infrastructure
test-rig generate <component> --non-interactive # Generate tests
test-rig run --parallel --agents 4 --headless  # Run tests in parallel
test-rig coverage --headless                   # Generate coverage report
test-rig analyze --headless                    # Analyze codebase
test-rig doctor --headless                     # Check test setup health
test-rig serve --port 8080                     # Start API server
```

## Useful kubectl Commands

```bash
# Check pod status
ssh demo-server-root "kubectl get pods -n claude-pod"

# View logs
ssh demo-server-root "kubectl logs -n claude-pod deployment/claude-pod"
ssh demo-server-root "kubectl logs -n claude-pod deployment/litellm-proxy"

# Restart deployment
ssh demo-server-root "kubectl rollout restart deployment/claude-pod -n claude-pod"
ssh demo-server-root "kubectl rollout restart deployment/litellm-proxy -n claude-pod"

# Check events
ssh demo-server-root "kubectl get events -n claude-pod --sort-by='.lastTimestamp'"

# Port forward (for local access)
ssh demo-server-root "kubectl port-forward -n claude-pod deployment/claude-pod 8013:8013"
```

## CI/CD Pipeline

- **Trigger**: `git push origin main`
- **Duration**: ~3 minutes
- **Pipeline URL**: https://gitlab.com/flow-master/claude-pod/-/pipelines
- **Process**:
  1. Sync code to demo-server
  2. Build Docker images (claude-pod + litellm)
  3. Tag images with registry.gitlab.com names
  4. Import to K3S containerd
  5. Apply Kustomize manifests
  6. Restart deployments

## Configuration Files

- **Dockerfile**: `/tmp/claude-pod/docker/Dockerfile`
- **LiteLLM config**: `/tmp/claude-pod/config/litellm-config.yaml`
- **K8S manifests**: `/tmp/claude-pod/k8s/base/`
- **CI/CD**: `/tmp/claude-pod/.gitlab-ci.yml`

## Troubleshooting

**Pod not starting:**
```bash
ssh demo-server-root "kubectl describe pod -n claude-pod -l app.kubernetes.io/component=claude"
```

**Health check failing:**
```bash
ssh demo-server-root "kubectl exec -n claude-pod deployment/claude-pod -- curl -v http://localhost:8013"
```

**LiteLLM proxy issues:**
```bash
ssh demo-server-root "kubectl logs -n claude-pod deployment/litellm-proxy"
ssh demo-server-root "kubectl exec -n claude-pod deployment/claude-pod -- curl http://litellm-proxy:4000/health"
```

## Ports

- **8013**: claude-pod health check
- **4000**: LiteLLM API
- **8000**: LiteLLM health check

## API Keys (GitLab CI/CD Variables)

- `ANTHROPIC_API_KEY`: Fallback Claude API key
- `GROK_API_KEY`: X.AI Grok API key
- `GEMINI_API_KEY`: Google Gemini API key
- `LITELLM_MASTER_KEY`: LiteLLM master key
- `SSH_PRIVATE_KEY`: demo-server SSH key

Access via: `glab variable get VARIABLE_NAME --group flow-master`
