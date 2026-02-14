---
name: worker-ssh
description: SSH access credentials and patterns for FlowMaster servers
disable-model-invocation: true
---

# Worker SSH Knowledge

## SSH Access Patterns

### Dev Server 1 (65.21.153.235)
- **Root**: `ssh dev-01-root` (root@65.21.153.235)
- **User**: `ssh dev-01` (ben@65.21.153.235)
- **Preferred**: Use root for infrastructure operations
- **SSH config**: `~/.ssh/config` has host aliases configured

### Dev Server 2 (65.21.52.58)
- **Root**: `ssh dev-02-root` (root@65.21.52.58)
- **User**: `ssh dev-02` (ben@65.21.52.58)
- **Status**: Development/backup server
- **SSH config**: `~/.ssh/config` has host aliases configured

### Playground (89.167.2.145)
- **Root**: `ssh playground-root` (root@89.167.2.145)
- **User**: `ssh playground` (ben@89.167.2.145)
- **Status**: Testing/experimentation server
- **SSH config**: `~/.ssh/config` has host aliases configured

### Production (91.99.237.14)
- **URL**: app.flow-master.ai
- **Access**: No SSH from local machine (Docker Compose only)

### Staging (91.98.159.56)
- **URL**: staging.flow-master.ai, dev.flow-master.ai
- **Status**: DECOMMISSIONED

## SSH Command Patterns

Always use timeout to prevent hanging:
```bash
ssh -o ConnectTimeout=10 dev-01-root "command"
```

Example commands:
```bash
ssh dev-01-root "kubectl -n flowmaster get pods"
ssh dev-01-root "docker ps"
ssh dev-01-root "cat /opt/flowmaster-deployments/docker-compose.staging.yml"
```

## SSH Config Location
`~/.ssh/config` contains host aliases and connection settings.

## Key Facts
- Dev-01 is primary for development and testing
- Dev-02 is backup/alternate development server
- Playground is for experimentation and testing
- Always set ConnectTimeout=10 to avoid infinite hangs
- Root access required for K8S, Docker, and system-level operations
