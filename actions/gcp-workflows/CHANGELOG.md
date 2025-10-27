# Changelog

All notable changes to the GCP Workflows action will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.1.0] - 2025-10-05

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security


## [v0.2.0] - 2025-10-27

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security


## [v0.1.1] - 2025-10-05

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security


### Added
- Future enhancements will be documented here

### Changed
- Future changes will be documented here

### Fixed
- Future bug fixes will be documented here

## [1.0.0] - 2025-10-05

### Added
- Initial release of GCP Workflows action
- Support for static workflow names via `WORKFLOW_NAME` environment variable
- Support for dynamic workflow names via `WORKFLOW_NAME_FIELD` with alert field extraction
- Comprehensive alert data passed to workflows as JSON input
- Support for GCP service account authentication via `GOOGLE_APPLICATION_CREDENTIALS`
- Support for GCP Workload Identity authentication for keyless GKE integration
- Configurable execution timeout via `TIMEOUT_SECONDS`
- Optional workflow completion monitoring via `WAIT_FOR_COMPLETION`
- Workflow name sanitization to ensure GCP naming compliance
- Rich error handling and structured logging
- Security hardening with non-root user execution (UID 1001)
- Comprehensive test suite with unit tests and integration tests
- Complete documentation with usage examples and Workload Identity setup
- Example AlertReaction configurations for various use cases
- GCP setup script (`setup-gcp.sh`) for automated resource provisioning
- Support for extracting workflow names from alert labels and annotations using dot notation
- Environment variable fallbacks for alert data when JSON parsing fails
- Configurable workflow execution source identification
- Container image optimization with multi-stage builds
- Alpine-based runtime image for minimal attack surface