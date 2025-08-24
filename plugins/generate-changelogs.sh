#!/bin/bash

# Script to generate changelog.md for all repositories in cloned_repos directory
# Uses git-cliff to generate changelogs

set -e  # Exit on any error

# Configuration
REPOS_DIR="cloned_repos"
CHANGELOG_FILE="CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if git-cliff is installed
check_git_cliff() {
    if ! command -v git-cliff &> /dev/null; then
        print_error "git-cliff is not installed or not in PATH"
        print_error "Please install git-cliff from https://git-cliff.org/docs/installation"
        exit 1
    fi
    print_success "git-cliff found: $(git-cliff --version)"
}

# Check if cloned_repos directory exists
check_repos_directory() {
    if [[ ! -d "$REPOS_DIR" ]]; then
        print_error "Directory '$REPOS_DIR' not found"
        print_error "Please create the directory and clone your repositories into it"
        exit 1
    fi
    print_success "Found repositories directory: $REPOS_DIR"
}

# Generate changelog for a single repository
generate_changelog() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    print_status "Processing repository: $repo_name"
    
    # Change to repository directory
    cd "$repo_path"
    
    # Check if it's a git repository
    if [[ ! -d ".git" ]]; then
        print_warning "Skipping '$repo_name' - not a git repository"
        cd - > /dev/null
        return 1
    fi
    
    # Check if there are any commits
    if ! git rev-parse HEAD &> /dev/null; then
        print_warning "Skipping '$repo_name' - no commits found"
        cd - > /dev/null
        return 1
    fi
    
    # Generate changelog
    print_status "Generating changelog for $repo_name..."
    
    if git-cliff --output "$CHANGELOG_FILE"; then
        print_success "Generated changelog for $repo_name"
        
        # Show some stats
        local line_count=$(wc -l < "$CHANGELOG_FILE" 2>/dev/null || echo "0")
        print_status "Changelog contains $line_count lines"
    else
        print_error "Failed to generate changelog for $repo_name"
        cd - > /dev/null
        return 1
    fi
    
    # Return to original directory
    cd - > /dev/null
    return 0
}

# Main function
main() {
    print_status "Starting changelog generation process..."
    
    # Perform checks
    check_git_cliff
    check_repos_directory
    
    # Count repositories
    local repo_count=0
    local success_count=0
    local failed_count=0
    
    print_status "Scanning for repositories in $REPOS_DIR..."
    
    # Process each directory in cloned_repos
    for repo_dir in "$REPOS_DIR"/*; do
        # Skip if not a directory
        [[ ! -d "$repo_dir" ]] && continue
        
        repo_count=$((repo_count + 1))
        
        echo ""
        print_status "Repository $repo_count: $(basename "$repo_dir")"
        print_status "Path: $repo_dir"
        
        if generate_changelog "$repo_dir"; then
            success_count=$((success_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
    done
    
    # Summary
    echo ""
    print_status "=== SUMMARY ==="
    print_status "Total repositories processed: $repo_count"
    print_success "Successful: $success_count"
    if [[ $failed_count -gt 0 ]]; then
        print_error "Failed: $failed_count"
    else
        print_success "Failed: $failed_count"
    fi
    
    if [[ $repo_count -eq 0 ]]; then
        print_warning "No repositories found in $REPOS_DIR"
        print_warning "Make sure to clone repositories into the $REPOS_DIR directory"
    elif [[ $success_count -eq $repo_count ]]; then
        print_success "All repositories processed successfully!"
    fi
}

# Show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Generate changelog.md files for all git repositories in the cloned_repos directory"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -d, --dir DIR  Use DIR instead of 'cloned_repos' as the repositories directory"
    echo ""
    echo "Requirements:"
    echo "  - git-cliff must be installed (https://git-cliff.org/docs/installation)"
    echo "  - Repositories must be in the specified directory (default: cloned_repos/)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Use default 'cloned_repos' directory"
    echo "  $0 -d my_repos       # Use 'my_repos' directory"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            REPOS_DIR="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main