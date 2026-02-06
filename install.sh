#!/bin/bash

# Claude Config Loader - Installation Script
# Run this to install skills and hook to your Claude Code environment

set -e  # Exit on error

echo "🚀 Installing Claude Config Loader..."
echo ""

# Create directories
echo "📁 Creating directories..."
mkdir -p ~/.claude/skills
mkdir -p ~/.claude/hooks

# Install skills (symlink for auto-sync)
echo "📦 Installing skills..."
ln -sf ~/projects/claude-config-loader/skills/ports ~/.claude/skills/ports
ln -sf ~/projects/claude-config-loader/skills/servers ~/.claude/skills/servers
ln -sf ~/projects/claude-config-loader/skills/databases ~/.claude/skills/databases
ln -sf ~/projects/claude-config-loader/skills/rules ~/.claude/skills/rules
ln -sf ~/projects/claude-config-loader/skills/repos ~/.claude/skills/repos
ln -sf ~/projects/claude-config-loader/skills/cicd ~/.claude/skills/cicd
ln -sf ~/projects/claude-config-loader/skills/project ~/.claude/skills/project
ln -sf ~/projects/claude-config-loader/skills/environment ~/.claude/skills/environment
ln -sf ~/projects/claude-config-loader/skills/remember ~/.claude/skills/remember

echo "✅ Skills installed:"
ls -la ~/.claude/skills/ | grep -E "ports|servers|databases|rules|repos|cicd|project|environment|remember"

# Install hook
echo ""
echo "🔗 Installing hook..."
ln -sf ~/projects/claude-config-loader/hooks/load-context.sh ~/.claude/hooks/load-context.sh
chmod +x ~/.claude/hooks/load-context.sh

# Configure settings.json
echo ""
echo "⚙️  Configuring settings..."

SETTINGS_FILE=~/.claude/settings.json

if [ -f "$SETTINGS_FILE" ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup"
    echo "📋 Backed up existing settings to ${SETTINGS_FILE}.backup"

    # Check if hooks already configured
    if grep -q "user-prompt-submit" "$SETTINGS_FILE"; then
        echo "⚠️  Hook already configured in settings.json"
        echo "   Manual action: Verify hook path in $SETTINGS_FILE"
    else
        # Add hook to settings
        # This is a simple approach - for complex JSON, use jq
        echo "   Adding hook to settings..."
        # Read current settings, add hooks
        python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)
settings['hooks'] = {'user-prompt-submit': '~/.claude/hooks/load-context.sh'}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
" 2>/dev/null || {
            echo "   ⚠️  Could not automatically add hook to settings"
            echo "   Manual action: Add the following to ~/.claude/settings.json:"
            echo '   "hooks": {'
            echo '     "user-prompt-submit": "~/.claude/hooks/load-context.sh"'
            echo '   }'
        }
    fi
else
    # Create new settings file
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "model": "sonnet",
  "hooks": {
    "user-prompt-submit": "~/.claude/hooks/load-context.sh"
  }
}
EOF
    echo "✅ Created new settings.json with hook configured"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "📚 Next steps:"
echo "   1. Customize config files in ~/projects/claude-config-loader/config/"
echo "   2. Test: claude (then try /ports)"
echo "   3. Read QUICKSTART.md for usage guide"
echo ""
echo "Available skills:"
echo "   /ports       - Port mappings"
echo "   /servers     - Server information"
echo "   /databases   - Database relationships"
echo "   /rules       - Development rules"
echo "   /repos       - Git repositories"
echo "   /cicd        - CI/CD configuration"
echo "   /project     - Current project info"
echo "   /environment - Dev environment (OrbStack, ~/projects/)"
echo "   /remember    - Save new information"
echo ""
echo "💡 Try: 'My GitLab repo is https://...' and Claude will offer to save it!"
echo ""
