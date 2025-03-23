#!/bin/bash

# Script for deploying a minimal Hugo site to GitHub Pages
# Uses a simplified approach with minimal content to avoid shortcode errors

# Colors
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

print_message "$BLUE" "Starting simplified Hugo deployment..."

# Store current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
print_message "$BLUE" "Current branch: $current_branch"

# Create a temporary work directory
temp_dir="hugo-minimal"
mkdir -p "$temp_dir/content"
mkdir -p "$temp_dir/themes/minimal/layouts/_default"
mkdir -p "$temp_dir/themes/minimal/layouts/shortcodes"

# Create a simple content file
cat > "$temp_dir/content/index.md" << EOL
---
title: "MCP Documentation Hub"
---

# Multi-Agent Control Platform Documentation

This is a temporary documentation hub that will be expanded in future updates.

## Sections

* Architecture
* Guides
* Project Documentation
* Standards

## Status

This site is currently being migrated to Hugo. Please check back soon for the complete documentation.
EOL

# Create simple theme templates
cat > "$temp_dir/themes/minimal/layouts/_default/single.html" << EOL
<!DOCTYPE html>
<html>
<head>
    <title>{{ .Title }}</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        footer { margin-top: 40px; padding-top: 10px; border-top: 1px solid #eee; font-size: 0.8em; color: #777; }
    </style>
</head>
<body>
    <main>
        <h1>{{ .Title }}</h1>
        {{ .Content }}
    </main>
    <footer>
        <p>Multi-Agent Control Platform Documentation - Generated on $(date)</p>
    </footer>
</body>
</html>
EOL

cat > "$temp_dir/themes/minimal/layouts/_default/list.html" << EOL
<!DOCTYPE html>
<html>
<head>
    <title>{{ .Title }}</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; max-width: 800px; margin: 0 auto; }
        h1 { color: #333; }
        ul { padding-left: 20px; }
        footer { margin-top: 40px; padding-top: 10px; border-top: 1px solid #eee; font-size: 0.8em; color: #777; }
    </style>
</head>
<body>
    <main>
        <h1>{{ .Title }}</h1>
        {{ .Content }}
        <ul>
            {{ range .Pages }}
            <li><a href="{{ .RelPermalink }}">{{ .Title }}</a></li>
            {{ end }}
        </ul>
    </main>
    <footer>
        <p>Multi-Agent Control Platform Documentation - Generated on $(date)</p>
    </footer>
</body>
</html>
EOL

# Create Hugo config
cat > "$temp_dir/config.toml" << EOL
baseURL = "/"
languageCode = "en-us"
title = "MCP Documentation"
theme = "minimal"
EOL

# Build the site
print_message "$BLUE" "Building site..."
cd "$temp_dir"
if ! hugo -d ../public; then
  print_message "$RED" "Error: Hugo build failed."
  cd ..
  rm -rf "$temp_dir"
  exit 1
fi
cd ..

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

# Switch to gh-pages branch
print_message "$BLUE" "Switching to gh-pages branch..."
if ! git checkout gh-pages; then
  print_message "$RED" "Error: Failed to switch to gh-pages branch."
  rm -rf "$temp_dir" public
  git checkout "$current_branch"
  exit 1
fi

# Remove existing content (preserving .git)
print_message "$BLUE" "Clearing existing content..."
find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./public" -exec rm -rf {} \;

# Copy new content
print_message "$BLUE" "Copying new content from public directory..."
cp -r public/* .
rm -rf "$temp_dir" public

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

print_message "$GREEN" "✅ Simplified deployment to GitHub Pages complete!"
print_message "$YELLOW" "Note: This is a minimal site. Full documentation will be available in future updates."
print_message "$YELLOW" "Note: It may take a few minutes for changes to appear on the live site."