# Shared Development Tools - dev-01

**Server:** dev-01 (65.21.153.235) | Helsinki | Hetzner CCX23 16GB

These are preparation configs for the shared development tools that run alongside FlowMaster on dev-01. All developers and agents use these tools.

## Tools Overview

| Tool | Port | URL | Purpose |
|------|------|-----|---------|
| **Plane** | 8083 | `http://65.21.153.235:8083` | Project management (Jira alternative) |
| **Grafana** | 3001 | `http://65.21.153.235:3001` | Monitoring dashboards |
| **Prometheus** | 9090 | `http://65.21.153.235:9090` | Metrics collection |
| **Node Exporter** | 9100 | `http://65.21.153.235:9100` | Host metrics |
| **Agent Chat** | 8099 | `http://65.21.153.235:8099` | Agent communication & telemetry |

## Port Map (Full Server)

```
Port   | Service              | Stack
-------|----------------------|------------------
80     | Nginx reverse proxy  | System service
3000   | FlowMaster Frontend  | FlowMaster (K3S)
3001   | Grafana              | Shared Tools
3010   | SDX Frontend         | SDX (Docker)
5432   | PostgreSQL           | FlowMaster
5433   | PostgreSQL (Plane)   | Shared Tools
8000   | FlowMaster Backend   | FlowMaster (K3S)
8010   | SDX Backend          | SDX (Docker)
8011   | SDX MCP Server       | SDX (Docker)
8083   | Plane Web UI         | Shared Tools
8099   | Agent Chat/Telemetry | Shared Tools
8529   | ArangoDB             | FlowMaster/SDX
9090   | Prometheus           | Shared Tools
9100   | Node Exporter        | Shared Tools
```

## Tool Details

### Plane (Project Management)

Open-source project management tool. Used for tracking FlowMaster requirements, sprint planning, and agent work assignments.

- **Web UI:** http://65.21.153.235:8083
- **API:** http://65.21.153.235:8083/api/v1/
- **API Key:** Stored in GitLab CI/CD variable `PLANE_API_KEY`
- **Workspace:** `flowmaster`
- **Components:** proxy, web, admin, space, live, api, worker, beat-worker, db, redis, minio

API example:
```bash
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "http://65.21.153.235:8083/api/v1/workspaces/flowmaster/projects/$PLANE_PROJECT_ID/issues/?per_page=200"
```

### Grafana (Monitoring)

Dashboards for server metrics, container health, and application performance.

- **Web UI:** http://65.21.153.235:3001
- **Default login:** admin / (see GitLab CI/CD: `GRAFANA_ADMIN_PASSWORD`)
- **Data source:** Prometheus at http://prometheus:9090

### Prometheus (Metrics)

Collects and stores time-series metrics from node-exporter and application endpoints.

- **Web UI:** http://65.21.153.235:9090
- **Config:** `./prometheus/prometheus.yml`
- **Retention:** 30 days
- **Targets:** node-exporter, K3S metrics (if configured)

### Node Exporter

Exports host-level metrics (CPU, memory, disk, network) to Prometheus.

- **Metrics:** http://65.21.153.235:9100/metrics

### Agent Chat / Telemetry

Lightweight Node.js service for agent communication and telemetry collection.

- **Endpoint:** http://65.21.153.235:8099
- **Health:** http://65.21.153.235:8099/health

## Nginx Configuration

Nginx runs as a system service (not in Docker). Below is the configuration needed for shared tools. Add to `/etc/nginx/sites-available/shared-tools`:

```nginx
# Plane - Project Management
server {
    listen 80;
    server_name plane.dev-01.internal;

    location / {
        proxy_pass http://127.0.0.1:8083;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 5M;
    }
}

# Grafana - Monitoring
server {
    listen 80;
    server_name grafana.dev-01.internal;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Agent Chat / Telemetry
server {
    listen 80;
    server_name agent.dev-01.internal;

    location / {
        proxy_pass http://127.0.0.1:8099;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

After adding, enable and reload:
```bash
sudo ln -s /etc/nginx/sites-available/shared-tools /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

## Deployment

### Prerequisites
1. Copy `.env.shared-tools` to the server and update all `CHANGE_ME_*` values
2. Create Prometheus config directory: `mkdir -p prometheus/`
3. Create a basic `prometheus/prometheus.yml` (see below)
4. If using agent-chat, ensure `agent-chat/server.js` exists

### Prometheus Config

Create `prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'grafana'
    static_configs:
      - targets: ['grafana:3000']
```

### Deploy Commands
```bash
# On dev-01 (65.21.153.235)
cd /srv/shared-tools  # or wherever you place this

# Copy env file
cp .env.shared-tools .env

# Start specific services (NEVER docker compose up without specifying)
docker compose -f docker-compose.shared-tools.yml up -d plane-db plane-redis plane-minio
docker compose -f docker-compose.shared-tools.yml up -d plane-api plane-worker plane-beat-worker
docker compose -f docker-compose.shared-tools.yml up -d plane-web plane-space plane-admin plane-live plane-proxy
docker compose -f docker-compose.shared-tools.yml up -d prometheus node-exporter grafana
docker compose -f docker-compose.shared-tools.yml up -d agent-chat
```

### Adding New Shared Tools

1. Add the service definition to `docker-compose.shared-tools.yml`
2. Add environment variables to `.env.shared-tools`
3. Update the port map in this README
4. Add nginx config if the tool needs a domain name
5. Document the tool in the Tools Overview table above
6. Store sensitive credentials in GitLab CI/CD variables

## Memory Budget

dev-01 has 16GB RAM. Approximate memory allocation:

```
FlowMaster K3S cluster    ~8 GB  (29 pods + infrastructure)
Plane stack               ~3 GB  (13 containers)
Monitoring stack          ~1 GB  (Grafana + Prometheus + Node Exporter)
Agent Chat                ~0.25 GB
SDX Platform              ~0.5 GB  (3 containers)
System / OS               ~1.5 GB
Buffer                    ~1.75 GB
```

The server is tight on memory (~3GB available as of 2026-02-11). Monitor with `htop` or Grafana and consider scaling down Plane workers if needed.
