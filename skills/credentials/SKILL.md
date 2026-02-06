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
```

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
