# Webhook Sender Action

A robust webhook sender action that posts alert data to HTTP endpoints in JSON format.

## Features

- **Reliable HTTP delivery** with configurable timeouts
- **Rich alert data** extraction and formatting
- **Custom authentication** support
- **Error handling** with detailed logging
- **Security hardened** with non-root user execution
- **Small image size** (~15MB) using multi-stage builds

## Usage

Add this action to your AlertReaction:

```yaml
- name: send-webhook
  image: dudizimber/alert-reactions-webhook-sender:v1.0.0
  env:
  - name: WEBHOOK_URL
    valueFrom:
      secretKeyRef:
        name: webhook-config
        key: url
  - name: TIMEOUT_SECONDS
    value: "30"
  - name: AUTH_HEADER
    valueFrom:
      secretKeyRef:
        name: webhook-config
        key: auth-header
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
  resources:
    requests:
      cpu: "50m"
      memory: "32Mi"
    limits:
      cpu: "200m"
      memory: "64Mi"
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `WEBHOOK_URL` | **Yes** | - | HTTP endpoint to send the webhook to |
| `TIMEOUT_SECONDS` | No | `30` | HTTP request timeout in seconds |
| `AUTH_HEADER` | No | - | Authorization header value (e.g., "Bearer token123") |
| `ALERT_JSON` | No | - | Complete alert data as JSON |
| `ALERT_NAME` | No | - | Alert name (fallback if ALERT_JSON not available) |
| `ALERT_STATUS` | No | - | Alert status (firing/resolved) |
| `ALERT_SEVERITY` | No | - | Alert severity level |
| `INSTANCE` | No | - | Instance that triggered the alert |
| `ALERT_SUMMARY` | No | - | Brief alert summary |
| `ALERT_DESCRIPTION` | No | - | Detailed alert description |

## Webhook Payload

The action sends a JSON payload with the following structure:

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
  "timestamp": "2025-10-01T12:34:56Z"
}
```

## Complete Example

### 1. Create Kubernetes Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: webhook-config
  namespace: default
type: Opaque
stringData:
  url: "https://your-webhook-endpoint.com/alerts"
  auth-header: "Bearer your-secret-token"
```

### 2. Create AlertReaction

```yaml
apiVersion: alertreaction.io/v1alpha1
kind: AlertReaction
metadata:
  name: webhook-alert-reaction
  namespace: default
spec:
  alertName: HighCPUUsage
  actions:
  - name: send-webhook
    image: dudizimber/alert-reactions-webhook-sender:v1.0.0
    env:
    - name: WEBHOOK_URL
      valueFrom:
        secretKeyRef:
          name: webhook-config
          key: url
    - name: AUTH_HEADER
      valueFrom:
        secretKeyRef:
          name: webhook-config
          key: auth-header
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
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
      limits:
        cpu: "200m"
        memory: "64Mi"
```

## Building Locally

```bash
# Build the Docker image
docker build -t dudizimber/alert-reactions-webhook-sender:dev .

# Test with sample data
docker run --rm \
  -e WEBHOOK_URL="https://httpbin.org/post" \
  -e ALERT_JSON='{"status":"firing","labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test alert"}}' \
  dudizimber/alert-reactions-webhook-sender:dev
```

## Testing

### Unit Tests

```bash
cd src
go test -v ./...
```

### Integration Test

Test with a real webhook endpoint:

```bash
docker run --rm \
  -e WEBHOOK_URL="https://httpbin.org/post" \
  -e TIMEOUT_SECONDS="10" \
  -e ALERT_NAME="TestAlert" \
  -e ALERT_STATUS="firing" \
  -e ALERT_SEVERITY="critical" \
  dudizimber/alert-reactions-webhook-sender:latest
```

## Security Considerations

- **Secrets**: Always store webhook URLs and authentication tokens in Kubernetes secrets
- **HTTPS**: Use HTTPS endpoints when possible for encrypted transmission
- **Timeouts**: Set appropriate timeouts to prevent hanging requests
- **Validation**: The webhook endpoint should validate incoming requests
- **Non-root**: The container runs as a non-root user for security

## Error Handling

The action will fail and log errors for:
- Missing `WEBHOOK_URL` environment variable
- Network connectivity issues
- HTTP response codes outside 200-299 range
- Request timeouts
- Invalid JSON in alert data (logs warning but continues)

## Performance

- **Image size**: ~15MB compressed
- **Memory usage**: Typically <10MB at runtime
- **CPU usage**: Minimal, completes in <1 second
- **Network**: Single HTTP request per execution

## Changelog

### v1.0.0
- Initial release
- HTTP webhook support with authentication
- Configurable timeouts
- Rich alert data formatting
- Security hardening

## Contributing

To contribute improvements:
1. Modify the Go source code in `src/`
2. Add tests for new functionality
3. Update this README with changes
4. Test with `docker build` and local testing
5. Submit a pull request