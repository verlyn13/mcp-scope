#!/bin/bash

# Direct deployment script for MCP documentation
# Use this if the regular deployment script fails

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

# Check if hugo is installed
if ! command -v hugo >/dev/null 2>&1; then
  print_message "$RED" "Error: Hugo is not installed. This script requires a local Hugo installation."
  print_message "$YELLOW" "Please install Hugo: https://gohugo.io/installation/"
  exit 1
fi

print_message "$BLUE" "Starting direct deployment process..."

# Store current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
print_message "$BLUE" "Current branch: $current_branch"

# Build the site directly with hugo
print_message "$BLUE" "Building site with local Hugo installation..."
if ! hugo --minify -d public; then
  print_message "$RED" "Error: Hugo build failed."
  exit 1
fi

print_message "$GREEN" "✓ Hugo build successful"

# Check if gh-pages branch exists locally
if git show-ref --verify --quiet refs/heads/gh-pages; then
  print_message "$BLUE" "Updating existing gh-pages branch..."
else
  # Check if gh-pages exists in remote
  if git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
    print_message "$BLUE" "Fetching remote gh-pages branch..."
    git fetch origin gh-pages
    git checkout -b gh-pages origin/gh-pages
    git checkout "$current_branch"
  else
    print_message "$BLUE" "Creating new gh-pages branch..."
    git checkout --orphan gh-pages
    git rm -rf .
    echo "# MCP Documentation" > README.md
    git add README.md
    git commit -m "Initialize gh-pages branch"
    git push -u origin gh-pages
    git checkout "$current_branch"
  fi
fi

# Confirm with user before proceeding
print_message "$YELLOW" "This will update the gh-pages branch with new content."
read -p "Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  print_message "$YELLOW" "Deployment cancelled."
  rm -rf public
  exit 0
fi

# Switch to gh-pages branch
print_message "$BLUE" "Switching to gh-pages branch..."
if ! git checkout gh-pages; then
  print_message "$RED" "Error: Failed to switch to gh-pages branch."
  rm -rf public
  git checkout "$current_branch"
  exit 1
fi

# Remove existing content (preserving .git directory)
print_message "$BLUE" "Clearing existing content..."
find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./public" -exec rm -rf {} \;

# Copy new content
print_message "$BLUE" "Copying new content from public directory..."
cp -r public/* .
rm -rf public

# Create a simple .gitignore for gh-pages
cat > .gitignore << EOL
# gh-pages specific .gitignore
.DS_Store
Thumbs.db
EOL

# Add and commit
print_message "$BLUE" "Committing changes to gh-pages branch..."
git add .

# Only commit if there are changes
if git diff --staged --quiet; then
  print_message "$YELLOW" "No changes detected in the built site."
else
  git commit -m "Update GitHub Pages site - $(date +'%Y-%m-%d %H:%M:%S')"
  
  # Push to GitHub
  print_message "$BLUE" "Pushing to GitHub Pages..."
  if ! git push origin gh-pages; then
    print_message "$RED" "Error: Failed to push to GitHub Pages."
    print_message "$YELLOW" "Please check your network connection and repository permissions."
    git checkout "$current_branch"
    exit 1
  fi
  print_message "$GREEN" "✓ Successfully pushed to GitHub Pages"
fi

# Return to original branch
print_message "$BLUE" "Returning to $current_branch branch..."
git checkout "$current_branch"

print_message "$GREEN" "✅ Direct deployment to GitHub Pages complete!"
print_message "$YELLOW" "Note: It may take a few minutes for changes to appear on the live site."