---
name: worker-frontend
description: Frontend repository, build process, deployment, and development setup
disable-model-invocation: true
---

# Worker Frontend Knowledge

## Repository

### GitLab (Source of Truth)
- **URL**: gitlab.com/flow-master/flowmaster-frontend-nextjs
- **IMPORTANT**: Name is **flowmaster-frontend-nextjs** (not frontend-nextjs)

### GitHub (Public Mirror)
- **URL**: github.com/HCB-Consulting-ME/frontend-nextjs
- **Access**: Standard SSH or HTTPS (no special credentials needed)

### Local Clone
- **Location**: ~/projects/flowmaster/repos/flowmaster-frontend-nextjs/
- **Branch**: typically `main` or `develop`

## Tech Stack

- **Framework**: Next.js 15 with App Router (NOT Pages Router)
- **Language**: TypeScript
- **CSS**: Tailwind CSS
- **UI Components**: shadcn/ui
- **Package Manager**: npm or yarn

## Directory Structure

```
src/
├── app/              # Next.js app routes (pages)
│   ├── page.tsx
│   ├── dashboard/
│   └── [dynamic]/
├── features/         # Domain-specific logic (components, hooks, utils)
│   ├── processes/
│   ├── workflows/
│   └── auth/
├── components/       # Shared UI components
│   └── ui/          # shadcn/ui components
└── lib/             # Utilities (API clients, helpers)
```

## Development

### Local Development
```bash
cd ~/projects/flowmaster/repos/flowmaster-frontend-nextjs/
npm install
npm run dev
# Opens on http://localhost:3000
```

### Build
```bash
npm run build
```

### Lint & Format
```bash
npm run lint
npm run format
```

## Docker Build and Deployment

### Build Docker Image
```bash
docker build --platform linux/amd64 \
  -t localhost:30500/flowmaster/frontend-nextjs:<tag> \
  --build-arg API_GATEWAY_URL=http://api-gateway:9000 \
  .
```

### Push to K3S Registry
```bash
docker push localhost:30500/flowmaster/frontend-nextjs:<tag>
```

### Deploy to K3S
```bash
ssh dev-01-root "kubectl set image -n flowmaster \
  deploy/frontend \
  frontend=localhost:30500/flowmaster/frontend-nextjs:<tag>"
```

## Build Arguments

These are passed during Docker build and embedded in the image:

- **API_GATEWAY_URL**: `http://api-gateway:9000` (K8S internal URL, not used by browser)
- **NEXT_PUBLIC_API_URL**: (empty) — Browser uses Nginx `/api/` proxy
- **NEXT_PUBLIC_WS_URL**: `ws://65.21.153.235/ws` (WebSocket URL for real-time features)
- **NEXT_PUBLIC_NODE_ENV**: `production` (or `development`)

### Build Argument Sources
- `.gitlab-ci.yml` - Defines all build args for CI/CD
- `deploy-demo-template.yml` - Kubernetes deployment template with DOCKER_BUILD_ARGS variable

## K3S Deployment

### Deployment Details
- **Service**: frontend
- **Port**: 3000 (Next.js internal)
- **Namespace**: flowmaster
- **ClusterIP**: 10.43.185.219:3000 (hardcoded in Nginx)
- **imagePullPolicy**: Always

### Check Deployment Status
```bash
ssh dev-01-root "kubectl -n flowmaster get deploy frontend"
ssh dev-01-root "kubectl -n flowmaster describe deploy frontend"
```

### View Logs
```bash
ssh dev-01-root "kubectl logs -n flowmaster deploy/frontend --tail=50"
```

### Check Health
```bash
ssh dev-01-root "kubectl exec -n flowmaster deploy/frontend -- wget -qO- http://localhost:3000/"
```

## Authentication

### Default Credentials (From Memory)
- **Email**: admin@flowmaster.dev OR admin@flowmaster.ai
- **Password**: FlowMaster2026! OR admin

**Note**: Login page shows `admin@flowmaster.dev` but API gateway may use `admin@flowmaster.ai` - this is a known mismatch.

### Authentication Flow
1. User enters credentials on login page
2. Frontend sends request to `/api/v1/auth/login`
3. Gateway routes to auth-service
4. Token returned and stored in browser session/localStorage

## Nginx Configuration

Frontend is accessed via:
- **Route**: `/` (root path)
- **Nginx proxy**: 10.43.185.219:3000
- **Config file**: `/etc/nginx/sites-enabled/flowmaster`

## API Integration

### API Routes in Frontend
All API calls use `/api/` prefix:
```typescript
// In frontend code
const response = await fetch('/api/v1/processes');

// Browser sends: GET /api/v1/processes
// Nginx routes to: api-gateway:9000/api/v1/processes
// Gateway routes to: process-design:9003/api/v1/processes
```

### WebSocket Connection
```typescript
const ws = new WebSocket('ws://65.21.153.235/ws');

// Or from K8S:
const ws = new WebSocket('ws://<pod-ip>:9010');
```

## Common Issues

### Build Fails
- Check `npm install` succeeds locally
- Verify build args are passed to docker build
- Check Docker platform matches (linux/amd64)

### Page Not Loading
- Verify Nginx is routing to ClusterIP 10.43.185.219:3000
- Check frontend pod is running: `kubectl -n flowmaster get pods | grep frontend`
- Check frontend logs: `kubectl logs -n flowmaster deploy/frontend`

### API Not Responding
- Verify Nginx `/api/` route works: Check `/etc/nginx/sites-enabled/flowmaster`
- Verify API Gateway is running: `kubectl -n flowmaster get pods | grep api-gateway`
- Check Gateway logs: `kubectl logs -n flowmaster deploy/api-gateway`

## Key Facts
- Repository name on GitLab is **flowmaster-frontend-nextjs** (critical)
- Uses Next.js 15 App Router (modern, not legacy Pages)
- API calls use `/api/` prefix proxied through Nginx
- WebSocket uses ws:// to websocket-gateway service
- Default ClusterIP in Nginx is 10.43.185.219:3000 (will change if pod recreated)
- Build args control environment at Docker build time
- No sensitive data in frontend code (auth tokens in browser storage/session)
