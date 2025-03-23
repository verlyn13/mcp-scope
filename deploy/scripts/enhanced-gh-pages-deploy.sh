#!/bin/bash

# Enhanced GitHub Pages Deployment for MCP Documentation
# This script properly handles badges, emojis, and HTML in markdown

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

# Default settings
SOURCE_BRANCH="main"
TARGET_BRANCH="gh-pages"
SOURCE_DIR="public"
DRY_RUN="false"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="true"
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --dry-run        Run without making actual changes"
      echo "  --help           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown parameter: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
  shift
done

# Banner
echo "=================================================="
echo "     Enhanced GitHub Pages Deployment Script       "
echo "=================================================="
echo "Dry Run: $DRY_RUN"
echo "=================================================="
echo ""

# Function to deploy to GitHub Pages with proper rendering
deploy_with_enhanced_rendering() {
  # Record starting time
  local start_time=$(date +%s)
  
  # Store the current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$current_branch" ]; then
    print_message "$RED" "✗ Not in a git repository"
    return 1
  fi
  
  # Verify we're on the main branch
  if [ "$current_branch" != "$SOURCE_BRANCH" ]; then
    print_message "$RED" "✗ Deployment must start from $SOURCE_BRANCH branch"
    print_message "$YELLOW" "You are currently on branch: $current_branch"
    print_message "$YELLOW" "Switch to $SOURCE_BRANCH branch first with: git checkout $SOURCE_BRANCH"
    return 1
  fi
  
  # Check if working directory is clean
  if ! git diff-index --quiet HEAD --; then
    print_message "$RED" "✗ Working directory is not clean"
    print_message "$YELLOW" "Commit or stash your changes before deploying"
    git status -s
    return 1
  fi
  
  # Create required directories
  print_message "$BLUE" "Setting up content directories..."
  mkdir -p content
  
  # Copy the main readme with badges to index
  print_message "$BLUE" "Copying main README with badges to index..."
  if [ -f "mcp-project/README.md" ]; then
    # Create a proper front matter for the home page
    cat > content/_index.md << EOL
---
title: "ScopeCam MCP"
description: "Multi-Agent Control Platform for ScopeCam Integration"
---

$(cat mcp-project/README.md)
EOL
    print_message "$GREEN" "✓ Main README with badges copied to content/_index.md"
  else
    print_message "$YELLOW" "⚠ mcp-project/README.md not found, using default README"
    cp README.md content/_index.md
  fi
  
  # Ensure config.toml exists
  if [ ! -f "config.toml" ]; then
    print_message "$YELLOW" "⚠ config.toml not found, creating minimal config"
    cat > config.toml << EOL
baseURL = "/"
languageCode = "en-us"
title = "ScopeCam MCP Documentation"

# Enable emoji and GitHub-style rendering
enableEmoji = true
enableGitInfo = true

[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      # Important for rendering HTML in markdown (required for badges)
      unsafe = true
EOL
  fi
  
  # Create a basic layout for proper rendering
  mkdir -p layouts/_default
  cat > layouts/_default/baseof.html << EOL
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ if .Title }}{{ .Title }} | {{ end }}{{ .Site.Title }}</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            line-height: 1.6;
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        a { color: #0366d6; }
        h1, h2, h3 { margin-top: 24px; margin-bottom: 16px; font-weight: 600; line-height: 1.25; }
        h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid #eaecef; }
        h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid #eaecef; }
        h3 { font-size: 1.25em; }
        code { padding: 0.2em 0.4em; background-color: rgba(27,31,35,0.05); border-radius: 3px; }
        pre { padding: 16px; overflow: auto; line-height: 1.45; background-color: #f6f8fa; border-radius: 3px; }
        pre code { padding: 0; background-color: transparent; }
        blockquote { padding: 0 1em; color: #6a737d; border-left: 0.25em solid #dfe2e5; }
        table { border-collapse: collapse; border-spacing: 0; }
        table th, table td { padding: 6px 13px; border: 1px solid #dfe2e5; }
        table tr { background-color: #fff; border-top: 1px solid #c6cbd1; }
        table tr:nth-child(2n) { background-color: #f6f8fa; }
        img { max-width: 100%; box-sizing: border-box; }
    </style>
</head>
<body>
    <main>
        {{ block "main" . }}{{ end }}
    </main>
</body>
</html>
EOL

  cat > layouts/_default/single.html << EOL
{{ define "main" }}
    <h1>{{ .Title }}</h1>
    {{ .Content }}
{{ end }}
EOL

  cat > layouts/_default/list.html << EOL
{{ define "main" }}
    <h1>{{ .Title }}</h1>
    {{ .Content }}
    <ul>
    {{ range .Pages }}
        <li>
            <a href="{{ .RelPermalink }}">{{ .Title }}</a>
        </li>
    {{ end }}
    </ul>
{{ end }}
EOL

  cat > layouts/index.html << EOL
{{ define "main" }}
    {{ .Content }}
{{ end }}
EOL
  
  # If dry run, just show what would happen
  if [ "$DRY_RUN" == "true" ]; then
    print_message "$BLUE" "[DRY RUN] Would build Hugo site with enhanced rendering"
    print_message "$BLUE" "[DRY RUN] Would deploy to $TARGET_BRANCH branch"
    print_message "$GREEN" "✓ Dry run completed, no changes made"
    return 0
  fi
  
  # Build the site
  print_message "$BLUE" "Building Hugo site with enhanced rendering..."
  if command -v hugo > /dev/null; then
    # Use local Hugo
    if ! hugo --minify; then
      print_message "$RED" "✗ Hugo build failed"
      return 1
    fi
  elif command -v docker > /dev/null; then
    # Use Docker
    if ! docker run --rm -v "$(pwd)":/src -w /src klakegg/hugo:latest --minify; then
      print_message "$RED" "✗ Hugo build with Docker failed"
      return 1
    fi
  elif command -v podman > /dev/null; then
    # Use Podman
    if ! podman run --rm -v "$(pwd)":/src:z -w /src docker.io/klakegg/hugo:latest --minify; then
      print_message "$RED" "✗ Hugo build with Podman failed"
      return 1
    fi
  else
    print_message "$RED" "✗ Hugo not found and no container runtime available"
    return 1
  fi
  
  # Verify build succeeded
  if [ ! -d "$SOURCE_DIR" ]; then
    print_message "$RED" "✗ Build failed, $SOURCE_DIR directory not found"
    return 1
  fi
  
  print_message "$GREEN" "✓ Site built successfully"
  
  # Switch to target branch
  print_message "$BLUE" "Switching to $TARGET_BRANCH branch..."
  if git show-ref --verify --quiet refs/heads/$TARGET_BRANCH; then
    # Branch exists, switch to it
    if ! git checkout $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to switch to $TARGET_BRANCH branch"
      return 1
    fi
  else
    # Create branch if it doesn't exist
    if ! git checkout --orphan $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to create $TARGET_BRANCH branch"
      return 1
    fi
    # Remove everything
    git rm -rf . > /dev/null 2>&1 || true
    # Create an initial README
    echo "# ScopeCam MCP Documentation" > README.md
    git add README.md
    git commit -m "Initialize $TARGET_BRANCH branch"
  fi
  
  # Remove existing files (except .git directory and README.md)
  print_message "$BLUE" "Removing existing files in $TARGET_BRANCH branch..."
  find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./README.md" -exec rm -rf {} \;
  
  # Copy new files
  print_message "$BLUE" "Copying new files from $SOURCE_DIR..."
  cp -r "$SOURCE_DIR"/* .
  
  # Create a .nojekyll file to disable GitHub Pages Jekyll processing
  touch .nojekyll
  
  # Add all changes
  print_message "$BLUE" "Adding changes to git..."
  git add .
  
  # Check if there are changes to commit
  if git diff --staged --quiet; then
    print_message "$YELLOW" "No changes to commit. Site is already up to date."
  else
    # Commit changes
    print_message "$BLUE" "Committing changes..."
    git commit -m "Update documentation - $(date +'%Y-%m-%d %H:%M:%S')"
    
    # Push changes
    print_message "$BLUE" "Pushing changes to remote..."
    if ! git push origin $TARGET_BRANCH; then
      print_message "$RED" "✗ Failed to push changes to $TARGET_BRANCH"
      
      # Always return to source branch, even after error
      print_message "$BLUE" "Returning to $SOURCE_BRANCH branch..."
      git checkout $SOURCE_BRANCH
      
      return 1
    fi
    
    print_message "$GREEN" "✓ Successfully pushed changes to $TARGET_BRANCH"
  fi
  
  # Return to source branch
  print_message "$BLUE" "Returning to $SOURCE_BRANCH branch..."
  if ! git checkout $SOURCE_BRANCH; then
    print_message "$RED" "✗ Failed to return to $SOURCE_BRANCH branch"
    print_message "$RED" "IMPORTANT: You are still on $TARGET_BRANCH branch!"
    print_message "$YELLOW" "Manually switch back with: git checkout $SOURCE_BRANCH"
    return 1
  fi
  
  # Calculate elapsed time
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - start_time))
  
  # Clean up temporary files
  rm -rf content layouts
  
  print_message "$GREEN" "✓ Deployment with enhanced rendering completed successfully in ${elapsed_time} seconds"
  print_message "$GREEN" "✓ You are now back on the $SOURCE_BRANCH branch"
  return 0
}

# Execute the deployment function
deploy_with_enhanced_rendering

# Exit with the result of the deployment
exit $?