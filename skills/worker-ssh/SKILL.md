---
name: worker-ssh
description: SSH access credentials and patterns for FlowMaster servers
disable-model-invocation: true
---

# Worker SSH Knowledge

## SSH Access Patterns

### Demo Server (65.21.153.235)
- **Root**: `ssh demo-server-root` (root@65.21.153.235)
- **User**: `ssh demo-server` (ben@65.21.153.235)
- **Preferred**: Use root for infrastructure operations
- **SSH config**: `~/.ssh/config` has host aliases configured

### Production (91.99.237.14)
- **URL**: app.flow-master.ai
- **Access**: No SSH from local machine (Docker Compose only)

### Staging (91.98.159.56)
- **URL**: staging.flow-master.ai, dev.flow-master.ai
- **Status**: Currently DOWN

## SSH Command Patterns

Always use timeout to prevent hanging:
```bash
ssh -o ConnectTimeout=10 demo-server-root "command"
```

Example commands:
```bash
ssh demo-server-root "kubectl -n flowmaster get pods"
ssh demo-server-root "docker ps"
ssh demo-server-root "cat /opt/flowmaster-deployments/docker-compose.staging.yml"
```

## SSH Config Location
`~/.ssh/config` contains host aliases and connection settings.

## Key Facts
- Demo server is primary for development and testing
- Always set ConnectTimeout=10 to avoid infinite hangs
- Root access required for K8S, Docker, and system-level operations
