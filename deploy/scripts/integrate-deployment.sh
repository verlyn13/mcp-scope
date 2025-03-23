#!/bin/bash

# Integration script for the main unified-deploy.sh with safe branch management
# This adds the safe branch management features to the existing deployment workflow

# Update the deploy_to_github_pages function in unified-deploy.sh
# This should be done by sourcing this script at the beginning of unified-deploy.sh

# New flag to use enhanced branch safety
USE_SAFE_BRANCH="false"

# Function to deploy to GitHub Pages with improved branch safety
enhanced_deploy_to_github_pages() {
  if [[ "$SKIP_GIT" == "true" ]]; then
    print_message "$YELLOW" "⚠ Skipping Git operations as requested"
    print_message "$GREEN" "✓ Site built in 'public' directory"
    return 0
  fi
  
  print_message "$BLUE" "Deploying to GitHub Pages ($TARGET_BRANCH branch)..."
  
  # Check if we should use the enhanced branch safety script
  if [[ "$USE_SAFE_BRANCH" == "true" ]]; then
    if [ -f "./deploy/scripts/safe-gh-pages-deploy.sh" ]; then
      print_message "$BLUE" "Using enhanced branch safety for deployment"
      
      # Build options for the safe deployment script
      local options=""
      
      if [[ "$TARGET_BRANCH" != "gh-pages" ]]; then
        options="$options --target-branch $TARGET_BRANCH"
      fi
      
      if [[ "$OUTPUT_MODE" == "quiet" ]]; then
        options="$options --skip-confirm"
      fi
      
      # Execute the safe deployment script
      ./deploy/scripts/safe-gh-pages-deploy.sh $options
      local result=$?
      
      if [ $result -eq 0 ]; then
        print_message "$GREEN" "✓ Deployment completed successfully with enhanced branch safety"
      else
        print_message "$RED" "✗ Deployment failed"
      fi
      
      return $result
    else
      print_message "$YELLOW" "⚠ safe-gh-pages-deploy.sh not found, falling back to standard deployment"
    fi
  fi
  
  # Continue with original deployment function if enhanced script not used
  # ... (existing deploy_to_github_pages code here)
  return 0
}

# Function to parse additional arguments
parse_additional_args() {
  # Add the USE_SAFE_BRANCH flag to argument parsing
  case $1 in
    --safe-branch)
      USE_SAFE_BRANCH="true"
      ;;
  esac
}

# Add a note for integrating this script
echo "This script should be sourced from the unified-deploy.sh script"
echo "Add the following near the beginning of unified-deploy.sh:"
echo ""
echo "# Source enhanced deployment functions"
echo "if [ -f \"./deploy/scripts/integrate-deployment.sh\" ]; then"
echo "  source \"./deploy/scripts/integrate-deployment.sh\""
echo "fi"
echo ""
echo "Then replace the deploy_to_github_pages function call with enhanced_deploy_to_github_pages"