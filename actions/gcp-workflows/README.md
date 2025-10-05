# GCP Workflows Action

A robust action that executes Google Cloud Workflows based on Prometheus alerts. This action supports both static workflow names and dynamic workflow names derived from alert fields, making it highly flexible for different alerting scenarios.

## Features

- **Flexible workflow execution** with static or dynamic workflow name resolution
- **Alert-driven workflow names** extracted from alert labels or annotations
- **Reliable authentication** via service accounts or Application Default Credentials
- **Workload Identity support** for secure GKE authentication
- **Rich alert data** passed as workflow input with structured JSON format
- **Configurable timeouts** and optional execution monitoring
- **Workflow name sanitization** to ensure GCP naming compliance
- **Security hardened** with non-root user execution
- **Comprehensive error handling** and structured logging

## Usage

### Static Workflow Name

Execute a fixed workflow for all matching alerts:

```yaml
- name: execute-incident-workflow
  image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
  env:
  - name: GCP_PROJECT_ID
    value: "your-gcp-project-id"
  - name: GCP_LOCATION
    value: "us-central1"
  - name: WORKFLOW_NAME
    value: "incident-response-workflow"
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: "/etc/gcp/service-account.json"
  - name: TIMEOUT_SECONDS
    value: "300"
  - name: WAIT_FOR_COMPLETION
    value: "true"
  # Alert data is automatically injected by the operator
  - name: ALERT_JSON
    valueFrom:
      alertRef:
        fieldPath: "."
  - name: ALERT_NAME
    valueFrom:
      alertRef:
        fieldPath: "labels.alertname"
  - name: ALERT_STATUS
    valueFrom:
      alertRef:
        fieldPath: "status"
  - name: ALERT_SEVERITY
    valueFrom:
      alertRef:
        fieldPath: "labels.severity"
  - name: INSTANCE
    valueFrom:
      alertRef:
        fieldPath: "labels.instance"
  - name: ALERT_SUMMARY
    valueFrom:
      alertRef:
        fieldPath: "annotations.summary"
  - name: ALERT_DESCRIPTION
    valueFrom:
      alertRef:
        fieldPath: "annotations.description"
  volumeMounts:
  - name: gcp-service-account
    mountPath: /etc/gcp
    readOnly: true
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
```

### Dynamic Workflow Name from Alert Field

Execute different workflows based on alert content:

```yaml
- name: execute-alert-specific-workflow
  image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
  env:
  - name: GCP_PROJECT_ID
    value: "your-gcp-project-id"
  - name: GCP_LOCATION
    value: "us-central1"
  - name: WORKFLOW_NAME_FIELD
    value: "labels.workflow"  # or "annotations.workflow_name"
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: "/etc/gcp/service-account.json"
  - name: TIMEOUT_SECONDS
    value: "300"
  - name: WAIT_FOR_COMPLETION
    value: "false"
  - name: ALERT_JSON
    valueFrom:
      alertRef:
        fieldPath: "."
  # Additional environment variables for fallback
  - name: ALERT_NAME
    valueFrom:
      alertRef:
        fieldPath: "labels.alertname"
  - name: ALERT_STATUS
    valueFrom:
      alertRef:
        fieldPath: "status"
  - name: ALERT_SEVERITY
    valueFrom:
      alertRef:
        fieldPath: "labels.severity"
  volumeMounts:
  - name: gcp-service-account
    mountPath: /etc/gcp
    readOnly: true
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GCP_PROJECT_ID` | **Yes** | - | GCP project ID containing the workflows |
| `GCP_LOCATION` | No | `us-central1` | GCP region where workflows are deployed |
| `WORKFLOW_NAME` | Conditional* | - | Static workflow name to execute |
| `WORKFLOW_NAME_FIELD` | Conditional* | - | Alert field path for dynamic workflow name |
| `GOOGLE_APPLICATION_CREDENTIALS` | No | - | Path to service account JSON file |
| `TIMEOUT_SECONDS` | No | `300` | Execution timeout in seconds |
| `WAIT_FOR_COMPLETION` | No | `true` | Whether to wait for workflow completion |
| `WORKFLOW_SOURCE` | No | `k8s-alert-reaction-operator` | Source identifier for workflow executions |
| `ALERT_JSON` | No | - | Complete alert data as JSON |
| `ALERT_NAME` | No | - | Alert name (fallback if ALERT_JSON not available) |
| `ALERT_STATUS` | No | - | Alert status (firing/resolved) |
| `ALERT_SEVERITY` | No | - | Alert severity level |
| `INSTANCE` | No | - | Instance that triggered the alert |
| `ALERT_SUMMARY` | No | - | Brief alert summary |
| `ALERT_DESCRIPTION` | No | - | Detailed alert description |

*Either `WORKFLOW_NAME` (static) or `WORKFLOW_NAME_FIELD` (dynamic) must be specified, but not both.

## Workflow Name Resolution

### Static Workflow Names
When `WORKFLOW_NAME` is specified, the same workflow is executed for all matching alerts:

```yaml
env:
- name: WORKFLOW_NAME
  value: "incident-response-workflow"
```

### Dynamic Workflow Names
When `WORKFLOW_NAME_FIELD` is specified, the workflow name is extracted from the alert using dot notation:

```yaml
# Extract from alert labels
env:
- name: WORKFLOW_NAME_FIELD
  value: "labels.workflow"

# Extract from alert annotations  
env:
- name: WORKFLOW_NAME_FIELD
  value: "annotations.workflow_name"

# Extract from alert status
env:
- name: WORKFLOW_NAME_FIELD
  value: "status"
```

### Workflow Name Sanitization
Workflow names are automatically sanitized to meet GCP requirements:
- Converted to lowercase
- Spaces replaced with hyphens
- Invalid characters removed
- Must start with letter or underscore
- Maximum 63 characters

Examples:
- `"Alert Handler Workflow"` → `"alert-handler-workflow"`
- `"High CPU Alert!"` → `"high-cpu-alert"`
- `"123-critical"` → `"_123-critical"`

## Authentication Methods

### 1. Service Account Key File (Recommended for Kubernetes)

Create a Kubernetes secret with your service account key:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gcp-workflows-credentials
  namespace: monitoring
type: Opaque
data:
  service-account.json: <base64-encoded-service-account-key>
```

Mount the secret and set `GOOGLE_APPLICATION_CREDENTIALS`:

```yaml
env:
- name: GOOGLE_APPLICATION_CREDENTIALS
  value: "/etc/gcp/service-account.json"
volumeMounts:
- name: gcp-service-account
  mountPath: /etc/gcp
  readOnly: true
volumes:
- name: gcp-service-account
  secret:
    secretName: gcp-workflows-credentials
```

### 2. Workload Identity (Recommended for GKE)

Workload Identity provides secure, keyless authentication for GKE workloads. This is the most secure method as it eliminates the need to manage service account keys.

#### Step 1: Enable Workload Identity on your GKE cluster

```bash
# Enable Workload Identity when creating a cluster
gcloud container clusters create my-cluster \
    --workload-pool=PROJECT_ID.svc.id.goog \
    --zone=us-central1-a

# Or update an existing cluster
gcloud container clusters update my-cluster \
    --workload-pool=PROJECT_ID.svc.id.goog \
    --zone=us-central1-a
```

#### Step 2: Create a Google Service Account

```bash
# Create the Google Service Account
gcloud iam service-accounts create workflows-executor \
    --display-name="Workflows Executor for Alert Reactions" \
    --project=PROJECT_ID

# Grant necessary permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:workflows-executor@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/workflows.invoker"
```

#### Step 3: Create and configure the Kubernetes Service Account

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alert-workflows-sa
  namespace: monitoring
  annotations:
    iam.gke.io/gcp-service-account: workflows-executor@PROJECT_ID.iam.gserviceaccount.com
```

#### Step 4: Bind the Google and Kubernetes Service Accounts

```bash
gcloud iam service-accounts add-iam-policy-binding \
    workflows-executor@PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[monitoring/alert-workflows-sa]"
```

#### Step 5: Use in AlertReaction

```yaml
apiVersion: alertreaction.io/v1alpha1
kind: AlertReaction
metadata:
  name: workflow-alert-reaction
  namespace: monitoring
spec:
  serviceAccountName: alert-workflows-sa  # Use the Kubernetes SA
  alertName: HighCPUUsage
  actions:
  - name: execute-workflow
    image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
    env:
    - name: GCP_PROJECT_ID
      value: "PROJECT_ID"
    - name: GCP_LOCATION
      value: "us-central1"
    - name: WORKFLOW_NAME
      value: "cpu-alert-handler"
    # No GOOGLE_APPLICATION_CREDENTIALS needed with Workload Identity
    - name: ALERT_JSON
      valueFrom:
        alertRef:
          fieldPath: "."
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
```

### 3. Application Default Credentials

When running on GCP (GKE, GCE), credentials are automatically detected if no explicit credentials are provided.

## Workflow Input Format

The action passes alert data to the workflow as JSON input:

```json
{
  "alertName": "HighCPUUsage",
  "status": "firing",
  "severity": "warning",
  "instance": "10.0.1.15:9100",
  "summary": "High CPU usage detected",
  "description": "CPU usage is above 80% for more than 5 minutes",
  "labels": {
    "alertname": "HighCPUUsage",
    "instance": "10.0.1.15:9100",
    "job": "node-exporter",
    "severity": "warning",
    "workflow": "cpu-alert-handler"
  },
  "annotations": {
    "summary": "High CPU usage detected",
    "description": "CPU usage is above 80% for more than 5 minutes",
    "workflow_name": "cpu-incident-response"
  },
  "timestamp": "2025-10-05T12:34:56Z",
  "source": "k8s-alert-reaction-operator"
}
```

## Complete Examples

### Example 1: Static Workflow with Service Account

```yaml
apiVersion: alertreaction.io/v1alpha1
kind: AlertReaction
metadata:
  name: static-workflow-reaction
  namespace: monitoring
spec:
  alertName: DatabaseDown
  actions:
  - name: execute-db-recovery-workflow
    image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
    env:
    - name: GCP_PROJECT_ID
      value: "my-gcp-project"
    - name: GCP_LOCATION
      value: "us-central1"
    - name: WORKFLOW_NAME
      value: "database-recovery-workflow"
    - name: GOOGLE_APPLICATION_CREDENTIALS
      value: "/etc/gcp/service-account.json"
    - name: TIMEOUT_SECONDS
      value: "600"
    - name: WAIT_FOR_COMPLETION
      value: "true"
    - name: WORKFLOW_SOURCE
      value: "production-k8s-cluster"
    - name: ALERT_JSON
      valueFrom:
        alertRef:
          fieldPath: "."
    - name: ALERT_NAME
      valueFrom:
        alertRef:
          fieldPath: "labels.alertname"
    - name: ALERT_STATUS
      valueFrom:
        alertRef:
          fieldPath: "status"
    - name: ALERT_SEVERITY
      valueFrom:
        alertRef:
          fieldPath: "labels.severity"
    - name: INSTANCE
      valueFrom:
        alertRef:
          fieldPath: "labels.instance"
    - name: ALERT_SUMMARY
      valueFrom:
        alertRef:
          fieldPath: "annotations.summary"
    - name: ALERT_DESCRIPTION
      valueFrom:
        alertRef:
          fieldPath: "annotations.description"
    volumeMounts:
    - name: gcp-service-account
      mountPath: /etc/gcp
      readOnly: true
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
  volumes:
  - name: gcp-service-account
    secret:
      secretName: gcp-workflows-credentials
```

### Example 2: Dynamic Workflow with Workload Identity

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: alert-workflows-sa
  namespace: monitoring
  annotations:
    iam.gke.io/gcp-service-account: workflows-executor@my-gcp-project.iam.gserviceaccount.com
---
apiVersion: alertreaction.io/v1alpha1
kind: AlertReaction
metadata:
  name: dynamic-workflow-reaction
  namespace: monitoring
spec:
  serviceAccountName: alert-workflows-sa
  alertName: GenericAlert
  actions:
  - name: execute-alert-specific-workflow
    image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
    env:
    - name: GCP_PROJECT_ID
      value: "my-gcp-project"
    - name: GCP_LOCATION
      value: "us-central1"
    - name: WORKFLOW_NAME_FIELD
      value: "labels.workflow"
    - name: TIMEOUT_SECONDS
      value: "300"
    - name: WAIT_FOR_COMPLETION
      value: "false"
    - name: WORKFLOW_SOURCE
      value: "production-k8s-cluster"
    - name: ALERT_JSON
      valueFrom:
        alertRef:
          fieldPath: "."
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
```

## Required GCP Setup

### 1. Create Workflows

```bash
# Deploy a sample workflow
cat > cpu-alert-handler.yaml << 'EOF'
main:
  params: [input]
  steps:
    - log_alert:
        call: sys.log
        args:
          text: ${"Alert received: " + input.alertName + " with severity " + input.severity}
          severity: INFO
    - check_severity:
        switch:
          - condition: ${input.severity == "critical"}
            next: handle_critical
          - condition: ${input.severity == "warning"}
            next: handle_warning
        next: handle_info
    - handle_critical:
        call: sys.log
        args:
          text: "Handling critical alert - immediate action required"
          severity: ERROR
        next: end
    - handle_warning:
        call: sys.log
        args:
          text: "Handling warning alert - monitoring situation"
          severity: WARNING
        next: end
    - handle_info:
        call: sys.log
        args:
          text: "Handling info alert - logging for reference"
          severity: INFO
    - end:
        return: ${"Processed alert: " + input.alertName}
EOF

# Deploy the workflow
gcloud workflows deploy cpu-alert-handler \
    --source=cpu-alert-handler.yaml \
    --location=us-central1 \
    --project=my-gcp-project
```

### 2. Set Up Service Account (for non-Workload Identity)

```bash
# Create service account
gcloud iam service-accounts create workflows-executor \
    --display-name="Workflows Executor" \
    --project=my-gcp-project

# Grant necessary permissions
gcloud projects add-iam-policy-binding my-gcp-project \
    --member="serviceAccount:workflows-executor@my-gcp-project.iam.gserviceaccount.com" \
    --role="roles/workflows.invoker"

# Create and download service account key
gcloud iam service-accounts keys create workflows-executor-key.json \
    --iam-account=workflows-executor@my-gcp-project.iam.gserviceaccount.com
```

### 3. Create Kubernetes Secret (for non-Workload Identity)

```bash
kubectl create secret generic gcp-workflows-credentials \
    --from-file=service-account.json=./workflows-executor-key.json \
    --namespace=monitoring
```

## Required GCP Permissions

The service account needs the following IAM permissions:

```yaml
# Minimum required permissions
- workflows.executions.create  # To start workflow executions
- workflows.executions.get     # To check execution status (if WAIT_FOR_COMPLETION=true)
- workflows.workflows.get      # To validate workflow exists

# Or use the predefined role:
# roles/workflows.invoker
```

For Workload Identity, the Google Service Account needs:
```bash
# Grant Workflows Invoker role
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:workflows-executor@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/workflows.invoker"
```

## Building Locally

```bash
# Build the Docker image
docker build -t dudizimber/alert-reactions-gcp-workflows:dev .

# Test with sample data (requires GCP credentials)
docker run --rm \
    -v ~/.config/gcloud:/root/.config/gcloud \
    -e GCP_PROJECT_ID="your-project-id" \
    -e GCP_LOCATION="us-central1" \
    -e WORKFLOW_NAME="test-workflow" \
    -e WAIT_FOR_COMPLETION="false" \
    -e ALERT_JSON='{"status":"firing","labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test alert"}}' \
    dudizimber/alert-reactions-gcp-workflows:dev
```

## Testing

### Unit Tests

```bash
cd src
go test -v ./...
```

### Integration Test with Docker

```bash
# Run the comprehensive test suite
./test.sh dudizimber/alert-reactions-gcp-workflows:dev
```

### Manual Integration Test

Test with a real workflow:

```bash
# Create test workflow
gcloud workflows deploy test-workflow \
    --source=<(echo 'main: 
  params: [input]
  steps:
    - log_input:
        call: sys.log
        args:
          text: ${input}
        return: "Test completed"') \
    --location=us-central1 \
    --project=your-project-id

# Test the action
docker run --rm \
    -v ~/.config/gcloud:/root/.config/gcloud \
    -e GCP_PROJECT_ID="your-project-id" \
    -e GCP_LOCATION="us-central1" \
    -e WORKFLOW_NAME="test-workflow" \
    -e WAIT_FOR_COMPLETION="true" \
    -e ALERT_NAME="TestAlert" \
    -e ALERT_STATUS="firing" \
    -e ALERT_SEVERITY="info" \
    dudizimber/alert-reactions-gcp-workflows:latest

# Check execution results
gcloud workflows executions list \
    --workflow=test-workflow \
    --location=us-central1 \
    --project=your-project-id
```

## Monitoring and Observability

### Logs
The action provides structured logging:
- Configuration loading and validation
- Workflow name resolution
- Workflow execution attempts  
- Success/failure status with execution IDs
- Workflow completion status (if waiting)

### Metrics
Monitor these GCP Workflows metrics:
- `workflows.googleapis.com/execution/execution_count`
- `workflows.googleapis.com/execution/execution_duration`
- `workflows.googleapis.com/workflow/execution_count`

### Alerting
Set up alerts for:
- Workflow execution failures
- Long-running workflows
- Authentication failures
- Workflow not found errors

## Error Handling

The action handles various error conditions:

- **Missing workflow**: Validates workflow exists before execution
- **Authentication failures**: Clear error messages for credential issues
- **Network timeouts**: Configurable timeout with proper error reporting
- **Invalid JSON**: Continues with environment variable fallbacks
- **Workflow name resolution failures**: Detailed error messages for debugging
- **Execution failures**: Workflow error details are logged and reported

## Security Considerations

- **Service Account Keys**: Store in Kubernetes secrets, never in container images
- **Workload Identity**: Preferred authentication method for GKE (keyless)
- **Network Policies**: Restrict egress to GCP API endpoints only
- **Resource Limits**: Set appropriate CPU/memory limits
- **Non-root User**: Container runs as unprivileged user (UID 1001)
- **Minimal Permissions**: Use least-privilege IAM roles (`roles/workflows.invoker`)
- **Secret Management**: Use Kubernetes secrets or GCP Secret Manager

## Performance

- **Image size**: ~30MB compressed
- **Memory usage**: Typically <64MB at runtime
- **CPU usage**: Minimal, completes in <5 seconds for simple workflows
- **Network**: Single API call per execution (plus optional polling)
- **Concurrency**: Each action instance handles one workflow execution

## Troubleshooting

### Common Issues

1. **"Workflow not found"**
   ```bash
   gcloud workflows describe WORKFLOW_NAME --location=LOCATION --project=PROJECT_ID
   ```

2. **"Permission denied"**
   ```bash
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member="serviceAccount:SA_EMAIL" \
     --role="roles/workflows.invoker"
   ```

3. **"Could not load default credentials"**
   - Ensure `GOOGLE_APPLICATION_CREDENTIALS` points to valid JSON file
   - Or configure Application Default Credentials
   - Or set up Workload Identity properly

4. **"Workflow name resolution failed"**
   - Check that the specified alert field exists and contains a valid value
   - Verify the field path syntax (e.g., `labels.workflow` not `label.workflow`)
   - Check alert data with `ALERT_JSON` environment variable

5. **"Context deadline exceeded"**
   - Increase `TIMEOUT_SECONDS`
   - Check network connectivity to `workflows.googleapis.com`
   - Consider setting `WAIT_FOR_COMPLETION=false` for long-running workflows

### Workload Identity Troubleshooting

1. **"failed to retrieve default credentials"**
   ```bash
   # Verify Workload Identity is enabled
   gcloud container clusters describe CLUSTER_NAME --location=LOCATION --format="value(workloadIdentityConfig.workloadPool)"
   
   # Check service account binding
   gcloud iam service-accounts get-iam-policy SA_EMAIL
   ```

2. **"error retrieving GCE metadata"**
   - Ensure the pod is using the correct Kubernetes service account
   - Verify the service account annotation is correct
   - Check that the Google and Kubernetes service accounts are properly bound

## Changelog

### v1.0.0
- Initial release
- Support for static and dynamic workflow names
- GCP Workflows execution with comprehensive input data
- Service account and Workload Identity authentication
- Configurable timeouts and execution monitoring
- Workflow name sanitization and validation
- Comprehensive error handling and logging
- Security hardening with non-root execution

## Contributing

To contribute improvements:
1. Modify the Go source code in `src/`
2. Add tests for new functionality
3. Update this README with changes
4. Test with `docker build` and real GCP resources
5. Run the test suite with `./test.sh your-image:dev`
6. Submit a pull request