# Dual Remote Push Policy

## Overview

When working with projects that sync to both GitHub and GitLab, the word "push" means pushing to **ALL configured remotes**, not just one.

## Affected Projects

Projects with dual sync enabled:
- **claude-config-loader** - `origin` (GitHub) + `gitlab` (GitLab)
- **test-rig** - `github` (GitHub) + `gitlab` (GitLab)

## Implementation

### Automatic Detection

When user says "push", Claude will:
1. Check `git remote -v` to detect all remotes
2. Push to each remote sequentially
3. Report success/failure for each push

### Command Pattern

```bash
# Standard pattern for dual remotes
git push origin main && git push gitlab main

# Alternative names
git push github main && git push gitlab main

# Single remote (fallback)
git push origin main
```

### Error Handling

If push fails on any remote:
1. Report which remote failed
2. Show error message
3. Don't proceed to next remote unless user confirms
4. Suggest fixes based on error type

## Updated Documentation

### Core Development Rules
Added to `~/.claude/skills/core-development-rules.md`:
```markdown
## Pre-Push Quality Gates

**IMPORTANT: When user says "push", push to ALL configured remotes (GitHub + GitLab).**

For projects with multiple remotes:
```bash
git push origin main && git push gitlab main
```

Projects with dual sync: claude-config-loader, test-rig
```

### Git Workflow
Added new section to `~/.claude/skills/git-workflow.md`:
```markdown
## Push to Multiple Remotes

**CRITICAL: When user says "push", push to ALL configured remotes.**

### Default Behavior

For projects with multiple remotes (GitHub + GitLab):
- Check remotes first with `git remote -v`
- Push to each remote sequentially
- Report results for each push
```

## Rationale

**Why push to both:**
1. **Redundancy** - Code backed up in two locations
2. **Accessibility** - Team can access from either platform
3. **CI/CD** - Different pipelines on different platforms
4. **Compliance** - Some organizations require GitLab for audit trails
5. **Flexibility** - Easy to switch primary platform if needed

**Why not just one:**
- Single point of failure
- Platform-specific features may differ
- One platform may go down
- Team members have different platform preferences

## Verification

Check if project has multiple remotes:
```bash
cd ~/projects/your-project
git remote -v
```

Expected output for dual-sync projects:
```
github    https://github.com/user/repo.git (fetch)
github    https://github.com/user/repo.git (push)
gitlab    https://gitlab.com/group/repo.git (fetch)
gitlab    https://gitlab.com/group/repo.git (push)
```

or:

```
origin    https://github.com/user/repo.git (fetch)
origin    https://github.com/user/repo.git (push)
gitlab    https://gitlab.com/group/repo.git (fetch)
gitlab    https://gitlab.com/group/repo.git (push)
```

## Adding Dual Sync to New Projects

```bash
cd ~/projects/your-project

# Add GitHub remote (if not already set)
git remote add origin https://github.com/user/repo.git

# Add GitLab remote
git remote add gitlab https://gitlab.com/group/repo.git

# Push to both
git push -u origin main
git push -u gitlab main

# Verify
git remote -v
```

## Removing Dual Sync

If project should only use one remote:
```bash
# Remove GitLab remote
git remote remove gitlab

# Now "push" only goes to GitHub
git push origin main
```

## Best Practices

1. **Always verify remotes** before first push in a session
2. **Push to both immediately** - don't let them drift
3. **Check both platforms** if push fails on one
4. **Update git-repos.yaml** when adding/removing remotes
5. **Test with --dry-run** if unsure: `git push --dry-run origin main`

## Troubleshooting

### One Remote Fails
```bash
# Push failed on gitlab
# Fix the issue, then push again
git push gitlab main

# Verify both are in sync
git log origin/main
git log gitlab/main
```

### Remotes Out of Sync
```bash
# Check status
git log origin/main...gitlab/main

# Force sync (careful!)
git push --force-with-lease gitlab main
```

### Wrong Remote Names
```bash
# Rename remote
git remote rename old-name new-name

# Update URLs
git remote set-url origin https://new-url.git
```

## Summary

**Key Takeaway:** "push" = push to ALL remotes for dual-sync projects.

This ensures code is always backed up to multiple platforms and accessible to all team members regardless of their platform preference.
