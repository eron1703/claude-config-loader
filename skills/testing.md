---
name: testing
description: Access testing configuration and delegate to test-rig tool for test generation and execution
user-invocable: true
---

# Testing Skill (Minimal)

**Purpose:** Provide testing configuration and delegate to `test-rig` tool.

## Configuration

!`cat ~/projects/claude-config-loader/config/testing.yaml`

## test-rig Tool

**Installation:**
```bash
npm install -g test-rig
# or
git clone https://github.com/your-org/test-rig
cd test-rig && npm install && npm link
```

## Quick Commands

```bash
# Setup test infrastructure for current project
test-rig setup

# Generate tests for component
test-rig generate user-service

# Run tests
test-rig run
test-rig run unit
test-rig run integration
test-rig run --parallel

# Check coverage
test-rig coverage

# Get help
test-rig --help
```

## From Claude Code

When user requests testing tasks, Claude Code will:
1. Load project config from `testing.yaml`
2. Invoke `test-rig` CLI with appropriate commands
3. Report results back to user

## Project Mappings

Loaded from configuration:
- resolver: vitest, 4 agents, postgres+arangodb+redis
- commander: vitest, 8 agents, microservices
- flowmaster: vitest+pytest, 12 agents, large microservices
- dxg: pytest, 4 agents, postgres+redis
- engage: vitest, 6 agents, MCP testing
- sdx: vitest, 4 agents, contract testing

## Documentation

Full documentation available at: ~/projects/test-rig/README.md

---

**Note:** This skill provides lightweight configuration. Heavy tooling lives in the `test-rig` project.
