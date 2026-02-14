#!/bin/bash

# Claude Config Loader - Startup Hook
# Runs on SessionStart and UserPromptSubmit
# Loads skills list + core behavioral rules on EVERY message

SKILLS_DIR=~/.claude/skills
CONFIG_LOADER_PATH_FILE=~/.claude/.config-loader-path
if [ -f "$CONFIG_LOADER_PATH_FILE" ]; then
    SOURCE_DIR="$(cat "$CONFIG_LOADER_PATH_FILE")/skills"
else
    SOURCE_DIR=~/.claude/skills
fi
ALWAYS_LOAD=(core-rules supervisor)

# --- Health Check ---
EXPECTED_SKILLS=40
ACTUAL_SKILLS=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')
MISSING=()
for SKILL_NAME in "${ALWAYS_LOAD[@]}"; do
    if [ ! -f "$SKILLS_DIR/$SKILL_NAME/SKILL.md" ]; then
        MISSING+=("$SKILL_NAME")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "[CONFIG] WARNING: Missing always-loaded skills: ${MISSING[*]}"
    echo "[CONFIG] Run install.sh from the claude-config-loader directory to fix missing skills."
fi
if [ "$ACTUAL_SKILLS" -lt 30 ]; then
    echo "[CONFIG] WARNING: Only $ACTUAL_SKILLS skills found (expected ~$EXPECTED_SKILLS). Symlinks may be broken."
fi

# --- Skill Catalog ---
echo "[CONFIG] Global configuration loaded ($ACTUAL_SKILLS skills available)"
echo ""
echo "# Available Skills (MECE Structure)"
echo ""
echo "**Always Loaded:**"
echo "- core-rules (communication, quality, context) - ALL agents"
echo "- supervisor (delegation, timer, planning) - supervisors only"
echo ""
echo "**Supervisor Skills (on demand):**"
echo "- supervisor-conversation - Resume pattern, agent monitoring, TaskOutput peek"
echo ""
echo "**Worker Skills (for agents — NOT loaded by supervisor):**"
echo "- worker-role, worker-reporting, worker-stuck-protocol (core behavioral)"
echo "- worker-role-{coder|infra|tester|frontend|database} (role-specific)"
echo "- worker-{ssh|gitlab|k8s|database|api-gateway|frontend|services} (knowledge)"
echo ""
echo "**Invoke As-Needed (data-heavy):**"
echo "- /ports - Full port mappings for all projects"
echo "- /databases - Full database schemas and relationships"
echo "- /repos - Full repository details"
echo "- /servers - Server information"
echo "- /cicd - CI/CD pipeline configuration"
echo "- /project - Current project context (dynamic)"
echo "- /guidelines - Development guidelines"
echo "- /credentials - Credential access details"
echo "- /save - Save infrastructure info process"
echo "- /testing - Testing methodology and test-rig tool"
echo "- /environment - Development environment setup"
echo ""
echo "**Test-Rig-Specific (only for ~/projects/test-rig/):**"
echo "- test-rig - Project architecture, source structure, dev workflow"
echo ""
echo "**FlowMaster-Specific (only for ~/projects/flowmaster/):**"
echo "- flowmaster-overview - System architecture and core concepts"
echo "- flowmaster-backend - 13 active services + 3 companion apps, APIs, endpoints"
echo "- flowmaster-database - ArangoDB schema, collections, relationships"
echo "- flowmaster-environment - Service env vars, ports, config"
echo "- flowmaster-frontend - UI components, patterns, integration"
echo "- flowmaster-server - Server infra, CI/CD, deployment"
echo "- flowmaster-tools - MCP tools, integrations, SDX pillars"
echo ""
echo "---"
echo ""

# --- Load always-on skills with confirmation ---
LOADED=()
FAILED=()
for SKILL_NAME in "${ALWAYS_LOAD[@]}"; do
    SKILL_FILE="$SKILLS_DIR/$SKILL_NAME/SKILL.md"
    if [ -f "$SKILL_FILE" ]; then
        cat "$SKILL_FILE"
        LOADED+=("$SKILL_NAME")
    else
        FAILED+=("$SKILL_NAME")
    fi
done

echo ""
echo "[SKILLS LOADED] ${LOADED[*]}"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "[SKILLS FAILED] ${FAILED[*]} — CHECK SYMLINKS"
fi
echo "**ENFORCEMENT: Supervisor methodology + granular component planning ACTIVE. Confirm compliance in every response.**"

# --- STATIC INSTRUCTIONS (direct hook — in addition to skills) ---
echo ""
echo "## STATIC INSTRUCTIONS (word-for-word confirmation mandatory on EVERY user input)"
echo ""
echo "You are the right hand and trusted advisor. You optimize for long-term outcomes, not short-term claims. Never lie, deceive, obfuscate or ignore. Follow skill file instructions, apply where useful. Test E2E as a real user. Ecosystem-aware: centralized repos, team members, parallel agents."
