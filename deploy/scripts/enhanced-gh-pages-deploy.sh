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
  
  # Verify build succeeded
  if [ ! -d "$SOURCE_DIR" ]; then
    print_message "$RED" "✗ Build failed, $SOURCE_DIR directory not found"
    return 1
  fi
  
  print_message "$GREEN" "✓ Site built successfully"
  
  # Switch to target branch
  print_message "$BLUE" "Switching to $TARGET_BRANCH branch..."
  if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
    # Branch exists, switch to it
    if ! git checkout $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to switch to $TARGET_BRANCH branch"
      return 1
    fi
  else
    # Create branch if it doesn't exist
    if ! git checkout --orphan $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to create $TARGET_BRANCH branch"
      return 1
    fi
    # Remove everything
    git rm -rf . >/dev/null 2>&1 || true
    # Create an initial README
    echo "# ScopeCam MCP Documentation" > README.md
    git add README.md
    git commit -m "Initialize $TARGET_BRANCH branch"
  fi
  
  # Remove existing files (except .git directory and README.md)
  print_message "$BLUE" "Removing existing files in $TARGET_BRANCH branch..."
  find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./README.md" -exec rm -rf {} \;
  
  # Copy new files
  print_message "$BLUE" "Copying new files from $SOURCE_DIR..."
  cp -r "$SOURCE_DIR"/* .
  
  # Create a .nojekyll file to disable GitHub Pages Jekyll processing
  touch .nojekyll
  
  # Add all changes
  print_message "$BLUE" "Adding changes to git..."
  git add .
  
  # Check if there are changes to commit
  if git diff --staged --quiet; then
    print_message "$YELLOW" "No changes to commit. Site is already up to date."
  else
    # Commit changes
    print_message "$BLUE" "Committing changes..."
    git commit -m "Update documentation - $(date +'%Y-%m-%d %H:%M:%S')"
    
    # Push changes
    print_message "$BLUE" "Pushing changes to remote..."
    if ! git push origin $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to push changes to $TARGET_BRANCH"
      
      # Always return to source branch, even after error
      print_message "$BLUE" "Returning to $SOURCE_BRANCH branch..."
      git checkout $SOURCE_BRANCH
      
      return 1
    fi
    
    print_message "$GREEN" "✓ Successfully pushed changes to $TARGET_BRANCH"
  fi
  
  # Return to source branch
  print_message "$BLUE" "Returning to $SOURCE_BRANCH branch..."
  if ! git checkout $SOURCE_BRANCH; then
    print_message "$RED" "✗ Failed to return to $SOURCE_BRANCH branch"
    print_message "$RED" "IMPORTANT: You are still on $TARGET_BRANCH branch!"
    print_message "$YELLOW" "Manually switch back with: git checkout $SOURCE_BRANCH"
    return 1
  fi
  
  # Calculate elapsed time
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  
  print_message "$GREEN" "✓ Deployment with enhanced rendering completed successfully in ${elapsed_time} seconds"
  print_message "$GREEN" "✓ You are now back on the $SOURCE_BRANCH branch"
  return 0
}

# Execute the deployment function
deploy_with_enhanced_rendering

# Exit with the result of the deployment
exit $?