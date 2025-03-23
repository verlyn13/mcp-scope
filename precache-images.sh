#!/bin/bash

# Script to pre-cache container images for the MCP Documentation system
# Run this during environment setup to prevent runtime issues

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

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Detect container runtime
CONTAINER_CMD=""
if command_exists podman; then
  CONTAINER_CMD="podman"
  print_message "$GREEN" "✓ Using Podman as container runtime"
elif command_exists docker; then
  CONTAINER_CMD="docker"
  print_message "$GREEN" "✓ Using Docker as container runtime"
else
  print_message "$RED" "Error: Neither Podman nor Docker found. Cannot pre-cache images."
  print_message "$YELLOW" "Please install Podman or Docker first."
  exit 1
fi

# Pre-cache Hugo image
print_message "$BLUE" "Pre-caching Hugo image..."
HUGO_CACHED=false

# If using podman, handle the registry-specific case
if [[ "$CONTAINER_CMD" == "podman" ]]; then
  # Explicitly pull from Docker Hub with full path
  print_message "$BLUE" "Using podman with explicit Docker Hub registry..."
  
  # Try with explicit registry path
  print_message "$BLUE" "Trying docker.io/klakegg/hugo:0.110-ext-alpine..."
  if $CONTAINER_CMD pull docker.io/klakegg/hugo:0.110-ext-alpine; then
    print_message "$GREEN" "✓ Successfully pulled from Docker Hub"
    $CONTAINER_CMD tag docker.io/klakegg/hugo:0.110-ext-alpine hugo-local
    HUGO_CACHED=true
  else
    # If that fails, try the latest
    print_message "$YELLOW" "First attempt failed, trying alternative version..."
    print_message "$BLUE" "Trying docker.io/klakegg/hugo:latest-ext-alpine..."
    if $CONTAINER_CMD pull docker.io/klakegg/hugo:latest-ext-alpine; then
      print_message "$GREEN" "✓ Successfully pulled alternative version"
      $CONTAINER_CMD tag docker.io/klakegg/hugo:latest-ext-alpine hugo-local
      HUGO_CACHED=true
    fi
  fi
else
  # Docker typically doesn't need the registry prefix
  print_message "$BLUE" "Trying klakegg/hugo:0.110-ext-alpine..."
  if $CONTAINER_CMD pull klakegg/hugo:0.110-ext-alpine; then
    print_message "$GREEN" "✓ Successfully pulled klakegg/hugo:0.110-ext-alpine"
    $CONTAINER_CMD tag klakegg/hugo:0.110-ext-alpine hugo-local
    HUGO_CACHED=true
  else
    print_message "$YELLOW" "First attempt failed, trying alternative version..."
    print_message "$BLUE" "Trying klakegg/hugo:latest-ext-alpine..."
    if $CONTAINER_CMD pull klakegg/hugo:latest-ext-alpine; then
      print_message "$GREEN" "✓ Successfully pulled alternative version"
      $CONTAINER_CMD tag klakegg/hugo:latest-ext-alpine hugo-local
      HUGO_CACHED=true
    fi
  fi
fi

# If all pulls failed, try to build locally
if [ "$HUGO_CACHED" = false ]; then
  print_message "$YELLOW" "Could not pull any Hugo images. Attempting to build locally..."
  if [ -f "Dockerfile.hugo" ]; then
    print_message "$BLUE" "Building from Dockerfile.hugo..."
    if $CONTAINER_CMD build -t hugo-local -f Dockerfile.hugo .; then
      print_message "$GREEN" "✓ Successfully built Hugo image locally"
      HUGO_CACHED=true
    else
      print_message "$RED" "✗ Failed to build Hugo image locally"
    fi
  else
    print_message "$RED" "✗ Dockerfile.hugo not found. Cannot build image."
  fi
fi

# Pre-cache Jinja2/Python image
print_message "$BLUE" "Pre-caching template processor image..."
if [ -f "Dockerfile.template" ]; then
  print_message "$BLUE" "Building from Dockerfile.template..."
  if $CONTAINER_CMD build -t template-processor -f Dockerfile.template .; then
    print_message "$GREEN" "✓ Successfully built template processor image"
  else
    print_message "$RED" "✗ Failed to build template processor image"
  fi
else
  print_message "$YELLOW" "Dockerfile.template not found. Skipping template processor image."
fi

# Summary
print_message "$BLUE" "===== Image Pre-caching Summary ====="
if [ "$HUGO_CACHED" = true ]; then
  print_message "$GREEN" "✓ Hugo image ready for use"
  $CONTAINER_CMD image ls | grep hugo-local
else
  print_message "$RED" "✗ Hugo image not cached - deployment may fail"
  print_message "$YELLOW" "Alternative: Install Hugo locally using https://gohugo.io/installation/"
  print_message "$YELLOW" "Then use ./direct-deploy.sh for deployment"
fi

if $CONTAINER_CMD image ls | grep -q template-processor; then
  print_message "$GREEN" "✓ Template processor image ready for use"
  $CONTAINER_CMD image ls | grep template-processor
else
  print_message "$YELLOW" "✗ Template processor image not cached"
fi

print_message "$BLUE" "====================================="

if [ "$HUGO_CACHED" = true ]; then
  print_message "$GREEN" "Pre-caching complete. You're ready to use the MCP Documentation system."
  exit 0
else
  print_message "$YELLOW" "Pre-caching incomplete. Some features may not work properly."
  print_message "$YELLOW" "Consider using ./direct-deploy.sh for deployment as an alternative."
  exit 1
fi