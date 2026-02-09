#!/bin/bash

# Claude Config Loader - Auto Sync Hook
# Debounced: only runs git operations if >30 min since last sync
# Registered on SessionStart + UserPromptSubmit
# - Commits any uncommitted changes
# - Pushes to all remotes
# - Pulls latest from origin

CONFIG_LOADER_PATH_FILE=~/.claude/.config-loader-path
LAST_SYNC_FILE=~/.claude/.last-config-sync
SYNC_INTERVAL=1800  # 30 minutes in seconds

# Skip if config loader not installed
if [ ! -f "$CONFIG_LOADER_PATH_FILE" ]; then
    exit 0
fi

CONFIG_DIR="$(cat "$CONFIG_LOADER_PATH_FILE")"
if [ ! -d "$CONFIG_DIR/.git" ]; then
    exit 0
fi

# Debounce: check if enough time has passed
if [ -f "$LAST_SYNC_FILE" ]; then
    last_sync=$(cat "$LAST_SYNC_FILE")
    now=$(date +%s)
    elapsed=$((now - last_sync))
    if [ "$elapsed" -lt "$SYNC_INTERVAL" ]; then
        exit 0
    fi
fi

# --- Perform sync ---
cd "$CONFIG_DIR" || exit 0
ACTIONS=""

# 1. Commit any uncommitted changes
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git add -A 2>/dev/null
    git commit -m "auto-sync: config updates $(date '+%Y-%m-%d %H:%M')" --quiet 2>/dev/null
    ACTIONS="committed"
fi

# 2. Push to all remotes
for remote in $(git remote 2>/dev/null); do
    git push "$remote" main --quiet 2>/dev/null
done
if [ -n "$ACTIONS" ]; then
    ACTIONS="$ACTIONS + pushed"
fi

# 3. Pull latest from origin
pull_output=$(git pull origin main --quiet --no-edit 2>&1)
if [ $? -eq 0 ]; then
    if echo "$pull_output" | grep -q "Already up to date"; then
        : # No new changes
    elif [ -z "$ACTIONS" ]; then
        ACTIONS="pulled new changes"
    else
        ACTIONS="$ACTIONS + pulled"
    fi
fi

# Update timestamp
date +%s > "$LAST_SYNC_FILE"

# Report (brief, only if something happened)
if [ -n "$ACTIONS" ]; then
    echo "[CONFIG-SYNC] $ACTIONS"
fi
