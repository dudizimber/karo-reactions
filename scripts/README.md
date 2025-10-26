# Scripts

This directory contains helper scripts for maintaining the karo-reactions repository.

## prepare-release.sh

A comprehensive script for managing per-action changelogs and preparing releases.

### Usage

```bash
# List all actions with changelogs
./scripts/prepare-release.sh list

# Show status of unreleased changes
./scripts/prepare-release.sh status

# Edit a changelog interactively
./scripts/prepare-release.sh webhook-sender edit

# Validate changelog format
./scripts/prepare-release.sh webhook-sender validate

# Prepare a release (interactive)
./scripts/prepare-release.sh webhook-sender v1.2.0

# Prepare a pre-release
./scripts/prepare-release.sh webhook-sender v1.2.0-beta1
```

### Features

- **Changelog Validation**: Ensures proper [Keep a Changelog](https://keepachangelog.com/) format
- **Interactive Release Preparation**: Guides through the release process
- **Automatic Tag Creation**: Creates properly formatted release tags
- **Git Integration**: Handles commits and tag pushing
- **Status Overview**: Shows unreleased changes across all actions
- **Pre-release Support**: Handles alpha, beta, and RC versions

### Workflow

1. **During Development**: Add changes to the `[Unreleased]` section of your action's CHANGELOG.md
2. **Before Release**: Run `./scripts/prepare-release.sh <action-name> v<version>`
3. **Script Actions**:
   - Validates changelog format
   - Moves unreleased changes to a versioned section
   - Creates new empty unreleased section
   - Shows release notes preview
   - Creates and pushes release tag (with confirmation)
4. **Automation**: GitHub Actions takes over to build, test, and publish

### Examples

```bash
# Check what's ready for release
./scripts/prepare-release.sh status

# Prepare webhook-sender v1.3.0
./scripts/prepare-release.sh webhook-sender v1.3.0

# Edit gcp-pubsub changelog
./scripts/prepare-release.sh gcp-pubsub edit
```

### Requirements

- Git repository
- Bash 4.0+
- Standard Unix tools (sed, grep, head, tail, etc.)
- Write access to repository (for tagging and pushing)