---
name: flowmaster-backend
description: "FlowMaster backend API endpoints, microservices architecture, and integration patterns for building MCP servers"
disable-model-invocation: false
---

# FlowMaster Backend Architecture & APIs

## Overview

FlowMaster is a modular microservices platform with 22 core services organized into 5 layers. Each service owns its database and communicates via Event Bus (async) and REST APIs (sync). Critical for MCP integration: all cross-service data flows through standardized APIs or event-driven patterns.

---

## Core Domain Services (Layer 1)

### 1. Process Design Service (PDS)
**Purpose:** Design, version, and manage dynamic/self-declaring process definitions

**Key Endpoints:**
- `POST /processes/designs` — Create new process definition
- `GET /processes/{id}/versions` — Retrieve process versions
- `PUT /processes/{id}` — Update process definition
- `POST /processes/{id}/publish` — Publish process version
- `POST /processes/{id}/validate` — Validate process syntax & mappings
- `POST /processes/{id}/sandbox` — Test process execution

**Request Format:**
```json
{
  "name": "Approval Workflow",
  "nodes": [
    {
      "id": "node-1",
      "type": "human_task",
      "config": { "assignee": "manager" }
    }
  ],
  "version": "1.0.0"
}
```

**Response Format:**
```json
{
  "id": "proc-123",
  "version": "1.0.0",
  "status": "published",
  "createdAt": "2025-02-07T10:00:00Z",
  "metadata": { "nodes": 3, "variables": 5 }
}
```

**Database:** ArangoDB (process_definitions, process_versions)
**Dependencies:** Auth Service, Data Intelligence, Event Bus, Internal Data Hub API

**Important Patterns:**
- Supports dynamic/self-declaring schemas — schema changes don't break running processes
- Contract tests required for cross-service interactions
- Must integrate suggested mappings from Data Intelligence Service

---

### 2. Execution Engine Service (EES)
**Purpose:** Execute processes, orchestrate tasks, manage state, and coordinate nodes

**Key Endpoints:**
- `POST /executions` — Start process execution
- `GET /executions/{id}` — Get execution state
- `PUT /executions/{id}/pause` — Pause running execution
- `PUT /executions/{id}/resume` — Resume paused execution
- `PUT /executions/{id}/cancel` — Cancel execution
- `GET /executions/{id}/history` — Get execution event history
- `POST /executions/{id}/compensate` — Trigger compensating actions (saga pattern)

**Request Format:**
```json
{
  "processId": "proc-123",
  "version": "1.0.0",
  "variables": {
    "userId": "user-456",
    "amount": 5000
  },
  "initiator": "system"
}
```

**Response Format:**
```json
{
  "executionId": "exec-789",
  "processId": "proc-123",
  "status": "running",
  "currentNode": "node-1",
  "state": {
    "variables": { "userId": "user-456", "amount": 5000 },
    "nodeStates": { "node-1": "completed" }
  },
  "startedAt": "2025-02-07T10:05:00Z"
}
```

**Database:** PostgreSQL (execution_instances, execution_state), Redis (transient state)
**Dependencies:** PDS, AI Agent, Human Task, Data Hub, Integration Hub, Event Bus, Auth

**Important Patterns:**
- **Execution may be distributed** between client & server
- **Durable state:** All state changes persisted to PostgreSQL
- **Event-driven:** Publishes events for async operations (node completion, task updates, etc.)
- **Node routing:** Routes to Human Task, AI Agent, or Integrations based on node type
- **Saga pattern:** Supports compensating actions for distributed transactions

---

### 3. Human Task Service (HTS)
**Purpose:** Manage human-in-the-loop tasks for approvals, forms, and decisions

**Key Endpoints:**
- `POST /tasks` — Create new human task
- `GET /tasks/{id}` — Get task details
- `PUT /tasks/{id}/assign` — Assign task to user
- `PUT /tasks/{id}/respond` — Submit task response/decision
- `GET /tasks` — List tasks with filters (assignee, status, SLA)
- `PUT /tasks/{id}/escalate` — Escalate task up chain
- `GET /tasks/{id}/history` — Get task audit trail

**Request Format:**
```json
{
  "executionId": "exec-789",
  "title": "Approve Budget Request",
  "description": "Review $5000 request for project X",
  "assignee": "manager-123",
  "form": {
    "fields": [
      { "name": "decision", "type": "enum", "options": ["approve", "reject", "revise"] },
      { "name": "comments", "type": "text" }
    ]
  },
  "sla": { "hoursToComplete": 24 },
  "escalationChain": ["manager-123", "director-456"]
}
```

**Response Format:**
```json
{
  "taskId": "task-111",
  "status": "assigned",
  "assignedTo": "manager-123",
  "createdAt": "2025-02-07T10:10:00Z",
  "slaDeadline": "2025-02-08T10:10:00Z",
  "response": null
}
```

**Database:** PostgreSQL (tasks, responses, assignments)
**Dependencies:** Auth, Notification, Execution Engine, Event Bus

**Important Patterns:**
- **SLA & escalation handling:** Required for compliance
- **Event-driven notifications:** Publishes events when tasks are created, assigned, or completed
- **Dynamic form rendering:** Supports complex validation rules
- **Response tracking:** Stores user responses linked to execution state

---

### 4. Integration Hub Service (IHS)
**Purpose:** External system integrations & secure connector orchestration

**Key Endpoints:**
- `POST /integrations` — Register new integration
- `GET /integrations/{id}` — Get integration config
- `PUT /integrations/{id}` — Update integration
- `POST /integrations/{id}/connect` — Test connection
- `POST /integrations/{id}/transform` — Apply data transformation
- `POST /integrations/{id}/execute` — Execute external API call with retry/circuit-breaker

**Request Format:**
```json
{
  "name": "Salesforce CRM",
  "connectorType": "rest_api",
  "baseUrl": "https://company.salesforce.com/api/v57.0",
  "authType": "oauth2",
  "credentials": {
    "clientId": "encrypted-value",
    "clientSecret": "encrypted-value"
  },
  "mapping": {
    "external_id": "id",
    "external_name": "name"
  }
}
```

**Response Format:**
```json
{
  "integrationId": "int-222",
  "status": "connected",
  "lastSyncAt": "2025-02-07T10:00:00Z",
  "transformedData": { "records": 150 }
}
```

**Database:** PostgreSQL (integrations, connector_secrets, logs)
**Dependencies:** Data Intelligence, Data Hub, Event Bus, Auth

**Supported Connectors:**
- REST API (with OAuth/API key)
- SOAP
- Database (SQL, NoSQL)
- FTP/SFTP
- Webhooks (inbound/outbound)

**Important Patterns:**
- **Secure vault:** All credentials encrypted & audited
- **Async integrations:** Supports event-based async with guaranteed delivery
- **Retry & circuit breaker:** Built-in resilience
- **Data mapping:** Transform + validation before ingestion

---

### 5. Internal Data Hub Service (IDHS)
**Purpose:** Tenant-aware dynamic data storage for process variables and entity data

**Key Endpoints:**
- `POST /entities` — Create new entity type
- `POST /entities/{type}` — Insert entity record
- `GET /entities/{type}/{id}` — Get entity record
- `PUT /entities/{type}/{id}` — Update entity
- `DELETE /entities/{type}/{id}` — Delete entity
- `GET /entities/{type}` — Query entities with filters
- `POST /entities/search` — Full-text search across entities

**Request Format:**
```json
{
  "entityType": "customer",
  "data": {
    "name": "Acme Corp",
    "email": "contact@acme.com",
    "region": "US-WEST"
  }
}
```

**Response Format:**
```json
{
  "id": "entity-333",
  "entityType": "customer",
  "tenantId": "tenant-123",
  "data": { "name": "Acme Corp", "email": "contact@acme.com", "region": "US-WEST" },
  "createdAt": "2025-02-07T10:00:00Z",
  "relationships": { "contacts": ["entity-444", "entity-555"] }
}
```

**Database:** ArangoDB (entity_records, entity_collections, schemas)
**Dependencies:** Auth, Data Intelligence, Integration Hub

**Important Patterns:**
- **Tenant isolation:** Schema-per-tenant or tenantId column-based
- **Dynamic schemas:** Schema registry for flexible entity types
- **Relationship resolution:** Supports cross-entity queries
- **Single source of truth:** Acts as primary dynamic data store for all processes

---

## Intelligence Layer Services (Layer 2)

### 6. AI Agent Service (AIS)
**Purpose:** Central orchestrator for LLM/agent calls with routing, caching, and metering

**Key Endpoints:**
- `POST /agents/{id}/invoke` — Call LLM with prompt
- `POST /agents/{id}/stream` — Stream LLM response
- `GET /agents` — List available agents
- `POST /agents/{id}/tools/execute` — Execute tool-based action
- `GET /agents/{id}/metrics` — Get usage metrics & token count

**Request Format:**
```json
{
  "agentId": "agent-gpt4",
  "prompt": "Analyze this customer data and suggest next steps",
  "context": {
    "customerId": "customer-123",
    "data": { "sentiment": "negative", "engagement": "low" }
  },
  "model": "gpt-4",
  "temperature": 0.7,
  "maxTokens": 500
}
```

**Response Format:**
```json
{
  "agentId": "agent-gpt4",
  "response": "Recommend immediate outreach to re-engage customer...",
  "tokensUsed": 150,
  "cached": false,
  "executedTools": ["customer_analysis"]
}
```

**Database:** PostgreSQL (agent_profiles, token_usage_logs), Redis (response cache)
**Dependencies:** Prompt Engineering, Learning Management, Auth, Event Bus

**Supported LLM Providers:**
- OpenAI (GPT-4, GPT-3.5)
- Anthropic (Claude)
- Cohere
- Azure OpenAI

**Important Patterns:**
- **Traffic management:** Load balancing across multiple LLMs
- **Response caching:** Redis-backed for identical prompts
- **Rate limiting:** Per-tenant, per-model limits
- **Feedback loop:** Integrates with Learning Management for improvement
- **Streaming:** Supports real-time response streaming

---

### 7. Prompt Engineering Service (PES)
**Purpose:** Manage reusable, versioned prompt templates with dynamic variable assembly

**Key Endpoints:**
- `POST /prompts` — Create new prompt template
- `GET /prompts/{id}` — Get prompt template
- `GET /prompts/{id}/versions` — List prompt versions
- `POST /prompts/{id}/assemble` — Assemble prompt with runtime variables
- `POST /prompts/{id}/validate` — Validate prompt syntax & variables
- `POST /prompts/{id}/publish` — Publish new version

**Request Format:**
```json
{
  "name": "Customer Analysis",
  "template": "Analyze the following customer data: {{customer_data}}. Provide recommendations for {{interaction_type}}.",
  "variables": [
    { "name": "customer_data", "type": "object", "required": true },
    { "name": "interaction_type", "type": "string", "required": true }
  ],
  "tags": ["analysis", "customer_engagement"]
}
```

**Response Format:**
```json
{
  "promptId": "prompt-666",
  "version": "1.2.0",
  "assembled": "Analyze the following customer data: {...}. Provide recommendations for upsell.",
  "variables": { "customer_data": {...}, "interaction_type": "upsell" }
}
```

**Database:** ArangoDB (prompts, versions)
**Dependencies:** AI Agent, Learning Management, Data Hub

**Important Patterns:**
- **Versioning:** All prompt changes tracked for reproducibility
- **Dynamic assembly:** Runtime variable injection at execution time
- **Contract tests:** Ensure prompt output stability across versions
- **Blocks:** Reusable prompt segments for composition

---

### 8. Learning Management Service (LMS)
**Purpose:** Self-learning engine to improve agent performance via feedback

**Key Endpoints:**
- `POST /feedback` — Submit execution feedback
- `GET /feedback` — Query feedback by agent/prompt
- `POST /datasets` — Create training dataset
- `POST /retraining/jobs` — Schedule retraining job
- `GET /retraining/jobs/{id}` — Get retraining status
- `GET /agents/{id}/metrics/drift` — Get agent performance drift

**Request Format:**
```json
{
  "executionId": "exec-789",
  "agentId": "agent-gpt4",
  "promptId": "prompt-666",
  "feedback": {
    "accuracy": 0.92,
    "userSatisfaction": 4.5,
    "expectedOutput": "...",
    "actualOutput": "...",
    "notes": "Excellent analysis"
  }
}
```

**Database:** PostgreSQL (feedback), S3 (training artifacts)
**Dependencies:** AI Agent, Prompt Engineering, Event Bus

**Important Patterns:**
- **Feedback linking:** Always linked to specific agent & prompt versions
- **Async retraining:** Jobs scheduled asynchronously
- **Drift detection:** Monitors agent accuracy over time
- **Training datasets:** Built from usage logs + feedback

---

### 9. Data Intelligence Service (DIS)
**Purpose:** Analyze external/internal data for schema & mapping intelligence

**Key Endpoints:**
- `POST /analyze/schema` — Discover schema from data source
- `POST /analyze/mappings` — Suggest field mappings
- `GET /discovered-schemas` — List discovered schemas
- `POST /analyze/data-quality` — Score data quality
- `POST /generate/synthetic-data` — Generate test data

**Request Format:**
```json
{
  "sourceType": "rest_api",
  "sampleData": [{...}, {...}],
  "sourceId": "int-222"
}
```

**Response Format:**
```json
{
  "discoveredSchema": {
    "fields": [
      { "name": "id", "type": "string", "confidence": 0.99 },
      { "name": "created_at", "type": "timestamp", "confidence": 0.95 }
    ]
  },
  "suggestedMappings": [
    { "source": "id", "target": "customer_id", "confidence": 0.87 }
  ],
  "dataQuality": 0.89
}
```

**Database:** ArangoDB (discovered_schemas, field_maps, profiles)
**Dependencies:** Integration Hub, Data Hub, AI Agent

**Important Patterns:**
- **API for Process Designer:** Provides suggestions for dynamic node configuration
- **Synthetic data:** Respects tenant boundaries & privacy
- **Schema profiling:** Continuous analysis for data quality

---

### 10. Document Intelligence Service (DocIS)
**Purpose:** Transform documents into structured data, embeddings, and searchable content

**Key Endpoints:**
- `POST /documents/upload` — Upload document
- `POST /documents/{id}/extract` — Extract entities & metadata
- `POST /documents/classify` — Predict document type
- `POST /documents/search` — Semantic search across documents
- `GET /documents/{id}/embeddings` — Get document embeddings

**Request Format:**
```json
{
  "document": "base64-encoded-pdf",
  "documentType": "invoice",
  "extractionConfig": {
    "entities": ["invoice_number", "amount", "vendor"],
    "includeOcr": true
  }
}
```

**Response Format:**
```json
{
  "documentId": "doc-888",
  "type": "invoice",
  "extractedData": {
    "invoiceNumber": "INV-2025-001",
    "amount": 1500.00,
    "vendor": "Supplier Inc."
  },
  "embedding": [0.123, 0.456, ...],
  "confidence": 0.96
}
```

**Database:** S3 (raw files), PostgreSQL (metadata), VectorDB (embeddings)
**Dependencies:** AI Agent, Data Hub, Event Bus

**Important Patterns:**
- **Multi-document type support:** Invoices, contracts, forms, etc.
- **Streaming processing:** Large document handling
- **Semantic search:** Vector embeddings for similarity search
- **OCR integration:** Handles scanned documents

---

## Integration Layer Services (Layer 3)

### 11. Data Connector Service (DCS)
**Purpose:** Database/file ingestion connectors & scheduled data sync

**Key Endpoints:**
- `POST /ingest/jobs` — Create ingestion job
- `GET /ingest/jobs/{id}` — Get job status
- `PUT /ingest/jobs/{id}/start` — Start sync
- `PUT /ingest/jobs/{id}/cancel` — Cancel sync
- `POST /ingest/test-connection` — Validate source connection
- `GET /ingest/jobs/{id}/stats` — Get sync statistics

**Request Format:**
```json
{
  "sourceType": "postgresql",
  "sourceConfig": {
    "host": "db.example.com",
    "database": "sales_db",
    "query": "SELECT * FROM customers WHERE updated_at > ?"
  },
  "destination": "internal-data-hub",
  "schedule": "0 0 * * *",
  "cdcEnabled": true
}
```

**Database:** PostgreSQL (ingest_jobs, sources)
**Dependencies:** Integration Hub, Data Hub

**Supported Connectors:**
- SQL databases (PostgreSQL, MySQL, SQL Server)
- NoSQL (MongoDB, DynamoDB)
- Files (CSV, Parquet, Avro)
- FTP/SFTP
- Cloud storage (S3, GCS, Azure Blob)

**Important Patterns:**
- **Batch & streaming:** Both ingestion modes
- **CDC support:** Change Data Capture for delta sync
- **Data integrity:** Checksums & reconciliation
- **Retry logic:** Exponential backoff with DLQ

---

### 12. Communication Service (Comms)
**Purpose:** Two-way channels for WhatsApp, Telegram, Slack, SMS integration

**Key Endpoints:**
- `POST /channels/register` — Register communication channel
- `POST /channels/{id}/send` — Send message
- `POST /channels/{id}/webhook` — Receive inbound messages
- `GET /conversations/{id}` — Get conversation history
- `PUT /conversations/{id}/context` — Link to process context

**Request Format:**
```json
{
  "channel": "whatsapp",
  "recipientId": "user-123",
  "message": "Your order #12345 is ready for pickup",
  "variables": { "orderId": "12345" }
}
```

**Response Format:**
```json
{
  "messageId": "msg-999",
  "status": "sent",
  "channel": "whatsapp",
  "sentAt": "2025-02-07T10:30:00Z",
  "readAt": null
}
```

**Database:** PostgreSQL (conversations, channel_configs)
**Dependencies:** Notification, Execution Engine, AI Agent

**Supported Channels:**
- WhatsApp
- Telegram
- Slack
- SMS

**Important Patterns:**
- **Message linking:** To process & tenant context
- **Multi-channel routing:** Route based on user preference
- **Compliance:** GDPR & regulatory audit trails
- **Webhook ingestion:** Receive messages from external channels

---

## Platform/Foundation Services (Layer 4)

### 13. Authentication & Authorization Service (AAS)
**Purpose:** Centralized JWT/OAuth auth with RBAC/ABAC authorization

**Key Endpoints:**
- `POST /auth/login` — Authenticate user
- `POST /auth/logout` — Logout & invalidate token
- `POST /auth/refresh` — Refresh JWT token
- `GET /auth/validate` — Validate token
- `GET /permissions` — List user permissions
- `POST /roles` — Create role
- `PUT /roles/{id}/permissions` — Assign permissions

**Request Format:**
```json
{
  "username": "user@company.com",
  "password": "secure-password",
  "tenantId": "tenant-123"
}
```

**Response Format:**
```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "expiresIn": 3600,
  "user": {
    "id": "user-123",
    "email": "user@company.com",
    "roles": ["manager", "approver"],
    "permissions": ["process:view", "task:approve"]
  }
}
```

**Database:** PostgreSQL (users, roles, permissions), Redis (sessions)
**Dependencies:** None (core infrastructure)

**Authorization Models:**
- **RBAC:** Role-based access control
- **ABAC:** Attribute-based access control (fine-grained)
- **Node-level:** Process node permissions

**Important Patterns:**
- **Tenant isolation:** Multi-tenant support
- **Service-level access:** Inter-service JWT validation
- **Token refresh:** Secure refresh without password

---

### 14. API Gateway Service (AGS)
**Purpose:** Single entrypoint with dynamic routing, rate limiting, and request validation

**Key Endpoints:**
- `*` (any method/path) — Dynamic routing to services
- Rate limiting enforced per tenant/endpoint
- Request validation against OpenAPI spec
- Response transformation

**Configuration Format:**
```json
{
  "routes": [
    {
      "path": "/api/processes",
      "target": "process-design-service:3001",
      "rateLimit": "100/min",
      "authRequired": true
    },
    {
      "path": "/api/executions",
      "target": "execution-engine-service:3002",
      "rateLimit": "1000/min",
      "authRequired": true
    }
  ]
}
```

**Database:** Redis (route_configs), PostgreSQL (long-lived configs)
**Dependencies:** Auth, Service Registry

**Important Patterns:**
- **Dynamic routing:** Service registry integration
- **Tenant-aware:** Route based on tenant ID
- **API versioning:** Support multiple versions simultaneously
- **Request transformation:** Header/body manipulation

---

### 15. Event Bus Service (EBS)
**Purpose:** Reliable event streaming backbone with schema validation & replay

**Key Endpoints:**
- `POST /events` — Publish event
- `GET /subscriptions` — List subscriptions
- `POST /subscriptions` — Subscribe to topic
- `DELETE /subscriptions/{id}` — Unsubscribe
- `GET /events/replay` — Replay events from timestamp

**Request Format:**
```json
{
  "topic": "execution.completed",
  "event": {
    "executionId": "exec-789",
    "status": "completed",
    "duration": 3600,
    "processId": "proc-123"
  },
  "timestamp": "2025-02-07T10:30:00Z"
}
```

**Technology:** Apache Kafka
**Database:** Kafka topics, PostgreSQL (subscriptions, DLQ)
**Dependencies:** All async services

**Topics Structure:**
- `process.created` — New process published
- `process.updated` — Process definition changed
- `execution.started` — Execution began
- `execution.completed` — Execution finished
- `execution.failed` — Execution error
- `task.created` — Human task created
- `task.responded` — Human task answered
- `agent.invoked` — AI agent called
- `integration.synced` — External data synced
- `document.extracted` — Document processed

**Important Patterns:**
- **At-least-once delivery:** Guaranteed message delivery
- **Schema validation:** Event structure validation
- **Dead-letter queue:** Failed events routed to DLQ
- **Replay capability:** Recover from service failures
- **Subscription model:** Services subscribe to topics

---

### 16. WebSocket Gateway Service (WGS)
**Purpose:** Real-time communication for UI/portal with presence & streaming

**Key Endpoints:**
- `WS /connect` — Establish WebSocket connection
- `WS /channels/{id}/subscribe` — Join channel
- `WS /channels/{id}/publish` — Broadcast message to channel

**Message Format:**
```json
{
  "type": "task.update",
  "payload": {
    "taskId": "task-111",
    "status": "completed",
    "response": { "decision": "approve" }
  }
}
```

**Database:** Redis (presence, channels)
**Dependencies:** Auth, Execution Engine, Notification

**Streaming Types:**
- **Task updates:** Real-time task status changes
- **Agent streaming:** Live LLM response tokens
- **Process notifications:** Execution milestones
- **Presence tracking:** User online/offline status

**Important Patterns:**
- **Low-latency:** Sub-100ms updates
- **Presence channels:** Track active users
- **Automatic reconnection:** Client-side retry logic
- **Message ordering:** Guaranteed ordered delivery

---

### 17. Service Registry (SR)
**Purpose:** Dynamic service discovery with health checks & metadata

**Key Endpoints:**
- `POST /services/register` — Register service
- `DELETE /services/{id}` — Deregister service
- `GET /services/{name}` — Discover service instances
- `GET /services` — List all services
- `POST /health/{serviceId}` — Health check

**Request Format:**
```json
{
  "serviceName": "process-design-service",
  "instanceId": "pds-1",
  "host": "pds-1.internal",
  "port": 3001,
  "version": "1.2.0",
  "metadata": {
    "region": "us-west",
    "capacity": 100
  }
}
```

**Technology:** Redis / lightweight PostgreSQL
**Dependencies:** All services

**Important Patterns:**
- **Heartbeat registration:** Services send periodic heartbeats
- **Health checks:** Automatic removal of unhealthy instances
- **Metadata:** Custom attributes for routing decisions
- **Load balancing:** Gateway selects instances based on health

---

## Support Layer Services (Layer 5)

### 18. Notification Service (NS)
**Purpose:** Send emails, SMS, push notifications with templating & retry

**Key Endpoints:**
- `POST /notifications/send` — Send notification
- `GET /notifications/{id}` — Get notification status
- `GET /notifications` — Query notification history
- `POST /templates` — Create notification template

**Request Format:**
```json
{
  "templateId": "task-assigned",
  "recipient": {
    "email": "user@company.com",
    "userId": "user-123"
  },
  "variables": {
    "taskTitle": "Approve Budget Request",
    "deadline": "2025-02-08"
  },
  "channels": ["email", "push"]
}
```

**Database:** PostgreSQL (templates, queue, logs)
**Dependencies:** None (used by all services)

**Template Variables:**
- `{{userName}}` — User name
- `{{taskTitle}}` — Task title
- `{{deadline}}` — Task deadline
- `{{actionUrl}}` — Link to action
- `{{customVar}}` — Custom variables

**Important Patterns:**
- **Guaranteed delivery:** Retries with exponential backoff
- **Provider failover:** Fallback if primary fails
- **Throttling:** Rate limit per recipient
- **Audit trail:** All notifications logged for compliance

---

### 19. Portal Management Service (PMS)
**Purpose:** Multi-tenant portal configuration with white-labeling support

**Key Endpoints:**
- `POST /portals` — Create tenant portal
- `GET /portals/{id}` — Get portal config
- `PUT /portals/{id}/branding` — Update theme/branding
- `GET /portals/{id}/feature-flags` — Get feature flags
- `POST /companies` — Create company/tenant
- `PUT /companies/{id}/approvals` — Configure approval chains

**Request Format:**
```json
{
  "tenantId": "tenant-123",
  "name": "Acme Portal",
  "branding": {
    "logo": "https://acme.com/logo.png",
    "primaryColor": "#FF6B35",
    "customDomain": "portal.acme.com"
  },
  "features": {
    "processDesigner": true,
    "documentProcessing": true,
    "aiAgents": true
  }
}
```

**Database:** PostgreSQL (portals, branding, tenants)
**Dependencies:** Auth, Data Hub

**Important Patterns:**
- **Multi-tenant isolation:** Schema-per-tenant
- **Feature flags:** Enable/disable per tenant
- **Sub-companies:** Support multi-level hierarchies
- **Inter-tenant approvals:** Approval chains across entities

---

### 20. Audit & Compliance Service (ACS)
**Purpose:** Immutable audit logs with compliance & retention rules

**Key Endpoints:**
- `POST /audit-logs` — Log event
- `GET /audit-logs` — Query logs with filters
- `POST /reports/compliance` — Generate compliance report
- `DELETE /records` — GDPR deletion request

**Log Entry Format:**
```json
{
  "timestamp": "2025-02-07T10:30:00Z",
  "actor": "user-123",
  "action": "task.responded",
  "resourceType": "task",
  "resourceId": "task-111",
  "changes": {
    "before": { "status": "assigned" },
    "after": { "status": "completed" }
  },
  "tenantId": "tenant-123"
}
```

**Database:** ClickHouse / BigQuery (append-only logs)
**Dependencies:** All services emit events

**Retention Policies:**
- 90 days: Detailed logs
- 2 years: Summary logs
- 7 years: Compliance-critical logs
- GDPR: Deletion after 30 days notice

**Important Patterns:**
- **Immutable:** Append-only storage (no updates/deletes)
- **Audit trail:** Full change tracking
- **Compliance reports:** GDPR, SOC2, HIPAA templates
- **Retention rules:** Automatic cleanup based on policy

---

### 21. Scheduling Service (SS)
**Purpose:** Cron triggers & time-based process automation

**Key Endpoints:**
- `POST /schedules` — Create schedule
- `GET /schedules/{id}` — Get schedule details
- `PUT /schedules/{id}` — Update schedule
- `DELETE /schedules/{id}` — Delete schedule
- `POST /schedules/{id}/execute` — Trigger immediately

**Request Format:**
```json
{
  "processId": "proc-123",
  "cronExpression": "0 9 * * MON-FRI",
  "timezone": "America/New_York",
  "variables": {
    "reportType": "daily",
    "recipients": ["manager@company.com"]
  }
}
```

**Database:** PostgreSQL (schedules)
**Dependencies:** Execution Engine, Event Bus

**Important Patterns:**
- **Timezone-aware:** Support all timezones
- **Recurrence rules:** Cron or RRULE format
- **Missed execution handling:** Catch-up logic for failed triggers
- **High reliability:** Critical business events

---

### 22. Analytics Service (AS)
**Purpose:** Metrics, dashboards, and real-time reporting

**Key Endpoints:**
- `GET /metrics` — Query metrics
- `GET /dashboards/{id}` — Get dashboard data
- `POST /reports` — Generate report
- `GET /kpis` — Get KPI values

**Metrics Available:**
- `process.execution_count` — Total executions
- `process.avg_duration` — Average execution time
- `task.avg_completion_time` — Average task completion
- `agent.response_latency` — LLM response latency
- `integration.sync_success_rate` — Data sync success %
- `tenant.active_users` — Concurrent active users

**Request Format:**
```json
{
  "metric": "process.execution_count",
  "startTime": "2025-02-01T00:00:00Z",
  "endTime": "2025-02-07T23:59:59Z",
  "groupBy": "process_id",
  "aggregation": "sum"
}
```

**Database:** ClickHouse / BigQuery (metrics), TimescaleDB (time-series)
**Dependencies:** Event Bus, Audit Service

**Important Patterns:**
- **Near real-time:** Sub-minute latency
- **Tenant isolation:** Metrics per tenant
- **Aggregation:** Hourly, daily, monthly views
- **Dashboards:** Predefined + custom

---

## Database Connectivity Patterns

All services follow these rules:

### Single Responsibility
- Each service **owns its own database** (no direct reads from other service DBs)
- Cross-service data flows via **Event Bus (async)** or **APIs (sync)**

### Multi-Tenancy
- Schema-per-tenant **OR** tenantId column-based isolation
- All queries filtered by tenantId

### Migrations
- PostgreSQL/SQL: Prisma, Flyway, Liquibase
- NoSQL: arango-migrate
- **CI/CD integration:** Auto-migration on deploy

### Service Structure Requirements
Every service includes:
```
src/
├── api/            # HTTP controllers
├── core/           # Business logic / use-cases
├── domain/         # Entity models & interfaces
├── infra/
│   ├── db/         # Database repository
│   ├── messaging/  # Event Bus integration
│   ├── cache/      # Redis adapter
│   └── http/       # External service clients
├── config/         # Environment & DI
├── security/       # Auth/RBAC
├── errors/         # Error types
└── utils/          # Helpers
```

---

## Authentication Pattern

**All API calls must include:**

```
Authorization: Bearer {accessToken}
X-Tenant-Id: {tenantId}
X-Service-Name: {serviceName} (for service-to-service)
```

**Token Structure (JWT):**
```json
{
  "sub": "user-123",
  "tenantId": "tenant-123",
  "roles": ["manager", "approver"],
  "permissions": ["process:view", "task:approve"],
  "iat": 1234567890,
  "exp": 1234571490
}
```

---

## When to Use This Skill

Use this FlowMaster Backend skill when:

1. **Building MCP server interactions** with FlowMaster APIs
2. **Designing process workflows** — understanding Process Design Service
3. **Handling process execution logic** — integrating with Execution Engine
4. **Managing human tasks** — implementing approval flows
5. **External integrations** — connecting external systems via Integration Hub
6. **Data operations** — storing/querying process variables in Data Hub
7. **AI/LLM integration** — invoking AI Agent Service
8. **Real-time updates** — WebSocket Gateway integration
9. **Authentication** — JWT token validation patterns
10. **Event-driven architecture** — Publishing/subscribing to Event Bus topics
11. **Analytics queries** — Building dashboards from Analytics Service
12. **Audit requirements** — Accessing compliance logs from Audit Service

---

## Key Integration Checklist for MCP Server

- [ ] Implement Auth Service JWT validation
- [ ] Connect to Event Bus for process events
- [ ] Create repository layer for API calls to core services
- [ ] Implement retry/circuit-breaker patterns
- [ ] Add tenant-aware request filtering
- [ ] Support async patterns (Event Bus subscriptions)
- [ ] Implement proper error handling with standardized error codes
- [ ] Add request/response logging for audit trails
- [ ] Validate all incoming requests against schemas
- [ ] Implement rate limiting & caching strategies

