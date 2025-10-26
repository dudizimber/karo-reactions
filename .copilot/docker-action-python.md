# GitHub Copilot Prompt: Python Docker Action

Copy this entire prompt into GitHub Copilot Chat to create a new Python-based Docker action.

---

## Prompt

```
I need to create a new Docker-based action for Karo. This action will be written in Python and should follow the established patterns in this repository.

### Context
Karo executes actions as Kubernetes pods when alerts are triggered. Each action receives alert data through environment variables and performs specific tasks like sending notifications, scaling resources, or integrating with external systems.

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
    ├── requirements.txt   # Python dependencies
    └── src/
        └── main.py        # Main application entry point
```

### Reference Implementation
Look at `actions/webhook-sender/` (Go) and `actions/gcp-pubsub/` (Go) for examples of:
- Dockerfile best practices (multi-stage builds, security hardening)
- Application structure with proper error handling
- Environment variable parsing and validation
- Comprehensive test.sh scripts
- README.md documentation format

### Requirements
1. **Python Application**:
   - Use Python 3.11+ with virtual environment
   - Parse environment variables for configuration using os.environ
   - Handle ALERT_JSON environment variable (parse JSON alert data)
   - Use proper logging with appropriate levels
   - Implement comprehensive error handling with try/except
   - Exit with appropriate codes (sys.exit(0) for success, sys.exit(1) for failure)
   - Use type hints and follow PEP 8 style guidelines

2. **Dependencies**:
   - Create requirements.txt with pinned versions
   - Use minimal dependencies (requests for HTTP, standard library when possible)
   - Include development dependencies for testing (pytest, etc.)

3. **Dockerfile**:
   - Multi-stage build (build stage + runtime stage)
   - Use python:3.11-alpine for minimal size
   - Install dependencies in build stage
   - Run as non-root user (create app user)
   - Security hardening (no shell, read-only filesystem when possible)
   - Proper layer caching optimization

4. **Test Script**:
   - Executable test.sh that accepts Docker image name as parameter
   - Unit tests using pytest
   - Integration tests with sample alert data
   - Validate error scenarios and edge cases
   - Test requirements.txt installation

5. **Documentation**:
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
2. Create a production-ready Python application in `src/main.py`
3. Write requirements.txt with appropriate dependencies
4. Write an optimized Dockerfile with security best practices
5. Create a comprehensive test.sh script with pytest integration
6. Generate detailed README.md with usage examples
7. Create initial CHANGELOG.md with unreleased features
8. Add .dockerignore for optimal build context

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

### Python Code Patterns
```python
import os
import json
import logging
import sys
from typing import Dict, Any

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def parse_alert_data() -> Dict[str, Any]:
    """Parse alert data from environment variable."""
    alert_json = os.environ.get('ALERT_JSON')
    if not alert_json:
        logger.error("ALERT_JSON environment variable is required")
        sys.exit(1)
    
    try:
        return json.loads(alert_json)
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in ALERT_JSON: {e}")
        sys.exit(1)
```

Generate all files following the patterns established in existing actions, adapted for Python best practices. Focus on production readiness, security, and comprehensive testing.
```

---

## After Generation

1. **Review generated code** for Python best practices and security
2. **Customize** the action logic for your specific use case
3. **Test thoroughly** using `docker build` and `./test.sh`
4. **Validate** with `./scripts/prepare-release.sh [action-name] validate`
5. **Update requirements.txt** with any additional dependencies needed