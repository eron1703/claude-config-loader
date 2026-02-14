---
name: worker-database
description: Database credentials, URLs, collections, and connection patterns
disable-model-invocation: true
---

# Worker Database Knowledge

## Databases on Dev-01 Server (65.21.153.235)

All databases run in the `databases-test` namespace on K3S.

### ArangoDB (Multi-model)

**Connection Details**:
- **Port**: 8529
- **User**: root
- **Password**: flowmaster25!
- **K8S URL**: http://arangodb.databases-test.svc.cluster.local:8529
- **Web UI**: http://65.21.153.235:8529 (from dev-01)

**Databases**:
- `flowmaster` - Production data
- `flowmaster_test` - Test environment
- `flowmaster_dev` - Development environment

**Key Collections**:
- `process_definitions` - BPMN/workflow definitions
- `process_instances` - Running workflow instances
- `agent_sessions` - AI agent conversation history
- `knowledge_items` - RAG/knowledge base documents
- `schedules` - Scheduled tasks and triggers
- `node_executions` - Execution logs per process node
- `business_rules` - DMN rules and conditions

**Query Pattern**:
```
FOR doc IN process_definitions
FILTER doc.type == "workflow"
RETURN doc
```

### PostgreSQL (Relational)

**Connection Details**:
- **Port**: 5432
- **User**: postgres
- **Password**: flowmaster25!
- **K8S URL**: postgres-clusterip.databases-test.svc.cluster.local:5432
- **CLI**: `psql -h localhost -U postgres`

**Databases**:
- `flowmaster_core` - Auth, RBAC, permissions
- `flowmaster_users` - User profiles and settings
- `flowmaster_workflow` - Workflow execution state

**ORM**: Prisma (used in auth-service)

**Prisma Schema Location**:
- auth-service repository: `prisma/schema.prisma`

### Redis (Cache/Queue)

**Connection Details**:
- **Port**: 6379
- **Authentication**: None
- **K8S URL**: redis.databases-test.svc.cluster.local:6379

**Environment Variable**:
- `REDIS_URL=redis://redis.databases-test.svc.cluster.local:6379`

**Used By**:
- `event-bus` - Event routing and queuing
- `ai-agent` - Session caching
- `prompt-engineering` - Prompt cache
- `scheduling` - Job scheduling

**CLI**: `redis-cli` or `redis-cli -h redis.databases-test.svc.cluster.local`

## Database Access from Local Machine

### Via SSH Tunnel
```bash
# Create tunnel for ArangoDB
ssh dev-01-root -L 8529:arangodb.databases-test.svc.cluster.local:8529 -N &

# Create tunnel for PostgreSQL
ssh dev-01-root -L 5432:postgres-clusterip.databases-test.svc.cluster.local:5432 -N &

# Create tunnel for Redis
ssh dev-01-root -L 6379:redis.databases-test.svc.cluster.local:6379 -N &

# Now connect locally
arangosh --server.endpoint http://127.0.0.1:8529 --server.username root --server.password flowmaster25!
psql -h localhost -U postgres -d flowmaster_core
redis-cli -p 6379
```

## Common Database Operations

### ArangoDB: Insert Document
```javascript
db.process_definitions.insert({
  _key: "workflow_123",
  name: "Approval Workflow",
  version: "1.0",
  type: "workflow",
  definition: { /* BPMN */ }
})
```

### ArangoDB: Query with Filter
```javascript
FOR doc IN process_instances
FILTER doc.status == "running"
LIMIT 10
RETURN doc
```

### PostgreSQL: User Query
```sql
SELECT id, email, role FROM users WHERE role = 'admin';
```

### PostgreSQL: RBAC Query
```sql
SELECT p.*, r.name FROM permissions p
JOIN roles r ON p.role_id = r.id
WHERE p.resource = 'process_design';
```

### Redis: Get Value
```bash
redis-cli GET session:user_123
```

### Redis: Publish Event
```bash
redis-cli PUBLISH events:workflow '{"type":"started","id":"123"}'
```

## Key Facts
- All databases are in `databases-test` namespace (despite name, used for production)
- ArangoDB is primary for workflow/domain data (BPMN, processes, knowledge)
- PostgreSQL is for auth and RBAC (smaller, relational)
- Redis is for caching and event distribution (high-speed in-memory)
- All default password is `flowmaster25!`
- K8S service URLs use `.databases-test.svc.cluster.local` domain
- SSH tunnels needed to access databases from local machine
