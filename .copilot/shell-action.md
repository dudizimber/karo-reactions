# GitHub Copilot Prompt: Shell-based Action

Copy this entire prompt into GitHub Copilot Chat to create a new shell-based action.

---

## Prompt

```
I need to create a new shell-based action for Karo. This action should use existing container images and shell commands, requiring no custom compilation.

### Context
Karo executes actions as Kubernetes pods when alerts are triggered. Shell-based actions are simple, lightweight actions that use existing public container images (like Alpine, curl, kubectl) and execute shell commands to perform tasks.

### Repository Structure
Shell-based actions have a simpler structure:
```
actions/
└── my-action/
    ├── README.md          # Comprehensive documentation
    ├── action.yaml        # Action specification (optional)
    └── test.sh           # Test script (optional)
```

### Reference Implementation
Look at `actions/echo/` for an example of:
- Simple directory structure
- README.md documentation format
- action.yaml specification format

### Requirements
1. **Action Configuration**:
   - Use existing public container images (alpine, curlimages/curl, bitnami/kubectl, etc.)
   - Access alert data through environment variables using alertRef.fieldPath
   - Use configMapKeyRef and secretKeyRef for configuration and secrets
   - Specify appropriate resource requests and limits

2. **Documentation**:
   - Comprehensive README.md with complete usage examples
   - Include all environment variables and their sources
   - Provide example AlertReaction YAML showing the action in context
   - Document resource requirements and prerequisites

3. **Optional Files**:
   - action.yaml with complete action specification
   - test.sh for validation (if testable without external dependencies)

### Action Specification
Create a shell-based action that: [DESCRIBE YOUR SPECIFIC ACTION PURPOSE HERE]

Container image to use: [SPECIFY BASE IMAGE - e.g., curlimages/curl:latest, alpine:latest, bitnami/kubectl:latest]

Environment variables needed:
- [LIST ALERT FIELDS NEEDED - e.g., labels.alertname, annotations.summary]
- [LIST CONFIGURATION FROM CONFIGMAPS]
- [LIST SECRETS NEEDED]

### Tasks
1. Generate the complete directory structure for `actions/[ACTION_NAME]/`
2. Create comprehensive README.md with:
   - Clear description of the action's purpose
   - Complete usage section with YAML example
   - Environment variables table
   - Example AlertReaction showing the action in context
   - Resource requirements
   - Prerequisites (if any)
3. Create optional action.yaml with complete action specification
4. Create optional test.sh script if the action can be tested

### Environment Variable Patterns
Shell-based actions access alert data like this:
```yaml
env:
# Alert data
- name: ALERT_NAME
  valueFrom:
    alertRef:
      fieldPath: "labels.alertname"
- name: INSTANCE
  valueFrom:
    alertRef:
      fieldPath: "labels.instance"
- name: ALERT_SUMMARY
  valueFrom:
    alertRef:
      fieldPath: "annotations.summary"

# Configuration
- name: CONFIG_VALUE
  valueFrom:
    configMapKeyRef:
      name: my-config
      key: config-key

# Secrets
- name: API_KEY
  valueFrom:
    secretKeyRef:
      name: my-secret
      key: api-key
```

### Example Alert Fields Available
- `labels.alertname` - Name of the alert
- `labels.instance` - Instance that triggered the alert
- `labels.severity` - Alert severity (critical, warning, info)
- `labels.job` - Job name
- `annotations.summary` - Brief alert summary
- `annotations.description` - Detailed alert description
- `annotations.runbook_url` - Link to runbook
- `status` - Alert status (firing, resolved)
- `startsAt` - When alert started
- `endsAt` - When alert ended (for resolved alerts)

### Resource Guidelines
```yaml
resources:
  requests:
    cpu: "50m"      # Start conservative
    memory: "64Mi"   # Minimal for shell commands
  limits:
    cpu: "200m"     # Allow bursts
    memory: "128Mi"  # Prevent runaway processes
```

### Container Image Recommendations
- **HTTP requests**: `curlimages/curl:latest`
- **Kubernetes operations**: `bitnami/kubectl:latest`
- **General shell**: `alpine:latest`
- **Text processing**: `alpine:latest` (has sed, awk, grep)
- **Cloud CLI**: Cloud-specific images (gcr.io/google.com/cloudsdktool/cloud-sdk)

### Action Template Structure
```yaml
- name: [action-name]
  image: [appropriate-image:tag]
  command: ["command"]
  args:
  - "arg1"
  - "arg2"
  env:
  - name: ALERT_DATA
    valueFrom:
      alertRef:
        fieldPath: "[field-path]"
  resources:
    requests:
      cpu: "50m"
      memory: "64Mi"
    limits:
      cpu: "200m"
      memory: "128Mi"
```

Generate all files following the patterns established in the echo action. Focus on simplicity, clarity, and practical usage examples.
```

---

## After Generation

1. **Review generated configuration** for correctness and security
2. **Customize** the shell commands for your specific use case
3. **Test** the action configuration in a development cluster
4. **Validate** resource usage doesn't exceed specified limits
5. **Update** documentation with any additional requirements or examples