#!/bin/bash

# Simple script to test Hugo site without containers
# First, check if Hugo is installed
if command -v hugo >/dev/null 2>&1; then
  echo "Hugo found, starting server..."
  # Start Hugo server in the current directory
  hugo server --bind=0.0.0.0 --buildDrafts --buildFuture --disableFastRender
else
  echo "Hugo not found. You need to install Hugo to use this script."
  echo "Installation instructions: https://gohugo.io/installation/"
  
  # Provide alternative suggestion
  echo ""
  echo "Alternative approaches:"
  echo "1. Install Hugo directly: https://gohugo.io/installation/"
  echo "2. Use a container: docker build -t hugo-local -f Dockerfile.hugo ."
  echo "   Then: docker run --rm -it -v $(pwd):/src:z -p 1313:1313 hugo-local server --bind=0.0.0.0"
  echo "3. Use npx: npx hugo-server"
  
  exit 1
fi