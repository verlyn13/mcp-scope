#!/bin/bash

# Enhanced GitHub Pages Deployment for MCP Documentation
# This script properly handles badges, emojis, and HTML in markdown

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Default settings
SOURCE_BRANCH="main"
TARGET_BRANCH="gh-pages"
SOURCE_DIR="public"
DRY_RUN="false"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="true"
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --dry-run        Run without making actual changes"
      echo "  --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown parameter: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
  shift
done

# Banner
echo "=================================================="
echo "     Enhanced GitHub Pages Deployment Script       "
echo "=================================================="
echo "Dry Run: $DRY_RUN"
echo "=================================================="
echo ""

# Function to deploy to GitHub Pages with proper rendering
deploy_with_enhanced_rendering() {
  # Record starting time
  local start_time=$(date +%s)
  
  # Store the current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$current_branch" ]; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  # Verify we're on the main branch
  if [ "$current_branch" != "$SOURCE_BRANCH" ]; then
    print_message "$RED" "✗ Deployment must start from $SOURCE_BRANCH branch"
    print_message "$YELLOW" "You are currently on branch: $current_branch"
    print_message "$YELLOW" "Switch to $SOURCE_BRANCH branch first with: git checkout $SOURCE_BRANCH"
    return 1
  fi
  
  # Check if working directory is clean
  if ! git diff-index --quiet HEAD --; then
    print_message "$RED" "✗ Working directory is not clean"
    print_message "$YELLOW" "Commit or stash your changes before deploying"
    git status -s
    return 1
  fi
  
  # Use the comprehensive content copying script
  print_message "$BLUE" "Preparing all documentation content..."
  ./deploy/scripts/copy-all-content.sh
  
  # Check if content preparation was successful
  if [ $? -ne 0 ]; then
    print_message "$RED" "✗ Content preparation failed"
    return 1
  fi
  
  # If dry run, just show what would happen
  if [ "$DRY_RUN" == "true" ]; then
    print_message "$BLUE" "[DRY RUN] Would build Hugo site with enhanced rendering"
    print_message "$BLUE" "[DRY RUN] Would deploy to $TARGET_BRANCH branch"
    print_message "$GREEN" "✓ Dry run completed, no changes made"
    return 0
  fi
  
  # Build the site
  print_message "$BLUE" "Building Hugo site with enhanced rendering..."
  if command -v hugo > /dev/null; then
    # Use local Hugo
    if ! hugo --minify; then
      print_message "$RED" "✗ Hugo build failed"
      return 1
    fi
  elif command -v docker > /dev/null; then
    # Use Docker
    if ! docker run --rm -v "$(pwd)":/src -w /src klakegg/hugo:latest --minify; then
      print_message "$RED" "✗ Hugo build with Docker failed"
      return 1
    fi
  elif command -v podman > /dev/null; then
    # Use Podman
    if ! podman run --rm -v "$(pwd)":/src:z -w /src docker.io/klakegg/hugo:latest --minify; then
      print_message "$RED" "✗ Hugo build with Podman failed"
      return 1
    fi
  else
    print_message "$RED" "✗ Hugo not found and no container runtime available"
    return 1
  fi