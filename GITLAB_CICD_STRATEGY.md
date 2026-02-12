# GitLab Repository Structure and CI/CD Pipeline Strategy

**Document Version**: 1.0
**Date**: 2026-02-12
**Status**: Design Document - Awaiting Implementation
**Author**: Claude (Sonnet 4.5)

---

## Executive Summary

This document defines the GitLab repository structure, CI/CD pipeline architecture, and deployment strategy for the FlowMaster microservices platform consisting of 29 services across multiple deployment environments.

**Key Decisions**:
- **Repository Strategy**: Hybrid monorepo + multi-repo approach
- **Branch Strategy**: GitFlow with environment-specific branches
- **Pipeline Stages**: 6-stage pipeline (lint → test → build → package → deploy → validate)
- **Deployment Strategy**: Progressive deployment through dev → staging → production
- **Rollback**: Automated rollback capability with version tagging

---

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [Branch Strategy](#branch-strategy)
3. [CI/CD Pipeline Architecture](#cicd-pipeline-architecture)
4. [Deployment Procedures](#deployment-procedures)
5. [Version Tagging](#version-tagging)
6. [Rollback Procedures](#rollback-procedures)
7. [Security & Secrets](#security--secrets)
8. [Monitoring & Observability](#monitoring--observability)

---

## Repository Structure

### Strategy: Hybrid Monorepo + Multi-Repo

**Rationale**: Balance between code sharing, team autonomy, and deployment flexibility.

### Repository Organization

```yaml
gitlab.com/flow-master/
├── flowmaster-platform/          # MONOREPO - Core Platform
│   ├── services/
│   │   ├── api-gateway/          # Service 1
│   │   ├── auth-service/         # Service 2
│   │   ├── process-design/       # Service 3
│   │   ├── execution-engine/     # Service 4
│   │   ├── human-task/           # Service 5
│   │   ├── ai-agent/             # Service 6
│   │   ├── scheduling/           # Service 7
│   │   ├── notification/         # Service 8
│   │   ├── websocket-gateway/    # Service 9
│   │   ├── document-intelligence/# Service 10
│   │   ├── process-analytics/    # Service 11
│   │   ├── external-integration/ # Service 12
│   │   └── ...                   # Services 13-22
│   ├── shared/
│   │   ├── libraries/            # Shared Python/Node libraries
│   │   ├── proto/                # Protobuf definitions
│   │   ├── schemas/              # ArangoDB schemas
│   │   └── configs/              # Shared configs
│   ├── docker/
│   │   ├── base-images/          # Base Docker images
│   │   └── docker-compose/       # Compose templates
│   ├── k8s/
│   │   ├── base/                 # Base K8s manifests
│   │   ├── overlays/             # Kustomize overlays
│   │   │   ├── dev/
│   │   │   ├── staging/
│   │   │   └── production/
│   │   └── charts/               # Helm charts
│   ├── scripts/
│   │   ├── deploy/               # Deployment scripts
│   │   ├── migrations/           # DB migration scripts
│   │   └── health-checks/        # Health check scripts
│   ├── .gitlab-ci.yml            # Root CI/CD pipeline
│   └── README.md
│
├── flowmaster-frontend/          # SEPARATE REPO - Main Frontend
│   ├── src/
│   │   ├── modules/
│   │   │   ├── process-designer/
│   │   │   ├── dxg/              # DXG module (integrated)
│   │   │   ├── sdx/              # SDX module (integrated)
│   │   │   ├── admin/
│   │   │   └── dashboard/
│   │   ├── components/
│   │   ├── layouts/
│   │   └── routes/
│   ├── .gitlab-ci.yml
│   └── README.md
│
├── flowmaster-engage/            # SEPARATE REPO - Employee App
│   ├── src/
│   ├── .gitlab-ci.yml
│   └── README.md
│
├── flowmaster-manager/           # SEPARATE REPO - Manager App
│   ├── src/
│   ├── .gitlab-ci.yml
│   └── README.md
│
├── flowmaster-mobile/            # SEPARATE REPO - Guard Mobile
│   ├── ios/
│   ├── android/
│   ├── src/
│   ├── .gitlab-ci.yml
│   └── README.md
│
├── flowmaster-infrastructure/    # SEPARATE REPO - Infrastructure
│   ├── terraform/                # Terraform configs
│   ├── ansible/                  # Ansible playbooks
│   ├── monitoring/               # Grafana/Prometheus
│   ├── databases/                # DB schemas and migrations
│   │   ├── arangodb/
│   │   ├── postgresql/
│   │   └── redis/
│   ├── nginx/                    # Nginx configs
│   ├── k3s/                      # K3s cluster setup
│   ├── .gitlab-ci.yml
│   └── README.md
│
└── flowmaster-testing/           # SEPARATE REPO - Test Infrastructure
    ├── contract-tests/           # Pact contract tests
    ├── e2e-tests/                # End-to-end tests
    ├── performance-tests/        # Load/stress tests
    ├── .gitlab-ci.yml
    └── README.md
```

### Repository Breakdown

**Monorepo: `flowmaster-platform`**
- **Purpose**: Core microservices (Services 1-22)
- **Benefits**:
  - Shared code/libraries versioned together
  - Atomic cross-service changes
  - Simplified dependency management
  - Single CI/CD configuration
- **Drawbacks**:
  - Larger repository size
  - Requires smart CI/CD (only build changed services)

**Separate Repos: Frontends**
- **`flowmaster-frontend`**: Main admin/designer app (Next.js)
- **`flowmaster-engage`**: Employee task app
- **`flowmaster-manager`**: Manager oversight app
- **`flowmaster-mobile`**: Guard mobile app
- **Rationale**: Independent release cycles, different tech stacks, separate teams

**Separate Repos: Infrastructure**
- **`flowmaster-infrastructure`**: Terraform, K8s, configs
- **`flowmaster-testing`**: Test infrastructure
- **Rationale**: Infrastructure-as-code, security isolation, ops team ownership

### Repository Access Control

```yaml
access_control:
  flowmaster-platform:
    maintainers:
      - platform-team
      - devops-team
    developers:
      - backend-engineers
    reporters:
      - qa-team
      - product-team

  flowmaster-frontend:
    maintainers:
      - frontend-team
    developers:
      - frontend-engineers

  flowmaster-infrastructure:
    maintainers:
      - devops-team
    developers:
      - platform-team
    reporters:
      - all-engineers

  flowmaster-testing:
    maintainers:
      - qa-team
    developers:
      - all-engineers
```

---

## Branch Strategy

### GitFlow with Environment Branches

```
main (production)
├── staging (pre-production)
│   └── develop (integration)
│       ├── feature/FM-123-process-designer
│       ├── feature/FM-124-ai-agent-upgrade
│       ├── bugfix/FM-125-auth-token-refresh
│       └── hotfix/FM-126-critical-security-patch
```

### Branch Definitions

| Branch | Purpose | Deploy Target | Protection |
|--------|---------|---------------|------------|
| `main` | Production-ready code | Production servers | Protected, requires approval |
| `staging` | Pre-production testing | Staging servers | Protected, auto-deploy |
| `develop` | Integration branch | Dev servers | Protected, auto-deploy |
| `feature/*` | New features | None (local testing) | No protection |
| `bugfix/*` | Bug fixes | None (local testing) | No protection |
| `hotfix/*` | Critical production fixes | Fast-tracked to main | Requires approval |

### Branch Protection Rules

**`main` Branch**:
```yaml
protection:
  - no_direct_push: true
  - require_merge_request: true
  - require_approval: 2 (senior engineers)
  - require_ci_pass: true
  - no_force_push: true
  - require_signed_commits: true
  - merge_method: squash
```

**`staging` Branch**:
```yaml
protection:
  - no_direct_push: true
  - require_merge_request: true
  - require_approval: 1 (any engineer)
  - require_ci_pass: true
  - auto_deploy_on_merge: true
```

**`develop` Branch**:
```yaml
protection:
  - no_direct_push: true
  - require_merge_request: true
  - require_ci_pass: true
  - auto_deploy_on_merge: true
```

### Merge Request Workflow

```
1. Create Feature Branch
   └─> git checkout -b feature/FM-123-process-designer develop

2. Develop & Commit
   └─> git commit -m "feat(process): add BPMN import capability"

3. Push & Create MR
   └─> git push origin feature/FM-123-process-designer
   └─> Create MR: feature/FM-123 → develop

4. CI/CD Pipeline Runs
   └─> Lint → Test → Build → Deploy to Dev (if merged)

5. Code Review
   └─> Reviewers approve MR

6. Merge to Develop
   └─> Auto-deploy to dev.flow-master.ai

7. Promote to Staging
   └─> Create MR: develop → staging
   └─> Auto-deploy to staging.flow-master.ai

8. Promote to Production
   └─> Create MR: staging → main
   └─> Manual trigger: Deploy to app.flow-master.ai
```

---

## CI/CD Pipeline Architecture

### Pipeline Stages Overview

```yaml
stages:
  - lint          # Code quality checks
  - test          # Unit & integration tests
  - build         # Build artifacts
  - package       # Docker image creation
  - deploy        # Deployment to target environment
  - validate      # Post-deployment validation
```

### Root Pipeline: `.gitlab-ci.yml`

**Location**: `flowmaster-platform/.gitlab-ci.yml`

```yaml
# FlowMaster Platform CI/CD Pipeline
# Monorepo pipeline with service-specific jobs

stages:
  - lint
  - test
  - build
  - package
  - deploy
  - validate

variables:
  DOCKER_REGISTRY: registry.gitlab.com/flow-master
  DOCKER_TLS_CERTDIR: "/certs"
  KUBECONFIG: /etc/deploy/kubeconfig

# Global before_script
before_script:
  - echo "Pipeline for commit $CI_COMMIT_SHORT_SHA"
  - export SERVICE_PATH=$(echo $CI_JOB_NAME | sed 's/.*:\(.*\)/\1/')

# === LINT STAGE ===
# Run linters for Python and Node.js services

lint:python:
  stage: lint
  image: python:3.11-slim
  script:
    - pip install black flake8 mypy
    - black --check services/
    - flake8 services/
    - mypy services/ --ignore-missing-imports
  rules:
    - changes:
        - services/**/*.py
        - shared/**/*.py

lint:node:
  stage: lint
  image: node:20-alpine
  script:
    - npm install -g eslint prettier
    - eslint services/*/src
    - prettier --check services/*/src
  rules:
    - changes:
        - services/**/*.ts
        - services/**/*.js

lint:docker:
  stage: lint
  image: hadolint/hadolint:latest
  script:
    - hadolint services/*/Dockerfile
    - hadolint docker/base-images/*/Dockerfile
  rules:
    - changes:
        - services/*/Dockerfile
        - docker/**/*

# === TEST STAGE ===
# Run unit and integration tests

.test_template: &test_template
  stage: test
  services:
    - postgres:15
    - redis:7-alpine
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: test_user
    POSTGRES_PASSWORD: test_password
    REDIS_URL: redis://redis:6379

test:api-gateway:
  <<: *test_template
  image: python:3.11-slim
  script:
    - cd services/api-gateway
    - pip install -r requirements.txt
    - pip install pytest pytest-cov
    - pytest --cov=. --cov-report=xml
  coverage: '/(?i)total.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: services/api-gateway/coverage.xml
  rules:
    - changes:
        - services/api-gateway/**/*

test:auth-service:
  <<: *test_template
  image: python:3.11-slim
  script:
    - cd services/auth-service
    - pip install -r requirements.txt
    - pip install pytest pytest-cov
    - pytest --cov=. --cov-report=xml
  coverage: '/(?i)total.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: services/auth-service/coverage.xml
  rules:
    - changes:
        - services/auth-service/**/*

# Repeat for all 22 services...
# test:process-design:
# test:execution-engine:
# test:human-task:
# test:ai-agent:
# ... etc

test:shared-libraries:
  stage: test
  image: python:3.11-slim
  script:
    - cd shared/libraries
    - pip install -r requirements.txt
    - pytest --cov=. --cov-report=xml
  rules:
    - changes:
        - shared/libraries/**/*

# === BUILD STAGE ===
# Build service artifacts

.build_template: &build_template
  stage: build
  image: python:3.11-slim
  artifacts:
    paths:
      - services/*/dist/
    expire_in: 1 day

build:api-gateway:
  <<: *build_template
  script:
    - cd services/api-gateway
    - pip install build
    - python -m build
  rules:
    - changes:
        - services/api-gateway/**/*

# Repeat for all services...

# === PACKAGE STAGE ===
# Build and push Docker images

.docker_template: &docker_template
  stage: package
  image: docker:24-cli
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

docker:api-gateway:
  <<: *docker_template
  script:
    - cd services/api-gateway
    - |
      docker build \
        --build-arg VERSION=$CI_COMMIT_SHORT_SHA \
        -t $DOCKER_REGISTRY/api-gateway:$CI_COMMIT_SHORT_SHA \
        -t $DOCKER_REGISTRY/api-gateway:$CI_COMMIT_REF_SLUG \
        .
    - docker push $DOCKER_REGISTRY/api-gateway:$CI_COMMIT_SHORT_SHA
    - docker push $DOCKER_REGISTRY/api-gateway:$CI_COMMIT_REF_SLUG
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop" || $CI_COMMIT_BRANCH == "staging" || $CI_COMMIT_BRANCH == "main"'
      changes:
        - services/api-gateway/**/*

# Repeat for all services...

# === DEPLOY STAGE ===
# Deploy to target environments

.deploy_template: &deploy_template
  stage: deploy
  image: bitnami/kubectl:latest
  before_script:
    - mkdir -p /etc/deploy
    - echo "$KUBECONFIG_CONTENT" | base64 -d > /etc/deploy/kubeconfig
    - export KUBECONFIG=/etc/deploy/kubeconfig

deploy:dev:
  <<: *deploy_template
  environment:
    name: development
    url: https://dev.flow-master.ai
  script:
    - |
      for service in api-gateway auth-service process-design execution-engine human-task ai-agent scheduling notification websocket-gateway document-intelligence process-analytics external-integration; do
        if [ -f "services/$service/k8s/deployment.yaml" ]; then
          kubectl set image deployment/$service \
            $service=$DOCKER_REGISTRY/$service:$CI_COMMIT_SHORT_SHA \
            -n flowmaster-dev
        fi
      done
    - kubectl rollout status deployment -n flowmaster-dev --timeout=300s
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'
  when: on_success

deploy:staging:
  <<: *deploy_template
  environment:
    name: staging
    url: https://staging.flow-master.ai
  script:
    - |
      for service in api-gateway auth-service process-design execution-engine human-task ai-agent scheduling notification websocket-gateway document-intelligence process-analytics external-integration; do
        kubectl set image deployment/$service \
          $service=$DOCKER_REGISTRY/$service:$CI_COMMIT_SHORT_SHA \
          -n flowmaster-staging
      done
    - kubectl rollout status deployment -n flowmaster-staging --timeout=300s
  rules:
    - if: '$CI_COMMIT_BRANCH == "staging"'
  when: on_success

deploy:production:
  <<: *deploy_template
  environment:
    name: production
    url: https://app.flow-master.ai
  script:
    - |
      for service in api-gateway auth-service process-design execution-engine human-task ai-agent scheduling notification websocket-gateway document-intelligence process-analytics external-integration; do
        kubectl set image deployment/$service \
          $service=$DOCKER_REGISTRY/$service:$CI_COMMIT_TAG \
          -n flowmaster-production
      done
    - kubectl rollout status deployment -n flowmaster-production --timeout=600s
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  when: manual
  allow_failure: false

# === VALIDATE STAGE ===
# Post-deployment health checks

.validate_template: &validate_template
  stage: validate
  image: curlimages/curl:latest

validate:dev:
  <<: *validate_template
  script:
    - |
      for service in api-gateway auth-service process-design execution-engine human-task ai-agent; do
        curl -f https://dev.flow-master.ai/$service/health || exit 1
      done
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'
  needs:
    - deploy:dev

validate:staging:
  <<: *validate_template
  script:
    - |
      for service in api-gateway auth-service process-design execution-engine human-task ai-agent; do
        curl -f https://staging.flow-master.ai/$service/health || exit 1
      done
  rules:
    - if: '$CI_COMMIT_BRANCH == "staging"'
  needs:
    - deploy:staging

validate:production:
  <<: *validate_template
  script:
    - |
      for service in api-gateway auth-service process-design execution-engine human-task ai-agent; do
        curl -f https://app.flow-master.ai/$service/health || exit 1
      done
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  needs:
    - deploy:production
```

### Frontend Pipeline: `flowmaster-frontend/.gitlab-ci.yml`

```yaml
# FlowMaster Frontend CI/CD Pipeline

stages:
  - lint
  - test
  - build
  - deploy

variables:
  DOCKER_REGISTRY: registry.gitlab.com/flow-master

lint:
  stage: lint
  image: node:20-alpine
  script:
    - npm ci
    - npm run lint
    - npm run typecheck
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/

test:
  stage: test
  image: node:20-alpine
  script:
    - npm ci
    - npm run test:ci
  coverage: '/All files[^|]*\|[^|]*\s+([\d\.]+)/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/

build:
  stage: build
  image: node:20-alpine
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - .next/
      - out/
    expire_in: 1 day
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .next/cache/

docker:
  stage: build
  image: docker:24-cli
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - |
      docker build \
        --build-arg VERSION=$CI_COMMIT_SHORT_SHA \
        -t $DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_SHORT_SHA \
        -t $DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_REF_SLUG \
        .
    - docker push $DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_SHORT_SHA
    - docker push $DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_REF_SLUG
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop" || $CI_COMMIT_BRANCH == "staging" || $CI_COMMIT_BRANCH == "main"'

deploy:dev:
  stage: deploy
  image: bitnami/kubectl:latest
  environment:
    name: development
    url: https://dev.flow-master.ai
  script:
    - echo "$KUBECONFIG_CONTENT" | base64 -d > /tmp/kubeconfig
    - export KUBECONFIG=/tmp/kubeconfig
    - |
      kubectl set image deployment/flowmaster-frontend \
        flowmaster-frontend=$DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_SHORT_SHA \
        -n flowmaster-dev
    - kubectl rollout status deployment/flowmaster-frontend -n flowmaster-dev
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop"'

deploy:staging:
  stage: deploy
  image: bitnami/kubectl:latest
  environment:
    name: staging
    url: https://staging.flow-master.ai
  script:
    - echo "$KUBECONFIG_CONTENT" | base64 -d > /tmp/kubeconfig
    - export KUBECONFIG=/tmp/kubeconfig
    - |
      kubectl set image deployment/flowmaster-frontend \
        flowmaster-frontend=$DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_SHORT_SHA \
        -n flowmaster-staging
    - kubectl rollout status deployment/flowmaster-frontend -n flowmaster-staging
  rules:
    - if: '$CI_COMMIT_BRANCH == "staging"'

deploy:production:
  stage: deploy
  image: bitnami/kubectl:latest
  environment:
    name: production
    url: https://app.flow-master.ai
  script:
    - echo "$KUBECONFIG_CONTENT" | base64 -d > /tmp/kubeconfig
    - export KUBECONFIG=/tmp/kubeconfig
    - |
      kubectl set image deployment/flowmaster-frontend \
        flowmaster-frontend=$DOCKER_REGISTRY/flowmaster-frontend:$CI_COMMIT_TAG \
        -n flowmaster-production
    - kubectl rollout status deployment/flowmaster-frontend -n flowmaster-production
  rules:
    - if: '$CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/'
  when: manual
```

### Infrastructure Pipeline: `flowmaster-infrastructure/.gitlab-ci.yml`

```yaml
# FlowMaster Infrastructure CI/CD Pipeline

stages:
  - validate
  - plan
  - apply

variables:
  TF_ROOT: terraform/
  TF_STATE_NAME: flowmaster

validate:terraform:
  stage: validate
  image: hashicorp/terraform:latest
  script:
    - cd $TF_ROOT
    - terraform init -backend=false
    - terraform validate
    - terraform fmt -check
  rules:
    - changes:
        - terraform/**/*

validate:ansible:
  stage: validate
  image: cytopia/ansible:latest
  script:
    - cd ansible/
    - ansible-lint playbooks/
  rules:
    - changes:
        - ansible/**/*

validate:k8s:
  stage: validate
  image: bitnami/kubectl:latest
  script:
    - kubectl apply --dry-run=client -f k3s/manifests/
  rules:
    - changes:
        - k3s/**/*

plan:terraform:
  stage: plan
  image: hashicorp/terraform:latest
  script:
    - cd $TF_ROOT
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - $TF_ROOT/tfplan
    expire_in: 1 day
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop" || $CI_COMMIT_BRANCH == "staging" || $CI_COMMIT_BRANCH == "main"'
      changes:
        - terraform/**/*

apply:terraform:
  stage: apply
  image: hashicorp/terraform:latest
  script:
    - cd $TF_ROOT
    - terraform init
    - terraform apply -auto-approve tfplan
  dependencies:
    - plan:terraform
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
      changes:
        - terraform/**/*
  when: manual

deploy:monitoring:
  stage: apply
  image: bitnami/kubectl:latest
  script:
    - echo "$KUBECONFIG_CONTENT" | base64 -d > /tmp/kubeconfig
    - export KUBECONFIG=/tmp/kubeconfig
    - kubectl apply -k monitoring/overlays/$CI_COMMIT_REF_SLUG/
  rules:
    - if: '$CI_COMMIT_BRANCH == "develop" || $CI_COMMIT_BRANCH == "staging" || $CI_COMMIT_BRANCH == "main"'
      changes:
        - monitoring/**/*
```

---

## Deployment Procedures

### Environment Configuration

| Environment | Server | URL | Branch | Deploy Trigger | Approval |
|-------------|--------|-----|--------|----------------|----------|
| **Development** | 65.21.153.235 | dev.flow-master.ai | `develop` | Auto on merge | None |
| **Staging** | 91.98.159.56 | staging.flow-master.ai | `staging` | Auto on merge | None |
| **Production** | 91.99.237.14 | app.flow-master.ai | `main` (tags) | Manual | Required (2) |

### Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ DEVELOPMENT ENVIRONMENT                                         │
│ dev.flow-master.ai (65.21.153.235)                              │
├─────────────────────────────────────────────────────────────────┤
│ Trigger: Push to develop branch                                │
│ Deploy: Automatic (on CI/CD pass)                              │
│ Validation: Health checks + smoke tests                        │
│ Rollback: Automatic on health check failure                    │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ QA Testing + Manual Validation
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ STAGING ENVIRONMENT                                             │
│ staging.flow-master.ai (91.98.159.56)                           │
├─────────────────────────────────────────────────────────────────┤
│ Trigger: MR: develop → staging                                 │
│ Deploy: Automatic (on merge + CI/CD pass)                      │
│ Validation: Full integration tests + contract tests            │
│ Soak Period: 24-48 hours                                       │
│ Rollback: Automatic on test failure                            │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Approval by 2 senior engineers
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ PRODUCTION ENVIRONMENT                                          │
│ app.flow-master.ai (91.99.237.14)                               │
├─────────────────────────────────────────────────────────────────┤
│ Trigger: Git tag (v*.*.*)                                      │
│ Deploy: MANUAL trigger required                                │
│ Validation: Production health checks + canary deployment       │
│ Monitoring: Real-time alerts + error tracking                  │
│ Rollback: Manual trigger with automated execution              │
└─────────────────────────────────────────────────────────────────┘
```

### Deployment Steps

**1. Development Deployment**

```bash
# Automatic on push to develop
git checkout develop
git merge feature/FM-123-process-designer
git push origin develop

# GitLab CI/CD automatically:
# 1. Runs lint + tests
# 2. Builds Docker images
# 3. Deploys to dev.flow-master.ai
# 4. Runs health checks
# 5. Notifies team in Slack
```

**2. Staging Deployment**

```bash
# Create merge request
# develop → staging

# After approval and merge, GitLab CI/CD:
# 1. Runs full test suite
# 2. Builds Docker images with staging tag
# 3. Deploys to staging.flow-master.ai
# 4. Runs integration tests
# 5. Monitors for 24-48 hours
```

**3. Production Deployment**

```bash
# Create version tag
git checkout main
git merge staging
git tag -a v1.2.3 -m "Release v1.2.3: Process Designer Improvements"
git push origin main --tags

# In GitLab UI:
# 1. Navigate to CI/CD → Pipelines
# 2. Find pipeline for tag v1.2.3
# 3. Click "deploy:production" job
# 4. Review deployment plan
# 5. Click "Manual action" → "Run"
# 6. Monitor deployment progress
# 7. Verify production health checks
```

### Deployment Verification

**Health Check Script**: `scripts/health-checks/verify-deployment.sh`

```bash
#!/bin/bash
# Verify deployment health

ENVIRONMENT=$1
BASE_URL=$2

SERVICES=(
  "api-gateway"
  "auth-service"
  "process-design"
  "execution-engine"
  "human-task"
  "ai-agent"
  "scheduling"
  "notification"
  "websocket-gateway"
  "document-intelligence"
  "process-analytics"
  "external-integration"
)

echo "Verifying deployment to $ENVIRONMENT ($BASE_URL)"

FAILED_SERVICES=()

for service in "${SERVICES[@]}"; do
  echo "Checking $service..."

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/$service/health)

  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "  ✅ $service healthy"
  else
    echo "  ❌ $service failed (HTTP $HTTP_CODE)"
    FAILED_SERVICES+=("$service")
  fi
done

if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
  echo ""
  echo "✅ All services healthy"
  exit 0
else
  echo ""
  echo "❌ Failed services: ${FAILED_SERVICES[*]}"
  exit 1
fi
```

---

## Version Tagging

### Semantic Versioning Strategy

**Format**: `v{MAJOR}.{MINOR}.{PATCH}`

**Examples**:
- `v1.0.0` - Initial release
- `v1.1.0` - New feature release
- `v1.1.1` - Bug fix release
- `v2.0.0` - Breaking changes

### Versioning Rules

**MAJOR version** (v**X**.0.0):
- Breaking API changes
- Database schema breaking changes
- Major architectural changes
- Incompatible with previous versions

**MINOR version** (v1.**X**.0):
- New features (backward compatible)
- New API endpoints
- Database migrations (non-breaking)
- Deprecations (with backward compatibility)

**PATCH version** (v1.1.**X**):
- Bug fixes
- Performance improvements
- Security patches
- Documentation updates

### Tag Creation Process

**1. Manual Tagging**

```bash
# Checkout main branch
git checkout main
git pull origin main

# Create annotated tag
git tag -a v1.2.3 -m "Release v1.2.3

Features:
- FM-123: BPMN import capability
- FM-124: AI agent conversation memory
- FM-125: Process analytics dashboard

Bug Fixes:
- FM-126: Auth token refresh issue
- FM-127: WebSocket reconnection logic

Breaking Changes:
- None
"

# Push tag to GitLab
git push origin v1.2.3
```

**2. Automated Tagging (via GitLab CI)**

```yaml
# .gitlab-ci.yml

release:tag:
  stage: deploy
  image: alpine/git:latest
  script:
    - |
      VERSION=$(cat VERSION)
      git tag -a v$VERSION -m "Automated release v$VERSION"
      git push origin v$VERSION
  rules:
    - if: '$CI_COMMIT_BRANCH == "main" && $CI_COMMIT_MESSAGE =~ /^Release v[0-9]+\.[0-9]+\.[0-9]+/'
  when: manual
```

### Tag Management

**List Tags**:
```bash
git tag -l -n9  # List tags with 9 lines of annotation
```

**Delete Tag** (if mistake):
```bash
git tag -d v1.2.3              # Delete local
git push origin :refs/tags/v1.2.3  # Delete remote
```

**Rollback to Tag**:
```bash
git checkout v1.2.2
kubectl rollout undo deployment/api-gateway -n flowmaster-production
```

### Service Version Tracking

**Version File**: `VERSION`

```
1.2.3
```

**Inject into Docker Images**:

```dockerfile
# Dockerfile
FROM python:3.11-slim
ARG VERSION=unknown
ENV APP_VERSION=$VERSION
LABEL version="$VERSION"
```

**Build with Version**:
```bash
docker build --build-arg VERSION=v1.2.3 -t flowmaster/api-gateway:v1.2.3 .
```

---

## Rollback Procedures

### Automated Rollback Triggers

```yaml
rollback_triggers:
  health_check_failure:
    threshold: 3 consecutive failures
    action: automatic rollback

  error_rate_spike:
    threshold: error_rate > 5%
    window: 5 minutes
    action: automatic rollback

  response_time_degradation:
    threshold: p95_latency > 2x baseline
    window: 10 minutes
    action: alert + manual rollback approval

  canary_failure:
    threshold: canary_error_rate > 1%
    action: automatic rollback
```

### Rollback Methods

#### Method 1: Kubernetes Rollback (Fastest)

```bash
# Rollback to previous deployment
kubectl rollout undo deployment/api-gateway -n flowmaster-production

# Rollback to specific revision
kubectl rollout undo deployment/api-gateway -n flowmaster-production --to-revision=42

# Check rollback status
kubectl rollout status deployment/api-gateway -n flowmaster-production
```

#### Method 2: Redeploy Previous Tag

```bash
# Checkout previous tag
git checkout v1.2.2

# Trigger deployment pipeline
# (In GitLab UI: Pipelines → Run Pipeline for v1.2.2)

# Or manually deploy
kubectl set image deployment/api-gateway \
  api-gateway=registry.gitlab.com/flow-master/api-gateway:v1.2.2 \
  -n flowmaster-production
```

#### Method 3: Database Rollback (if migrations involved)

```bash
# Run migration rollback script
cd flowmaster-infrastructure/databases/arangodb/migrations
./rollback-migration.sh v1.2.3

# Verify database schema version
./verify-schema-version.sh
```

### Rollback Checklist

```
Pre-Rollback:
□ Identify root cause of failure
□ Determine rollback target version
□ Verify rollback target is stable
□ Notify team and stakeholders
□ Capture logs and metrics from failed deployment

Execute Rollback:
□ Execute rollback procedure (Method 1, 2, or 3)
□ Monitor rollback progress
□ Verify health checks pass
□ Verify core user workflows

Post-Rollback:
□ Confirm system stability
□ Notify team and stakeholders (rollback complete)
□ Create incident report
□ Root cause analysis
□ Create fix for failed deployment
□ Schedule re-deployment
```

### Rollback Script

**Script**: `scripts/deploy/rollback-production.sh`

```bash
#!/bin/bash
# Production rollback script

set -e

NAMESPACE="flowmaster-production"
TARGET_VERSION=$1

if [ -z "$TARGET_VERSION" ]; then
  echo "Usage: $0 <target-version>"
  echo "Example: $0 v1.2.2"
  exit 1
fi

echo "🔴 PRODUCTION ROLLBACK INITIATED"
echo "Target Version: $TARGET_VERSION"
echo "Namespace: $NAMESPACE"
echo ""

read -p "Are you sure you want to rollback production? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Rollback cancelled"
  exit 0
fi

echo ""
echo "📋 Rolling back services..."

SERVICES=(
  "api-gateway"
  "auth-service"
  "process-design"
  "execution-engine"
  "human-task"
  "ai-agent"
  "scheduling"
  "notification"
  "websocket-gateway"
  "document-intelligence"
  "process-analytics"
  "external-integration"
)

for service in "${SERVICES[@]}"; do
  echo "Rolling back $service..."

  kubectl set image deployment/$service \
    $service=registry.gitlab.com/flow-master/$service:$TARGET_VERSION \
    -n $NAMESPACE

  echo "Waiting for $service rollout..."
  kubectl rollout status deployment/$service -n $NAMESPACE --timeout=300s

  echo "✅ $service rolled back successfully"
  echo ""
done

echo ""
echo "🔍 Verifying health checks..."
./scripts/health-checks/verify-deployment.sh production https://app.flow-master.ai

echo ""
echo "✅ PRODUCTION ROLLBACK COMPLETE"
echo "Rolled back to: $TARGET_VERSION"
```

---

## Security & Secrets

### Secrets Management Strategy

**GitLab CI/CD Variables** (encrypted at rest):

```yaml
# Protected Variables (only main/staging/develop branches)
variables:
  # Docker Registry
  CI_REGISTRY_USER: (protected, masked)
  CI_REGISTRY_PASSWORD: (protected, masked)

  # Kubernetes
  KUBECONFIG_CONTENT: (protected, masked, file)

  # Database Credentials
  ARANGO_ROOT_PASSWORD: (protected, masked)
  POSTGRES_PASSWORD: (protected, masked)
  REDIS_PASSWORD: (protected, masked)

  # API Keys
  OPENAI_API_KEY: (protected, masked)
  ANTHROPIC_API_KEY: (protected, masked)

  # Auth Secrets
  JWT_SECRET_KEY: (protected, masked)
  SESSION_SECRET_KEY: (protected, masked)

  # Notification Services
  SLACK_WEBHOOK_URL: (protected, masked)
  EMAIL_SMTP_PASSWORD: (protected, masked)
```

### Environment-Specific Secrets

```yaml
# Development
dev:
  ARANGO_ROOT_PASSWORD: dev_password (less secure OK)
  JWT_SECRET_KEY: dev_secret

# Staging
staging:
  ARANGO_ROOT_PASSWORD: (GitLab CI variable)
  JWT_SECRET_KEY: (GitLab CI variable)

# Production
production:
  ARANGO_ROOT_PASSWORD: (GitLab CI variable + Vault)
  JWT_SECRET_KEY: (GitLab CI variable + Vault)
  encrypted: true
  rotation_policy: 90_days
```

### Secrets Rotation

```bash
# Rotate production secrets quarterly
# 1. Generate new secrets
# 2. Update GitLab CI variables
# 3. Update Kubernetes secrets
kubectl create secret generic flowmaster-secrets \
  --from-literal=arango-password=$NEW_PASSWORD \
  --from-literal=jwt-secret=$NEW_JWT_SECRET \
  -n flowmaster-production \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Rolling restart services
kubectl rollout restart deployment -n flowmaster-production
```

### Security Best Practices

```yaml
security_practices:
  - Never commit secrets to git
  - Use GitLab CI/CD protected variables
  - Mask sensitive outputs in CI logs
  - Rotate secrets quarterly (production)
  - Use Vault for production secrets
  - Principle of least privilege (service accounts)
  - Scan Docker images for vulnerabilities (Trivy)
  - Enable RBAC in Kubernetes
  - Audit GitLab access logs
  - Use signed commits for main branch
```

---

## Monitoring & Observability

### CI/CD Pipeline Monitoring

**Metrics to Track**:
```yaml
pipeline_metrics:
  success_rate: "% of successful pipeline runs"
  build_duration: "Average build time per service"
  deploy_duration: "Average deployment time"
  test_coverage: "Code coverage %"
  failure_rate: "% of failed pipelines"
  rollback_frequency: "Number of rollbacks per month"
```

**Dashboards**:
- GitLab CI/CD Analytics (built-in)
- Grafana Dashboard: "FlowMaster CI/CD Metrics"
- Prometheus metrics scraped from GitLab Runner

### Deployment Monitoring

**Post-Deployment Checks**:
```yaml
deployment_validation:
  health_checks:
    - endpoint: /health
      expected: 200 OK
      timeout: 5s

  smoke_tests:
    - login_flow
    - create_process
    - execute_process
    - view_dashboard

  performance_checks:
    - api_latency < 200ms (p95)
    - error_rate < 0.1%
    - cpu_usage < 70%
    - memory_usage < 80%
```

**Alerts**:
```yaml
alerts:
  pipeline_failure:
    channel: slack-#eng-alerts
    notify: @platform-team

  deployment_failure:
    channel: slack-#eng-alerts + pagerduty
    notify: @on-call-engineer
    severity: high

  rollback_triggered:
    channel: slack-#eng-alerts + pagerduty
    notify: @platform-team + @devops-team
    severity: critical
```

### Integration with Monitoring Stack

**Grafana Integration**:
- GitLab CI/CD metrics exported to Prometheus
- Custom Grafana dashboards for pipeline analytics
- Deployment event annotations on service dashboards

**Loki Integration**:
- GitLab CI/CD logs streamed to Loki
- Centralized log search for pipeline debugging
- Correlation between CI logs and application logs

---

## Appendix

### Service Port Registry

| Service | Port | Type | Protocol |
|---------|------|------|----------|
| API Gateway | 9000 | Backend | HTTP/REST |
| Auth Service | 9001 | Backend | HTTP/REST |
| Document Intelligence | 9002 | Backend | HTTP/REST |
| Process Design | 9003 | Backend | HTTP/REST |
| Execution Engine | 9004 | Backend | HTTP/gRPC |
| Scheduling Service | 9005 | Backend | HTTP/REST |
| Human Task Service | 9007 | Backend | HTTP/REST |
| AI Agent Orchestration | 9008 | Backend | HTTP/REST |
| Notification Service | 9009 | Backend | HTTP/REST |
| WebSocket Gateway | 9010 | Backend | WebSocket |
| Process Analytics | 9011 | Backend | HTTP/REST |
| External Integration | 9012 | Backend | HTTP/REST |
| SDX Service | 9013 | Backend | HTTP/REST |
| Admin Frontend | 3000 | Frontend | HTTP |
| Engage App | 3001 | Frontend | HTTP |
| Manager App | 3002 | Frontend | HTTP |

### Docker Registry Structure

```
registry.gitlab.com/flow-master/
├── api-gateway:develop
├── api-gateway:staging
├── api-gateway:v1.2.3
├── auth-service:develop
├── auth-service:staging
├── auth-service:v1.2.3
├── ... (repeat for all 29 services)
├── flowmaster-frontend:develop
├── flowmaster-frontend:staging
├── flowmaster-frontend:v1.2.3
```

### Environment Variables Template

**.env.template** (for local development):

```bash
# Database
ARANGO_HOST=localhost
ARANGO_PORT=8529
ARANGO_DB=flowmaster
ARANGO_USER=root
ARANGO_PASSWORD=your_password_here

POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=flowmaster
POSTGRES_USER=flowmaster
POSTGRES_PASSWORD=your_password_here

REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_password_here

# API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Authentication
JWT_SECRET_KEY=your_secret_key_here
JWT_ALGORITHM=HS256
JWT_EXPIRATION=3600

# Service URLs
API_GATEWAY_URL=http://localhost:9000
AUTH_SERVICE_URL=http://localhost:9001
PROCESS_DESIGN_URL=http://localhost:9003

# Frontend URLs
FRONTEND_URL=http://localhost:3000
ENGAGE_APP_URL=http://localhost:3001

# Monitoring
GRAFANA_URL=http://localhost:30080
PROMETHEUS_URL=http://localhost:9090
```

---

## Document Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-12 | Claude (Sonnet 4.5) | Initial document creation |

---

**END OF DOCUMENT**
