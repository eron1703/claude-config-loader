# Global Development Rules

Development guidelines and best practices enforced across all projects.

## 1. Security Rules

### Credentials Management
- **NEVER hardcode credentials** in source code
- Use environment variables for all secrets (API keys, passwords, tokens)
- Use `.env` files with `.env.example` templates showing required variables
- All `.env` files must be in `.gitignore`
- Never commit `.env` files to version control
- Rotate credentials regularly

### Input Validation & Injection Prevention
- Parameterized queries for all database operations - prevent SQL injection
- Validate all user input at system boundaries (controllers, CLI handlers)
- Sanitize inputs only at boundaries, not throughout the application
- Never trust external API responses - validate schemas
- Type checking prevents many injection issues

### Repository Security
- No credentials in git history
- Use `git-secrets` or similar to scan commits
- Verify `.gitignore` is properly configured before initial commit
- Use SSH keys for git authentication, not tokens in URLs

### Data Protection
- Hash passwords with bcrypt (Python) or argon2
- Never log sensitive data (passwords, tokens, SSNs)
- Use HTTPS for all external communications
- Encrypt sensitive data at rest when required
- Implement CORS properly - whitelist specific origins

## 2. Code Quality Standards

### Development Approach
- **Implement only what's requested** - no over-engineering or "nice-to-haves"
- No scope creep - if it's not in the requirements, don't build it
- Delete unused code immediately - no dead code
- **STRICTLY FORBIDDEN: No mock functionality** in production code
- No commented-out code - use version control history instead
- Self-documenting code with clear, descriptive names

### Type Safety
- **Type hints on all Python functions** (parameter types and return types)
- `TypeScript` interfaces/types for all React components and data structures
- Use `Pydantic` models for FastAPI validation and serialization
- Never use `any` in TypeScript - be specific with types

### Code Organization
- Keep functions small and focused (single responsibility)
- Maximum function length: 50 lines (encourage breaking into smaller functions)
- Avoid deeply nested conditionals (max 3 levels)
- Extract magic numbers and strings into named constants
- Use descriptive variable names - avoid single letters except in loops

### Documentation
- Docstrings for all public functions/classes
- Include parameter descriptions and return types
- Document non-obvious logic inline
- Keep comments close to the code they describe

## 3. Architecture Patterns

### Python/FastAPI Backend
- Use `async`/`await` for all I/O operations (database, HTTP calls)
- Dependency injection via FastAPI's `Depends()`
- Structured logging with `structlog` - include context (case_id, user_id, request_id)
- Exception handling: let exceptions bubble to FastAPI middleware
- Only catch specific exceptions you can actually handle
- Return consistent error response format from all endpoints
- Use Pydantic models for request/response validation
- Version APIs explicitly (e.g., `/api/v1/...`)

### React/TypeScript Frontend
- Functional components only - no class components
- React Query (TanStack Query) for server state management
- Zustand or Context API for local state
- No inline styles - use CSS modules or styled-components
- Custom hooks for reusable logic
- Prop interfaces/types on all components
- Use React DevTools and Performance profiler

### Database Patterns
- **ArangoDB**: Use AQL queries with proper variable binding, implement graph traversals, use edge collections for relationships
- **PostgreSQL**: Normalize data properly, use foreign keys, parameterized statements, appropriate indexes on frequently queried columns, migrations with version control

### API Design
- RESTful endpoints following standard conventions (GET, POST, PUT, DELETE)
- Explicit API versioning (v1, v2)
- Consistent JSON response structure:
  ```json
  {
    "success": boolean,
    "data": {...} | [...],
    "error": {
      "code": "ERROR_CODE",
      "message": "Human readable message"
    }
  }
  ```
- Proper HTTP status codes (200, 201, 400, 401, 403, 404, 500)
- Pagination for list endpoints (limit, offset/cursor)
- Include request IDs in all responses for debugging

### Real-Time Communication
- WebSocket for real-time features
- Use Socket.IO for auto-reconnection and fallback
- Implement heartbeat/ping-pong to detect disconnections
- Clean up subscriptions on disconnect

## 4. Repository Structure

### Required Files
- `README.md` - Project overview, setup instructions, how to run
- `CHANGELOG.md` - Document all changes per version
- `CLAUDE.md` - AI assistant context and project-specific rules

### Required Directories
- `docs/` - Documentation directory
  - `docs/ARCHITECTURE.md` - System design, data models, component relationships
  - `docs/API.md` - API endpoint documentation, request/response examples
  - `docs/DEVELOPER.md` - Development setup, common tasks, debugging
- `tests/` - Test suite directory
  - `tests/unit/` - Unit tests for individual functions/components
  - `tests/integration/` - Integration tests for multiple components
  - `tests/e2e/` - End-to-end tests using real services

### Project Root Rules
- No temp files in root
- No screenshots in root (`/screenshots` or `docs/assets/` if needed)
- No debug files, `.DS_Store`, or system files
- No large binary files (images should be external references or documentation)
- Configuration files in `config/` directory
- Source code in `src/` or language-specific directories

### .gitignore Essentials
- `node_modules/`, `__pycache__/`, `.venv/`
- `.env`, `.env.local` (all environment files)
- `.DS_Store`, `Thumbs.db`
- IDE settings (`.vscode/`, `.idea/`)
- Build artifacts (`dist/`, `build/`, `.next/`)
- Test coverage reports (`coverage/`, `.nyc_output/`)
- Logs and temp files (`*.log`, `tmp/`)

## 5. Docker/Container Rules

### Container Management
- **NEVER shut down Docker/OrbStack globally** - only manage individual containers
- Always check container status before operations
- Use named volumes for persistent data (not bind mounts)
- Implement health checks for all services

### Configuration & Credentials
- Use `.env` files for container environment variables
- Docker Compose for multi-container orchestration
- Mount `.env` as read-only where possible
- Never commit `.env` files

### Port Management
- Always check port availability before starting containers
- Document port mappings in README and docker-compose.yml
- Use non-privileged ports (> 1024) in development
- Avoid hard-coding ports - use environment variables

### Best Practices
- Use specific image tags (not `latest`)
- Multi-stage builds to reduce image size
- Run as non-root user
- Set resource limits (memory, CPU)
- Implement graceful shutdown (signal handling)

## 6. Error Handling

### Exception Strategy
- Let exceptions bubble up to framework error handlers
- Only catch specific exceptions you can handle
- Catch at the boundary where you can take action
- Never catch bare `Exception` in normal code

### Structured Logging
- Use structured logging (structlog, Winston)
- Include context with every log: `user_id`, `case_id`, `request_id`, `action`
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Log on entry/exit for async operations
- Never log sensitive data

### Error Responses
- Return consistent error format to clients
- Include error codes for programmatic handling
- Provide human-readable messages (avoid stack traces in production)
- Log full stack traces internally, not to client
- Track error metrics for monitoring

## 7. Performance Optimization

### Async I/O
- All database queries must be async in FastAPI
- All API calls must be async
- Batch database operations where possible
- Use connection pooling for databases

### Data Management
- Implement pagination for all list endpoints (default limit: 20-50)
- Cache expensive computations with TTL
- Use database indexes on frequently queried columns
- Lazy load routes and heavy components in React
- Virtual scrolling for long lists (>100 items)

### Frontend Performance
- Code splitting at route boundaries
- Tree-shaking to remove unused code
- Defer non-critical JavaScript
- Optimize images (WebP, responsive sizes)
- Monitor bundle size with tools like `webpack-bundle-analyzer`
- Use React.memo for expensive component renders

### Monitoring
- Implement request/response timing logs
- Monitor slow queries (> 100ms threshold)
- Track error rates and patterns
- Use APM tools in production (Datadog, New Relic, etc.)
- Set up alerts for critical issues

## 8. Testing Strategy

### Test Types
- **Unit tests**: Individual functions/components in isolation
- **Integration tests**: Multiple components working together
- **E2E tests**: Full user workflows through the application

### Test Requirements
- All public functions should have unit tests
- Async functions must test both success and error paths
- Component tests should verify rendered output, not just existence
- Mock external dependencies (APIs, databases) in unit tests
- Use real services in integration tests

### Coverage Goals
- Aim for 70%+ overall coverage
- 100% coverage for critical paths
- Critical paths: auth, data validation, error handling

## 9. Git & Version Control

### Commit Practices
- Atomic commits - one logical change per commit
- Clear commit messages following conventional commits
- Reference issue numbers when applicable
- Never force push to main/master branch
- Require PR reviews before merging to protected branches

### Branch Strategy
- `main` - production releases only
- `develop` - integration branch
- `feature/name` - feature development
- `bugfix/name` - bug fixes
- `docs/name` - documentation updates

### PR Guidelines
- Keep PRs focused on single feature/fix
- Include description of changes and rationale
- Reference related issues
- All tests must pass
- Code review required before merge
- Squash commits before merging feature branches

## 10. Environment Management

### Development
- Use `.env` files locally
- Document all required variables in `.env.example`
- Use reasonable defaults for non-sensitive values
- Document any required setup steps in DEVELOPER.md

### Staging
- Use deployment pipeline (GitHub Actions, GitLab CI, etc.)
- Automated tests must pass
- Manual testing gate
- Use production-like configuration

### Production
- Environment variables from secure vault (AWS Secrets Manager, etc.)
- Immutable infrastructure - rebuild for changes
- Blue-green deployments when possible
- Automated rollback capability
- Monitoring and alerting

---

**Last Updated**: 2026-02-07
**Version**: 1.0
