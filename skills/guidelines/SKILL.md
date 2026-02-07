---
name: guidelines
description: Development guidelines - security, code quality, git workflow, Docker rules
disable-model-invocation: true
---

# Development Guidelines

## Skill Scoping Rules

**CRITICAL: Generic skills and project-specific skills are NOT the same.**

### Generic Infrastructure Skills (apply to ALL projects)
- ports, databases, servers, repos, cicd, credentials, environment, guidelines, save, project, supervisor, testing
- These describe the local development environment, shared infrastructure, and general workflows

### Project-Specific Skills (apply ONLY to their project)
- `flowmaster-*` skills apply ONLY when working on FlowMaster (`~/projects/flowmaster/`)
- Do NOT use FlowMaster skills when working on other projects
- Do NOT confuse project-specific databases, ports, or env vars with generic infrastructure config

### Override Rules
- Project-specific skills override generic skills where they conflict
- Generic skills still apply for shared infrastructure (Docker rules, git workflow, security)

---

## 1. Security Rules

### Credentials Management
- NEVER hardcode credentials in source code
- Use environment variables for all secrets
- Use `.env` files with `.env.example` templates
- All `.env` files must be in `.gitignore`

### Input Validation & Injection Prevention
- Parameterized queries for all database operations
- Validate all user input at system boundaries
- Never trust external API responses - validate schemas

### Data Protection
- Hash passwords with bcrypt or argon2
- Never log sensitive data
- Use HTTPS for all external communications
- Implement CORS properly - whitelist specific origins

## 2. Code Quality Standards

### Development Approach
- Implement only what's requested - no over-engineering
- No scope creep
- Delete unused code immediately
- STRICTLY FORBIDDEN: No mock functionality
- Self-documenting code with clear names

### Type Safety
- Type hints on all Python functions
- TypeScript interfaces/types for all components
- Use Pydantic models for FastAPI validation
- Never use `any` in TypeScript

### Code Organization
- Small focused functions (single responsibility, max 50 lines)
- Max 3 levels of nesting
- Named constants for magic numbers/strings

## 3. Architecture Patterns

### Python/FastAPI Backend
- Use async/await for all I/O
- Dependency injection via Depends()
- Structured logging with context
- Consistent error response format
- Pydantic models for validation
- Version APIs explicitly (/api/v1/)

### React/TypeScript Frontend
- Functional components only
- React Query for server state
- No inline styles
- Custom hooks for reusable logic

### API Design
- RESTful conventions
- Consistent JSON response: `{success, data, error}`
- Proper HTTP status codes
- Pagination for list endpoints

## 4. Docker/Container Rules

- NEVER shut down Docker/OrbStack globally
- Check container status before operations
- Use named volumes for persistent data
- Health checks for all services
- Specific image tags (not latest)
- Multi-stage builds, non-root user
- Check port availability: `lsof -i :PORT`

## 5. Git & Version Control

### Commit Practices
- Atomic commits, conventional commit messages
- Never force push to main/master
- PR reviews required

### Branch Strategy
- main (production), develop (integration), feature/*, bugfix/*, docs/*

## 6. Error Handling
- Let exceptions bubble up to framework handlers
- Structured logging with context (user_id, request_id)
- Consistent error format to clients
- Never log sensitive data

## 7. Testing Strategy
- Unit tests: individual functions in isolation
- Integration tests: multiple components together
- E2E tests: full user workflows
- 70%+ coverage, 100% on critical paths

---

**Note:** Project-specific rules (CLAUDE.md) override these global guidelines.
