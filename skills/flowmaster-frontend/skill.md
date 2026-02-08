---
name: flowmaster-frontend
description: "FlowMaster frontend components and UI patterns for process automation"
disable-model-invocation: false
---

# FlowMaster Frontend Skill

## Overview
FlowMaster frontend comprises three independent applications serving different user roles in a process automation platform:
1. **Frontend Admin** - Admin dashboard for process/service management
2. **Engage App** - Employee-facing task execution interface with AI assistance
3. **DXG Frontend** - Development/testing UI for DXG (Data eXperience Generator)

Plus two supporting tools: SDX Frontend (data mapping) and planned Manager App (escalation handling).

## 1. Frontend Admin (flowmaster-frontend-nextjs)

### Stack & Architecture
- **Framework**: Next.js 14+ (React/TypeScript) with 236 TS/TSX files
- **UI Library**: Radix UI components (shadcn/ui), TailwindCSS for styling
- **Forms**: React Hook Form + Zod validation for type-safe inputs
- **Architecture**: Feature-based organization (process design, execution, task management)

### Core Components
- **Admin Dashboard**: Overview of system health, active processes, user activity
- **Process Management UI**:
  - Process Explorer: Browse and view all defined processes
  - Process Designer: Visual workflow builder with drag-drop support
  - Process configuration and version control
- **User Management**: Create, edit, remove users and manage roles
- **Service Monitoring**: View status and metrics for backend services
- **Authentication Flow Integration**: Handle login, session management, token refresh

### API Connections
- **API Gateway**: REST endpoints at port 9000 for process/service data
- **WebSocket Gateway**: Real-time updates for process execution status and system events

### Known Gaps (per baseline)
- R08: Field mapping confirmation UI (SDX integration)
- R17: Affiliated Organizations management
- D12: Process Designer integration completeness

---

## 2. Engage App (flowmaster-engage)

### Stack & Architecture
- **Framework**: Next.js 16 (React 19/TypeScript) with 242 TS/TSX files
- **Purpose**: Employee-facing app for executing workflow process steps with AI-powered task intelligence
- **Design Pattern**: Progressive disclosure - show only what's needed at each step

### Key Routes & Screens

#### `/tasks` - Task Queue Dashboard
- Displays all assigned tasks in filterable table
- Filters: Status, Priority, Due Date
- Status badges: Not Started, In Progress, Pending Review, Completed
- Quick navigation to individual task detail pages

#### `/tasks/[id]` - Task Detail & Execution
**Left Panel (Task Briefing)**:
- `ContextBriefingPanel`: AI-generated case summary with key facts
- `SmartReviewForm`: DXG-generated pre-filled HTML form for task data input
  - Auto-filled with AI suggestions (shows confidence levels)
  - Employee can modify/override values
  - Field-level provenance (shows where data came from)

**Right Sidebar**:
- `InteractiveQueryChat`: Ask AI questions about task context
  - Example: "What was the customer's previous order?"
  - "When is the deadline for escalation?"

**Footer Actions**:
- Save Draft (persist partial completion)
- Approve & Submit (advance process to next step)
- Reject (return to sender with reason)

#### `/dashboard` - Overview Dashboard
- Cards showing task metrics (open, pending review, completed today)
- Recent activity stream
- Quick stats on process adherence

#### `/history` - Task History
- Completed tasks with execution timeline
- View submitted forms and approval chain
- Audit trail of changes

#### `/agents` - AI Agent Management
- View active AI agents assisting with task execution
- Agent performance metrics
- Configure AI behavior preferences

### DXG Integration (Next.js API Proxy)
Engage proxies requests to DXG backend via `/api/dxg/*` endpoints:

```
GET  /api/dxg/analyze/{taskId}
     → DXG unified analysis: domain context, case summary, key metrics, risk flags

GET  /api/dxg/smart-form/{taskId}
     → DXG form generation: pre-filled HTML form based on task data + LLM

POST /api/dxg/query/{taskId}
     → DXG interactive Q&A: employee asks questions, AI responds with context-aware answers
```

### Task Execution Flow
1. Employee opens `/tasks` → fetch assigned tasks from Human Task Service (REST)
2. Click task card → navigate to `/tasks/{id}`
3. Parallel DXG calls: `analyzeTask()` + `getSmartForm()`
4. Display briefing panel + smart form + enable chat sidebar
5. Employee reviews pre-filled form and modifies as needed
6. Click "Approve & Submit" → `POST /api/tasks/{taskId}/complete`
7. Execution Engine advances process to next step

### Design Patterns
- **Pre-filled Forms**: AI suggests values, employee confirms/overrides
- **Contextual Briefing**: Show relevant case info before form
- **Inline Help**: Chat sidebar for Q&A without leaving task
- **Data Provenance**: Display where each form value came from
- **Draft Saving**: Allow incomplete submissions for later resumption

### Known Gaps (per baseline)
- R25: Full case data loading completeness
- R26: Complete AI Q&A functionality
- R27: Preemptive contextual info (showing task context without asking)
- R28-R29: Design-time analytics (track form accuracy, task completion times)

---

## 3. DXG Frontend (dxg)

### Stack & Architecture
- **Framework**: React + Vite + TypeScript (development/testing UI)
- **Purpose**: NOT end-user facing; used by developers/designers to build and test DXG experiences

### Panels & Layout
- **Left Panel**: Prompt editor, configuration settings, saved designs library
- **Center Panel**: Real-time HTML preview of generated UI
- **Right Panel**: Data structure inspector, LLM API traffic viewer, error logs
- **UIRenderer Component**: Sandboxed HTML preview with style isolation

### Workflow
1. Developer writes natural language prompt: "Create a customer complaint form with escalation path"
2. Click "Generate" → calls DXG backend `/api/v1/generate`
3. Backend returns HTML + metadata
4. Vite preview renders HTML with sandboxing
5. Developer inspects generated form structure, field types, validation rules
6. Refine prompt → iterate until satisfied
7. Export/save design → used by Engage app

### Backend Endpoints (consumed by both DXG Frontend & Engage)
```
POST /api/v1/generate
    Input: { prompt, context, rules }
    Output: { html, fields, metadata, validationRules }

GET  /api/v1/analyze/{task_id}
    Output: { domain, caseSummary, keyMetrics, riskFlags }

GET  /api/v1/smart-form/{task_id}
    Output: { html, fieldValues, confidence, provenance }

POST /api/v1/query/{task_id}
    Input: { question }
    Output: { answer, sources, confidence }

GET  /api/v1/briefing/{task_id}
    Output: { summary, timeline, activeAlerts }
```

---

## 4. SDX Frontend (sdx-frontend)

### Stack & Architecture
- **Framework**: React
- **Purpose**: Data source registration and semantic field mapping UI

### Screens
- Data source explorer
- Field mapping workflow (map source fields to domain entities)
- Semantic type assignment (mark fields as Customer ID, Order Date, etc.)
- Visual data lineage diagrams

### Integration Gap (R08)
- Needs to integrate into Process Designer field mapping workflow
- Currently standalone; should be embedded in process design step

---

## 5. Manager App (PLANNED - R30-R33)

### Stack & Architecture
- **Framework**: React (mobile-optimized; can share codebase with Engage)
- **Purpose**: Manager-only interface for escalation handling ONLY
  - NOT for case approval (that's Engage employees)
  - ONLY for agent blockage resolution and guidance

### Planned Screens
- Escalation queue (tasks escalated by AI agents)
- Blockage resolution (provide context to help agent proceed)
- Guidance provision (share internal policies, precedents)
- Escalation metrics dashboard

---

## Integration Architecture

```
┌─────────────────────────────────────────────────┐
│         Frontend Admin (Next.js)                │
│  - Process Designer, User Management, Monitoring │
└──────────────┬──────────────────────────────────┘
               │ REST
               ▼
        ┌──────────────┐
        │ API Gateway  │ (:9000)
        └──────────────┘
               │
    ┌──────────┼──────────┐
    │          │          │
    ▼          ▼          ▼
[Services] [Auth] [WebSocket]

┌──────────────────────────────────┐
│     Engage App (Next.js 16)      │
│ - Task queue, execution, AI help │
└────────────┬─────────────────────┘
             │ Next.js API Routes
             ▼
        ┌────────────┐
        │ DXG Service│ (:8005)
        │ + Human    │
        │ Task Srv   │
        └────────────┘

┌──────────────────────────────────┐
│  DXG Frontend (React + Vite)     │
│  - UI design, testing, iteration │
└────────────┬─────────────────────┘
             │ REST
             ▼
        ┌────────────┐
        │ DXG Backend│ (:8005)
        │ (FastAPI)  │
        └────────────┘

┌──────────────────────────────────┐
│  SDX Frontend (React)            │
│  - Data mapping, field lineage   │
└────────────┬─────────────────────┘
             │ REST
             ▼
        ┌────────────┐
        │ SDX API    │
        └────────────┘
```

---

## Design System & Patterns

### Form Interaction Patterns
- **Progressive Disclosure**: Show complex fields only when relevant
- **Validation Feedback**: Real-time field validation with clear error messages
- **Auto-fill with Override**: AI suggests, human confirms/changes
- **Field Provenance**: Display source of pre-filled values (e.g., "From customer CRM", "AI prediction 87%")

### Navigation Patterns
- **Breadcrumb Trail**: Show path in process (e.g., Task > Approval > Handoff)
- **Sidebar Menu**: Quick access to main app sections
- **Tab Navigation**: Organize related content (Details, History, Related Tasks)

### Data Display
- **Color-Coded Status**: Pending (yellow), Active (blue), Completed (green), Blocked (red)
- **User Avatars**: Show assignee/reviewer with hover card details
- **Timeline Views**: Show task progression and handoff points
- **Empty States**: Helpful message and CTA when no tasks/data

### Real-time Features
- WebSocket updates for task status changes
- Live notifications for new task assignments
- Collaborative awareness (see who's viewing same task)

---

## When to Use This Skill

Use this skill when you need to:
- Build or modify employee task execution interfaces (Engage App)
- Design AI-assisted form pre-filling experiences (DXG integration)
- Develop admin dashboards for process monitoring and management
- Implement real-time task queue updates via WebSocket
- Create data mapping workflows for semantic field configuration (SDX)
- Debug DXG HTML generation or form pre-fill issues
- Extend task execution with new AI analysis features
- Build manager escalation handling interfaces
- Implement progressive disclosure and contextual UI patterns
- Design mobile-friendly employee task interfaces
