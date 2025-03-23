#!/bin/bash

# Script to properly copy all content for Hugo site building
# This ensures we include ALL documentation files in the build

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Clear previous content directory if it exists
if [ -d "content" ]; then
  print_message "$BLUE" "Cleaning previous content directory..."
  rm -rf content
fi

# Create content directory
print_message "$BLUE" "Creating content directory structure..."
mkdir -p content

# Copy the main README with badges to index
print_message "$BLUE" "Setting up main index page..."
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

# Step 1: Copy all documentation from the docs directory
print_message "$BLUE" "Copying documentation from docs/ directory..."
if [ -d "docs" ]; then
  # Create necessary subdirectories first
  find docs -type d | while read dir; do
    # Create corresponding directory in content
    target_dir="content/${dir#docs/}"
    if [ "$dir" != "docs" ]; then
      mkdir -p "$target_dir"
    fi
  done
  
  # Copy all markdown files
  find docs -name "*.md" | while read file; do
    # Get the relative path
    rel_path="${file#docs/}"
    target_file="content/$rel_path"
    cp "$file" "$target_file"
  done
  print_message "$GREEN" "✓ Documentation from docs/ copied"
else
  print_message "$YELLOW" "⚠ docs/ directory not found"
fi

# Step 2: Copy content from architecture directory
print_message "$BLUE" "Copying content from architecture/ directory..."
if [ -d "architecture" ]; then
  mkdir -p content/architecture
  cp architecture/*.md content/architecture/ 2>/dev/null || true
  print_message "$GREEN" "✓ Architecture documentation copied"
else
  print_message "$YELLOW" "⚠ architecture/ directory not found"
fi

# Step 3: Copy any markdown files from root
print_message "$BLUE" "Copying markdown files from root directory..."
for file in *.md; do
  if [ "$file" != "README.md" ] && [ -f "$file" ]; then
    cp "$file" "content/"
    print_message "$GREEN" "✓ Copied $file to content/"
  fi
done

# Step 4: Copy MCP project docs if they exist
print_message "$BLUE" "Copying MCP project documentation..."
if [ -d "mcp-project/docs" ]; then
  mkdir -p content/mcp
  # Copy all subdirectories recursively
  find mcp-project/docs -type d | while read dir; do
    if [ "$dir" != "mcp-project/docs" ]; then
      # Create corresponding directory in content/mcp
      target_dir="content/mcp/${dir#mcp-project/docs/}"
      mkdir -p "$target_dir"
    fi
  done
  
  # Copy all markdown files
  find mcp-project/docs -name "*.md" | while read file; do
    # Get the relative path
    rel_path="${file#mcp-project/docs/}"
    target_file="content/mcp/$rel_path"
    cp "$file" "$target_file"
  done
  print_message "$GREEN" "✓ MCP project documentation copied"
else
  print_message "$YELLOW" "⚠ mcp-project/docs directory not found"
fi

# Count how many content files we've copied
content_files=$(find content -name "*.md" | wc -l)
print_message "$BLUE" "Content preparation complete: $content_files markdown files ready for Hugo build"