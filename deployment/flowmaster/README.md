# FlowMaster Dev Server Deployment

Deployment configuration for FlowMaster across 3 dev servers.

## Server Mapping

| Alias  | IP              | Location    | Branch    | Purpose                    |
|--------|-----------------|-------------|-----------|----------------------------|
| dev-01 | 65.21.153.235   | Helsinki    | develop   | Primary dev, shared tools  |
| dev-02 | 91.98.159.56    | Falkenstein | staging   | Staging / integration      |
| dev-03 | 65.21.52.58     | Helsinki    | feature/* | Feature branch testing     |

## Quick Start

```bash
# Deploy develop branch to dev-01
./deploy.sh dev-01

# Dry run staging deploy
./deploy.sh dev-02 --dry-run

# Deploy a feature branch to dev-03
./deploy.sh dev-03 --branch feature/auth-redesign
```

## Services

Each server runs 5 services with local databases (not shared between servers):

| Service   | Port | Image                       |
|-----------|------|-----------------------------|
| frontend  | 3000 | flowmaster-frontend          |
| backend   | 8000 | flowmaster-backend (FastAPI) |
| arangodb  | 8529 | arangodb:3.11               |
| postgres  | 5432 | postgres:16-alpine          |
| redis     | 6379 | redis:7-alpine              |

Memory budget per CCX23 (16GB RAM): frontend 1G, backend 2G, arangodb 3G, postgres 2G, redis 768M = ~8.8G reserved, ~7G for OS + overhead.

## Files

```
deployment/flowmaster/
  docker-compose.dev.yml   # Compose overlay for all dev servers
  deploy.sh                # Deployment script (SSH-based)
  .env.dev-01              # Environment for dev-01
  .env.dev-02              # Environment for dev-02
  .env.dev-03              # Environment for dev-03
  README.md                # This file
```

## Environment Variables

| Variable           | Description                          | Example                              |
|--------------------|--------------------------------------|--------------------------------------|
| SERVER_NAME        | Server identifier                    | dev-01                               |
| ENVIRONMENT        | Runtime environment                  | development / staging                |
| DATABASE_URL       | PostgreSQL connection string         | postgresql://user:pass@postgres:5432 |
| ARANGO_URL         | ArangoDB endpoint                    | http://arangodb:8529                 |
| REDIS_URL          | Redis connection string              | redis://redis:6379/0                 |
| API_URL            | Public backend URL                   | http://65.21.153.235:8000            |
| SECRET_KEY         | Application secret (unique/server)   | fm-dev01-secret-...                  |
| JWT_SECRET_KEY     | JWT signing key (unique/server)      | fm-dev01-jwt-...                     |
| DOCKER_REGISTRY    | Container image registry             | registry.gitlab.com/flow-master      |
| FRONTEND_TAG       | Frontend image tag                   | develop / staging / latest           |
| BACKEND_TAG        | Backend image tag                    | develop / staging / latest           |

## Common Operations

### Restart a single service
```bash
ssh dev-01 "cd /opt/flowmaster && docker compose -f docker-compose.dev.yml restart backend"
```

### View logs
```bash
ssh dev-01 "cd /opt/flowmaster && docker compose -f docker-compose.dev.yml logs -f backend --tail=100"
```

### Check service health
```bash
ssh dev-01 "docker ps --filter 'name=flowmaster-' --format 'table {{.Names}}\t{{.Status}}'"
```

### Rollback to previous image
```bash
# On the server:
cd /opt/flowmaster
docker compose -f docker-compose.dev.yml stop backend
docker compose -f docker-compose.dev.yml pull backend  # pulls :develop tag
docker compose -f docker-compose.dev.yml up -d backend

# Or use a specific tag:
BACKEND_TAG=develop-abc1234 docker compose -f docker-compose.dev.yml up -d backend
```

### Full teardown (preserves volumes)
```bash
ssh dev-01 "cd /opt/flowmaster && docker compose -f docker-compose.dev.yml down"
```

### Full teardown including data
```bash
ssh dev-01 "cd /opt/flowmaster && docker compose -f docker-compose.dev.yml down -v"
```

## Prerequisites

Before first deployment:
1. Git repository must be cloned at `/opt/flowmaster` on the target server
2. Docker and Docker Compose must be installed
3. SSH keys must be configured (dev-01/dev-03: `~/.ssh/demo_server`, dev-02: `~/.ssh/id_rsa`)
4. Container images must be built and pushed to the GitLab registry

## Notes

- Each server has its own isolated databases; no cross-server DB sharing
- All database passwords are unique per server
- SECRET_KEY and JWT_SECRET_KEY are unique per server
- dev-03 requires `--branch` flag since it has no default branch
- The deploy script uses `--env-file` so the compose file itself is server-agnostic
