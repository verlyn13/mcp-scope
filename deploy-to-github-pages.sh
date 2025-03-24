#!/bin/bash

# Script to deploy Hugo site to GitHub Pages using locally sourced token
# This script is an alternative to GitHub Actions when you want to use local credentials

set -e  # Exit on any error

# Text formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}=================================================="
echo -e "     Local GitHub Pages Deployment Script       "
echo -e "==================================================${NC}"

# Source the GitHub token from your secrets file
if [ -f "/home/verlyn13/.secrets/mcp-scope/github_token" ]; then
  echo -e "${GREEN}✓ Loading GitHub token from local secrets file${NC}"
  source /home/verlyn13/.secrets/mcp-scope/github_token
else
  echo -e "${RED}✗ GitHub token file not found at /home/verlyn13/.secrets/mcp-scope/github_token${NC}"
  exit 1
fi

# Check if the token is available
if [ -z "$GH_PAT" ]; then
  echo -e "${RED}✗ GitHub token not found in environment variables${NC}"
  echo -e "${YELLOW}Make sure the token file exports a variable named GH_PAT${NC}"
  exit 1
fi

# Build the Hugo site
echo -e "${BLUE}Building Hugo site...${NC}"
./deploy-docs.sh --build-only

# Check if build was successful
if [ ! -d "public" ]; then
  echo -e "${RED}✗ Hugo build failed - public directory not found${NC}"
  exit 1
fi

# List the files in the public directory to verify content
echo -e "${BLUE}Verifying build output...${NC}"
echo "Files in public directory:"
ls -la public/
echo ""

if [ ! -f "public/index.html" ]; then
  echo -e "${RED}✗ index.html not found in public directory${NC}"
  exit 1
else
  echo -e "${GREEN}✓ index.html found in public directory${NC}"
fi

# Configure Git for deployment
echo -e "${BLUE}Configuring Git for deployment...${NC}"
REPO_URL="https://${GH_PAT}@github.com/verlyn13/mcp-scope.git"

# Save current branch to return to it later
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch is ${CURRENT_BRANCH}, will return to it after deployment${NC}"

# Create or switch to gh-pages branch
echo -e "${BLUE}Switching to gh-pages branch...${NC}"
if git show-ref --verify --quiet refs/heads/gh-pages; then
  git checkout gh-pages
else
  git checkout --orphan gh-pages
  # Remove everything to start with a clean branch
  git rm -rf . || true
  # Create an empty commit to start with a clean history
  git commit --allow-empty -m "Initialize gh-pages branch"
fi

# Remove existing files but keep .git directory
echo -e "${BLUE}Cleaning gh-pages branch...${NC}"
# Use find to list and remove files (excluding .git directory)
find . -mindepth 1 -maxdepth 1 -not -path "./.git" -exec rm -rf {} \; 2>/dev/null || true

# Copy the built site to the root
echo -e "${BLUE}Copying Hugo build to gh-pages branch root...${NC}"
cp -r public/* .
touch .nojekyll  # Add .nojekyll file to disable Jekyll processing

# Verify files were copied correctly
echo -e "${BLUE}Verifying files in gh-pages branch...${NC}"
echo "Files in gh-pages branch root:"
ls -la
echo ""

if [ ! -f "index.html" ]; then
  echo -e "${RED}✗ index.html not found in gh-pages root${NC}"
  # Try to fix by copying again directly
  echo -e "${YELLOW}Attempting to copy index.html directly...${NC}"
  cp public/index.html .
  if [ ! -f "index.html" ]; then
    echo -e "${RED}✗ Failed to copy index.html${NC}"
    git checkout $CURRENT_BRANCH
    exit 1
  fi
else
  echo -e "${GREEN}✓ index.html found in gh-pages root${NC}"
fi

# Add all changes
echo -e "${BLUE}Committing changes...${NC}"
git add --all

# Create a commit message with a timestamp
COMMIT_MSG="Update documentation - $(date +'%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG" || {
  echo -e "${YELLOW}⚠ No changes to commit. Site is already up to date.${NC}"
  git checkout $CURRENT_BRANCH
  exit 0
}

# Push changes to GitHub using the token for authentication
echo -e "${BLUE}Pushing to GitHub with authentication...${NC}"
git push -f "$REPO_URL" gh-pages

# Switch back to original branch
echo -e "${BLUE}Switching back to ${CURRENT_BRANCH} branch...${NC}"
git checkout $CURRENT_BRANCH

echo -e "${GREEN}✓ Successfully deployed to GitHub Pages using local token${NC}"
echo -e "${GREEN}✓ Site should be available at https://verlyn13.github.io/mcp-scope/${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for GitHub Pages to update${NC}"