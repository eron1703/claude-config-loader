---
name: credentials
description: Access team credentials stored in GitLab CI/CD variables - servers, databases, APIs
user-invocable: true
---

# Credentials Management

**All team credentials are stored in GitLab CI/CD Variables.**

Access them using GitLab CLI - authenticates with your Microsoft SSO.

## Setup (One-time per developer)

```bash
# Install GitLab CLI
brew install glab

# Authenticate (opens browser for Microsoft SSO)
glab auth login
```

## Quick Access

```bash
# List all available credentials
glab variable list --group flow-master

# Get specific credential
glab variable get CREDENTIAL_NAME --group flow-master

# Copy to clipboard (macOS)
glab variable get CREDENTIAL_NAME --group flow-master | pbcopy

# Copy to clipboard (Linux)
glab variable get CREDENTIAL_NAME --group flow-master | xclip -selection clipboard
```

## Common Credentials

When team asks "what's the password for...":

```bash
# Database credentials
glab variable get PROD_DB_PASSWORD --group flow-master
glab variable get STAGING_DB_PASSWORD --group flow-master

# Server SSH keys
glab variable get SSH_PRIVATE_KEY --group flow-master
glab variable get BASTION_PASSWORD --group flow-master

# API tokens
glab variable get EXTERNAL_API_TOKEN --group flow-master
glab variable get SLACK_WEBHOOK_URL --group flow-master

# Hetzner Cloud (firewall, servers, DNS)
glab variable get HETZNER_API_TOKEN --group flow-master
```

### Hetzner Cloud API Token
- **Location**: GitLab CI/CD group variable `HETZNER_API_TOKEN` (masked, protected)
- **Group**: `flow-master` (ID: 122023679)
- **Use for**: Managing dev-01 server (65.21.153.235) firewall rules, server operations
- **API endpoint**: `https://api.hetzner.cloud/v1/`
- **Auth header**: `Authorization: Bearer $HETZNER_API_TOKEN`
- **Firewall ID**: 2269906 ("firewall-1") — attached to dev-01
- **Quick firewall check**: `curl -s -H "Authorization: Bearer $TOKEN" https://api.hetzner.cloud/v1/firewalls/2269906 | python3 -m json.tool`

### Grafana Monitoring
- **Location**: GitLab CI/CD group variable `GRAFANA_ADMIN_PASSWORD` (masked, protected)
- **Group**: `flow-master` (ID: 122023679)
- **URL variable**: `GRAFANA_URL` (not masked, not protected)
- **Dashboard**: http://dev-01:3001 (65.21.153.235:3001)
- **Admin user**: `admin`
- **Use for**: Viewing dashboards, managing alert rules, checking monitoring data
- **Quick check**: `curl -s http://admin:$(glab variable get GRAFANA_ADMIN_PASSWORD --group flow-master)@dev-01:3001/api/health`

### FlowMaster Dev Environment (flowmaster-dev namespace)
**Default credentials (NOT in GitLab - stored in database only):**

| Email | Password | Role | Notes |
|-------|----------|------|-------|
| `admin@flowmaster.ai` | `admin` | Administrator | Created 2026-02-11, matches frontend dev login button |
| `admin@flowmaster.io` | `Admin@123` | Tenant Admin | Seeded from migration 012 |
| `superadmin@flowmaster.io` | `Admin@123` | Platform Superuser | Seeded from migration 012 |
| `eng.admin@flowmaster.io` | `Admin@123` | Org Admin | Seeded from migration 012 |

**Database details:**
- Database: `flowmaster_dev_core` (in databases-test namespace)
- Schema: `auth_service`
- Table: `"user"` (quoted - reserved keyword)
- Bcrypt hash for `admin`: `$2b$12$3fqkA46LrHNNiXeXp668EukV2ED3QneA8AGgBlOf7OmfFooFVclWO`
- Bcrypt hash for `Admin@123`: `$2b$12$HhniFOKLHA4UKkSU/5KTf.ywFNdMy76/uZxxFSAPp3WRCdK8ntc9S`

**Login endpoint:** http://dev-01/api/v1/auth/login (65.21.153.235)

## Where are credentials stored?

**In GitLab UI:**
- **Group-level** (shared across projects): `Group > Settings > CI/CD > Variables`
- **Project-level** (specific to one project): `Project > Settings > CI/CD > Variables`

**Best practice:** Use group-level for shared credentials (databases, servers)

## Adding new credentials

```bash
# Add to group (requires Maintainer role)
glab variable set NEW_CREDENTIAL "value" --group flow-master

# Add to specific project
glab variable set NEW_CREDENTIAL "value" --repo your-org/project
```

## Security Notes

- ✅ All access is audited in GitLab
- ✅ Uses your Microsoft SSO (no additional password)
- ✅ Role-based access control
- ❌ Never commit credentials to git
- ❌ Never share credentials via Slack/email

## Troubleshooting

**"Variable not found":**
- Check if you have correct permissions in GitLab
- Verify variable name (case-sensitive)
- Confirm you're looking in correct group/project

**"Not authenticated":**
```bash
glab auth status  # Check auth status
glab auth login   # Re-authenticate
```

**List what you can access:**
```bash
glab variable list --group flow-master | grep KEY
```
