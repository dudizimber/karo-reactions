# GCP Pub/Sub Action

A robust action that publishes alert data to Google Cloud Pub/Sub topics for event-driven architectures and downstream processing.

## Features

- **Reliable message delivery** to GCP Pub/Sub topics
- **Flexible authentication** via service accounts or Application Default Credentials
- **Rich alert data** formatting with message attributes
- **Configurable timeouts** and error handling
- **Security hardened** with non-root user execution
- **Topic validation** to ensure topic exists before publishing
- **Structured logging** for debugging and monitoring

## Usage

Add this action to your Karo:

```yaml
- name: publish-to-pubsub
  image: dudizimber/karo-reactions-gcp-pubsub:v1.0.0
  env:
  - name: GCP_PROJECT_ID
    value: "your-gcp-project-id"
  - name: PUBSUB_TOPIC_ID
    value: "alert-notifications"
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: "/etc/gcp/service-account.json"
  - name: TIMEOUT_SECONDS
    value: "30"
  - name: MESSAGE_SOURCE
    value: "k8s-production-cluster"
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

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GCP_PROJECT_ID` | **Yes** | - | GCP project ID containing the Pub/Sub topic |
| `PUBSUB_TOPIC_ID` | **Yes** | - | Name of the Pub/Sub topic to publish to |
| `GOOGLE_APPLICATION_CREDENTIALS` | No | - | Path to service account JSON file |
| `TIMEOUT_SECONDS` | No | `30` | Publishing timeout in seconds |
| `MESSAGE_SOURCE` | No | `karo` | Source identifier for messages |
| `ALERT_JSON` | No | - | Complete alert data as JSON |
| `ALERT_NAME` | No | - | Alert name (fallback if ALERT_JSON not available) |
| `ALERT_STATUS` | No | - | Alert status (firing/resolved) |
| `ALERT_SEVERITY` | No | - | Alert severity level |
| `INSTANCE` | No | - | Instance that triggered the alert |
| `ALERT_SUMMARY` | No | - | Brief alert summary |
| `ALERT_DESCRIPTION` | No | - | Detailed alert description |

## Authentication Methods

### 1. Service Account Key File (Recommended for Kubernetes)

Create a Kubernetes secret with your service account key:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gcp-pubsub-credentials
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
    secretName: gcp-pubsub-credentials
```

### 2. Workload Identity (Recommended for GKE)

For GKE clusters with Workload Identity enabled:

```yaml
# No GOOGLE_APPLICATION_CREDENTIALS needed
# The pod will automatically use the bound service account
metadata:
  annotations:
    iam.gke.io/gcp-service-account: alert-publisher@PROJECT_ID.iam.gserviceaccount.com
```

### 3. Application Default Credentials

When running on GCP (GKE, GCE), credentials are automatically detected if no explicit credentials are provided.

## Message Format

The action publishes JSON messages with the following structure:

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
    "severity": "warning"
  },
  "annotations": {
    "summary": "High CPU usage detected",
    "description": "CPU usage is above 80% for more than 5 minutes"
  },
  "timestamp": "2025-10-01T12:34:56Z",
  "source": "k8s-production-cluster"
}
```

### Message Attributes

Each message includes Pub/Sub attributes for easy filtering:

- `alertName`: Name of the alert
- `status`: Alert status (firing/resolved)
- `severity`: Alert severity level
- `source`: Source system identifier
- `timestamp`: ISO 8601 timestamp

## Complete Example

### 1. Create GCP Resources

```bash
# Create Pub/Sub topic
gcloud pubsub topics create alert-notifications --project=your-project-id

# Create service account
gcloud iam service-accounts create alert-publisher \
  --display-name="Alert Publisher" \
  --project=your-project-id

# Grant Pub/Sub Publisher role
gcloud projects add-iam-policy-binding your-project-id \
  --member="serviceAccount:alert-publisher@your-project-id.iam.gserviceaccount.com" \
  --role="roles/pubsub.publisher"

# Create and download service account key
gcloud iam service-accounts keys create service-account.json \
  --iam-account=alert-publisher@your-project-id.iam.gserviceaccount.com
```

### 2. Create Kubernetes Secret

```bash
kubectl create secret generic gcp-pubsub-credentials \
  --from-file=service-account.json=./service-account.json \
  --namespace=monitoring
```

### 3. Create AlertReaction

```yaml
apiVersion: karo.io/v1alpha1
kind: AlertReaction
metadata:
  name: pubsub-alert-reaction
  namespace: monitoring
spec:
  alertName: HighCPUUsage
  actions:
  - name: publish-to-pubsub
    image: dudizimber/karo-reactions-gcp-pubsub:v1.0.0
    env:
    - name: GCP_PROJECT_ID
      value: "your-gcp-project-id"
    - name: PUBSUB_TOPIC_ID
      value: "alert-notifications"
    - name: GOOGLE_APPLICATION_CREDENTIALS
      value: "/etc/gcp/service-account.json"
    - name: MESSAGE_SOURCE
      value: "k8s-production-cluster"
    - name: TIMEOUT_SECONDS
      value: "30"
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
      secretName: gcp-pubsub-credentials
```

## Required GCP Permissions

The service account needs the following IAM permissions:

```yaml
# Minimum required permissions
- pubsub.topics.get      # To verify topic exists
- pubsub.topics.publish  # To publish messages

# Or use the predefined role:
# roles/pubsub.publisher
```

## Building Locally

```bash
# Build the Docker image
docker build -t dudizimber/karo-reactions-gcp-pubsub:dev .

# Test with sample data (requires GCP credentials)
docker run --rm \
  -v ~/.config/gcloud:/root/.config/gcloud \
  -e GCP_PROJECT_ID="your-project-id" \
  -e PUBSUB_TOPIC_ID="test-topic" \
  -e ALERT_JSON='{"status":"firing","labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test alert"}}' \
  dudizimber/karo-reactions-gcp-pubsub:dev
```

## Testing

### Unit Tests

```bash
cd src
go test -v ./...
```

### Integration Test

Test with a real Pub/Sub topic:

```bash
# Create test topic
gcloud pubsub topics create test-alerts --project=your-project-id

# Test the action
docker run --rm \
  -v ~/.config/gcloud:/root/.config/gcloud \
  -e GCP_PROJECT_ID="your-project-id" \
  -e PUBSUB_TOPIC_ID="test-alerts" \
  -e ALERT_NAME="TestAlert" \
  -e ALERT_STATUS="firing" \
  -e ALERT_SEVERITY="critical" \
  -e MESSAGE_SOURCE="test-cluster" \
  dudizimber/karo-reactions-gcp-pubsub:latest

# Verify message was published
gcloud pubsub subscriptions create test-sub --topic=test-alerts --project=your-project-id
gcloud pubsub subscriptions pull test-sub --auto-ack --limit=1 --project=your-project-id
```

## Monitoring and Observability

### Logs
The action provides structured logging:
- Configuration loading
- Message publishing attempts  
- Success/failure status
- Message IDs for published messages

### Metrics
Monitor these GCP Pub/Sub metrics:
- `pubsub.googleapis.com/topic/send_message_operation_count`
- `pubsub.googleapis.com/topic/send_request_count`
- `pubsub.googleapis.com/topic/message_sizes`

### Alerting
Set up alerts for:
- Publishing failures
- High message sizes
- Topic quota exceeded
- Authentication failures

## Error Handling

The action handles various error conditions:

- **Missing topic**: Validates topic exists before publishing
- **Authentication failures**: Clear error messages for credential issues
- **Network timeouts**: Configurable timeout with proper error reporting
- **Invalid JSON**: Continues with environment variable fallbacks
- **Quota exceeded**: GCP API errors are properly logged and reported

## Security Considerations

- **Service Account Keys**: Store in Kubernetes secrets, never in container images
- **Workload Identity**: Preferred authentication method for GKE
- **Network Policies**: Restrict egress to GCP API endpoints only
- **Resource Limits**: Set appropriate CPU/memory limits
- **Non-root User**: Container runs as unprivileged user
- **Minimal Permissions**: Use least-privilege IAM roles

## Performance

- **Image size**: ~25MB compressed
- **Memory usage**: Typically <50MB at runtime
- **CPU usage**: Minimal, completes in <2 seconds
- **Network**: Single API call per execution
- **Concurrency**: Each action instance handles one message

## Troubleshooting

### Common Issues

1. **"Topic does not exist"**
   ```bash
   gcloud pubsub topics create YOUR_TOPIC --project=YOUR_PROJECT
   ```

2. **"Permission denied"**
   ```bash
   gcloud projects add-iam-policy-binding YOUR_PROJECT \
     --member="serviceAccount:SA_EMAIL" \
     --role="roles/pubsub.publisher"
   ```

3. **"Could not load default credentials"**
   - Ensure `GOOGLE_APPLICATION_CREDENTIALS` points to valid JSON file
   - Or configure Application Default Credentials

4. **"Context deadline exceeded"**
   - Increase `TIMEOUT_SECONDS`
   - Check network connectivity to `pubsub.googleapis.com`

## Changelog

### v1.0.0
- Initial release
- GCP Pub/Sub publishing with authentication
- Service account and Workload Identity support
- Rich message formatting with attributes
- Comprehensive error handling and logging
- Security hardening

## Contributing

To contribute improvements:
1. Modify the Go source code in `src/`
2. Add tests for new functionality
3. Update this README with changes
4. Test with `docker build` and real GCP resources
5. Submit a pull request