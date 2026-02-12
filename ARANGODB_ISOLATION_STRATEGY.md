# ArangoDB Database Isolation Strategy

**Date**: 2026-02-12
**Version**: 1.0
**Status**: DESIGN - Pending Implementation
**Related**: Architecture Fix Plan H2

---

## Executive Summary

**Current State**: All 29 FlowMaster services plus SDX infrastructure share a single `flowmaster` ArangoDB database with 45+ document collections and 15+ edge collections. No schema versioning, collection ownership model, or migration coordination exists.

**Risk Level**: HIGH - Schema conflicts, migration failures, and data corruption potential

**Recommended Solution**: Multi-database architecture with collection ownership model, schema versioning, and coordinated migration system.

---

## Problem Statement

### Current Architecture Issues

1. **No Collection Ownership**
   - Unknown which service owns which collection
   - Multiple services may write to same collections
   - No enforcement of access boundaries
   - Difficult to trace data mutations

2. **No Schema Versioning**
   - Breaking changes affect all services simultaneously
   - No migration rollback capability
   - No compatibility testing between versions
   - Deployment coordination nightmare

3. **No Migration Coordination**
   - Services may deploy independently with schema changes
   - Race conditions during concurrent migrations
   - No guarantee of migration order
   - Rollback requires manual intervention

4. **SDX/FlowMaster Coupling**
   - SDX shares database with FlowMaster core
   - SDX schema changes affect FlowMaster stability
   - Cannot version SDX independently
   - Tight coupling prevents modular evolution

---

## Recommended Architecture

### Database Separation Strategy

```yaml
databases:
  flowmaster_core:
    purpose: Core FlowMaster process execution and management
    services: Process, Execution, Human Task, AI Agent, Scheduler
    collections: 40 document + 15 edge collections

  flowmaster_sdx:
    purpose: Semantic Data eXchange infrastructure
    services: SDX services only
    collections: 11 SDX-specific collections
    isolation: Complete separation from core

  flowmaster_shared:
    purpose: Cross-cutting concerns (optional)
    services: Event audit, notifications, configurations
    collections: Minimal shared infrastructure
```

### Collection Ownership Model

Each collection assigned to exactly ONE owning service with defined access patterns:

```yaml
collection_ownership:
  ownership_types:
    - owner: Full read/write access, schema management
    - reader: Read-only access via well-defined queries
    - writer: Write-only via service-owned API
    - prohibited: No direct access (use service API)

  access_enforcement:
    - Database user per service
    - Collection-level permissions
    - Audit logging for all writes
    - API gateway for cross-service access
```

---

## Detailed Design

### 1. Database Architecture

#### Database: `flowmaster_core`

**Purpose**: Core process execution, workflow management, human tasks, AI agents

**Owning Services and Collections**:

```yaml
process_service (Port 9001):
  owns:
    - process_def (document)
    - node_def (document)
    - data_definition (document)
    - proc_def_defines_node (edge)
    - proc_def_node_flow (edge)
    - proc_def_uses_data_def (edge)
    - node_def_produces_data_def (edge)
    - node_def_uses_data_def (edge)
    - templates (document)
  access: Owner (full read/write)
  readers: Execution Service, Analytics Service

execution_service (Port 9002):
  owns:
    - execution_sessions (document)
    - execution_instances (document)
    - execution_history (document)
    - execution_state (document)
    - execution_checkpoints (document)
    - execution_patterns (document)
    - proc_inst (document)
    - node_inst (document)
    - data_inst (document)
    - proc_inst_of_proc_def (edge)
    - proc_inst_has_node_inst (edge)
    - proc_inst_has_node (edge)
    - node_inst_of_node_def (edge)
    - node_inst_produces_data (edge)
    - node_inst_consumes_data (edge)
    - node_variables (document)
    - node_states (document)
    - document_chunks (document)
    - context_items (document)
    - execution_locks (document)
    - dead_letter_queue (document)
    - compensation_actions (document)
    - replays_requests (document)
  access: Owner (full read/write)
  readers: Analytics Service, Human Task Service

human_task_service (Port 9003):
  owns:
    - human_tasks (document)
    - pending_human_tasks (document)
    - task_comments (document)
    - task_has_human_task (edge)
  access: Owner (full read/write)
  readers: Execution Service, Analytics Service
  writers: Execution Service (task creation only)

ai_agent_service (Port 9004):
  owns:
    - agent_profiles (document)
    - agent_instances (document)
    - agent_tasks (document)
    - agent_executes_task (edge)
    - agent_spawns_agent (edge)
    - agent_memories (document)
    - ai_agent_checkpoints (document)
    - ai_audit_logs (document)
  access: Owner (full read/write)
  readers: Execution Service, Analytics Service
  writers: Execution Service (agent task assignment)

scheduler_service (Port 9008):
  owns:
    - schedules (document)
    - schedule_triggers_exec (edge)
    - schedule_executions (document)
    - schedule_locks (document)
  access: Owner (full read/write)
  readers: Analytics Service
  writers: None

event_audit_service (Port 9010):
  owns:
    - event_audit_log (document)
    - event_schemas (document)
    - event_delivered_to (edge)
    - error_patterns (document)
  access: Owner (full read/write)
  readers: Analytics Service, Monitoring Service
  writers: All services (append-only audit events)

configuration_service (Port 9012):
  owns:
    - llm_models (document)
    - llm_providers (document)
    - llm_usage_logs (document)
    - mcp_servers (document)
    - local_mcp_servers (document)
    - cloud_mcp_servers (document)
    - tenant_configurations (document)
    - notification_preferences (document)
    - circuit_breaker_state (document)
    - rate_limit_state (document)
  access: Owner (full read/write)
  readers: All services (configuration lookup)
  writers: Admin Service only
```

#### Database: `flowmaster_sdx`

**Purpose**: Semantic Data eXchange - database metadata, schema discovery, semantic annotations

**Owning Service**: SDX Service (Port 9015)

**Collections**:

```yaml
sdx_service (Port 9015):
  owns:
    - sdx_datasources (document) - External data source definitions
    - sdx_schemas (document) - Database schema metadata
    - sdx_tables (document) - Table definitions
    - sdx_columns (document) - Column definitions with annotations
    - sdx_connections (document) - Database connection credentials (encrypted)
    - sdx_llm_configs (document) - LLM provider configurations
    - sdx_secrets (document) - Encrypted credential storage
    - sdx_annotations (document) - Semantic data annotations
    - sdx_jobs (document) - Async job tracking
    - sdx_webhooks (document) - Webhook subscriptions
    - sdx_audit (document) - SDX-specific audit logs
  access: Owner (full read/write)
  readers: Analytics Service (via API only)
  writers: None (access via SDX Service API only)

isolation_rationale:
  - SDX evolves independently from FlowMaster core
  - SDX schema changes don't affect process execution
  - SDX can be versioned and deployed separately
  - Clear boundary between semantic layer and execution layer
  - Easier to extract SDX as separate product in future
```

#### Database: `flowmaster_shared` (Optional)

**Purpose**: True cross-cutting concerns that must be shared

**Recommendation**: AVOID if possible. Use service APIs instead.

**If Required**:
```yaml
shared_collections:
  # Only if absolutely necessary
  # Prefer service-owned collections with API access
```

---

### 2. Schema Versioning System

#### Version Format

```
<service>_schema_v<major>.<minor>.<patch>

Examples:
- process_schema_v1.0.0
- execution_schema_v1.2.5
- sdx_schema_v2.0.0
```

#### Schema Metadata Collection

```javascript
// Collection: schema_versions (per database)
{
  _key: "process_schema_v1.5.0",
  service: "process_service",
  version: "1.5.0",
  applied_at: "2026-02-12T14:30:00Z",
  applied_by: "deployment_pipeline",
  migration_script: "migrations/process/v1.5.0_add_subprocess_timeout.js",
  rollback_script: "migrations/process/v1.5.0_rollback.js",
  breaking_changes: true,
  backward_compatible_with: ["1.4.x"],
  requires_services: ["process_service >= 1.5.0"],
  status: "applied", // pending | applied | failed | rolled_back
  checksum: "sha256:abc123...",
  metadata: {
    collections_modified: ["process_def", "node_def"],
    indexes_added: ["process_def.organization_tenant_idx"],
    data_migrations: true
  }
}
```

#### Migration Coordination

```yaml
migration_workflow:
  1_pre_deploy:
    - Validate migration script checksum
    - Check current schema version
    - Verify backward compatibility requirements
    - Acquire migration lock (distributed lock in ArangoDB)

  2_execute:
    - Begin transaction (if supported by migration)
    - Apply schema changes
    - Run data migrations
    - Update schema_versions collection
    - Commit transaction

  3_post_deploy:
    - Verify migration success
    - Run validation queries
    - Release migration lock
    - Notify dependent services

  4_rollback_if_needed:
    - Execute rollback script
    - Restore previous schema version
    - Alert operations team
```

---

### 3. Migration Coordination Mechanism

#### Distributed Lock System

```javascript
// Collection: migration_locks (per database)
{
  _key: "flowmaster_core_migration_lock",
  locked_by: "deployment_pipeline_instance_xyz",
  locked_at: "2026-02-12T14:25:00Z",
  expires_at: "2026-02-12T14:35:00Z", // 10-minute timeout
  migration_version: "process_schema_v1.5.0",
  status: "in_progress" // in_progress | completed | failed
}
```

#### Migration Service

New microservice: `migration_coordinator_service` (Port 9020)

**Responsibilities**:
- Acquire/release migration locks
- Coordinate multi-service migrations
- Validate migration dependencies
- Execute migration scripts in correct order
- Handle rollbacks
- Audit migration history

**API**:
```yaml
POST /migrations/plan:
  description: Analyze migration dependencies and create execution plan
  input:
    - service: "process_service"
    - target_version: "1.5.0"
  output:
    - execution_order: ["process_schema_v1.5.0", "execution_schema_v2.1.0"]
    - affected_services: ["process_service", "execution_service"]
    - breaking_changes: true
    - estimated_downtime: "2 minutes"

POST /migrations/execute:
  description: Execute coordinated migration
  input:
    - migration_plan_id: "plan_abc123"
    - force: false
  output:
    - status: "success" | "failed" | "partially_applied"
    - applied_versions: ["process_schema_v1.5.0"]
    - failed_versions: []
    - rollback_required: false

POST /migrations/rollback:
  description: Rollback failed migration
  input:
    - version: "process_schema_v1.5.0"
  output:
    - status: "rolled_back"
    - current_version: "process_schema_v1.4.2"
```

---

### 4. Access Control & Security

#### Database Users per Service

```javascript
// ArangoDB user configuration
{
  "process_service_user": {
    "databases": {
      "flowmaster_core": {
        "collections": {
          "process_def": "rw",
          "node_def": "rw",
          "data_definition": "rw",
          "proc_def_defines_node": "rw",
          "proc_def_node_flow": "rw",
          "execution_sessions": "ro", // Read-only access to execution data
          "human_tasks": "ro"
        }
      }
    }
  },

  "execution_service_user": {
    "databases": {
      "flowmaster_core": {
        "collections": {
          "execution_sessions": "rw",
          "execution_instances": "rw",
          "proc_inst": "rw",
          "process_def": "ro", // Read-only access to process definitions
          "node_def": "ro",
          "human_tasks": "wo" // Write-only for task creation
        }
      }
    }
  },

  "sdx_service_user": {
    "databases": {
      "flowmaster_sdx": {
        "collections": {
          "*": "rw" // Full access to SDX database
        }
      },
      "flowmaster_core": {
        "collections": {} // NO access to core database
      }
    }
  }
}
```

#### Audit Logging

```javascript
// Collection: collection_access_audit (per database)
{
  _key: "audit_abc123",
  timestamp: "2026-02-12T14:30:15.234Z",
  service: "execution_service",
  user: "execution_service_user",
  operation: "write",
  collection: "human_tasks",
  document_key: "task_xyz789",
  access_type: "direct", // direct | api | migration
  allowed: true,
  denied_reason: null
}
```

---

### 5. Collection Access Patterns

#### Direct Database Access (Allowed)

```yaml
owner_service_access:
  pattern: Direct ArangoDB queries
  use_case: Service accessing its own collections
  example: Process Service querying process_def

reader_service_access:
  pattern: Direct read-only queries
  use_case: Analytics reading execution history
  example: Analytics Service querying execution_sessions
```

#### API-Mediated Access (Required)

```yaml
cross_service_writes:
  pattern: Service API calls (no direct DB writes)
  use_case: Execution Service creating human tasks
  example: POST /human-tasks/create (via Human Task Service API)
  enforcement: Database permissions prevent direct writes

cross_service_reads:
  pattern: Service API calls for complex queries
  use_case: Analytics aggregating across multiple services
  example: GET /analytics/process-execution-stats (aggregates via APIs)
```

---

## Implementation Plan

### Phase 1: Design & Documentation (Day 1)

**Tasks**:
1. ✅ Document collection ownership model (this document)
2. ✅ Design schema versioning system
3. ✅ Design migration coordination mechanism
4. Create database user permission matrix
5. Get stakeholder approval

**Deliverables**:
- This strategy document
- Database user permission matrix
- Migration service API specification

### Phase 2: Database Separation (Day 2)

**Tasks**:
1. Create `flowmaster_sdx` database
2. Migrate SDX collections to new database
3. Update SDX service configuration
4. Test SDX isolation
5. Create database users with collection-level permissions

**Validation**:
- SDX service can read/write to `flowmaster_sdx`
- SDX service CANNOT access `flowmaster_core`
- FlowMaster services CANNOT access `flowmaster_sdx`

### Phase 3: Schema Versioning Infrastructure (Day 2-3)

**Tasks**:
1. Create `schema_versions` collection in each database
2. Create `migration_locks` collection in each database
3. Implement migration coordinator service (basic version)
4. Create migration script templates
5. Document migration workflow for developers

**Deliverables**:
- Migration coordinator service (Port 9020)
- Migration script templates
- Developer migration guide

### Phase 4: Backfill Current State (Day 3)

**Tasks**:
1. Document current schema as "v1.0.0" for each service
2. Generate schema version entries for current state
3. Create baseline migration scripts
4. Validate schema documentation accuracy

**Deliverables**:
- Current schema versions documented
- Baseline migrations in version control

### Phase 5: Testing & Validation (Day 3)

**Tasks**:
1. Test schema migration workflow
2. Test rollback procedure
3. Validate access controls
4. Performance test collection-level permissions
5. Security audit of database access

**Validation**:
- Successful migration execution
- Successful rollback
- Access controls enforced
- No performance degradation

---

## Migration Examples

### Example 1: Adding New Collection

```javascript
// Migration: process_schema_v1.6.0_add_process_templates.js
module.exports = {
  version: "1.6.0",
  service: "process_service",
  breaking: false,

  async up(db) {
    // Create new collection
    await db.createCollection("process_templates", {
      schema: {
        rule: {
          type: "object",
          properties: {
            name: { type: "string" },
            category: { type: "string" },
            template_data: { type: "object" }
          },
          required: ["name", "category"]
        }
      }
    });

    // Create indexes
    await db.collection("process_templates").ensureIndex({
      type: "persistent",
      fields: ["category", "name"],
      unique: true
    });
  },

  async down(db) {
    // Rollback: drop collection
    await db.dropCollection("process_templates");
  }
};
```

### Example 2: Breaking Schema Change

```javascript
// Migration: execution_schema_v2.0.0_rename_status_field.js
module.exports = {
  version: "2.0.0",
  service: "execution_service",
  breaking: true, // Breaking change!
  backward_compatible_with: [], // Not backward compatible

  async up(db) {
    const collection = db.collection("execution_sessions");

    // Rename field: execution_status → status
    await db.query(`
      FOR doc IN execution_sessions
        UPDATE doc WITH {
          status: doc.execution_status
        } IN execution_sessions
    `);

    // Remove old field
    await db.query(`
      FOR doc IN execution_sessions
        REPLACE doc WITH UNSET(doc, "execution_status") IN execution_sessions
    `);
  },

  async down(db) {
    const collection = db.collection("execution_sessions");

    // Restore old field name
    await db.query(`
      FOR doc IN execution_sessions
        UPDATE doc WITH {
          execution_status: doc.status
        } IN execution_sessions
    `);

    await db.query(`
      FOR doc IN execution_sessions
        REPLACE doc WITH UNSET(doc, "status") IN execution_sessions
    `);
  }
};
```

---

## Database Decision: SDX Separation

### Question: Does SDX need separate database?

**Answer: YES** - Strong recommendation for separate database

### Rationale

#### Technical Isolation
```yaml
benefits:
  - Independent schema evolution
  - Separate backup/restore cycles
  - Independent performance tuning
  - Isolated resource allocation (RAM, disk)
  - Clear architectural boundary

risks_avoided:
  - SDX schema changes breaking FlowMaster
  - FlowMaster migrations affecting SDX
  - Resource contention between systems
  - Coupled deployment cycles
```

#### Organizational Benefits
```yaml
development:
  - SDX team can iterate independently
  - Clear API contract enforcement
  - Easier to modularize codebase
  - Simpler testing and CI/CD

operations:
  - Independent scaling (SDX vs FlowMaster)
  - Separate monitoring and alerting
  - Easier troubleshooting
  - Independent disaster recovery
```

#### Future-Proofing
```yaml
evolution:
  - SDX can become standalone product
  - Easier to extract as microservice
  - Can sell SDX separately from FlowMaster
  - Multi-tenancy easier to implement
```

### Implementation

```yaml
database_structure:
  flowmaster_core:
    purpose: Process execution and workflow management
    services: 24 FlowMaster services
    size: ~40 document + 15 edge collections

  flowmaster_sdx:
    purpose: Semantic data exchange and metadata
    services: SDX services only (5 services)
    size: 11 SDX-specific collections

  separation_benefits:
    - Zero shared collections
    - Independent schema versions
    - Separate access control
    - Clear ownership boundaries
```

---

## Success Criteria

### Functional Requirements

✅ **Collection Ownership**:
- Every collection has exactly one owner service
- Access patterns documented and enforced
- No ambiguous ownership

✅ **Schema Versioning**:
- All schema changes tracked in `schema_versions`
- Migration scripts in version control
- Rollback capability for all migrations

✅ **Migration Coordination**:
- Distributed lock prevents concurrent migrations
- Migration order enforced by dependencies
- Failed migrations trigger rollback

✅ **Database Separation**:
- SDX database fully isolated from core
- SDX services cannot access core database
- Core services cannot access SDX database

### Non-Functional Requirements

✅ **Performance**:
- No performance degradation from collection permissions
- Migration execution time < 5 minutes per service
- Lock acquisition < 100ms

✅ **Reliability**:
- Migration success rate > 99%
- Rollback success rate > 99%
- Zero data corruption from failed migrations

✅ **Security**:
- Collection-level access control enforced
- Audit logging for all write operations
- Encrypted credentials in `sdx_connections`

---

## Risks & Mitigations

### Risk 1: Migration Failures

**Risk**: Migration script fails mid-execution, leaving database in inconsistent state

**Mitigation**:
- Use ArangoDB transactions where possible
- Test migrations in staging environment
- Require rollback script for all migrations
- Implement automated rollback on failure

### Risk 2: Performance Impact

**Risk**: Collection-level permissions slow down queries

**Mitigation**:
- Benchmark query performance before/after
- Use connection pooling per service
- Cache permission checks where possible
- Monitor query performance metrics

### Risk 3: Service Dependencies

**Risk**: Service A migration requires Service B upgrade, coordination failure

**Mitigation**:
- Document migration dependencies explicitly
- Migration coordinator validates dependencies
- Enforce deployment order via CI/CD
- Rolling deployments with health checks

### Risk 4: Data Migration Complexity

**Risk**: Large-scale data migrations take too long, cause downtime

**Mitigation**:
- Implement online migrations where possible
- Use batch processing for large collections
- Schedule migrations during low-traffic windows
- Provide progress monitoring

---

## Appendix A: Collection Ownership Reference

### Quick Reference Table

| Collection | Owner Service | Port | Readers | Writers |
|------------|---------------|------|---------|---------|
| process_def | Process | 9001 | Execution, Analytics | Process only |
| node_def | Process | 9001 | Execution, Analytics | Process only |
| execution_sessions | Execution | 9002 | Analytics, Process | Execution only |
| human_tasks | Human Task | 9003 | Execution, Analytics | Human Task, Execution (create) |
| agent_profiles | AI Agent | 9004 | Execution, Analytics | AI Agent only |
| schedules | Scheduler | 9008 | Analytics | Scheduler only |
| event_audit_log | Event Audit | 9010 | Analytics, Monitoring | All (append-only) |
| llm_models | Configuration | 9012 | All services | Admin only |
| sdx_datasources | SDX | 9015 | None (API) | SDX only |
| sdx_schemas | SDX | 9015 | None (API) | SDX only |

**Note**: See Section 1 "Database Architecture" for complete ownership details.

---

## Appendix B: Migration Script Template

```javascript
// migrations/<service>/<version>_<description>.js
//
// Example: migrations/process/v1.6.0_add_process_templates.js

module.exports = {
  // Metadata
  version: "1.6.0",
  service: "process_service",
  description: "Add process templates collection",
  breaking: false, // true if backward incompatible
  backward_compatible_with: ["1.5.x"], // Compatible versions
  requires_services: [], // Service version dependencies

  // Migration function
  async up(db) {
    // Implement schema changes here
    // Use db.query(), db.createCollection(), etc.

    console.log("Applying migration: v1.6.0");

    // Example: Create collection
    await db.createCollection("process_templates");

    // Example: Add index
    await db.collection("process_templates").ensureIndex({
      type: "persistent",
      fields: ["category", "name"],
      unique: true
    });

    // Example: Data migration
    await db.query(`
      FOR doc IN old_collection
        INSERT {
          _key: doc._key,
          new_field: doc.old_field
        } INTO new_collection
    `);

    console.log("Migration v1.6.0 applied successfully");
  },

  // Rollback function
  async down(db) {
    // Implement rollback logic here
    // Must reverse all changes from up()

    console.log("Rolling back migration: v1.6.0");

    // Example: Drop collection
    await db.dropCollection("process_templates");

    console.log("Migration v1.6.0 rolled back successfully");
  },

  // Validation function (optional)
  async validate(db) {
    // Verify migration was applied correctly
    const collection = await db.collection("process_templates");
    const count = await collection.count();

    if (count < 0) {
      throw new Error("Migration validation failed: collection not created");
    }

    console.log("Migration v1.6.0 validated successfully");
  }
};
```

---

## Appendix C: Database User Permission Matrix

```javascript
// Full permission matrix for ArangoDB users

const permissions = {
  // Process Service User
  "process_service_user": {
    "flowmaster_core": {
      "process_def": "rw",
      "node_def": "rw",
      "data_definition": "rw",
      "proc_def_defines_node": "rw",
      "proc_def_node_flow": "rw",
      "proc_def_uses_data_def": "rw",
      "node_def_produces_data_def": "rw",
      "node_def_uses_data_def": "rw",
      "templates": "rw",
      "execution_sessions": "ro",
      "human_tasks": "ro",
      "event_audit_log": "wo"
    }
  },

  // Execution Service User
  "execution_service_user": {
    "flowmaster_core": {
      "execution_sessions": "rw",
      "execution_instances": "rw",
      "execution_history": "rw",
      "execution_state": "rw",
      "execution_checkpoints": "rw",
      "execution_patterns": "rw",
      "proc_inst": "rw",
      "node_inst": "rw",
      "data_inst": "rw",
      "node_variables": "rw",
      "node_states": "rw",
      "document_chunks": "rw",
      "context_items": "rw",
      "execution_locks": "rw",
      "dead_letter_queue": "rw",
      "compensation_actions": "rw",
      "replays_requests": "rw",
      "process_def": "ro",
      "node_def": "ro",
      "human_tasks": "wo", // Create tasks only
      "event_audit_log": "wo"
    }
  },

  // Human Task Service User
  "human_task_service_user": {
    "flowmaster_core": {
      "human_tasks": "rw",
      "pending_human_tasks": "rw",
      "task_comments": "rw",
      "task_has_human_task": "rw",
      "execution_sessions": "ro",
      "event_audit_log": "wo"
    }
  },

  // AI Agent Service User
  "ai_agent_service_user": {
    "flowmaster_core": {
      "agent_profiles": "rw",
      "agent_instances": "rw",
      "agent_tasks": "rw",
      "agent_executes_task": "rw",
      "agent_spawns_agent": "rw",
      "agent_memories": "rw",
      "ai_agent_checkpoints": "rw",
      "ai_audit_logs": "rw",
      "execution_sessions": "ro",
      "event_audit_log": "wo"
    }
  },

  // Scheduler Service User
  "scheduler_service_user": {
    "flowmaster_core": {
      "schedules": "rw",
      "schedule_triggers_exec": "rw",
      "schedule_executions": "rw",
      "schedule_locks": "rw",
      "process_def": "ro",
      "event_audit_log": "wo"
    }
  },

  // Event Audit Service User
  "event_audit_service_user": {
    "flowmaster_core": {
      "event_audit_log": "rw",
      "event_schemas": "rw",
      "event_delivered_to": "rw",
      "error_patterns": "rw"
    }
  },

  // Configuration Service User
  "configuration_service_user": {
    "flowmaster_core": {
      "llm_models": "rw",
      "llm_providers": "rw",
      "llm_usage_logs": "rw",
      "mcp_servers": "rw",
      "local_mcp_servers": "rw",
      "cloud_mcp_servers": "rw",
      "tenant_configurations": "rw",
      "notification_preferences": "rw",
      "circuit_breaker_state": "rw",
      "rate_limit_state": "rw"
    }
  },

  // SDX Service User
  "sdx_service_user": {
    "flowmaster_sdx": {
      "sdx_datasources": "rw",
      "sdx_schemas": "rw",
      "sdx_tables": "rw",
      "sdx_columns": "rw",
      "sdx_connections": "rw",
      "sdx_llm_configs": "rw",
      "sdx_secrets": "rw",
      "sdx_annotations": "rw",
      "sdx_jobs": "rw",
      "sdx_webhooks": "rw",
      "sdx_audit": "rw"
    }
    // NO access to flowmaster_core
  },

  // Analytics Service User (read-only across multiple collections)
  "analytics_service_user": {
    "flowmaster_core": {
      "process_def": "ro",
      "node_def": "ro",
      "execution_sessions": "ro",
      "execution_instances": "ro",
      "execution_history": "ro",
      "human_tasks": "ro",
      "agent_instances": "ro",
      "agent_tasks": "ro",
      "schedules": "ro",
      "schedule_executions": "ro",
      "event_audit_log": "ro",
      "llm_usage_logs": "ro"
    }
  },

  // Admin Service User (elevated permissions for maintenance)
  "admin_service_user": {
    "flowmaster_core": {
      "*": "ro", // Read all
      "llm_models": "rw",
      "llm_providers": "rw",
      "tenant_configurations": "rw"
    },
    "flowmaster_sdx": {
      "*": "ro" // Read all (SDX admin via SDX service API)
    }
  }
};

// Permission levels:
// rw = read/write (full access)
// ro = read-only
// wo = write-only (append-only for audit logs)
// none = no access (implicit if not listed)
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-12 | Architecture Team | Initial design document |

---

## Approval Sign-Off

- [ ] Technical Lead: ___________________ Date: ___________
- [ ] Database Administrator: ___________ Date: ___________
- [ ] Security Team: ____________________ Date: ___________
- [ ] Product Owner: ____________________ Date: ___________
