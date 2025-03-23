#!/bin/bash

# Simple alias script for MCP documentation deployment
# This provides a user-friendly command for deploying documentation to GitHub Pages

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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
  echo "  --build-only    Build the site without deploying"
  echo "  --deploy-only   Deploy existing build without rebuilding"
  echo "  --dry-run       Test deployment without making changes"
  echo "  --help          Show this help message"
  echo ""
  echo "Without options, this will both build and deploy the documentation."
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

# Step 1: Build the site
if [ "$BUILD" == "true" ]; then
  echo -e "${BLUE}Building documentation site...${NC}"
  ./deploy/unified-deploy.sh --mode local --skip-git
  
  # Check if build was successful
  if [ ! -d "public" ]; then
    echo -e "${RED}Build failed. The 'public' directory was not created.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✓ Site built successfully${NC}"
fi

# Step 2: Deploy to GitHub Pages
if [ "$DEPLOY" == "true" ]; then
  echo -e "${BLUE}Deploying to GitHub Pages...${NC}"
  ./deploy/scripts/standard-gh-pages-deploy.sh $DRY_RUN
  
  # Check if deployment was successful
  if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment failed.${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✓ All operations completed successfully${NC}"
exit 0