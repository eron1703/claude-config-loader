---
name: cicd
description: Load CI/CD pipeline configuration and deployment information when working with automation or deployments
disable-model-invocation: false
---

# CI/CD Configuration

!`cat "$(cat ~/.claude/.config-loader-path)/config/cicd.yaml"`

Use this information when:
- Setting up CI/CD pipelines
- Configuring GitHub Actions / GitLab CI
- Troubleshooting deployment issues
- Managing secrets and environment variables
- Understanding deployment workflows
- Configuring monitoring and alerts

**Security Note:** Never commit secrets. Always use environment variables or secrets managers.
