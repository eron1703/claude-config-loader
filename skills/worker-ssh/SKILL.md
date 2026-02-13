---
name: worker-ssh
description: SSH access credentials and patterns for FlowMaster servers
disable-model-invocation: true
---

# Worker SSH Knowledge

## SSH Access Patterns

### dev-01 (65.21.153.235) — Main Dev
- **Root**: `ssh dev-01` (root@65.21.153.235)
- **User**: `ssh dev-01-ben` (ben@65.21.153.235)
- **SSH Key**: `~/.ssh/demo_server`
- **Location**: Helsinki | CCX23
- **Preferred**: Use root for infrastructure operations
- **SSH config**: `~/.ssh/config` has host aliases configured

### dev-02 (91.98.159.56) — Secondary Dev
- **Root**: `ssh dev-02` (root@91.98.159.56)
- **SSH Key**: `~/.ssh/id_rsa`
- **Location**: Falkenstein | CCX23
- **URL**: staging.flow-master.ai, dev.flow-master.ai

### dev-03 (65.21.52.58) — Tertiary Dev (Feature Branches)
- **Root**: `ssh dev-03` (root@65.21.52.58)
- **SSH Key**: `~/.ssh/demo_server` (same as dev-01)
- **Location**: Helsinki | CCX23
- **Status**: NEW

### prod-01 (91.99.237.14) — Production
- **User**: `ssh prod-01` (ben@91.99.237.14)
- **Root**: `ssh prod-01-root` (root@91.99.237.14)
- **SSH Key**: `~/.ssh/eron1703_duckdns`
- **Location**: Nuremberg | CPX41
- **URL**: app.flow-master.ai

## SSH Command Patterns

Always use timeout to prevent hanging:
```bash
ssh -o ConnectTimeout=10 dev-01 "command"
```

Example commands:
```bash
ssh dev-01 "kubectl -n flowmaster get pods"
ssh dev-01 "docker ps"
ssh dev-01 "cat /opt/flowmaster-deployments/docker-compose.staging.yml"
```

## SSH Config Location
`~/.ssh/config` contains host aliases and connection settings.

## Quick Reference

| Alias | User | IP | Role |
|-------|------|----|------|
| `dev-01` | root | 65.21.153.235 | Main dev, shared tools, GitLab Runner |
| `dev-01-ben` | ben | 65.21.153.235 | Main dev (user access) |
| `dev-02` | root | 91.98.159.56 | Secondary dev (staging/integration) |
| `dev-03` | root | 65.21.52.58 | Tertiary dev (feature branches) |
| `prod-01` | ben | 91.99.237.14 | Production |
| `prod-01-root` | root | 91.99.237.14 | Production (root access) |

**Legacy aliases kept**: `server`, `root-server`, `dev-server`, `dev`, `ms-dev`, `microservices-dev`, `dokku-server`

## Team User Accounts

All servers have these user accounts with sudo and docker access:

| Username | SSH Key | Example |
|----------|---------|---------|
| irtiza | ~/.ssh/id_ed25519_irtiza | `ssh -i ~/.ssh/id_ed25519_irtiza irtiza@65.21.153.235` |
| subhan | ~/.ssh/id_ed25519_subhan | `ssh -i ~/.ssh/id_ed25519_subhan subhan@65.21.153.235` |
| ali | ~/.ssh/id_ed25519_ali | `ssh -i ~/.ssh/id_ed25519_ali ali@65.21.153.235` |
| fahad | ~/.ssh/id_ed25519_fahad | `ssh -i ~/.ssh/id_ed25519_fahad fahad@65.21.153.235` |
| engineering | ~/.ssh/id_ed25519_engineering | `ssh -i ~/.ssh/id_ed25519_engineering engineering@65.21.153.235` |

All users: sudo (NOPASSWD), docker group member

## Key Facts
- dev-01 is primary for development and testing
- Always set ConnectTimeout=10 to avoid infinite hangs
- Root access required for K8S, Docker, and system-level operations
- dev-03 uses the same SSH key as dev-01 (~/.ssh/demo_server)
