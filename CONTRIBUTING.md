# Contributing to Alert Reactions

Thank you for your interest in contributing to the official Alert Reactions repository! This guide will help you create new actions and contribute effectively.

## Action Types

This repository supports two types of actions:

### Shell-based Actions
Simple actions using existing container images with shell commands. No compilation required.
- **Examples**: Echo, simple curl commands, kubectl operations
- **Definition**: YAML configuration only
- **Images**: Use existing public images (alpine, curl, kubectl, etc.)

### Docker-based Actions  
Complex actions with custom code requiring compilation into Docker images.
- **Examples**: HTTP webhooks, data processing, integrations
- **Languages**: Go, Python, Node.js, Rust, etc.
- **Images**: Automatically built and published to `dudizimber/alert-reactions-<name>`
- **CI/CD**: GitHub Actions build pipeline

**For Docker-based actions, see `DOCKER_ACTIONS.md` for detailed guidelines.**

## How to Contribute New Actions

### 1. Action Structure

#### Shell-based Actions
```
actions/
└── your-action-name/
    ├── README.md          # Documentation for your action
    └── action.yaml        # Action specification (optional)
```

#### Docker-based Actions
```
actions/
└── your-action-name/
    ├── README.md          # Documentation for your action
    ├── Dockerfile         # Docker build configuration
    ├── .dockerignore      # Docker ignore patterns
    ├── src/               # Source code directory
    │   ├── main.go        # Main application (language-specific)
    │   └── go.mod         # Dependencies (language-specific)
    ├── tests/             # Test files (optional)
    └── examples/          # Usage examples (optional)
        └── alertreaction.yaml
```

### 2. Action Directory Naming

- Use lowercase letters and hyphens (kebab-case)
- Be descriptive but concise
- Examples: `slack-notify`, `scale-deployment`, `restart-pods`

### 3. README.md Requirements

Your action's README.md must include:

#### Required Sections:
- **Brief description** of what the action does
- **Usage section** with complete YAML example
- **Environment variables** documentation
- **Resource requirements**
- **Example AlertReaction** showing the action in context

#### Optional Sections:
- Prerequisites or setup requirements
- Configuration options
- Troubleshooting tips
- Expected output examples

### 4. Testing Requirements (Docker-based Actions)

**Every Docker-based action MUST include a `test.sh` script** that defines how to test the action:

- **Location**: In the action's root directory
- **Executable**: Must be executable (`chmod +x test.sh`)
- **Interface**: Receives Docker image name as first parameter
- **Exit codes**: Exit 0 for success, non-zero for failure
- **Coverage**: Test success cases, error handling, and configuration validation

Example test.sh structure:
```bash
#!/bin/bash
set -e
IMAGE_NAME=${1:-"test-action:latest"}

# Unit tests
docker run --rm -v "$PWD/src:/app" -w /app golang:1.21-alpine go test ./...

# Integration tests  
docker run --rm -e TEST_VAR="value" "$IMAGE_NAME"

echo "✅ All tests passed!"
```

### 5. Action Specification Guidelines

When creating your action specification:

#### Container Image
- **Always use specific tags**, never `latest`
- Prefer official images or well-maintained community images
- Use minimal base images when possible (Alpine, distroless)

#### Resource Limits
- **Always specify resource requests and limits**
- Be conservative with resource allocation
- Test your action to determine appropriate limits

#### Environment Variables
- Document all required and optional environment variables
- Use `alertRef.fieldPath` to access alert data
- Use `secretKeyRef` for sensitive data
- Use `configMapKeyRef` for configuration data

#### Security
- Never hardcode secrets or credentials
- Use least-privilege principles
- Avoid running as root when possible

### 5. Action Template

Here's a template for creating new actions:

```yaml
# In your README.md, include this YAML template:
- name: your-action-name
  image: appropriate/image:specific-tag
  command: ["command"]
  args:
  - "arg1"
  - "arg2"
  env:
  - name: ALERT_NAME
    valueFrom:
      alertRef:
        fieldPath: "labels.alertname"
  - name: YOUR_CONFIG
    valueFrom:
      configMapKeyRef:
        name: your-config
        key: config-key
  - name: YOUR_SECRET
    valueFrom:
      secretKeyRef:
        name: your-secret
        key: secret-key
  resources:
    requests:
      cpu: "50m"
      memory: "64Mi"  
    limits:
      cpu: "200m"
      memory: "128Mi"
```

### 6. Testing Your Action

Before submitting:

1. **Test with real alerts** in a development cluster
2. **Verify resource usage** doesn't exceed your limits
3. **Test error scenarios** (missing secrets, network issues)
4. **Check logs** for any unexpected output or errors

### 7. Documentation Standards

#### README.md Format:
```markdown
# Action Name

Brief description of what this action does.

## What it does

Detailed explanation of the action's functionality.

## Usage

Complete YAML configuration block.

## Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| VAR_NAME | Yes | Description | `value` |

## Example AlertReaction

Complete example showing the action in context.

## Resource Requirements

- CPU: Xm request, Ym limit
- Memory: XMi request, YMi limit

## Prerequisites

Any setup required before using this action.
```

### 8. Submission Process

1. **Fork** this repository
2. **Create a new branch** for your action
3. **Create your action directory** with all required files:
   - README.md with complete documentation
   - **test.sh script** (for Docker-based actions) 
   - Dockerfile and source code (for Docker-based actions)
4. **Test thoroughly** using your test.sh script
5. **Verify CI tests pass** by running `./test.sh your-image:dev` locally
6. **Submit a pull request** with:
   - Clear description of what the action does
   - Evidence that `test.sh` passes locally
   - Test results and validation steps
   - Any special setup requirements

### 9. Review Criteria

Your action will be reviewed for:

- **Functionality**: Does it work as described?
- **Security**: Are secrets handled properly?
- **Documentation**: Is it clear and complete?
- **Resource efficiency**: Reasonable resource usage?
- **Code quality**: Clean, maintainable implementation?

### 10. Common Alert Data Fields

Here are commonly available alert fields you can reference:

```yaml
# Alert metadata
labels.alertname      # Name of the alert
labels.instance       # Instance that triggered the alert
labels.job           # Job name
labels.severity      # Alert severity (critical, warning, info)

# Alert content
annotations.summary     # Brief alert summary
annotations.description # Detailed alert description
annotations.runbook_url # Link to runbook

# Alert status
status                # firing, resolved
startsAt             # When alert started
endsAt               # When alert ended (for resolved alerts)

# Full alert object
.                    # Complete alert JSON
```

### 11. Best Practices

#### Security
- Use Kubernetes secrets for sensitive data
- Don't log sensitive information
- Validate input data when possible

#### Reliability
- Handle network failures gracefully  
- Set appropriate timeouts
- Use retries for transient failures

#### Performance
- Use efficient base images
- Minimize resource usage
- Clean up temporary files

#### Maintainability
- Use clear, descriptive names
- Comment complex logic
- Keep actions focused on single responsibilities

## Questions?

If you have questions about contributing:
1. Check existing actions for examples
2. Open an issue for discussion
3. Reach out to maintainers

We appreciate your contributions to make alert automation better for everyone!