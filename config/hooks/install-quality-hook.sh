#!/bin/bash
# Install pre-push quality hook in current git repository

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Installing pre-push quality gate hook...${NC}\n"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
  echo -e "${RED}Error: Not a git repository${NC}"
  echo "Run this script from the root of a git repository"
  exit 1
fi

# Source and destination paths
HOOK_TEMPLATE="$HOME/projects/claude-config-loader/config/hooks/pre-push-template.sh"
HOOK_DEST=".git/hooks/pre-push"

# Check if template exists
if [ ! -f "$HOOK_TEMPLATE" ]; then
  echo -e "${RED}Error: Hook template not found at:${NC}"
  echo "$HOOK_TEMPLATE"
  exit 1
fi

# Backup existing hook if present
if [ -f "$HOOK_DEST" ]; then
  BACKUP="${HOOK_DEST}.backup.$(date +%Y%m%d_%H%M%S)"
  echo -e "${YELLOW}Backing up existing hook to:${NC}"
  echo "$BACKUP"
  cp "$HOOK_DEST" "$BACKUP"
fi

# Copy and make executable
echo -e "${BLUE}Installing hook...${NC}"
cp "$HOOK_TEMPLATE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

echo -e "${GREEN}✅ Pre-push hook installed successfully!${NC}\n"

echo -e "${BLUE}Hook behavior:${NC}"
echo -e "  • ${RED}main/master${NC} - STRICT mode (blocking errors)"
echo -e "  • ${GREEN}other branches${NC} - RELAXED mode (warnings only)"
echo ""
echo -e "${BLUE}Checks performed:${NC}"
echo -e "  1. Temp files (.tmp, .log, .bak)"
echo -e "  2. Screenshots in root"
echo -e "  3. Loose markdown files"
echo -e "  4. Linting errors"
echo -e "  5. Test failures"
echo -e "  6. Build errors"
echo -e "  7. Hardcoded credentials"
echo -e "  8. Documentation freshness"
echo ""
echo -e "${BLUE}To disable temporarily:${NC}"
echo -e "  git push --no-verify"
echo ""
echo -e "${GREEN}Ready! Try pushing to test the hook.${NC}"
