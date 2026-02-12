# FlowMaster Architecture Fix Plan

**Date**: 2026-02-12
**Status**: CRITICAL ISSUES IDENTIFIED - Fix Required Before Parallel Build

---

## User Clarification Received

**CRITICAL**: DXG and SDX are **NOT separate frontends**. They should be **integrated modules within FlowMaster main app**.

### Intended Architecture

```
┌─────────────────────────────────────┐
│   Main FlowMaster Application       │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  Process Designer           │   │
│   │  + DXG (integrated module)  │   │
│   │  + SDX (integrated module)  │   │
│   └─────────────────────────────┘   │
│                                     │
│   Admin Dashboard, Monitoring, etc. │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│   Employee App (Engage)             │
│   - Task execution interface        │
│   - AI-powered task intelligence    │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│   Login / Authentication            │
│   - Centralized auth                │
└─────────────────────────────────────┘
```

### Current (INCORRECT) Implementation

Currently implemented/documented as **5+ separate applications**:
- Frontend Admin (:3000)
- Engage App (:3001)
- **DXG Frontend** (separate - WRONG!)
- **SDX Frontend** (separate - WRONG!)
- Manager App (planned)

**This is why BA review scored 2.8/10** - fundamental architectural mismatch.

---

## Critical Issues Summary

### H1: Port Collisions (BLOCKER)

**Impact**: Services will fail to start due to port conflicts

**Conflicts Identified**:
```yaml
port_9006:
  - Human Task Service (flowmaster-backend skill line 43)
  - AI Agent Orchestration (flowmaster-backend skill line 53)

port_9014:
  - Process Analytics (flowmaster-backend skill line 129)
  - External Integration (flowmaster-backend skill line 137)

port_9000:
  - API Gateway (documented multiple places)
  - Process Service (potential conflict)

port_3001:
  - Engage App (flowmaster-frontend skill)
  - Employee Frontend (flowmaster-environment skill)
  - Manager App (planned)
```

**Root Cause**: Documentation conflicts between skills - backend skill doesn't match environment skill

**Fix Required**:
1. Audit all 29 services for actual vs. documented ports
2. Create canonical port registry (single source of truth)
3. Update flowmaster-backend and flowmaster-environment skills
4. Verify no runtime conflicts
5. Update docker-compose files

**Estimated Effort**: 1 day (audit + fix + verification)

---

### H2: Shared ArangoDB Without Isolation (HIGH RISK)

**Impact**: Schema conflicts, migration failures, data corruption risk

**Current State** (flowmaster-database skill lines 11-12):
```
Database: flowmaster (shared)
Shared by: FlowMaster core services AND SDX infrastructure
Collections: 45+ document collections, 15+ edge collections
No schema versioning, no collection ownership, no migration coordination
```

**Problems**:
- All 29 services share single `flowmaster` database
- No collection-level ownership (which service owns which collection?)
- No schema versioning (how to handle breaking changes?)
- No migration coordination (how to deploy schema updates?)
- SDX and FlowMaster sharing same database creates coupling

**Fix Required**:
1. Define collection ownership model
2. Implement schema versioning system
3. Create migration coordination mechanism
4. Consider separating SDX database from FlowMaster database
5. Document collection access patterns

**Estimated Effort**: 2-3 days (design + implementation + migration)

---

### H3: Hardcoded ClusterIPs in Nginx (INFRASTRUCTURE BRITTLE)

**Impact**: System breaks on every pod restart

**Current State**:
Nginx configuration contains hardcoded Kubernetes ClusterIPs like `10.43.x.x`

**Problem**:
- ClusterIPs change on pod restart
- Manual config updates required
- Downtime on every deployment

**Fix Required**:
1. Replace ClusterIPs with service DNS names
2. Use Kubernetes service discovery
3. Implement health checks
4. Test failover scenarios

**Estimated Effort**: 1 day (config update + testing)

---

### H4: Zero Service Contract Testing (CRITICAL QUALITY GAP)

**Impact**: Integration failures, runtime errors, breaking changes undetected

**Current State**:
- 29 deployed services
- 0 contract tests
- No API versioning validation
- No schema compatibility checks

**Fix Required**:
1. Implement contract testing framework (Pact, Spring Cloud Contract)
2. Create contract tests for all service-to-service interactions
3. Add contract validation to CI/CD pipeline
4. Document service contracts (OpenAPI specs)

**Estimated Effort**: 3-5 days (framework setup + initial contract tests)

---

### H5: Code Not in Version Control (DEPLOYMENT RISK)

**Impact**: No rollback capability, no audit trail, manual deployments only

**Current State**:
- Code deployed to servers
- No GitLab pushes for deployed code
- No version tags
- No deployment history

**Fix Required**:
1. Commit all deployed code to GitLab
2. Create version tags for current deployment
3. Set up GitLab CI/CD pipelines
4. Document deployment procedures
5. Implement automated deployments

**Estimated Effort**: 2-3 days (commit + CI/CD setup + testing)

---

### H6: Frontend Architecture Misalignment (UX CRITICAL)

**Impact**: 2.8/10 user intent alignment, fragmented UX, poor developer experience

**Root Cause**: DXG and SDX implemented as separate frontends instead of integrated modules

**Current State**:
- DXG exists as separate React + Vite application
- SDX exists as separate React application
- Each has own deployment, dependencies, routing

**Intended State**:
- DXG integrated as module within FlowMaster main app
- SDX integrated as module within FlowMaster main app
- Single unified navigation, shared components, consistent UX

**Fix Required**:
1. **Design Integration Strategy**:
   - Module boundaries (DXG module, SDX module within main app)
   - Shared components and design system
   - Routing strategy (nested routes vs. tabs)
   - State management (isolated vs. shared state)

2. **Refactor DXG Frontend**:
   - Extract DXG core logic into reusable module
   - Migrate from standalone Vite app to Next.js route/component
   - Integrate into FlowMaster main app navigation
   - Preserve existing DXG functionality
   - Remove standalone DXG deployment

3. **Refactor SDX Frontend**:
   - Extract SDX core logic into reusable module
   - Migrate from standalone React app to Next.js route/component
   - Integrate into Process Designer workflow (R08 gap)
   - Preserve existing SDX functionality
   - Remove standalone SDX deployment

4. **Unified UX**:
   - Consistent navigation (sidebar, breadcrumbs)
   - Shared design system (Radix UI, Tailwind)
   - Unified authentication and session management
   - Integrated help and documentation

5. **Update Documentation**:
   - Fix flowmaster-frontend skill to reflect correct architecture
   - Update deployment docs
   - Update development setup guide

**Estimated Effort**: 5-7 days (design + refactor + testing + docs)

**Impact on User Intent Alignment**: Expected improvement from 2.8/10 → 7-8/10

---

## Prioritized Fix Plan

### Phase 1: Critical Blockers (3-4 days)
**Must fix before any parallel build**

1. **Port Conflicts** (H1) - 1 day
   - Create canonical port registry
   - Update all documentation
   - Verify no runtime conflicts

2. **Frontend Architecture** (H6) - Design only (1 day)
   - Design DXG/SDX integration strategy
   - Create integration architecture document
   - Get user approval on approach

3. **Version Control** (H5) - 2 days
   - Commit all code to GitLab
   - Tag current deployment
   - Basic CI/CD setup

### Phase 2: Infrastructure Hardening (2-3 days)
**Required for production stability**

4. **Nginx ClusterIPs** (H3) - 1 day
   - Replace hardcoded IPs with DNS names
   - Test failover

5. **Database Isolation** (H2) - 2 days
   - Define collection ownership
   - Implement schema versioning
   - Create migration process

### Phase 3: Quality & Integration (3-5 days)
**Required for sustainable development**

6. **Contract Testing** (H4) - 3-5 days
   - Set up contract testing framework
   - Create initial contract tests
   - Integrate into CI/CD

### Phase 4: Frontend Integration (5-7 days)
**User experience transformation**

7. **DXG Integration** (H6) - 3 days
   - Refactor DXG into FlowMaster module
   - Integrate into main app navigation

8. **SDX Integration** (H6) - 2-3 days
   - Refactor SDX into FlowMaster module
   - Integrate into Process Designer (R08)

9. **Unified UX Polish** (H6) - 1-2 days
   - Consistent navigation and design
   - Testing and refinement

---

## Recommended Approach

**Option A (Recommended): Fix Critical Blockers First**

1. Phase 1 (3-4 days) - Fix blockers
2. Parallel Build with infrastructure work items
3. Phase 2-4 in parallel with feature development

**Benefits**:
- Unblocks parallel agent execution
- Prevents building on broken foundation
- Infrastructure work can happen in parallel with features

**Option B: Hybrid Approach**

1. Fix H1 (ports) and H5 (version control) immediately (3 days)
2. Start parallel build for non-conflicting work
3. Fix H2-H6 in parallel with feature development

**Benefits**:
- Faster start on feature development
- More risk but manageable

**Option C: Full Fix First**

1. Complete all Phase 1-4 fixes (13-19 days)
2. Then start parallel build with clean architecture

**Benefits**:
- Perfect foundation
- Zero technical debt in new features

**Trade-offs**:
- Delays feature development
- Requires significant upfront investment

---

## Next Steps

**Immediate**:
1. ✅ Get user confirmation on frontend architecture understanding
2. Get user decision on which fix approach (A, B, or C)
3. Update flowmaster-frontend skill to reflect correct architecture

**After Decision**:
- Create detailed work items for chosen phases
- Begin execution on critical fixes
- Maintain quality pipeline agents for ongoing review

---

## Questions for User

1. **Frontend Integration**: Confirm DXG and SDX should be integrated INTO FlowMaster main app as modules, not separate applications?

2. **Fix Approach**: Which approach do you prefer (A, B, or C)?

3. **Frontend Structure**: Should DXG and SDX be:
   - Nested routes within main app (`/process-designer/dxg`, `/process-designer/sdx`)?
   - Tabs within Process Designer?
   - Modal overlays?
   - Other?

4. **Priority**: Are there any fixes you want to prioritize or defer?
