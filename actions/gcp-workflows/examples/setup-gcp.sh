#!/bin/bash

# GCP Workflows Setup Script for Alert Reactions
# This script helps set up the necessary GCP resources and Kubernetes configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
PROJECT_ID=""
LOCATION="us-central1"
SA_NAME="workflows-executor"
SA_DISPLAY_NAME="Workflows Executor for Alert Reactions"
K8S_NAMESPACE="monitoring"
K8S_SA_NAME="alert-workflows-sa"
USE_WORKLOAD_IDENTITY=false
CLUSTER_NAME=""

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --project-id PROJECT_ID      GCP Project ID (required)"
    echo "  -l, --location LOCATION          GCP location (default: us-central1)"
    echo "  -s, --service-account SA_NAME    Service account name (default: workflows-executor)"
    echo "  -n, --namespace NAMESPACE        Kubernetes namespace (default: monitoring)"
    echo "  -k, --k8s-sa K8S_SA_NAME        Kubernetes service account name (default: alert-workflows-sa)"
    echo "  -w, --workload-identity          Use Workload Identity (requires --cluster-name)"
    echo "  -c, --cluster-name CLUSTER_NAME  GKE cluster name (required with --workload-identity)"
    echo "  -h, --help                       Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Setup with service account key file"
    echo "  $0 --project-id my-project"
    echo ""
    echo "  # Setup with Workload Identity"
    echo "  $0 --project-id my-project --workload-identity --cluster-name my-cluster"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-id)
            PROJECT_ID="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -s|--service-account)
            SA_NAME="$2"
            shift 2
            ;;
        -n|--namespace)
            K8S_NAMESPACE="$2"
            shift 2
            ;;
        -k|--k8s-sa)
            K8S_SA_NAME="$2"
            shift 2
            ;;
        -w|--workload-identity)
            USE_WORKLOAD_IDENTITY=true
            shift
            ;;
        -c|--cluster-name)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$PROJECT_ID" ]]; then
    log_error "Project ID is required. Use --project-id or -p"
    print_usage
    exit 1
fi

if [[ "$USE_WORKLOAD_IDENTITY" == true && -z "$CLUSTER_NAME" ]]; then
    log_error "Cluster name is required when using Workload Identity. Use --cluster-name or -c"
    print_usage
    exit 1
fi

# Check if required tools are installed
check_requirements() {
    log_info "Checking requirements..."
    
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is required but not installed"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is required but not installed"
        exit 1
    fi
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 &> /dev/null; then
        log_error "Please authenticate with gcloud: gcloud auth login"
        exit 1
    fi
    
    log_info "Requirements check passed ✓"
}

# Set up GCP project
setup_gcp_project() {
    log_info "Setting up GCP project: $PROJECT_ID"
    
    # Set project
    gcloud config set project "$PROJECT_ID"
    
    # Enable required APIs
    log_info "Enabling required APIs..."
    gcloud services enable workflows.googleapis.com
    gcloud services enable iam.googleapis.com
    
    if [[ "$USE_WORKLOAD_IDENTITY" == true ]]; then
        gcloud services enable container.googleapis.com
    fi
    
    log_info "GCP project setup completed ✓"
}

# Create Google Service Account
create_service_account() {
    log_info "Creating Google Service Account: $SA_NAME"
    
    # Check if service account already exists
    if gcloud iam service-accounts describe "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" &> /dev/null; then
        log_warn "Service account already exists, skipping creation"
    else
        gcloud iam service-accounts create "$SA_NAME" \
            --display-name="$SA_DISPLAY_NAME" \
            --project="$PROJECT_ID"
    fi
    
    # Grant necessary permissions
    log_info "Granting IAM permissions..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="roles/workflows.invoker"
    
    log_info "Service account setup completed ✓"
}

# Setup Workload Identity
setup_workload_identity() {
    log_info "Setting up Workload Identity..."
    
    # Enable Workload Identity on cluster (if not already enabled)
    log_info "Enabling Workload Identity on cluster: $CLUSTER_NAME"
    gcloud container clusters update "$CLUSTER_NAME" \
        --workload-pool="${PROJECT_ID}.svc.id.goog" \
        --location="$LOCATION" \
        --project="$PROJECT_ID" || log_warn "Workload Identity may already be enabled"
    
    # Create Kubernetes service account
    log_info "Creating Kubernetes service account..."
    kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $K8S_SA_NAME
  namespace: $K8S_NAMESPACE
  annotations:
    iam.gke.io/gcp-service-account: ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
EOF
    
    # Bind service accounts
    log_info "Binding Google and Kubernetes service accounts..."
    gcloud iam service-accounts add-iam-policy-binding \
        "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${PROJECT_ID}.svc.id.goog[${K8S_NAMESPACE}/${K8S_SA_NAME}]" \
        --project="$PROJECT_ID"
    
    log_info "Workload Identity setup completed ✓"
}

# Setup service account key method
setup_service_account_key() {
    log_info "Setting up service account key authentication..."
    
    # Create service account key
    KEY_FILE="${SA_NAME}-key.json"
    log_info "Creating service account key: $KEY_FILE"
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --project="$PROJECT_ID"
    
    # Create Kubernetes namespace
    kubectl create namespace "$K8S_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Create Kubernetes secret
    log_info "Creating Kubernetes secret: gcp-workflows-credentials"
    kubectl create secret generic gcp-workflows-credentials \
        --from-file=service-account.json="$KEY_FILE" \
        --namespace="$K8S_NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Clean up local key file for security
    rm "$KEY_FILE"
    
    log_info "Service account key setup completed ✓"
}

# Create sample workflow
create_sample_workflow() {
    log_info "Creating sample workflow..."
    
    WORKFLOW_FILE="sample-alert-handler.yaml"
    cat > "$WORKFLOW_FILE" << 'EOF'
main:
  params: [input]
  steps:
    - log_received:
        call: sys.log
        args:
          text: ${"Alert received: " + input.alertName + " with status " + input.status}
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
          text: ${"CRITICAL ALERT: " + input.summary + " on instance " + input.instance}
          severity: ERROR
        next: send_notification
    - handle_warning:
        call: sys.log
        args:
          text: ${"WARNING ALERT: " + input.summary + " on instance " + input.instance}
          severity: WARNING
        next: send_notification
    - handle_info:
        call: sys.log
        args:
          text: ${"INFO ALERT: " + input.summary}
          severity: INFO
    - send_notification:
        call: sys.log
        args:
          text: ${"Notification sent for alert: " + input.alertName}
          severity: INFO
    - return_result:
        return: ${"Successfully processed " + input.alertName + " alert"}
EOF
    
    # Deploy the workflow
    gcloud workflows deploy sample-alert-handler \
        --source="$WORKFLOW_FILE" \
        --location="$LOCATION" \
        --project="$PROJECT_ID"
    
    # Remove the temporary file
    rm "$WORKFLOW_FILE"
    
    log_info "Sample workflow 'sample-alert-handler' created ✓"
}

# Generate example AlertReaction
generate_example_alertreaction() {
    log_info "Generating example AlertReaction YAML..."
    
    if [[ "$USE_WORKLOAD_IDENTITY" == true ]]; then
        EXAMPLE_FILE="example-workload-identity-alertreaction.yaml"
        cat > "$EXAMPLE_FILE" << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $K8S_SA_NAME
  namespace: $K8S_NAMESPACE
  annotations:
    iam.gke.io/gcp-service-account: ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
---
apiVersion: alertreaction.io/v1alpha1
kind: AlertReaction
metadata:
  name: sample-workflow-reaction
  namespace: $K8S_NAMESPACE
spec:
  serviceAccountName: $K8S_SA_NAME
  alertName: SampleAlert
  actions:
  - name: execute-sample-workflow
    image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
    env:
    - name: GCP_PROJECT_ID
      value: "$PROJECT_ID"
    - name: GCP_LOCATION
      value: "$LOCATION"
    - name: WORKFLOW_NAME
      value: "sample-alert-handler"
    - name: TIMEOUT_SECONDS
      value: "300"
    - name: WAIT_FOR_COMPLETION
      value: "true"
    - name: WORKFLOW_SOURCE
      value: "k8s-cluster"
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
EOF
    else
        EXAMPLE_FILE="example-service-account-alertreaction.yaml"
        cat > "$EXAMPLE_FILE" << EOF
apiVersion: alertreaction.io/v1alpha1
kind: AlertReaction
metadata:
  name: sample-workflow-reaction
  namespace: $K8S_NAMESPACE
spec:
  alertName: SampleAlert
  actions:
  - name: execute-sample-workflow
    image: dudizimber/alert-reactions-gcp-workflows:v1.0.0
    env:
    - name: GCP_PROJECT_ID
      value: "$PROJECT_ID"
    - name: GCP_LOCATION
      value: "$LOCATION"
    - name: WORKFLOW_NAME
      value: "sample-alert-handler"
    - name: GOOGLE_APPLICATION_CREDENTIALS
      value: "/etc/gcp/service-account.json"
    - name: TIMEOUT_SECONDS
      value: "300"
    - name: WAIT_FOR_COMPLETION
      value: "true"
    - name: WORKFLOW_SOURCE
      value: "k8s-cluster"
    - name: ALERT_JSON
      valueFrom:
        alertRef:
          fieldPath: "."
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
EOF
    fi
    
    log_info "Example AlertReaction saved to: $EXAMPLE_FILE"
}

# Print summary
print_summary() {
    echo ""
    log_info "🎉 Setup completed successfully!"
    echo ""
    echo "Summary:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Location: $LOCATION"
    echo "  Google Service Account: ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
    if [[ "$USE_WORKLOAD_IDENTITY" == true ]]; then
        echo "  Authentication: Workload Identity"
        echo "  Kubernetes Service Account: $K8S_SA_NAME"
        echo "  Cluster: $CLUSTER_NAME"
    else
        echo "  Authentication: Service Account Key"
        echo "  Kubernetes Secret: gcp-workflows-credentials"
    fi
    echo "  Sample Workflow: sample-alert-handler"
    echo ""
    echo "Next steps:"
    echo "1. Review and apply the generated AlertReaction:"
    if [[ "$USE_WORKLOAD_IDENTITY" == true ]]; then
        echo "   kubectl apply -f example-workload-identity-alertreaction.yaml"
    else
        echo "   kubectl apply -f example-service-account-alertreaction.yaml"
    fi
    echo ""
    echo "2. Test the workflow:"
    echo "   gcloud workflows executions list --workflow=sample-alert-handler --location=$LOCATION --project=$PROJECT_ID"
    echo ""
    echo "3. Customize your AlertReaction configurations based on your alert rules"
}

# Main execution
main() {
    log_info "Starting GCP Workflows setup for Alert Reactions..."
    echo "Project: $PROJECT_ID"
    echo "Location: $LOCATION"
    echo "Authentication: $(if [[ "$USE_WORKLOAD_IDENTITY" == true ]]; then echo "Workload Identity"; else echo "Service Account Key"; fi)"
    echo ""
    
    check_requirements
    setup_gcp_project
    create_service_account
    
    if [[ "$USE_WORKLOAD_IDENTITY" == true ]]; then
        setup_workload_identity
    else
        setup_service_account_key
    fi
    
    create_sample_workflow
    generate_example_alertreaction
    print_summary
}

# Run main function
main