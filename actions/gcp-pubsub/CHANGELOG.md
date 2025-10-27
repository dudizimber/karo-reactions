# Changelog

All notable changes to the gcp-pubsub action will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.2.0] - 2025-10-27

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security


### Added
- Initial implementation of gcp-pubsub action
- Google Cloud Pub/Sub topic publishing
- Multiple authentication methods:
  - Service Account Key (JSON)
  - Application Default Credentials (ADC)
  - Workload Identity support
- Message attributes support
- Topic validation and auto-creation option
- Comprehensive error handling and logging
- Docker multi-stage build with Alpine Linux
- Security hardening (non-root user, minimal attack surface)
- Comprehensive test suite with integration tests
- Alert data serialization to JSON message payload
- Custom message attributes from alert labels/annotations
- Configurable publish timeout

### Changed

### Deprecated

### Removed

### Fixed

### Security
- Non-root container execution
- Minimal base image (Alpine Linux)
- Secure credential handling
- No sensitive data in logs