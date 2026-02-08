---
name: flowmaster-tools
description: FlowMaster tools and integrations configuration
disable-model-invocation: false
---

# FlowMaster Tools & Integrations

## Overview

FlowMaster exposes a comprehensive tool registry with 50+ tools organized across 4 pillars, spanning two integrated systems: **SDX** (data management and discovery) and **DXG** (dynamic UI generation and task intelligence). SDX exposes REST endpoints for connections, data ingestion, discovery, and routing operations. External MCP access to these tools is unified through the **FlowMaster MCP Server** (port 9000), which proxies requests to SDX, Execution Engine, Human Task, Knowledge Hub, DXG, and Process Analytics services. Tools manage connections, data ingestion, discovery, routing operations, UI generation, and task analysis with support for multiple database backends and LLM providers.

## Available Tools by Pillar

### 1. Admin Pillar (`flowmaster://admin/*`)

Connection and configuration management tools. SDX REST endpoints (`POST /admin/*`) are accessed externally through FlowMaster MCP Server (port 9000):

- **Connection Management**
  - `create_connection` - Create new database connection
  - `list_connections` - List all configured connections
  - `test_connection` - Validate database connectivity
  - `delete_connection` - Remove existing connection

- **Secret Management**
  - `create_secret` - Store encrypted credentials
  - `list_secrets` - List available secrets
  - `rotate_secret` - Rotate encryption keys
  - `delete_secret` - Remove stored secret

- **LLM Configuration**
  - `create_llm_config` - Configure LLM provider
  - `list_llm_configs` - List all LLM configurations
  - `set_default_llm` - Set primary LLM provider
  - `delete_llm_config` - Remove LLM configuration

### 2. Ingest Pillar (`flowmaster://ingest/*`)

Data ingestion and annotation tools. SDX REST endpoints (`POST /ingest/*`) are accessed externally through FlowMaster MCP Server:

- **Ingestion Operations**
  - `start_ingestion` - Begin async data ingestion job
  - `get_ingestion_status` - Poll ingestion job progress
  - `cancel_ingestion` - Stop running ingestion

- **Annotation Management**
  - `get_annotations` - Retrieve field annotations
  - `validate_annotations` - Validate generated annotations
  - `update_annotations` - Modify annotation values

- **Entity Mapping**
  - `find_entity_matches` - Find matching entities
  - `create_entity_map` - Define entity relationships
  - `map_entity` - Apply mapping to entities

- **Sync & Protection**
  - `configure_sync_pattern` - Set sync schedule
  - `set_write_protection` - Enable/disable write protection

### 3. Discovery Pillar (`flowmaster://discover/*`)

Metadata exploration and relationship mapping. SDX REST endpoints (`GET /discover/*`) are accessed externally through FlowMaster MCP Server:

- **Data Source Discovery**
  - `discover_datasources` - List available data sources
  - `get_datasource_metadata` - Retrieve datasource details
  - `search_datasources` - Search by name/type

- **Table & Column Exploration**
  - `list_tables` - Enumerate tables in datasource
  - `get_table_schema` - Retrieve table structure
  - `list_columns` - Get column metadata
  - `get_column_details` - Detailed column information

- **Relationship Mapping**
  - `discover_relationships` - Detect table relationships
  - `find_foreign_keys` - Identify FK relationships
  - `map_relationships` - Create relationship definitions

### 4. Data Router Pillar (`flowmaster://data/*`)

Data querying and retrieval (in development). SDX REST endpoints (`POST /data/*`) are accessed externally through FlowMaster MCP Server:

- **Data Querying**
  - `query_data` - Execute data queries (NOT YET IMPLEMENTED)
  - `get_sample_data` - Retrieve sample rows (default 20)
  - `validate_data` - Data validation operations

### 5. DXG API Pillar (`flowmaster://dxg/*`)

Dynamic UI generation and task intelligence tools. DXG REST endpoints are accessed externally through FlowMaster MCP Server:

- **Context Analysis**
  - `analyze_task` (`GET /api/v1/analyze/{task_id}`) - Unified context analysis: walks ArangoDB graph, computes prefill deterministically, single LLM call for domain analysis, metrics, flags, field recommendations
  - Returns: domain, summary, keyMetrics, codeResolutions, fieldAnalysis, flags, referenceData, caseHistory, sufficiency

- **UI Generation**
  - `generate_ui` (`POST /api/v1/generate`) - Generate HTML UI from natural language prompt
  - `smart_form` (`GET /api/v1/smart-form/{task_id}`) - Pre-filled form with intelligent defaults from prior steps
  - Returns: html (Tailwind CSS), inputDataStructure, outputDataStructure, metadata

- **Interactive Intelligence**
  - `query_task` (`POST /api/v1/query/{task_id}`) - Q&A about task context with source citations
  - `briefing` (`GET /api/v1/briefing/{task_id}`) - Case summary and sufficiency evaluation

**DXG Prefill Priority:**
1. Prior node data (exact field match)
2. Input data definitions
3. Cross-referenced data
4. Process contextRef
5. Boolean defaults (if all prior steps completed)

**DXG Context Budget:** 6000 characters assembled from task info, field definitions, prior step data, cross-references, case history (priority-ordered)

**LLM:** OpenAI GPT-4, temperature 0.3, structured JSON output

## Supported Database Backends

### Fully Implemented

**PostgreSQL**
- Library: asyncpg
- Features:
  - Schema discovery
  - Table enumeration
  - Column metadata extraction
  - Sample row retrieval (configurable 1-50 rows)
  - Connection testing
- Connection timeout: 1-300 seconds (configurable)
- Connection pool: 1-50 connections (configurable)

### Configured but Not Implemented

- MySQL
- Oracle
- SQL Server
- MongoDB

## LLM Provider Configuration

Tools support multiple LLM backends for annotation generation and field resolution:

### Configured Providers
- **OpenRouter** (Primary - IMPLEMENTED)
- **OpenAI** (IMPLEMENTED)
- **Anthropic** (Configured, not implemented)
- **Azure** (Configured, not implemented)
- **Custom** (Configured, not implemented)

### Configuration Storage
- Collection: `sdx_llm_configs`
- API keys: Encrypted in `sdx_secrets` collection
- Per-tenant: Each tenant can have multiple configs
- Default: One default config per tenant

### Timeout Configuration
- Embedding API calls: 30 seconds
- LLM API calls: 60 seconds (configurable)

## External Integrations

### OpenAI / OpenRouter
- **Purpose**: LLM-powered field resolution and annotations
- **Models**: text-embedding-3-small (1536-dimensional vectors)
- **Authentication**: Bearer token (stored encrypted)
- **Use Cases**:
  - Annotation embedding generation
  - Semantic similarity search
  - Natural language field resolution

### Webhook Delivery
- **Collection**: `sdx_webhooks`
- **Method**: HTTP POST with HMAC-SHA256 signature
- **Timeout**: 10 seconds per attempt
- **Retry**: Configurable (default: 3 retries, exponential backoff)

**Event Types**:
- datasource.ingested
- annotations.created
- annotations.validated
- resolution.completed
- job.completed
- job.failed

## Configuration Patterns

### Connection Creation Workflow
```
1. Create connection (store credentials encrypted)
2. Test connection (validate accessibility)
3. List tables (discover schema)
4. Get column details (extract metadata)
5. Store metadata in ArangoDB
```

### Ingestion Workflow
```
1. Start ingestion (async job created)
2. Schema discovery (connect to external DB)
3. Table enumeration (fetch all tables)
4. Column extraction (fetch column types)
5. Sample data retrieval (optional, default 20 rows)
6. Metadata storage (ArangoDB collections)
7. Annotation generation (LLM processing)
8. Job completion (return datasource_id)
```

### Credential Management
- Encrypted storage in `sdx_secrets` collection
- Master key: `SDX_MASTER_KEY` (environment variable)
- On-demand retrieval and decryption
- Support for multiple secret types:
  - database_credentials
  - api_key
  - llm_api_key
  - connection_password

## Integration Points

### Data Flow Architecture
```
Client/Claude
    ↓
[FlowMaster MCP Server] (Port 9000)
JSON-RPC 2.0 over HTTP
Auth: API key + OAuth 2.0 with tenant isolation
    ↓
    ├── Admin (flowmaster://admin/*) → SDX REST API (/admin/*) → ArangoDB
    │                                                           → Secrets Store
    │
    ├── Ingest (flowmaster://ingest/*) → SDX REST API (/ingest/*) → User Databases
    │                                                               → ArangoDB
    │
    ├── Discovery (flowmaster://discover/*) → SDX REST API (/discover/*) → ArangoDB
    │
    ├── Data Router (flowmaster://data/*) → SDX REST API (/data/*) → User Databases
    │                                                               → OpenAI (embeddings)
    │                                                               → OpenRouter (LLM)
    │
    ├── Execution Engine → Process execution & state management
    │
    ├── Human Task → Task context and assignment
    │
    ├── Knowledge Hub → Knowledge graph queries
    │
    ├── DXG (flowmaster://dxg/*) → DXG REST API (/api/v1/*) → ArangoDB (graph walk)
    │                                                       → OpenAI GPT-4
    │
    └── Process Analytics → Analytics and metrics
```

## FlowMaster MCP Server

The **FlowMaster MCP Server** is the unified gateway for external MCP access to all FlowMaster services.

### Configuration
- **Port**: 9000
- **Protocol**: JSON-RPC 2.0 over HTTP
- **Endpoint**: `POST /rpc`
- **Authentication**: API key + OAuth 2.0
- **Tenant Isolation**: All requests scoped to tenant context

### Unified MCP Gateway Features
- Single entry point for all FlowMaster tools
- Automatic request routing to backend services
- Consistent authentication and authorization
- Tenant isolation and context management
- JSON-RPC 2.0 protocol compliance
- Error handling and request validation

### Backend Service Proxying
The MCP Server proxies to the following services:

1. **SDX** (REST API)
   - Admin tools: `/admin/*` endpoints
   - Ingest tools: `/ingest/*` endpoints
   - Discovery tools: `/discover/*` endpoints
   - Data Router tools: `/data/*` endpoints

2. **DXG** (REST API)
   - Dynamic UI generation: `/api/v1/generate`
   - Task analysis: `/api/v1/analyze/{task_id}`
   - Smart forms: `/api/v1/smart-form/{task_id}`
   - Task queries: `/api/v1/query/{task_id}`
   - Task briefings: `/api/v1/briefing/{task_id}`

3. **Execution Engine**
   - Process execution
   - State management
   - Variable resolution

4. **Human Task Service**
   - Task context retrieval
   - Task assignment

5. **Knowledge Hub**
   - Knowledge graph queries
   - Context retrieval

6. **Process Analytics**
   - Metrics and reporting
   - Process insights

### Request/Response Format
```json
{
  "jsonrpc": "2.0",
  "method": "flowmaster://admin/create_connection",
  "params": {
    "tenant_id": "tenant_123",
    "connection_name": "my_db",
    "db_type": "postgresql",
    "host": "localhost",
    "port": 5432,
    "database": "mydb"
  },
  "id": 1
}
```

### Authentication Headers
```
Authorization: Bearer tenant:<tenant_id>:token:<api_key>
X-OAuth-Token: <oauth_token>  (optional)
```

### Storage Collections
- `sdx_llm_configs` - LLM provider configurations
- `sdx_datasources` - External data source definitions
- `sdx_schemas` - Database schema metadata
- `sdx_tables` - Table definitions
- `sdx_columns` - Column definitions
- `sdx_connections` - Database connection credentials
- `sdx_webhooks` - Webhook subscriptions
- `sdx_jobs` - Async job tracking
- `sdx_annotations` - Data annotations
- `sdx_secrets` - Encrypted credential storage
- `sdx_audit` - Audit logs

## Async Job Processing

### Job Service
- **Collection**: `sdx_jobs`
- **Status**: queued, running, completed, failed, cancelled
- **Polling**: Client polls job_id for progress
- **Types**:
  - ingestion
  - annotation
  - validation
  - resolution
  - sync

## Security & Tenant Isolation

### MCP Server Authentication
- Authorization header parsing: `Bearer tenant:<tenant_id>:token:<token_value>`
- Required for all POST /rpc requests to FlowMaster MCP Server
- OAuth 2.0 token support via X-OAuth-Token header
- Error code: TENANT_ERROR if missing

### Tenant Context
- All queries filtered by tenant_id via MCP Server
- Cross-tenant data access prevented at gateway layer
- Credential isolation per tenant
- Token validation before backend service proxying

## When to Use These Tools

### Use Admin Tools When:
- Setting up new database connections
- Managing API keys and secrets
- Configuring LLM providers
- Testing connectivity

### Use Ingest Tools When:
- Loading data from external sources
- Generating or validating field annotations
- Mapping entities between systems
- Scheduling data synchronization

### Use Discovery Tools When:
- Exploring available data sources
- Understanding table/column structure
- Mapping relationships between tables
- Searching for specific schemas

### Use Data Router Tools When:
- Retrieving sample data for validation
- Executing data queries
- Testing data quality
- Validating field values

### Use DXG API Tools When:
- Analyzing task context and requirements
- Generating dynamic UI forms
- Pre-filling forms with intelligent defaults
- Querying task-specific data and relationships
- Retrieving case summaries and briefings

## Performance Notes

### Timeouts
- Embedding API: 30 seconds
- LLM API: 60 seconds (configurable)
- Webhook delivery: 10 seconds
- PostgreSQL connections: 30 seconds (configurable)

### Connection Pooling
- PostgreSQL: 1-50 pool size (configurable)
- ArangoDB: Client-managed pooling
- HTTP: httpx.AsyncClient with timeout

## Known Limitations

- Data Router tool execution not yet implemented
- MySQL, Oracle, SQL Server, MongoDB not implemented
- Anthropic and Azure LLM providers configured but not implemented
- Custom LLM provider not implemented
- No rate limiting on MCP endpoints
- No request logging/tracing

## Best Practices

1. **Always test connections** before ingestion
2. **Use encrypted secrets** for all credentials
3. **Enable write protection** on production datasources
4. **Configure webhooks** for async job notifications
5. **Set appropriate timeouts** based on data volume
6. **Use sample data retrieval** before full ingestion
7. **Configure LLM defaults** for annotation generation
8. **Leverage DXG context budget** by prioritizing recent and high-confidence data
9. **Use analyze_task** as the first step when working with process tasks
10. **Validate field recommendations** from analyze_task before generating UI
