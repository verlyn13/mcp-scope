#!/bin/bash

# MCP Documentation GitHub Deployment Script
# This script provides a streamlined way to commit and push changes to GitHub,
# which will automatically trigger the GitHub Actions deployment workflow.

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║               MCP Documentation Deployment                 ║"
echo "║             GitHub Actions Deployment Helper               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to check if gh CLI is installed
check_gh_cli() {
  if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI (gh) is not installed.${NC}"
    echo -e "${YELLOW}Workflow status checks will be disabled.${NC}"
    echo -e "${YELLOW}Install gh CLI for enhanced workflow monitoring.${NC}"
    return 1
  fi
  
  # Check if authenticated
  if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI is not authenticated.${NC}"
    echo -e "${YELLOW}Run 'gh auth login' to authenticate.${NC}"
    return 1
  fi
  
  return 0
}

# Function to get current branch
get_current_branch() {
  git branch --show-current
}

# Function to check for uncommitted changes
check_uncommitted_changes() {
  if [[ -n $(git status -s) ]]; then
    return 0 # Has changes
  else
    return 1 # No changes
  fi
}

# Function to commit and push changes
commit_and_push() {
  local commit_message="$1"
  local branch="$2"
  
  # Add all changes
  echo -e "${BLUE}Adding all changes to git...${NC}"
  git add .
  
  # Commit changes
  echo -e "${BLUE}Committing changes...${NC}"
  git commit -m "$commit_message"
  
  # Push to remote
  echo -e "${BLUE}Pushing to $branch branch...${NC}"
  git push origin "$branch"
  
  return $?
}

# Function to monitor workflow
monitor_workflow() {
  local repo=$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')
  
  echo -e "${BLUE}Waiting for workflow to start...${NC}"
  sleep 5 # Give GitHub a moment to register the push
  
  echo -e "${BLUE}Opening workflow status in browser...${NC}"
  gh workflow view "Deploy Hugo site to GitHub Pages" --repo "$repo"
  
  echo -e "${GREEN}You can monitor the workflow status in your browser.${NC}"
  echo -e "${GREEN}Once complete, your site will be available at:${NC}"
  
  # Extract username and repo name
  IFS='/' read -r username reponame <<< "$repo"
  echo -e "${GREEN}https://$username.github.io/$reponame/${NC}"
}

# Function to manually trigger workflow
trigger_workflow() {
  local branch="$1"
  local repo=$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')
  
  echo -e "${BLUE}Manually triggering GitHub Actions workflow...${NC}"
  gh workflow run "Deploy Hugo site to GitHub Pages" --ref "$branch" --repo "$repo"
  
  return $?
}

# Main function
main() {
  local current_branch=$(get_current_branch)
  
  # Check if we're on main branch
  if [[ "$current_branch" != "main" ]]; then
    echo -e "${YELLOW}Warning: You are not on the main branch.${NC}"
    echo -e "${YELLOW}Current branch: $current_branch${NC}"
    
    read -p "Do you want to continue anyway? (y/n): " choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
      echo -e "${RED}Deployment aborted.${NC}"
      exit 1
    fi
  fi
  
  # Check for uncommitted changes
  if ! check_uncommitted_changes; then
    echo -e "${YELLOW}No uncommitted changes detected.${NC}"
    
    read -p "Do you want to trigger the workflow anyway? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
      if check_gh_cli; then
        trigger_workflow "$current_branch"
        monitor_workflow
      else
        echo -e "${RED}Cannot trigger workflow without GitHub CLI.${NC}"
        echo -e "${RED}Please install and authenticate gh CLI first.${NC}"
        exit 1
      fi
    else
      echo -e "${RED}Deployment aborted.${NC}"
      exit 1
    fi
    
    exit 0
  fi
  
  # Prompt for commit message
  read -p "Enter commit message [Documentation update]: " commit_message
  if [[ -z "$commit_message" ]]; then
    commit_message="Documentation update"
  fi
  
  # Add prefix if not present
  if [[ ! "$commit_message" =~ ^docs: ]]; then
    commit_message="docs: $commit_message"
  fi
  
  # Commit and push changes
  if commit_and_push "$commit_message" "$current_branch"; then
    echo -e "${GREEN}Changes pushed successfully!${NC}"
    
    # Check if gh CLI is available for workflow monitoring
    if check_gh_cli; then
      monitor_workflow
    else
      echo -e "${YELLOW}GitHub CLI not available. Cannot monitor workflow.${NC}"
      echo -e "${YELLOW}Check your Actions tab in the GitHub repository.${NC}"
    fi
  else
    echo -e "${RED}Error pushing changes.${NC}"
    exit 1
  fi
}

# Execute main function
main