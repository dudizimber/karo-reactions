# Karo Reactions - Official Actions Repository

This repository contains officially supported Reaction Actions for [Karo (Kubernetes Alert Reaction Operator)](https://github.com/dudizimber/karo).

## Overview

Karo allows you to define automated responses to Kubernetes alerts using custom resources called `AlertReaction`. Each AlertReaction can contain multiple actions that are executed as Kubernetes pods when an alert is triggered.

## Repository Structure

```
karo-reactions/
├── .github/
│   └── workflows/            # CI/CD pipelines for building Docker images
├── actions/                  # Directory containing all available actions
│   ├── echo/                # Simple echo action (shell-based)
│   │   ├── README.md        # Action documentation
│   │   └── action.yaml      # Action definition
│   ├── webhook-sender/      # Compiled Go action (Docker-based)
│   │   ├── README.md        # Action documentation
│   │   ├── Dockerfile       # Docker build configuration
│   │   ├── .dockerignore    # Docker ignore patterns
│   │   └── src/             # Source code
│   │       ├── main.go      # Go application
│   │       └── go.mod       # Go dependencies
│   └── [action-name]/       # Each action has its own directory
├── CONTRIBUTING.md          # Contribution guidelines
├── DOCKER_ACTIONS.md        # Docker-based action development guide
└── README.md               # This file
```

## How Actions Work

Actions are essentially Pod specifications that get executed when an alert is triggered. Each action defines:

- **Container Image**: The Docker image to run
- **Command & Arguments**: What the container should execute
- **Environment Variables**: Data from the alert and external sources
- **Resource Limits**: CPU and memory constraints

## Example AlertReaction

Here's an example of how actions are used in an AlertReaction:

```yaml
apiVersion: karo.io/v1alpha1
kind: AlertReaction
metadata:
  name: high-cpu-alert-reaction
  namespace: default
spec:
  alertName: HighCPUUsage
  actions:
  - name: notify-slack
    image: curlimages/curl:latest
    command: ["curl"]
    args:
    - "-X"
    - "POST"
    - "-H"
    - "Content-type: application/json"
    - "--data"
    - '{"text":"High CPU alert triggered on instance: $INSTANCE"}'
    env:
    - name: INSTANCE
      valueFrom:
        alertRef:
          fieldPath: "labels.instance"
    - name: SLACK_WEBHOOK_URL
      valueFrom:
        secretKeyRef:
          name: slack-webhook
          key: url
  - name: scale-deployment
    image: bitnami/kubectl:latest
    command: ["kubectl"]
    args:
    - "scale"
    - "deployment"
    - "my-app"
    - "--replicas=5"
    env:
    - name: KUBECONFIG
      value: "/etc/kubeconfig/config"
    resources:
      requests:
        cpu: "100m"
        memory: "64Mi"
      limits:
        cpu: "200m"
        memory: "128Mi"
```

## Action Types

### Shell-based Actions
Simple actions that use existing container images (like Alpine, curl, kubectl) with shell commands. These are defined directly in YAML and don't require compilation.

**Example**: Echo Action (`actions/echo/`)

### Docker-based Actions
Complex actions with custom code that require compilation into Docker images. These actions are automatically built and published to Docker Hub with semantic versioning.

**Examples**: 
- Webhook Sender (`actions/webhook-sender/`) - HTTP webhooks with authentication
- GCP Pub/Sub (`actions/gcp-pubsub/`) - Google Cloud Pub/Sub publishing
- **Image Pattern**: `dudizimber/karo-reactions-<action-name>:<version>`
- **Language**: Go (with support for other languages)
- **Features**: Production-ready with security hardening and error handling

## Available Actions

### Echo Action (Shell-based)
A simple debugging action that prints out alert information. Useful for testing and understanding what data is available from alerts.

Location: `actions/echo/`

### Webhook Sender Action (Docker-based)
A robust HTTP webhook sender that posts alert data to external endpoints in JSON format.

Location: `actions/webhook-sender/`  
Image: `dudizimber/karo-reactions-webhook-sender:latest`

### GCP Pub/Sub Action (Docker-based)
Publishes alert data to Google Cloud Pub/Sub topics for event-driven architectures and downstream processing.

Location: `actions/gcp-pubsub/`  
Image: `dudizimber/karo-reactions-gcp-pubsub:latest`

## Using Actions

### Shell-based Actions
To use a shell-based action:

1. Browse the `actions/` directory to find the action you need
2. Read the action's README.md for specific usage instructions
3. Copy the action configuration from the action's `action.yaml` file
4. Paste it into your AlertReaction's `spec.actions` array
5. Customize environment variables and parameters as needed

### Docker-based Actions
To use a Docker-based action:

1. Browse the `actions/` directory to find the action you need
2. Read the action's README.md for complete configuration examples
3. Use the published Docker image: `dudizimber/karo-reactions-<action-name>:<version>`
4. Configure required environment variables (usually from secrets)
5. Set appropriate resource limits

**Recommended**: Always use specific version tags (e.g., `v1.0.0`) instead of `latest` for production deployments.

## Building and Development

### Docker Images
All Docker-based actions are automatically built and published when:
- Code is pushed to the `main` branch (development images)
- Tags are created (release images with semantic versioning)
- Pull requests are opened (test builds)

### Local Development
To build and test an action locally:

```bash
# Navigate to the action directory
cd actions/webhook-sender

# Build the Docker image
docker build -t karo-reactions-webhook-sender:dev .

# Test with sample data
docker run --rm \
  -e WEBHOOK_URL="https://httpbin.org/post" \
  -e ALERT_JSON='{"labels":{"alertname":"TestAlert"}}' \
  karo-reactions-webhook-sender:dev
```

### Published Images and Versioning
Each action is versioned independently using semantic versioning. Images are published to Docker Hub when release tags are created:

- **Repository Pattern**: `dudizimber/karo-reactions-<action-name>`
- **Release Tag Format**: `release/<action-name>/<version>`
- **Docker Tag Pattern**: Multiple tags are created for each release:
  - `v1.0.0` (exact version)
  - `v1.0` (minor version)  
  - `v1` (major version)
  - `latest` (latest stable release)

**Examples**:
```bash
# Webhook Sender v1.2.0
dudizimber/karo-reactions-webhook-sender:v1.2.0
dudizimber/karo-reactions-webhook-sender:v1.2
dudizimber/karo-reactions-webhook-sender:v1
dudizimber/karo-reactions-webhook-sender:latest

# GCP Pub/Sub v2.1.0
dudizimber/karo-reactions-gcp-pubsub:v2.1.0
dudizimber/karo-reactions-gcp-pubsub:v2.1
dudizimber/karo-reactions-gcp-pubsub:v2
```

**Creating Releases**: Maintainers create releases by tagging:
```bash
git tag -a release/webhook-sender/v1.2.0 -m "Release webhook-sender v1.2.0"
git push origin release/webhook-sender/v1.2.0
```

## Contributing

We welcome contributions of new actions! Please see our contribution guidelines for details on how to submit new actions.

### 🤖 GitHub Copilot Templates
Use our structured prompts to quickly create new actions with GitHub Copilot:

- **[`.copilot/`](.copilot/)** - Complete prompt templates for:
  - **Docker Actions**: Go, Python, Node.js implementations
  - **Shell Actions**: Simple container-based actions
  - **Test Scripts**: Comprehensive testing approaches
  - **Documentation**: README and changelog templates

**Quick start**: Copy a prompt from `.copilot/` → Paste into Copilot Chat → Follow the interactive guidance!

### For Shell-based Actions
See `CONTRIBUTING.md` for templates and guidelines.

### For Docker-based Actions
See `DOCKER_ACTIONS.md` for comprehensive development guidelines including:
- Directory structure requirements
- Dockerfile best practices
- Build and testing procedures
- Security considerations
- Documentation standards

### Creating a New Action

#### Shell-based Actions
1. Create a new directory under `actions/` with your action name
2. Add a `README.md` explaining what the action does and how to use it
3. Add an `action.yaml` with the complete action specification (optional)
4. Test your action thoroughly
5. Submit a pull request

#### Docker-based Actions
1. Create a new directory under `actions/` with your action name
2. Add source code in the `src/` directory  
3. Create a `Dockerfile` following security best practices
4. **Create a `test.sh` script** that defines how to test your action
5. Add comprehensive `README.md` with usage examples
6. Test locally using `./test.sh your-image:dev`
7. Submit a pull request (images will be built and tested automatically)

## Environment Variables from Alerts

Karo provides access to alert data through environment variables:

- Use `alertRef.fieldPath` to extract specific fields from the alert
- Common paths include:
  - `labels.instance` - The instance that triggered the alert
  - `labels.job` - The job name
  - `annotations.summary` - Alert summary
  - `annotations.description` - Alert description

## Security Considerations

- Always use specific image tags instead of `latest` in production
- Set appropriate resource limits for all actions
- Use Kubernetes secrets for sensitive data like API keys and webhooks
- Review action code before using in production environments

## License

This project is licensed under the MIT License - see the LICENSE file for details.