#!/bin/bash

# prepare-release.sh - Helper script for maintaining changelogs and preparing releases
# Usage: ./scripts/prepare-release.sh <action-name> [version]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <action-name> [version]"
    echo ""
    echo "Commands:"
    echo "  $0 <action-name> edit           - Edit the changelog for an action"
    echo "  $0 <action-name> <version>      - Prepare release for specific version"
    echo "  $0 <action-name> validate       - Validate changelog format"
    echo "  $0 list                         - List all actions with changelogs"
    echo "  $0 status                       - Show unreleased changes status"
    echo ""
    echo "Examples:"
    echo "  $0 webhook-sender edit          - Open changelog in editor"
    echo "  $0 webhook-sender v1.2.0        - Prepare v1.2.0 release"
    echo "  $0 webhook-sender validate      - Check changelog format"
    echo "  $0 list                         - Show all actions"
    echo "  $0 status                       - Show unreleased changes"
}

# Function to get the root directory of the repository
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Function to list all actions with changelogs
list_actions() {
    local repo_root=$(get_repo_root)
    print_info "Actions with changelogs:"
    
    for action_dir in "$repo_root/actions"/*; do
        if [[ -d "$action_dir" && -f "$action_dir/CHANGELOG.md" ]]; then
            local action_name=$(basename "$action_dir")
            echo "  - $action_name"
        fi
    done
}

# Function to show status of unreleased changes
show_status() {
    local repo_root=$(get_repo_root)
    print_info "Unreleased changes status:"
    
    for action_dir in "$repo_root/actions"/*; do
        if [[ -d "$action_dir" && -f "$action_dir/CHANGELOG.md" ]]; then
            local action_name=$(basename "$action_dir")
            local changelog="$action_dir/CHANGELOG.md"
            
            # Check if there are unreleased changes
            if grep -q "## \[Unreleased\]" "$changelog"; then
                local unreleased_section=$(sed -n '/## \[Unreleased\]/,/## \[/p' "$changelog" | sed '$d')
                local changes_count=$(echo "$unreleased_section" | grep -c "^-" 2>/dev/null || echo "0")
                
                if [[ $changes_count -gt 0 ]]; then
                    echo -e "  ${GREEN}$action_name${NC}: $changes_count unreleased changes"
                else
                    echo -e "  ${YELLOW}$action_name${NC}: No unreleased changes"
                fi
            else
                echo -e "  ${RED}$action_name${NC}: No unreleased section found"
            fi
        fi
    done
}

# Function to validate changelog format
validate_changelog() {
    local action_name=$1
    local repo_root=$(get_repo_root)
    local changelog="$repo_root/actions/$action_name/CHANGELOG.md"
    
    if [[ ! -f "$changelog" ]]; then
        print_error "Changelog not found: $changelog"
        return 1
    fi
    
    print_info "Validating changelog for $action_name..."
    
    local errors=0
    
    # Check for required sections
    if ! grep -q "# Changelog" "$changelog"; then
        print_error "Missing main 'Changelog' header"
        ((errors++))
    fi
    
    if ! grep -q "## \[Unreleased\]" "$changelog"; then
        print_error "Missing '[Unreleased]' section"
        ((errors++))
    fi
    
    # Check for Keep a Changelog format
    if ! grep -q "Keep a Changelog" "$changelog"; then
        print_warning "Missing reference to Keep a Changelog format"
    fi
    
    if ! grep -q "Semantic Versioning" "$changelog"; then
        print_warning "Missing reference to Semantic Versioning"
    fi
    
    # Check for standard sections in unreleased
    local unreleased_section=$(sed -n '/## \[Unreleased\]/,/## \[/p' "$changelog" | sed '$d')
    
    for section in "### Added" "### Changed" "### Deprecated" "### Removed" "### Fixed" "### Security"; do
        if ! echo "$unreleased_section" | grep -q "$section"; then
            print_warning "Missing section: $section"
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        print_success "Changelog validation passed!"
        return 0
    else
        print_error "Changelog validation failed with $errors errors"
        return 1
    fi
}

# Function to edit changelog
edit_changelog() {
    local action_name=$1
    local repo_root=$(get_repo_root)
    local changelog="$repo_root/actions/$action_name/CHANGELOG.md"
    
    if [[ ! -f "$changelog" ]]; then
        print_error "Changelog not found: $changelog"
        return 1
    fi
    
    print_info "Opening changelog for $action_name..."
    
    # Use editor from environment or default to vim
    local editor=${EDITOR:-vim}
    "$editor" "$changelog"
}

# Function to prepare a release
prepare_release() {
    local action_name=$1
    local version=$2
    local repo_root=$(get_repo_root)
    local changelog="$repo_root/actions/$action_name/CHANGELOG.md"
    
    # Validate inputs
    if [[ ! -f "$changelog" ]]; then
        print_error "Changelog not found: $changelog"
        return 1
    fi
    
    # Validate version format
    if [[ ! $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        print_error "Invalid version format. Use semantic versioning (e.g., v1.2.0, v1.0.0-beta1)"
        return 1
    fi
    
    print_info "Preparing release $version for $action_name..."
    
    # Check if version already exists
    if grep -q "## \[$version\]" "$changelog"; then
        print_error "Version $version already exists in changelog"
        return 1
    fi
    
    # Check if there are unreleased changes
    local unreleased_section=$(sed -n '/## \[Unreleased\]/,/## \[/p' "$changelog" | sed '$d')
    local changes_count=$(echo "$unreleased_section" | grep -c "^-" 2>/dev/null || echo "0")
    
    if [[ $changes_count -eq 0 ]]; then
        print_warning "No unreleased changes found. Continue anyway? (y/N)"
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Release preparation cancelled"
            return 0
        fi
    fi
    
    # Get current date
    local release_date=$(date +%Y-%m-%d)
    
    # Create backup
    cp "$changelog" "$changelog.backup"
    print_info "Created backup: $changelog.backup"
    
    # Update changelog
    print_info "Updating changelog..."
    
    # Use a temporary file for the sed operation
    local temp_file=$(mktemp)
    
    # Replace [Unreleased] with [version] and add new [Unreleased] section
    sed "s/## \[Unreleased\]/## [$version] - $release_date/" "$changelog" > "$temp_file"
    
    # Add new unreleased section after the title
    {
        # Print everything up to and including the first version section
        sed -n '1,/## \[.*\] - [0-9]/p' "$temp_file"
        
        # Add new unreleased section
        echo ""
        echo "## [Unreleased]"
        echo ""
        echo "### Added"
        echo ""
        echo "### Changed"
        echo ""
        echo "### Deprecated"
        echo ""
        echo "### Removed"
        echo ""
        echo "### Fixed"
        echo ""
        echo "### Security"
        echo ""
        
        # Print the rest of the file starting from the line after the first version section
        sed -n '/## \[.*\] - [0-9]/,$p' "$temp_file" | tail -n +2
    } > "$changelog"
    
    rm "$temp_file"
    
    print_success "Changelog updated successfully!"
    
    # Show what would be in the release notes
    print_info "Release notes preview:"
    echo "----------------------------------------"
    sed -n "/## \[$version\]/,/## \[/p" "$changelog" | head -n -1 | tail -n +2
    echo "----------------------------------------"
    
    # Ask if user wants to create the tag
    print_info "Create release tag? (y/N)"
    read -r create_tag
    
    if [[ $create_tag =~ ^[Yy]$ ]]; then
        local tag_name="release/$action_name/$version"
        
        # Check if tag already exists
        if git tag -l | grep -q "^$tag_name$"; then
            print_error "Tag $tag_name already exists"
            return 1
        fi
        
        # Create commit with changelog update
        git add "$changelog"
        git commit -m "Update changelog for $action_name $version"
        
        # Create release tag
        local release_notes=$(sed -n "/## \[$version\]/,/## \[/p" "$changelog" | head -n -1 | tail -n +3)
        git tag -a "$tag_name" -m "Release $action_name $version

$release_notes"
        
        print_success "Created tag: $tag_name"
        print_info "Push the tag with: git push origin $tag_name"
        
        # Ask if user wants to push immediately
        print_info "Push tag now? (y/N)"
        read -r push_tag
        
        if [[ $push_tag =~ ^[Yy]$ ]]; then
            git push origin "$tag_name"
            print_success "Tag pushed to origin!"
        fi
    else
        print_info "Tag creation skipped. You can create it later with:"
        echo "  git tag -a release/$action_name/$version -m \"Release $action_name $version\""
    fi
    
    print_success "Release preparation complete!"
}

# Main script logic
main() {
    local repo_root=$(get_repo_root)
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Check if actions directory exists
    if [[ ! -d "$repo_root/actions" ]]; then
        print_error "Actions directory not found: $repo_root/actions"
        exit 1
    fi
    
    case "${1:-}" in
        "list")
            list_actions
            ;;
        "status")
            show_status
            ;;
        "")
            show_usage
            exit 1
            ;;
        *)
            local action_name=$1
            local command=${2:-}
            
            # Check if action exists
            if [[ ! -d "$repo_root/actions/$action_name" ]]; then
                print_error "Action not found: $action_name"
                echo "Available actions:"
                list_actions
                exit 1
            fi
            
            case "$command" in
                "edit")
                    edit_changelog "$action_name"
                    ;;
                "validate")
                    validate_changelog "$action_name"
                    ;;
                v*)
                    prepare_release "$action_name" "$command"
                    ;;
                "")
                    print_error "Command required for action $action_name"
                    show_usage
                    exit 1
                    ;;
                *)
                    print_error "Unknown command: $command"
                    show_usage
                    exit 1
                    ;;
            esac
            ;;
    esac
}

# Run main function with all arguments
main "$@"