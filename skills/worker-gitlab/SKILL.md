---
name: worker-gitlab
description: GitLab access patterns, PAT, and repository locations
disable-model-invocation: true
---

# Worker GitLab Knowledge

## GitLab Access

### Group: flow-master
- **URL**: https://gitlab.com/flow-master
- **Privacy**: Private group
- **Source of Truth**: FlowMaster services are deployed from GitLab repos

### Personal Access Token (PAT)
- **Token**: `glpat-pAHA_wkFOqaOMicMktkEVW86MQp1Omp1bHVnCw.01.120epzb64`
- **Expires**: 2026-06-11
- **Scope**: API, read_api, read_repository, write_repository

### Clone Pattern
```bash
git clone https://oauth2:<PAT>@gitlab.com/flow-master/<repo>.git
```

### Push Pattern
```bash
git push https://oauth2:<PAT>@gitlab.com/flow-master/<repo>.git <branch>
```

## Critical Repositories

### Frontend
- **GitLab**: gitlab.com/flow-master/flowmaster-frontend-nextjs
- **GitHub Mirror**: github.com/HCB-Consulting-ME/frontend-nextjs
- **IMPORTANT**: Use **flowmaster-frontend-nextjs** (NOT frontend-nextjs on GitLab)

### Backend Services
All 29 services are in the flow-master group on GitLab.

## GitHub Organization

### HCB-Consulting-ME
- **URL**: https://github.com/HCB-Consulting-ME
- **Privacy**: Public
- **Push Method**: Standard SSH or HTTPS (no PAT needed, SSH keys from ~/.ssh/)

## Repository Sync Pattern
- GitLab is source of truth for CI/CD and deployments
- GitHub is public mirror/reference
- Deployment pipelines trigger from GitLab pushes

## Key Facts
- Always use GitLab as primary source for service code
- PAT expires June 2026 (regenerate before expiration)
- flowmaster-frontend-nextjs is the correct frontend repo name on GitLab
- SSH config can be used for GitHub (no special credentials needed)
