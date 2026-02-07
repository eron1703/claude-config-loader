---
name: flowmaster-tools
description: FlowMaster tools and integrations configuration
disable-model-invocation: false
---

# FlowMaster Tools & Integrations

## Overview

FlowMaster exposes a comprehensive MCP tool registry with 50+ tools organized across 4 pillars. Tools manage connections, data ingestion, discovery, and routing operations with support for multiple database backends and LLM providers.

## Available Tools by Pillar

### 1. Admin Pillar (`sdx://admin/*`)

Connection and configuration management tools:

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

### 2. Ingest Pillar (`sdx://ingest/*`)

Data ingestion and annotation tools:

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

### 3. Discovery Pillar (`sdx://discover/*`)

Metadata exploration and relationship mapping:

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

### 4. Data Router Pillar (`sdx://data/*`)

Data querying and retrieval (in development):

- **Data Querying**
  - `query_data` - Execute data queries (NOT YET IMPLEMENTED)
  - `get_sample_data` - Retrieve sample rows (default 20)
  - `validate_data` - Data validation operations

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
POST /rpc (JSON-RPC 2.0)
    ↓
[MCP Server Request Routing]
├── Admin Tools → ArangoDB (connections, secrets, llm_configs)
├── Ingest Tools → User Databases (PostgreSQL, etc.)
│                → ArangoDB (schemas, tables, columns)
├── Discovery Tools → ArangoDB (metadata search)
└── Data Router Tools → User Databases (queries)
                     → OpenAI (embeddings)
                     → OpenRouter (LLM)
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

### Authentication
- Authorization header parsing: `Bearer tenant:<tenant_id>:token:<token_value>`
- Required for all /rpc requests
- Error code: TENANT_ERROR if missing

### Tenant Context
- All queries filtered by tenant_id
- Cross-tenant data access prevented
- Credential isolation per tenant

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
