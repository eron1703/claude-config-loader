#!/bin/bash

# Claude Config Loader - Startup Hook
# Runs on SessionStart and UserPromptSubmit
# Loads skills list + core behavioral rules on EVERY message

echo "[CONFIG] Global configuration loaded"
echo ""
echo "# Available Skills (MECE Structure)"
echo ""
echo "**Always Loaded:**"
echo "- core-rules (supervisor methodology, autonomous operation, communication, git safety, quality gates)"
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
echo "- flowmaster-backend - 22 microservices, APIs, endpoints"
echo "- flowmaster-database - ArangoDB schema, collections, relationships"
echo "- flowmaster-environment - Service env vars, ports, config"
echo "- flowmaster-frontend - UI components, patterns, integration"
echo "- flowmaster-server - Server infra, CI/CD, deployment"
echo "- flowmaster-tools - MCP tools, integrations, SDX pillars"
echo ""
echo "---"
echo ""

# Load always-on skills
for SKILL_NAME in core-rules supervisor-methodology; do
    SKILL_FILE=~/.claude/skills/$SKILL_NAME/SKILL.md
    if [ -f "$SKILL_FILE" ]; then
        cat "$SKILL_FILE"
    fi
done

echo ""
echo "**ENFORCEMENT: Supervisor methodology + granular component planning ACTIVE. Confirm compliance in every response.**"
