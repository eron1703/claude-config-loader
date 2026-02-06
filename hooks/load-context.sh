#!/bin/bash

# Claude Config Loader Hook
# This runs on every user command to remind Claude about available skills
# Token cost: ~100 tokens per command

cat << 'EOF'
📋 Configuration Skills Available:
• /ports       - Port mappings for all projects
• /servers     - Server list and infrastructure
• /databases   - Database relationships and schemas
• /rules       - Development rules and guidelines
• /repos       - GitHub/GitLab repositories
• /cicd        - CI/CD pipeline configuration
• /project     - Current project information
• /environment - Dev environment (OrbStack, ~/projects/, etc.)
• /remember    - Save new information to config

💡 When I provide new infrastructure info, offer to /remember it!
⚠️  NEVER shut down Docker/OrbStack service (multi-user environment)
EOF
