# Claude Code Configuration - Demystified

This guide explains WHERE things go and WHY. Claude Code's config system is confusing - this should help.

---

## The Confusion

Claude Code has multiple config locations:
- `~/.claude/` - Global (affects ALL projects)
- `./.claude/` - Project-specific (affects ONLY current project)
- `CLAUDE.md` or `claude_instructions.md` - Project instructions
- `settings.json` - Global settings
- Skills can be global OR project-specific

**This project (claude-config-loader) makes this SIMPLER by centralizing everything.**

---

## Where Things Actually Live

### 1. Your Source of Truth (This Project)

```
~/projects/claude-config-loader/
├── config/          ← YOUR ACTUAL CONFIG DATA (edit these!)
│   ├── ports.yaml
│   ├── servers.yaml
│   └── ...
└── skills/          ← SKILL DEFINITIONS (how to load config)
    ├── ports/
    ├── servers/
    └── ...
```

**This is the ONLY place you edit.** Everything else is just shortcuts.

### 2. Claude's Global Config (Shortcuts)

```
~/.claude/
├── skills/          ← SHORTCUTS to claude-config-loader/skills/
│   ├── ports        → ~/projects/claude-config-loader/skills/ports
│   ├── servers      → ~/projects/claude-config-loader/skills/servers
│   └── ...
├── hooks/
│   └── load-context.sh  → ~/projects/claude-config-loader/hooks/load-context.sh
└── settings.json    ← HOOK CONFIGURATION (points to load-context.sh)
```

**You don't edit here.** These are just shortcuts (symlinks).

### 3. Project-Specific Instructions (Optional)

```
~/projects/your-project/
├── claude_instructions.md   ← Project-specific rules (optional)
└── CLAUDE.md                ← Alternative name (optional)
```

**These override global rules when in this project.**

---

## What the Install Script Does

**TL;DR:** Creates shortcuts so skills work everywhere.

```bash
./install.sh
```

**What it does:**
1. Creates `~/.claude/skills/` directory
2. Creates shortcuts from your project to `~/.claude/skills/`
3. Creates shortcut for hook script
4. Updates `~/.claude/settings.json` to use the hook

**Result:** Skills work in ANY directory on your computer.

---

## How It Works After Installation

### When You're in ANY Project

```bash
cd ~/projects/resolver
claude
> /ports
```

**What happens:**
1. Hook runs (shows reminder)
2. You invoke `/ports`
3. Claude reads `~/.claude/skills/ports/SKILL.md` (which is a shortcut)
4. Skill executes: `cat ~/projects/claude-config-loader/config/ports.yaml`
5. Config is loaded

**You're in resolver, but it loads config from claude-config-loader. This is INTENTIONAL.**

### When You Edit Config

```bash
cd ~/projects/claude-config-loader/config
vim ports.yaml
# Make changes
```

**Changes are IMMEDIATELY available everywhere because:**
- Skills are shortcuts to claude-config-loader
- Skills read files from claude-config-loader/config/
- No need to reinstall or update anything

---

## The Three Levels of Config

### Level 1: Global Skills (claude-config-loader)
**Where:** `~/.claude/skills/` (shortcuts to claude-config-loader)
**Scope:** ALL projects
**Example:** `/ports`, `/servers`, `/databases`
**Used when:** You invoke them or Claude detects need

### Level 2: Hook (runs every command)
**Where:** `~/.claude/hooks/load-context.sh`
**Scope:** ALL projects
**What it does:** Shows reminder about available skills
**Token cost:** ~100 tokens per command

### Level 3: Project-Specific Rules
**Where:** `./claude_instructions.md` in each project
**Scope:** ONLY that project
**Example:** Supervisor mode rules for resolver
**Loaded by:** `/rules` skill when in that directory

---

## Comparison: Before vs After Installation

### BEFORE Installation

```bash
cd ~/projects/resolver
claude
> What port is the backend on?

Claude: [Doesn't know - no config loaded]
You'd have to tell Claude every time.
```

### AFTER Installation

```bash
cd ~/projects/resolver
claude

# Hook shows reminder
📋 Configuration Skills Available:
• /ports, /servers, /databases, /rules, /repos, /cicd, /project, /environment, /remember

> What port is the backend on?

Claude: [Automatically invokes /ports]
Claude: The resolver backend is on port 9000
```

**Or from ANY other project:**

```bash
cd ~/projects/some-other-project
claude
> What port does resolver use?

Claude: [Invokes /ports]
Claude: Resolver backend is on port 9000
```

---

## Do You Need to Reinstall?

**NO!** Once installed, skills work forever.

**When you change config:**
```bash
vim ~/projects/claude-config-loader/config/ports.yaml
# Save changes
```

Changes are immediately available because skills read directly from this file.

**Only reinstall if:**
- You add NEW skills (new directories in skills/)
- You delete `~/.claude/skills/` by accident
- You move the claude-config-loader project to a different location

---

## Where Does Claude Look for Config?

When you invoke `/ports`, here's what happens:

1. **Claude checks:** `~/.claude/skills/ports/SKILL.md` (global skill)
2. **Shortcut points to:** `~/projects/claude-config-loader/skills/ports/SKILL.md`
3. **Skill contains:** Command to read `~/projects/claude-config-loader/config/ports.yaml`
4. **Config loaded:** From claude-config-loader project

**You can be in ANY directory. Skills always load from claude-config-loader.**

---

## Project-Specific Overrides

You can override for specific projects:

```bash
cd ~/projects/resolver

# Copy template
cp ~/projects/claude-config-loader/config/project-templates/SUPERVISOR_MODE_TEMPLATE.md \
   ./claude_instructions.md

# Edit for this project
vim ./claude_instructions.md
```

**Now when you're in resolver:**
```bash
cd ~/projects/resolver
claude
> /rules
```

**Claude loads:**
1. Global rules from claude-config-loader
2. Project rules from ./claude_instructions.md
3. Shows BOTH (project rules take precedence)

---

## File Hierarchy (Priority Order)

When `/rules` is invoked:

1. **Highest priority:** `./claude_instructions.md` (current project)
2. **Medium priority:** `~/projects/claude-config-loader/config/rules/architecture.md`
3. **Lowest priority:** `~/projects/claude-config-loader/config/rules/global-rules.md`

Project-specific always wins.

---

## Quick Decision Guide

### "Where do I edit ports?"
→ `~/projects/claude-config-loader/config/ports.yaml`

### "Where do I edit servers?"
→ `~/projects/claude-config-loader/config/servers.yaml`

### "Where do I add project-specific rules?"
→ `~/projects/your-project/claude_instructions.md`

### "Where are the skills?"
→ Source: `~/projects/claude-config-loader/skills/`
→ Shortcuts: `~/.claude/skills/` (auto-created by install.sh)

### "Do I need to reinstall after editing config?"
→ **NO!** Changes are immediate.

### "Will skills work in all my projects?"
→ **YES!** That's the whole point.

---

## Summary: One Source of Truth

```
YOU EDIT HERE:
~/projects/claude-config-loader/config/

SHORTCUTS (auto-managed):
~/.claude/skills/ → points to claude-config-loader

PROJECT OVERRIDES (optional):
~/projects/each-project/claude_instructions.md

RESULT:
Skills work everywhere, config in one place, easy to maintain.
```

---

## Still Confused?

Think of it like this:

**claude-config-loader is a library.**
- You write config files in the library
- Install script creates shortcuts so Claude can find the library
- Skills are like functions that read from the library
- Works from anywhere because shortcuts are global

**You only edit ONE place:** `~/projects/claude-config-loader/config/`

Everything else is automatic.
