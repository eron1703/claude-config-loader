# FlowMaster Dashboard UI - Work Items

**Project:** FlowMaster Frontend (React + Vite + TypeScript + Tailwind)
**Location:** `/srv/projects/flowmaster/frontend/`
**Port:** 3000
**Created:** 2026-02-12

---

## Work Item 1: Create Main Dashboard Layout Component

**Priority:** High
**Estimate:** Medium
**Dependencies:** None

### Description
Create a reusable main dashboard layout component that provides the foundational structure for all dashboard views, including a responsive grid system and consistent spacing.

### Technical Requirements
- Component path: `src/components/layout/DashboardLayout.tsx`
- Use existing Tailwind configuration with FlowMaster blue (`#0F3460`)
- Follow Corporate UI theming from `CorporateUIContext`
- Responsive design: mobile-first approach
- Support for sidebar, top navigation, and main content area

### Implementation Details
```typescript
interface DashboardLayoutProps {
  children: React.ReactNode;
  showSidebar?: boolean;
  showTopNav?: boolean;
  className?: string;
}
```

### Acceptance Criteria
- [ ] Layout component created and exported
- [ ] Responsive grid system implemented (mobile, tablet, desktop)
- [ ] Integrates with Corporate UI theme
- [ ] Proper TypeScript types defined
- [ ] Component documented with usage examples
- [ ] No console errors or warnings

### Files to Create
- `src/components/layout/DashboardLayout.tsx`
- `src/components/layout/index.ts` (barrel export)

### References
- Existing pattern: `src/features/settings/components/SettingsLayout.tsx`
- Theme: `src/contexts/CorporateUIContext.tsx`
- Colors: `tailwind.config.js`

---

## Work Item 2: Implement Sidebar Navigation Component

**Priority:** High
**Estimate:** Medium
**Dependencies:** Work Item 1

### Description
Build a collapsible sidebar navigation component with icon support, active state indicators, and responsive behavior. Should integrate with existing navigation patterns from App.tsx.

### Technical Requirements
- Component path: `src/components/layout/Sidebar.tsx`
- Use `lucide-react` icons (already in dependencies)
- Support collapsed/expanded states
- Active route highlighting
- Smooth transitions and animations
- Mobile: drawer overlay pattern

### Implementation Details
```typescript
interface SidebarProps {
  isCollapsed?: boolean;
  onToggle?: () => void;
  items: NavigationItem[];
  activeItem?: string;
  onNavigate: (itemId: string) => void;
}

interface NavigationItem {
  id: string;
  label: string;
  icon: React.ReactNode;
  badge?: string | number;
  children?: NavigationItem[];
}
```

### Navigation Items to Include
Based on existing App.tsx structure:
- Home / Dashboard
- Explorer (Process Explorer)
- Monitor (Execution Monitor)
- Audit
- Agents
- Settings

### Acceptance Criteria
- [ ] Sidebar component created with collapsible functionality
- [ ] Icon support using lucide-react
- [ ] Active state highlighting matches current view
- [ ] Smooth expand/collapse animations
- [ ] Mobile-responsive drawer behavior
- [ ] Logo integration (FlowMaster logo)
- [ ] Matches existing ThemedNavItem pattern
- [ ] TypeScript types properly defined

### Files to Create
- `src/components/layout/Sidebar.tsx`
- `src/types/navigation.ts` (navigation types)

### References
- Current nav implementation: `src/App.tsx` (lines 65-100)
- Themed component: `src/components/ThemeAwareComponents.tsx`
- Icon library: `lucide-react`

---

## Work Item 3: Add Top Navigation Bar Component

**Priority:** High
**Estimate:** Medium
**Dependencies:** Work Item 1

### Description
Create a top navigation bar component featuring breadcrumbs, search integration, user profile menu, and system status indicators.

### Technical Requirements
- Component path: `src/components/layout/TopNavBar.tsx`
- Fixed position at top of viewport
- Responsive width management
- Dropdown menu support for user profile
- Integration point for search (Work Item 5)
- Database status indicator (current database display)

### Implementation Details
```typescript
interface TopNavBarProps {
  currentDatabase?: string;
  user?: {
    name: string;
    role: string;
    avatar?: string;
  };
  onDatabaseChange?: () => void;
  onProfileMenuClick?: (action: string) => void;
}
```

### Features to Include
- FlowMaster branding (left side)
- Database status badge (shows current DB from `databaseService`)
- Search bar placeholder (integration point)
- User profile dropdown
- Notifications icon (placeholder)
- Help/documentation link

### Acceptance Criteria
- [ ] Top nav bar component created
- [ ] Fixed positioning works correctly
- [ ] Current database display integration
- [ ] User profile dropdown functional
- [ ] Responsive design (mobile menu)
- [ ] Clean visual hierarchy
- [ ] Proper z-index layering

### Files to Create
- `src/components/layout/TopNavBar.tsx`
- `src/components/layout/ProfileDropdown.tsx`

### References
- Database service: `src/services/databaseService.ts`
- Current database usage: `src/App.tsx` (lines 35-40)

---

## Work Item 4: Create Breadcrumb Component

**Priority:** Medium
**Estimate:** Small
**Dependencies:** Work Item 3

### Description
Build a flexible breadcrumb navigation component that shows the user's current location in the application hierarchy and allows quick navigation to parent levels.

### Technical Requirements
- Component path: `src/components/layout/Breadcrumb.tsx`
- Enhance existing ProcessBreadcrumb pattern for general use
- Support icons and custom separators
- Click navigation for all items except current
- Truncation for long paths
- Accessible markup (aria labels)

### Implementation Details
```typescript
interface BreadcrumbProps {
  items: BreadcrumbItem[];
  onNavigate: (itemId: string) => void;
  separator?: 'chevron' | 'slash' | 'arrow';
  maxItems?: number; // truncate if exceeds
}

interface BreadcrumbItem {
  id: string;
  label: string;
  icon?: React.ReactNode;
  href?: string;
}
```

### Acceptance Criteria
- [ ] Breadcrumb component created
- [ ] Clickable navigation except for last item
- [ ] Visual active state for current item
- [ ] Icon support for items
- [ ] Truncation for long paths (e.g., Home > ... > Current)
- [ ] Responsive design (mobile truncation)
- [ ] Accessibility: proper ARIA labels and keyboard navigation

### Files to Create
- `src/components/layout/Breadcrumb.tsx`

### References
- Existing pattern: `src/features/processExplorer/components/ProcessBreadcrumb.tsx`
- Icons: `lucide-react` (ChevronRight, Home, Slash)

---

## Work Item 5: Implement Global Search Functionality

**Priority:** Medium
**Estimate:** Large
**Dependencies:** Work Item 3

### Description
Create a comprehensive global search component with real-time suggestions, keyboard shortcuts, and multi-entity search (processes, agents, tasks, settings).

### Technical Requirements
- Component path: `src/components/layout/GlobalSearch.tsx`
- Command palette pattern (⌘K / Ctrl+K shortcut)
- Debounced search input (300ms)
- Category-based results (Processes, Agents, Settings, etc.)
- Keyboard navigation (arrow keys, enter)
- Recent searches storage (localStorage)

### Implementation Details
```typescript
interface GlobalSearchProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigate: (result: SearchResult) => void;
}

interface SearchResult {
  id: string;
  type: 'process' | 'agent' | 'setting' | 'task' | 'execution';
  title: string;
  description?: string;
  icon?: React.ReactNode;
  category: string;
}
```

### Search Categories
- Processes (from Process Explorer)
- Agents (from Agent Dashboard)
- Executions (from Execution Monitor)
- Settings sections
- Audit logs
- Help documentation

### Acceptance Criteria
- [ ] Search component created with modal/overlay
- [ ] Keyboard shortcut (⌘K/Ctrl+K) implemented
- [ ] Debounced search input
- [ ] Category-based result grouping
- [ ] Keyboard navigation (up/down arrows, enter)
- [ ] Click navigation to results
- [ ] Recent searches persistence
- [ ] Empty state and loading state
- [ ] Accessible (ARIA labels, focus management)

### Files to Create
- `src/components/layout/GlobalSearch.tsx`
- `src/components/layout/SearchResults.tsx`
- `src/hooks/useSearch.ts`
- `src/services/searchService.ts`

### References
- Search pattern inspiration: Command palette (⌘K pattern)
- Local storage: Browser localStorage API
- Keyboard handling: React event handlers

---

## Work Item 6: Create Dashboard Widget Grid System

**Priority:** Medium
**Estimate:** Medium
**Dependencies:** Work Item 1

### Description
Build a flexible grid system for dashboard widgets that supports drag-and-drop, responsive layouts, and widget customization.

### Technical Requirements
- Component path: `src/components/dashboard/WidgetGrid.tsx`
- CSS Grid-based layout
- Support for different widget sizes (1x1, 2x1, 2x2, etc.)
- Responsive breakpoints (mobile stacks vertically)
- Optional: drag-and-drop reordering (future enhancement)

### Implementation Details
```typescript
interface WidgetGridProps {
  widgets: Widget[];
  layout?: 'default' | 'compact' | 'expanded';
  columns?: number; // default: 12-column grid
}

interface Widget {
  id: string;
  title: string;
  component: React.ComponentType<any>;
  size: { cols: number; rows: number };
  minSize?: { cols: number; rows: number };
}
```

### Grid Features
- 12-column responsive grid
- Auto-placement algorithm
- Gap spacing consistency
- Widget header with title and actions
- Loading and error states per widget

### Acceptance Criteria
- [ ] Widget grid component created
- [ ] Responsive grid system (12-column)
- [ ] Support for different widget sizes
- [ ] Widget header with title and optional actions
- [ ] Loading state per widget
- [ ] Error boundary per widget
- [ ] Clean visual spacing and alignment
- [ ] Mobile: single column stack

### Files to Create
- `src/components/dashboard/WidgetGrid.tsx`
- `src/components/dashboard/WidgetContainer.tsx`
- `src/types/widget.ts`

### References
- CSS Grid documentation
- Existing grid patterns in codebase

---

## Work Item 7: Build Dashboard Stat Cards Component

**Priority:** Medium
**Estimate:** Small
**Dependencies:** Work Item 6

### Description
Create reusable stat card components for displaying key metrics on the dashboard (e.g., active processes, total executions, agent count).

### Technical Requirements
- Component path: `src/components/dashboard/StatCard.tsx`
- Support for trend indicators (up/down arrows)
- Icon support
- Color variants (success, warning, danger, info)
- Loading skeleton state
- Click action support

### Implementation Details
```typescript
interface StatCardProps {
  title: string;
  value: string | number;
  icon?: React.ReactNode;
  trend?: {
    value: number;
    direction: 'up' | 'down';
    label?: string;
  };
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info';
  isLoading?: boolean;
  onClick?: () => void;
}
```

### Visual Design
- Card with subtle shadow and border
- Icon on left, value on right
- Trend indicator below value
- Hover effect if clickable
- Loading skeleton animation

### Acceptance Criteria
- [ ] StatCard component created
- [ ] Icon integration (lucide-react)
- [ ] Trend indicator with up/down arrows
- [ ] Color variants properly styled
- [ ] Loading skeleton state
- [ ] Hover effect for clickable cards
- [ ] Responsive text sizing
- [ ] Accessible markup

### Files to Create
- `src/components/dashboard/StatCard.tsx`
- `src/components/dashboard/StatCardSkeleton.tsx`

### References
- Icons: `lucide-react` (TrendingUp, TrendingDown, Activity, etc.)
- Color scheme: Tailwind config

---

## Work Item 8: Implement Dashboard Activity Feed

**Priority:** Medium
**Estimate:** Medium
**Dependencies:** Work Item 6

### Description
Create an activity feed widget showing recent system events, process executions, and agent activities with real-time updates.

### Technical Requirements
- Component path: `src/components/dashboard/ActivityFeed.tsx`
- Timeline-based layout
- Event type icons and colors
- Timestamp formatting (use `date-fns`)
- Infinite scroll or pagination
- Real-time update support (polling or WebSocket)

### Implementation Details
```typescript
interface ActivityFeedProps {
  limit?: number; // max items to show
  filters?: ActivityFilter[];
  onEventClick?: (event: ActivityEvent) => void;
}

interface ActivityEvent {
  id: string;
  type: 'execution' | 'agent' | 'process' | 'audit' | 'error';
  title: string;
  description?: string;
  timestamp: Date;
  user?: string;
  metadata?: Record<string, any>;
}
```

### Event Types to Display
- Process executions (started, completed, failed)
- Agent activities (created, updated, deployed)
- Audit events (config changes, access)
- System errors and warnings

### Acceptance Criteria
- [ ] Activity feed component created
- [ ] Timeline-based layout
- [ ] Event type icons and color coding
- [ ] Relative time formatting (date-fns)
- [ ] Click handler for event details
- [ ] Loading state (skeleton)
- [ ] Empty state (no recent activity)
- [ ] Scrollable container with max height
- [ ] Responsive design

### Files to Create
- `src/components/dashboard/ActivityFeed.tsx`
- `src/components/dashboard/ActivityEventItem.tsx`
- `src/types/activity.ts`

### References
- Date formatting: `date-fns` library (already in dependencies)
- Icons: `lucide-react`

---

## Work Item 9: Create Dashboard Quick Actions Component

**Priority:** Low
**Estimate:** Small
**Dependencies:** Work Item 6

### Description
Build a quick actions widget providing shortcuts to common tasks like creating processes, running executions, or accessing frequently used settings.

### Technical Requirements
- Component path: `src/components/dashboard/QuickActions.tsx`
- Grid or list layout of action buttons
- Icon + label design
- Keyboard shortcuts display
- Customizable action set
- Permission-aware (show/hide based on user role)

### Implementation Details
```typescript
interface QuickActionsProps {
  actions: QuickAction[];
  layout?: 'grid' | 'list';
  maxVisible?: number;
}

interface QuickAction {
  id: string;
  label: string;
  icon: React.ReactNode;
  onClick: () => void;
  shortcut?: string; // e.g., "⌘N"
  variant?: 'primary' | 'secondary' | 'danger';
  requiresPermission?: string;
}
```

### Common Actions to Include
- Create New Process
- Run Execution
- Create Agent
- View Audit Log
- Database Settings
- System Settings
- Help Documentation

### Acceptance Criteria
- [ ] Quick actions component created
- [ ] Grid and list layout options
- [ ] Icon + label design
- [ ] Keyboard shortcut hints
- [ ] Click handlers working
- [ ] Variant styling (primary, secondary, danger)
- [ ] Responsive grid (mobile: single column)
- [ ] Accessible (keyboard navigation)

### Files to Create
- `src/components/dashboard/QuickActions.tsx`
- `src/components/dashboard/ActionButton.tsx`

### References
- Button component: `src/components/common/Button.tsx`
- Icons: `lucide-react`

---

## Work Item 10: Build Dashboard Main View Integration

**Priority:** High
**Estimate:** Medium
**Dependencies:** Work Items 1-9

### Description
Integrate all dashboard components into a cohesive main dashboard view that serves as the default landing page for FlowMaster, combining widgets, stats, activity feed, and quick actions.

### Technical Requirements
- Component path: `src/features/dashboard/components/DashboardView.tsx`
- Replace or enhance existing Dashboard.tsx
- Use DashboardLayout from Work Item 1
- Compose all dashboard widgets
- State management with Zustand (already in dependencies)
- Data fetching and caching

### Implementation Details
```typescript
interface DashboardViewProps {
  onNavigate: (view: string, id?: string) => void;
}

// Dashboard state management
interface DashboardState {
  stats: DashboardStats;
  activities: ActivityEvent[];
  isLoading: boolean;
  error: Error | null;
  refreshData: () => Promise<void>;
}
```

### Layout Structure
```
┌─────────────────────────────────────────────────────┐
│ Top Navigation Bar (Work Item 3)                    │
├─────┬───────────────────────────────────────────────┤
│     │ Breadcrumb: Home > Dashboard                  │
│  S  ├───────────────────────────────────────────────┤
│  i  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐          │
│  d  │ │Stat 1│ │Stat 2│ │Stat 3│ │Stat 4│          │
│  e  │ └──────┘ └──────┘ └──────┘ └──────┘          │
│  b  ├───────────────────────┬───────────────────────┤
│  a  │                       │                       │
│  r  │   Activity Feed       │   Quick Actions       │
│     │   (Work Item 8)       │   (Work Item 9)       │
│     │                       │                       │
│  (2)│                       │                       │
└─────┴───────────────────────┴───────────────────────┘
```

### Data Sources
- Process count: Process Explorer data
- Execution stats: Execution Monitor data
- Agent count: Agent Dashboard data
- Activity events: Audit log + execution events
- Current database: `databaseService.getCurrentDatabase()`

### Acceptance Criteria
- [ ] DashboardView component created
- [ ] All widgets integrated and functional
- [ ] Stat cards showing real data
- [ ] Activity feed populated with events
- [ ] Quick actions working
- [ ] Loading states for all data sections
- [ ] Error handling and display
- [ ] Responsive layout (mobile, tablet, desktop)
- [ ] Navigation integration with App.tsx
- [ ] Zustand store for dashboard state
- [ ] Data refresh mechanism (manual or auto)

### Files to Create
- `src/features/dashboard/components/DashboardView.tsx`
- `src/features/dashboard/store/dashboardStore.ts`
- `src/features/dashboard/hooks/useDashboardData.ts`
- `src/features/dashboard/types.ts`

### Files to Update
- `src/App.tsx` - Update dashboard view routing
- `src/features/dashboard/index.ts` - Export new DashboardView

### References
- Existing: `src/features/dashboard/components/Dashboard.tsx`
- State management: Zustand (used elsewhere in codebase)
- Database service: `src/services/databaseService.ts`

---

## Implementation Order

Recommended implementation sequence:

1. **Phase 1: Core Layout** (Week 1)
   - Work Item 1: Main Dashboard Layout
   - Work Item 2: Sidebar Navigation
   - Work Item 3: Top Navigation Bar

2. **Phase 2: Navigation Enhancement** (Week 1-2)
   - Work Item 4: Breadcrumb Component
   - Work Item 5: Global Search

3. **Phase 3: Dashboard Widgets** (Week 2)
   - Work Item 6: Widget Grid System
   - Work Item 7: Stat Cards
   - Work Item 8: Activity Feed
   - Work Item 9: Quick Actions

4. **Phase 4: Integration** (Week 3)
   - Work Item 10: Dashboard Main View Integration
   - Testing and refinement
   - Mobile responsiveness verification

---

## Technical Stack Summary

**Framework:** React 18.2 + TypeScript
**Build Tool:** Vite 5.0
**Styling:** Tailwind CSS 3.4
**Icons:** lucide-react 0.263
**Routing:** react-router-dom 7.8
**State:** Zustand 4.4
**Date Formatting:** date-fns 4.1
**Utilities:** clsx, tailwind-merge

**Theme Colors:**
- Primary: FlowMaster Navy Blue `#0F3460`
- Supporting: Blue scale (50-950 from Tailwind config)
- Corporate UI theme integration

**Code Standards:**
- TypeScript strict mode
- Functional components with hooks
- Corporate UI context integration
- Responsive-first design
- Accessibility (ARIA labels, keyboard nav)

---

## Testing Requirements

For each work item:
- [ ] Component renders without errors
- [ ] TypeScript compilation successful
- [ ] Props validation working
- [ ] Responsive design verified (mobile, tablet, desktop)
- [ ] Accessibility: keyboard navigation and screen readers
- [ ] Integration with existing Corporate UI theme
- [ ] No console warnings or errors
- [ ] Visual regression check against design

---

## Notes

- All components should integrate with existing `CorporateUIContext` for theming
- Follow existing patterns from `SettingsLayout` and `ProcessBreadcrumb`
- Use `lucide-react` icons consistently
- Maintain Tailwind CSS utility-first approach
- Ensure TypeScript types are properly defined
- Components should be reusable and composable
- Mobile-first responsive design approach
