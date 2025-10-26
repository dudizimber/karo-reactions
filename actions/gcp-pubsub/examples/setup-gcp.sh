#!/bin/bash

# GCP Pub/Sub Setup Script
# This script sets up the necessary GCP resources for the karo-reactions GCP Pub/Sub action

set -e

# Configuration
PROJECT_ID=${1:-"your-project-id"}
TOPIC_NAME=${2:-"alert-notifications"}
SERVICE_ACCOUNT_NAME=${3:-"alert-publisher"}

echo "Setting up GCP Pub/Sub resources..."
echo "Project ID: $PROJECT_ID"
echo "Topic Name: $TOPIC_NAME"
echo "Service Account: $SERVICE_ACCOUNT_NAME"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI is not installed or not in PATH"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set the project
echo "Setting GCP project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling Pub/Sub API..."
gcloud services enable pubsub.googleapis.com

# Create Pub/Sub topic
echo "Creating Pub/Sub topic: $TOPIC_NAME..."
if gcloud pubsub topics describe $TOPIC_NAME &>/dev/null; then
    echo "Topic $TOPIC_NAME already exists"
else
    gcloud pubsub topics create $TOPIC_NAME
    echo "Topic $TOPIC_NAME created successfully"
fi

# Create service account
echo "Creating service account: $SERVICE_ACCOUNT_NAME..."
if gcloud iam service-accounts describe "${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" &>/dev/null; then
    echo "Service account $SERVICE_ACCOUNT_NAME already exists"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="Karo Pub/Sub Publisher" \
        --description="Service account for publishing alert data to Pub/Sub"
    echo "Service account $SERVICE_ACCOUNT_NAME created successfully"
fi

# Grant Pub/Sub Publisher role
echo "Granting Pub/Sub Publisher role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/pubsub.publisher"

# Create service account key
KEY_FILE="${SERVICE_ACCOUNT_NAME}-key.json"
echo "Creating service account key: $KEY_FILE..."
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Create Kubernetes secret with the service account key:"
echo "   kubectl create secret generic gcp-pubsub-credentials \\"
echo "     --from-file=service-account.json=$KEY_FILE \\"
echo "     --namespace=monitoring"
echo ""
echo "2. Update your AlertReaction with:"
echo "   - GCP_PROJECT_ID: $PROJECT_ID"
echo "   - PUBSUB_TOPIC_ID: $TOPIC_NAME"
echo ""
echo "3. Test the setup:"
echo "   gcloud pubsub topics publish $TOPIC_NAME --message='test message'"
echo ""
echo "4. Create a subscription to receive messages:"
echo "   gcloud pubsub subscriptions create test-subscription --topic=$TOPIC_NAME"
echo "   gcloud pubsub subscriptions pull test-subscription --auto-ack"
echo ""
echo "⚠️  Important: Keep the service account key file ($KEY_FILE) secure and delete it after creating the Kubernetes secret!"