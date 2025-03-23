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

# Try different Hugo image tags in order of preference
HUGO_TAGS=("latest" "latest-ext" "extended" "0.111.3" "0.91.2-ext-alpine")

for tag in "${HUGO_TAGS[@]}"; do
  if [[ "$CONTAINER_CMD" == "podman" ]]; then
    print_message "$BLUE" "Trying to pull klakegg/hugo:$tag with Podman..."
    if podman pull docker.io/klakegg/hugo:$tag >/dev/null 2>&1; then
      # Tag succeeded, tag it as hugo-local
      podman tag docker.io/klakegg/hugo:$tag hugo-local
      print_message "$GREEN" "✓ Successfully pulled and tagged klakegg/hugo:$tag"
      
      # Verify the image works
      print_message "$BLUE" "Verifying Hugo image..."
      if podman run --rm hugo-local version >/dev/null 2>&1; then
        print_message "$GREEN" "✓ Hugo image verified successfully"
        exit 0
      else
        print_message "$YELLOW" "⚠ Image pulled but verification failed, trying next tag..."
        podman rmi hugo-local >/dev/null 2>&1
      fi
    else
      print_message "$YELLOW" "⚠ Failed to pull klakegg/hugo:$tag, trying next tag..."
    fi
  else
    # Docker
    print_message "$BLUE" "Trying to pull klakegg/hugo:$tag with Docker..."
    if docker pull klakegg/hugo:$tag >/dev/null 2>&1; then
      # Tag succeeded, tag it as hugo-local
      docker tag klakegg/hugo:$tag hugo-local
      print_message "$GREEN" "✓ Successfully pulled and tagged klakegg/hugo:$tag"
      
      # Verify the image works
      print_message "$BLUE" "Verifying Hugo image..."
      if docker run --rm hugo-local version >/dev/null 2>&1; then
        print_message "$GREEN" "✓ Hugo image verified successfully"
        exit 0
      else
        print_message "$YELLOW" "⚠ Image pulled but verification failed, trying next tag..."
        docker rmi hugo-local >/dev/null 2>&1
      fi
    else
      print_message "$YELLOW" "⚠ Failed to pull klakegg/hugo:$tag, trying next tag..."
    fi
  fi
done

# If we get here, we couldn't pull any image
print_message "$RED" "✗ Failed to pull any Hugo image"
exit 1