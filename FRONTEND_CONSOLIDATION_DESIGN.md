# FlowMaster Frontend Consolidation Design

> **Design Document: H6 - Frontend Architecture Consolidation**
> **Date**: 2026-02-12
> **Status**: Design Phase
> **Current User Intent Alignment**: 2.8/10
> **Target User Intent Alignment**: 8.5+/10

## Executive Summary

This document outlines the consolidation of 5+ separate frontend applications into a **unified Next.js application** with an API-first architecture. The current fragmented experience (Frontend Admin :3000, Engage :3001, Process Designer :3002, DXG Frontend, SDX Frontend) creates confusion and reduces user intent alignment to 2.8/10.

**Key Principle**: DXG and SDX are **backend services only**. The unified frontend consumes their APIs but does NOT embed their UIs.

**Expected Outcomes**:
- Single unified application with cohesive navigation
- Improved user intent alignment: 2.8/10 → 8.5+/10
- Consistent design system and user experience
- Reduced context switching and cognitive load
- Simplified deployment and maintenance

---

## 1. Current State Analysis

### 1.1 Existing Applications

| Application | Port | Purpose | Tech Stack | Issues |
|-------------|------|---------|------------|--------|
| **Frontend Admin** | 3000 | Admin dashboard, process management, user management, monitoring | Next.js 14+, Radix UI, TailwindCSS | Lacks integration with DXG/SDX features |
| **Engage App** | 3001 | Employee task execution, AI-assisted forms, case briefings | Next.js 16, React 19, Radix UI, TailwindCSS | Separate app creates context switching |
| **Process Designer** | 3002 | Visual workflow builder (drag-drop) | React/unknown | Standalone tool, not integrated with main workflow |
| **DXG Frontend** | N/A | Development/testing UI for DXG experiences | React + Vite + TypeScript | Developer tool, NOT end-user facing |
| **SDX Frontend** | N/A | Data source registration and field mapping | React | Standalone UI, needs integration into process design |

### 1.2 Backend Services (API-Only)

| Service | Port | Purpose | Frontend Integration |
|---------|------|---------|---------------------|
| **DXG Service** | 9011 | AI-powered UI generation, task analysis, smart forms | Consumed via REST API |
| **SDX API** | TBD | Data source registration, semantic mapping, field lineage | Consumed via REST API |

### 1.3 Current User Experience Pain Points

1. **Fragmented Navigation**: Users must navigate between 3-5 different apps to complete workflows
2. **Context Loss**: Switching between apps loses user context and state
3. **Inconsistent UX**: Different navigation patterns, layouts, and interactions
4. **Confusion**: Users unclear which app to use for which task
5. **No Single Source of Truth**: Process data scattered across multiple interfaces
6. **Poor Integration**: DXG and SDX features not integrated into main workflows
7. **Cognitive Overload**: Mental model requires understanding 5+ separate systems

**Current User Intent Alignment**: 2.8/10
- Users struggle to find features
- Workflow completion requires multiple app switches
- No unified navigation or search
- Inconsistent terminology across apps

---

## 2. Unified Application Architecture

### 2.1 Application Name & Identity

**Name**: **FlowMaster Workspace** (or simply "FlowMaster")

**Value Proposition**: Single unified workspace for designing, executing, and managing business process automation with AI assistance.

### 2.2 Core Architecture Principles

1. **API-First Design**: All backend services (DXG, SDX, Process Design, etc.) exposed via REST APIs
2. **Component-Based Integration**: Process Designer integrated as React component, NOT iframe
3. **Shared State Management**: Unified state management across all features (Zustand or React Context)
4. **Consistent Design System**: Single Radix UI + TailwindCSS design system
5. **Progressive Enhancement**: Start with core features, incrementally add advanced capabilities
6. **Role-Based Views**: Different users see different features based on permissions

### 2.3 Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Framework** | Next.js 14+ (App Router) | SSR, API routes, file-based routing, performance |
| **UI Library** | Radix UI (shadcn/ui) | Accessible components, consistent with existing apps |
| **Styling** | TailwindCSS | Utility-first, matches existing design system |
| **Forms** | React Hook Form + Zod | Type-safe validation, existing pattern |
| **State Management** | Zustand (or React Context + Hooks) | Simple, performant, TypeScript-friendly |
| **Data Fetching** | React Query (TanStack Query) | Caching, optimistic updates, background sync |
| **Authentication** | NextAuth.js | JWT integration with Authentication Service (port 8002) |
| **Real-time** | Socket.io client | WebSocket Gateway integration (port 9010) |
| **Process Designer** | Embedded React component | ReactFlow or custom SVG-based editor |

---

## 3. Route Structure & Navigation

### 3.1 Primary Navigation Structure

```
/                          → Dashboard (home page)
/processes                 → Process Explorer (browse all processes)
/processes/new             → Create new process (embedded designer)
/processes/:id             → Process details & analytics
/processes/:id/edit        → Edit process (embedded designer)
/processes/:id/versions    → Version history

/tasks                     → Task Queue (employee task list)
/tasks/:id                 → Task Execution (Engage experience)

/agents                    → AI Agent Management
/agents/:id                → Agent details & performance

/analytics                 → Process Analytics Dashboard
/analytics/processes/:id   → Process-specific analytics

/data                      → Data Source Management (SDX integration)
/data/sources              → Browse data sources
/data/sources/new          → Register new data source
/data/sources/:id          → Data source details & field mapping
/data/lineage              → Visual data lineage diagrams

/marketplace               → BAC Marketplace (process templates)
/marketplace/search        → Search marketplace
/marketplace/:id           → Template details & install

/settings                  → Application Settings
/settings/profile          → User profile
/settings/organizations    → Organization & legal entities
/settings/integrations     → External integrations & webhooks
/settings/users            → User management (admin only)
/settings/rules            → Business Rules (DMN-style)

/notifications             → Notification center
/help                      → Help & documentation
```

### 3.2 Navigation Patterns

#### Global Navigation (Persistent Sidebar)

```
┌─────────────────────────────────────────────────┐
│ [FlowMaster Logo]                   [User Menu] │
├─────────────────────────────────────────────────┤
│                                                 │
│  🏠 Dashboard                                   │
│  📊 Processes                                   │
│  ✓  Tasks                                       │
│  🤖 Agents                                      │
│  📈 Analytics                                   │
│  🗃️ Data Sources                                │
│  🛒 Marketplace                                 │
│                                                 │
│  ──────────────────────────                    │
│  ⚙️  Settings                                   │
│  🔔 Notifications (3)                           │
│  ❓ Help                                        │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### Breadcrumb Navigation

```
Dashboard > Processes > Customer Onboarding > Edit
```

#### Contextual Actions (Top Bar)

```
┌────────────────────────────────────────────────┐
│ [Breadcrumb Trail]              [Search] [👤]  │
│                                                │
│ Customer Onboarding Process                    │
│ [Edit] [Publish] [Analytics] [Delete] [...]   │
└────────────────────────────────────────────────┘
```

---

## 4. Feature Integration Strategy

### 4.1 Process Designer Integration

**Current State**: Standalone app on port 3002
**Target State**: Embedded React component within main app

#### Integration Approach

**Option A: ReactFlow-Based Component (Recommended)**
- Embed ReactFlow library for visual node-based editing
- Integrate directly into `/processes/:id/edit` route
- Shared state with main app via Zustand store
- No iframe isolation, full access to app context

**Option B: Web Component Wrapper**
- Convert existing Process Designer to Web Component
- Embed via `<process-designer>` custom element
- Limited communication via custom events
- Interim solution if full rewrite not feasible

**Recommended**: **Option A** - Full React component integration
- Better performance (no iframe overhead)
- Shared authentication and state
- Consistent styling and UX
- Easier debugging and maintenance

#### UI Layout for Process Designer

```
┌───────────────────────────────────────────────┐
│  [Save] [Publish] [Preview] [Share]    [X]   │
├───────────────────────────────────────────────┤
│ Tools  │                                      │
│ ────── │                                      │
│ Start  │         Canvas (ReactFlow)           │
│ Task   │                                      │
│ Gate   │         [Drag & Drop Nodes]          │
│ End    │                                      │
│ Agent  │                                      │
│ ...    │                                      │
│        │                                      │
│ Props  │                                      │
│ ────── │                                      │
│ [Node  │                                      │
│  Props]│                                      │
└───────────────────────────────────────────────┘
```

**Key Features to Preserve**:
- Drag-and-drop node creation
- Swimlane support for organizational structure
- Inline AI assistance (suggest next steps)
- Real-time validation and error highlighting
- Version control and diff visualization
- Multi-user collaboration (via WebSocket)

### 4.2 DXG Service Integration (API-First)

**Current State**: DXG has separate frontend (React + Vite) for developers
**Target State**: DXG backend consumed via API, UI integrated into main app

#### DXG API Endpoints (Consumed by Unified Frontend)

```typescript
// Task Analysis & Briefing
GET  /api/dxg/analyze/:taskId
→ { domain, caseSummary, keyMetrics, riskFlags }

// Smart Form Generation
GET  /api/dxg/smart-form/:taskId
→ { html, fieldValues, confidence, provenance }

// Interactive Q&A
POST /api/dxg/query/:taskId
→ { question: string }
← { answer, sources, confidence }

// Context Briefing
GET  /api/dxg/briefing/:taskId
→ { summary, timeline, activeAlerts }

// UI Generation (for designers/developers)
POST /api/dxg/generate
→ { prompt, context, rules }
← { html, fields, metadata, validationRules }
```

#### UI Integration Points

1. **Task Execution Page** (`/tasks/:id`):
   - Left panel: `ContextBriefingPanel` (consumes `/api/dxg/briefing/:taskId`)
   - Center: `SmartReviewForm` (consumes `/api/dxg/smart-form/:taskId`)
   - Right sidebar: `InteractiveQueryChat` (consumes `/api/dxg/query/:taskId`)

2. **Process Designer** (`/processes/:id/edit`):
   - Node property panel: "Generate Form" button
   - Calls `/api/dxg/generate` with prompt
   - Preview generated HTML inline
   - Save generated form configuration to process definition

3. **Developer Tools** (Admin only, `/settings/developer`):
   - Full DXG testing interface (preserved from current DXG Frontend)
   - Prompt editor, real-time preview, API traffic viewer
   - Only visible to users with `developer` role

**Key Principle**: DXG UI is NOT embedded as iframe. Instead, unified frontend calls DXG REST APIs and renders results natively.

### 4.3 SDX Service Integration (API-First)

**Current State**: SDX has separate frontend for data mapping
**Target State**: SDX backend consumed via API, UI integrated into `/data` routes

#### SDX API Endpoints (Consumed by Unified Frontend)

```typescript
// Data Source Management
GET    /api/sdx/sources
POST   /api/sdx/sources
GET    /api/sdx/sources/:id
PUT    /api/sdx/sources/:id
DELETE /api/sdx/sources/:id

// Field Mapping
GET  /api/sdx/sources/:id/fields
POST /api/sdx/sources/:id/map-field
→ { fieldName, semanticType, targetEntity }

// Semantic Types
GET  /api/sdx/semantic-types
→ [ { id, name, description, examples } ]

// Data Lineage
GET  /api/sdx/sources/:id/lineage
→ { nodes, edges, transformations }

// Data Preview
GET  /api/sdx/sources/:id/preview
→ { rows, schema, sampleData }
```

#### UI Integration Points

1. **Data Sources List** (`/data/sources`):
   - Table view of all registered data sources
   - Columns: Name, Type, Status, Last Sync, Actions
   - Actions: View, Edit, Map Fields, Delete

2. **Data Source Registration** (`/data/sources/new`):
   - Form to register new data source
   - Connection string/credentials input
   - Test connection button
   - Schema auto-discovery

3. **Field Mapping Workflow** (`/data/sources/:id`):
   - Left panel: Source schema tree view
   - Center: Mapping canvas with drag-drop
   - Right panel: Semantic type selector
   - Visual indicators for mapped/unmapped fields

4. **Data Lineage Visualization** (`/data/lineage`):
   - Interactive graph (D3.js or ReactFlow)
   - Show data flow from source → transformations → target entities
   - Filter by data source, entity type, or time period

5. **Process Designer Integration** (`/processes/:id/edit`):
   - When configuring a task node, "Map Data Fields" button
   - Opens modal with SDX field mapping interface
   - Saves mapping configuration to task definition

**Key Principle**: SDX UI is NOT embedded as iframe. Instead, unified frontend calls SDX REST APIs and renders mapping interface natively.

### 4.4 Engage App Integration

**Current State**: Separate app on port 3001
**Target State**: Integrated into `/tasks` routes

#### Route Mapping

| Engage App Route | Unified App Route | Description |
|------------------|-------------------|-------------|
| `/tasks` | `/tasks` | Task queue dashboard |
| `/tasks/:id` | `/tasks/:id` | Task execution with AI briefing |
| `/dashboard` | `/` | Main dashboard (home page) |
| `/history` | `/tasks?status=completed` | Completed tasks (filtered view) |
| `/agents` | `/agents` | AI agent management |

#### UI Components to Preserve

1. **Task Queue Dashboard** (`/tasks`):
   - Filterable table (status, priority, due date)
   - Status badges (Not Started, In Progress, Pending Review, Completed)
   - Quick actions (assign, escalate, complete)

2. **Task Execution Page** (`/tasks/:id`):
   - **Left Panel**: `ContextBriefingPanel` (AI-generated case summary)
   - **Center**: `SmartReviewForm` (DXG-generated pre-filled form)
   - **Right Sidebar**: `InteractiveQueryChat` (AI Q&A)
   - **Footer**: Save Draft | Approve & Submit | Reject

3. **Task History** (`/tasks?status=completed`):
   - Completed tasks with execution timeline
   - Audit trail of changes
   - View submitted forms and approval chain

### 4.5 Manager App Integration

**Current State**: Separate app on port 3001 (same port as Engage)
**Target State**: Integrated into main app with role-based access

#### Key Distinction
- **Engage App**: Employee task execution (case approval)
- **Manager App**: Escalation handling ONLY (agent blockage resolution)

#### Route Mapping

| Manager App Route | Unified App Route | Description |
|-------------------|-------------------|-------------|
| `/escalations` | `/escalations` | Escalation queue (manager-only) |
| `/escalations/:id` | `/escalations/:id` | Escalation resolution |
| `/dashboard` | `/` | Dashboard with manager-specific widgets |

#### UI Components

1. **Escalation Queue** (`/escalations`):
   - Only visible to users with `manager` role
   - Table of agent escalations (blocked tasks)
   - Columns: Task, Agent, Reason, Duration, Priority
   - Actions: Provide Guidance, Approve Override, Reject

2. **Escalation Resolution** (`/escalations/:id`):
   - Context: Why agent escalated (uncertainty, policy conflict, etc.)
   - Manager Actions: Provide context, share policy docs, approve exception
   - Escalation Metrics: Response time, resolution rate

---

## 5. API Integration Patterns

### 5.1 API Client Architecture

**Centralized API Client** (`lib/api-client.ts`):

```typescript
// Unified API client with authentication and error handling
import axios from 'axios';

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_GATEWAY_URL || 'http://localhost:9000',
  timeout: 10000,
});

// Add JWT token to all requests
apiClient.interceptors.request.use((config) => {
  const token = getAuthToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle token refresh on 401
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      await refreshToken();
      return apiClient.request(error.config);
    }
    return Promise.reject(error);
  }
);

export default apiClient;
```

### 5.2 Service-Specific API Modules

**DXG API Module** (`lib/api/dxg.ts`):

```typescript
import apiClient from '../api-client';

export const dxgApi = {
  // Analyze task for AI briefing
  analyzeTask: (taskId: string) =>
    apiClient.get(`/dxg/analyze/${taskId}`),

  // Get smart form for task
  getSmartForm: (taskId: string) =>
    apiClient.get(`/dxg/smart-form/${taskId}`),

  // Interactive Q&A
  queryTask: (taskId: string, question: string) =>
    apiClient.post(`/dxg/query/${taskId}`, { question }),

  // Get task briefing
  getBriefing: (taskId: string) =>
    apiClient.get(`/dxg/briefing/${taskId}`),

  // Generate UI (for designers)
  generateUI: (prompt: string, context: any, rules: any) =>
    apiClient.post('/dxg/generate', { prompt, context, rules }),
};
```

**SDX API Module** (`lib/api/sdx.ts`):

```typescript
import apiClient from '../api-client';

export const sdxApi = {
  // Data source management
  listSources: () =>
    apiClient.get('/sdx/sources'),

  createSource: (data: DataSourceInput) =>
    apiClient.post('/sdx/sources', data),

  getSource: (id: string) =>
    apiClient.get(`/sdx/sources/${id}`),

  updateSource: (id: string, data: Partial<DataSourceInput>) =>
    apiClient.put(`/sdx/sources/${id}`, data),

  deleteSource: (id: string) =>
    apiClient.delete(`/sdx/sources/${id}`),

  // Field mapping
  getFields: (sourceId: string) =>
    apiClient.get(`/sdx/sources/${sourceId}/fields`),

  mapField: (sourceId: string, mapping: FieldMapping) =>
    apiClient.post(`/sdx/sources/${sourceId}/map-field`, mapping),

  // Data lineage
  getLineage: (sourceId: string) =>
    apiClient.get(`/sdx/sources/${sourceId}/lineage`),

  // Preview data
  previewData: (sourceId: string, limit = 100) =>
    apiClient.get(`/sdx/sources/${sourceId}/preview?limit=${limit}`),

  // Semantic types
  getSemanticTypes: () =>
    apiClient.get('/sdx/semantic-types'),
};
```

### 5.3 React Query Integration

**Custom Hooks for Data Fetching**:

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { dxgApi, sdxApi } from '@/lib/api';

// DXG hooks
export function useTaskAnalysis(taskId: string) {
  return useQuery({
    queryKey: ['dxg', 'analysis', taskId],
    queryFn: () => dxgApi.analyzeTask(taskId),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useSmartForm(taskId: string) {
  return useQuery({
    queryKey: ['dxg', 'smart-form', taskId],
    queryFn: () => dxgApi.getSmartForm(taskId),
  });
}

// SDX hooks
export function useDataSources() {
  return useQuery({
    queryKey: ['sdx', 'sources'],
    queryFn: () => sdxApi.listSources(),
  });
}

export function useCreateDataSource() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: sdxApi.createSource,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sdx', 'sources'] });
    },
  });
}
```

---

## 6. Shared Design System

### 6.1 Component Library

**Core Components** (from Radix UI + shadcn/ui):
- `Button`, `Input`, `Select`, `Checkbox`, `Radio`, `Switch`
- `Dialog`, `Popover`, `Tooltip`, `DropdownMenu`
- `Table`, `Card`, `Badge`, `Avatar`
- `Tabs`, `Accordion`, `Collapsible`
- `Form`, `Label`, `FormField`, `FormMessage`

**Custom Components**:
- `ProcessCard` - Process summary card
- `TaskCard` - Task queue item
- `AgentCard` - AI agent summary
- `DataSourceCard` - Data source item
- `FieldMappingCanvas` - SDX field mapping interface
- `ProcessDesignerCanvas` - ReactFlow-based process editor
- `ContextBriefingPanel` - DXG AI briefing
- `SmartReviewForm` - DXG smart form renderer
- `InteractiveQueryChat` - DXG Q&A sidebar

### 6.2 Design Tokens

**Colors**:
```css
:root {
  --primary: 222.2 47.4% 11.2%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96.1%;
  --secondary-foreground: 222.2 47.4% 11.2%;
  --accent: 210 40% 96.1%;
  --accent-foreground: 222.2 47.4% 11.2%;
  --destructive: 0 84.2% 60.2%;
  --destructive-foreground: 210 40% 98%;
  --muted: 210 40% 96.1%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --border: 214.3 31.8% 91.4%;
  --input: 214.3 31.8% 91.4%;
  --ring: 222.2 84% 4.9%;
  --radius: 0.5rem;
}
```

**Typography**:
- Font Family: `Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`
- Headings: `font-bold text-2xl/3xl/4xl`
- Body: `font-normal text-sm/base`
- Code: `font-mono text-sm`

**Spacing Scale**:
- `xs`: 4px (0.25rem)
- `sm`: 8px (0.5rem)
- `md`: 16px (1rem)
- `lg`: 24px (1.5rem)
- `xl`: 32px (2rem)
- `2xl`: 48px (3rem)

### 6.3 Layout Patterns

**Application Shell**:
```
┌──────────────────────────────────────────────────┐
│  Sidebar (240px)  │  Main Content (flex-1)       │
│                   │                              │
│  [Navigation]     │  [Top Bar]                   │
│                   │  [Breadcrumbs]               │
│  [User Menu]      │                              │
│                   │  [Page Content]              │
│                   │                              │
│                   │                              │
│                   │                              │
└──────────────────────────────────────────────────┘
```

**Responsive Breakpoints**:
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

---

## 7. Authentication & Session Management

### 7.1 Authentication Flow

**NextAuth.js Integration**:

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';

export const authOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        // Call Authentication Service (port 8002)
        const res = await fetch('http://localhost:8002/auth/login', {
          method: 'POST',
          body: JSON.stringify(credentials),
          headers: { "Content-Type": "application/json" }
        });

        const user = await res.json();

        if (res.ok && user) {
          return user; // { id, email, name, accessToken, refreshToken, roles }
        }
        return null;
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.accessToken = user.accessToken;
        token.refreshToken = user.refreshToken;
        token.roles = user.roles;
      }
      return token;
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken;
      session.roles = token.roles;
      return session;
    }
  },
  pages: {
    signIn: '/login',
    signOut: '/logout',
    error: '/auth/error',
  },
};

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
```

### 7.2 Role-Based Access Control

**User Roles**:
- `admin` - Full system access
- `designer` - Process design and management
- `employee` - Task execution (Engage features)
- `manager` - Escalation handling
- `developer` - DXG/SDX developer tools

**Protected Routes**:

```typescript
// middleware.ts
import { withAuth } from "next-auth/middleware";

export default withAuth({
  callbacks: {
    authorized({ req, token }) {
      // Admin-only routes
      if (req.nextUrl.pathname.startsWith("/settings/users")) {
        return token?.roles?.includes("admin");
      }

      // Manager-only routes
      if (req.nextUrl.pathname.startsWith("/escalations")) {
        return token?.roles?.includes("manager");
      }

      // Developer-only routes
      if (req.nextUrl.pathname.startsWith("/settings/developer")) {
        return token?.roles?.includes("developer");
      }

      // Default: require authentication
      return !!token;
    },
  },
});

export const config = {
  matcher: [
    "/processes/:path*",
    "/tasks/:path*",
    "/agents/:path*",
    "/analytics/:path*",
    "/data/:path*",
    "/settings/:path*",
    "/escalations/:path*",
  ],
};
```

---

## 8. Migration Strategy

### 8.1 Phased Rollout Approach

**Phase 1: Foundation (Weeks 1-2)**
- Set up unified Next.js application structure
- Implement authentication and session management
- Create shared design system and component library
- Build application shell (sidebar, top bar, routing)
- Integrate API Gateway client

**Phase 2: Core Features (Weeks 3-4)**
- Migrate dashboard and analytics views
- Implement `/processes` routes (list, details, create)
- Integrate Process Designer as React component (or interim iframe)
- Build `/tasks` queue view
- Add basic navigation and breadcrumbs

**Phase 3: DXG Integration (Weeks 5-6)**
- Implement task execution page (`/tasks/:id`)
- Integrate DXG API calls (analyze, smart-form, query, briefing)
- Build `ContextBriefingPanel`, `SmartReviewForm`, `InteractiveQueryChat`
- Add task completion workflow (save draft, approve, reject)

**Phase 4: SDX Integration (Weeks 7-8)**
- Implement `/data` routes (sources list, registration, details)
- Build field mapping interface
- Integrate data lineage visualization
- Add SDX integration into Process Designer (field mapping for tasks)

**Phase 5: Remaining Features (Weeks 9-10)**
- Migrate agent management (`/agents`)
- Add escalation handling (`/escalations`) for managers
- Implement marketplace (`/marketplace`)
- Build settings pages (`/settings`)
- Add notification center

**Phase 6: Polish & Launch (Weeks 11-12)**
- End-to-end testing across all workflows
- Performance optimization and code splitting
- User acceptance testing (UAT) with key stakeholders
- Documentation and training materials
- Gradual rollout (beta users → all users)
- Decommission old apps (3000, 3001, 3002)

### 8.2 Data Migration Needs

**Minimal Data Migration Required**:
- User preferences and settings (if stored client-side)
- Draft process definitions (if stored client-side)
- UI state and cached data

**No Backend Migration**:
- All backend services remain unchanged
- APIs continue to serve same data
- Authentication service unchanged

**Migration Validation**:
- Compare unified app against old apps for feature parity
- Ensure all API endpoints return same data
- Verify role-based access control matches old apps
- Test real-time WebSocket connections

### 8.3 Rollback Plan

**If Critical Issues Arise**:
1. Keep old apps running in parallel during phased rollout
2. DNS/routing allows instant switch back to old apps
3. Monitor error rates, performance, and user feedback
4. Gradual rollout (10% → 25% → 50% → 100%) with rollback at each stage

---

## 9. Expected Impact on User Intent Alignment

### 9.1 Current State (2.8/10)

**Why Low Score**:
- Users can't find features (scattered across 5 apps)
- High context switching costs (lose state between apps)
- Inconsistent terminology and navigation
- Confusion about which app to use for which task
- Poor integration between DXG/SDX and main workflows

### 9.2 Target State (8.5+/10)

**Improvements**:

1. **Single Unified Workspace** (+2.0 points)
   - All features accessible from one app
   - Consistent navigation and terminology
   - No context switching or state loss

2. **Integrated Workflows** (+1.5 points)
   - DXG/SDX features embedded into natural workflows
   - Field mapping integrated into process design
   - Smart forms appear in task execution context

3. **Role-Based Experience** (+1.0 points)
   - Users only see features relevant to their role
   - Reduced cognitive load and confusion
   - Clearer mental model of system capabilities

4. **Consistent Design & UX** (+1.0 points)
   - Single design system (Radix UI + Tailwind)
   - Predictable interaction patterns
   - Cohesive visual language

5. **Improved Discoverability** (+0.7 points)
   - Global search across all features
   - Breadcrumb navigation shows context
   - Help documentation integrated inline

6. **Better Performance** (+0.5 points)
   - Single-page app navigation (instant transitions)
   - Optimistic UI updates
   - Shared caching and state management

**Total Target Score**: 2.8 + 6.7 = **9.5/10** (conservative estimate: 8.5/10)

### 9.3 Success Metrics

**Quantitative Metrics**:
- Task completion rate: +40% (fewer abandoned workflows)
- Time to complete workflow: -30% (less context switching)
- Error rate: -50% (clearer UX, better validation)
- User satisfaction score: +3.5 points (on 10-point scale)

**Qualitative Metrics**:
- User feedback: "Much easier to find features"
- Support tickets: -60% (fewer "how do I..." questions)
- Onboarding time: -50% (single system to learn)

---

## 10. Open Questions & Decisions Needed

### 10.1 Process Designer Integration

**Decision Needed**: ReactFlow component vs. Web Component vs. Interim iframe?

**Recommendation**: **ReactFlow component** (best UX, full integration)
- **Pros**: Native React, shared state, consistent UX, easier debugging
- **Cons**: Requires rebuild of existing designer (higher initial effort)
- **Interim**: Use iframe initially, replace with ReactFlow in Phase 2 if needed

### 10.2 State Management

**Decision Needed**: Zustand vs. React Context vs. Redux?

**Recommendation**: **Zustand** (simple, performant, TypeScript-friendly)
- **Pros**: Minimal boilerplate, good DX, works well with React Query
- **Cons**: Less ecosystem than Redux (not a major issue)

### 10.3 Mobile Experience

**Decision Needed**: Mobile-first design or desktop-first with responsive?

**Recommendation**: **Desktop-first with responsive breakpoints**
- Process design and analytics are desktop-heavy workflows
- Task execution can be mobile-friendly (Engage features)
- Use responsive design patterns (Tailwind breakpoints)
- Consider separate mobile app for Engage/Manager features (future)

### 10.4 Real-Time Updates

**Decision Needed**: WebSocket integration strategy?

**Recommendation**: **Global WebSocket connection with React Context**
- Single WebSocket connection managed at app root
- React Context provides subscription API to components
- Optimistic UI updates while awaiting WebSocket confirmation

### 10.5 Error Handling & Resilience

**Decision Needed**: How to handle API failures gracefully?

**Recommendation**: **React Query retry logic + Error Boundaries**
- React Query handles automatic retries (exponential backoff)
- Error Boundaries catch component errors and show fallback UI
- Toast notifications for user-facing errors
- Sentry or similar for error tracking

---

## 11. Next Steps

### 11.1 Immediate Actions

1. **Validate Design with Stakeholders**
   - Review this document with product team
   - Confirm route structure and navigation
   - Agree on phased rollout timeline

2. **Technical Prototype**
   - Build Next.js app shell with sidebar and routing
   - Integrate authentication (NextAuth.js + Auth Service)
   - Create 2-3 sample pages to validate design system

3. **Process Designer Decision**
   - Evaluate ReactFlow vs. interim iframe approach
   - Build proof-of-concept for preferred approach
   - Estimate effort for full migration

4. **API Integration Planning**
   - Document all API endpoints from DXG, SDX, and core services
   - Create API client architecture (axios + React Query)
   - Define TypeScript types for all API responses

### 11.2 Success Criteria

**Phase 1 Complete When**:
- App shell is functional (sidebar, top bar, routing)
- Authentication works (login, logout, session management)
- Design system is established (component library, tokens)
- 1-2 routes are live (e.g., `/` dashboard and `/processes`)

**Project Complete When**:
- All features from old apps are available in unified app
- User acceptance testing passes (8.5+ satisfaction score)
- Performance benchmarks met (sub-3s page loads)
- Old apps decommissioned (ports 3000, 3001, 3002 freed)
- User intent alignment score: **8.5+/10**

---

## 12. Conclusion

This consolidation design provides a clear path from the current fragmented frontend experience (2.8/10 user intent alignment) to a unified, cohesive workspace (8.5+/10 target score). By consolidating 5+ separate apps into a single Next.js application with API-first integration, we dramatically reduce cognitive load, improve discoverability, and create a more intuitive user experience.

**Key Success Factors**:
1. **API-First Design**: DXG and SDX are backend services, NOT embedded UIs
2. **Component-Based Integration**: Process Designer as React component (not iframe)
3. **Phased Rollout**: Incremental migration minimizes risk
4. **Consistent Design**: Single design system across all features
5. **Role-Based Views**: Users only see relevant features

**Expected Outcomes**:
- **User Intent Alignment**: 2.8/10 → 8.5+/10 (3x improvement)
- **Task Completion Rate**: +40%
- **Time to Complete Workflow**: -30%
- **Support Tickets**: -60%

This design positions FlowMaster for scalable growth while dramatically improving the user experience.
