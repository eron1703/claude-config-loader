# User Instructions - Benjamin Hippler

**Purpose:** Track all process instructions and decisions across sessions. These instructions feed into Commander's externalized company brain feature.

**Last Updated:** 2026-02-14

---

## Development Process

### Project Structure & Execution
- **Repository Home:** All active projects on GitLab (retire GitHub for active projects)
- **Naming Convention:** Run repos named by project: `{project}-run-{NNN}` (e.g., commander-run-001, flowmaster-run-002)
- **Methodology:** KICK → COLLECT → SPEC → CHECK → BUILD
  - KICK: Identify the problem/goal
  - COLLECT: Gather existing context and constraints
  - SPEC: Write detailed technical spec before building
  - CHECK: Validate spec understanding with stakeholders
  - BUILD: Execute against spec
- **Spec-First Approach:** Follow spec-writing approach before building anything

### Code Quality & Verification
- **No Mocks:** Everything must show REAL data, verified end-to-end
- **Testing Philosophy:** Test outcomes, not components — full user journey verification required
- **E2E Proof:** E2E testing with Puppeteer screenshots
- **Visual Reports:** HTML visual proof reports for all deployments
- **Verification Standard:** Never claim "done" without proof
- **TDD:** Specs → Tests → Code → Refactor

### Reporting & Documentation
- **ARB Reports:** Keep short and actionable — focus on decisions and conflicts, not lengthy baselines
- **Merge Strategy:** Merge between CRs within a run (not just at end)
- **Design Principle:** "Don't build frontend bullshit that doesn't do anything"

---

## Infrastructure & Deployment

### Server Architecture
- **Cloud Provider:** All servers on Hetzner Cloud
- **Locations:** Helsinki (dev cluster) + Nuremberg (production)
- **Server Fleet:**
  - **dev-01** (65.21.153.235): CCX23, 160GB - Dev env + tools (Plane, Grafana, K3S)
  - **dev-02** (65.21.52.58): CCX33, 8 CPU, 240GB - High-perf dev, agent pods, builds
  - **playground** (89.167.2.145): CX33, 80GB - Pilots, classic Docker (no K3S/CI)
  - **prod-01** (91.99.237.14): CPX41, 250GB - Production app + www.flow-master.ai
  - **mac-mini:** Dynamic - Local (RustDesk via dev-01)

### Orchestration & Container Management
- **K3S:** Primary orchestration on dev-01 and dev-02
- **Registry:** Private container registries per K3S cluster
- **Management Approach:** Enhanced YAML + Grafana visibility (not ArgoCD/Terraform/Portainer)
- **IaC:** Enhanced YAML approach with validate.py validation scripts

### Port Management (CRITICAL)
- **Workflow:** Check existing ports → pick next free → document in ports.yaml → commit & push
- **Allocation Rules:**
  - APIs: 9000-9099
  - Services: 8000-8099
  - Frontends: 3000-3099
- **Documentation:** Must be documented IMMEDIATELY in ports.yaml (project section + by_port section)

### SSH & Connectivity
- **SSH Port Requirement:** ALWAYS include explicit port flag `-p 22` when connecting to Hetzner servers
- **Connection Format:** `ssh -p 22 server-name "command"`
- **Key Mapping:**
  - dev-01 (ben): id_ed25519_dev01_ben
  - dev-01 (root): id_ed25519_dev01
  - prod-01: id_ed25519_prod01
  - dev-02: id_ed25519_dev02 (TODO: generate)
  - playground: id_ed25519_playground (TODO: generate)

### Credentials & Secrets
- **Storage:** GitLab CI/CD group variables
- **Access Method:** Always use `/credentials` skill for token access
- **Firewall Management:** Use Hetzner Cloud API (Token from CI/CD variables)

---

## Team & Tooling

### Primary Tools
- **Development:** Claude Code as primary development tool
- **Parallelization:** Agent swarms for parallel work
- **Project Management:** Plane for project tracking
- **CI/CD:** GitLab CI/CD for pipelines
- **Visibility:** Grafana for monitoring and infrastructure visibility
- **Chat Integration:** Agent Chat Room on dev-01:8099

### Knowledge Management
- **Instructions Tracking:** All instructions documented in this file
- **Purpose:** Feed into Commander's externalized brain feature
- **Living Document:** Updated as new patterns and decisions emerge

### Key Services & Commands
- **claude-pod:** Auto-deploy via push to main (~5 min), repo at https://gitlab.com/flow-master/claude-pod
- **Model Routing (claude-pod):** Sonnet→Grok-3, Opus/Haiku→Gemini 2.5 Flash
- **Agent Chat API:**
  - POST /send
  - GET /messages
  - GET /agents
  - GET /health

---

## Quality Standards & Non-Negotiables

- **Real Data Only:** No mocks — all demonstrations must use actual data
- **End-to-End Verification:** Every feature tested with full user workflow
- **Visual Proof:** Screenshots and HTML reports for all deployments
- **Transparency:** Document decisions, conflicts, and solutions
- **Completeness:** Everything must be production-ready before claiming completion

---

## Recent Session Notes

### 2026-02-14 (Current)
- Created USER-INSTRUCTIONS.md to centralize all collected process instructions
- Established this as living documentation for Commander's externalized brain
- Consolidating instructions from MEMORY.md and across project sessions
