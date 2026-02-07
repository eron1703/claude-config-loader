---
name: test-rig
description: Test-rig project development context - architecture, source structure, dev workflow (only for ~/projects/test-rig/)
user-invocable: true
---

# Test-Rig Development

**Project:** Multi-agent testing orchestration platform (CLI + API server)
**Location:** ~/projects/test-rig/
**Tech:** TypeScript, Vitest, Playwright, Testcontainers
**Repos:** GitHub (eron1703/test-rig) + GitLab (flow-master/test-rig)
**Version:** 1.0.0 | 29 tests | Quality 7.2/10

---

## Architecture

```
src/
├── cli/commands/     # CLI commands (setup, generate, run, coverage, analyze, doctor, serve)
├── core/             # Test execution (test-runner, project-detector, framework-installer, config-loader, component-analyzer, spec-generator, coverage-generator, health-checker)
├── agents/           # Multi-agent orchestration (orchestrator, test-generator)
├── server/           # Optional API server (Express + SSE streaming)
├── templates/        # Test templates with {{PLACEHOLDER}} syntax
└── utils/            # Environment detection (CI, Claude agents, non-TTY)
```

## Key Source Files

| File | Purpose |
|---|---|
| src/cli/index.ts | CLI entry point (Commander.js) |
| src/cli/commands/run.ts | Test execution command |
| src/core/test-runner.ts | Vitest/Pytest/Playwright execution + JSON output parsing |
| src/agents/orchestrator.ts | Parallel agent spawning, topological sort, result aggregation |
| src/agents/test-generator.ts | Test file generation from templates |
| src/server/index.ts | API server (POST /test/run, GET /test/stream, GET /health) |
| src/utils/environment.ts | CI/agent detection (CLAUDE_CODE, GITHUB_ACTIONS, etc.) |

## Development Workflow

```bash
# Edit src/ → build → test → lint
npm run build && npm test && npm run lint

# Watch mode for development
npm run test:watch
```

## Agent Rules for This Project

- ALL test-rig commands MUST use `--headless`, `--yes`, `--non-interactive` flags
- Environment auto-detection: CLAUDE_CODE=true, CI=true, non-TTY
- Templates in src/templates/ use {{COMPONENT_NAME}}, {{COMPONENT_PATH}} placeholders
- Component specs (YAML) define testable units with dependency ordering
- Orchestrator does topological sort for parallel execution without conflicts

## Common Dev Tasks

**Add new framework:** framework-installer.ts → test-runner.ts → template → README
**Add new template:** src/templates/ → test-generator.ts → postbuild copy
**Add CLI command:** src/cli/commands/ → register in src/cli/index.ts
**Add API endpoint:** src/server/index.ts

## Quality Gates (Strict on main)

- All 29 tests passing
- No linting errors
- Clean build (`npm run build`)
- Push to BOTH remotes: `git push github main && git push gitlab main`
