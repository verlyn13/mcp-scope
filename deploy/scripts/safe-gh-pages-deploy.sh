#!/bin/bash

# Safe GitHub Pages Deployment Script for MCP Documentation
# This script ensures safe deployment to GitHub Pages with branch management

# Source the branch safety functions
if [ -f "./deploy/scripts/branch-safety.sh" ]; then
  source "./deploy/scripts/branch-safety.sh"
else
  echo "Error: branch-safety.sh not found"
  exit 1
fi

# Default settings
TARGET_BRANCH="gh-pages"
SOURCE_DIR="public"
SKIP_CONFIRM="false"
DRY_RUN="false"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --target-branch)
      TARGET_BRANCH="$2"
      shift
      ;;
    --source-dir)
      SOURCE_DIR="$2"
      shift
      ;;
    --skip-confirm)
      SKIP_CONFIRM="true"
      ;;
    --dry-run)
      DRY_RUN="true"
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --target-branch BRANCH  Set target branch (default: gh-pages)"
      echo "  --source-dir DIR        Set source directory (default: public)"
      echo "  --skip-confirm          Skip confirmation prompts"
      echo "  --dry-run               Run without making actual changes"
      echo "  --help                  Show this help message"
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
echo "        Safe GitHub Pages Deployment Script        "
echo "=================================================="
echo "Target Branch: $TARGET_BRANCH"
echo "Source Directory: $SOURCE_DIR"
echo "Dry Run: $DRY_RUN"
echo "=================================================="
echo ""

# Function to deploy to GitHub Pages with safety measures
safe_deploy_to_gh_pages() {
  # Record starting time
  local start_time=$(date +%s)
  
  # Store the original branch
  local original_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$original_branch" ]; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  print_message "$BLUE" "Starting deployment from branch: $original_branch"
  
  # Validate we're on main branch to start
  if [ "$original_branch" != "main" ]; then
    if [ "$SKIP_CONFIRM" != "true" ]; then
      print_message "$YELLOW" "⚠️ WARNING: You are not on the main branch."
      print_message "$YELLOW" "It is recommended to deploy from the main branch."
      
      if ! confirm_destructive_operation "Continue deployment" "from branch $original_branch"; then
        print_message "$BLUE" "Deployment cancelled"
        return 1
      fi
    else
      print_message "$YELLOW" "⚠️ WARNING: Deploying from non-main branch: $original_branch"
    fi
  fi
  
  # Check for working directory cleanliness
  if ! check_clean_working_directory; then
    print_message "$RED" "✗ Working directory must be clean before deployment"
    return 1
  fi
  
  # Ensure source directory exists
  if [ ! -d "$SOURCE_DIR" ]; then
    print_message "$RED" "✗ Source directory '$SOURCE_DIR' does not exist"
    print_message "$YELLOW" "Build the site first to create the output directory"
    return 1
  fi
  
  # Log the branch operation
  log_branch_operation "Deploy Start" "$original_branch" "$TARGET_BRANCH" "Started"
  
  # Perform the deployment (safely switch branches)
  if ! safe_branch_switch "$TARGET_BRANCH"; then
    print_message "$RED" "✗ Failed to switch to $TARGET_BRANCH branch"
    log_branch_operation "Deploy Fail" "$original_branch" "$TARGET_BRANCH" "Failed to switch branch"
    return 1
  fi
  
  # We're now on the target branch
  print_message "$BLUE" "Preparing to update $TARGET_BRANCH branch"
  
  # If dry run, just show what would happen
  if [ "$DRY_RUN" == "true" ]; then
    print_message "$BLUE" "[DRY RUN] Would update files in $TARGET_BRANCH branch"
    find "$SOURCE_DIR" -type f | wc -l | xargs -I{} echo "[DRY RUN] Would copy {} files"
    
    # Return to original branch
    safe_return_to_branch "$original_branch"
    print_message "$GREEN" "✓ Dry run completed"
    log_branch_operation "Deploy DryRun" "$original_branch" "$TARGET_BRANCH" "Completed"
    return 0
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
    if ! git push origin "$TARGET_BRANCH"; then
      print_message "$RED" "✗ Failed to push changes to $TARGET_BRANCH"
      log_branch_operation "Deploy Fail" "$original_branch" "$TARGET_BRANCH" "Failed to push"
      
      # Return to original branch even after failure
      safe_return_to_branch "$original_branch"
      return 1
    fi
    
    print_message "$GREEN" "✓ Successfully pushed changes to $TARGET_BRANCH"
  fi
  
  # Return to original branch
  if ! safe_return_to_branch "$original_branch"; then
    print_message "$RED" "✗ Failed to return to original branch"
    log_branch_operation "Deploy Partial" "$TARGET_BRANCH" "$original_branch" "Failed to return"
    return 1
  fi
  
  # Calculate elapsed time
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  
  # Log successful completion
  log_branch_operation "Deploy Complete" "$original_branch" "$TARGET_BRANCH" "Success (${elapsed_time}s)"
  
  print_message "$GREEN" "✓ Deployment completed successfully in ${elapsed_time} seconds"
  return 0
}

# Execute the deployment function
safe_deploy_to_gh_pages

# Exit with the result of the deployment
exit $?