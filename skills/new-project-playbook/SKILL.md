---
name: new-project-playbook
description: New project setup playbook — GitLab, CI/CD, Plane, test-rig, branching, agent tracking
user-invocable: true
---

# New Project Playbook

**Run this BEFORE build-method [SPEC] phase. Every new project.**

## 1. GitLab Repo

- Create in group `gitlab.com/flow-master/<project-name>`
- One repo per microservice from day 1
- README, .gitignore, .env.example, LICENSE
- Default branch: `develop`
- Deploy keys: `SSH_PRIVATE_KEY` in GitLab CI/CD vars
- Mirror to GitHub (HCB-Consulting-ME) if needed

## 2. Branches

```
main ← production (manual deploy gate)
  └── staging ← auto-deploy on push
        └── develop ← auto-deploy on push
              └── feature/<plane-id>-<desc>
              └── bugfix/<plane-id>-<desc>
```

- Feature branches from `develop`, MR back to `develop`
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `ci:`
- Squash merge. MR title = conventional commit. MR body references Plane ID.
- Never force push develop/staging/main

## 3. GitLab CI/CD (Day 1)

Pipeline: **test → build → deploy**. No docker-compose in CI — GitLab CI handles everything.

```yaml
stages: [test, build, deploy]

test:
  stage: test
  image: python:3.11  # or node:20
  script:
    - test-rig run --parallel
    - test-rig coverage --threshold 80

build:
  stage: build
  image: docker:24
  services: [docker:24-dind]
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

deploy-dev:
  stage: deploy
  only: [develop]
  environment: development
  script:
    - ssh root@$DEV_SERVER "cd /opt/$PROJECT-develop && docker pull $IMAGE && docker compose up -d"

deploy-staging:
  stage: deploy
  only: [staging]
  environment: staging
  script:
    - ssh root@$STAGING_SERVER "cd /opt/$PROJECT-staging && docker pull $IMAGE && docker compose up -d"

deploy-prod:
  stage: deploy
  only: [main]
  when: manual
  environment: production
  script:
    - ssh root@$PRODUCTION_SERVER "cd /opt/$PROJECT && docker pull $IMAGE && docker compose up -d"
```

**Servers:** Dev: 65.21.153.235 | Staging: 91.98.159.56 | Production: 91.99.237.14
**GitLab Runner:** On dev server (65.21.153.235), tags: docker, demo-server

## 4. Plane Project

**Server:** http://65.21.153.235:8083 | **Workspace:** `flowmaster-reimagined`

Setup:
1. Create project (short code, e.g. `RTA`)
2. Create labels (see §5)
3. Every sub-component spec from build-method = 1 Plane work item
4. Work items include: acceptance criteria, test cases, service contract

**Status flow:** `Backlog → Todo → In Progress → In Review → Done`

Rules:
- Update status in real-time
- Never leave "In Progress" without active work
- Blocked items get `Blocked` status + comment with reason

## 5. Agent Tracking

### Labels (create in every project)

| Category | Format | Examples |
|----------|--------|---------|
| Owner | `owner:<name>` | `owner:ben`, `owner:irtiza`, `owner:sadiq` |
| Agent | `agent:<name>` | `agent:coral-fox`, `agent:steel-hawk` |
| Environment | `env:<location>` | `env:mac-mini`, `env:ben-mbp`, `env:pod-api`, `env:server-dev` |
| Priority | `P0` to `P3` | `P0-critical`, `P1-high`, `P2-medium`, `P3-low` |

### Checkout Protocol

**Pick up:**
1. Status → `In Progress`
2. Labels → `agent:<my-name>` + `env:<where>`
3. Comment → `Checked out by <agent> at <time>`

**Complete:**
1. Comment → `Done. Evidence: <tests, logs, screenshots>`
2. Remove `agent:` label
3. Status → `In Review`

**Blocked:**
1. Comment → `Blocked: <reason>`
2. Status → `Blocked` (keep agent label)

### Find who's working on what
- `agent:*` label → all active agent work
- `env:mac-mini` → all Mac Mini work
- `In Progress` + no agent label → orphaned (problem!)

## 6. Port Registration (MANDATORY)

**Every new service MUST register its ports.**
1. Check `/ports` skill for current allocations
2. Pick next available: backends 9000-9099, frontends 3000-3099
3. Update ports config: `~/.claude/skills/claude-config-loader/config/ports.yaml`
4. Commit port registration before first deploy

## 7. Secrets Registration (MANDATORY)

**Every new service MUST register its secrets.**
1. Create `.env.example` with all env vars (no real values)
2. Add real values to GitLab CI/CD variables (Settings → CI/CD → Variables)
3. Document in service README which env vars are required
4. Never hardcode. Never commit `.env`. Always `.gitignore` it.

## 8. Test-Rig (Day 1)

Per service:
```bash
cd <service-dir> && test-rig setup && test-rig doctor
```

## 9. Service Template

```
<service>/
├── .gitlab-ci.yml
├── Dockerfile
├── test-rig.config.yaml
├── .env.example
├── README.md
├── src/
│   └── main.py
└── tests/
    ├── unit/
    ├── integration/
    └── specs/
```

## 10. MR Template

```markdown
## Plane: [RTA-123](link)
## What: <1-2 sentences>
## Evidence
- [ ] test-rig passes, coverage >= 80%
- [ ] Screenshots (if UI)
- [ ] Logs clean
## Agent: <name> | Env: <where>
```

Review: CI passes + 1 approval = merge. Human required for: prod deploy, schema change, security.
