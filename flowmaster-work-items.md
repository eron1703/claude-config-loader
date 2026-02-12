# FlowMaster Infrastructure, Configuration & Test Data Work Items

## Priority Legend
- **P0**: Blocking - Must have for MVP
- **P1**: Critical - Required for production
- **P2**: Important - Needed for full functionality
- **P3**: Nice to have - Enhances system

## Complexity Scale
- **XS**: 1-2 hours
- **S**: 2-4 hours
- **M**: 1-2 days
- **L**: 3-5 days
- **XL**: 1-2 weeks

---

# INFRASTRUCTURE WORK ITEMS

## INF-001: Kafka Message Queue Infrastructure Setup

**Priority**: P0 (Blocking)
**Complexity**: L (3-5 days)
**Category**: Infrastructure - Message Queue

### Description
Set up production-ready Kafka cluster for FlowMaster's event-driven architecture. This includes broker configuration, Zookeeper ensemble, and topic management for inter-service communication.

### Technical Specifications
```yaml
components:
  - kafka_brokers: 3 nodes (minimum for production)
  - zookeeper_ensemble: 3 nodes (quorum)
  - kafka_connect: For external integrations
  - schema_registry: For message schema management

network:
  - docker_network: flowmaster-network
  - kafka_ports: 9092 (internal), 9093 (external)
  - zookeeper_ports: 2181, 2888, 3888

configuration:
  retention_policy: 7 days (configurable per topic)
  partitions_default: 3
  replication_factor: 2
  min_insync_replicas: 1
```

### Service Contracts

**Topics to Create**:
```yaml
process_events:
  partitions: 5
  replication: 2
  retention: 7d

execution_events:
  partitions: 10
  replication: 2
  retention: 3d

human_task_events:
  partitions: 3
  replication: 2
  retention: 14d

agent_task_events:
  partitions: 5
  replication: 2
  retention: 7d

system_events:
  partitions: 3
  replication: 2
  retention: 30d
```

### Configuration Files Needed

**docker-compose.kafka.yml**:
```yaml
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    volumes:
      - zookeeper-data:/var/lib/zookeeper/data
      - zookeeper-logs:/var/lib/zookeeper/log
    networks:
      - flowmaster-network

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:9092,PLAINTEXT_HOST://localhost:9093
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: "false"
    volumes:
      - kafka-data:/var/lib/kafka/data
    networks:
      - flowmaster-network

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: flowmaster
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:9092
    depends_on:
      - kafka
    networks:
      - flowmaster-network

volumes:
  zookeeper-data:
  zookeeper-logs:
  kafka-data:

networks:
  flowmaster-network:
    external: true
```

**scripts/setup-kafka-topics.sh**:
```bash
#!/bin/bash
# Create all required Kafka topics

KAFKA_CONTAINER="flowmaster-kafka-1"

topics=(
  "process_events:5:2"
  "execution_events:10:2"
  "human_task_events:3:2"
  "agent_task_events:5:2"
  "system_events:3:2"
)

for topic_spec in "${topics[@]}"; do
  IFS=':' read -r topic partitions replication <<< "$topic_spec"

  docker exec $KAFKA_CONTAINER kafka-topics \
    --create \
    --topic $topic \
    --partitions $partitions \
    --replication-factor $replication \
    --if-not-exists \
    --bootstrap-server localhost:9092

  echo "Created topic: $topic"
done
```

### Testing Procedures

**Health Check**:
```bash
# Check Zookeeper
docker exec flowmaster-zookeeper-1 zkServer.sh status

# Check Kafka brokers
docker exec flowmaster-kafka-1 kafka-broker-api-versions \
  --bootstrap-server localhost:9092

# List topics
docker exec flowmaster-kafka-1 kafka-topics \
  --list \
  --bootstrap-server localhost:9092

# Test producer/consumer
docker exec flowmaster-kafka-1 kafka-console-producer \
  --topic test \
  --bootstrap-server localhost:9092

docker exec flowmaster-kafka-1 kafka-console-consumer \
  --topic test \
  --from-beginning \
  --bootstrap-server localhost:9092
```

### Rollback Procedures
```bash
# Stop Kafka services
docker-compose -f docker-compose.kafka.yml down

# Preserve data volumes
docker volume ls | grep kafka
docker volume ls | grep zookeeper

# Full cleanup (destructive)
docker-compose -f docker-compose.kafka.yml down -v
```

### Acceptance Criteria
- [ ] Kafka cluster running with 3 brokers
- [ ] Zookeeper ensemble operational
- [ ] All required topics created
- [ ] Kafka UI accessible at localhost:8080
- [ ] Producer/consumer tests pass
- [ ] Health checks return healthy status
- [ ] Message retention policies configured
- [ ] Monitoring dashboard shows metrics

### Dependencies
- Docker network: flowmaster-network must exist
- Sufficient disk space: 50GB minimum
- None (foundational infrastructure)

### Documentation Requirements
- Kafka architecture diagram
- Topic naming conventions
- Retention policy guide
- Monitoring and alerting setup
- Troubleshooting guide

---

## INF-002: Redis Cache Infrastructure Setup

**Priority**: P0 (Blocking)
**Complexity**: M (1-2 days)
**Category**: Infrastructure - Cache

### Description
Set up Redis cache infrastructure with Sentinel for high availability. Supports session caching, WebSocket pub/sub, and distributed locking.

### Technical Specifications
```yaml
components:
  - redis_primary: Main Redis instance
  - redis_replicas: 2 read replicas
  - redis_sentinel: 3 sentinel nodes for HA

ports:
  - redis_primary: 6379
  - redis_replica_1: 6380
  - redis_replica_2: 6381
  - sentinel: 26379

configuration:
  max_memory: 2GB
  eviction_policy: allkeys-lru
  persistence: RDB + AOF
  replica_sync: async
```

### Service Contracts

**Cache Namespaces**:
```yaml
sessions:
  prefix: "session:"
  ttl: 3600  # 1 hour

execution_state:
  prefix: "exec:"
  ttl: 86400  # 24 hours

websocket_channels:
  prefix: "ws:"
  ttl: null  # persistent

rate_limits:
  prefix: "ratelimit:"
  ttl: 60  # 1 minute

locks:
  prefix: "lock:"
  ttl: 30  # 30 seconds
```

### Configuration Files Needed

**docker-compose.redis.yml**:
```yaml
version: '3.8'
services:
  redis-primary:
    image: redis:7-alpine
    command: redis-server /usr/local/etc/redis/redis.conf
    ports:
      - "6379:6379"
    volumes:
      - redis-primary-data:/data
      - ./config/redis/redis-primary.conf:/usr/local/etc/redis/redis.conf
    networks:
      - flowmaster-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis-replica-1:
    image: redis:7-alpine
    command: redis-server /usr/local/etc/redis/redis.conf --replicaof redis-primary 6379
    ports:
      - "6380:6379"
    volumes:
      - redis-replica-1-data:/data
      - ./config/redis/redis-replica.conf:/usr/local/etc/redis/redis.conf
    depends_on:
      - redis-primary
    networks:
      - flowmaster-network

  redis-replica-2:
    image: redis:7-alpine
    command: redis-server /usr/local/etc/redis/redis.conf --replicaof redis-primary 6379
    ports:
      - "6381:6379"
    volumes:
      - redis-replica-2-data:/data
      - ./config/redis/redis-replica.conf:/usr/local/etc/redis/redis.conf
    depends_on:
      - redis-primary
    networks:
      - flowmaster-network

  redis-sentinel-1:
    image: redis:7-alpine
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    ports:
      - "26379:26379"
    volumes:
      - ./config/redis/sentinel.conf:/usr/local/etc/redis/sentinel.conf
    depends_on:
      - redis-primary
      - redis-replica-1
      - redis-replica-2
    networks:
      - flowmaster-network

volumes:
  redis-primary-data:
  redis-replica-1-data:
  redis-replica-2-data:

networks:
  flowmaster-network:
    external: true
```

**config/redis/redis-primary.conf**:
```conf
# Network
bind 0.0.0.0
protected-mode no
port 6379

# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Replication
min-replicas-to-write 1
min-replicas-max-lag 10

# Security
requirepass ${REDIS_PASSWORD}
```

**config/redis/sentinel.conf**:
```conf
port 26379
sentinel monitor flowmaster-primary redis-primary 6379 2
sentinel auth-pass flowmaster-primary ${REDIS_PASSWORD}
sentinel down-after-milliseconds flowmaster-primary 5000
sentinel parallel-syncs flowmaster-primary 1
sentinel failover-timeout flowmaster-primary 10000
```

### Scripts/Automation Required

**scripts/redis-health-check.sh**:
```bash
#!/bin/bash
# Check Redis cluster health

echo "Checking Redis primary..."
docker exec flowmaster-redis-primary-1 redis-cli -a $REDIS_PASSWORD ping

echo "Checking replication status..."
docker exec flowmaster-redis-primary-1 redis-cli -a $REDIS_PASSWORD info replication

echo "Checking Sentinel status..."
docker exec flowmaster-redis-sentinel-1-1 redis-cli -p 26379 sentinel masters
```

### Testing Procedures

**Functional Tests**:
```bash
# Test basic operations
redis-cli -a $REDIS_PASSWORD SET test "Hello World"
redis-cli -a $REDIS_PASSWORD GET test

# Test pub/sub
redis-cli -a $REDIS_PASSWORD SUBSCRIBE test_channel &
redis-cli -a $REDIS_PASSWORD PUBLISH test_channel "Test message"

# Test replication
redis-cli -h localhost -p 6379 -a $REDIS_PASSWORD SET key1 "value1"
redis-cli -h localhost -p 6380 -a $REDIS_PASSWORD GET key1

# Test failover
docker stop flowmaster-redis-primary-1
sleep 10
redis-cli -h localhost -p 26379 SENTINEL get-master-addr-by-name flowmaster-primary
```

### Rollback Procedures
```bash
# Stop Redis cluster
docker-compose -f docker-compose.redis.yml down

# Preserve data
docker volume ls | grep redis

# Full cleanup
docker-compose -f docker-compose.redis.yml down -v
```

### Acceptance Criteria
- [ ] Redis primary accepting connections
- [ ] 2 replicas syncing from primary
- [ ] Sentinel monitoring cluster
- [ ] Automatic failover working
- [ ] Pub/sub functionality verified
- [ ] Session storage tested
- [ ] Rate limiting tested
- [ ] Distributed locks working
- [ ] Memory limits enforced
- [ ] Persistence (RDB + AOF) confirmed

### Dependencies
- Docker network: flowmaster-network
- Environment variable: REDIS_PASSWORD

---

## INF-003: ArangoDB Database Setup & Optimization

**Priority**: P0 (Blocking)
**Complexity**: L (3-5 days)
**Category**: Infrastructure - Database

### Description
Configure and optimize ArangoDB for FlowMaster's graph-based process and execution data. Includes collection setup, indexing strategy, and backup procedures.

### Technical Specifications
```yaml
version: ArangoDB 3.11+
deployment: Single instance (upgrade to cluster later)

configuration:
  max_memory: 8GB
  storage_engine: RocksDB
  replication: none (single instance)

collections:
  document_collections: 45+
  edge_collections: 15+
  total_estimated_size: 100GB (1 year)
```

### Service Contracts

**Collection Structure** (see flowmaster-database skill for full schema):
```yaml
process_layer:
  - process_def
  - node_def
  - data_definition
  - proc_def_defines_node (edge)
  - proc_def_node_flow (edge)

execution_layer:
  - execution_sessions
  - execution_instances
  - execution_state
  - execution_checkpoints

human_tasks:
  - human_tasks
  - pending_human_tasks
  - task_comments

agent_layer:
  - agent_profiles
  - agent_instances
  - agent_tasks
  - agent_memories
```

### Configuration Files Needed

**docker-compose.arangodb.yml**:
```yaml
version: '3.8'
services:
  arangodb:
    image: arangodb:3.11
    environment:
      ARANGO_ROOT_PASSWORD: ${ARANGO_ROOT_PASSWORD}
      ARANGO_NO_AUTH: "false"
    ports:
      - "8529:8529"
    volumes:
      - arangodb-data:/var/lib/arangodb3
      - arangodb-apps:/var/lib/arangodb3-apps
      - ./config/arangodb:/etc/arangodb3
    networks:
      - flowmaster-network
    command: >
      arangod
      --server.endpoint tcp://0.0.0.0:8529
      --database.directory /var/lib/arangodb3
      --log.level INFO

volumes:
  arangodb-data:
  arangodb-apps:

networks:
  flowmaster-network:
    external: true
```

**scripts/init-arangodb-schema.js**:
```javascript
// Initialize FlowMaster database schema
const db = require('@arangodb').db;
const dbName = 'flowmaster';

// Create database
if (!db._databases().includes(dbName)) {
  db._createDatabase(dbName);
}
db._useDatabase(dbName);

// Document Collections
const docCollections = [
  'process_def', 'node_def', 'data_definition',
  'execution_sessions', 'execution_instances', 'execution_state',
  'human_tasks', 'pending_human_tasks', 'task_comments',
  'agent_profiles', 'agent_instances', 'agent_tasks',
  'agent_memories', 'ai_audit_logs', 'event_audit_log',
  'llm_models', 'llm_providers', 'llm_usage_logs',
  'sdx_datasources', 'sdx_schemas', 'sdx_tables', 'sdx_columns'
];

docCollections.forEach(name => {
  if (!db._collection(name)) {
    db._create(name);
    console.log(`Created collection: ${name}`);
  }
});

// Edge Collections
const edgeCollections = [
  'proc_def_defines_node', 'proc_def_node_flow',
  'node_def_produces_data_def', 'node_def_uses_data_def',
  'proc_inst_of_proc_def', 'proc_inst_has_node_inst',
  'agent_executes_task', 'agent_spawns_agent'
];

edgeCollections.forEach(name => {
  if (!db._collection(name)) {
    db._createEdgeCollection(name);
    console.log(`Created edge collection: ${name}`);
  }
});

// Create indexes
db.process_def.ensureIndex({ type: 'persistent', fields: ['organization_id'] });
db.process_def.ensureIndex({ type: 'persistent', fields: ['tenant_id'] });
db.process_def.ensureIndex({ type: 'persistent', fields: ['owner'] });

db.execution_sessions.ensureIndex({ type: 'persistent', fields: ['context.execution_id'] });
db.execution_sessions.ensureIndex({ type: 'persistent', fields: ['active_agent_ids[*]'] });

db.human_tasks.ensureIndex({ type: 'persistent', fields: ['status'] });
db.human_tasks.ensureIndex({ type: 'persistent', fields: ['assignee'] });
db.human_tasks.ensureIndex({ type: 'persistent', fields: ['created_at'] });

db.agent_tasks.ensureIndex({ type: 'persistent', fields: ['status'] });
db.agent_tasks.ensureIndex({ type: 'persistent', fields: ['agent_id'] });

console.log('Schema initialization complete');
```

### Scripts/Automation Required

**scripts/backup-arangodb.sh**:
```bash
#!/bin/bash
# Backup ArangoDB database

BACKUP_DIR="/backups/arangodb/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

docker exec flowmaster-arangodb-1 arangodump \
  --server.endpoint tcp://127.0.0.1:8529 \
  --server.username root \
  --server.password $ARANGO_ROOT_PASSWORD \
  --output-directory /tmp/backup \
  --overwrite true

docker cp flowmaster-arangodb-1:/tmp/backup $BACKUP_DIR

echo "Backup completed: $BACKUP_DIR"
```

**scripts/restore-arangodb.sh**:
```bash
#!/bin/bash
# Restore ArangoDB from backup

BACKUP_DIR=$1

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: $0 <backup_directory>"
  exit 1
fi

docker cp $BACKUP_DIR flowmaster-arangodb-1:/tmp/restore

docker exec flowmaster-arangodb-1 arangorestore \
  --server.endpoint tcp://127.0.0.1:8529 \
  --server.username root \
  --server.password $ARANGO_ROOT_PASSWORD \
  --input-directory /tmp/restore \
  --create-database true

echo "Restore completed from: $BACKUP_DIR"
```

### Testing Procedures

```bash
# Test database connection
curl http://localhost:8529/_api/version

# Create test collection
curl -X POST http://localhost:8529/_db/flowmaster/_api/collection \
  -u root:$ARANGO_ROOT_PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"name":"test_collection"}'

# Insert test document
curl -X POST http://localhost:8529/_db/flowmaster/_api/document/test_collection \
  -u root:$ARANGO_ROOT_PASSWORD \
  -H 'Content-Type: application/json' \
  -d '{"test":"data"}'

# Query test document
curl http://localhost:8529/_db/flowmaster/_api/document/test_collection \
  -u root:$ARANGO_ROOT_PASSWORD

# Run backup test
./scripts/backup-arangodb.sh

# Verify backup
ls -lh /backups/arangodb/
```

### Rollback Procedures
```bash
# Stop ArangoDB
docker-compose -f docker-compose.arangodb.yml down

# Restore from backup
./scripts/restore-arangodb.sh /backups/arangodb/20260212_143000

# Restart
docker-compose -f docker-compose.arangodb.yml up -d
```

### Acceptance Criteria
- [ ] ArangoDB accessible at localhost:8529
- [ ] Database 'flowmaster' created
- [ ] All 45+ document collections created
- [ ] All 15+ edge collections created
- [ ] Indexes created on key fields
- [ ] Backup script working
- [ ] Restore script tested
- [ ] Web UI accessible
- [ ] Query performance acceptable (<100ms for indexed queries)
- [ ] Storage monitoring configured

### Dependencies
- Docker network: flowmaster-network
- Environment variable: ARANGO_ROOT_PASSWORD
- Disk space: 100GB minimum

---

## INF-004: PostgreSQL Per-Service Databases

**Priority**: P1 (Critical)
**Complexity**: M (1-2 days)
**Category**: Infrastructure - Database

### Description
Set up PostgreSQL instance with separate databases for each microservice that requires relational data (authentication, user management, configuration).

### Technical Specifications
```yaml
databases:
  - auth_service_db: User authentication and sessions
  - config_service_db: System configuration
  - analytics_db: Logging and analytics data

configuration:
  max_connections: 200
  shared_buffers: 2GB
  effective_cache_size: 6GB
  maintenance_work_mem: 512MB
```

### Configuration Files Needed

**docker-compose.postgresql.yml**:
```yaml
version: '3.8'
services:
  postgresql:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_ROOT_PASSWORD}
      POSTGRES_USER: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgresql-data:/var/lib/postgresql/data
      - ./scripts/init-postgres.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - flowmaster-network
    command: >
      postgres
      -c max_connections=200
      -c shared_buffers=2GB
      -c effective_cache_size=6GB
      -c maintenance_work_mem=512MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c default_statistics_target=100
      -c random_page_cost=1.1
      -c effective_io_concurrency=200

volumes:
  postgresql-data:

networks:
  flowmaster-network:
    external: true
```

**scripts/init-postgres.sql**:
```sql
-- Create databases for each service
CREATE DATABASE auth_service_db;
CREATE DATABASE config_service_db;
CREATE DATABASE analytics_db;

-- Create users for each service
CREATE USER auth_service WITH PASSWORD '${AUTH_SERVICE_DB_PASSWORD}';
CREATE USER config_service WITH PASSWORD '${CONFIG_SERVICE_DB_PASSWORD}';
CREATE USER analytics_service WITH PASSWORD '${ANALYTICS_SERVICE_DB_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE auth_service_db TO auth_service;
GRANT ALL PRIVILEGES ON DATABASE config_service_db TO config_service;
GRANT ALL PRIVILEGES ON DATABASE analytics_db TO analytics_service;

-- Connect to auth_service_db and create schema
\c auth_service_db;
CREATE SCHEMA IF NOT EXISTS auth;
GRANT ALL ON SCHEMA auth TO auth_service;

-- Connect to config_service_db and create schema
\c config_service_db;
CREATE SCHEMA IF NOT EXISTS config;
GRANT ALL ON SCHEMA config TO config_service;

-- Connect to analytics_db and create schema
\c analytics_db;
CREATE SCHEMA IF NOT EXISTS analytics;
GRANT ALL ON SCHEMA analytics TO analytics_service;
```

### Acceptance Criteria
- [ ] PostgreSQL running on port 5432
- [ ] All 3 databases created
- [ ] Service users created with correct permissions
- [ ] Connection pooling configured
- [ ] Backup strategy implemented
- [ ] Performance tuning applied

### Dependencies
- Docker network: flowmaster-network
- Environment variables: POSTGRES_ROOT_PASSWORD, AUTH_SERVICE_DB_PASSWORD, CONFIG_SERVICE_DB_PASSWORD, ANALYTICS_SERVICE_DB_PASSWORD

---

## INF-005: Docker Network & Service Discovery

**Priority**: P0 (Blocking)
**Complexity**: S (2-4 hours)
**Category**: Infrastructure - Networking

### Description
Configure Docker network for all FlowMaster services with proper DNS resolution and service discovery.

### Technical Specifications
```yaml
network_name: flowmaster-network
driver: bridge
subnet: 172.20.0.0/16
gateway: 172.20.0.1

services_on_network:
  - kafka
  - zookeeper
  - redis
  - arangodb
  - postgresql
  - api-gateway
  - process-service
  - execution-service
  - agent-service
  - sdx-service
  - engage-service
```

### Configuration Files Needed

**scripts/create-network.sh**:
```bash
#!/bin/bash
# Create Docker network for FlowMaster

NETWORK_NAME="flowmaster-network"

# Check if network exists
if docker network ls | grep -q $NETWORK_NAME; then
  echo "Network $NETWORK_NAME already exists"
else
  docker network create \
    --driver bridge \
    --subnet 172.20.0.0/16 \
    --gateway 172.20.0.1 \
    $NETWORK_NAME
  echo "Created network: $NETWORK_NAME"
fi

# List network details
docker network inspect $NETWORK_NAME
```

### Testing Procedures
```bash
# Create network
./scripts/create-network.sh

# Test DNS resolution between services
docker run --rm --network flowmaster-network alpine ping -c 3 kafka
docker run --rm --network flowmaster-network alpine ping -c 3 redis
docker run --rm --network flowmaster-network alpine ping -c 3 arangodb

# Check network connectivity
docker network inspect flowmaster-network
```

### Acceptance Criteria
- [ ] Network created successfully
- [ ] All services can resolve each other by name
- [ ] Network subnet configured correctly
- [ ] No IP conflicts

### Dependencies
- None (foundational infrastructure)

---

I'll continue with more work items in the next file. This first document covers the core infrastructure (Kafka, Redis, ArangoDB, PostgreSQL, and networking). Would you like me to continue with:

1. Logging & Monitoring infrastructure (INF-006 to INF-009)
2. Security infrastructure (INF-010 to INF-012)
3. CI/CD infrastructure (INF-013 to INF-015)
4. Configuration management work items
5. Test data management work items

Let me know which section you'd like next, or if you want me to create all sections in separate files!