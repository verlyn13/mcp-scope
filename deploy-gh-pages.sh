#!/bin/bash

# Simple and reliable script to deploy Hugo site to GitHub Pages
# This script ensures content from public/ directory is properly copied to the root of gh-pages branch

set -e  # Exit on any error

# Text formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}=================================================="
echo -e "     Hugo GitHub Pages Deployment Script       "
echo -e "==================================================${NC}"

# Save current branch to return to it later
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}Current branch is ${CURRENT_BRANCH}${NC}"
echo -e "${BLUE}Will return to this branch after deployment${NC}"

# Source the GitHub token if available
if [ -f "/home/verlyn13/.secrets/mcp-scope/github_token" ]; then
  echo -e "${GREEN}✓ Loading GitHub token from local secrets file${NC}"
  source /home/verlyn13/.secrets/mcp-scope/github_token
  # Configure Git for deployment with token
  if [ ! -z "$GH_PAT" ]; then
    REPO_URL="https://${GH_PAT}@github.com/verlyn13/mcp-scope.git"
    USING_TOKEN=true
    echo -e "${GREEN}✓ GitHub token loaded successfully${NC}"
  else
    echo -e "${YELLOW}⚠ GitHub token file exists but GH_PAT variable not found${NC}"
    USING_TOKEN=false
  fi
else
  echo -e "${YELLOW}⚠ GitHub token file not found, will use standard authentication${NC}"
  USING_TOKEN=false
fi

# Step 1: Build the Hugo site
echo -e "${BLUE}Step 1: Building Hugo site...${NC}"
if [ -f "./deploy-docs.sh" ]; then
  ./deploy-docs.sh --build-only
else
  echo -e "${YELLOW}⚠ deploy-docs.sh not found, trying to build Hugo directly${NC}"
  if command -v hugo &> /dev/null; then
    hugo
  else
    echo -e "${RED}✗ Hugo command not found and no deploy-docs.sh script available${NC}"
    echo -e "${RED}✗ Cannot build the site${NC}"
    exit 1
  fi
fi

# Check if build was successful by looking for public directory and index.html
if [ ! -d "public" ]; then
  echo -e "${RED}✗ Build failed - public directory not found${NC}"
  exit 1
fi

if [ ! -f "public/index.html" ]; then
  echo -e "${RED}✗ Build failed - index.html not found in public directory${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Hugo site built successfully${NC}"

# Step 2: Switch to gh-pages branch or create it if it doesn't exist
echo -e "${BLUE}Step 2: Preparing gh-pages branch...${NC}"
if git show-ref --verify --quiet refs/heads/gh-pages; then
  echo -e "${BLUE}Checking out existing gh-pages branch${NC}"
  git checkout gh-pages
else
  echo -e "${BLUE}Creating new gh-pages branch${NC}"
  git checkout --orphan gh-pages
  git rm -rf . || true
  git commit --allow-empty -m "Initialize gh-pages branch"
fi

# Step 3: Remove all existing files on gh-pages branch except .git
echo -e "${BLUE}Step 3: Cleaning gh-pages branch...${NC}"
find . -maxdepth 1 -not -path "./.git" -not -path "." -exec rm -rf {} \; 2>/dev/null || true

# Step 4: Copy files from public directory to root of gh-pages branch
echo -e "${BLUE}Step 4: Copying files from public directory to gh-pages branch root...${NC}"
cp -r ../public/* .
touch .nojekyll  # Create .nojekyll file to disable Jekyll processing

# Verify index.html exists in the root
if [ ! -f "index.html" ]; then
  echo -e "${RED}✗ Failed to copy index.html to gh-pages branch root${NC}"
  echo -e "${BLUE}Trying direct copy of index.html...${NC}"
  cp ../public/index.html .
  
  if [ ! -f "index.html" ]; then
    echo -e "${RED}✗ Failed to copy index.html directly${NC}"
    echo -e "${RED}✗ Aborting deployment${NC}"
    git checkout "$CURRENT_BRANCH"
    exit 1
  fi
fi

echo -e "${GREEN}✓ Files copied successfully${NC}"

# Step 5: Commit and push changes
echo -e "${BLUE}Step 5: Committing and pushing changes...${NC}"
git add --all
git commit -m "Update site - $(date +'%Y-%m-%d %H:%M:%S')" || {
  echo -e "${YELLOW}⚠ No changes to commit${NC}"
  echo -e "${YELLOW}⚠ Site is already up to date${NC}"
  git checkout "$CURRENT_BRANCH"
  exit 0
}

# Push changes using token or standard push
if [ "$USING_TOKEN" = true ]; then
  echo -e "${BLUE}Pushing with GitHub token...${NC}"
  git push -f "$REPO_URL" gh-pages
else
  echo -e "${BLUE}Pushing normally...${NC}"
  git push -f origin gh-pages
fi

# Step 6: Return to original branch
echo -e "${BLUE}Step 6: Returning to ${CURRENT_BRANCH} branch...${NC}"
git checkout "$CURRENT_BRANCH"

echo -e "${GREEN}✓ Deployment completed successfully${NC}"
echo -e "${GREEN}✓ Site should be available at https://verlyn13.github.io/mcp-scope/${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for GitHub Pages to update${NC}"