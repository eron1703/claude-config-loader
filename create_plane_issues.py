#!/usr/bin/env python3
"""
Create all FlowMaster work items in Plane
Reads from:
- Planning agent output file
- Infrastructure work items markdown
Creates:
- Epics, User Stories, Infrastructure/Config/Test tasks
"""

import subprocess
import json
import re

PLANE_SERVER = "demo-server"
PROJECT = "FM"

# Infrastructure work items from flowmaster-work-items.md
infrastructure_items = [
    {
        "id": "INF-001",
        "title": "Kafka Message Queue Infrastructure Setup",
        "priority": "P0",
        "complexity": "L",
        "description": """Set up production-ready Kafka cluster for FlowMaster's event-driven architecture. Includes broker configuration, Zookeeper ensemble, and topic management.

Topics: process_events, execution_events, human_task_events, agent_task_events, system_events

Configuration:
- 3 Kafka brokers
- 3 Zookeeper nodes
- Kafka Connect for integrations
- Schema registry""",
        "acceptance_criteria": [
            "Kafka cluster running with 3 brokers",
            "Zookeeper ensemble operational",
            "All required topics created",
            "Kafka UI accessible at localhost:8080",
            "Producer/consumer tests pass",
            "Health checks return healthy status"
        ]
    },
    {
        "id": "INF-002",
        "title": "Redis Cache Infrastructure Setup",
        "priority": "P0",
        "complexity": "M",
        "description": """Set up Redis cache infrastructure with Sentinel for high availability. Supports session caching, WebSocket pub/sub, and distributed locking.

Components:
- Redis primary (port 6379)
- 2 read replicas (ports 6380, 6381)
- 3 Sentinel nodes for HA

Cache namespaces: sessions, execution_state, websocket_channels, rate_limits, locks""",
        "acceptance_criteria": [
            "Redis primary accepting connections",
            "2 replicas syncing from primary",
            "Sentinel monitoring cluster",
            "Automatic failover working",
            "Pub/sub functionality verified",
            "Session storage tested",
            "Rate limiting tested",
            "Distributed locks working"
        ]
    },
    {
        "id": "INF-003",
        "title": "ArangoDB Database Setup & Optimization",
        "priority": "P0",
        "complexity": "L",
        "description": """Configure and optimize ArangoDB for FlowMaster's graph-based process and execution data.

Collections:
- 45+ document collections
- 15+ edge collections
- Process layer, execution layer, human tasks, agent layer

Indexes on:
- organization_id, tenant_id, owner
- execution_id, agent_ids
- task status, assignee, created_at""",
        "acceptance_criteria": [
            "ArangoDB accessible at localhost:8529",
            "Database 'flowmaster' created",
            "All 45+ document collections created",
            "All 15+ edge collections created",
            "Indexes created on key fields",
            "Backup script working",
            "Restore script tested",
            "Query performance <100ms for indexed queries"
        ]
    },
    {
        "id": "INF-004",
        "title": "PostgreSQL Per-Service Databases",
        "priority": "P1",
        "complexity": "M",
        "description": """Set up PostgreSQL instance with separate databases for each microservice requiring relational data.

Databases:
- auth_service_db: User authentication and sessions
- config_service_db: System configuration
- analytics_db: Logging and analytics data

Configuration:
- max_connections: 200
- shared_buffers: 2GB
- effective_cache_size: 6GB""",
        "acceptance_criteria": [
            "PostgreSQL accessible at localhost:5432",
            "All service databases created",
            "Service users created with proper privileges",
            "Connection pooling configured",
            "Backup/restore scripts working",
            "Performance tuning applied"
        ]
    },
    {
        "id": "INF-005",
        "title": "Docker Network & Volume Strategy",
        "priority": "P0",
        "complexity": "S",
        "description": """Establish Docker networking and volume management strategy for all FlowMaster services.

Network:
- flowmaster-network (bridge mode)
- Service discovery via DNS

Volumes:
- Named volumes for all databases
- Backup volume mounts
- Log volume strategy""",
        "acceptance_criteria": [
            "flowmaster-network created",
            "All services can communicate",
            "DNS resolution working",
            "Named volumes configured",
            "Backup access verified",
            "Volume permissions correct"
        ]
    },
    {
        "id": "INF-006",
        "title": "API Gateway & Service Mesh",
        "priority": "P1",
        "complexity": "L",
        "description": """Implement API Gateway (Nginx/Kong) and service mesh for microservice communication.

Features:
- Request routing
- Load balancing
- Rate limiting
- Authentication/Authorization
- Circuit breaking
- Service discovery""",
        "acceptance_criteria": [
            "API Gateway operational",
            "All service routes configured",
            "Load balancing working",
            "Rate limiting enforced",
            "Auth middleware active",
            "Health checks integrated"
        ]
    },
    {
        "id": "INF-007",
        "title": "Monitoring Stack (Prometheus + Grafana)",
        "priority": "P2",
        "complexity": "M",
        "description": """Set up comprehensive monitoring with Prometheus and Grafana.

Metrics:
- Service health
- Resource usage (CPU, memory, disk)
- Request rates and latencies
- Database performance
- Kafka throughput

Dashboards:
- System overview
- Service-specific metrics
- Database performance
- Kafka monitoring""",
        "acceptance_criteria": [
            "Prometheus scraping all services",
            "Grafana dashboards created",
            "Alerting rules configured",
            "Retention policy set",
            "Historical data accessible"
        ]
    },
    {
        "id": "INF-008",
        "title": "Logging Stack (ELK/Loki)",
        "priority": "P2",
        "complexity": "M",
        "description": """Centralized logging infrastructure with Elasticsearch/Loki + Kibana/Grafana.

Components:
- Log aggregation
- Log shipping (Filebeat/Promtail)
- Log storage
- Search and visualization
- Log retention policies""",
        "acceptance_criteria": [
            "All service logs centralized",
            "Log search working",
            "Log dashboards created",
            "Retention policies active",
            "Alert rules configured"
        ]
    },
    {
        "id": "INF-009",
        "title": "Backup & Disaster Recovery",
        "priority": "P1",
        "complexity": "M",
        "description": """Automated backup strategy for all data stores with disaster recovery procedures.

Backup targets:
- ArangoDB (daily full + incremental)
- PostgreSQL (hourly)
- Redis (snapshots)
- Kafka (topic replication)

DR procedures:
- Restore playbooks
- RTO: 4 hours
- RPO: 1 hour""",
        "acceptance_criteria": [
            "Automated backups running",
            "Backup verification working",
            "Restore procedures tested",
            "Off-site backup storage configured",
            "DR documentation complete"
        ]
    },
    {
        "id": "INF-010",
        "title": "CI/CD Pipeline Setup",
        "priority": "P1",
        "complexity": "L",
        "description": """GitHub Actions or GitLab CI pipeline for automated build, test, and deployment.

Stages:
- Code quality (lint, format)
- Unit tests
- Integration tests
- Container build
- Security scanning
- Automated deployment to staging
- Manual approval for production""",
        "acceptance_criteria": [
            "Pipeline running on commits",
            "All tests passing",
            "Container images built",
            "Security scans active",
            "Staging deployment automated",
            "Production deployment gated"
        ]
    },
    {
        "id": "INF-011",
        "title": "Secret Management (Vault/Docker Secrets)",
        "priority": "P1",
        "complexity": "M",
        "description": """Secure secret management for credentials, API keys, certificates.

Features:
- Secret encryption at rest
- Access control policies
- Secret rotation
- Audit logging
- Integration with services""",
        "acceptance_criteria": [
            "Vault operational",
            "All secrets migrated",
            "Access policies configured",
            "Rotation policies active",
            "Audit log accessible"
        ]
    },
    {
        "id": "INF-012",
        "title": "Service Health Checks & Auto-Recovery",
        "priority": "P2",
        "complexity": "M",
        "description": """Implement health check endpoints and auto-recovery mechanisms for all services.

Health checks:
- Liveness probes
- Readiness probes
- Dependency checks

Auto-recovery:
- Automatic restarts
- Circuit breakers
- Graceful degradation""",
        "acceptance_criteria": [
            "All services have health endpoints",
            "Docker health checks configured",
            "Auto-restart working",
            "Circuit breakers tested",
            "Graceful degradation verified"
        ]
    },
    {
        "id": "INF-013",
        "title": "Load Testing Infrastructure",
        "priority": "P2",
        "complexity": "M",
        "description": """Set up load testing tools and procedures for performance validation.

Tools:
- k6 or Gatling for load testing
- Test scenarios for critical paths
- Performance benchmarking
- Bottleneck identification

Targets:
- 1000 concurrent users
- <200ms API response time
- <3s page load time""",
        "acceptance_criteria": [
            "Load testing tools configured",
            "Test scenarios created",
            "Baseline performance measured",
            "Bottlenecks identified",
            "Performance report generated"
        ]
    },
    {
        "id": "INF-014",
        "title": "Documentation Infrastructure",
        "priority": "P2",
        "complexity": "S",
        "description": """Set up documentation platform and processes.

Components:
- API documentation (Swagger/OpenAPI)
- Architecture diagrams (PlantUML/Mermaid)
- Runbooks and playbooks
- User guides
- Developer documentation

Platform: Docusaurus or MkDocs""",
        "acceptance_criteria": [
            "Documentation platform deployed",
            "API docs auto-generated",
            "Architecture diagrams created",
            "Runbooks documented",
            "Search functionality working"
        ]
    },
    {
        "id": "INF-015",
        "title": "Development Environment Standardization",
        "priority": "P2",
        "complexity": "S",
        "description": """Standardize development environment setup for team consistency.

Components:
- Docker Compose for local development
- Development database seeds
- Environment variable templates
- IDE configurations (VS Code)
- Pre-commit hooks
- Documentation

Goal: New developer productive in <1 hour""",
        "acceptance_criteria": [
            "Docker Compose working",
            "Database seeds functional",
            "Environment templates provided",
            "IDE configs shared",
            "Pre-commit hooks active",
            "Setup documentation complete"
        ]
    }
]

def create_plane_issue(title, description, priority="medium", labels=None, parent_id=None):
    """Create a Plane issue using plane-cli"""

    # Map priority codes to Plane priority levels
    priority_map = {
        "P0": "urgent",
        "P1": "high",
        "P2": "medium",
        "P3": "low"
    }

    # Build command
    cmd = [
        "plane-cli",
        "issue", "create",
        "-s", PLANE_SERVER,
        "-p", PROJECT,
        "-t", title,
        "-d", description,
        "--priority", priority
    ]

    if labels:
        for label in labels:
            cmd.extend(["--label", label])

    if parent_id:
        cmd.extend(["--parent", parent_id])

    # Execute command
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode == 0:
        # Extract issue ID from output
        output = result.stdout
        # Look for issue ID pattern like FM-123
        match = re.search(r'(FM-\d+)', output)
        if match:
            return match.group(1)

    return None

def create_infrastructure_issues():
    """Create all infrastructure work items"""
    created = []

    for item in infrastructure_items:
        # Format description with acceptance criteria
        desc = item["description"]
        if item.get("acceptance_criteria"):
            desc += "\n\n## Acceptance Criteria\n"
            for criteria in item["acceptance_criteria"]:
                desc += f"- [ ] {criteria}\n"

        # Map priority
        priority_map = {
            "P0": "urgent",
            "P1": "high",
            "P2": "medium",
            "P3": "low"
        }
        priority = priority_map.get(item["priority"], "medium")

        # Create issue
        issue_id = create_plane_issue(
            title=f"[{item['id']}] {item['title']}",
            description=desc,
            priority=priority,
            labels=["infrastructure", item["complexity"]]
        )

        if issue_id:
            created.append({
                "original_id": item["id"],
                "plane_id": issue_id,
                "title": item["title"],
                "type": "Infrastructure Task"
            })
            print(f"✅ Created {issue_id}: {item['title']}")
        else:
            print(f"❌ Failed to create {item['id']}")

    return created

def main():
    print("=" * 80)
    print("FlowMaster Plane Issue Creation")
    print("=" * 80)
    print()

    # Create infrastructure issues
    print("Creating Infrastructure Work Items...")
    infra_issues = create_infrastructure_issues()

    print()
    print("=" * 80)
    print(f"SUMMARY: Created {len(infra_issues)} issues")
    print("=" * 80)

    for issue in infra_issues:
        print(f"{issue['plane_id']}: [{issue['original_id']}] {issue['title']}")

if __name__ == "__main__":
    main()
