#!/bin/bash

# Lightweight per-message reminder (~200 tokens vs ~3000 for full load)
# Core rules summary only - full skills loaded on SessionStart

SKILLS_DIR=~/.claude/skills
ACTUAL_SKILLS=$(ls -d "$SKILLS_DIR"/*/ 2>/dev/null | wc -l | tr -d ' ')

cat << 'EOF'
[REMINDER] core-rules + supervisor active. Test before claiming. Evidence required. Use /slash-commands to load skills on demand.
Telemetry: http://65.21.153.235:8099 — /push, /wait, /ack, /queue, /files. Process events: control > task > chat > telemetry > file.
EOF
