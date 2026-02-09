# Pre-Push Quality Gates - Implementation Summary

## Overview

Added comprehensive quality enforcement with branch-specific rules to maintain high standards for production code while allowing rapid iteration on dev branches.

## What Was Added

### 1. Core Development Rules Update
**File:** `~/.claude/skills/core-development-rules.md`

Added complete "Pre-Push Quality Gates" section covering:
- Branch-specific requirements (strict vs relaxed)
- 8 automated quality checks
- Documentation maintenance rules
- Quality checklist summaries

### 2. Git Workflow Enhancement
**File:** `~/.claude/skills/git-workflow.md`

Added "Pre-Push Quality Gates" section with:
- Hook installation instructions
- Main/master vs dev/feature requirements
- Quality check enforcement details
- Documentation maintenance guidelines
- Required documentation structure

### 3. Automated Quality Hook
**File:** `config/hooks/pre-push-template.sh` (332 lines)

Comprehensive pre-push hook that:
- Detects target branch (main/master vs others)
- Runs 8 automated checks
- Blocks or warns based on branch and severity
- Color-coded output (red=error, yellow=warning, green=pass)
- Provides clear feedback and actionable messages

### 4. Easy Installation Script
**File:** `config/hooks/install-quality-hook.sh`

One-command installation for any project:
```bash
$(cat ~/.claude/.config-loader-path)/config/hooks/install-quality-hook.sh
```

## Branch-Specific Rules

### Main/Master (STRICT MODE - BLOCKING)

**All checks must pass:**
1. ✅ No temp files (*.tmp, *.log, *.bak)
2. ✅ No screenshots in root (must be in docs/)
3. ⚠️  No loose .md files (only README, CHANGELOG, CLAUDE, claude_instructions)
4. ✅ Linting passes (no errors)
5. ✅ All tests passing
6. ✅ Clean build (no errors)
7. ✅ No hardcoded credentials
8. ⚠️  Documentation updated (prompted if code changed without doc updates)

**Documentation requirements:**
- README.md (if features changed)
- docs/ARCHITECTURE.md (if structure changed)
- docs/API.md (if endpoints changed)
- docs/DEVELOPER.md (if setup changed)
- Component specs (if interfaces changed)

### Dev/Feature Branches (RELAXED MODE - WARNINGS ONLY)

**Push proceeds with warnings:**
1. ⚠️  Temp files warned (clean before merging)
2. ⚠️  Linting errors warned
3. ⚠️  Test failures warned
4. ⚠️  Build errors warned
5. ⚠️  Documentation updates suggested

**Philosophy:**
- Allow rapid iteration
- Enable work-in-progress commits
- Defer cleanup to merge time
- Tests optional for WIP

## 8 Automated Checks

### 1. Temp Files
Scans for `.tmp`, `.log`, `.bak` files that shouldn't be committed.

### 2. Screenshots in Root
Ensures images are in `docs/` directory, not root.

### 3. Loose Markdown Files
Only allows `README.md`, `CHANGELOG.md`, `CLAUDE.md`, `claude_instructions.md` in root.

### 4. Linting
Runs `npm run lint` or equivalent for code quality.

### 5. Tests
Runs `npm test` or `pytest` to ensure all tests pass.

### 6. Build
Runs `npm run build` to verify clean compilation.

### 7. Hardcoded Credentials
Scans git diff for common credential patterns:
- `password.*=.*['"]`
- `api_key.*=.*['"]`
- `secret.*=.*['"]`
- `token.*=.*['"]`
- Bearer tokens

### 8. Documentation Freshness
Detects if code changed without corresponding documentation updates.

## Hook Output Examples

### STRICT MODE (main branch):
```
🔍 Running pre-push quality checks...

Branch: main
Mode: STRICT (production branch)

═══════════════════════════════════════
  STRICT MODE: All checks must pass
═══════════════════════════════════════

[1/8] Checking for temp files...
✓ Pass

[2/8] Checking for screenshots in root...
✓ Pass

[3/8] Checking for loose markdown files...
✓ Pass

[4/8] Running linting...
✓ Pass

[5/8] Running tests...
✓ Pass

[6/8] Running build...
✓ Pass

[7/8] Scanning for hardcoded credentials...
✓ Pass

[8/8] Checking documentation freshness...
✓ Pass

═══════════════════════════════════════
✅ All strict checks passed!
Proceeding with push to main
```

### RELAXED MODE (dev branch):
```
🔍 Running pre-push quality checks...

Branch: feature/new-api
Mode: RELAXED (development branch)

═══════════════════════════════════════
  RELAXED MODE: Warnings only
═══════════════════════════════════════

[1/5] Checking for temp files...
⚠️  Temp files found (clean up before merging to main)

[2/5] Running linting...
⚠️  Linting errors found (fix before merging to main)

[3/5] Running tests...
✓ Pass

[4/5] Running build...
✓ Pass

[5/5] Checking documentation...
⚠️  Code changed - consider updating docs before merging

═══════════════════════════════════════
✅ Push proceeding (dev branch)
⚠️  3 warning(s) - address before merging to main
```

## Installation & Usage

### Install in Any Project
```bash
cd ~/projects/your-project
$(cat ~/.claude/.config-loader-path)/config/hooks/install-quality-hook.sh
```

### Bypass Hook (Emergency)
```bash
git push --no-verify
```

### Manual Quality Check
```bash
# Run same checks as hook
npm run lint
npm test
npm run build

# Check for temp files
find . -name "*.tmp" -o -name "*.log" -o -name "*.bak"

# Check for screenshots in root
ls *.png *.jpg 2>/dev/null
```

## Required Documentation Structure

```
project/
├── README.md                    # Project overview, quick start
├── CHANGELOG.md                 # Version history
├── CLAUDE.md                    # Project-specific Claude instructions
├── claude_instructions.md       # Alternative name for CLAUDE.md
├── docs/
│   ├── ARCHITECTURE.md          # System design, patterns, tech stack
│   ├── API.md                   # Endpoint documentation
│   ├── DEVELOPER.md             # Setup, build, deploy instructions
│   ├── DEPLOYMENT.md            # Infrastructure details
│   └── components/              # Component-specific docs
│       ├── user-service.md
│       └── auth-service.md
└── tests/
    └── specs/                   # Component specifications (YAML)
        ├── user-service.spec.yaml
        └── auth-service.spec.yaml
```

## Already Installed

**test-rig:** ✅ Hook installed and active

## Philosophy

### Production (Main/Master):
- **Zero tolerance** for quality issues
- **Complete documentation** required
- **All tests passing** mandatory
- **Clean repository** enforced
- **No technical debt** allowed

### Development (Feature Branches):
- **Rapid iteration** encouraged
- **WIP commits** allowed
- **Tests optional** for exploration
- **Documentation deferred** to merge time
- **Clean up before merging**

## Benefits

1. **Prevents bad code in production** - Strict enforcement on main
2. **Maintains documentation quality** - Forces updates when code changes
3. **Enables rapid development** - Relaxed rules on dev branches
4. **Reduces PR review time** - Quality issues caught before push
5. **Clear feedback** - Color-coded output shows exactly what's wrong
6. **Flexible enforcement** - Can bypass with --no-verify if needed
7. **Automated checking** - No manual quality verification needed
8. **Consistent standards** - Same rules across all projects

## Next Steps

1. Install hook in other active projects (resolver, commander, flowmaster, etc.)
2. Monitor effectiveness over next few pushes
3. Adjust thresholds based on team feedback
4. Consider adding project-specific checks
5. Document exceptions and override policies

## Files Modified

- `~/.claude/skills/core-development-rules.md` (+218 lines)
- `~/.claude/skills/git-workflow.md` (+104 lines)
- `config/hooks/pre-push-template.sh` (new, 332 lines)
- `config/hooks/install-quality-hook.sh` (new, 47 lines)
- `config/git-repos.yaml` (test-rig URLs updated)

**Total:** ~700 lines of quality enforcement infrastructure
