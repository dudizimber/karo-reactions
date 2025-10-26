# Docker-Based Action Structure

This document defines the standard structure for actions that require compilation and custom Docker images.

## Directory Structure

Each Docker-based action should follow this structure:

```
actions/
└── action-name/
    ├── README.md              # Action documentation
    ├── Dockerfile             # Docker build configuration
    ├── .dockerignore          # Docker ignore patterns
    ├── test.sh               # Test script (REQUIRED)
    ├── src/                  # Source code directory
    │   ├── main.go           # Main application (example for Go)
    │   ├── go.mod            # Dependencies (Go example)
    │   └── go.sum            # Dependency locks (Go example)
    └── examples/             # Usage examples
        └── alertreaction.yaml
```

## Docker Image Naming Convention

All published images follow the pattern:
```
dudizimber/karo-reactions-<action-name>:<version>
```

Examples:
- `dudizimber/karo-reactions-webhook-sender:v1.0.0`
- `dudizimber/karo-reactions-slack-notify:v1.2.1`
- `dudizimber/karo-reactions-scale-deployment:v2.0.0`

## Versioning Strategy

### Semantic Versioning
All actions use semantic versioning (SemVer):
- **Major (v1.0.0 → v2.0.0)**: Breaking changes
- **Minor (v1.0.0 → v1.1.0)**: New features, backward compatible
- **Patch (v1.0.0 → v1.0.1)**: Bug fixes, backward compatible

### Image Tags
Each action maintains multiple tags:
- `latest`: Latest stable release
- `v1`, `v1.2`, `v1.2.3`: Semantic version tags
- `main`: Latest development build (optional)

## Build Process

### Automated Building
All Docker images are built automatically via GitHub Actions when:
1. Code is pushed to `main` branch (development builds)
2. Tags are created (release builds)
3. Pull requests are opened (test builds)

### Manual Building
For local development:
```bash
cd actions/action-name
docker build -t dudizimber/karo-reactions-action-name:dev .
```

## Dockerfile Requirements

### Multi-stage Builds
Use multi-stage builds for efficiency:
```dockerfile
# Build stage
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY src/ .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Runtime stage  
FROM alpine:3.18
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/app .
CMD ["./app"]
```

### Security Best Practices
- Use minimal base images (Alpine, distroless)
- Run as non-root user when possible
- Don't include unnecessary tools in final image
- Use specific base image versions

### Labels
Include standard labels:
```dockerfile
LABEL org.opencontainers.image.title="Karo: Action Name"
LABEL org.opencontainers.image.description="Description of what this action does"
LABEL org.opencontainers.image.source="https://github.com/dudizimber/karo-reactions"
LABEL org.opencontainers.image.vendor="dudizimber"
```

## Environment Variables

### Standard Variables
All actions receive these standard environment variables:
- `ALERT_JSON`: Complete alert data as JSON
- `ALERT_NAME`: Alert name from labels.alertname
- `ALERT_STATUS`: Alert status (firing/resolved)
- `ALERT_SEVERITY`: Alert severity level

### Action-Specific Variables
Document all additional environment variables your action uses:
```yaml
env:
- name: WEBHOOK_URL
  valueFrom:
    secretKeyRef:
      name: webhook-secret
      key: url
- name: TIMEOUT_SECONDS
  value: "30"
```

## Testing

### Required test.sh Script
**Every Docker-based action MUST include a `test.sh` script** in its root directory that defines how to test the action. This script will be automatically executed by the CI/CD pipeline.

#### Script Interface
The test script receives the Docker image name as the first parameter:
```bash
#!/bin/bash
IMAGE_NAME=${1:-"test-action-name:latest"}
echo "Testing $IMAGE_NAME"
# Your test logic here
```

#### Test Script Template
```bash
#!/bin/bash
set -e

IMAGE_NAME=${1:-"test-action-name:latest"}
echo "Testing action with image: $IMAGE_NAME"

# Test 1: Unit tests (language-specific)
echo "=== Running Unit Tests ==="
if [ -d "src" ] && [ -f "src/go.mod" ]; then
    docker run --rm -v "$PWD/src:/app" -w /app golang:1.24-alpine go test ./...
    echo "✅ Unit tests passed"
fi

# Test 2: Basic functionality test
echo "=== Running Integration Tests ==="
docker run --rm \
    -e REQUIRED_VAR="test-value" \
    -e ALERT_JSON='{"labels":{"alertname":"TestAlert"}}' \
    "$IMAGE_NAME"
echo "✅ Basic functionality test passed"

# Test 3: Error handling tests
echo "=== Running Error Handling Tests ==="
if docker run --rm "$IMAGE_NAME" 2>&1; then
    echo "❌ Expected error but action succeeded"
    exit 1
else
    echo "✅ Error handling test passed"
fi

echo "🎉 All tests passed!"
```

#### Best Practices for test.sh
- **Make it executable**: `chmod +x test.sh`
- **Use set -e**: Exit on first error
- **Test multiple scenarios**: Success cases, error cases, edge cases
- **Validate configuration**: Test missing required variables
- **Test security**: Verify non-root execution
- **Provide clear output**: Use emoji and clear success/failure messages
- **Language agnostic**: The script can test any language/technology

### Testing During Development
Run tests locally during development:
```bash
cd actions/your-action
docker build -t test-your-action:dev .
./test.sh test-your-action:dev
```

## Documentation Requirements

### README.md Structure
Each action's README.md must include:

1. **Description**: What the action does
2. **Features**: Key capabilities
3. **Usage**: Complete YAML configuration
4. **Environment Variables**: All required and optional vars
5. **Examples**: Working AlertReaction examples
6. **Building**: How to build locally
7. **Testing**: How to test the action
8. **Changelog**: Version history

### Code Documentation
- Comment complex logic
- Document exported functions/methods
- Include usage examples in code comments

## Release Process

### Tagging Convention
Each action has independent versioning using the format:
```bash
release/<action-name>/<version>
```

Examples:
- `release/webhook-sender/v1.0.0`
- `release/gcp-pubsub/v1.2.1`
- `release/slack-notify/v2.0.0-beta1`

### Creating a Release
1. Update version references in the action's README.md
2. Update any CHANGELOG or version files specific to the action
3. Create and push a release tag:
   ```bash
   # For webhook-sender version 1.0.0
   git tag -a release/webhook-sender/v1.0.0 -m "Release webhook-sender v1.0.0"
   git push origin release/webhook-sender/v1.0.0
   ```
4. GitHub Actions will automatically:
   - Build and publish the Docker image with proper tags
   - Create a GitHub release with changelog
   - Update documentation

### Docker Image Tags
When you create a release tag, the following Docker tags are created:
- `dudizimber/karo-reactions-<action>:v1.0.0` (exact version)
- `dudizimber/karo-reactions-<action>:v1.0` (minor version)
- `dudizimber/karo-reactions-<action>:v1` (major version)
- `dudizimber/karo-reactions-<action>:latest` (latest stable)

### Pre-release Testing
Before creating a release tag:
1. Test locally with the action's `test.sh` script:
   ```bash
   cd actions/your-action
   docker build -t test-action:dev .
   ./test.sh test-action:dev
   ```
2. Validate with real Kubernetes AlertReaction
3. Ensure documentation is up to date

### Changelog Maintenance
Each Docker action **must** maintain a `CHANGELOG.md` file following the [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

## [Unreleased]

### Added
- New feature descriptions

### Changed
- Changes in existing functionality

### Fixed
- Bug fixes

## [1.0.0] - 2024-01-15

### Added
- Initial release
```

**Workflow**:
1. **During development**: Add changes to the `[Unreleased]` section
2. **Before release**: Use the helper script to prepare the release:
   ```bash
   ./scripts/prepare-release.sh webhook-sender v1.2.0
   ```
3. **The script will**:
   - Move unreleased changes to a versioned section
   - Create a new empty unreleased section
   - Generate and push the release tag
   - Trigger automated Docker build and GitHub release

### Helper Script Usage
```bash
# Edit changelog interactively
./scripts/prepare-release.sh webhook-sender edit

# Validate changelog format
./scripts/prepare-release.sh webhook-sender validate

# Prepare a release (interactive)
./scripts/prepare-release.sh webhook-sender v1.2.0

# Show status of all actions
./scripts/prepare-release.sh status
```

### Pre-releases
For alpha, beta, or release candidate versions:
```bash
./scripts/prepare-release.sh webhook-sender v1.0.0-beta1
```
Or manually:
```bash
git tag -a release/webhook-sender/v1.0.0-beta1 -m "Release webhook-sender v1.0.0-beta1"
```
These will be marked as pre-releases in GitHub and tagged accordingly.

## Supported Languages

While any language can be used, we provide templates for:
- **Go**: Recommended for performance and small images
- **Shell**: For simple system operations

## Example Action Implementation

See `actions/webhook-sender/` for a complete example of a Docker-based action following all these conventions.