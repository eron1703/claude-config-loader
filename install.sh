#!/bin/bash

# Claude Config Loader - Installation Script
# Sets up hooks + skills system for Claude Code
# Run from any location: bash /path/to/claude-config-loader/install.sh

set -e

# Auto-detect the config loader directory from this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOADER_DIR="$SCRIPT_DIR"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude Config Loader..."
echo "  Source: $LOADER_DIR"
echo "  Target: $CLAUDE_DIR"
echo ""

# Save the config loader path for dynamic resolution by skills
echo "$LOADER_DIR" > "$CLAUDE_DIR/.config-loader-path"
echo "Saved config loader path to $CLAUDE_DIR/.config-loader-path"

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

# Install ALL skills as symlinks (use -n to prevent creating links inside existing dirs)
echo "Installing skills..."

# Clean any existing symlink artifacts first
for skill_dir in "$LOADER_DIR"/skills/*/; do
    skill_name=$(basename "$skill_dir")
    # Remove self-referencing symlinks created by previous ln -sf (without -n)
    rm -f "$skill_dir/$skill_name" 2>/dev/null
done

# Always-loaded (via hook)
ln -sfn "$LOADER_DIR/skills/core-rules"               "$CLAUDE_DIR/skills/core-rules"

# Supervisor skills
ln -sfn "$LOADER_DIR/skills/supervisor"                 "$CLAUDE_DIR/skills/supervisor"
ln -sfn "$LOADER_DIR/skills/supervisor-conversation"    "$CLAUDE_DIR/skills/supervisor-conversation"

# Worker skills
for WORKER_SKILL in worker-role worker-reporting worker-stuck-protocol \
    worker-role-coder worker-role-database worker-role-frontend worker-role-infra worker-role-tester \
    worker-ssh worker-gitlab worker-k8s worker-database worker-api-gateway worker-frontend worker-services; do
    if [ -d "$LOADER_DIR/skills/$WORKER_SKILL" ]; then
        ln -sfn "$LOADER_DIR/skills/$WORKER_SKILL" "$CLAUDE_DIR/skills/$WORKER_SKILL"
    fi
done

# Generic infrastructure (on-demand, all projects)
ln -sfn "$LOADER_DIR/skills/cicd"                      "$CLAUDE_DIR/skills/cicd"
ln -sfn "$LOADER_DIR/skills/credentials"               "$CLAUDE_DIR/skills/credentials"
ln -sfn "$LOADER_DIR/skills/databases"                  "$CLAUDE_DIR/skills/databases"
ln -sfn "$LOADER_DIR/skills/environment"                "$CLAUDE_DIR/skills/environment"
ln -sfn "$LOADER_DIR/skills/guidelines"                 "$CLAUDE_DIR/skills/guidelines"
ln -sfn "$LOADER_DIR/skills/ports"                      "$CLAUDE_DIR/skills/ports"
ln -sfn "$LOADER_DIR/skills/project"                    "$CLAUDE_DIR/skills/project"
ln -sfn "$LOADER_DIR/skills/remember"                   "$CLAUDE_DIR/skills/remember"
ln -sfn "$LOADER_DIR/skills/repos"                      "$CLAUDE_DIR/skills/repos"
ln -sfn "$LOADER_DIR/skills/save"                       "$CLAUDE_DIR/skills/save"
ln -sfn "$LOADER_DIR/skills/servers"                    "$CLAUDE_DIR/skills/servers"
ln -sfn "$LOADER_DIR/skills/testing"                    "$CLAUDE_DIR/skills/testing"

# Test-Rig-specific (on-demand, test-rig project only)
ln -sfn "$LOADER_DIR/skills/test-rig"                   "$CLAUDE_DIR/skills/test-rig"

# FlowMaster-specific (on-demand, flowmaster project only)
ln -sfn "$LOADER_DIR/skills/flowmaster-backend"         "$CLAUDE_DIR/skills/flowmaster-backend"
ln -sfn "$LOADER_DIR/skills/flowmaster-database"        "$CLAUDE_DIR/skills/flowmaster-database"
ln -sfn "$LOADER_DIR/skills/flowmaster-environment"     "$CLAUDE_DIR/skills/flowmaster-environment"
ln -sfn "$LOADER_DIR/skills/flowmaster-frontend"        "$CLAUDE_DIR/skills/flowmaster-frontend"
ln -sfn "$LOADER_DIR/skills/flowmaster-overview"        "$CLAUDE_DIR/skills/flowmaster-overview"
ln -sfn "$LOADER_DIR/skills/flowmaster-server"          "$CLAUDE_DIR/skills/flowmaster-server"
ln -sfn "$LOADER_DIR/skills/flowmaster-tools"           "$CLAUDE_DIR/skills/flowmaster-tools"

# Install hooks
echo "Installing hooks..."
cp "$LOADER_DIR/hooks/auto-load-config.sh"             "$CLAUDE_DIR/hooks/auto-load-config.sh"
cp "$LOADER_DIR/hooks/auto-sync-config.sh"             "$CLAUDE_DIR/hooks/auto-sync-config.sh"
cp "$LOADER_DIR/hooks/per-message-reminder.sh"         "$CLAUDE_DIR/hooks/per-message-reminder.sh"
chmod +x "$CLAUDE_DIR/hooks/auto-load-config.sh"
chmod +x "$CLAUDE_DIR/hooks/auto-sync-config.sh"
chmod +x "$CLAUDE_DIR/hooks/per-message-reminder.sh"

# Configure settings.json (preserve existing plugins if any)
# SessionStart: full skill load + sync
# UserPromptSubmit: lightweight reminder + sync (debounced)
LOAD_HOOK="$CLAUDE_DIR/hooks/auto-load-config.sh"
REMINDER_HOOK="$CLAUDE_DIR/hooks/per-message-reminder.sh"
SYNC_HOOK="$CLAUDE_DIR/hooks/auto-sync-config.sh"
echo "Configuring hooks..."

if command -v python3 &>/dev/null; then
    python3 -c "
import json, os
settings_path = '$CLAUDE_DIR/settings.json'
settings = {}
if os.path.exists(settings_path):
    with open(settings_path, 'r') as f:
        settings = json.load(f)
settings['hooks'] = {
    'SessionStart': [{'hooks': [
        {'type': 'command', 'command': '$LOAD_HOOK'},
        {'type': 'command', 'command': '$SYNC_HOOK'}
    ]}],
    'UserPromptSubmit': [{'hooks': [
        {'type': 'command', 'command': '$REMINDER_HOOK'},
        {'type': 'command', 'command': '$SYNC_HOOK'}
    ]}]
}
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
print('Updated settings.json (full load on SessionStart, lightweight reminder on UserPromptSubmit)')
"
else
    cat > "$CLAUDE_DIR/settings.json" << SETTINGSEOF
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "$LOAD_HOOK" },
          { "type": "command", "command": "$SYNC_HOOK" }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "$REMINDER_HOOK" },
          { "type": "command", "command": "$SYNC_HOOK" }
        ]
      }
    ]
  }
}
SETTINGSEOF
    echo "Created new settings.json"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Skills installed:"
ls -1 "$CLAUDE_DIR/skills/" | sed 's/^/  /'
echo ""
echo "Config loader path: $LOADER_DIR"
echo "Hooks:"
echo "  SessionStart  -> auto-load-config.sh (full skill loading, ~3KB)"
echo "  SessionStart  -> auto-sync-config.sh (git sync, debounced 30min)"
echo "  UserPromptSubmit -> per-message-reminder.sh (lightweight, ~200 bytes)"
echo "  UserPromptSubmit -> auto-sync-config.sh (git sync, debounced 30min)"
echo "Always loaded: core-rules, supervisor-methodology"
echo "On-demand: /ports /databases /repos /servers /cicd /project /credentials /save /guidelines /testing /environment"
echo "Test-Rig: test-rig (project development context)"
echo "FlowMaster: flowmaster-overview, flowmaster-backend, flowmaster-database, etc."
