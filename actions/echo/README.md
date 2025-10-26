# Echo Action

A simple debugging action that prints out alert information to help you understand what data is available from alerts and test your Karo setup.

## What it does

This action creates a pod that echoes all available alert information, including:
- Alert name and status
- Severity level
- Instance and job information
- Alert summary and description
- Full alert JSON data (if available)

## Usage

Copy the following action configuration into your Karo's `spec.actions` array:

```yaml
- name: echo-alert
  image: alpine:3.18
  command: ["sh"]
  args:
  - "-c" 
  - |
    echo "=== Alert Information ==="
    echo "Alert Name: $ALERT_NAME"
    echo "Alert Status: $ALERT_STATUS"
    echo "Alert Severity: $ALERT_SEVERITY"
    echo "Instance: $INSTANCE"
    echo "Job: $JOB"
    echo "Summary: $ALERT_SUMMARY"
    echo "Description: $ALERT_DESCRIPTION"
    echo "Timestamp: $(date)"
    echo "========================="
    echo "Raw Alert Data:"
    echo "$ALERT_JSON" | jq '.' 2>/dev/null || echo "$ALERT_JSON"
  env:
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
  - name: JOB
    valueFrom:
      alertRef:
        fieldPath: "labels.job"
  - name: ALERT_SUMMARY
    valueFrom:
      alertRef:
        fieldPath: "annotations.summary"
  - name: ALERT_DESCRIPTION
    valueFrom:
      alertRef:
        fieldPath: "annotations.description"
  - name: ALERT_JSON
    valueFrom:
      alertRef:
        fieldPath: "."
  resources:
    requests:
      cpu: "50m"
      memory: "32Mi"
    limits:
      cpu: "100m"
      memory: "64Mi"
```

## Example AlertReaction

```yaml
apiVersion: karo.io/v1alpha1
kind: AlertReaction
metadata:
  name: debug-alert-reaction
  namespace: default
spec:
  alertName: HighCPUUsage
  actions:
  - name: echo-alert
    image: alpine:3.18
    command: ["sh"]
    args:
    - "-c" 
    - |
      echo "=== Alert Information ==="
      echo "Alert Name: $ALERT_NAME"
      echo "Alert Status: $ALERT_STATUS"
      echo "Alert Severity: $ALERT_SEVERITY"
      echo "Instance: $INSTANCE"
      echo "Job: $JOB"
      echo "Summary: $ALERT_SUMMARY"
      echo "Description: $ALERT_DESCRIPTION"
      echo "Timestamp: $(date)"
      echo "========================="
      echo "Raw Alert Data:"
      echo "$ALERT_JSON" | jq '.' 2>/dev/null || echo "$ALERT_JSON"
    env:
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
    - name: JOB
      valueFrom:
        alertRef:
          fieldPath: "labels.job"
    - name: ALERT_SUMMARY
      valueFrom:
        alertRef:
          fieldPath: "annotations.summary"
    - name: ALERT_DESCRIPTION
      valueFrom:
        alertRef:
          fieldPath: "annotations.description"
    - name: ALERT_JSON
      valueFrom:
        alertRef:
          fieldPath: "."
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
      limits:
        cpu: "100m"
        memory: "64Mi"
```

## Expected Output

When this action runs, you should see output similar to:

```
=== Alert Information ===
Alert Name: HighCPUUsage
Alert Status: firing
Alert Severity: warning
Instance: 10.0.1.15:9100
Job: node-exporter
Summary: High CPU usage detected
Description: CPU usage is above 80% for more than 5 minutes
Timestamp: Mon Oct  1 12:34:56 UTC 2025
=========================
Raw Alert Data:
{
  "status": "firing",
  "labels": {
    "alertname": "HighCPUUsage",
    "instance": "10.0.1.15:9100",
    "job": "node-exporter",
    "severity": "warning"
  },
  "annotations": {
    "summary": "High CPU usage detected",
    "description": "CPU usage is above 80% for more than 5 minutes"
  }
}
```

## Use Cases

- **Debugging**: Understand what alert data is available
- **Testing**: Verify your Karo configuration works
- **Development**: See the structure of alert data before building complex actions
- **Monitoring**: Log alert occurrences for audit purposes

## Resource Usage

This action uses minimal resources:
- CPU: 50m request, 100m limit
- Memory: 32Mi request, 64Mi limit

The pod typically completes within seconds.

## Notes

- Uses Alpine Linux for minimal footprint
- Includes `jq` attempt for JSON formatting (fallback to raw output)
- All environment variables are optional - missing values will show as empty
- The action will still run even if some alert fields are not available