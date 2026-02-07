---
name: flowmaster-frontend
description: "FlowMaster frontend components and UI patterns for process automation"
disable-model-invocation: false
---

# FlowMaster Frontend Skill

## Overview
FlowMaster is a process automation platform built with Next.js. The frontend provides a user interface for creating, managing, and monitoring workflow processes. It connects to multiple backend services through WebSocket and REST APIs.

## Component Architecture

### Core UI Components

#### Project Management
- **Project List View**: Displays all projects in the workspace with filtering and search capabilities
- **Project Details Panel**: Shows project metadata, description, and configuration
- **Project Settings**: Allows editing project properties and team access

#### Issue/Task Management
- **Issue Browser**: Main view for listing issues with multiple filtering options
  - Filter by state (priority levels: urgent, high, medium, low, none)
  - Filter by assignee
  - Filter by state/status
  - Pagination with configurable limits (default: 50 items)

#### Issue Operations
- **Create Issue Form**: Modal/panel for creating new issues
  - Title input (required)
  - Description editor (HTML-based)
  - Priority selector
  - State/status selector
  - Multi-select assignee picker
  - Description preview

- **Issue Detail View**: Shows complete issue information
  - All issue metadata
  - Assignees list
  - Priority and state badges
  - Full description rendering

- **Issue Update Panel**: Inline/modal editor for modifying issues
  - Title editing
  - Description modification
  - Priority adjustment
  - Assignee management
  - State transitions

## UI Patterns and Interactions

### Navigation Patterns
- Hierarchical navigation: Workspace → Projects → Issues
- Sidebar project listing with quick access
- Breadcrumb trail for context awareness
- Tab-based navigation for related views

### Data Display
- **List Views**: Paginated tables with sortable columns
- **Filter Bar**: Horizontal filter controls above lists
- **Status Badges**: Color-coded priority and state indicators
- **User Avatars**: Profile pictures for assignees with hover cards

### Forms and Input
- **Form Validation**: Client-side validation with error messaging
- **Rich Text Editor**: For issue descriptions (HTML output)
- **Multi-select Controls**: Tag-style assignee selectors
- **Dropdown Selectors**: For priority, status, and state selection
- **Search Input**: Real-time filtering on lists

### Modal/Dialog Components
- Issue creation modal
- Confirmation dialogs for destructive actions
- Settings/preferences panels
- Error/success notification toasts

### Responsive Layout
- Grid-based layout system
- Sidebar collapsible on mobile
- Responsive tables with horizontal scroll
- Touch-friendly button sizes (48px minimum)

## Integration with Backend

### REST API Endpoints
The frontend consumes these key endpoints:

```
GET  /api/v1/workspaces/{workspace}/projects/
GET  /api/v1/workspaces/{workspace}/projects/{project_id}/
GET  /api/v1/workspaces/{workspace}/projects/{project_id}/issues/
POST /api/v1/workspaces/{workspace}/projects/{project_id}/issues/
GET  /api/v1/workspaces/{workspace}/projects/{project_id}/issues/{issue_id}/
PATCH /api/v1/workspaces/{workspace}/projects/{project_id}/issues/{issue_id}/
DELETE /api/v1/workspaces/{workspace}/projects/{project_id}/issues/{issue_id}/
```

### WebSocket Connections
- **Execution Engine WebSocket**: `ws://localhost:9010/ws/execution`
  - Real-time process execution status
  - Workflow state updates
  - Error notifications

- **General WebSocket**: `ws://localhost:9010/ws`
  - Collaborative updates
  - User presence
  - Real-time notifications

### Service Integration
- **API Gateway**: Primary REST API endpoint (port 9000)
- **Auth Service**: Authentication and session management (port 9001)
- **Human Task Service**: Human-in-the-loop task handling (port 9006)
- **Execution Engine**: Workflow execution status (port 9005)
- **WebSocket Gateway**: Real-time communication hub (port 9010)

## User-Facing Features

### Project Management
- Create, view, and manage projects
- Organize issues within projects
- Configure project settings and team access
- Track project metadata and descriptions

### Issue Lifecycle Management
- **Create**: Add new issues with detailed information
- **Read**: View issue details and metadata
- **Update**: Modify issue properties (title, description, priority, assignees, state)
- **Delete**: Remove issues (indicated by 'delete' or 'remove' in title)
- **Filter**: Find issues by multiple criteria
- **List**: Browse issues with pagination

### Priority System
- **Urgent**: Critical priority requiring immediate attention
- **High**: Important issues for near-term completion
- **Medium**: Standard priority tasks
- **Low**: Optional or deferred tasks
- **None**: Unspecified priority

### Assignment and Collaboration
- Assign multiple users to issues
- View assignee information
- Track who is working on what
- Support for collaborative editing

### State Management
- Multiple state options for workflow progression
- Visual state indicators on issues
- Filter by state to track progress
- Customizable state transitions

## When to Use This Skill

Use this skill when you need to:
- Understand the Plane project management interface structure
- Design or modify project and issue management workflows
- Troubleshoot UI interaction issues
- Plan frontend features related to task management
- Integrate Plane into a larger platform
- Develop custom themes or styling for process views
- Create documentation for end users about using Plane features
- Design API integrations with the Plane interface
- Implement real-time collaboration features
- Build mobile-responsive views for workflow management
