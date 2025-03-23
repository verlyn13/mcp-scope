#!/bin/bash

# Branch Safety Script for MCP Documentation Deployment
# This script provides safety functions for branch operations during deployment

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

# Function to verify current branch
verify_current_branch() {
  local expected_branch=$1
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [ -z "$current_branch" ]; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  if [ "$current_branch" != "$expected_branch" ]; then
    print_message "$RED" "✗ Expected to be on branch '$expected_branch', but current branch is '$current_branch'"
    return 1
  fi
  
  print_message "$GREEN" "✓ Confirmed on branch '$current_branch'"
  return 0
}

# Function to check if working directory is clean
check_clean_working_directory() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  if ! git diff-index --quiet HEAD --; then
    print_message "$RED" "✗ Working directory is not clean"
    print_message "$YELLOW" "Please commit or stash your changes before proceeding"
    git status -s
    return 1
  fi
  
  print_message "$GREEN" "✓ Working directory is clean"
  return 0
}

# Function to safely switch branches
safe_branch_switch() {
  local target_branch=$1
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [ -z "$current_branch" ]; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  # Don't switch if already on target branch
  if [ "$current_branch" == "$target_branch" ]; then
    print_message "$BLUE" "Already on branch '$target_branch'"
    return 0
  fi
  
  # Record the branch switch attempt
  print_message "$BLUE" "Attempting to switch from '$current_branch' to '$target_branch'"
  
  # Try to switch branch
  if ! git checkout "$target_branch" >/dev/null 2>&1; then
    print_message "$RED" "✗ Failed to switch to branch '$target_branch'"
    
    # Check if target branch exists
    if ! git show-ref --verify --quiet refs/heads/"$target_branch"; then
      print_message "$YELLOW" "Branch '$target_branch' does not exist"
      
      # Offer to create branch if it doesn't exist
      read -p "Create branch '$target_branch'? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        if git checkout -b "$target_branch"; then
          print_message "$GREEN" "✓ Created and switched to new branch '$target_branch'"
          return 0
        else
          print_message "$RED" "✗ Failed to create branch '$target_branch'"
        fi
      fi
    fi
    
    return 1
  fi
  
  print_message "$GREEN" "✓ Successfully switched to branch '$target_branch'"
  return 0
}

# Function to safely return to original branch
safe_return_to_branch() {
  local original_branch=$1
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [ -z "$current_branch" ]; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  # Don't switch if already on original branch
  if [ "$current_branch" == "$original_branch" ]; then
    print_message "$BLUE" "Already on branch '$original_branch'"
    return 0
  fi
  
  print_message "$BLUE" "Returning to original branch '$original_branch'"
  
  if ! git checkout "$original_branch" >/dev/null 2>&1; then
    print_message "$RED" "✗ Failed to return to branch '$original_branch'"
    print_message "$YELLOW" "⚠️ WARNING: You are now on branch '$current_branch', not your original branch"
    print_message "$YELLOW" "Manually switch back with: git checkout $original_branch"
    return 1
  fi
  
  print_message "$GREEN" "✓ Successfully returned to branch '$original_branch'"
  return 0
}

# Function to confirm destructive operation
confirm_destructive_operation() {
  local operation=$1
  local target=$2
  
  print_message "$YELLOW" "⚠️ WARNING: About to perform potentially destructive operation"
  print_message "$YELLOW" "Operation: $operation"
  print_message "$YELLOW" "Target: $target"
  
  read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
  echo
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_message "$BLUE" "Proceeding with operation"
    return 0
  else
    print_message "$BLUE" "Operation cancelled"
    return 1
  fi
}

# Function to track branch operations in deployment log
log_branch_operation() {
  local operation=$1
  local from_branch=$2
  local to_branch=$3
  local status=$4
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  # Create log directory if it doesn't exist
  mkdir -p "deploy-reports/branch-logs"
  
  # Append to log file
  echo "[$timestamp] $operation | From: $from_branch | To: $to_branch | Status: $status" >> "deploy-reports/branch-logs/branch-operations.log"
}