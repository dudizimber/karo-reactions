# GitHub Copilot Prompt: Action README

Copy this entire prompt into GitHub Copilot Chat to create comprehensive README.md documentation for your action.

---

## Prompt

```
I need to create a comprehensive README.md file for my Karo action. The documentation should be clear, complete, and follow the established patterns in this repository.

### Context
Every action MUST include a detailed README.md file that explains what the action does, how to use it, and provides complete configuration examples. This documentation is crucial for users to understand and implement the action.

### Documentation Requirements
1. **Structure**: Follow the established template with required sections
2. **Completeness**: Include all configuration options and examples
3. **Clarity**: Use clear language and practical examples
4. **Examples**: Provide complete, working YAML configurations
5. **Context**: Show the action within a complete AlertReaction

### Reference Implementation
Look at existing README files:
- `actions/webhook-sender/README.md` - Docker action with HTTP integration
- `actions/gcp-pubsub/README.md` - Docker action with cloud integration
- `actions/echo/README.md` - Shell action example

### Action Details
Action name: [ACTION_NAME]
Action type: [Docker/Shell]
Primary purpose: [BRIEF DESCRIPTION OF WHAT THE ACTION DOES]
Container image: [IMAGE_NAME] (for Docker actions) or [BASE_IMAGE] (for shell actions)
Programming language: [Go/Python/Node.js/Shell] (for Docker actions)

### Environment Variables
List all environment variables the action uses:
- [VARIABLE_NAME]: [Required/Optional] - [Description]
- [Add all variables here]

### Configuration Sources
How the action gets configuration:
- Alert data: [List alert fields used - e.g., labels.alertname, annotations.summary]
- ConfigMaps: [List configmap references if any]
- Secrets: [List secret references if any]

### README Structure Template
```markdown
# [Action Name]

[Brief description of what this action does and why it's useful]

## What it does

[Detailed explanation of the action's functionality, including:]
- [Primary function]
- [Key features]
- [Use cases]
- [Integration points]

## Usage

[Complete YAML configuration block showing the action]

## Environment Variables

| Variable | Required | Description | Example |
|----------|----------|-------------|----------|
| VAR_NAME | Yes/No | Description | `example_value` |

## Configuration

[Additional configuration details, setup requirements, etc.]

## Example AlertReaction

[Complete AlertReaction YAML showing the action in real context]

## Resource Requirements

- CPU: [X]m request, [Y]m limit
- Memory: [X]Mi request, [Y]Mi limit

## Prerequisites

[Any setup required before using this action]

## Examples

[Additional usage examples for different scenarios]

## Troubleshooting

[Common issues and solutions]
```

### Required Sections
1. **Title and Description**: Clear action name and purpose
2. **What it does**: Detailed functionality explanation
3. **Usage**: Complete YAML configuration
4. **Environment Variables**: Table with all variables
5. **Example AlertReaction**: Full context example
6. **Resource Requirements**: CPU and memory specs
7. **Prerequisites**: Setup requirements (if any)

### Optional Sections
8. **Configuration**: Advanced configuration details
9. **Examples**: Multiple usage scenarios
10. **Troubleshooting**: Common issues and solutions
11. **Security**: Security considerations
12. **Limitations**: Known limitations

### Docker Action Specifics
For Docker actions, include:
- Docker image name and version
- Authentication methods (if applicable)
- Network requirements
- Volume mounts (if any)
- Security context information

### Shell Action Specifics
For shell actions, include:
- Base container image used
- Command structure explanation
- Available tools in the container
- Resource efficiency notes

### Example Environment Variables Table
```markdown
| Variable | Required | Description | Example |
|----------|----------|-------------|----------|
| ALERT_JSON | Yes | Full alert data in JSON format | `{"status":"firing",...}` |
| WEBHOOK_URL | Yes | Target webhook endpoint | `https://hooks.slack.com/...` |
| AUTH_TOKEN | No | Bearer token for authentication | `bearer_token_here` |
| TIMEOUT | No | Request timeout in seconds | `30` |
| RETRY_COUNT | No | Number of retry attempts | `3` |
```

### Example AlertReaction Context
```yaml
apiVersion: karo.io/v1alpha1
kind: AlertReaction
metadata:
  name: [descriptive-name]
  namespace: default
spec:
  alertName: [AlertName]
  actions:
  - name: [action-name]
    image: [full-image-name:version]
    # ... complete configuration
    env:
    - name: ALERT_DATA
      valueFrom:
        alertRef:
          fieldPath: "labels.alertname"
    # ... all environment variables
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
```

### Alert Data Available
Common alert fields users can reference:
- `labels.alertname` - Alert name
- `labels.instance` - Instance identifier
- `labels.severity` - Alert severity
- `labels.job` - Job name
- `annotations.summary` - Brief summary
- `annotations.description` - Detailed description
- `annotations.runbook_url` - Runbook link
- `status` - Alert status (firing/resolved)
- `startsAt` - Alert start time
- `endsAt` - Alert end time (for resolved)

### Tasks
1. Generate a comprehensive README.md for my action
2. Include all required sections with appropriate content
3. Create a complete environment variables table
4. Provide a full AlertReaction example showing the action in context
5. Include proper resource requirements
6. Add troubleshooting section with common issues
7. Ensure the documentation is clear and actionable
8. Follow the formatting and style of existing action READMEs

Generate documentation that makes it easy for users to understand and implement the action successfully.
```

---

## After Generation

1. **Review completeness**: Ensure all sections have appropriate content
2. **Test examples**: Verify YAML examples are valid and complete
3. **Check clarity**: Make sure explanations are clear and helpful
4. **Update variables**: Ensure environment variables table matches action code
5. **Validate context**: Confirm AlertReaction example shows realistic usage
6. **Refine as needed**: Update documentation as the action evolves

# GitHub Copilot Prompts for Karo

This directory contains structured prompts to help developers create new actions for Karo using GitHub Copilot.

## Available Prompts

### 🐳 Docker-based Actions
- **[docker-action-go.md](docker-action-go.md)** - Create Go-based Docker actions
- **[docker-action-python.md](docker-action-python.md)** - Create Python-based Docker actions
- **[docker-action-node.md](docker-action-node.md)** - Create Node.js-based Docker actions

### 📝 Shell-based Actions
- **[shell-action.md](shell-action.md)** - Create simple shell-based actions

### 🧪 Testing & Validation
- **[test-script.md](test-script.md)** - Create comprehensive test scripts
- **[changelog.md](changelog.md)** - Maintain action changelogs

### 📚 Documentation
- **[readme.md](readme.md)** - Create comprehensive action documentation

## How to Use

1. **Choose the appropriate prompt** based on your action type
2. **Copy the entire prompt** from the markdown file
3. **Paste it into GitHub Copilot Chat** in VS Code
4. **Follow the interactive guidance** to customize for your specific use case
5. **Iterate and refine** using the generated code as a starting point

## Prompt Structure

Each prompt follows this structure:
- **Context**: Explains Karo and action requirements
- **Specifications**: Technical requirements and constraints
- **Examples**: Reference implementations from existing actions
- **Tasks**: Step-by-step generation requests
- **Validation**: Quality checks and testing guidance

## Contributing

When adding new prompts:
1. Follow the established structure
2. Include concrete examples from existing actions
3. Provide clear, actionable instructions
4. Test the prompts with Copilot before committing

## Tips for Best Results

- **Be specific**: Include exact requirements and constraints
- **Provide context**: Reference existing actions and patterns
- **Iterate**: Use follow-up prompts to refine the output
- **Validate**: Always test generated code thoroughly