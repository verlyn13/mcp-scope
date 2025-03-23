#!/bin/bash

# Simple alias script for MCP documentation deployment
# This provides a user-friendly command for deploying documentation to GitHub Pages
# With proper support for badges, emojis, and HTML in markdown

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}=================================================="
echo -e "       MCP Documentation Deployment Tool        "
echo -e "==================================================${NC}"

# Check if help was requested
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  echo "Usage: ./deploy-docs.sh [options]"
  echo ""
  echo "Options:"
  echo "  --build-only     Build the site without deploying"
  echo "  --deploy-only    Deploy existing build without rebuilding"
  echo "  --dry-run        Test deployment without making actual changes"
  echo "  --help, -h       Show this help message"
  echo ""
  echo "Without options, this will both build and deploy the documentation."
  echo "This script uses enhanced rendering to properly handle badges, emojis, and HTML."
  exit 0
fi

# Default behavior
BUILD="true"
DEPLOY="true"
DRY_RUN=""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --build-only)
      BUILD="true"
      DEPLOY="false"
      ;;
    --deploy-only)
      BUILD="false"
      DEPLOY="true"
      ;;
    --dry-run)
      DRY_RUN="--dry-run"
      ;;
  esac
done

# Step 1: Build the site (now integrated into the enhanced deploy script)
if [ "$BUILD" == "true" ] && [ "$DEPLOY" == "true" ]; then
  echo -e "${BLUE}Building and deploying documentation site...${NC}"
  # The enhanced script handles both building and deploying
  ./deploy/scripts/enhanced-gh-pages-deploy.sh $DRY_RUN
  
  # Check if deployment was successful
  if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed.${NC}"
    exit 1
  fi
elif [ "$BUILD" == "true" ] && [ "$DEPLOY" == "false" ]; then
  echo -e "${BLUE}Building documentation site only...${NC}"
  # Create necessary directories and copy content
  mkdir -p content
  
  # Copy the main README with badges to the index
  if [ -f "mcp-project/README.md" ]; then
    # Create a proper front matter for the home page
    cat > content/_index.md << EOL
---
title: "ScopeCam MCP"
description: "Multi-Agent Control Platform for ScopeCam Integration"
---

$(cat mcp-project/README.md)
EOL
    echo -e "${GREEN}✓ Main README with badges copied to content/_index.md${NC}"
  else
    echo -e "${YELLOW}⚠ mcp-project/README.md not found, using default README${NC}"
    cp README.md content/_index.md
  fi
  
  # Build the site using Hugo
  if command -v hugo > /dev/null; then
    # Use local Hugo
    if ! hugo --minify; then
      echo -e "${RED}✗ Hugo build failed${NC}"
      exit 1
    fi
  elif command -v docker > /dev/null; then
    # Use Docker
    if ! docker run --rm -v "$(pwd)":/src -w /src klakegg/hugo:latest --minify; then
      echo -e "${RED}✗ Hugo build with Docker failed${NC}"
      exit 1
    fi
  elif command -v podman > /dev/null; then
    # Use Podman
    if ! podman run --rm -v "$(pwd)":/src:z -w /src docker.io/klakegg/hugo:latest --minify; then
      echo -e "${RED}✗ Hugo build with Podman failed${NC}"
      exit 1
    fi
  else
    echo -e "${RED}✗ Hugo not found and no container runtime available${NC}"
    exit 1
  fi
  
  # Verify build succeeded
  if [ ! -d "public" ]; then
    echo -e "${RED}✗ Build failed, public directory not found${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✓ Site built successfully${NC}"
  echo -e "${GREEN}✓ The built site is available in the 'public' directory${NC}"
elif [ "$BUILD" == "false" ] && [ "$DEPLOY" == "true" ]; then
  echo -e "${BLUE}Deploying existing build...${NC}"
  
  # Check if public directory exists
  if [ ! -d "public" ]; then
    echo -e "${RED}✗ Public directory not found. Build the site first.${NC}"
    echo -e "${YELLOW}Run: ./deploy-docs.sh --build-only${NC}"
    exit 1
  fi
  
  # Deploy using the enhanced script with deploy-only option
  ./deploy/scripts/enhanced-gh-pages-deploy.sh $DRY_RUN
  
  # Check if deployment was successful
  if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed.${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✓ All operations completed successfully${NC}"
exit 0