---
name: flowmaster-environment
description: "FlowMaster environment variables and configuration for all microservices"
disable-model-invocation: false
---

# FlowMaster Environment Variables Skill

This skill provides a comprehensive reference for all FlowMaster microservices environment variables, including required settings, defaults, and configuration patterns.

**Note**: The API Gateway (Port 9000) is implemented in **Python/FastAPI** (not Node.js), serving as the central request router and authentication entry point for all client requests.

## Core Infrastructure Variables

### JWT & Security (All Services)
```
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
```
- **Purpose**: Shared JWT authentication across all services
- **Required**: Yes
- **Note**: Must be identical across all services for inter-service communication

### CORS Configuration
```
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: Allow cross-origin requests from frontend and local development
- **Default**: Listed values for development
- **Production**: Update to actual domain origins

---

## Shared Infrastructure Services

### Redis (Shared Instance)
```
REDIS_HOST=flowmaster-redis
REDIS_PORT=6379
REDIS_PASSWORD=flowmaster_redis_2025
REDIS_DB=0
```
- **Purpose**: Caching, pub/sub messaging, state management
- **Default DB**: 0 for general use, specific DBs for services (1, 5, 6)
- **Used by**: All services for caching and WebSocket pub/sub

### ArangoDB (Graph Database)
```
ARANGO_HOST=monolith-arangodb
ARANGO_PORT=8529
ARANGO_USER=root
ARANGO_PASSWORD=flowmaster25!
ARANGO_DATABASE=flowmaster
```
- **Purpose**: Process definitions, nodes, tasks, documents
- **Database**: flowmaster (primary)
- **Services**: Process Design, Human Task, Document Intelligence

### PostgreSQL (Relational Database)
```
POSTGRES_HOST=<service>-postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=flowmaster25!
POSTGRES_DATABASE=<service-specific>
```
- **Purpose**: Structured data, audit logs, execution history
- **Databases**: execution_engine, flowmaster_schedules, notification_service, event_bus, flowmaster_agent
- **Note**: Avoid special characters (!) in passwords for URL encoding issues

---

## Service-Specific Environment Variables

### Frontend (Port 5173)
```
VITE_API_URL=http://localhost:9000
VITE_WS_URL=ws://localhost:9010/ws
VITE_WS_EXECUTION_URL=ws://localhost:9010/ws/execution
VITE_WS_BASE_URL=ws://localhost:9010
VITE_PROCESS_DESIGN_URL=http://localhost:9003
VITE_EXECUTION_ENGINE_URL=http://localhost:9005
VITE_HUMAN_TASK_URL=http://localhost:9006
VITE_DOC_INTELLIGENCE_URL=http://localhost:9002
VITE_NODE_ENV=development
```
- **Purpose**: Frontend API and WebSocket endpoints
- **Primary**: API_URL routes through API Gateway (9000)
- **WebSocket**: Direct connection to WebSocket Gateway (9010)
- **Direct Services**: Available via Vite proxy for development

### API Gateway (Port 9000)
```
PORT=9000
ENVIRONMENT=development
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
REDIS_HOST=flowmaster-redis
REDIS_PORT=6379
REDIS_PASSWORD=flowmaster_redis_2025
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: Central request routing and authentication
- **Role**: Entry point for all client requests
- **Services**: Routes to all microservices via service.yaml configuration

### Process Design Service (Port 9003)
```
PORT=9003
ARANGO_URL=http://monolith-arangodb:8529
ARANGO_DATABASE=flowmaster
ARANGO_USERNAME=root
ARANGO_PASSWORD=flowmaster25!
JWT_SECRET=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
EVENT_BUS_URL=http://flowmaster-event-bus-service:9013
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
LOG_LEVEL=DEBUG
```
- **Purpose**: BPMN process definitions, nodes, edges management
- **Database**: ArangoDB (flowmaster)
- **Event Bus**: Publishes process lifecycle events

### Execution Engine Service (Port 9005)
```
PORT=9005
ENVIRONMENT=development
DEBUG=true
POSTGRES_HOST=execution-postgres
POSTGRES_PORT=5432
POSTGRES_USER=flowmaster
POSTGRES_PASSWORD=flowmaster25!
POSTGRES_DATABASE=execution_engine
REDIS_HOST=flowmaster-redis
REDIS_PORT=6379
REDIS_PASSWORD=flowmaster_redis_2025
REDIS_DB=0
WS_REDIS_ENABLED=true
WS_REDIS_HOST=flowmaster-redis
WS_REDIS_PORT=6379
WS_REDIS_PASSWORD=flowmaster_redis_2025
WS_REDIS_DB=1
EVENT_BUS_URL=http://flowmaster-event-bus-service:9013
PROCESS_DESIGN_SERVICE_URL=http://flowmaster-process-design-service:9003
HUMAN_TASK_SERVICE_URL=http://flowmaster-human-task-service:9006
AI_AGENT_SERVICE_URL=http://flowmaster-ai-agent-service:9001
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: Core workflow execution and state management
- **Database**: PostgreSQL (execution_engine) for instances and history
- **Cache**: Redis DB 0 for state, DB 1 for WebSocket state
- **Integration**: Calls Process Design, Human Task, and AI Agent services

### Human Task Service (Port 9006)
```
SERVICE_NAME=human-task-service
SERVICE_VERSION=1.0.0
PORT=9006
ENVIRONMENT=development
DEBUG=true
ARANGO_HOST=flowmaster-arangodb
ARANGO_PORT=8529
ARANGO_USER=root
ARANGO_PASSWORD=flowmaster25!
ARANGO_DATABASE=flowmaster
EXECUTION_ENGINE_URL=http://flowmaster-execution-engine-service:9005
EVENT_BUS_URL=http://flowmaster-event-bus-service:9013
EVENT_BUS_ENABLED=true
WS_REDIS_HOST=flowmaster-redis
WS_REDIS_PORT=6379
WS_REDIS_PASSWORD=flowmaster_redis_2025
WS_REDIS_DB=0
WS_REDIS_ENABLED=true
REDIS_HOST=flowmaster-redis
REDIS_PORT=6379
REDIS_PASSWORD=flowmaster_redis_2025
REDIS_DB=5
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: Human-in-the-loop task management and escalations
- **Database**: ArangoDB for task records
- **Callbacks**: Sends completion events to Execution Engine
- **Redis DB 5**: Task-specific caching

### Scheduling Service (Port 9008)
```
SERVICE_NAME=scheduling-service
SERVICE_VERSION=1.0.0
PORT=9008
ENVIRONMENT=development
DEBUG=true
POSTGRES_HOST=scheduling-postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=flowmaster25
POSTGRES_DB=flowmaster_schedules
EXECUTION_ENGINE_URL=http://flowmaster-execution-engine-service:9005
EXECUTION_TIMEOUT=30
EVENT_BUS_URL=http://flowmaster-event-bus-service:9013
EVENT_BUS_ENABLED=true
WS_REDIS_HOST=flowmaster-redis
WS_REDIS_PORT=6379
WS_REDIS_PASSWORD=flowmaster_redis_2025
WS_REDIS_ENABLED=true
SCHEDULER_TIMEZONE=UTC
SCHEDULER_JOB_DEFAULTS_COALESCE=true
SCHEDULER_JOB_DEFAULTS_MAX_INSTANCES=3
SCHEDULER_MISFIRE_GRACE_TIME=60
MAX_RETRIES=3
RETRY_DELAY=5
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: Cron-based automated process triggering
- **Scheduler**: APScheduler with PostgreSQL backend
- **Timezone**: UTC (configurable)
- **Job Settings**: Coalesce enabled, max 3 instances, 60s misfire grace

### Notification Service (Port 9011)
```
SERVICE_NAME=notification-service
SERVICE_VERSION=1.0.0
PORT=9011
ENVIRONMENT=development
DEBUG=true
POSTGRES_HOST=notification-postgres
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=flowmaster25!
POSTGRES_DATABASE=notification_service
POSTGRES_POOL_SIZE=10
POSTGRES_MAX_OVERFLOW=20
EVENT_BUS_URL=http://flowmaster-event-bus-service:9013
EVENT_BUS_SUBSCRIBER_ID=notification-service
EVENT_BUS_ENABLED=true
WS_REDIS_HOST=flowmaster-redis
WS_REDIS_PORT=6379
WS_REDIS_PASSWORD=flowmaster_redis_2025
WS_REDIS_DB=0
WS_REDIS_ENABLED=true
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=100
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: In-app notifications with user preferences
- **Event Bus**: Subscribes to task, execution, and schedule events
- **Pagination**: Default 20, max 100 per page
- **Pool**: Configurable connection pooling

### Event Bus Service (Port 9013)
```
APP_NAME=event-bus-service
PORT=9013
ENVIRONMENT=development
DEBUG=true
KAFKA_BOOTSTRAP_SERVERS=flowmaster-kafka:9092
KAFKA_CLIENT_ID=event-bus-service
KAFKA_CONSUMER_GROUP_ID=event-bus-consumer-group
DATABASE_URL=postgresql+asyncpg://postgres:flowmaster25@event-bus-postgres:5432/event_bus
REDIS_URL=redis://:flowmaster_redis_2025@flowmaster-redis:6379/0
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
```
- **Purpose**: Event-driven communication hub with Kafka
- **Kafka Topics**: flowmaster.events.workflow, flowmaster.events.execution, flowmaster.events.task, etc.
- **Database**: PostgreSQL for audit logs and subscriptions
- **Cache**: Redis for caching (DB 0)

### WebSocket Gateway Service (Port 9010)
```
NODE_ENV=development
ENVIRONMENT=development
PORT=9010
REDIS_HOST=flowmaster-redis
REDIS_PORT=6379
REDIS_PASSWORD=flowmaster_redis_2025
REDIS_DB=0
REDIS_KEY_PREFIX=wgs:
JWT_SECRET=flowmaster-jwt-secret-2025-secure-key
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
WS_CORS_ORIGIN=*
LOG_LEVEL=info
```
- **Purpose**: Real-time event distribution via WebSocket
- **Runtime**: Node.js 18+
- **Key Prefix**: Quoted as "wgs:" to avoid YAML parsing issues
- **Log Level**: Must be lowercase (info, debug, warn, error)

### Document Intelligence Service (Port 9002)
```
PORT=9002
DEBUG=true
ARANGO_HOST=monolith-arangodb
ARANGO_PORT=8529
ARANGO_USER=root
ARANGO_PASSWORD=flowmaster25!
ARANGO_DATABASE=flowmaster
AI_AGENT_SERVICE_URL=http://flowmaster-ai-agent-service:9001
LLM_MODEL_PRIMARY=google/gemini-2.0-flash-001
LLM_MODEL_FALLBACK=openai/gpt-3.5-turbo
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=8000
LLM_TIMEOUT=60
OPENAI_API_KEY=<your-openai-key>
EMBEDDING_MODEL=text-embedding-ada-002
UPLOAD_DIR=/tmp/flowmaster_uploads
MAX_FILE_SIZE=52428800
CHUNK_SIZE=1000
CHUNK_OVERLAP=100
MAX_SUBPROCESS_DEPTH=5
MIN_CONFIDENCE_THRESHOLD=0.7
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
CORS_ORIGINS=*
```
- **Purpose**: AI-powered document processing and process extraction
- **LLM Routing**: Routes through AI Agent Service (not directly to providers)
- **Models**: Primary Gemini, fallback to OpenAI
- **Document Processing**: Max 50MB files, 1000-char chunks with 100-char overlap
- **Confidence**: Minimum 0.7 threshold for AI-extracted patterns

### AI Agent Service (Port 9001)
```
APP_NAME=flowmaster-ai-agent-service
APP_ENV=development
APP_DEBUG=true
APP_HOST=0.0.0.0
APP_PORT=9001
DATABASE_URL=postgresql+asyncpg://fm_agent_user:fm_agent_secure_2025@ai-agent-postgres:5432/flowmaster
ARANGO_HOST=monolith-arangodb
ARANGO_PORT=8529
ARANGO_DATABASE=flowmaster
ARANGO_USER=root
ARANGO_PASSWORD=flowmaster25!
REDIS_URL=redis://ai-agent-redis:6379/0
REDIS_CACHE_TTL=3600
OPENROUTER_API_KEY=<your_openrouter_key>
GOOGLE_API_KEY=<your_google_key>
GEMINI_MODEL=gemini-2.0-flash-exp
OPENAI_API_KEY=<your_openai_key>
ANTHROPIC_API_KEY=<your_anthropic_key>
DEFAULT_LLM_PROVIDER=google
DEFAULT_LLM_MODEL=gemini-2.0-flash-exp
COMPOSIO_API_KEY=<optional>
COMPOSIO_ENABLED=false
JWT_SECRET_KEY=flowmaster-jwt-secret-2025-secure-key
JWT_ALGORITHM=HS256
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:9000
EVENT_BUS_SERVICE_URL=http://flowmaster-event-bus-service:9013
AUTH_SERVICE_URL=http://monolith-backend:8000
```
- **Purpose**: Central LLM orchestration and agent management
- **LLM Providers**: Google (primary), OpenRouter, OpenAI, Anthropic
- **Cache**: Redis with 3600s (1 hour) TTL
- **Integrations**: Composio (optional, for tool execution)
- **Token Usage**: Tracks all LLM requests with cost estimation

### DXG Service (Port 8005)
```
ARANGODB_URL=http://localhost:8529
ARANGODB_DATABASE=flowmaster
OPENAI_API_KEY=sk-...
DXG_PORT=8005
DXG_ENVIRONMENT=development
```
- **Purpose**: AI-powered dynamic UI generation from workflow context
- **LLM**: OpenAI GPT-4, temperature 0.3
- **Database**: ArangoDB (walks workflow graph for context)

### Engage App (Port 3010)
```
NEXT_PUBLIC_DXG_API_URL=http://localhost:8005/api/v1
DXG_API_URL=http://localhost:8005/api/v1
NEXT_PUBLIC_API_URL=http://localhost:9000
PORT=3010
```
- **Purpose**: Employee-facing task execution with DXG integration
- **Runtime**: Next.js 16
- **DXG**: Both public (client) and server-side URLs needed

### SDX API
```
SDX_PORT=8010
SDX_MASTER_KEY=<encryption-key>
ARANGODB_URL=http://localhost:8529
ARANGODB_DATABASE=flowmaster
OPENAI_API_KEY=sk-...
POSTGRES_URL=postgresql://...
```
- **Purpose**: Semantic data management with LLM field matching
- **Database**: ArangoDB (primary) + PostgreSQL
- **MCP Server**: JSON-RPC 2.0 interface

---

## Environment Variable Categories

### By Function

#### Authentication & Security
- JWT_SECRET_KEY, JWT_ALGORITHM
- CORS_ORIGINS, WS_CORS_ORIGIN

#### Database Connections
- POSTGRES_HOST, POSTGRES_PORT, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DATABASE
- ARANGO_HOST, ARANGO_PORT, ARANGO_USER, ARANGO_PASSWORD, ARANGO_DATABASE
- REDIS_HOST, REDIS_PORT, REDIS_PASSWORD, REDIS_DB

#### Service Integration
- EVENT_BUS_URL, EVENT_BUS_ENABLED
- EXECUTION_ENGINE_URL, PROCESS_DESIGN_SERVICE_URL
- AI_AGENT_SERVICE_URL, WS_REDIS_ENABLED

#### LLM Configuration
- DEFAULT_LLM_PROVIDER, DEFAULT_LLM_MODEL
- OPENROUTER_API_KEY, GOOGLE_API_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY
- LLM_TEMPERATURE, LLM_MAX_TOKENS, LLM_TIMEOUT

#### Logging & Debugging
- LOG_LEVEL, DEBUG, ENVIRONMENT
- APP_DEBUG, NODE_ENV

---

## Configuration Patterns

### Development vs Production

**Development**:
- ENVIRONMENT=development
- DEBUG=true (where applicable)
- LOG_LEVEL=DEBUG or info
- LOCAL_ARANGODB, LOCAL_POSTGRES connections

**Production**:
- ENVIRONMENT=production
- DEBUG=false
- LOG_LEVEL=warn or error
- RDS/Cloud database connections
- Secure JWT_SECRET_KEY (rotate regularly)
- Real API keys for LLM providers

### Docker Networking
All services use container names for internal communication:
- Database hosts: monolith-arangodb, execution-postgres, etc.
- Service URLs: flowmaster-{service-name}-service:{port}
- Example: http://flowmaster-execution-engine-service:9005

### Redis Database Allocation
```
DB 0: General pub/sub, state cache (Execution Engine, WebSocket Gateway)
DB 1: WebSocket state (Execution Engine)
DB 5: Task caching (Human Task Service)
DB 6: Schedule caching (Scheduling Service)
```

### Port Mapping
```
3010: Engage App
3011: SDX Frontend (was 3010, conflict resolved)
5173: Frontend (Vite)
8005: DXG Backend
8010: SDX API (demo server)
8529: ArangoDB
5432: PostgreSQL
6379: Redis
9000: API Gateway (Python/FastAPI)
9001: AI Agent Service
9002: Document Intelligence
9003: Process Design
9005: Execution Engine
9006: Human Task
9008: Scheduling
9010: WebSocket Gateway
9011: Notification
9013: Event Bus
9092: Kafka
```

---

## When to Use This Skill

1. **Microservices Setup**: Configuring new service instances
2. **Integration Issues**: Debugging service-to-service communication
3. **Database Connections**: Setting up or troubleshooting database access
4. **Environment Migration**: Moving between development/staging/production
5. **LLM Configuration**: Setting up AI provider credentials
6. **Performance Tuning**: Adjusting cache TTLs, connection pools, timeouts
7. **Troubleshooting**: Quick reference for expected variable values

---

## Notes & Best Practices

- **No Special Characters in Passwords**: PostgreSQL passwords should avoid special characters like `!` due to URL encoding issues
- **Container Names in Docker**: Use container names (not localhost) for inter-service URLs
- **Redis Key Prefix**: Quote Redis key prefix values in YAML: `"REDIS_KEY_PREFIX=wgs:"`
- **Log Level Validation**: WebSocket Gateway requires lowercase log levels (info, not INFO)
- **Secret Rotation**: Change JWT_SECRET_KEY and provider API keys regularly in production
- **Multi-tenancy**: REDIS_DB and database naming allows per-tenant isolation
- **Health Checks**: All services expose `/health`, `/health/ready`, and `/health/live` endpoints
