#!/bin/bash
# Pre-push quality gate hook
# Copy to .git/hooks/pre-push and chmod +x

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Running pre-push quality checks...${NC}\n"

# Get current branch and remote
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")

echo -e "Branch: ${BLUE}$CURRENT_BRANCH${NC}"

# Determine if pushing to main/master
STRICT_MODE=false
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  STRICT_MODE=true
  echo -e "Mode: ${RED}STRICT${NC} (production branch)\n"
else
  echo -e "Mode: ${GREEN}RELAXED${NC} (development branch)\n"
fi

# Initialize error tracking
ERRORS=0
WARNINGS=0

# ============================================================================
# STRICT MODE CHECKS (BLOCKING)
# ============================================================================

if [ "$STRICT_MODE" = true ]; then
  echo -e "${RED}═══════════════════════════════════════${NC}"
  echo -e "${RED}  STRICT MODE: All checks must pass   ${NC}"
  echo -e "${RED}═══════════════════════════════════════${NC}\n"

  # 1. Check for temp files
  echo -e "${BLUE}[1/8]${NC} Checking for temp files..."
  TEMP_FILES=$(find . -type f \( -name "*.tmp" -o -name "*.log" -o -name "*.bak" \) ! -path "./node_modules/*" ! -path "./dist/*" ! -path "./.git/*" 2>/dev/null || true)
  if [ -n "$TEMP_FILES" ]; then
    echo -e "${RED}❌ FAIL: Temp files found:${NC}"
    echo "$TEMP_FILES"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "${GREEN}✓ Pass${NC}"
  fi

  # 2. Check for screenshots in root
  echo -e "${BLUE}[2/8]${NC} Checking for screenshots in root..."
  ROOT_IMAGES=$(ls *.png *.jpg *.jpeg *.gif 2>/dev/null || true)
  if [ -n "$ROOT_IMAGES" ]; then
    echo -e "${RED}❌ FAIL: Screenshots in root. Move to docs/:${NC}"
    echo "$ROOT_IMAGES"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "${GREEN}✓ Pass${NC}"
  fi

  # 3. Check for loose markdown files
  echo -e "${BLUE}[3/8]${NC} Checking for loose markdown files..."
  ALLOWED_MD="README.md CHANGELOG.md CLAUDE.md claude_instructions.md"
  LOOSE_MD=$(ls *.md 2>/dev/null | grep -v -E "^(README|CHANGELOG|CLAUDE|claude_instructions)\.md$" || true)
  if [ -n "$LOOSE_MD" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Loose markdown files found:${NC}"
    echo "$LOOSE_MD"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${GREEN}✓ Pass${NC}"
  fi

  # 4. Run linting
  echo -e "${BLUE}[4/8]${NC} Running linting..."
  if [ -f "package.json" ] && grep -q "\"lint\"" package.json; then
    if npm run lint > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${RED}❌ FAIL: Linting errors found${NC}"
      npm run lint
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  Skipped (no lint script)${NC}"
  fi

  # 5. Run tests
  echo -e "${BLUE}[5/8]${NC} Running tests..."
  if [ -f "package.json" ] && grep -q "\"test\"" package.json; then
    if npm test > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${RED}❌ FAIL: Tests failing${NC}"
      npm test
      ERRORS=$((ERRORS + 1))
    fi
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    if pytest > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${RED}❌ FAIL: Tests failing${NC}"
      pytest
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  Skipped (no test configuration)${NC}"
  fi

  # 6. Run build
  echo -e "${BLUE}[6/8]${NC} Running build..."
  if [ -f "package.json" ] && grep -q "\"build\"" package.json; then
    if npm run build > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${RED}❌ FAIL: Build errors${NC}"
      npm run build
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  Skipped (no build script)${NC}"
  fi

  # 7. Check for hardcoded credentials
  echo -e "${BLUE}[7/8]${NC} Scanning for hardcoded credentials..."
  CREDENTIAL_PATTERNS=(
    "password.*=.*['\"]"
    "api_key.*=.*['\"]"
    "secret.*=.*['\"]"
    "token.*=.*['\"]"
    "bearer [a-zA-Z0-9_-]{20,}"
  )
  CREDENTIAL_FOUND=false
  for pattern in "${CREDENTIAL_PATTERNS[@]}"; do
    if git diff origin/main...HEAD | grep -iE "$pattern" | grep -v "example" > /dev/null 2>&1; then
      if [ "$CREDENTIAL_FOUND" = false ]; then
        echo -e "${RED}❌ FAIL: Potential hardcoded credentials found${NC}"
        CREDENTIAL_FOUND=true
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
  if [ "$CREDENTIAL_FOUND" = false ]; then
    echo -e "${GREEN}✓ Pass${NC}"
  fi

  # 8. Check documentation freshness
  echo -e "${BLUE}[8/8]${NC} Checking documentation freshness..."
  CODE_CHANGED=$(git diff origin/main...HEAD --name-only | grep -E "^src/|^lib/" || true)
  DOCS_CHANGED=$(git diff origin/main...HEAD --name-only | grep -E "^docs/|^README" || true)

  if [ -n "$CODE_CHANGED" ] && [ -z "$DOCS_CHANGED" ]; then
    echo -e "${YELLOW}⚠️  WARNING: Code changed but documentation not updated${NC}"
    echo -e "Consider updating:"
    echo -e "  • README.md (if features changed)"
    echo -e "  • docs/ARCHITECTURE.md (if structure changed)"
    echo -e "  • docs/API.md (if endpoints changed)"
    echo -e "  • docs/DEVELOPER.md (if setup changed)"
    WARNINGS=$((WARNINGS + 1))

    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${RED}Push cancelled. Update documentation first.${NC}"
      exit 1
    fi
  else
    echo -e "${GREEN}✓ Pass${NC}"
  fi

  # Summary
  echo -e "\n${RED}═══════════════════════════════════════${NC}"
  if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All strict checks passed!${NC}"
    if [ $WARNINGS -gt 0 ]; then
      echo -e "${YELLOW}⚠️  $WARNINGS warning(s) - review recommended${NC}"
    fi
    echo -e "${GREEN}Proceeding with push to $CURRENT_BRANCH${NC}"
    exit 0
  else
    echo -e "${RED}❌ $ERRORS check(s) failed${NC}"
    echo -e "${RED}Fix errors before pushing to $CURRENT_BRANCH${NC}"
    exit 1
  fi

# ============================================================================
# RELAXED MODE CHECKS (NON-BLOCKING)
# ============================================================================

else
  echo -e "${GREEN}═══════════════════════════════════════${NC}"
  echo -e "${GREEN}  RELAXED MODE: Warnings only         ${NC}"
  echo -e "${GREEN}═══════════════════════════════════════${NC}\n"

  # 1. Check for temp files (warning only)
  echo -e "${BLUE}[1/5]${NC} Checking for temp files..."
  TEMP_FILES=$(find . -type f \( -name "*.tmp" -o -name "*.log" -o -name "*.bak" \) ! -path "./node_modules/*" ! -path "./dist/*" ! -path "./.git/*" 2>/dev/null || true)
  if [ -n "$TEMP_FILES" ]; then
    echo -e "${YELLOW}⚠️  Temp files found (clean up before merging to main)${NC}"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${GREEN}✓ Clean${NC}"
  fi

  # 2. Run linting (warning only)
  echo -e "${BLUE}[2/5]${NC} Running linting..."
  if [ -f "package.json" ] && grep -q "\"lint\"" package.json; then
    if npm run lint > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${YELLOW}⚠️  Linting errors found (fix before merging to main)${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  Skipped${NC}"
  fi

  # 3. Run tests (warning only)
  echo -e "${BLUE}[3/5]${NC} Running tests..."
  if [ -f "package.json" ] && grep -q "\"test\"" package.json; then
    if npm test > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${YELLOW}⚠️  Tests failing (fix before merging to main)${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  Skipped${NC}"
  fi

  # 4. Run build (warning only)
  echo -e "${BLUE}[4/5]${NC} Running build..."
  if [ -f "package.json" ] && grep -q "\"build\"" package.json; then
    if npm run build > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Pass${NC}"
    else
      echo -e "${YELLOW}⚠️  Build errors (fix before merging to main)${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  Skipped${NC}"
  fi

  # 5. Check documentation
  echo -e "${BLUE}[5/5]${NC} Checking documentation..."
  CODE_CHANGED=$(git diff origin/$CURRENT_BRANCH...HEAD --name-only 2>/dev/null | grep -E "^src/|^lib/" || true)
  if [ -n "$CODE_CHANGED" ]; then
    echo -e "${YELLOW}⚠️  Code changed - consider updating docs before merging${NC}"
    WARNINGS=$((WARNINGS + 1))
  else
    echo -e "${GREEN}✓ OK${NC}"
  fi

  # Summary
  echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Push proceeding (dev branch)${NC}"
  if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) - address before merging to main${NC}"
  fi
  exit 0
fi
