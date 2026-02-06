# Architecture Guidelines

## Stack-Specific Guidelines

### Python/FastAPI Backend

#### Structure
```python
# Use async/await for I/O operations
async def get_user(user_id: str) -> User:
    return await db.fetch_one(...)

# Type hints on function signatures
def process_data(input: dict[str, Any]) -> ProcessedData:
    ...

# Pydantic for validation
class UserRequest(BaseModel):
    email: EmailStr
    name: str
```

#### Logging
- Use structlog for structured JSON logging
- Include context (case_id, user_id, etc.)
```python
logger.info("Processing started", case_id=case_id, user_id=user_id)
```

#### Error Handling
- Let exceptions bubble to FastAPI handlers
- Only catch specific exceptions you can handle
- Use `exc_info=True` for debugging

#### Dependencies
- Use dependency injection for services
- Follow FastAPI patterns

### TypeScript/React Frontend

#### Component Structure
```typescript
// Functional components with TypeScript
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

export const UserCard: React.FC<UserCardProps> = ({ user, onEdit }) => {
  // Hooks at the top
  const [isEditing, setIsEditing] = useState(false);

  // Event handlers
  const handleEdit = () => onEdit(user.id);

  // Render
  return <div>...</div>;
};
```

#### Data Fetching
- Use React Query for server state
- Use useState/useContext for UI state
- Avoid prop drilling - use context or state management

#### Styling
- CSS Modules or styled-components
- Follow existing project patterns
- No inline styles except for dynamic values

### Database (ArangoDB)

#### Query Patterns
```aql
// Use AQL for complex queries
FOR event IN events
  FILTER event.case_id == @caseId
  SORT event.timestamp DESC
  LIMIT 100
  RETURN event
```

#### Graph Modeling
- Entities → Collections (nodes)
- Relationships → Edge Collections
- Use graph traversals for connected data

#### Performance
- Create indexes in migrations
- Use appropriate index types
- Test query performance

### Database (PostgreSQL)

#### Schema Design
- Normalize data appropriately
- Use foreign keys for relationships
- Add indexes for frequently queried columns

#### Queries
- Use prepared statements
- Optimize with EXPLAIN ANALYZE
- Consider connection pooling

## Docker & Infrastructure

### Docker Compose
- One service per container
- Use named volumes for persistence
- Environment variables in .env files (gitignored)
- Health checks for dependent services

### Port Allocation
- Backend APIs: 9000-9099
- Frontend Dev: 3000-3099
- PostgreSQL: 5432-5499
- ArangoDB: 8529 (main), 8530 (web UI)
- MongoDB: 27017-27099
- Redis: 6379-6399

## API Design

### RESTful Patterns
- Use standard HTTP methods (GET, POST, PUT, DELETE)
- Resource-based URLs: `/api/users/{id}`
- Use appropriate status codes
- Version APIs: `/api/v1/...`

### Request/Response
- Validate all inputs with Pydantic
- Return consistent error format
- Include request IDs for tracing

### WebSockets
- Use for real-time bidirectional communication
- Implement heartbeat/ping-pong
- Handle reconnection gracefully
- Close with appropriate codes

## Performance Guidelines

### Backend
- Use async I/O for database/API calls
- Implement pagination for large datasets
- Cache expensive computations
- Use database indexes
- Monitor query performance

### Frontend
- Lazy load routes and heavy components
- Debounce user input
- Use React.memo for expensive renders
- Virtual scrolling for long lists
- Code splitting

### Database
- Index frequently queried fields
- Avoid N+1 queries
- Use connection pooling
- Monitor slow queries

## Security Guidelines

### Authentication
- Never auto-fill credentials
- Store tokens securely (httpOnly cookies)
- Implement CSRF protection
- Use secure session management

### Authorization
- Check permissions on every request
- Principle of least privilege
- Don't trust client-side checks

### Input Validation
- Validate all user input on backend
- Sanitize before database operations
- Use parameterized queries
- Escape output appropriately

### API Security
- Rate limiting on sensitive endpoints
- CORS configuration
- JWT expiration and refresh
- API key management

## Monitoring & Observability

### Logging
- Structured logging (JSON)
- Include context (request ID, user ID, etc.)
- Log levels: DEBUG, INFO, WARNING, ERROR
- Don't log sensitive data

### Metrics
- Track response times
- Monitor error rates
- Database query performance
- Resource usage (CPU, memory)

### Tracing
- Use request IDs
- Trace through distributed systems
- Identify bottlenecks
