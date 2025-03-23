#!/bin/bash

# Standard GitHub Pages Deployment Script for MCP Documentation
# This script implements the standard GitHub Pages workflow:
# - All development on main branch
# - Deploy built site to gh-pages branch
# - Always return to main after deployment

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
SOURCE_BRANCH="main"       # Always deploy from main branch
TARGET_BRANCH="gh-pages"   # Always deploy to gh-pages branch
SOURCE_DIR="public"        # Built site directory
DRY_RUN="false"            # Default to actual deployment

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --source-dir)
      SOURCE_DIR="$2"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --source-dir DIR    Set source directory (default: public)"
      echo "  --dry-run           Run without making actual changes"
      echo "  --help              Show this help message"
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
echo "       Standard GitHub Pages Deployment Script     "
echo "=================================================="
echo "Source Branch: $SOURCE_BRANCH"
echo "Target Branch: $TARGET_BRANCH"
echo "Source Directory: $SOURCE_DIR"
echo "Dry Run: $DRY_RUN"
echo "=================================================="
echo ""

# Function to deploy to GitHub Pages
deploy_to_github_pages() {
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
  
  # Ensure source directory exists
  if [ ! -d "$SOURCE_DIR" ]; then
    print_message "$RED" "✗ Source directory '$SOURCE_DIR' does not exist"
    print_message "$YELLOW" "Build the site first with: ./deploy/unified-deploy.sh --mode local --skip-git"
    return 1
  fi
  
  print_message "$BLUE" "Deploying from $SOURCE_BRANCH to $TARGET_BRANCH..."
  
  # If dry run, just show what would happen
  if [ "$DRY_RUN" == "true" ]; then
    print_message "$BLUE" "[DRY RUN] Would deploy from $SOURCE_BRANCH to $TARGET_BRANCH"
    print_message "$BLUE" "[DRY RUN] Would copy $(find "$SOURCE_DIR" -type f | wc -l) files"
    print_message "$GREEN" "✓ Dry run completed, no changes made"
    return 0
  fi
  
  # Check if target branch exists
  if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
    print_message "$BLUE" "Target branch $TARGET_BRANCH exists"
  else
    # If target branch doesn't exist, create it
    print_message "$YELLOW" "Target branch $TARGET_BRANCH does not exist, creating..."
    if ! git checkout --orphan $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to create $TARGET_BRANCH branch"
      return 1
    fi
    # Create a clean initial state
    git rm -rf .
    echo "# MCP Documentation" > README.md
    git add README.md
    git commit -m "Initialize $TARGET_BRANCH branch"
    
    # Return to source branch
    if ! git checkout $SOURCE_BRANCH; then
      print_message "$RED" "✗ Failed to return to $SOURCE_BRANCH branch"
      return 1
    fi
  fi
  
  # Switch to target branch
  print_message "$BLUE" "Switching to $TARGET_BRANCH branch..."
  if ! git checkout $TARGET_BRANCH; then
    print_message "$RED" "✗ Failed to switch to $TARGET_BRANCH branch"
    return 1
  fi
  
  # Remove existing files (except .git directory and README.md)
  print_message "$BLUE" "Removing existing files in $TARGET_BRANCH branch..."
  find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./README.md" -exec rm -rf {} \;
  
  # Copy new files
  print_message "$BLUE" "Copying new files from $SOURCE_DIR..."
  cp -r "$SOURCE_DIR"/* .
  
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
  
  print_message "$GREEN" "✓ Deployment completed successfully in ${elapsed_time} seconds"
  print_message "$GREEN" "✓ You are now back on the $SOURCE_BRANCH branch"
  return 0
}

# Execute the deployment function
deploy_to_github_pages

# Exit with the result of the deployment
exit $?