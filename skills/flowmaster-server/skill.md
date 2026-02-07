---
name: flowmaster-server
description: "FlowMaster server configuration and infrastructure"
disable-model-invocation: false
---

# FlowMaster Server Configuration Skill

## Server Architecture

### Infrastructure Overview

**Server Details:**
- IP Address: 91.98.159.56
- Operating System: Ubuntu 24.04.3 LTS
- Deployment Pattern: Multi-environment single server

### Environment Configuration

| Environment | Branch | Domain | Frontend Port | Backend Port |
|-------------|--------|--------|------------------|------------------|
| Production | `production` | app.flow-master.ai | 3002 | 3001 |
| Staging | `staging` | staging.flow-master.ai | 4000 | 4001 |
| Demo | `demo` | demo.flow-master.ai | 5000 | 5001 |
| Development | `develop` | dev.flow-master.ai | 6000 | 6001 |

All frontend containers expose port 80 internally, and backend containers expose port 8000 internally. The server Nginx acts as SSL termination and reverse proxy.

### Directory Structure

```
/srv/flowmaster/
    dev/                    # Development environment
        environments/
            .env.development
        docker-compose.development.yml
    demo/                   # Demo environment
        environments/
            .env.demo
        docker-compose.demo.yml
    staging/                # Staging environment
        environments/
            .env.staging
        docker-compose.staging.yml

/opt/flowmaster-prod/       # Production environment
    environments/
        .env.production
    docker-compose.production.yml
```

### Network Architecture

```
Internet
    |
    v
[Server Nginx :443 - SSL Termination]
    |
    +---> demo.flow-master.ai    -> localhost:5000 (frontend) / 5001 (API)
    +---> dev.flow-master.ai     -> localhost:6000 (frontend) / 6001 (API)
    +---> staging.flow-master.ai -> localhost:4000 (frontend) / 4001 (API)
    +---> app.flow-master.ai     -> localhost:3002 (frontend) / 3001 (API)
    |
    v
[Docker Compose Services]
    ├─ Backend (Python FastAPI)
    └─ Frontend (React + Nginx)
```

## Deployment Configuration

### CI/CD Pipeline

**Platform:** GitLab CI/CD

**Pipeline Stages:**
```
detect-changes -> test -> build -> deploy
```

**Timeline:** ~10-15 minutes per deployment

### Pipeline Stages Breakdown

#### Stage 1: Detect Changes (30s)
- Identifies backend and frontend changes
- Sets `BACKEND_CHANGED` and `FRONTEND_CHANGED` flags
- Always passes (informational only)

#### Stage 2: Test (2-3 min each)
- **test-backend:** Python linting (Pylint >= 5.0) + unit tests (pytest)
- **test-frontend:** TypeScript check + npm build (< 10MB bundle)
- **security-trivy:** Vulnerability scan (non-blocking)
- **security-secrets:** Secret detection (blocking)

#### Stage 3: Build (3-5 min total)
- **build-backend:** Docker image build using `backend/Dockerfile.production`
- **build-frontend:** Docker image build using `frontend/Dockerfile.production`
- **integration-tests:** Full stack test with health checks

#### Stage 4: Deploy (2-3 min)
Environment-specific deployment jobs:
- `deploy-production` (manual trigger only)
- `deploy-staging`
- `deploy-demo`
- `deploy-development`

### Deployment Process

1. Developer pushes to branch (e.g., `staging`)
2. GitLab triggers pipeline
3. Code goes through detect-changes, test, and build stages
4. SSH to server via deployment job
5. Pull latest code from branch
6. Stop existing containers (`docker compose down`)
7. Start new containers with build (`docker compose up -d --build`)
8. Wait for health checks to pass
9. Verify containers running

### Required GitLab CI/CD Variables

**Connection Variables:**
- `SSH_PRIVATE_KEY` - SSH key for server access
- `SERVER_HOST` - Server IP (91.98.159.56)
- `DEPLOY_PATH` - Deployment directory path (per environment)
- `APP_URL` - Application URL (per environment)

**Database Variables:**
- `ARANGO_HOST`, `ARANGO_PORT` (8529), `ARANGO_USER`, `ARANGO_PASSWORD`, `ARANGO_DB`
- `POSTGRES_GLOBAL_HOST`, `POSTGRES_GLOBAL_PORT` (5432), `POSTGRES_GLOBAL_USER`, `POSTGRES_GLOBAL_PASSWORD`, `POSTGRES_GLOBAL_DB`
- `REDIS_HOST`, `REDIS_PORT` (6379), `REDIS_PASSWORD`

**Security Variables:**
- `JWT_SECRET` - JWT signing secret
- `ENCRYPTION_KEY` - Data encryption key
- `SECRET_KEY` - Application secret key

**API Keys:**
- `GEMINI_API_KEY` - Google Gemini API key
- `OPENAI_API_KEY` - OpenAI API key
- `OPENROUTER_API_KEY` - OpenRouter API key

## Infrastructure Requirements

### Docker Configuration

#### Backend Service

**Base Image:** python:3.11-slim (multi-stage build)

**Key Specifications:**
- Health check: `curl http://localhost:8000/api/health`
- Health check interval: 30s, timeout: 10s, retries: 3, start period: 40s
- Runs as non-root user: `appuser`
- Workers: 4 (uvicorn)
- Port exposure: 8000 (internal)

**Multi-stage Build:**
- Builder stage: Installs gcc, g++, libpq-dev for compilation
- Runtime stage: Includes libpq5, curl; copies packages from builder

#### Frontend Service

**Base Image:** node:20-alpine (builder) + nginx:alpine (serve)

**Key Specifications:**
- Health check: `wget http://localhost:80/`
- Health check interval: 30s, timeout: 3s, retries: 3
- Port exposure: 80 (internal)
- Depends on backend service with condition: `service_healthy`

**Build Process:**
- npm ci for dependency installation
- npm run build for production bundle
- Copy built files to `/usr/share/nginx/html`

#### Docker Compose

**Services Relationship:**
- Frontend depends on backend being healthy
- Services communicate via Docker network (aliases: backend/frontend)
- Environment variables loaded from `.env.{environment}` file

**Network Configuration:**
- Each environment has isolated Docker network
- Services accessible by service names internally
- Port mappings expose services to host

### Nginx Configuration

#### Server Nginx (Host-level)

**Purpose:** SSL termination and reverse proxy

**Features:**
- HTTP to HTTPS redirect (port 80 -> 443)
- SSL certificates via Let's Encrypt
- Proxies frontend requests to Docker containers
- Proxies API requests with 3600s timeout (for AI operations)
- WebSocket proxy with 86400s timeout (24 hours)
- Client max body size: 50MB

**Per-domain blocks:**
```nginx
# HTTP redirect
server {
    listen 80;
    server_name {domain};
    return 301 https://$server_name$request_uri;
}

# HTTPS with SSL
server {
    listen 443 ssl http2;
    server_name {domain};
    ssl_certificate /etc/letsencrypt/live/{domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{domain}/privkey.pem;
}
```

#### Container Nginx (Frontend container)

**Purpose:** Serve React SPA and proxy API to backend

**Features:**
- Gzip compression (70-80% size reduction)
- Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)
- API proxy to backend on `/api/` routes
- WebSocket proxy on `/ws/` routes
- SPA routing (try_files for React routing)

### Technology Stack

- **CI/CD:** GitLab CI
- **Container Runtime:** Docker + Docker Compose
- **Web Server:** Nginx (reverse proxy + static serving)
- **SSL/TLS:** Let's Encrypt with auto-renewal via certbot
- **Backend:** Python 3.11 + FastAPI + uvicorn (4 workers)
- **Frontend:** Node.js 20 + React + Vite (built to static files)

## When to Use This Skill

### Use this skill when:

1. **Deploying FlowMaster applications**
   - Understanding deployment process and environment setup
   - Troubleshooting deployment failures
   - Setting up CI/CD pipelines

2. **Managing production infrastructure**
   - SSL certificate renewal and management
   - Port allocation and network configuration
   - Environment variable configuration

3. **Debugging container issues**
   - Backend health checks failing
   - Frontend container startup problems
   - Docker compose troubleshooting

4. **Scaling or modifying environments**
   - Adding new environment variables
   - Adjusting port allocations
   - Modifying health checks

5. **Performance optimization**
   - Configuring Nginx compression
   - Adjusting Docker resource limits
   - Optimizing build stages

### Common Troubleshooting Commands

```bash
# Check all FlowMaster containers
docker ps -a | grep flowmaster

# View backend logs
docker logs flowmaster-staging-backend --tail 100 -f

# View frontend logs
docker logs flowmaster-staging-frontend --tail 100 -f

# Check backend health
docker inspect flowmaster-staging-backend --format='{{.State.Health.Status}}'

# Test health endpoint
docker exec flowmaster-staging-backend curl -v http://localhost:8000/api/health

# Restart specific environment
cd /srv/flowmaster/staging
docker compose -f docker-compose.staging.yml restart

# Full rebuild
docker compose -f docker-compose.staging.yml down
docker compose -f docker-compose.staging.yml up -d --build

# Check Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Pass/Fail Criteria for CI/CD

| Stage | Requirement |
|-------|-------------|
| test-backend | Pylint >= 5.0, pytest passes |
| test-frontend | Build succeeds, bundle < 10MB |
| security-secrets | No verified secrets found |
| build-backend | Docker build succeeds |
| build-frontend | Docker build succeeds |
| integration-tests | Both backend and frontend health checks pass |
| deploy | Containers running with healthy status |

### Manual Deployment

When CI/CD fails, manual deployment steps:

```bash
# SSH to server
ssh root@91.98.159.56

# Navigate to environment
cd /srv/flowmaster/staging

# Pull latest code
git fetch origin
git checkout staging
git pull origin staging

# Update environment file
nano environments/.env.staging

# Rebuild and restart
docker compose -f docker-compose.staging.yml down
docker compose -f docker-compose.staging.yml up -d --build

# Verify
docker ps | grep flowmaster-staging
docker logs flowmaster-staging-backend --tail 50
```

### Request Flow Examples

**Frontend Request:**
```
User Browser
    |
    v
https://staging.flow-master.ai/dashboard
    |
    v
[Server Nginx :443]
    | SSL termination
    | proxy_pass http://127.0.0.1:4000
    v
[Container frontend :4000->80]
    |
    v
[Container Nginx]
    | try_files -> /index.html
    v
React SPA handles /dashboard route
```

**API Request:**
```
User Browser
    |
    v
https://staging.flow-master.ai/api/users
    |
    v
[Server Nginx :443]
    | SSL termination
    | proxy_pass http://127.0.0.1:4001
    v
[Container backend :4001->8000]
    |
    v
FastAPI handles /api/users
```
