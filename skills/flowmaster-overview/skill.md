---
name: flowmaster-overview
description: FlowMaster system overview and architecture
disable-model-invocation: false
---

# FlowMaster Microservices Platform Overview

## High-Level System Description

FlowMaster is a comprehensive **microservices-based business process automation platform** that enables organizations to design, deploy, and manage sophisticated workflows with AI integration. The platform combines visual process design, intelligent document processing, automated workflow execution, and real-time monitoring capabilities.

### Core Value Proposition
- **Visual Process Design**: Drag-and-drop BPMN-style process editor using ReactFlow
- **AI-Powered Intelligence**: LLM-powered document parsing and process extraction
- **Automated Execution**: State machine-based workflow orchestration with human-in-the-loop capabilities
- **Real-Time Monitoring**: WebSocket-based live event streaming and dashboards
- **Enterprise Ready**: Multi-tenant support with comprehensive task management and escalations

## Core Concepts and Terminology

### Key Entities

**Process Definition**: A BPMN-style workflow template stored in ArangoDB. Defines the complete flow with nodes (steps) and edges (connections). Has lifecycle states: draft, published, archived.

**Process Execution (Instance)**: A running instance of a process definition. Tracks current state, progress, input/output data, and execution history. Can be paused, resumed, or cancelled.

**Node**: An individual step in a process. Types include:
- **Event nodes** (start/end): Entry and exit points
- **Action nodes**: Automated tasks
- **Human nodes**: Manual tasks requiring human interaction
- **Decision nodes**: Gateways for conditional branching
- **Timer nodes**: Time-based triggers
- **Script nodes**: Custom code execution
- **Subprocess nodes**: Child process calls

**Edge**: A connection between nodes representing sequence flow. Can be conditional or default, with expressions for decision logic.

**Human Task**: A workflow step requiring human intervention. Has lifecycle: pending → claimed → in_progress → completed. Includes escalation support for manager review.

**Schedule**: A time-based trigger using cron expressions (e.g., daily, weekly). Automatically executes processes at specified times with input data.

**Event**: Messages published asynchronously via Event Bus (Kafka). Enable loose coupling between services (e.g., task.created, execution.completed).

**Notification**: In-app messages sent to users about workflow activities. Support preferences per user and notification type.

### Architectural Principles

**Microservices Pattern**: Each capability is an independent service with its own database, allowing independent scaling and deployment.

**Event-Driven Architecture**: Services communicate asynchronously via Event Bus (Kafka) for high-throughput scenarios.

**Real-Time Streaming**: WebSocket connections push execution state changes to frontend for live dashboards.

**State Machine Execution**: Execution Engine uses state machines for deterministic, resumable workflow execution with compensation (saga pattern).

**Multi-Tenancy**: All services support tenant isolation via tenant_id in requests and data.

## Architecture Patterns

### Service Topology

The platform consists of **12 microservices** organized into layers:

**Presentation Layer**
- **Frontend** (React + Vite): User interface at port 5173

**API Layer**
- **API Gateway** (FastAPI): Central routing, auth, rate limiting at port 9000
- **WebSocket Gateway** (Node.js): Real-time events at port 9010

**Business Logic Services**
- **Process Design** (9003): BPMN definitions, nodes, edges
- **Execution Engine** (9005): Workflow orchestration and state management
- **Human Task** (9006): Task management with escalations
- **Scheduling** (9008): Cron-based process triggering
- **Notification** (9011): In-app notifications
- **Document Intelligence** (9002): AI document parsing and process extraction
- **AI Agent Service** (9001): LLM orchestration and tool execution

**Infrastructure Services**
- **Event Bus** (9013): Kafka-based asynchronous messaging
- **ArangoDB** (8529): Graph database for processes/tasks
- **PostgreSQL** (5432+): Relational storage for executions/notifications/schedules
- **Redis** (6379): Caching and pub/sub

### Communication Patterns

**Synchronous (HTTP REST)**
- Frontend ↔ API Gateway ↔ Services
- Service-to-service direct calls (e.g., Execution Engine calls Human Task)
- Request-response pattern with timeouts

**Asynchronous (Event Bus)**
- Services publish domain events to Kafka topics
- Event Bus routes to subscribed services via webhooks
- Example: task.completed event triggers notifications and execution continuations

**Real-Time (Redis Pub/Sub)**
- Services publish to Redis channels
- WebSocket Gateway subscribes and broadcasts to connected clients
- Zero-latency updates for live dashboards

### Data Flow Example: Task Assignment

1. Execution Engine encounters human task node
2. Execution Engine → HTTP POST to Human Task Service `/api/v1/tasks`
3. Human Task Service creates task in ArangoDB
4. Human Task Service publishes `task.created` event to Event Bus
5. Human Task Service publishes to Redis `backend:task:events` channel
6. Event Bus webhook delivers event to Notification Service
7. WebSocket Gateway receives Redis event and broadcasts to frontend
8. Frontend updates task list in real-time

## Key Features and Capabilities

### Visual Process Design
- **Drag-and-drop editor** with node palette
- **BPMN 2.0 compliance** with start/end events, gateways, and subprocesses
- **Node configuration** with custom properties and metadata
- **Template library** for reusable process patterns
- **Import/Export** of processes in BPMN format
- **Process versioning** with archived historical versions

### AI-Powered Document Processing
- **Multi-format support**: PDF, DOCX, TXT, MD, HTML, RTF
- **Intelligent text extraction** with chunking and embeddings
- **LLM-powered process extraction** from procedural documents
- **Subprocess detection** for nested process hierarchies
- **Semantic search** across uploaded documents
- **Confidence scoring** for extracted processes

### Automated Workflow Execution
- **State machine orchestration** for deterministic execution
- **Parallel and exclusive gateways** for conditional branching
- **Subprocess calls** with data mapping
- **Variable resolution** from context and previous nodes
- **Timeout handling** with retry policies
- **Saga pattern** for compensating actions on failure
- **Execution pause/resume** with state persistence

### Human-in-the-Loop Management
- **Task assignment** to users or roles
- **Task claiming** with concurrent access control
- **Priority levels** (low/medium/high/critical)
- **Due dates** with reminders
- **Manager escalations** for decisions outside automation
- **Task comments** for collaboration
- **Reassignment** capabilities

### Intelligent Scheduling
- **Cron expression support** for flexible scheduling
- **Timezone-aware** scheduling
- **Execution history** tracking
- **Failed execution handling** with retry
- **Process input data** per schedule

### Real-Time Monitoring
- **Live execution canvas** showing node progress
- **WebSocket streaming** of state changes
- **Execution history** with complete event audit trail
- **Node-level debugging** information
- **Performance metrics** (duration, throughput)
- **Error tracking** with stack traces

### Multi-Tenant Support
- **Tenant isolation** at data and API level
- **Per-tenant quotas** and rate limiting
- **Tenant-specific configurations** (LLM models, escalation rules)
- **Data segregation** using tenant_id foreign keys

### Notification System
- **Event-triggered notifications** (task assigned, process completed)
- **User preferences** (enable/disable by type)
- **In-app notification center** with read status
- **Unread count tracking**
- **Notification archival**

## When to Use This Skill

This skill serves as the **primary entry point** for understanding FlowMaster. Reference it when:

1. **Learning the System**: New to FlowMaster and need architecture overview
2. **Planning Integration**: Designing APIs or workflows with FlowMaster
3. **Understanding Capabilities**: Determining what features suit your use case
4. **Troubleshooting Design Issues**: Process design problems or architectural questions
5. **Communicating with Stakeholders**: Need high-level system explanations

### Related Skills
- `flowmaster-api-gateway` - API routing and request handling
- `flowmaster-execution-engine` - Workflow orchestration details
- `flowmaster-human-tasks` - Task management API and lifecycle
- `flowmaster-document-intelligence` - AI document processing
- `flowmaster-event-bus` - Event publishing and subscriptions

### Quick Links
- **Service Ports**: Frontend (5173), API Gateway (9000), WebSocket (9010)
- **Databases**: ArangoDB (8529), PostgreSQL (5432), Redis (6379)
- **Documentation**: FlowMaster Complete Documentation v2.0 (January 2026)
