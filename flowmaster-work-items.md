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

## INF-006: Centralized Logging Infrastructure (ELK Stack)

**Priority**: P1 (Critical)
**Complexity**: L (3-5 days)
**Category**: Infrastructure - Logging & Monitoring

### Description
Set up centralized logging infrastructure using Elasticsearch, Logstash, and Kibana (ELK Stack) for aggregating, searching, and visualizing logs from all FlowMaster services.

### Technical Specifications
```yaml
components:
  - elasticsearch: 3-node cluster for log storage and search
  - logstash: Log ingestion and processing pipeline
  - kibana: Web UI for log visualization and analysis
  - filebeat: Lightweight log shippers on each service

configuration:
  elasticsearch:
    cluster_name: flowmaster-logs
    heap_size: 4GB
    shards_per_index: 3
    replicas: 1
    retention_policy: 30 days

  logstash:
    pipeline_workers: 4
    batch_size: 125
    batch_delay: 50ms

  kibana:
    elasticsearch_hosts: ["elasticsearch:9200"]
    port: 5601

data_retention:
  hot_tier: 7 days (fast SSD storage)
  warm_tier: 23 days (slower storage)
  total_retention: 30 days
```

### Service Contracts

**Log Levels and Routing**:
```yaml
log_levels:
  - ERROR: Critical issues requiring immediate attention
  - WARN: Warning conditions that should be reviewed
  - INFO: General operational information
  - DEBUG: Detailed debugging information
  - TRACE: Very detailed trace information

log_sources:
  - api_gateway: API requests, responses, authentication
  - process_service: Process definitions, executions
  - execution_service: Execution state changes, checkpoints
  - agent_service: Agent tasks, LLM interactions
  - human_task_service: Task assignments, completions
  - sdx_service: Data source queries, schema changes
  - engage_service: Email campaigns, notifications

log_formats:
  structured_json:
    timestamp: ISO8601
    level: ERROR|WARN|INFO|DEBUG|TRACE
    service: service_name
    trace_id: distributed_tracing_id
    user_id: optional_user_context
    message: log_message
    metadata: additional_context
```

### Configuration Files Needed

**docker-compose.elk.yml**:
```yaml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - cluster.name=flowmaster-logs
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms4g -Xmx4g"
      - xpack.security.enabled=true
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
      - ./config/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
    ports:
      - "9200:9200"
      - "9300:9300"
    networks:
      - flowmaster-network
    healthcheck:
      test: ["CMD-SHELL", "curl -s http://localhost:9200/_cluster/health | grep -q '\"status\":\"green\"\\|\"status\":\"yellow\"'"]
      interval: 30s
      timeout: 10s
      retries: 5

  logstash:
    image: docker.elastic.co/logstash/logstash:8.11.0
    volumes:
      - ./config/logstash/logstash.yml:/usr/share/logstash/config/logstash.yml
      - ./config/logstash/pipeline:/usr/share/logstash/pipeline
    ports:
      - "5000:5000/tcp"
      - "5000:5000/udp"
      - "9600:9600"
    environment:
      LS_JAVA_OPTS: "-Xmx2g -Xms2g"
      ELASTIC_PASSWORD: ${ELASTIC_PASSWORD}
    networks:
      - flowmaster-network
    depends_on:
      - elasticsearch

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: '["http://elasticsearch:9200"]'
      ELASTICSEARCH_USERNAME: elastic
      ELASTICSEARCH_PASSWORD: ${ELASTIC_PASSWORD}
      SERVER_NAME: flowmaster-kibana
    volumes:
      - ./config/kibana/kibana.yml:/usr/share/kibana/config/kibana.yml
    networks:
      - flowmaster-network
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    user: root
    volumes:
      - ./config/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - filebeat-data:/usr/share/filebeat/data
    environment:
      - ELASTICSEARCH_HOSTS=["elasticsearch:9200"]
      - ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
    networks:
      - flowmaster-network
    depends_on:
      - elasticsearch
      - logstash

volumes:
  elasticsearch-data:
  filebeat-data:

networks:
  flowmaster-network:
    external: true
```

**config/logstash/pipeline/logstash.conf**:
```conf
input {
  beats {
    port => 5044
  }
  tcp {
    port => 5000
    codec => json
  }
  http {
    port => 8080
    codec => json
  }
}

filter {
  # Parse JSON logs
  if [message] =~ /^\{.*\}$/ {
    json {
      source => "message"
    }
  }

  # Add service metadata
  if [container_name] {
    mutate {
      add_field => {
        "service" => "%{container_name}"
      }
    }
  }

  # Parse log level
  if [level] {
    mutate {
      uppercase => ["level"]
    }
  }

  # Add timestamp
  date {
    match => ["timestamp", "ISO8601"]
    target => "@timestamp"
  }

  # Grok for unstructured logs
  grok {
    match => {
      "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:log_message}"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "flowmaster-logs-%{+YYYY.MM.dd}"
    user => "elastic"
    password => "${ELASTIC_PASSWORD}"
  }

  # Debug output (optional, disable in production)
  # stdout { codec => rubydebug }
}
```

**config/filebeat/filebeat.yml**:
```yaml
filebeat.inputs:
  - type: container
    paths:
      - '/var/lib/docker/containers/*/*.log'
    processors:
      - add_docker_metadata:
          host: "unix:///var/run/docker.sock"
      - decode_json_fields:
          fields: ["message"]
          target: ""
          overwrite_keys: true

output.logstash:
  hosts: ["logstash:5044"]

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644
```

**config/elasticsearch/elasticsearch.yml**:
```yaml
cluster.name: flowmaster-logs
node.name: elasticsearch-1
network.host: 0.0.0.0

# Index lifecycle management
xpack.ilm.enabled: true

# Security
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
```

**config/kibana/kibana.yml**:
```yaml
server.host: "0.0.0.0"
server.name: "flowmaster-kibana"
elasticsearch.hosts: ["http://elasticsearch:9200"]
elasticsearch.username: "elastic"
elasticsearch.password: "${ELASTICSEARCH_PASSWORD}"

# Monitoring
monitoring.ui.enabled: true
```

### Scripts/Automation Required

**scripts/setup-elk-indices.sh**:
```bash
#!/bin/bash
# Create index templates and lifecycle policies

ELASTIC_URL="http://localhost:9200"
ELASTIC_USER="elastic"
ELASTIC_PASS=$ELASTIC_PASSWORD

# Create index lifecycle policy
curl -X PUT "$ELASTIC_URL/_ilm/policy/flowmaster-logs-policy" \
  -u "$ELASTIC_USER:$ELASTIC_PASS" \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "actions": {
            "rollover": {
              "max_age": "1d",
              "max_size": "50GB"
            }
          }
        },
        "warm": {
          "min_age": "7d",
          "actions": {
            "shrink": {
              "number_of_shards": 1
            },
            "forcemerge": {
              "max_num_segments": 1
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'

# Create index template
curl -X PUT "$ELASTIC_URL/_index_template/flowmaster-logs-template" \
  -u "$ELASTIC_USER:$ELASTIC_PASS" \
  -H 'Content-Type: application/json' \
  -d '{
    "index_patterns": ["flowmaster-logs-*"],
    "template": {
      "settings": {
        "number_of_shards": 3,
        "number_of_replicas": 1,
        "index.lifecycle.name": "flowmaster-logs-policy",
        "index.lifecycle.rollover_alias": "flowmaster-logs"
      },
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "level": { "type": "keyword" },
          "service": { "type": "keyword" },
          "trace_id": { "type": "keyword" },
          "user_id": { "type": "keyword" },
          "message": { "type": "text" },
          "metadata": { "type": "object" }
        }
      }
    }
  }'

echo "ELK indices and policies configured successfully"
```

**scripts/kibana-dashboards.sh**:
```bash
#!/bin/bash
# Import Kibana dashboards and visualizations

KIBANA_URL="http://localhost:5601"
ELASTIC_USER="elastic"
ELASTIC_PASS=$ELASTIC_PASSWORD

# Create index pattern
curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/flowmaster-logs" \
  -u "$ELASTIC_USER:$ELASTIC_PASS" \
  -H 'kbn-xsrf: true' \
  -H 'Content-Type: application/json' \
  -d '{
    "attributes": {
      "title": "flowmaster-logs-*",
      "timeFieldName": "@timestamp"
    }
  }'

echo "Kibana dashboards configured successfully"
```

### Testing Procedures

**Health Checks**:
```bash
# Check Elasticsearch cluster health
curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200/_cluster/health?pretty

# Check Logstash pipeline
curl http://localhost:9600/_node/stats/pipelines?pretty

# Check Kibana status
curl -u elastic:$ELASTIC_PASSWORD http://localhost:5601/api/status

# Test log ingestion
echo '{"level":"INFO","service":"test","message":"Test log entry"}' | \
  curl -u elastic:$ELASTIC_PASSWORD -X POST \
  http://localhost:5000 \
  -H 'Content-Type: application/json' \
  -d @-

# Query logs in Elasticsearch
curl -u elastic:$ELASTIC_PASSWORD -X GET \
  "http://localhost:9200/flowmaster-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{"query":{"match":{"service":"test"}}}'
```

**Functional Tests**:
```bash
# Test Filebeat is collecting container logs
docker logs flowmaster-filebeat-1 | grep "harvester started"

# Test log parsing in Logstash
docker logs flowmaster-logstash-1 | grep "Pipeline started successfully"

# Check Kibana discover page
open http://localhost:5601/app/discover
```

### Rollback Procedures
```bash
# Stop ELK stack
docker-compose -f docker-compose.elk.yml down

# Preserve data volumes
docker volume ls | grep elasticsearch
docker volume ls | grep filebeat

# Restore from backup if needed
# (Elasticsearch snapshot/restore would be configured separately)

# Full cleanup (destructive)
docker-compose -f docker-compose.elk.yml down -v
```

### Acceptance Criteria
- [ ] Elasticsearch cluster healthy (green/yellow status)
- [ ] Logstash processing logs successfully
- [ ] Kibana UI accessible at localhost:5601
- [ ] Filebeat shipping logs from Docker containers
- [ ] Index lifecycle policies configured
- [ ] Index templates created
- [ ] Log retention working (30 days)
- [ ] Search performance acceptable (<1s for recent logs)
- [ ] Dashboards created and functional
- [ ] All microservices sending logs to ELK
- [ ] Structured JSON logging working
- [ ] Trace IDs captured for distributed tracing

### Dependencies
- Docker network: flowmaster-network
- Environment variable: ELASTIC_PASSWORD
- Disk space: 100GB minimum for log storage
- All microservices configured for JSON logging

### Documentation Requirements
- Log message format standards
- Index naming conventions
- Retention policy explanation
- Query examples and common searches
- Dashboard creation guide
- Troubleshooting guide
- Performance tuning recommendations

---

## INF-007: Application Analytics and Metrics

**Priority**: P2 (Important)
**Complexity**: M (1-2 days)
**Category**: Infrastructure - Logging & Monitoring

### Description
Set up application-level analytics and metrics collection for tracking business metrics, user behavior, and application usage patterns.

### Technical Specifications
```yaml
components:
  - timescaledb: Time-series database for metrics storage
  - analytics_api: REST API for metrics ingestion
  - analytics_dashboard: Web UI for visualization

metrics_categories:
  business_metrics:
    - process_executions: Total, successful, failed
    - human_tasks: Created, completed, average_completion_time
    - agent_tasks: Created, completed, LLM_calls, tokens_used
    - api_calls: Total, by_endpoint, by_user

  performance_metrics:
    - response_times: p50, p95, p99
    - throughput: requests_per_second
    - error_rates: by_service, by_endpoint

  user_metrics:
    - active_users: daily, weekly, monthly
    - session_duration: average, distribution
    - feature_usage: by_feature, by_user_segment

storage:
  raw_metrics_retention: 90 days
  aggregated_metrics_retention: 2 years
  compression: TimescaleDB automatic compression
```

### Service Contracts

**Metrics Schema**:
```yaml
metric_event:
  timestamp: ISO8601
  metric_name: string
  metric_type: counter|gauge|histogram|summary
  value: number
  tags:
    service: string
    environment: production|staging|dev
    user_id: optional_string
    organization_id: optional_string
  metadata: optional_json_object

examples:
  process_execution_completed:
    metric_name: process.execution.completed
    metric_type: counter
    value: 1
    tags:
      service: execution-service
      process_def_id: "proc_123"
      status: "success"

  api_response_time:
    metric_name: api.response_time
    metric_type: histogram
    value: 245.5  # milliseconds
    tags:
      service: api-gateway
      endpoint: "/api/v1/processes"
      method: "GET"
      status_code: "200"
```

### Configuration Files Needed

**docker-compose.analytics.yml**:
```yaml
version: '3.8'
services:
  timescaledb:
    image: timescale/timescaledb:latest-pg15
    environment:
      POSTGRES_DB: analytics
      POSTGRES_USER: analytics
      POSTGRES_PASSWORD: ${ANALYTICS_DB_PASSWORD}
    ports:
      - "5433:5432"
    volumes:
      - timescaledb-data:/var/lib/postgresql/data
      - ./scripts/init-analytics-schema.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - flowmaster-network
    command: postgres -c shared_preload_libraries=timescaledb

  analytics-api:
    build: ./services/analytics-api
    ports:
      - "8081:8080"
    environment:
      DATABASE_URL: postgresql://analytics:${ANALYTICS_DB_PASSWORD}@timescaledb:5432/analytics
      REDIS_URL: redis://redis-primary:6379
    depends_on:
      - timescaledb
    networks:
      - flowmaster-network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-clock-panel
    volumes:
      - grafana-data:/var/lib/grafana
      - ./config/grafana/provisioning:/etc/grafana/provisioning
    depends_on:
      - timescaledb
    networks:
      - flowmaster-network

volumes:
  timescaledb-data:
  grafana-data:

networks:
  flowmaster-network:
    external: true
```

**scripts/init-analytics-schema.sql**:
```sql
-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create metrics table
CREATE TABLE IF NOT EXISTS metrics (
  time TIMESTAMPTZ NOT NULL,
  metric_name TEXT NOT NULL,
  metric_type TEXT NOT NULL,
  value DOUBLE PRECISION NOT NULL,
  tags JSONB,
  metadata JSONB
);

-- Convert to hypertable
SELECT create_hypertable('metrics', 'time', if_not_exists => TRUE);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics (metric_name, time DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_tags ON metrics USING GIN (tags);
CREATE INDEX IF NOT EXISTS idx_metrics_time ON metrics (time DESC);

-- Create continuous aggregates for hourly rollups
CREATE MATERIALIZED VIEW IF NOT EXISTS metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 hour', time) AS bucket,
  metric_name,
  tags->>'service' as service,
  tags->>'environment' as environment,
  COUNT(*) as count,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY value) as p50,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY value) as p95,
  PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY value) as p99
FROM metrics
GROUP BY bucket, metric_name, tags->>'service', tags->>'environment'
WITH NO DATA;

-- Create continuous aggregates for daily rollups
CREATE MATERIALIZED VIEW IF NOT EXISTS metrics_daily
WITH (timescaledb.continuous) AS
SELECT
  time_bucket('1 day', time) AS bucket,
  metric_name,
  tags->>'service' as service,
  tags->>'environment' as environment,
  COUNT(*) as count,
  AVG(value) as avg_value,
  MIN(value) as min_value,
  MAX(value) as max_value
FROM metrics
GROUP BY bucket, metric_name, tags->>'service', tags->>'environment'
WITH NO DATA;

-- Set up data retention policies
SELECT add_retention_policy('metrics', INTERVAL '90 days', if_not_exists => TRUE);
SELECT add_retention_policy('metrics_hourly', INTERVAL '1 year', if_not_exists => TRUE);
SELECT add_retention_policy('metrics_daily', INTERVAL '2 years', if_not_exists => TRUE);

-- Set up compression policies
SELECT add_compression_policy('metrics', INTERVAL '7 days', if_not_exists => TRUE);
SELECT add_compression_policy('metrics_hourly', INTERVAL '30 days', if_not_exists => TRUE);

-- Create user-facing views
CREATE OR REPLACE VIEW recent_metrics AS
SELECT * FROM metrics
WHERE time > NOW() - INTERVAL '1 hour'
ORDER BY time DESC;

CREATE OR REPLACE VIEW error_metrics AS
SELECT * FROM metrics
WHERE metric_name LIKE '%.error%'
  OR tags->>'status' LIKE 'error%'
  OR tags->>'status_code' >= '400'
ORDER BY time DESC;
```

**config/grafana/provisioning/datasources/timescaledb.yml**:
```yaml
apiVersion: 1

datasources:
  - name: TimescaleDB
    type: postgres
    url: timescaledb:5432
    database: analytics
    user: analytics
    secureJsonData:
      password: ${ANALYTICS_DB_PASSWORD}
    jsonData:
      sslmode: disable
      postgresVersion: 1500
      timescaledb: true
```

### Scripts/Automation Required

**scripts/analytics-health-check.sh**:
```bash
#!/bin/bash
# Check analytics infrastructure health

echo "Checking TimescaleDB..."
docker exec flowmaster-timescaledb-1 psql -U analytics -d analytics -c "SELECT version();"

echo "Checking continuous aggregates..."
docker exec flowmaster-timescaledb-1 psql -U analytics -d analytics -c \
  "SELECT view_name, materialization_hypertable_name FROM timescaledb_information.continuous_aggregates;"

echo "Checking Analytics API..."
curl http://localhost:8081/health

echo "Checking Grafana..."
curl -u admin:$GRAFANA_ADMIN_PASSWORD http://localhost:3001/api/health
```

**scripts/test-metrics-ingestion.sh**:
```bash
#!/bin/bash
# Test metrics ingestion

ANALYTICS_API="http://localhost:8081"

# Send test metric
curl -X POST "$ANALYTICS_API/metrics" \
  -H 'Content-Type: application/json' \
  -d '{
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "metric_name": "test.metric",
    "metric_type": "counter",
    "value": 1,
    "tags": {
      "service": "test-service",
      "environment": "dev"
    }
  }'

# Query metrics
sleep 2
curl "$ANALYTICS_API/query?metric_name=test.metric&time_range=1h"
```

### Testing Procedures

```bash
# Test TimescaleDB
psql -h localhost -p 5433 -U analytics -d analytics \
  -c "SELECT COUNT(*) FROM metrics;"

# Test continuous aggregates
psql -h localhost -p 5433 -U analytics -d analytics \
  -c "SELECT * FROM metrics_hourly LIMIT 10;"

# Test compression
psql -h localhost -p 5433 -U analytics -d analytics \
  -c "SELECT * FROM timescaledb_information.compression_settings;"

# Test Analytics API
curl http://localhost:8081/metrics \
  -H 'Content-Type: application/json' \
  -d '{"metric_name":"api.test","value":100,"tags":{"service":"test"}}'

# Access Grafana
open http://localhost:3001
```

### Rollback Procedures
```bash
# Stop analytics services
docker-compose -f docker-compose.analytics.yml down

# Preserve data
docker volume ls | grep timescaledb
docker volume ls | grep grafana

# Full cleanup
docker-compose -f docker-compose.analytics.yml down -v
```

### Acceptance Criteria
- [ ] TimescaleDB running and accepting connections
- [ ] Hypertables created for metrics
- [ ] Continuous aggregates configured
- [ ] Data retention policies active
- [ ] Compression policies working
- [ ] Analytics API accepting metrics
- [ ] Grafana accessible and configured
- [ ] Test metrics ingested successfully
- [ ] Query performance acceptable (<100ms for recent data)
- [ ] Dashboards created for key metrics

### Dependencies
- Docker network: flowmaster-network
- Environment variables: ANALYTICS_DB_PASSWORD, GRAFANA_ADMIN_PASSWORD
- Disk space: 50GB minimum

---

## INF-008: Prometheus Monitoring Setup

**Priority**: P1 (Critical)
**Complexity**: M (1-2 days)
**Category**: Infrastructure - Logging & Monitoring

### Description
Set up Prometheus for metrics collection, alerting, and monitoring of FlowMaster infrastructure and application components.

### Technical Specifications
```yaml
components:
  - prometheus: Metrics collection and storage
  - alertmanager: Alert routing and notification
  - node_exporter: System metrics
  - postgres_exporter: PostgreSQL metrics
  - redis_exporter: Redis metrics
  - kafka_exporter: Kafka metrics

configuration:
  retention: 15 days
  scrape_interval: 15s
  evaluation_interval: 15s

metrics_types:
  infrastructure:
    - cpu_usage
    - memory_usage
    - disk_io
    - network_io

  application:
    - http_request_duration
    - http_request_total
    - error_rate
    - active_connections

  database:
    - query_duration
    - connection_pool_usage
    - transaction_rate
    - slow_queries
```

### Service Contracts

**Prometheus Metrics Format**:
```yaml
metric_naming:
  pattern: "{namespace}_{subsystem}_{metric}_{unit}"
  examples:
    - flowmaster_api_request_duration_seconds
    - flowmaster_process_executions_total
    - flowmaster_agent_llm_calls_total
    - flowmaster_http_requests_total

labels:
  - service: Service name
  - environment: production|staging|dev
  - endpoint: API endpoint path
  - method: HTTP method
  - status_code: HTTP status code
  - instance: Service instance identifier
```

### Configuration Files Needed

**docker-compose.prometheus.yml**:
```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - ./config/prometheus/alerts:/etc/prometheus/alerts
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=15d'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - flowmaster-network

  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./config/alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - flowmaster-network

  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    networks:
      - flowmaster-network

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    ports:
      - "9187:9187"
    environment:
      DATA_SOURCE_NAME: "postgresql://postgres:${POSTGRES_ROOT_PASSWORD}@postgresql:5432/postgres?sslmode=disable"
    networks:
      - flowmaster-network
    depends_on:
      - prometheus

  redis-exporter:
    image: oliver006/redis_exporter:latest
    ports:
      - "9121:9121"
    environment:
      REDIS_ADDR: "redis://redis-primary:6379"
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    networks:
      - flowmaster-network

  kafka-exporter:
    image: danielqsj/kafka-exporter:latest
    ports:
      - "9308:9308"
    command:
      - '--kafka.server=kafka:9092'
    networks:
      - flowmaster-network

volumes:
  prometheus-data:
  alertmanager-data:

networks:
  flowmaster-network:
    external: true
```

**config/prometheus/prometheus.yml**:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'flowmaster'
    environment: 'production'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load rules
rule_files:
  - '/etc/prometheus/alerts/*.yml'

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  # PostgreSQL
  - job_name: 'postgresql'
    static_configs:
      - targets: ['postgres-exporter:9187']

  # Redis
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']

  # Kafka
  - job_name: 'kafka'
    static_configs:
      - targets: ['kafka-exporter:9308']

  # FlowMaster services (auto-discovery via Docker)
  - job_name: 'flowmaster-services'
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
    relabel_configs:
      - source_labels: [__meta_docker_container_label_com_prometheus_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_docker_container_label_com_prometheus_port]
        action: replace
        target_label: __address__
        regex: (.+)
        replacement: $1
```

**config/prometheus/alerts/flowmaster-alerts.yml**:
```yaml
groups:
  - name: infrastructure
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% (current value: {{ $value }}%)"

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% (current value: {{ $value }}%)"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 15% (current value: {{ $value }}%)"

  - name: application
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(flowmaster_http_requests_total{status_code=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Error rate is above 5% (current value: {{ $value }})"

      - alert: SlowResponseTime
        expr: histogram_quantile(0.95, rate(flowmaster_api_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Slow response times on {{ $labels.service }}"
          description: "95th percentile response time is above 1s (current value: {{ $value }}s)"

  - name: database
    interval: 30s
    rules:
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL is down"
          description: "PostgreSQL instance {{ $labels.instance }} is down"

      - alert: RedisDown
        expr: redis_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Redis is down"
          description: "Redis instance {{ $labels.instance }} is down"
```

**config/alertmanager/alertmanager.yml**:
```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      continue: true

    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://localhost:5001/alerts'

  - name: 'critical-alerts'
    webhook_configs:
      - url: 'http://localhost:5001/alerts/critical'
    # Add email/Slack/PagerDuty here

  - name: 'warning-alerts'
    webhook_configs:
      - url: 'http://localhost:5001/alerts/warning'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
```

### Scripts/Automation Required

**scripts/prometheus-health-check.sh**:
```bash
#!/bin/bash
# Check Prometheus and exporters health

echo "Checking Prometheus..."
curl -s http://localhost:9090/-/healthy

echo "Checking targets..."
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

echo "Checking Alertmanager..."
curl -s http://localhost:9093/-/healthy

echo "Checking active alerts..."
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alertname: .labels.alertname, state: .state}'
```

### Testing Procedures

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up'

# Check alerts
curl http://localhost:9090/api/v1/alerts

# Access Prometheus UI
open http://localhost:9090

# Access Alertmanager UI
open http://localhost:9093

# Test alert firing (simulate high CPU)
# stress --cpu 8 --timeout 60s
```

### Rollback Procedures
```bash
# Stop Prometheus stack
docker-compose -f docker-compose.prometheus.yml down

# Preserve data
docker volume ls | grep prometheus

# Full cleanup
docker-compose -f docker-compose.prometheus.yml down -v
```

### Acceptance Criteria
- [ ] Prometheus running and scraping metrics
- [ ] All exporters healthy and reporting
- [ ] Alert rules configured
- [ ] Alertmanager routing alerts
- [ ] Prometheus UI accessible
- [ ] Service discovery working
- [ ] Metrics retention configured (15 days)
- [ ] All critical infrastructure monitored
- [ ] Alert notifications tested

### Dependencies
- Docker network: flowmaster-network
- Environment variables: POSTGRES_ROOT_PASSWORD, REDIS_PASSWORD
- All monitored services must expose metrics endpoints

---

## INF-009: Grafana Dashboards

**Priority**: P2 (Important)
**Complexity**: M (1-2 days)
**Category**: Infrastructure - Logging & Monitoring

### Description
Create comprehensive Grafana dashboards for monitoring FlowMaster infrastructure, application performance, and business metrics.

### Technical Specifications
```yaml
dashboards:
  infrastructure_overview:
    panels:
      - CPU usage per service
      - Memory usage per service
      - Disk I/O
      - Network I/O
      - Container status

  application_performance:
    panels:
      - Request rate
      - Response times (p50, p95, p99)
      - Error rates
      - Active connections
      - Request duration by endpoint

  database_monitoring:
    panels:
      - Query performance
      - Connection pool usage
      - Transaction rates
      - Slow queries
      - Cache hit rates

  business_metrics:
    panels:
      - Process executions (total, success, failure)
      - Human tasks (pending, completed)
      - Agent tasks and LLM usage
      - Active users
      - API usage by endpoint

  kafka_monitoring:
    panels:
      - Message rates
      - Consumer lag
      - Topic sizes
      - Broker health
```

### Configuration Files Needed

**config/grafana/provisioning/dashboards/dashboard-config.yml**:
```yaml
apiVersion: 1

providers:
  - name: 'FlowMaster Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

**config/grafana/provisioning/datasources/datasources.yml**:
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true

  - name: TimescaleDB
    type: postgres
    url: timescaledb:5432
    database: analytics
    user: analytics
    secureJsonData:
      password: ${ANALYTICS_DB_PASSWORD}
    jsonData:
      sslmode: disable
      postgresVersion: 1500
      timescaledb: true

  - name: Elasticsearch
    type: elasticsearch
    url: http://elasticsearch:9200
    database: "[flowmaster-logs-]YYYY.MM.DD"
    basicAuth: true
    basicAuthUser: elastic
    secureJsonData:
      basicAuthPassword: ${ELASTIC_PASSWORD}
    jsonData:
      timeField: "@timestamp"
      esVersion: "8.11.0"
```

**config/grafana/dashboards/infrastructure-overview.json**:
```json
{
  "dashboard": {
    "title": "FlowMaster Infrastructure Overview",
    "tags": ["infrastructure", "flowmaster"],
    "timezone": "browser",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "{{ instance }}"
          }
        ]
      },
      {
        "title": "Disk Usage",
        "type": "gauge",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}) * 100)",
            "legendFormat": "Disk Usage %"
          }
        ]
      },
      {
        "title": "Container Status",
        "type": "stat",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "count(up{job=\"flowmaster-services\"} == 1)",
            "legendFormat": "Healthy Containers"
          }
        ]
      }
    ]
  }
}
```

### Scripts/Automation Required

**scripts/import-grafana-dashboards.sh**:
```bash
#!/bin/bash
# Import Grafana dashboards

GRAFANA_URL="http://localhost:3001"
GRAFANA_USER="admin"
GRAFANA_PASS=$GRAFANA_ADMIN_PASSWORD

# Import dashboard from JSON
for dashboard in config/grafana/dashboards/*.json; do
  echo "Importing $(basename $dashboard)..."
  curl -X POST "$GRAFANA_URL/api/dashboards/db" \
    -u "$GRAFANA_USER:$GRAFANA_PASS" \
    -H "Content-Type: application/json" \
    -d @"$dashboard"
done

echo "All dashboards imported successfully"
```

**scripts/create-grafana-alerts.sh**:
```bash
#!/bin/bash
# Create Grafana alert rules

GRAFANA_URL="http://localhost:3001"
GRAFANA_USER="admin"
GRAFANA_PASS=$GRAFANA_ADMIN_PASSWORD

# Create contact point for alerts
curl -X POST "$GRAFANA_URL/api/v1/provisioning/contact-points" \
  -u "$GRAFANA_USER:$GRAFANA_PASS" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "FlowMaster Alerts",
    "type": "webhook",
    "settings": {
      "url": "http://localhost:5001/grafana-alerts",
      "httpMethod": "POST"
    }
  }'
```

### Testing Procedures

```bash
# Access Grafana
open http://localhost:3001

# Login with admin credentials
# Username: admin
# Password: $GRAFANA_ADMIN_PASSWORD

# Verify datasources
curl -u admin:$GRAFANA_ADMIN_PASSWORD \
  http://localhost:3001/api/datasources | jq

# Test datasource connection
curl -u admin:$GRAFANA_ADMIN_PASSWORD \
  -X POST http://localhost:3001/api/datasources/proxy/1/api/v1/query?query=up

# List dashboards
curl -u admin:$GRAFANA_ADMIN_PASSWORD \
  http://localhost:3001/api/search | jq
```

### Acceptance Criteria
- [ ] Grafana accessible at localhost:3001
- [ ] All datasources configured and healthy
- [ ] Infrastructure dashboard showing real-time metrics
- [ ] Application performance dashboard functional
- [ ] Database monitoring dashboard working
- [ ] Business metrics dashboard displaying data
- [ ] Kafka monitoring dashboard operational
- [ ] Alert rules configured
- [ ] Notifications working
- [ ] Dashboard auto-refresh enabled
- [ ] Graphs responsive and loading quickly (<2s)

### Dependencies
- Prometheus (INF-008)
- TimescaleDB from Analytics (INF-007)
- Elasticsearch from ELK (INF-006)
- Environment variables: GRAFANA_ADMIN_PASSWORD, ANALYTICS_DB_PASSWORD, ELASTIC_PASSWORD

### Documentation Requirements
- Dashboard usage guide
- Metric interpretation guide
- Alert configuration guide
- Custom panel creation tutorial
- Query examples for each datasource

---
## INF-010: HashiCorp Vault Setup for Secrets Management

**Priority**: P1 (Critical)
**Complexity**: L (3-5 days)
**Category**: Infrastructure - Security

### Description
Set up HashiCorp Vault for centralized secrets management including API keys, database passwords, encryption keys, and service credentials. Implements secure storage, dynamic secrets, and audit logging.

### Technical Specifications
```yaml
deployment:
  mode: docker
  version: vault:1.15
  storage_backend: file  # Upgrade to Consul for HA later

configuration:
  seal_type: shamir  # 5 key shares, threshold 3
  api_addr: http://vault:8200
  cluster_addr: http://vault:8201

secrets_engines:
  - kv-v2: /flowmaster/secrets
  - database: /flowmaster/db
  - pki: /flowmaster/pki
  - transit: /flowmaster/encryption

access_control:
  auth_methods:
    - kubernetes
    - approle
    - userpass
  policies: 15+
```

### Service Contracts

**Secrets Organization**:
```yaml
flowmaster/secrets/:
  database:
    postgres_root: "root password"
    arango_root: "root password"
    redis_password: "cache password"

  services:
    auth_service: "service credentials"
    process_service: "service credentials"
    execution_service: "service credentials"
    agent_service: "service credentials"

  external:
    openai_api_key: "LLM provider key"
    anthropic_api_key: "LLM provider key"
    sendgrid_api_key: "Email service key"

  encryption:
    jwt_secret: "JWT signing key"
    aes_key: "Data encryption key"
    session_secret: "Session encryption"
```



---

# CONFIGURATION MANAGEMENT WORK ITEMS

## CFG-001: Environment Configuration Management

**Priority**: P0 (Blocking)
**Complexity**: M (1-2 days)
**Category**: Configuration - Environment Management

### Description
Implement comprehensive environment configuration management system supporting development, staging, and production environments with secure credential handling and runtime configuration updates.

### Technical Specifications
```yaml
environments:
  - development: Local development with hot-reload
  - staging: Pre-production testing environment
  - production: Production deployment with HA

configuration_sources:
  - environment_variables: Primary source
  - .env_files: Local development overrides
  - config_service: Centralized config server
  - secrets_manager: Encrypted credentials

configuration_structure:
  - database: Connection strings, pool settings
  - kafka: Broker addresses, topic configs
  - redis: Connection info, cache settings
  - services: API endpoints, timeouts
  - security: JWT secrets, encryption keys
  - feature_flags: Feature toggles
```

### Service Contracts

**Environment Configuration Schema**:
```typescript
interface EnvironmentConfig {
  environment: 'development' | 'staging' | 'production';

  database: {
    arangodb: {
      url: string;
      database: string;
      username: string;
      password: string;
      maxConnections: number;
    };
    postgresql: {
      host: string;
      port: number;
      databases: {
        auth: string;
        config: string;
        analytics: string;
      };
      credentials: Record<string, { username: string; password: string }>;
    };
  };

  messageQueue: {
    kafka: {
      brokers: string[];
      clientId: string;
      groupId: string;
      ssl: boolean;
      sasl?: {
        mechanism: string;
        username: string;
        password: string;
      };
    };
  };

  cache: {
    redis: {
      host: string;
      port: number;
      password: string;
      db: number;
      sentinel?: {
        enabled: boolean;
        masterName: string;
        sentinels: Array<{ host: string; port: number }>;
      };
    };
  };

  services: {
    apiGateway: { url: string; timeout: number };
    processService: { url: string; timeout: number };
    executionService: { url: string; timeout: number };
    agentService: { url: string; timeout: number };
    sdxService: { url: string; timeout: number };
    engageService: { url: string; timeout: number };
  };

  security: {
    jwtSecret: string;
    jwtExpiration: string;
    encryptionKey: string;
    corsOrigins: string[];
  };

  observability: {
    logging: {
      level: 'debug' | 'info' | 'warn' | 'error';
      format: 'json' | 'text';
    };
    metrics: {
      enabled: boolean;
      port: number;
    };
    tracing: {
      enabled: boolean;
      samplingRate: number;
    };
  };
}
```

### Scripts/Automation Required

**scripts/validate-config.sh**:
```bash
#!/bin/bash
# Validate environment configuration

ENV=${1:-development}
CONFIG_FILE="config/environments/${ENV}.yaml"

echo "Validating configuration for environment: $ENV"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "ERROR: Config file not found: $CONFIG_FILE"
  exit 1
fi

# Validate YAML syntax
if ! yaml-validator "$CONFIG_FILE"; then
  echo "ERROR: Invalid YAML syntax in $CONFIG_FILE"
  exit 1
fi

# Check required environment variables
REQUIRED_VARS=(
  "ARANGO_ROOT_PASSWORD"
  "POSTGRES_ROOT_PASSWORD"
  "REDIS_PASSWORD"
  "JWT_SECRET"
  "ENCRYPTION_KEY"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    MISSING_VARS+=("$var")
  fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
  echo "ERROR: Missing required environment variables:"
  printf '  - %s\n' "${MISSING_VARS[@]}"
  exit 1
fi

echo "✅ Configuration validation passed"
```

### Acceptance Criteria
- [ ] Environment configs for dev, staging, production created
- [ ] Config loader supports environment variable interpolation
- [ ] Hot-reload capability for development environment
- [ ] Validation script checks config syntax and required vars
- [ ] .env.template generated with all required variables
- [ ] TypeScript types defined for all config sections
- [ ] Config retrieval with dot notation paths
- [ ] Secure handling of sensitive credentials
- [ ] Documentation for adding new config values

### Dependencies
- Environment variables defined
- YAML parser library installed
- File system access for config files

---

## CFG-002 through CFG-010: Additional Configuration Work Items

Due to extensive detail requirements, CFG-002 through CFG-010 are outlined below with key focus areas:

### CFG-002: Service Configuration Templates
- Reusable templates for each microservice
- Base config inheritance
- Service-specific overrides
- **Complexity**: M (1-2 days)

### CFG-003: Feature Flags System
- Boolean, percentage, user-targeting, time-based flags
- PostgreSQL storage with Redis caching
- Real-time flag evaluation
- **Complexity**: M (1-2 days)

### CFG-004: Runtime Configuration Updates
- Redis pub/sub for config propagation
- WebSocket notifications
- Rollback capability
- **Complexity**: S (2-4 hours)

### CFG-005: Configuration Validation
- JSON Schema validation
- Pre-commit hooks
- Security validation (secret detection)
- **Complexity**: S (2-4 hours)

### CFG-006: Configuration Versioning
- Git-based version control for configs
- Change audit trail
- Diff visualization
- **Complexity**: S (2-4 hours)

### CFG-007: Multi-Tenant Configuration
- Tenant-specific overrides
- Tenant isolation validation
- Resource quotas per tenant
- **Complexity**: M (1-2 days)

### CFG-008: Configuration Backup & Restore
- Automated daily backups
- Point-in-time restore
- Disaster recovery procedures
- **Complexity**: S (2-4 hours)

### CFG-009: Configuration Documentation Generator
- Auto-generate docs from schemas
- Example configurations
- Migration guides
- **Complexity**: S (2-4 hours)

### CFG-010: Configuration Performance Optimization
- Caching strategies
- Lazy loading
- Config preloading
- **Complexity**: S (2-4 hours)

---

# TEST DATA & SEED DATA WORK ITEMS

## TEST-001: Finance Domain Seed Data (AP/AR Processes)

**Priority**: P2 (Important)
**Complexity**: M (1-2 days)
**Category**: Test Data - Finance Domain

### Description
Create comprehensive seed data for finance domain including Accounts Payable (AP) and Accounts Receivable (AR) process definitions, sample invoices, payment workflows, and approval hierarchies.

### Technical Specifications
```yaml
finance_processes:
  - invoice_approval_workflow: Multi-level approval process
  - payment_processing: Vendor payment automation
  - ar_collections: Receivables collection workflow
  - expense_reimbursement: Employee expense approvals

seed_data_volumes:
  - process_definitions: 8 finance processes
  - sample_invoices: 100 invoices (various states)
  - vendors: 50 vendor records
  - customers: 30 customer records
  - approval_rules: 20 different approval hierarchies
  - payment_terms: 10 payment term configurations

data_states:
  - pending_approval: 30%
  - approved: 40%
  - paid: 20%
  - rejected: 10%
```

### Service Contracts

**Finance Process Schema**:
```typescript
interface FinanceProcessDefinition {
  process_def_id: string;
  name: string;
  category: 'AP' | 'AR' | 'Expense' | 'General';
  description: string;

  approval_hierarchy: {
    level: number;
    role: string;
    threshold_amount?: number;
    required_count: number;
  }[];

  automation_rules: {
    auto_approve_under: number;
    auto_reject_conditions: string[];
    notification_triggers: string[];
  };

  integration_points: {
    erp_system?: string;
    payment_gateway?: string;
    accounting_system?: string;
  };
}

interface InvoiceSeedData {
  invoice_id: string;
  invoice_number: string;
  vendor_id: string;
  amount: number;
  currency: string;
  invoice_date: Date;
  due_date: Date;
  status: 'pending' | 'approved' | 'paid' | 'rejected' | 'overdue';
  line_items: {
    description: string;
    quantity: number;
    unit_price: number;
    total: number;
    gl_account: string;
  }[];
  approval_history: {
    approver: string;
    timestamp: Date;
    action: 'approved' | 'rejected' | 'forwarded';
    comments?: string;
  }[];
}
```

### Seed Data Files

**seed-data/finance/ap-invoice-approval-process.json**:
```json
{
  "process_def_id": "proc_ap_invoice_approval_001",
  "name": "Standard Invoice Approval Workflow",
  "category": "AP",
  "description": "Multi-level approval process for vendor invoices",
  "nodes": [
    {
      "node_id": "start_001",
      "type": "start_event",
      "name": "Invoice Received"
    },
    {
      "node_id": "task_001",
      "type": "human_task",
      "name": "Review Invoice Details",
      "assignee_role": "AP_Clerk",
      "form_fields": [
        {"name": "vendor_name", "type": "text", "required": true},
        {"name": "invoice_number", "type": "text", "required": true},
        {"name": "amount", "type": "currency", "required": true},
        {"name": "gl_account", "type": "dropdown", "required": true}
      ]
    },
    {
      "node_id": "gateway_001",
      "type": "exclusive_gateway",
      "name": "Check Amount",
      "condition_field": "amount"
    },
    {
      "node_id": "task_002",
      "type": "human_task",
      "name": "Manager Approval",
      "assignee_role": "AP_Manager",
      "condition": "amount >= 1000 && amount < 10000"
    },
    {
      "node_id": "task_003",
      "type": "human_task",
      "name": "Director Approval",
      "assignee_role": "Finance_Director",
      "condition": "amount >= 10000"
    },
    {
      "node_id": "task_004",
      "type": "agent_task",
      "name": "Process Payment",
      "agent_type": "payment_processor",
      "tool": "payment_gateway_integration"
    },
    {
      "node_id": "end_001",
      "type": "end_event",
      "name": "Invoice Processed"
    }
  ],
  "flows": [
    {"from": "start_001", "to": "task_001"},
    {"from": "task_001", "to": "gateway_001"},
    {"from": "gateway_001", "to": "task_002", "condition": "amount >= 1000 && amount < 10000"},
    {"from": "gateway_001", "to": "task_003", "condition": "amount >= 10000"},
    {"from": "gateway_001", "to": "task_004", "condition": "amount < 1000"},
    {"from": "task_002", "to": "task_004"},
    {"from": "task_003", "to": "task_004"},
    {"from": "task_004", "to": "end_001"}
  ]
}
```

**seed-data/finance/sample-invoices.json**:
```json
[
  {
    "invoice_id": "inv_001",
    "invoice_number": "INV-2026-001",
    "vendor_id": "vendor_001",
    "vendor_name": "Office Supplies Co.",
    "amount": 450.00,
    "currency": "USD",
    "invoice_date": "2026-02-01T00:00:00Z",
    "due_date": "2026-03-01T00:00:00Z",
    "status": "approved",
    "line_items": [
      {
        "description": "Printer Paper - 10 reams",
        "quantity": 10,
        "unit_price": 25.00,
        "total": 250.00,
        "gl_account": "6100-Office Supplies"
      },
      {
        "description": "Ink Cartridges",
        "quantity": 8,
        "unit_price": 25.00,
        "total": 200.00,
        "gl_account": "6100-Office Supplies"
      }
    ],
    "approval_history": [
      {
        "approver": "john.smith@example.com",
        "approver_role": "AP_Clerk",
        "timestamp": "2026-02-02T10:30:00Z",
        "action": "approved",
        "comments": "Verified against purchase order PO-12345"
      }
    ]
  },
  {
    "invoice_id": "inv_002",
    "invoice_number": "INV-2026-002",
    "vendor_id": "vendor_002",
    "vendor_name": "Cloud Services Inc.",
    "amount": 15000.00,
    "currency": "USD",
    "invoice_date": "2026-02-01T00:00:00Z",
    "due_date": "2026-02-15T00:00:00Z",
    "status": "pending",
    "line_items": [
      {
        "description": "Cloud Infrastructure - Monthly",
        "quantity": 1,
        "unit_price": 15000.00,
        "total": 15000.00,
        "gl_account": "6200-IT Services"
      }
    ],
    "approval_history": [
      {
        "approver": "jane.doe@example.com",
        "approver_role": "AP_Clerk",
        "timestamp": "2026-02-02T11:00:00Z",
        "action": "forwarded",
        "comments": "Amount requires Director approval"
      }
    ]
  }
]
```

### Scripts/Automation Required

**scripts/seed-finance-data.sh**:
```bash
#!/bin/bash
# Seed finance domain test data

echo "Seeding finance domain test data..."

# Load process definitions
echo "Loading AP/AR process definitions..."
node scripts/load-process-definitions.js seed-data/finance/ap-invoice-approval-process.json
node scripts/load-process-definitions.js seed-data/finance/ar-collection-process.json
node scripts/load-process-definitions.js seed-data/finance/expense-reimbursement-process.json

# Load vendors
echo "Loading vendor data..."
node scripts/load-vendors.js seed-data/finance/vendors.json

# Load sample invoices
echo "Loading sample invoices..."
node scripts/load-invoices.js seed-data/finance/sample-invoices.json

# Create execution instances for active invoices
echo "Creating execution instances..."
node scripts/create-execution-instances.js finance

echo "✅ Finance domain seed data loaded"
```

### Testing Procedures
```bash
# Load all finance seed data
./scripts/seed-finance-data.sh

# Verify process definitions loaded
curl http://localhost:3001/api/processes?category=AP | jq .

# Verify invoices loaded
curl http://localhost:3001/api/invoices | jq '.[] | {invoice_number, status, amount}'

# Test invoice approval workflow
curl -X POST http://localhost:3002/api/executions/start \
  -H "Content-Type: application/json" \
  -d '{
    "process_def_id": "proc_ap_invoice_approval_001",
    "context": {
      "invoice_id": "inv_001",
      "amount": 450.00
    }
  }'

# Query pending approvals
curl http://localhost:3004/api/human-tasks?status=pending\&role=AP_Manager | jq .
```

### Acceptance Criteria
- [ ] 8 finance process definitions loaded
- [ ] 100 sample invoices with various statuses
- [ ] 50 vendor records created
- [ ] 30 customer records for AR
- [ ] 20 approval hierarchy configurations
- [ ] Process definitions include all workflow nodes
- [ ] Sample data covers all approval levels
- [ ] Execution instances created for active invoices
- [ ] Human tasks generated for pending approvals
- [ ] Data validates against schema

### Dependencies
- ArangoDB database (INF-003)
- Process service (for loading definitions)
- Execution service (for creating instances)

---

## TEST-002: HR Domain Seed Data (Onboarding Processes)

**Priority**: P2 (Important)
**Complexity**: M (1-2 days)
**Category**: Test Data - HR Domain

### Description
Create comprehensive seed data for HR domain including employee onboarding workflows, background check processes, training schedules, and equipment provisioning.

### Technical Specifications
```yaml
hr_processes:
  - employee_onboarding: New hire onboarding workflow
  - background_check: Background verification process
  - equipment_provisioning: IT equipment setup
  - training_enrollment: Required training assignments
  - offboarding: Employee exit process

seed_data_volumes:
  - process_definitions: 5 HR processes
  - employee_records: 30 employees (various onboarding stages)
  - departments: 8 departments
  - training_courses: 15 courses
  - equipment_inventory: 50 items

onboarding_stages:
  - pre_hire: 10%
  - first_day: 20%
  - first_week: 30%
  - first_month: 25%
  - completed: 15%
```

### Seed Data Files

**seed-data/hr/employee-onboarding-process.json**:
```json
{
  "process_def_id": "proc_hr_onboarding_001",
  "name": "Standard Employee Onboarding",
  "category": "HR",
  "description": "Complete employee onboarding workflow",
  "nodes": [
    {
      "node_id": "start_001",
      "type": "start_event",
      "name": "Offer Accepted"
    },
    {
      "node_id": "task_001",
      "type": "human_task",
      "name": "Prepare Onboarding Documents",
      "assignee_role": "HR_Coordinator",
      "documents": [
        "Employment Contract",
        "Tax Forms",
        "Benefits Enrollment",
        "Company Policies Acknowledgment"
      ]
    },
    {
      "node_id": "task_002",
      "type": "agent_task",
      "name": "Initiate Background Check",
      "agent_type": "background_check_agent",
      "tool": "background_check_api"
    },
    {
      "node_id": "task_003",
      "type": "parallel_gateway",
      "name": "Parallel Setup Tasks"
    },
    {
      "node_id": "task_004",
      "type": "agent_task",
      "name": "Create Email Account",
      "agent_type": "it_provisioning_agent",
      "tool": "email_system_api"
    },
    {
      "node_id": "task_005",
      "type": "agent_task",
      "name": "Order Equipment",
      "agent_type": "it_provisioning_agent",
      "tool": "inventory_system_api"
    },
    {
      "node_id": "task_006",
      "type": "human_task",
      "name": "Assign Workspace",
      "assignee_role": "Facilities_Manager"
    },
    {
      "node_id": "task_007",
      "type": "human_task",
      "name": "Schedule Orientation",
      "assignee_role": "HR_Coordinator"
    },
    {
      "node_id": "task_008",
      "type": "human_task",
      "name": "First Day Check-in",
      "assignee_role": "Manager"
    },
    {
      "node_id": "task_009",
      "type": "agent_task",
      "name": "Enroll in Training Courses",
      "agent_type": "training_enrollment_agent",
      "required_courses": [
        "Company Culture & Values",
        "Information Security Basics",
        "Harassment Prevention"
      ]
    },
    {
      "node_id": "end_001",
      "type": "end_event",
      "name": "Onboarding Complete"
    }
  ]
}
```

**seed-data/hr/employees.json**:
```json
[
  {
    "employee_id": "emp_001",
    "first_name": "Alice",
    "last_name": "Johnson",
    "email": "alice.johnson@example.com",
    "department": "Engineering",
    "position": "Senior Software Engineer",
    "start_date": "2026-02-15T00:00:00Z",
    "onboarding_stage": "first_week",
    "manager_id": "emp_mgr_001",
    "location": "San Francisco, CA",
    "employment_type": "Full-time",
    "required_equipment": [
      "MacBook Pro",
      "External Monitor",
      "Keyboard & Mouse",
      "Headphones"
    ],
    "required_training": [
      "Company Culture & Values",
      "Information Security Basics",
      "Engineering Best Practices"
    ],
    "background_check_status": "completed"
  },
  {
    "employee_id": "emp_002",
    "first_name": "Bob",
    "last_name": "Smith",
    "email": "bob.smith@example.com",
    "department": "Finance",
    "position": "Financial Analyst",
    "start_date": "2026-03-01T00:00:00Z",
    "onboarding_stage": "pre_hire",
    "manager_id": "emp_mgr_002",
    "location": "New York, NY",
    "employment_type": "Full-time",
    "required_equipment": [
      "Dell Laptop",
      "Docking Station",
      "Dual Monitors"
    ],
    "required_training": [
      "Company Culture & Values",
      "Information Security Basics",
      "Financial Systems Training",
      "SOX Compliance"
    ],
    "background_check_status": "pending"
  }
]
```

### Scripts/Automation Required

**scripts/seed-hr-data.sh**:
```bash
#!/bin/bash
# Seed HR domain test data

echo "Seeding HR domain test data..."

# Load process definitions
echo "Loading HR process definitions..."
node scripts/load-process-definitions.js seed-data/hr/employee-onboarding-process.json
node scripts/load-process-definitions.js seed-data/hr/background-check-process.json
node scripts/load-process-definitions.js seed-data/hr/equipment-provisioning-process.json

# Load departments
echo "Loading department data..."
node scripts/load-departments.js seed-data/hr/departments.json

# Load employees
echo "Loading employee data..."
node scripts/load-employees.js seed-data/hr/employees.json

# Load training courses
echo "Loading training courses..."
node scripts/load-training-courses.js seed-data/hr/training-courses.json

# Create onboarding execution instances
echo "Creating onboarding execution instances..."
node scripts/create-hr-executions.js

echo "✅ HR domain seed data loaded"
```

### Acceptance Criteria
- [ ] 5 HR process definitions loaded
- [ ] 30 employee records with various onboarding stages
- [ ] 8 department configurations
- [ ] 15 training courses defined
- [ ] Equipment inventory seeded
- [ ] Onboarding workflows initiated for new hires
- [ ] Human tasks created for coordinators and managers
- [ ] Background check processes started
- [ ] IT provisioning tasks queued

### Dependencies
- ArangoDB database (INF-003)
- Process service
- Execution service
- Agent service (for automated tasks)

---

## TEST-003 through TEST-010: Additional Test Data Work Items

### TEST-003: Procurement Domain Seed Data
- Purchase requisition workflows
- Vendor management processes
- PO approval hierarchies
- **Complexity**: M (1-2 days)

### TEST-004: Test User Accounts and Roles
- User accounts for all personas
- Role-based access control data
- Permission matrices
- **Complexity**: S (2-4 hours)

### TEST-005: Sample Execution Histories
- Completed process executions
- Failed execution scenarios
- Long-running processes
- **Complexity**: M (1-2 days)

### TEST-006: Agent Interaction Test Data
- Agent conversation histories
- Tool execution logs
- Memory snapshots
- **Complexity**: S (2-4 hours)

### TEST-007: Performance Testing Data
- Large-scale process definitions
- High-volume execution data
- Stress test scenarios
- **Complexity**: M (1-2 days)

### TEST-008: Error Scenario Test Data
- Failed task examples
- Timeout scenarios
- Validation failures
- **Complexity**: S (2-4 hours)

### TEST-009: Multi-Tenant Test Data
- Multiple organization configurations
- Tenant isolation validation
- Cross-tenant scenarios
- **Complexity**: M (1-2 days)

### TEST-010: Integration Test Data
- External system mock data
- API response samples
- WebSocket event sequences
- **Complexity**: S (2-4 hours)

---

## Summary

### Configuration Management Work Items (CFG-001 to CFG-010)
Total estimated effort: 8-12 days
- **P0 (Blocking)**: CFG-001
- **P1 (Critical)**: CFG-002, CFG-005
- **P2 (Important)**: CFG-003, CFG-004, CFG-006 through CFG-010

### Test Data Work Items (TEST-001 to TEST-010)
Total estimated effort: 8-12 days
- **P2 (Important)**: All test data items
- Focus areas: Finance, HR, Procurement domains
- Supporting: Users, roles, execution histories, performance data

### Key Integration Points
- Configuration system integrates with all infrastructure components
- Test data relies on infrastructure being operational
- Feature flags enable gradual rollout of test scenarios
- Seed data supports end-to-end testing and demos
