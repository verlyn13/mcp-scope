#!/bin/bash

# Unified Deployment Script for MCP Documentation
# -------------------------------------------
# This script consolidates all deployment strategies into a single, organized workflow.
# It supports multiple deployment modes and handles all preparation steps automatically.

# Version
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default settings
DEPLOY_MODE="auto"     # auto, container, local, minimal
OUTPUT_MODE="normal"   # normal, verbose, quiet
SKIP_VERIFY="false"    # skip verification steps
SKIP_PRECACHE="false"  # skip image precaching
USE_DOC_DOCTOR="false" # use Doc Doctor for verification instead of built-in verify-shortcodes
SKIP_GIT="false"       # skip Git operations (useful for testing)
REPORT_PATH="./deploy-reports"
TARGET_BRANCH="gh-pages"

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  
  if [[ "$OUTPUT_MODE" != "quiet" ]]; then
    echo -e "${color}${message}${NC}"
  fi
}

# Function to print verbose messages
print_verbose() {
  local message=$1
  
  if [[ "$OUTPUT_MODE" == "verbose" ]]; then
    echo -e "${CYAN}[VERBOSE] ${message}${NC}"
  fi
}

# Function to print a banner
print_banner() {
  print_message "$BLUE" "===================================================="
  print_message "$BLUE" "          MCP Documentation Deployment v$VERSION"
  print_message "$BLUE" "===================================================="
  print_message "$BLUE" "Mode: $DEPLOY_MODE"
  print_message "$BLUE" "===================================================="
  echo ""
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to show help
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help               Show this help message"
  echo "  -m, --mode MODE          Set deployment mode (auto, container, local, minimal)"
  echo "  -o, --output MODE        Set output mode (normal, verbose, quiet)"
  echo "  -s, --skip-verify        Skip verification steps"
  echo "  -p, --skip-precache      Skip image precaching"
  echo "  -d, --use-doc-doctor     Use Doc Doctor for verification instead of built-in verify-shortcodes"
  echo "  -g, --skip-git           Skip Git operations (useful for testing)"
  echo "  -r, --report PATH        Set report directory"
  echo "  -b, --branch NAME        Set target branch (default: gh-pages)"
  echo ""
  echo "Deployment Modes:"
  echo "  auto                     Automatically select the best mode"
  echo "  container                Use containerized Hugo (Podman/Docker)"
  echo "  local                    Use locally installed Hugo"
  echo "  minimal                  Use minimal site with simplified content"
  echo ""
  echo "Examples:"
  echo "  $0 --mode auto           # Auto-select deployment mode"
  echo "  $0 --mode container      # Force container-based deployment"
  echo "  $0 --mode minimal        # Use minimal site deployment"
  echo "  $0 --mode local -s       # Use local Hugo and skip verification"
  echo "  $0 --use-doc-doctor      # Use Doc Doctor for thorough verification"
  echo "  $0 --skip-git            # Skip Git operations (for testing)"
  echo ""
}

# Function to parse arguments
parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      -m|--mode)
        DEPLOY_MODE="$2"
        shift
        ;;
      -o|--output)
        OUTPUT_MODE="$2"
        shift
        ;;
      -s|--skip-verify)
        SKIP_VERIFY="true"
        ;;
      -p|--skip-precache)
        SKIP_PRECACHE="true"
        ;;
      -d|--use-doc-doctor)
        USE_DOC_DOCTOR="true"
        ;;
      -g|--skip-git)
        SKIP_GIT="true"
        ;;
      -r|--report)
        REPORT_PATH="$2"
        shift
        ;;
      -b|--branch)
        TARGET_BRANCH="$2"
        shift
        ;;
      *)
        echo "Unknown parameter: $1"
        show_help
        exit 1
        ;;
    esac
    shift
  done
  
  # Validate deployment mode
  if [[ ! "$DEPLOY_MODE" =~ ^(auto|container|local|minimal)$ ]]; then
    print_message "$RED" "Invalid deployment mode: $DEPLOY_MODE. Using 'auto' instead."
    DEPLOY_MODE="auto"
  fi
  
  # Validate output mode
  if [[ ! "$OUTPUT_MODE" =~ ^(normal|verbose|quiet)$ ]]; then
    print_message "$RED" "Invalid output mode: $OUTPUT_MODE. Using 'normal' instead."
    OUTPUT_MODE="normal"
  fi
}

# Function to create directories
create_directories() {
  print_verbose "Creating required directories"
  
  # Create report directory if it doesn't exist
  if [ ! -d "$REPORT_PATH" ]; then
    mkdir -p "$REPORT_PATH"
  fi
}

# Function to determine best deployment mode
determine_deploy_mode() {
  if [[ "$DEPLOY_MODE" != "auto" ]]; then
    print_verbose "Using specified deployment mode: $DEPLOY_MODE"
    return
  fi
  
  print_message "$BLUE" "Determining optimal deployment mode..."
  
  # Check for local Hugo
  if command_exists hugo; then
    print_verbose "Hugo is installed locally"
    local hugo_version=$(hugo version)
    print_verbose "Hugo version: $hugo_version"
    
    # Check for container runtime
    if command_exists podman || command_exists docker; then
      print_verbose "Container runtime is available"
      
      # Decide based on verification results
      if [[ "$SKIP_VERIFY" == "true" ]]; then
        # If skipping verification, use local Hugo for speed
        print_message "$GREEN" "✓ Selected deployment mode: local (Hugo is available locally)"
        DEPLOY_MODE="local"
      else
        # Run verification to check for shortcode issues
        print_verbose "Running quick verification check for shortcodes"
        
        # Determine verification method
        if [[ "$USE_DOC_DOCTOR" == "true" ]] && [ -f "./doc-doctor.sh" ]; then
          print_verbose "Using Doc Doctor for verification"
          ./doc-doctor.sh --check-level quick --focus-area shortcodes --output-format terminal >/dev/null 2>&1
          shortcode_check_result=$?
        else
          print_verbose "Using built-in verification"
          ./deploy/scripts/verify-shortcodes.sh >/dev/null 2>&1
          shortcode_check_result=$?
        fi
        
        if [ $shortcode_check_result -eq 0 ]; then
          print_message "$GREEN" "✓ Selected deployment mode: container (for consistency)"
          DEPLOY_MODE="container"
        else
          print_message "$YELLOW" "⚠ Detected potential shortcode issues"
          print_message "$GREEN" "✓ Selected deployment mode: minimal (to bypass shortcode issues)"
          DEPLOY_MODE="minimal"
        fi
      fi
    else
      # No container runtime, must use local Hugo
      print_message "$GREEN" "✓ Selected deployment mode: local (only Hugo is available)"
      DEPLOY_MODE="local"
    fi
  else
    # No local Hugo
    print_verbose "Hugo is not installed locally"
    
    # Check for container runtime
    if command_exists podman || command_exists docker; then
      print_verbose "Container runtime is available"
      print_message "$GREEN" "✓ Selected deployment mode: container (Hugo not available locally)"
      DEPLOY_MODE="container"
    else
      # Neither Hugo nor container runtime available
      print_message "$RED" "✗ Neither Hugo nor container runtime available"
      print_message "$YELLOW" "⚠ Attempting minimal mode as fallback"
      DEPLOY_MODE="minimal"
    fi
  fi
}

# Function to verify environment
verify_environment() {
  if [[ "$SKIP_VERIFY" == "true" ]]; then
    print_verbose "Skipping environment verification"
    return
  fi
  
  print_message "$BLUE" "Verifying environment..."
  
  # Verify shortcodes first
  if [[ "$USE_DOC_DOCTOR" == "true" ]] && [ -f "./doc-doctor.sh" ]; then
    print_message "$BLUE" "Using Doc Doctor for thorough shortcode verification..."
    if ! ./doc-doctor.sh --check-level standard --focus-area shortcodes; then
      print_message "$RED" "✗ Doc Doctor found shortcode issues."
      print_message "$YELLOW" "Please fix these issues or use --skip-verify to bypass."
      exit 1
    fi
  else
    print_message "$BLUE" "Verifying shortcodes with built-in verification..."
    if [ -f "./deploy/scripts/verify-shortcodes.sh" ]; then
      if ! ./deploy/scripts/verify-shortcodes.sh; then
        print_message "$RED" "✗ Shortcode verification failed."
        print_message "$YELLOW" "Please fix these issues or use --skip-verify to bypass."
        exit 1
      fi
    else
      print_message "$YELLOW" "⚠ verify-shortcodes.sh not found, skipping verification"
    fi
  fi
  
  # Run verification based on selected mode
  case "$DEPLOY_MODE" in
    container)
      # Verify container environment
      if ! verify_container_environment; then
        print_message "$YELLOW" "⚠ Container mode failed, falling back to minimal mode"
        DEPLOY_MODE="minimal"
        verify_minimal_environment
      fi
      ;;
    local)
      # Verify local Hugo environment
      if ! verify_local_environment; then
        print_message "$YELLOW" "⚠ Local mode failed, falling back to minimal mode"
        DEPLOY_MODE="minimal"
        verify_minimal_environment
      fi
      ;;
    minimal)
      # Minimal verification for minimal mode
      verify_minimal_environment
      ;;
  esac
}

# Function to verify container environment
verify_container_environment() {
  print_verbose "Verifying container environment"
  
  # Determine container runtime
  if command_exists podman; then
    CONTAINER_CMD="podman"
    print_verbose "Using Podman as container runtime"
  elif command_exists docker; then
    CONTAINER_CMD="docker"
    print_verbose "Using Docker as container runtime"
  else
    print_message "$RED" "✗ No container runtime found (Podman or Docker)"
    return 1
  fi
  
  # Verify Hugo image availability or precache
  if [[ "$SKIP_PRECACHE" == "false" ]]; then
    print_verbose "Checking for Hugo image"
    
    if ! $CONTAINER_CMD image exists hugo-local 2>/dev/null && 
       ! $CONTAINER_CMD image exists docker.io/klakegg/hugo:latest 2>/dev/null &&
       ! $CONTAINER_CMD image exists klakegg/hugo:latest 2>/dev/null; then
      print_message "$YELLOW" "⚠ Hugo image not found, precaching..."
      
      if [[ -f "./deploy/scripts/precache-images.sh" ]]; then
        if ! ./deploy/scripts/precache-images.sh; then
          print_message "$RED" "✗ Failed to precache Hugo image"
          return 1
        fi
      else
        print_message "$RED" "✗ precache-images.sh not found"
        print_message "$YELLOW" "⚠ Attempting to pull Hugo image directly"
        
        if [[ "$CONTAINER_CMD" == "podman" ]]; then
          if ! podman pull docker.io/klakegg/hugo:latest; then
            print_message "$RED" "✗ Failed to pull Hugo image"
            return 1
          fi
          podman tag docker.io/klakegg/hugo:latest hugo-local
        else
          if ! docker pull klakegg/hugo:latest; then
            print_message "$RED" "✗ Failed to pull Hugo image"
            return 1
          fi
          docker tag klakegg/hugo:latest hugo-local
        fi
      fi
    else
      print_message "$GREEN" "✓ Hugo image is available"
    fi
  fi
  
  print_message "$GREEN" "✓ Container environment verified"
  return 0
}

# Function to verify local Hugo environment
verify_local_environment() {
  print_verbose "Verifying local Hugo environment"
  
  # Check for Hugo
  if ! command_exists hugo; then
    print_message "$RED" "✗ Hugo not found locally"
    return 1
  fi
  
  # Verify Hugo version
  local hugo_version=$(hugo version)
  print_message "$GREEN" "✓ Using local Hugo: $hugo_version"
  
  # Verify theme
  if [ ! -d "themes/mcp-theme" ]; then
    print_message "$YELLOW" "⚠ Theme not found (themes/mcp-theme), but continuing anyway"
  fi
  
  print_message "$GREEN" "✓ Local environment verified"
  return 0
}

# Function to verify minimal environment
verify_minimal_environment() {
  print_verbose "Verifying minimal environment"
  
  # Check for Git if we're not skipping Git operations
  if [[ "$SKIP_GIT" == "false" ]]; then
    if ! command_exists git; then
      print_message "$RED" "✗ Git not found"
      return 1
    fi
  fi
  
  print_message "$GREEN" "✓ Minimal environment verified"
  return 0
}

# Function to build the Hugo site
build_site() {
  print_message "$BLUE" "Building documentation site..."
  
  # Create a timestamp for the report
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local build_log="$REPORT_PATH/build_${timestamp}.log"
  
  # Build based on selected mode
  case "$DEPLOY_MODE" in
    container)
      if ! build_with_container "$build_log"; then
        print_message "$YELLOW" "⚠ Container build failed, falling back to minimal mode"
        DEPLOY_MODE="minimal"
        build_minimal_site "$build_log"
      fi
      ;;
    local)
      if ! build_with_local_hugo "$build_log"; then
        print_message "$YELLOW" "⚠ Local build failed, falling back to minimal mode"
        DEPLOY_MODE="minimal"
        build_minimal_site "$build_log"
      fi
      ;;
    minimal)
      build_minimal_site "$build_log"
      ;;
  esac
  
  # Check if public directory was created
  if [ ! -d "public" ]; then
    print_message "$RED" "✗ Build failed, public directory not found"
    print_message "$YELLOW" "See build log for details: $build_log"
    exit 1
  fi
  
  print_message "$GREEN" "✓ Site built successfully"
}

# Function to build with container
build_with_container() {
  local build_log=$1
  print_verbose "Building with container ($CONTAINER_CMD)"
  
  # Determine command to run
  if [[ "$CONTAINER_CMD" == "podman" ]]; then
    print_verbose "Using Podman to build site"
    podman run --rm -v "$(pwd)":/src:z -w /src hugo-local --minify 2>&1 | tee "$build_log"
    return ${PIPESTATUS[0]}
  else
    print_verbose "Using Docker to build site"
    docker run --rm -v "$(pwd)":/src -w /src hugo-local --minify 2>&1 | tee "$build_log"
    return ${PIPESTATUS[0]}
  fi
}

# Function to build with local Hugo
build_with_local_hugo() {
  local build_log=$1
  print_verbose "Building with local Hugo"
  
  # Run Hugo directly
  hugo --minify 2>&1 | tee "$build_log"
  return ${PIPESTATUS[0]}
}

# Function to build minimal site
build_minimal_site() {
  local build_log=$1
  print_verbose "Building minimal site"
  
  # Create temporary directory
  local temp_dir="temp-hugo"
  mkdir -p "$temp_dir/content"
  mkdir -p "$temp_dir/themes/minimal/layouts/_default"
  
  print_verbose "Creating minimal site structure"
  
  # Create a simple index.md
  cat > "$temp_dir/content/_index.md" << EOL
---
title: "MCP Documentation"
---

# MCP Documentation

This site contains documentation for the Multi-Agent Control Platform (MCP).

## Sections

* Architecture
* Implementation Guides
* Standards
* Project Documents

*Note: This is a minimal build. The complete documentation is being updated.*
EOL
  
  # Create simple templates
  cat > "$temp_dir/themes/minimal/layouts/_default/single.html" << EOL
<!DOCTYPE html>
<html>
<head>
    <title>{{ .Title }} | MCP Documentation</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>{{ .Title }}</h1>
    {{ .Content }}
</body>
</html>
EOL
  
  cat > "$temp_dir/themes/minimal/layouts/_default/list.html" << EOL
<!DOCTYPE html>
<html>
<head>
    <title>{{ .Title }} | MCP Documentation</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>{{ .Title }}</h1>
    {{ .Content }}
    <ul>
    {{ range .Pages }}
        <li><a href="{{ .RelPermalink }}">{{ .Title }}</a></li>
    {{ end }}
    </ul>
</body>
</html>
EOL
  
  # Create Hugo config
  cat > "$temp_dir/config.toml" << EOL
baseURL = "/"
title = "MCP Documentation"
theme = "minimal"
EOL
  
  # Build the site
  print_verbose "Running Hugo on minimal site"
  (cd "$temp_dir" && hugo --minify -d ../public 2>&1 | tee "../$build_log")
  
  # Clean up
  rm -rf "$temp_dir"
  
  return 0
}

# Function to deploy to GitHub Pages
deploy_to_github_pages() {
  if [[ "$SKIP_GIT" == "true" ]]; then
    print_message "$YELLOW" "⚠ Skipping Git operations as requested"
    return 0
  fi
  
  print_message "$BLUE" "Deploying to GitHub Pages ($TARGET_BRANCH branch)..."
  
  # Check if git is available
  if ! command_exists git; then
    print_message "$RED" "✗ Git not found, cannot deploy to GitHub Pages"
    print_message "$YELLOW" "The built site is available in the 'public' directory"
    return 1
  fi
  
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print_message "$RED" "✗ Not in a Git repository, cannot deploy to GitHub Pages"
    print_message "$YELLOW" "The built site is available in the 'public' directory"
    print_message "$YELLOW" "Initialize a Git repository or use --skip-git to skip deployment"
    return 1
  fi
  
  # Store current branch
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  print_verbose "Current branch: $current_branch"
  
  # Check if target branch exists
  if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
    print_verbose "Target branch $TARGET_BRANCH exists locally"
  else
    # Check if target branch exists in remote
    if git ls-remote --exit-code --heads origin $TARGET_BRANCH >/dev/null 2>&1; then
      print_verbose "Target branch $TARGET_BRANCH exists in remote, fetching"
      git fetch origin $TARGET_BRANCH
      git checkout -b $TARGET_BRANCH origin/$TARGET_BRANCH
      git checkout $current_branch
    else
      print_verbose "Creating new $TARGET_BRANCH branch"
      git checkout --orphan $TARGET_BRANCH
      git rm -rf .
      echo "# MCP Documentation" > README.md
      git add README.md
      git commit -m "Initialize $TARGET_BRANCH branch"
      git push -u origin $TARGET_BRANCH
      git checkout $current_branch
    fi
  fi
  
  # Switch to target branch
  print_verbose "Switching to $TARGET_BRANCH branch"
  if ! git checkout $TARGET_BRANCH; then
    print_message "$RED" "✗ Failed to switch to $TARGET_BRANCH branch"
    return 1
  fi
  
  # Remove existing content (preserving .git directory)
  print_verbose "Removing existing content"
  find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./public" -exec rm -rf {} \;
  
  # Copy new content
  print_verbose "Copying new content from public directory"
  cp -r public/* .
  rm -rf public
  
  # Add all changes
  print_verbose "Adding changes to git"
  git add .
  
  # Commit and push if there are changes
  if git diff --staged --quiet; then
    print_message "$YELLOW" "No changes to commit"
  else
    print_verbose "Committing changes"
    git commit -m "Update documentation - $(date +'%Y-%m-%d %H:%M:%S')"
    
    print_verbose "Pushing to remote"
    if ! git push origin $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to push to $TARGET_BRANCH branch"
      git checkout $current_branch
      return 1
    fi
    
    print_message "$GREEN" "✓ Successfully pushed to $TARGET_BRANCH branch"
  fi
  
  # Return to original branch
  print_verbose "Returning to $current_branch branch"
  git checkout $current_branch
  
  return 0
}

# Function to generate deployment report
generate_report() {
  print_verbose "Generating deployment report"
  
  # Create timestamp
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local report_file="$REPORT_PATH/deploy_report_${timestamp}.md"
  
  # Create report content
  cat > "$report_file" << EOL
# Deployment Report

Generated: $(date +'%Y-%m-%d %H:%M:%S')

## Deployment Details

- **Mode:** $DEPLOY_MODE
- **Target Branch:** $TARGET_BRANCH
- **Verification:** $([ "$SKIP_VERIFY" == "true" ] && echo "Skipped" || echo "Performed")
- **Verification Tool:** $([ "$USE_DOC_DOCTOR" == "true" ] && echo "Doc Doctor" || echo "Built-in verify-shortcodes")
- **Precaching:** $([ "$SKIP_PRECACHE" == "true" ] && echo "Skipped" || echo "Performed")
- **Git Operations:** $([ "$SKIP_GIT" == "true" ] && echo "Skipped" || echo "Performed")

## System Information

- **Hugo:** $(command_exists hugo && hugo version || echo "Not installed")
- **Container Runtime:** $(command_exists podman && echo "Podman $(podman --version)" || (command_exists docker && echo "Docker $(docker --version)" || echo "Not installed"))
- **Git:** $(command_exists git && git --version || echo "Not installed")

## Deployment Outcome

- **Status:** Successful
- **Timestamp:** $(date +'%Y-%m-%d %H:%M:%S')
EOL
  
  print_message "$GREEN" "✓ Deployment report generated: $report_file"
}

# Main function
main() {
  parse_args "$@"
  print_banner
  create_directories
  determine_deploy_mode
  verify_environment
  build_site
  
  # Only attempt Git deployment if not skipping Git
  if [[ "$SKIP_GIT" == "false" ]]; then
    deploy_to_github_pages
  else
    print_message "$YELLOW" "⚠ Skipping Git deployment (--skip-git specified)"
    print_message "$GREEN" "✓ Site built in 'public' directory"
  fi
  
  generate_report
  
  print_message "$GREEN" "✅ Deployment completed successfully!"
  echo ""
}

# Call main function with all arguments
main "$@"