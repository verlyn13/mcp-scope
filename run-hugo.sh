#!/bin/bash

# Run Hugo in the containerized environment

# Check if we need to (re)build the container
if [[ "$1" == "rebuild" ]]; then
  echo "Forcefully rebuilding Hugo container..."
  podman image rm -f hugo-local 2>/dev/null || true
  podman build --no-cache -t hugo-local -f Dockerfile.hugo .
  shift
elif ! podman image exists hugo-local; then
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
    echo "  rebuild     Rebuild the Hugo container before running another command"
    echo "  help        Show this help message"
    ;;
esac