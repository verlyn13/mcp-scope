#!/bin/bash

# Run Hugo in the containerized environment

# Build the container if it doesn't exist
if ! podman image exists hugo-local; then
  echo "Building Hugo container..."
  podman build -t hugo-local -f Dockerfile.hugo .
fi

# Function to run Hugo commands
run_hugo() {
  podman run --rm -it \
    -v $(pwd):/src:z \
    -p 1313:1313 \
    hugo-local "$@"
}

# Parse command line arguments
case "$1" in
  server)
    echo "Starting Hugo development server..."
    run_hugo server --bind=0.0.0.0 --buildDrafts --buildFuture --disableFastRender
    ;;
  build)
    echo "Building Hugo site..."
    run_hugo --minify
    ;;
  new)
    if [ -z "$2" ]; then
      echo "Usage: $0 new [path]"
      exit 1
    fi
    echo "Creating new content: $2"
    run_hugo new content/"$2"
    ;;
  help|*)
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  server      Start the Hugo development server"
    echo "  build       Build the static site"
    echo "  new [path]  Create new content"
    echo "  help        Show this help message"
    ;;
esac