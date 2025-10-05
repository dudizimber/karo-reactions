# GitHub Copilot Prompt: Go Docker Action

Copy this entire prompt into GitHub Copilot Chat to create a new Go-based Docker action.

---

## Prompt

```
I need to create a new Docker-based action for the k8s-alert-reaction-operator. This action will be written in Go and should follow the established patterns in this repository.

### Context
The k8s-alert-reaction-operator executes actions as Kubernetes pods when alerts are triggered. Each action receives alert data through environment variables and performs specific tasks like sending notifications, scaling resources, or integrating with external systems.

### Repository Structure
Actions are organized in the `actions/` directory with this structure:
```
actions/
└── my-action/
    ├── README.md          # Comprehensive documentation
    ├── CHANGELOG.md       # Keep a Changelog format
    ├── Dockerfile         # Multi-stage build with Alpine
    ├── .dockerignore      # Optimize build context
    ├── test.sh           # Test script (executable)
    └── src/
        ├── main.go        # Main application entry point
        └── go.mod         # Go module definition
```

### Reference Implementation
Look at `actions/webhook-sender/` and `actions/gcp-pubsub/` for examples of:
- Dockerfile best practices (multi-stage builds, security hardening)
- Go application structure with proper error handling
- Environment variable parsing and validation
- Comprehensive test.sh scripts
- README.md documentation format

### Requirements
1. **Go Application**:
   - Use Go 1.21+ with modules
   - Parse environment variables for configuration
   - Handle ALERT_JSON environment variable (contains full alert data)
   - Implement proper error handling and logging
   - Exit with appropriate codes (0 for success, non-zero for failure)

2. **Dockerfile**:
   - Multi-stage build (build stage + runtime stage)
   - Use Alpine Linux for minimal attack surface
   - Run as non-root user (UID 65534)
   - Security hardening (no shell, read-only filesystem when possible)
   - Proper layer caching optimization

3. **Test Script**:
   - Executable test.sh that accepts Docker image name as parameter
   - Unit tests for Go code
   - Integration tests with sample alert data
   - Validate error scenarios and edge cases

4. **Documentation**:
   - Comprehensive README.md with usage examples
   - CHANGELOG.md following Keep a Changelog format
   - Environment variables documentation
   - Example AlertReaction YAML

### Action Specification
Create an action that: [DESCRIBE YOUR SPECIFIC ACTION PURPOSE HERE]

Environment variables needed:
- ALERT_JSON (required): Full alert data in JSON format
- [ADD YOUR SPECIFIC ENVIRONMENT VARIABLES]

### Tasks
1. Generate the complete directory structure for `actions/[ACTION_NAME]/`
2. Create a production-ready Go application in `src/main.go`
3. Write an optimized Dockerfile with security best practices
4. Create a comprehensive test.sh script
5. Generate detailed README.md with usage examples
6. Create initial CHANGELOG.md with unreleased features
7. Add .dockerignore for optimal build context

### Example Alert Data
The ALERT_JSON environment variable contains data like:
```json
{
  "status": "firing",
  "labels": {
    "alertname": "HighCPUUsage",
    "instance": "web-server-1",
    "severity": "warning"
  },
  "annotations": {
    "summary": "High CPU usage detected",
    "description": "CPU usage is above 80% for 5 minutes"
  },
  "startsAt": "2023-01-15T10:30:00Z"
}
```

Generate all files following the patterns established in the webhook-sender and gcp-pubsub actions. Focus on production readiness, security, and comprehensive testing.
```

---

## After Generation

1. **Review generated code** for security and best practices
2. **Customize** the action logic for your specific use case
3. **Test thoroughly** using `docker build` and `./test.sh`
4. **Validate** with `./scripts/prepare-release.sh [action-name] validate`
5. **Update** any environment variables or configuration as needed