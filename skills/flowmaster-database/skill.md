---
name: flowmaster-database
description: FlowMaster database schema and relationships
disable-model-invocation: false
---

# FlowMaster Database Schema Reference

## Overview

FlowMaster v1.5 uses ArangoDB as its backend database, providing a flexible document-oriented schema for managing complex business processes, AI agents, and workflow execution. The database supports both document collections and edge collections for maintaining rich relationship graphs between entities.

**Database Name:** flowmaster
**Version:** 1.5
**Created:** 2026-02-02T13:18:53Z
**Database Type:** ArangoDB (Document + Graph)

## Core Database Architecture

### Key Characteristics

- **Document-based:** All data stored as JSON documents with flexible schemas
- **Graph-enabled:** Edge collections support complex relationship mapping
- **Multi-tenant:** Supports multiple tenants and organizations
- **Revision-tracked:** All documents maintain revision history for audit trails
- **Distributed:** Single shard configuration with replication support

## Key Tables & Their Purposes

### Process Definition Layer

| Collection | Purpose | Type |
|------------|---------|------|
| `process_def` | Defines workflow processes with metadata, owner, version | Document |
| `node_def` | Defines individual nodes (steps) within processes | Document |
| `data_definition` | Defines data schemas used by processes and nodes | Document |
| `proc_def_defines_node` | Links process definitions to their constituent nodes | Edge |
| `proc_def_node_flow` | Defines the flow/sequencing between nodes (conditional and sequential) | Edge |
| `proc_def_uses_data_def` | Links processes to their data definitions | Edge |
| `node_def_produces_data_def` | Maps data output from nodes | Edge |
| `node_def_uses_data_def` | Maps data input to nodes | Edge |

#### Process Definition Document Structure

```
process_def:
- _id: Unique identifier (e.g., "process_def/309386")
- _key: Numeric key for internal use
- _rev: Revision identifier for audit trails
- name: Human-readable process name
- organization_id: UUID of owning organization
- tenant_id: UUID of owning tenant
- owner: UUID of process owner user
- version: Semantic version string
- createdAt: ISO timestamp of creation
- updatedAt: ISO timestamp of last modification (optional)
- isTopLevel: Boolean flag for top-level processes
- metadata: Optional JSON object for extended attributes
```

#### Node Definition Document Structure

```
node_def:
- _id: Unique identifier (e.g., "node_def/a21b685f")
- _key: Unique key for cross-reference
- _rev: Revision identifier
- node_id: Custom node identifier
- type: Node type (start, end, action, ai_agent, subprocess, etc.)
- title: Human-readable node title
- description: Node purpose description
- action_type: Type of action (employee_task, script, ai_agent, etc.)
- isEntryNode: Boolean indicating if this is a process entry point
- isExitNode: Boolean indicating if this is a process exit point
- config: Node-specific configuration JSON
- data: Node data JSON
- metadata: Source information and confidence metrics
- position: Canvas coordinates {x, y}
- requiredInputs: Array of required input field names
- outputs: Array of output field names
```

### Execution Layer

| Collection | Purpose | Type |
|------------|---------|------|
| `execution_sessions` | Top-level execution sessions for process instances | Document |
| `execution_instances` | Individual execution instances within a session | Document |
| `execution_history` | Historical records of execution events | Document |
| `execution_state` | Current state snapshots of running executions | Document |
| `execution_checkpoints` | Savepoints in execution for recovery | Document |
| `execution_patterns` | Recurring execution patterns for optimization | Document |

#### Execution Sessions Document Structure

```
execution_sessions:
- _id: Unique session identifier
- _key: Numeric key
- _rev: Revision identifier
- active_agent_ids: Array of active agent IDs in this session
- context: Nested context object containing:
  - execution_id: UUID of the execution
  - process_context: Process metadata and state
  - node: Current node information
  - node_variables: Node input/output data
  - process: Process metadata
  - process_nodes: Array of all process nodes
  - data_definitions: Array of data schemas
```

### Node Instance Layer

| Collection | Purpose | Type |
|------------|---------|------|
| `node_inst` | Instantiated nodes during process execution | Document |
| `node_inst_of_node_def` | Links node instances to their definitions | Edge |
| `node_inst_produces_data` | Data produced by node instances | Edge |
| `node_inst_consumes_data` | Data consumed by node instances | Edge |
| `node_variables` | Variable snapshots for specific node executions | Document |
| `node_states` | State information for executing nodes | Document |

### Process Instance Layer

| Collection | Purpose | Type |
|------------|---------|------|
| `proc_inst` | Process instances (workflow executions) | Document |
| `proc_inst_of_proc_def` | Links process instances to definitions | Edge |
| `proc_inst_has_node_inst` | Links process instances to their node instances | Edge |
| `proc_inst_has_node` | Links process instances to node definitions | Edge |

### Human Task Management

| Collection | Purpose | Type |
|------------|---------|------|
| `human_tasks` | Human-assigned tasks requiring manual action | Document |
| `pending_human_tasks` | Queue of pending human tasks | Document |
| `task_comments` | Comments and notes on human tasks | Document |
| `task_has_human_task` | Relationship between system tasks and human tasks | Edge |

#### Human Task Document Structure

```
human_tasks:
- _id: Unique task identifier
- _key: Numeric key
- title: Task title for assignee
- description: Task description
- status: current status (pending, in_progress, completed, cancelled)
- assignee: UUID of assigned user
- process_id: UUID of parent process execution
- execution_id: UUID of execution context
- node_id: UUID of originating node
- form_fields: Array of form field definitions
- context_data: Nested context (execution_variables, form_data)
- result: Completion result JSON
- priority: Task priority (low, medium, high, urgent)
- created_at: ISO creation timestamp
- completed_at: ISO completion timestamp
- timeout_at: ISO timeout deadline
- metadata: Extended metadata (escalation_config, reminder_config, etc.)
```

### AI Agent & Execution

| Collection | Purpose | Type |
|------------|---------|------|
| `agent_profiles` | AI agent configuration and capabilities | Document |
| `agent_instances` | Running instances of AI agents | Document |
| `agent_tasks` | Tasks assigned to AI agents | Document |
| `agent_executes_task` | Edge linking agents to executed tasks | Edge |
| `agent_spawns_agent` | Hierarchical agent spawning relationships | Edge |
| `agent_memories` | Memory/context storage for agents | Document |
| `ai_agent_checkpoints` | Execution checkpoints for AI agents | Document |
| `ai_audit_logs` | Audit trail for AI agent activities | Document |

### Data Instance Layer

| Collection | Purpose | Type |
|------------|---------|------|
| `data_inst` | Instances of data definitions during execution | Document |
| `document_chunks` | Segmented documents for processing | Document |
| `context_items` | Context items referenced in executions | Document |

### Event & Audit Layer

| Collection | Purpose | Type |
|------------|---------|------|
| `event_audit_log` | Comprehensive audit log of all events | Document |
| `ai_audit_logs` | Specific audit log for AI operations | Document |
| `event_schemas` | Event type definitions | Document |
| `event_delivered_to` | Delivery tracking for events | Edge |
| `execution_history` | Historical execution records | Document |
| `error_patterns` | Detected error patterns for analysis | Document |

### Schedule & Trigger Management

| Collection | Purpose | Type |
|------------|---------|------|
| `schedules` | Scheduled process triggers | Document |
| `schedule_triggers_exec` | Triggers linked to executions | Edge |
| `schedule_executions` | Records of scheduled executions | Document |
| `schedule_locks` | Distributed locks for scheduled tasks | Document |

### System State & Observability

| Collection | Purpose | Type |
|------------|---------|------|
| `execution_locks` | Distributed execution locks | Document |
| `circuit_breaker_state` | Circuit breaker state for fault tolerance | Document |
| `rate_limit_state` | Rate limiting state tracking | Document |
| `dead_letter_queue` | Failed messages for reprocessing | Document |
| `compensation_actions` | Actions for undoing failed operations | Document |
| `replays_requests` | Replay request history | Document |

### Configuration & Metadata

| Collection | Purpose | Type |
|------------|---------|------|
| `llm_models` | Available LLM model configurations | Document |
| `llm_providers` | LLM provider definitions | Document |
| `llm_usage_logs` | Usage tracking for LLM calls | Document |
| `mcp_servers` | MCP (Model Context Protocol) server configs | Document |
| `local_mcp_servers` | Local MCP server instances | Document |
| `cloud_mcp_servers` | Cloud-based MCP server instances | Document |
| `templates` | Reusable process templates | Document |
| `tenant_configurations` | Tenant-specific configurations | Document |
| `notification_preferences` | User notification settings | Document |

## Important Relationships

### Process Definition Hierarchy

```
process_def (1) --defines--> (N) node_def
    |
    +--uses--> (N) data_definition

node_def (1) --produces--> (N) data_definition
node_def (1) --consumes--> (N) data_definition
```

### Execution Flow

```
execution_sessions (1) --contains--> (N) execution_instances
    |
    +--runs--> (1) proc_inst

proc_inst (1) --of--> (1) process_def
proc_inst (1) --has--> (N) node_inst
proc_inst (1) --references--> (N) data_inst

node_inst (1) --of--> (1) node_def
node_inst (1) --produces--> (N) data_inst
node_inst (1) --consumes--> (N) data_inst
```

### Node Flow Definition

```
proc_def_node_flow:
- _from: Source node_def ID
- _to: Target node_def ID
- type: "conditional" or "sequence"
- condition: Expression evaluated at runtime (for conditional flows)
- label: Human-readable flow label
```

### AI Agent Execution

```
agent_profiles (1) --spawns--> (N) agent_instances
agent_instances (1) --executes--> (N) agent_tasks
human_tasks (1) --references--> (1) agent_tasks (optional)
```

## Data Types & Constraints

### Common Field Types

| Type | Description | Examples |
|------|-------------|----------|
| UUID | Universally unique identifier | "a0000000-0000-0000-0000-000000000001" |
| ISO Timestamp | ISO 8601 datetime | "2026-02-02T13:18:53Z" |
| Numeric Key | Auto-incrementing integer | 309386, 288354 |
| Revision | ArangoDB revision string | "_l_0mKee---" |
| Status Enum | Predefined status values | "pending", "in_progress", "completed", "cancelled" |
| JSON Object | Flexible nested data | {key: value, ...} |
| Array | Ordered collection | [item1, item2, ...] |

### Common Status Values

**Execution Status:** pending, in_progress, completed, failed, cancelled, paused
**Human Task Status:** pending, in_progress, completed, cancelled, overdue
**Process Status:** draft, active, suspended, completed, archived

### Priority Levels

**Task Priority:** low, medium, high, urgent

### Node Types

**start** - Entry point of process
**end** - Exit point of process
**action** - Manual/human action
**ai_agent** - AI-powered operation
**script** - Automated script execution
**subprocess** - Call to another process
**decision** - Branching logic node
**parallel** - Parallel execution fork

### Action Types

**employee_task** - Task for employee completion
**script** - System script execution
**ai_agent** - AI agent execution
**approval** - Approval workflow
**notification** - Send notification
**webhook** - Call external webhook

## Query Patterns

### Get All Nodes in a Process

```
proc_def_defines_node where _from = "process_def/{id}"
```

### Get Process Flow

```
proc_def_node_flow where metadata.process_id = "{id}"
```

### Get Active Executions for a Process

```
execution_sessions where context.process_context.process.id = "{process_id}"
```

### Get Pending Human Tasks

```
human_tasks where status = "pending"
```

### Get Process with All Relationships

```
process_def (1) -> proc_def_defines_node (N) -> node_def
process_def (1) -> proc_def_uses_data_def (N) -> data_definition
```

## When to Use This Skill

Use this skill when you need to:

1. **Understand process structure** - Query process definitions, nodes, and their relationships
2. **Track execution state** - Monitor running processes, executions, and their current state
3. **Manage human tasks** - Query or understand human task assignments and workflows
4. **Build MCP endpoints** - Create tools that interact with the FlowMaster database
5. **Analyze workflows** - Study process flows, conditional branches, and data transformations
6. **Debug executions** - Understand execution history and state snapshots
7. **Query execution results** - Access results from completed executions
8. **Reference data schemas** - Look up data definitions used by processes
9. **Understand AI agent integration** - See how agents are configured and executed
10. **Track audit trails** - Access comprehensive audit logs and event history

## Development Notes

- All documents use ArangoDB's standard `_id`, `_key`, and `_rev` fields
- Edge collections follow the pattern `_from -> _to` to establish relationships
- Tenant and organization IDs are UUIDs for multi-tenancy support
- Timestamps are in ISO 8601 format with millisecond precision
- Execution context is deeply nested in execution_sessions for complete state capture
- The database uses automatic sharding (1 shard) with potential for horizontal scaling
- Revision tracking enables full audit history and conflict resolution
