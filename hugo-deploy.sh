#!/bin/bash

# MCP Documentation Deployment Script
# Complete deployment script with shortcode verification and error handling

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_message "$BLUE" "=========================================="
print_message "$BLUE" "     MCP Documentation Deployment"
print_message "$BLUE" "=========================================="

# Verify prerequisites
print_message "$BLUE" "Checking prerequisites..."

if ! command_exists hugo; then
  print_message "$YELLOW" "Hugo not found locally. Trying container approach..."
  if command_exists podman || command_exists docker; then
    print_message "$GREEN" "✓ Container runtime available"
  else
    print_message "$RED" "Error: Neither Hugo, Podman, nor Docker found."
    print_message "$YELLOW" "Please install Hugo or a container runtime to proceed."
    exit 1
  fi
else
  print_message "$GREEN" "✓ Hugo found: $(hugo version | head -n 1)"
fi

# Verify theme and shortcodes
print_message "$BLUE" "Verifying theme and shortcodes..."

if [ ! -d "themes/mcp-theme" ]; then
  print_message "$RED" "Error: MCP theme not found."
  print_message "$YELLOW" "Please ensure the theme directory exists at themes/mcp-theme"
  exit 1
fi

# Check for shortcode templates
required_shortcodes=("toc" "callout" "status" "progress" "related-docs")
missing_shortcodes=0

for shortcode in "${required_shortcodes[@]}"; do
  if [ ! -f "themes/mcp-theme/layouts/shortcodes/${shortcode}.html" ]; then
    print_message "$RED" "Error: Missing shortcode template: ${shortcode}.html"
    missing_shortcodes=$((missing_shortcodes + 1))
  else
    print_message "$GREEN" "✓ Found shortcode template: ${shortcode}.html"
  fi
done

if [ $missing_shortcodes -gt 0 ]; then
  print_message "$RED" "Error: $missing_shortcodes shortcode templates are missing."
  print_message "$YELLOW" "Please create the missing shortcode templates before deploying."
  exit 1
fi

# Check for unclosed shortcodes
print_message "$BLUE" "Checking for unclosed shortcodes..."

# Create a temporary script to check for unclosed shortcodes
temp_script=$(mktemp)
cat > $temp_script << 'EOF'
#!/bin/bash
for file in $(find content -name "*.md"); do
  content=$(awk '
    BEGIN { in_code_block = 0; }
    /^```/ { in_code_block = !in_code_block; next; }
    !in_code_block { print; }
  ' "$file")
  
  opening_callouts=$(echo "$content" | grep -c "{{< callout")
  closing_callouts=$(echo "$content" | grep -c "{{< /callout")
  
  if [ $opening_callouts -ne $closing_callouts ]; then
    echo "Error in $file: $opening_callouts opening callout tags, $closing_callouts closing tags"
    exit 1
  fi
done
exit 0
EOF

chmod +x $temp_script
if ! $temp_script; then
  print_message "$RED" "Error: Found unclosed shortcodes in content files."
  print_message "$YELLOW" "Please fix the unclosed shortcodes before deploying."
  print_message "$YELLOW" "Run ./find-unclosed-shortcodes-improved.sh for details."
  rm $temp_script
  exit 1
fi
rm $temp_script

print_message "$GREEN" "✓ No unclosed shortcodes found!"

# Store current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
print_message "$BLUE" "Current branch: $current_branch"

# Create a temporary directory for the build
temp_dir="temp-deploy"
mkdir -p "$temp_dir"

# Build the site
print_message "$BLUE" "Building site for production..."

if command_exists hugo; then
  # Use local Hugo installation
  hugo --minify -d "$temp_dir"
  build_result=$?
else
  # Try to use container
  if command_exists podman; then
    container_cmd="podman"
  elif command_exists docker; then
    container_cmd="docker"
  fi
  
  # Try to build the Hugo image if it doesn't exist
  if ! $container_cmd image exists hugo-local 2>/dev/null; then
    print_message "$BLUE" "Building Hugo container..."
    $container_cmd build -t hugo-local -f Dockerfile.hugo .
  fi
  
  print_message "$BLUE" "Running Hugo in container..."
  $container_cmd run --rm -v "$(pwd)":/src:z -w /src hugo-local --minify -d "$temp_dir"
  build_result=$?
fi

# Check build success
if [ $build_result -ne 0 ] || [ ! -d "$temp_dir" ] || [ -z "$(ls -A "$temp_dir")" ]; then
  print_message "$RED" "Error: Hugo build failed."
  print_message "$YELLOW" "Check the error messages above for details."
  rm -rf "$temp_dir"
  exit 1
fi

print_message "$GREEN" "✓ Hugo build successful!"

# Proceed with deployment
print_message "$BLUE" "Preparing for deployment to GitHub Pages..."

# Confirm with user before proceeding
read -p "Ready to deploy to GitHub Pages? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  print_message "$YELLOW" "Deployment cancelled. The built site remains in $temp_dir."
  exit 0
fi

# Check if gh-pages branch exists
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
  rm -rf "$temp_dir"
  git checkout "$current_branch"
  exit 1
fi

# Remove existing content (preserving .git directory)
print_message "$BLUE" "Clearing existing content..."
find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./$temp_dir" -exec rm -rf {} \;

# Copy new content
print_message "$BLUE" "Copying new content from build directory..."
cp -r "$temp_dir"/* .
rm -rf "$temp_dir"

# Create a .gitignore specifically for gh-pages
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

print_message "$GREEN" "=========================================="
print_message "$GREEN" "✅ Deployment to GitHub Pages complete!"
print_message "$GREEN" "=========================================="
print_message "$YELLOW" "Note: It may take a few minutes for changes to appear on the live site."

# Easter egg
if [[ "$RANDOM" -lt 10922 ]]; then # ~1/3 chance
  print_message "$CYAN" "
   __  __  ___  ___   
  |  \\/  |/ __|| _ \\ 
  | |\\/| | (__ |  _/ 
  |_|  |_|\\___||_|   
                      
  Documentation: Bringing order to chaos since 2025!"
fi