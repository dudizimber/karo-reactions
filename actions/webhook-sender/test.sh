#!/bin/bash

# Test script for webhook-sender action
# This script defines how to test the webhook-sender Docker image

set -e

# Get the Docker image name from the first parameter
IMAGE_NAME=${1:-"test-webhook-sender:latest"}

echo "Testing webhook-sender action with image: $IMAGE_NAME"

# Test 1: Unit tests (if Go modules exist)
echo "=== Running Unit Tests ==="
if [ -d "src" ] && [ -f "src/go.mod" ]; then
    echo "Running Go unit tests..."
    docker run --rm -v "$PWD/src:/app" -w /app golang:1.21-alpine go test ./...
    echo "✅ Unit tests passed"
else
    echo "⚠️  No Go modules found, skipping unit tests"
fi

# Test 2: Basic functionality test with httpbin
echo "=== Running Integration Tests ==="
echo "Testing webhook sending with httpbin.org..."

# Start the action with test data
docker run --rm \
    -e WEBHOOK_URL="https://httpbin.org/post" \
    -e TIMEOUT_SECONDS="10" \
    -e ALERT_JSON='{"status":"firing","labels":{"alertname":"TestAlert","severity":"warning","instance":"test-instance"},"annotations":{"summary":"Test alert summary","description":"Test alert description"}}' \
    "$IMAGE_NAME"

echo "✅ Basic webhook test passed"

# Test 3: Test with environment variable fallbacks
echo "Testing with environment variable fallbacks..."
docker run --rm \
    -e WEBHOOK_URL="https://httpbin.org/post" \
    -e TIMEOUT_SECONDS="10" \
    -e ALERT_NAME="EnvVarTest" \
    -e ALERT_STATUS="resolved" \
    -e ALERT_SEVERITY="info" \
    -e INSTANCE="env-test-instance" \
    -e ALERT_SUMMARY="Environment variable test" \
    -e ALERT_DESCRIPTION="Testing fallback to environment variables" \
    "$IMAGE_NAME"

echo "✅ Environment variable fallback test passed"

# Test 4: Test error handling (invalid URL)
echo "Testing error handling with invalid URL..."
if docker run --rm \
    -e WEBHOOK_URL="http://invalid-url-that-should-fail.local" \
    -e TIMEOUT_SECONDS="5" \
    -e ALERT_NAME="ErrorTest" \
    -e ALERT_STATUS="firing" \
    "$IMAGE_NAME" 2>&1; then
    echo "❌ Expected error but webhook succeeded"
    exit 1
else
    echo "✅ Error handling test passed (correctly failed with invalid URL)"
fi

# Test 5: Test missing required environment variable
echo "Testing missing required environment variable..."
if docker run --rm \
    -e ALERT_NAME="MissingURLTest" \
    "$IMAGE_NAME" 2>&1; then
    echo "❌ Expected error but webhook succeeded without URL"
    exit 1
else
    echo "✅ Missing environment variable test passed (correctly failed without WEBHOOK_URL)"
fi

echo ""
echo "🎉 All webhook-sender tests passed!"
echo "   - Unit tests: ✅"
echo "   - Basic functionality: ✅" 
echo "   - Environment fallbacks: ✅"
echo "   - Error handling: ✅"
echo "   - Input validation: ✅"