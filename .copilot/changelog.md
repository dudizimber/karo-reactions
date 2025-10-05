# GitHub Copilot Prompt: Changelog Maintenance

Copy this entire prompt into GitHub Copilot Chat to create or update a CHANGELOG.md for your action.

---

## Prompt

```
I need to create or update a CHANGELOG.md file for my alert reaction action. The changelog should follow the Keep a Changelog format and integrate with the release automation system.

### Context
Every Docker-based action MUST include a CHANGELOG.md file following the Keep a Changelog format. This changelog is used by the release automation system to generate GitHub release notes and track changes over time.

### Changelog Requirements
1. **Format**: Must follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format
2. **Location**: Must be in the action's root directory (`actions/[ACTION_NAME]/CHANGELOG.md`)
3. **Sections**: Must include standard sections (Added, Changed, Deprecated, Removed, Fixed, Security)
4. **Unreleased**: Must have an `[Unreleased]` section for ongoing development
5. **Integration**: Works with `./scripts/prepare-release.sh` for release automation

### Reference Implementation
Look at existing changelogs:
- `actions/webhook-sender/CHANGELOG.md`
- `actions/gcp-pubsub/CHANGELOG.md`

### Action Details
Action name: [ACTION_NAME]
Action type: [Docker/Shell]
Current status: [New action/Existing action needing changelog/Updating existing changelog]

### Changelog Structure
```markdown
# Changelog

All notable changes to the [ACTION_NAME] action will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- [List new features]

### Changed
- [List changes in existing functionality]

### Deprecated
- [List soon-to-be removed features]

### Removed
- [List now removed features]

### Fixed
- [List bug fixes]

### Security
- [List security improvements]

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release
```

### Change Categories
- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Now removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Action Features to Document
For a new action, document these features:

**Docker-based actions**:
- Core functionality and purpose
- Environment variables supported
- Authentication methods
- Error handling capabilities
- Security hardening features
- Multi-architecture support
- Test coverage
- Documentation quality

**Shell-based actions**:
- Action purpose and functionality
- Container image used
- Command structure
- Configuration options
- Resource requirements
- Documentation completeness

### Example Changes
Here are examples of different types of changes:

```markdown
### Added
- HTTP webhook sending with JSON payload
- Support for Bearer token authentication
- Support for Basic authentication
- Request timeout configuration (default 30s)
- Retry mechanism for failed requests (max 3 retries)
- Custom HTTP headers support
- Alert data templating in request body
- Comprehensive error logging
- Multi-platform Docker images (AMD64, ARM64)
- Security hardening with non-root user
- Integration tests with httpbin.org

### Changed
- Improved error messages for debugging
- Updated base image to Alpine Linux 3.18
- Enhanced logging format with timestamps

### Fixed
- Memory leak in HTTP client connection pooling
- Timeout not being respected in some scenarios
- JSON escaping issues in alert data

### Security
- Run container as non-root user (UID 65534)
- Use minimal Alpine Linux base image
- No sensitive data logged to stdout/stderr
- Read-only root filesystem in container
```

### Tasks
1. Generate a complete CHANGELOG.md file for my action
2. Include appropriate sections based on Keep a Changelog format
3. Document all current features in the [Unreleased] section (for new actions)
4. Use appropriate change categories for each feature
5. Include proper header with links to Keep a Changelog and Semantic Versioning
6. Format consistently with existing changelogs in the repository

### Release Automation Integration
The changelog works with the release script:
```bash
# Validate changelog format
./scripts/prepare-release.sh [ACTION_NAME] validate

# Prepare a release (moves unreleased to versioned section)
./scripts/prepare-release.sh [ACTION_NAME] v1.0.0
```

### Maintenance Workflow
1. **During development**: Add changes to `[Unreleased]` section
2. **Before release**: Use `./scripts/prepare-release.sh` to prepare release
3. **After release**: Continue adding new changes to `[Unreleased]`

Generate a comprehensive CHANGELOG.md that follows the Keep a Changelog format and documents all the action's features appropriately.
```

---

## After Generation

1. **Validate format**: Run `./scripts/prepare-release.sh [action-name] validate`
2. **Review content**: Ensure all features are properly documented
3. **Update as needed**: Add any missing features or details
4. **Maintain regularly**: Add new changes to `[Unreleased]` during development
5. **Use for releases**: Let the release script manage versioned sections