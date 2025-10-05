# GitHub Copilot Prompt: Node.js Docker Action

Copy this entire prompt into GitHub Copilot Chat to create a new Node.js-based Docker action.

---

## Prompt

```
I need to create a new Docker-based action for the k8s-alert-reaction-operator. This action will be written in Node.js and should follow the established patterns in this repository.

### Context
The k8s-alert-reaction-operator executes actions as Kubernetes pods when alerts are triggered. Each action receives alert data through environment variables and performs specific tasks like sending notifications, scaling resources, or integrating with external systems.

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
    ├── package.json       # Node.js dependencies and scripts
    ├── package-lock.json  # Lockfile for dependencies
    └── src/
        └── index.js       # Main application entry point
```

### Reference Implementation
Look at `actions/webhook-sender/` (Go) and `actions/gcp-pubsub/` (Go) for examples of:
- Dockerfile best practices (multi-stage builds, security hardening)
- Application structure with proper error handling
- Environment variable parsing and validation
- Comprehensive test.sh scripts
- README.md documentation format

### Requirements
1. **Node.js Application**:
   - Use Node.js 18+ (LTS) with npm
   - Parse environment variables using process.env
   - Handle ALERT_JSON environment variable (parse JSON alert data)
   - Use proper logging with console methods or logging library
   - Implement comprehensive error handling with try/catch
   - Exit with appropriate codes (process.exit(0) for success, process.exit(1) for failure)
   - Use modern JavaScript (ES2022+) or TypeScript
   - Follow Node.js best practices

2. **Dependencies**:
   - Create package.json with exact versions (save-exact)
   - Use minimal dependencies (axios for HTTP, standard library when possible)
   - Include development dependencies for testing (jest, etc.)
   - Generate package-lock.json for reproducible builds

3. **Dockerfile**:
   - Multi-stage build (build stage + runtime stage)
   - Use node:18-alpine for minimal size
   - Install dependencies with npm ci in build stage
   - Run as non-root user (node user)
   - Security hardening (no shell, read-only filesystem when possible)
   - Proper layer caching optimization

4. **Test Script**:
   - Executable test.sh that accepts Docker image name as parameter
   - Unit tests using Jest or built-in Node.js test runner
   - Integration tests with sample alert data
   - Validate error scenarios and edge cases
   - Test package.json scripts

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
2. Create a production-ready Node.js application in `src/index.js`
3. Write package.json with appropriate dependencies and scripts
4. Write an optimized Dockerfile with security best practices
5. Create a comprehensive test.sh script with Jest integration
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

### Node.js Code Patterns
```javascript
const parseAlertData = () => {
  const alertJson = process.env.ALERT_JSON;
  if (!alertJson) {
    console.error('ALERT_JSON environment variable is required');
    process.exit(1);
  }

  try {
    return JSON.parse(alertJson);
  } catch (error) {
    console.error('Invalid JSON in ALERT_JSON:', error.message);
    process.exit(1);
  }
};

const main = async () => {
  try {
    const alertData = parseAlertData();
    console.log('Processing alert:', alertData.labels.alertname);
    
    // Your action logic here
    
    console.log('Action completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('Action failed:', error.message);
    process.exit(1);
  }
};

main();
```

### Package.json Structure
```json
{
  "name": "alert-reactions-[ACTION_NAME]",
  "version": "1.0.0",
  "description": "[ACTION DESCRIPTION]",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

Generate all files following the patterns established in existing actions, adapted for Node.js best practices. Focus on production readiness, security, and comprehensive testing.
```

---

## After Generation

1. **Review generated code** for Node.js security and best practices
2. **Customize** the action logic for your specific use case
3. **Run** `npm install` to generate package-lock.json
4. **Test thoroughly** using `docker build` and `./test.sh`
5. **Validate** with `./scripts/prepare-release.sh [action-name] validate`
6. **Update package.json** with any additional dependencies needed