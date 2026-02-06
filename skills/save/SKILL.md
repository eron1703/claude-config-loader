---
name: save
description: Save infrastructure information (repos, servers, ports, databases) to configuration files for future use
user-invocable: true
---

# Save Configuration Information

**Purpose:** Persistently store infrastructure details so they're available in all future sessions.

**When to use:** User provides new information about repositories, servers, ports, databases, or other infrastructure.

## Configuration Files

- **Repositories** → `~/projects/claude-config-loader/config/git-repos.yaml`
- **Servers** → `~/projects/claude-config-loader/config/servers.yaml`
- **Ports** → `~/projects/claude-config-loader/config/ports.yaml`
- **Databases** → `~/projects/claude-config-loader/config/databases.yaml`
- **CI/CD** → `~/projects/claude-config-loader/config/cicd.yaml`
- **Environment** → `~/projects/claude-config-loader/config/environment.yaml`

## Process

1. Identify information type
2. Ask user for confirmation
3. Use Edit tool to update appropriate YAML file
4. Confirm what was saved and where

**Security:** Never save actual credentials - only references to password managers.
