---
name: save
description: Save infrastructure information (repos, servers, ports, databases) to configuration files for future use
user-invocable: true
---

# Save Configuration Information

**Purpose:** Persistently store infrastructure details so they're available in all future sessions.

**When to use:** User provides new information about repositories, servers, ports, databases, or other infrastructure.

## Configuration Files

- **Repositories** → `$(cat ~/.claude/.config-loader-path)/config/git-repos.yaml`
- **Servers** → `$(cat ~/.claude/.config-loader-path)/config/servers.yaml`
- **Ports** → `$(cat ~/.claude/.config-loader-path)/config/ports.yaml`
- **Databases** → `$(cat ~/.claude/.config-loader-path)/config/databases.yaml`
- **CI/CD** → `$(cat ~/.claude/.config-loader-path)/config/cicd.yaml`
- **Environment** → `$(cat ~/.claude/.config-loader-path)/config/environment.yaml`

## Process

1. Identify information type
2. Ask user for confirmation
3. Use Edit tool to update appropriate YAML file
4. Confirm what was saved and where

**Security:** Never save actual credentials - only references to password managers.
