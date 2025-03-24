#!/bin/bash

# Emergency script to fix GitHub Pages structure issues
# This script directly fixes the gh-pages branch structure

set -e  # Exit on any error

# Text formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}=================================================="
echo -e "     Emergency GitHub Pages Structure Fix     "
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

# Save current branch to return to it later
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch is ${CURRENT_BRANCH}, will return to it after fixing${NC}"

# Build the Hugo site (optional - only if needed)
if [ ! -d "public" ] || [ ! -f "public/index.html" ]; then
  echo -e "${BLUE}Building Hugo site...${NC}"
  ./deploy-docs.sh --build-only

  # Check if build was successful
  if [ ! -d "public" ] || [ ! -f "public/index.html" ]; then
    echo -e "${RED}✗ Hugo build failed - index.html not found in public directory${NC}"
    exit 1
  fi
else
  echo -e "${GREEN}✓ Public directory with index.html already exists${NC}"
fi

# Configure Git for deployment
echo -e "${BLUE}Configuring Git for deployment...${NC}"
REPO_URL="https://${GH_PAT}@github.com/verlyn13/mcp-scope.git"

# Switch to gh-pages branch
echo -e "${BLUE}Switching to gh-pages branch...${NC}"
if git show-ref --verify --quiet refs/heads/gh-pages; then
  git checkout gh-pages
else
  echo -e "${YELLOW}Creating new gh-pages branch...${NC}"
  git checkout --orphan gh-pages
  git rm -rf . || true
  git commit --allow-empty -m "Initialize gh-pages branch"
fi

# Remove all files except .git directory
echo -e "${BLUE}Cleaning gh-pages branch...${NC}"
git rm -rf . || true

# Create a list of all files in the public directory
echo -e "${BLUE}Listing files in public directory...${NC}"
find ../public -type f | sort

# Copy files from public to root of gh-pages branch
echo -e "${BLUE}Copying files from public directly to gh-pages root...${NC}"
cp -r ../public/* .
touch .nojekyll  # Add .nojekyll file

# List files to verify copy
echo -e "${BLUE}Verifying copy...${NC}"
ls -la

# Check specifically for index.html
if [ -f "index.html" ]; then
  echo -e "${GREEN}✓ index.html successfully copied to gh-pages root${NC}"
else
  echo -e "${RED}✗ index.html not found in gh-pages root after copy${NC}"
  
  # Try a direct specific copy of index.html
  echo -e "${YELLOW}Attempting direct copy of index.html...${NC}"
  cp ../public/index.html .
  
  if [ -f "index.html" ]; then
    echo -e "${GREEN}✓ index.html successfully copied with direct command${NC}"
  else
    echo -e "${RED}✗ Direct copy failed. Aborting.${NC}"
    git checkout $CURRENT_BRANCH
    exit 1
  fi
fi

# Add all files to git
echo -e "${BLUE}Adding files to git...${NC}"
git add --all

# Commit changes
echo -e "${BLUE}Committing changes...${NC}"
git commit -m "Fix GitHub Pages structure - $(date +'%Y-%m-%d %H:%M:%S')" || {
  echo -e "${YELLOW}No changes to commit${NC}"
}

# Push changes
echo -e "${BLUE}Pushing changes to GitHub...${NC}"
git push -f "$REPO_URL" gh-pages

# Switch back to original branch
git checkout $CURRENT_BRANCH

echo -e "${GREEN}✓ GitHub Pages structure fix complete${NC}"
echo -e "${GREEN}✓ Site should be available at https://verlyn13.github.io/mcp-scope/${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for GitHub Pages to update${NC}"