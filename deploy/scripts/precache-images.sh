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
  print_message "$RED" "✗ No container runtime found (Podman or Docker)"
  print_message "$YELLOW" "Please install Podman or Docker and try again"
  exit 1
fi

print_message "$BLUE" "Pre-caching Hugo container image..."

# Pull the Hugo image
if [[ "$CONTAINER_CMD" == "podman" ]]; then
  if podman image exists hugo-local 2>/dev/null; then
    print_message "$GREEN" "✓ Hugo image already cached"
  else
    print_message "$BLUE" "Pulling Hugo image using Podman..."
    podman pull docker.io/klakegg/hugo:0.110-ext-alpine
    
    if [ $? -eq 0 ]; then
      # Tag the image for easier reference
      podman tag docker.io/klakegg/hugo:0.110-ext-alpine hugo-local
      print_message "$GREEN" "✓ Hugo image pulled and tagged successfully"
    else
      print_message "$RED" "✗ Failed to pull Hugo image"
      exit 1
    fi
  fi
else
  if docker image inspect hugo-local >/dev/null 2>&1; then
    print_message "$GREEN" "✓ Hugo image already cached"
  else
    print_message "$BLUE" "Pulling Hugo image using Docker..."
    docker pull klakegg/hugo:0.110-ext-alpine
    
    if [ $? -eq 0 ]; then
      # Tag the image for easier reference
      docker tag klakegg/hugo:0.110-ext-alpine hugo-local
      print_message "$GREEN" "✓ Hugo image pulled and tagged successfully"
    else
      print_message "$RED" "✗ Failed to pull Hugo image"
      exit 1
    fi
  fi
fi

# Verify the image works
print_message "$BLUE" "Verifying Hugo image..."

if [[ "$CONTAINER_CMD" == "podman" ]]; then
  podman run --rm hugo-local version
else
  docker run --rm hugo-local version
fi

if [ $? -eq 0 ]; then
  print_message "$GREEN" "✓ Hugo image verified successfully"
else
  print_message "$RED" "✗ Hugo image verification failed"
  exit 1
fi

print_message "$GREEN" "✅ Container images pre-cached successfully!"