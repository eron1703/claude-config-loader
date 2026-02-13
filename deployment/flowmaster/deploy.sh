#!/usr/bin/env bash
#
# FlowMaster Dev Server Deployment Script
# Usage: ./deploy.sh <server-alias> [--dry-run] [--branch <branch>]
#
# Server mapping:
#   dev-01 -> 65.21.153.235 (Helsinki)    -> develop branch
#   dev-02 -> 91.98.159.56  (Falkenstein) -> staging branch
#   dev-03 -> 65.21.52.58   (Helsinki)    -> feature/* branches
#
# This script does NOT auto-execute. It requires explicit invocation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
BRANCH_OVERRIDE=""
DEPLOY_PATH="/opt/flowmaster"
COMPOSE_FILE="docker-compose.dev.yml"

# --- Color output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --- Server configuration ---
declare -A SERVER_IPS=(
    [dev-01]="65.21.153.235"
    [dev-02]="91.98.159.56"
    [dev-03]="65.21.52.58"
)

declare -A SERVER_BRANCHES=(
    [dev-01]="develop"
    [dev-02]="staging"
    [dev-03]=""  # feature/* - must be specified via --branch
)

declare -A SERVER_SSH_KEYS=(
    [dev-01]="~/.ssh/demo_server"
    [dev-02]="~/.ssh/id_rsa"
    [dev-03]="~/.ssh/demo_server"
)

declare -A SERVER_SSH_USERS=(
    [dev-01]="root"
    [dev-02]="root"
    [dev-03]="root"
)

# --- Usage ---
usage() {
    cat <<EOF
FlowMaster Dev Server Deployment

Usage: $(basename "$0") <server> [options]

Servers:
  dev-01    Helsinki (65.21.153.235)     develop branch
  dev-02    Falkenstein (91.98.159.56)   staging branch
  dev-03    Helsinki (65.21.52.58)       feature/* branches

Options:
  --dry-run           Show what would be done without executing
  --branch <branch>   Override default branch (required for dev-03)
  --help              Show this help message

Examples:
  $(basename "$0") dev-01                    # Deploy develop to dev-01
  $(basename "$0") dev-02 --dry-run          # Dry run staging on dev-02
  $(basename "$0") dev-03 --branch feature/auth   # Deploy feature branch to dev-03

EOF
    exit 0
}

# --- Parse arguments ---
SERVER=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        dev-01|dev-02|dev-03)
            SERVER="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --branch)
            BRANCH_OVERRIDE="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            ;;
    esac
done

# --- Validate ---
if [[ -z "$SERVER" ]]; then
    log_error "Server alias is required (dev-01, dev-02, dev-03)"
    usage
fi

SERVER_IP="${SERVER_IPS[$SERVER]}"
SSH_KEY="${SERVER_SSH_KEYS[$SERVER]}"
SSH_USER="${SERVER_SSH_USERS[$SERVER]}"
BRANCH="${BRANCH_OVERRIDE:-${SERVER_BRANCHES[$SERVER]}}"

if [[ -z "$BRANCH" ]]; then
    log_error "dev-03 requires --branch <branch> (e.g., --branch feature/auth)"
    exit 1
fi

ENV_FILE="${SCRIPT_DIR}/.env.${SERVER}"
if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Environment file not found: $ENV_FILE"
    exit 1
fi

# --- Summary ---
echo ""
echo "============================================"
echo "  FlowMaster Deployment"
echo "============================================"
echo "  Server:    $SERVER ($SERVER_IP)"
echo "  Branch:    $BRANCH"
echo "  Env file:  $ENV_FILE"
echo "  Path:      $DEPLOY_PATH"
echo "  Dry run:   $DRY_RUN"
echo "============================================"
echo ""

if $DRY_RUN; then
    log_warn "DRY RUN MODE - No changes will be made"
    echo ""
fi

# --- SSH helper ---
ssh_cmd() {
    local cmd="$1"
    if $DRY_RUN; then
        log_info "[DRY RUN] ssh ${SSH_USER}@${SERVER_IP}: $cmd"
    else
        ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" "$cmd"
    fi
}

# --- Step 1: Verify server connectivity ---
log_info "Step 1: Verifying connectivity to $SERVER..."
if ! $DRY_RUN; then
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${SSH_USER}@${SERVER_IP}" "echo ok" > /dev/null 2>&1; then
        log_ok "Connected to $SERVER"
    else
        log_error "Cannot connect to $SERVER ($SERVER_IP)"
        exit 1
    fi
else
    log_info "[DRY RUN] Would verify SSH connectivity"
fi

# --- Step 2: Ensure deploy directory exists ---
log_info "Step 2: Ensuring deploy directory exists..."
ssh_cmd "mkdir -p ${DEPLOY_PATH}"

# --- Step 3: Pull latest code ---
log_info "Step 3: Pulling latest code (branch: $BRANCH)..."
ssh_cmd "
    cd ${DEPLOY_PATH} && \
    if [ -d .git ]; then
        git fetch --all && \
        git checkout ${BRANCH} && \
        git pull origin ${BRANCH}
    else
        echo 'ERROR: Git repository not found at ${DEPLOY_PATH}'
        echo 'Please clone the repository first:'
        echo '  git clone <repo-url> ${DEPLOY_PATH}'
        exit 1
    fi
"

# --- Step 4: Copy env file and compose overlay ---
log_info "Step 4: Uploading configuration files..."
if $DRY_RUN; then
    log_info "[DRY RUN] Would SCP: $ENV_FILE -> ${DEPLOY_PATH}/.env"
    log_info "[DRY RUN] Would SCP: ${SCRIPT_DIR}/${COMPOSE_FILE} -> ${DEPLOY_PATH}/${COMPOSE_FILE}"
else
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$ENV_FILE" "${SSH_USER}@${SERVER_IP}:${DEPLOY_PATH}/.env"
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SCRIPT_DIR}/${COMPOSE_FILE}" "${SSH_USER}@${SERVER_IP}:${DEPLOY_PATH}/${COMPOSE_FILE}"
    log_ok "Configuration files uploaded"
fi

# --- Step 5: Docker compose up ---
log_info "Step 5: Starting services with docker compose..."
ssh_cmd "
    cd ${DEPLOY_PATH} && \
    docker compose -f docker-compose.dev.yml --env-file .env pull && \
    docker compose -f docker-compose.dev.yml --env-file .env up -d
"

# --- Step 6: Wait for health checks ---
log_info "Step 6: Waiting for services to become healthy..."
if ! $DRY_RUN; then
    SERVICES=("frontend" "backend" "arangodb" "postgres" "redis")
    MAX_WAIT=120
    INTERVAL=10

    for svc in "${SERVICES[@]}"; do
        CONTAINER="flowmaster-${svc}-${SERVER}"
        log_info "  Checking $CONTAINER..."
        ELAPSED=0
        while [[ $ELAPSED -lt $MAX_WAIT ]]; do
            STATUS=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SSH_USER}@${SERVER_IP}" \
                "docker inspect --format='{{.State.Health.Status}}' ${CONTAINER} 2>/dev/null || echo 'not_found'")
            if [[ "$STATUS" == "healthy" ]]; then
                log_ok "  $CONTAINER is healthy"
                break
            fi
            sleep $INTERVAL
            ELAPSED=$((ELAPSED + INTERVAL))
        done
        if [[ $ELAPSED -ge $MAX_WAIT ]]; then
            log_warn "  $CONTAINER did not become healthy within ${MAX_WAIT}s (status: $STATUS)"
        fi
    done
else
    log_info "[DRY RUN] Would wait for health checks on all 5 services"
fi

# --- Step 7: Final status ---
log_info "Step 7: Final service status..."
ssh_cmd "docker ps --filter 'name=flowmaster-' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

echo ""
echo "============================================"
if $DRY_RUN; then
    log_warn "DRY RUN COMPLETE - No changes were made"
else
    log_ok "Deployment to $SERVER complete"
    echo ""
    echo "  Frontend:  http://${SERVER_IP}:3000"
    echo "  Backend:   http://${SERVER_IP}:8000"
    echo "  ArangoDB:  http://${SERVER_IP}:8529"
fi
echo "============================================"
