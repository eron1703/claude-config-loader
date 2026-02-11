# Agent Task Handover Summary

**Date:** 2026-02-11 ~16:00 Dubai Time
**From:** Supervisor Agent (local macOS terminal)
**To:** zappy-ibex (next supervisor)
**Status:** ACTIVE SESSION — 3 agents running on demo-server

---

## Current State

### Server: demo-server-001 (65.21.153.235)

- **RAM:** ~3GB available of 15GB (12GB used)
- **K3s:** Running, healthy
- **HPA:** Patched to max 3 replicas (was 8, caused OOM/API timeouts)
- **Pods:** 3 claude-pods + 1 litellm-proxy + 1 litellm-redis

### Active Agents (tmux sessions on demo-server)

| Agent | tmux | Pod | Mission | Status |
|-------|------|-----|---------|--------|
| agent1 | `agent1` | `claude-pod-5b8df6d4f-6cl5w` | Grafana dashboard fix | **STUCK** - "Not logged in" error. Pod restarted 3x. Needs troubleshooting. |
| agent2 | `agent2` | `claude-pod-5b8df6d4f-7dc7k` | R45-R47 Agent Learning Pipeline | Mission submitted, should be starting |
| agent3 | `agent3` | `claude-pod-5b8df6d4f-2bdkn` | R48-R50 Process Analytics Service | **ACTIVE** - working ("checking full deployment spec", 4min in) |

### How to Connect to Agents

```bash
# SSH to demo-server
ssh -p 22 demo-server-root

# Attach to agent tmux sessions
tmux attach -t agent1
tmux attach -t agent2
tmux attach -t agent3

# Detach from tmux: Ctrl+B then D

# Check all sessions
tmux list-sessions

# Check agent screen without attaching
tmux capture-pane -t agent1 -p | tail -20
```

### How to Connect to a Pod Directly

```bash
kubectl exec -it -n claude-pod <pod-name> -- bash --norc
# Then run: claude
```

---

## Plane Board Status

**Backlog=6 | InProgress=0 | Done=178 | Total=184**

| # | Issue | ID | Status |
|---|-------|----|--------|
| 14 | R54-R56: FlowMaster MCP Server | `fc1b1dd5` | Backlog - unassigned |
| 12 | R48-R50: Process Analytics Service | `7cff2eab` | Backlog - agent3 working on it (not yet moved to InProgress in Plane) |
| 11 | R45-R47: Agent Learning Pipeline | `d4043f85` | Backlog - agent2 assigned |
| 9 | R39-R41: Prompt Engineering Service | `e46b5fd5` | Backlog - unassigned |
| 6 | R30-R33: Manager App | `5ec9c82d` | Backlog - unassigned |
| 5 | R27-R29: Engage App Analytics + Briefing | `57926725` | Backlog - unassigned |

### Plane API Quick Reference

```bash
# List issues
curl -s -H "X-API-Key: plane_api_bb5d084bdaae44c4b4610965fcfc0600" \
  "http://65.21.153.235:8083/api/v1/workspaces/flowmaster/projects/4704cb6d-9577-4761-b173-8a2bb279d00d/issues/?per_page=200"

# State IDs
# Backlog: 079e8734-fba6-4bc4-8cf7-807b465408b6
# InProgress: 7c3c1ad1-8692-4947-859c-721fa17fe06c
# Done: bd7b2b26-a29a-410e-94be-ae87299ca4b5

# Move issue to InProgress
curl -s -X PATCH -H "X-API-Key: plane_api_bb5d084bdaae44c4b4610965fcfc0600" \
  -H "Content-Type: application/json" \
  -d '{"state": "7c3c1ad1-8692-4947-859c-721fa17fe06c"}' \
  "http://65.21.153.235:8083/api/v1/workspaces/flowmaster/projects/4704cb6d-9577-4761-b173-8a2bb279d00d/issues/<ISSUE_ID>/"
```

---

## Open Issues / Things to Fix

### 1. Grafana Dashboards (PRIORITY)
- **Problem:** No graphs visible on Grafana dashboards
- **Root Cause:** Dashboard "FlowMaster Test Environment" (uid: `b60e6f11-3561-49ea-abd8-e2ee33c6e0d0`) has all panel queries referencing `namespace="flowmaster-test"` but actual namespace is `flowmaster-dev`
- **Fix:** GET dashboard JSON from Grafana API, replace `flowmaster-test` with `flowmaster-dev` in all panel targets, PUT back
- **Also check:** "Server CPU" dashboard (uid: `advr5dn`)
- **Grafana creds:** admin / `FlowMaster2025Admin` (or get from: `glab variable get GRAFANA_ADMIN_PASSWORD --group flow-master`)
- **Prometheus datasource UID:** `efcm11zuvcs1sd`
- **agent1 was assigned this but is stuck on login. May need to do manually or reassign.**

### 2. Agent1 "Not Logged In"
- Pod `6cl5w` restarted 3 times. Claude Code shows "Not logged in - Run /login"
- Env vars are correct: `ANTHROPIC_API_KEY=sk-1234`, `ANTHROPIC_BASE_URL=http://litellm-proxy:4000`
- May need to kill and restart the Claude Code process inside the pod, or delete the pod and let K8s recreate it

### 3. Agents Don't Produce Code Changes
- Agents only do runtime K8s operations (kubectl patches, restarts, curls)
- No git repos cloned in pods, no git credentials available
- Code doesn't get pushed to GitLab — this is by design currently
- To enable code production: would need git credentials, repo cloning, and updated CLAUDE.md workflow

### 4. Server Memory Pressure
- HPA was patched to max 3 replicas (from 8) to prevent OOM
- If pods increase above 3, server runs out of memory (<200MB free), K8s API times out
- If K8s API becomes unresponsive: `systemctl restart k3s` on demo-server, then quickly scale back down

---

## Agent Chat

- **URL:** http://65.21.153.235:8099
- **Endpoints:** `/health`, `/messages`, `/agents`
- **Post message:** `curl -X POST http://65.21.153.235:8099/messages -H "Content-Type: application/json" -d '{"agent":"name","message":"text"}'`
- **Read messages:** `curl -s http://65.21.153.235:8099/messages | python3 -m json.tool`

---

## Key Infrastructure References

| Resource | Location |
|----------|----------|
| Demo Server | 65.21.153.235 (SSH: `ssh -p 22 demo-server-root`) |
| K8s namespace (FlowMaster) | `flowmaster-dev` |
| K8s namespace (Claude pods) | `claude-pod` |
| Grafana | http://65.21.153.235:3001 |
| Plane | http://65.21.153.235:8083 |
| Agent Chat | http://65.21.153.235:8099 |
| LiteLLM Proxy | litellm-proxy:4000 (in-cluster) |
| claude-pod repo | https://gitlab.com/flow-master/claude-pod |
| config-loader repo | https://gitlab.com/flow-master/claude-config-loader |

---

## Recommended Next Steps for zappy-ibex

1. **Fix agent1** - Either restart the pod (`kubectl delete pod -n claude-pod claude-pod-5b8df6d4f-6cl5w`) or fix the login issue inside the pod
2. **Fix Grafana manually if agent1 can't** - Simple API call to update dashboard namespace
3. **Monitor agent2 and agent3** - Check progress via tmux, ensure they complete their Plane issues
4. **Assign remaining backlog** - R54-R56 MCP Server, R39-R41 Prompt Engineering, R30-R33 Manager App, R27-R29 Engage App
5. **Verify completed work** - When agents mark issues as Done, verify the actual service works end-to-end
