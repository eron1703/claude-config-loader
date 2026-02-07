#!/bin/bash

# Claude Config Loader - Installation Script
# Sets up hooks + skills system for Claude Code
# Run: bash ~/projects/claude-config-loader/install.sh

set -e

LOADER_DIR=~/projects/claude-config-loader
CLAUDE_DIR=~/.claude

echo "Installing Claude Config Loader..."
echo ""

# Create directories
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/hooks"

# Remove old standalone .md files (replaced by skills)
echo "Cleaning old standalone files..."
rm -f "$CLAUDE_DIR/skills/core-development-rules.md"
rm -f "$CLAUDE_DIR/skills/core-rules.md"
rm -f "$CLAUDE_DIR/skills/testing-methodology.md"
rm -f "$CLAUDE_DIR/skills/container-operations.md"
rm -f "$CLAUDE_DIR/skills/stack-architecture.md"
rm -f "$CLAUDE_DIR/skills/git-repositories.md"
rm -f "$CLAUDE_DIR/skills/database-configuration.md"
rm -f "$CLAUDE_DIR/skills/infrastructure-deployment.md"
rm -f "$CLAUDE_DIR/skills/credential-access.md"
rm -f "$CLAUDE_DIR/skills/save-infrastructure-info.md"
rm -f "$CLAUDE_DIR/skills/git-workflow.md"
rm -f "$CLAUDE_DIR/skills/current-project-context.md"

# Install ALL skills as symlinks
echo "Installing skills..."

# Always-loaded (via hook)
ln -sf "$LOADER_DIR/skills/core-rules"               "$CLAUDE_DIR/skills/core-rules"

# Generic infrastructure (on-demand, all projects)
ln -sf "$LOADER_DIR/skills/cicd"                      "$CLAUDE_DIR/skills/cicd"
ln -sf "$LOADER_DIR/skills/credentials"               "$CLAUDE_DIR/skills/credentials"
ln -sf "$LOADER_DIR/skills/databases"                  "$CLAUDE_DIR/skills/databases"
ln -sf "$LOADER_DIR/skills/environment"                "$CLAUDE_DIR/skills/environment"
ln -sf "$LOADER_DIR/skills/guidelines"                 "$CLAUDE_DIR/skills/guidelines"
ln -sf "$LOADER_DIR/skills/ports"                      "$CLAUDE_DIR/skills/ports"
ln -sf "$LOADER_DIR/skills/project"                    "$CLAUDE_DIR/skills/project"
ln -sf "$LOADER_DIR/skills/repos"                      "$CLAUDE_DIR/skills/repos"
ln -sf "$LOADER_DIR/skills/save"                       "$CLAUDE_DIR/skills/save"
ln -sf "$LOADER_DIR/skills/servers"                    "$CLAUDE_DIR/skills/servers"
ln -sf "$LOADER_DIR/skills/testing"                    "$CLAUDE_DIR/skills/testing"

# Test-Rig-specific (on-demand, test-rig project only)
ln -sf "$LOADER_DIR/skills/test-rig"                    "$CLAUDE_DIR/skills/test-rig"

# FlowMaster-specific (on-demand, flowmaster project only)
ln -sf "$LOADER_DIR/skills/flowmaster-backend"         "$CLAUDE_DIR/skills/flowmaster-backend"
ln -sf "$LOADER_DIR/skills/flowmaster-database"        "$CLAUDE_DIR/skills/flowmaster-database"
ln -sf "$LOADER_DIR/skills/flowmaster-environment"     "$CLAUDE_DIR/skills/flowmaster-environment"
ln -sf "$LOADER_DIR/skills/flowmaster-frontend"        "$CLAUDE_DIR/skills/flowmaster-frontend"
ln -sf "$LOADER_DIR/skills/flowmaster-overview"        "$CLAUDE_DIR/skills/flowmaster-overview"
ln -sf "$LOADER_DIR/skills/flowmaster-server"          "$CLAUDE_DIR/skills/flowmaster-server"
ln -sf "$LOADER_DIR/skills/flowmaster-tools"           "$CLAUDE_DIR/skills/flowmaster-tools"

# Install hook
echo "Installing hook..."
cp "$LOADER_DIR/config/hooks/auto-load-config.sh"      "$CLAUDE_DIR/hooks/auto-load-config.sh"
chmod +x "$CLAUDE_DIR/hooks/auto-load-config.sh"

# Configure settings.json
echo "Configuring hooks..."
cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/benjaminhippler/.claude/hooks/auto-load-config.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/Users/benjaminhippler/.claude/hooks/auto-load-config.sh"
          }
        ]
      }
    ]
  }
}
EOF

echo ""
echo "Installation complete!"
echo ""
echo "Skills installed:"
ls -1 "$CLAUDE_DIR/skills/" | sed 's/^/  /'
echo ""
echo "Hook: SessionStart + UserPromptSubmit -> auto-load-config.sh"
echo "Always loaded: core-rules"
echo "On-demand: /ports /databases /repos /servers /cicd /project /credentials /save /guidelines /testing /environment"
echo "Test-Rig: test-rig (project development context)"
echo "FlowMaster: flowmaster-overview, flowmaster-backend, flowmaster-database, etc."
