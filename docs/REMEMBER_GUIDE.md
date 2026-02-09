# Using the /remember Skill

The `/remember` skill allows Claude to save new information you provide to the appropriate configuration files.

## How It Works

### Automatic Detection

When you mention infrastructure details in conversation, Claude will proactively offer to save them:

```
You: My GitLab repository is at https://gitlab.com/myorg/project
Claude: I can save this GitLab repository information. Should I add it to git-repos.yaml?
You: yes
Claude: ✅ Saved repository information to git-repos.yaml
```

### Manual Invocation

You can explicitly ask Claude to remember things:

```
You: remember this: production server is at prod.example.com
Claude: [Saves to servers.yaml]
```

Or use the skill directly:
```
You: /remember
[Claude shows the remember skill guide and asks what to save]
```

## What Can Be Saved

| Information Type | Saved To | Example |
|-----------------|----------|---------|
| Git repositories | `git-repos.yaml` | GitHub, GitLab, Bitbucket URLs |
| Servers/Hosts | `servers.yaml` | IP addresses, hostnames, access info |
| Ports | `ports.yaml` | Service port mappings |
| Databases | `databases.yaml` | Database names, collections, schemas |
| CI/CD | `cicd.yaml` | Pipeline configurations |
| Environment | `environment.yaml` | System setup, tools, configurations |
| Rules | `rules/global-rules.md` | Development guidelines |

## Examples

### Example 1: Repository

```
You: I just created a new GitLab project at https://gitlab.com/mycompany/analytics
Claude: I can save this repository information. Should I add it to git-repos.yaml?
You: yes, it's for analytics project in ~/projects/analytics
Claude: [Adds to git-repos.yaml]
✅ Saved repository:
   - URL: https://gitlab.com/mycompany/analytics
   - Local: ~/projects/analytics
   You can now access this via /repos
```

### Example 2: Server

```
You: Production API is at api.mycompany.com, port 443
Claude: I can save this server information. Should I add it to servers.yaml?
You: yes
Claude: [Adds to servers.yaml]
✅ Saved server: api.mycompany.com
   You can now access this via /servers
```

### Example 3: Port

```
You: The new analytics backend will use port 9005
Claude: Should I save this port assignment to ports.yaml?
You: yes, for the analytics project
Claude: [Adds to ports.yaml]
✅ Saved port: analytics backend → 9005
   You can now access this via /ports
```

### Example 4: Development Rule

```
You: For this project, always use TypeScript strict mode
Claude: Should I save this as a project-specific rule?
You: yes, save it globally
Claude: [Adds to global-rules.md]
✅ Saved development rule to global-rules.md
```

## Security: Sensitive Information

Claude will **warn** if you try to save sensitive data:

```
You: The database password is SuperSecret123
Claude: ⚠️ Warning: This appears to be a password.
I should NOT save actual credentials to config files.
Instead, I'll save a reference:
"credentials: See 1Password vault: Production/Database"
Is this okay?
```

**Safe to save:**
- Server hostnames and IPs
- Repository URLs
- Port numbers
- Database names
- References to password managers

**NOT safe to save:**
- Passwords
- API keys
- Private keys
- Tokens
- Secrets

Instead, save references:
- "See 1Password vault: Production"
- "In environment variable: DB_PASSWORD"
- "In ~/.ssh/config"

## Updating Existing Information

If information already exists, Claude will offer to update it:

```
You: The resolver backend moved to port 9010
Claude: Port information exists for resolver backend (currently 9000).
Should I update it to 9010?
You: yes
Claude: [Updates ports.yaml]
✅ Updated resolver backend port: 9000 → 9010
```

## Viewing Saved Information

After saving, use the appropriate skill to view:

```
You: show me all repositories
[You invoke /repos]

You: what ports are assigned?
[You invoke /ports]
```

## Project-Specific Information

For project-specific details, Claude can create/update `claude_instructions.md`:

```
You: For this project, use supervisor agent mode with 10+ parallel agents
Claude: This is project-specific. Should I save this to ./claude_instructions.md?
You: yes
Claude: [Creates or updates ./claude_instructions.md]
✅ Saved to ./claude_instructions.md
   This will be loaded automatically via /rules when in this directory
```

## Bulk Information

You can provide multiple pieces of information at once:

```
You: Here's my setup:
- GitLab: https://gitlab.com/myorg/proj1
- Production: prod.example.com
- Staging: staging.example.com
- Backend port: 9020
- Frontend port: 3020

Claude: I can save all this information:
1. Repository → git-repos.yaml
2. Production server → servers.yaml
3. Staging server → servers.yaml
4. Ports → ports.yaml

Should I save all of these?
You: yes
Claude: [Saves everything]
✅ Saved 5 pieces of information across 3 config files
```

## Tips

1. **Be descriptive** - Include context when providing info
   - Good: "production API server at api.prod.com"
   - Bad: "api.prod.com"

2. **Mention project names** - Helps Claude categorize correctly
   - "The analytics project uses port 9005"

3. **Review after saving** - Use skills to verify
   - After saving: `/ports` to check it was added correctly

4. **Update when things change** - Keep config current
   - "The backend moved from 9000 to 9010"

5. **Use references for secrets** - Never save actual credentials
   - "Password is in 1Password" not "password is xyz123"

## Integration with Other Skills

The `/remember` skill works with all other skills:

- Save info with `/remember`
- View with `/ports`, `/servers`, `/databases`, etc.
- Context-aware via `/project`
- Environment info via `/environment`

## Troubleshooting

### Information Not Saved

Check if Claude has write permissions:
```bash
ls -la $(cat ~/.claude/.config-loader-path)/config/
```

All files should be writable by your user.

### Wrong File

Claude decides which file based on the type of information. If it goes to the wrong file:

```
You: Actually, that should go in servers.yaml, not environment.yaml
Claude: [Moves/copies the information to correct file]
```

### Can't Find Saved Info

After saving, verify with appropriate skill:
```
/repos
/ports
/servers
```

If not showing, check the YAML file directly:
```bash
cat $(cat ~/.claude/.config-loader-path)/config/ports.yaml
```
