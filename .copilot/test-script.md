# GitHub Copilot Prompt: Test Script

Copy this entire prompt into GitHub Copilot Chat to create a comprehensive test script for your action.

---

## Prompt

```
I need to create a comprehensive test.sh script for my Karo action. The script should follow the established patterns in this repository and thoroughly test the action.

### Context
Every Docker-based action MUST include a test.sh script, and shell-based actions SHOULD include one if testable. The test script is executed by the CI/CD pipeline and should validate that the action works correctly.

### Test Script Requirements
1. **Interface**:
   - Must be executable (`chmod +x test.sh`)
   - For Docker actions: Receives Docker image name as first parameter
   - For shell actions: No parameters needed
   - Exit 0 for success, non-zero for failure

2. **Test Coverage**:
   - Unit tests (for code-based actions)
   - Integration tests with sample alert data
   - Error scenario testing
   - Configuration validation
   - Edge case handling

3. **Best Practices**:
   - Use `set -e` to exit on any command failure
   - Provide clear output with success/failure indicators
   - Clean up any temporary resources
   - Test both success and failure scenarios

### Reference Implementation
Look at existing test scripts:
- `actions/webhook-sender/test.sh` - Go application with unit and integration tests
- `actions/gcp-pubsub/test.sh` - Go application with authentication testing

### Action Details
Action type: [Docker/Shell]
Action name: [ACTION_NAME]
Primary language: [Go/Python/Node.js/Shell]
Action purpose: [BRIEF DESCRIPTION]

### Test Scenarios to Cover
1. **Unit Tests** (for code-based actions):
   - Test core functionality with mocked dependencies
   - Validate input parsing and validation
   - Test error handling paths

2. **Integration Tests**:
   - Test with realistic alert data
   - Validate environment variable parsing
   - Test successful execution paths

3. **Error Scenarios**:
   - Missing required environment variables
   - Invalid input data
   - Network failures (for external integrations)
   - Authentication failures

4. **Configuration Validation**:
   - Test different configuration combinations
   - Validate parameter boundaries
   - Test default values

### Sample Alert Data
Use this sample alert data for testing:
```json
{
  "status": "firing",
  "labels": {
    "alertname": "TestAlert",
    "instance": "test-server-1",
    "severity": "warning",
    "job": "test-job"
  },
  "annotations": {
    "summary": "Test alert for validation",
    "description": "This is a test alert used for action validation",
    "runbook_url": "https://example.com/runbook"
  },
  "startsAt": "2023-01-15T10:30:00Z"
}
```

### Test Script Structure
For Docker actions:
```bash
#!/bin/bash
set -e

IMAGE_NAME=${1:-"test-action:latest"}

echo "🧪 Testing action: [ACTION_NAME]"
echo "📦 Docker image: $IMAGE_NAME"

# Unit tests (if applicable)
echo "\n🔬 Running unit tests..."
# Add unit test commands here

# Integration tests
echo "\n🔗 Running integration tests..."
# Add integration test commands here

# Error scenario tests
echo "\n❌ Testing error scenarios..."
# Add error scenario tests here

echo "\n✅ All tests passed!"
```

For shell actions:
```bash
#!/bin/bash
set -e

echo "🧪 Testing shell action: [ACTION_NAME]"

# Configuration validation
echo "\n📋 Validating configuration..."
# Add configuration tests here

# Documentation validation
echo "\n📚 Validating documentation..."
# Add documentation tests here

echo "\n✅ All tests passed!"
```

### Tasks
1. Generate a comprehensive test.sh script for my action
2. Include appropriate test categories based on the action type
3. Add specific test cases for the action's functionality
4. Include clear output with emojis and status indicators
5. Handle both success and failure scenarios
6. Add cleanup procedures if needed
7. Make the script robust and maintainable

### Testing Commands Examples
For different technologies:

**Go applications**:
```bash
# Unit tests
docker run --rm -v "$PWD/src:/app" -w /app golang:1.21-alpine go test ./...

# Integration test
docker run --rm \
  -e ALERT_JSON='[SAMPLE_JSON]' \
  -e CONFIG_VAR="test-value" \
  "$IMAGE_NAME"
```

**Python applications**:
```bash
# Unit tests
docker run --rm -v "$PWD:/app" -w /app "$IMAGE_NAME" python -m pytest tests/

# Integration test
docker run --rm \
  -e ALERT_JSON='[SAMPLE_JSON]' \
  "$IMAGE_NAME"
```

**Node.js applications**:
```bash
# Unit tests
docker run --rm -v "$PWD:/app" -w /app "$IMAGE_NAME" npm test

# Integration test
docker run --rm \
  -e ALERT_JSON='[SAMPLE_JSON]' \
  "$IMAGE_NAME"
```

Generate a comprehensive test script that thoroughly validates the action and follows the established patterns in this repository.
```

---

## After Generation

1. **Make executable**: Run `chmod +x test.sh`
2. **Test locally**: Run `./test.sh [image-name]` to verify it works
3. **Add specific tests**: Customize for your action's unique requirements
4. **Validate error cases**: Ensure error scenarios are properly tested
5. **Update as needed**: Maintain the script as your action evolves