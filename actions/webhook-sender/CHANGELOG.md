# Changelog

All notable changes to the webhook-sender action will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of webhook-sender action
- HTTP POST support with JSON payload
- Authentication support (Bearer token, Basic auth)
- Request timeout configuration
- Comprehensive error handling and logging
- Docker multi-stage build with Alpine Linux
- Security hardening (non-root user, minimal attack surface)
- Comprehensive test suite with integration tests
- Support for custom HTTP headers
- Retry mechanism for failed requests
- Alert data templating in request body

### Changed

### Deprecated

### Removed

### Fixed

### Security
- Non-root container execution
- Minimal base image (Alpine Linux)
- No sensitive data in logs