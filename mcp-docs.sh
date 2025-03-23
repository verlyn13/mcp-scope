#!/bin/bash

# MCP Documentation System - Combined Hugo and Jinja2 Tools
# Provides tools for both Hugo site generation and Jinja2 template processing

# Set up colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display colored output
print_message() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Easter egg - show ASCII art when using the help command with a special flag
show_easter_egg() {
  if [[ "$1" == "--mcp-special" ]]; then
    print_message "$CYAN" "
    __  __  ___  ___   
   |  \/  |/ __|| _ \ 
   | |\/| | (__ |  _/ 
   |_|  |_|\___||_|   
                       
   Multi-Agent Control Platform
   Documentation System
   
   'Documentation is like oxygen: you don't notice it when it's there, but you definitely miss it when it's not!'
   "
    return 0
  fi
  return 1
}

# Function to check prerequisites
check_prerequisites() {
  local mode=$1
  local missing=0
  
  print_message "$BLUE" "Checking prerequisites for $mode mode..."
  
  if [[ "$mode" == "hugo" || "$mode" == "all" ]]; then
    if ! command_exists hugo && ! command_exists podman; then
      print_message "$YELLOW" "Warning: Neither Hugo nor Podman found. You need one of them to build the site."
      missing=1
    else
      if command_exists hugo; then
        print_message "$GREEN" "✓ Hugo found ($(hugo version | head -n 1))"
      fi
      if command_exists podman; then
        print_message "$GREEN" "✓ Podman found ($(podman --version))"
      elif command_exists docker; then
        print_message "$GREEN" "✓ Docker found as alternative to Podman"
      fi
    fi
  fi
  
  if [[ "$mode" == "template" || "$mode" == "all" ]]; then
    if ! command_exists python3; then
      print_message "$YELLOW" "Warning: Python 3 not found. Needed for template processing."
      missing=1
    else
      print_message "$GREEN" "✓ Python 3 found ($(python3 --version))"
      
      # Check for Jinja2
      if ! python3 -c "import jinja2" &>/dev/null; then
        print_message "$YELLOW" "Warning: Jinja2 module not found. Installing required modules..."
        python3 -m pip install Jinja2 PyYAML jsonschema MarkupSafe
        if [ $? -ne 0 ]; then
          print_message "$YELLOW" "Warning: Could not install Jinja2 modules automatically."
          print_message "$YELLOW" "Please run: python3 -m pip install Jinja2 PyYAML jsonschema MarkupSafe"
          missing=1
        else
          print_message "$GREEN" "✓ Jinja2 modules installed"
        fi
      else
        print_message "$GREEN" "✓ Jinja2 module found"
      fi
    fi
  fi
  
  return $missing
}

# Function to run Hugo commands (with container fallback)
run_hugo() {
  if command_exists hugo; then
    print_message "$BLUE" "Running Hugo locally: hugo $*"
    hugo "$@"
  else
    # Try to use container
    local container_cmd=""
    if command_exists podman; then
      container_cmd="podman"
    elif command_exists docker; then
      container_cmd="docker"
    else
      print_message "$RED" "Error: Neither Hugo, Podman, nor Docker found. Cannot run Hugo commands."
      return 1
    fi
    
    # Build the container if it doesn't exist
    if ! $container_cmd image exists hugo-local 2>/dev/null; then
      print_message "$BLUE" "Building Hugo container..."
      $container_cmd build -t hugo-local -f Dockerfile.hugo .
    fi
    
    print_message "$BLUE" "Running Hugo in container: hugo $*"
    $container_cmd run --rm -it \
      -v "$(pwd)":/src:z \
      -p 1313:1313 \
      hugo-local "$@"
  fi
}

# Function to run template processing
run_template() {
  local action=$1
  shift
  
  if ! command_exists python3; then
    print_message "$RED" "Error: Python 3 not found. Cannot process templates."
    return 1
  fi
  
  case "$action" in
    list)
      print_message "$BLUE" "Listing available templates..."
      python3 simple-template.py list "$@"
      ;;
    generate)
      if [ $# -lt 3 ]; then
        print_message "$RED" "Error: Not enough arguments for template generation."
        print_message "$YELLOW" "Usage: $0 template generate <template> <data> <output>"
        return 1
      fi
      print_message "$BLUE" "Generating document from template..."
      python3 simple-template.py "$@"
      ;;
    validate)
      if [ $# -lt 1 ]; then
        print_message "$RED" "Error: Missing data file for validation."
        print_message "$YELLOW" "Usage: $0 template validate <data-file> [schema]"
        return 1
      fi
      print_message "$BLUE" "Validating template data..."
      python3 docs/tools/template-manager.py validate "$@"
      ;;
    *)
      print_message "$RED" "Error: Unknown template command: $action"
      print_message "$YELLOW" "Available commands: list, generate, validate"
      return 1
      ;;
  esac
}

# Function to deploy to GitHub Pages
deploy_to_github() {
  # Ensure we have the gh-pages branch
  print_message "$BLUE" "Preparing for deployment to GitHub Pages..."
  
  # Store current branch
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  # Build the site
  print_message "$BLUE" "Building site for production..."
  run_hugo --minify
  
  if [ ! -d "public" ]; then
    print_message "$RED" "Error: Build failed, 'public' directory not found."
    return 1
  fi
  
  # Check if gh-pages branch exists
  if git show-ref --verify --quiet refs/heads/gh-pages; then
    print_message "$BLUE" "Updating existing gh-pages branch..."
  else
    print_message "$BLUE" "Creating new gh-pages branch..."
    git checkout --orphan gh-pages
    git rm -rf .
    echo "# MCP Documentation" > README.md
    git add README.md
    git commit -m "Initialize gh-pages branch"
    git push -u origin gh-pages
    git checkout $current_branch
  fi
  
  # Switch to gh-pages branch
  git checkout gh-pages
  
  # Remove existing content
  find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./public" -exec rm -rf {} \;
  
  # Copy new content
  cp -r public/* .
  rm -rf public
  
  # Add and commit
  git add .
  git commit -m "Update GitHub Pages $(date +'%Y-%m-%d %H:%M:%S')"
  
  # Push to GitHub
  print_message "$GREEN" "Pushing to GitHub Pages..."
  git push origin gh-pages
  
  # Return to original branch
  git checkout $current_branch
  
  print_message "$GREEN" "✅ Deployment to GitHub Pages complete!"
}

# Main command parsing
main() {
  # Check for special easter egg
  if show_easter_egg "$2"; then
    return 0
  fi
  
  case "$1" in
    hugo)
      shift
      case "$1" in
        server)
          check_prerequisites "hugo" || { 
            print_message "$RED" "Cannot start server due to missing prerequisites"
            return 1
          }
          print_message "$BLUE" "Starting Hugo development server..."
          run_hugo server --bind=0.0.0.0 --buildDrafts --buildFuture --disableFastRender
          ;;
        build)
          check_prerequisites "hugo" || { 
            print_message "$RED" "Cannot build site due to missing prerequisites"
            return 1
          }
          print_message "$BLUE" "Building Hugo site..."
          run_hugo --minify
          ;;
        new)
          check_prerequisites "hugo" || { 
            print_message "$RED" "Cannot create new content due to missing prerequisites"
            return 1
          }
          if [ -z "$2" ]; then
            print_message "$RED" "Error: Missing path for new content."
            print_message "$YELLOW" "Usage: $0 hugo new [path]"
            return 1
          fi
          print_message "$BLUE" "Creating new content: $2"
          run_hugo new content/"$2"
          ;;
        *)
          print_message "$YELLOW" "Usage: $0 hugo [server|build|new]"
          print_message "$YELLOW" "  server      Start the Hugo development server"
          print_message "$YELLOW" "  build       Build the static site"
          print_message "$YELLOW" "  new [path]  Create new content"
          ;;
      esac
      ;;
    template)
      shift
      check_prerequisites "template" || { 
        print_message "$RED" "Cannot process templates due to missing prerequisites"
        return 1
      }
      run_template "$@"
      ;;
    deploy)
      check_prerequisites "hugo" || { 
        print_message "$RED" "Cannot deploy site due to missing prerequisites"
        return 1
      }
      deploy_to_github
      ;;
    check)
      check_prerequisites "all"
      ;;
    help|*)
      print_message "$BLUE" "MCP Documentation System"
      print_message "$BLUE" "------------------------"
      print_message "$YELLOW" "Usage: $0 [command]"
      print_message "$NC" ""
      print_message "$YELLOW" "Commands:"
      print_message "$GREEN" "  hugo [subcommand]     Hugo site generation commands"
      print_message "$YELLOW" "    server             Start the Hugo development server"
      print_message "$YELLOW" "    build              Build the static site"
      print_message "$YELLOW" "    new [path]         Create new content"
      print_message "$NC" ""
      print_message "$GREEN" "  template [subcommand] Template processing commands"
      print_message "$YELLOW" "    list               List available templates"
      print_message "$YELLOW" "    generate [args]    Generate document from template"
      print_message "$YELLOW" "    validate [args]    Validate template data"
      print_message "$NC" ""
      print_message "$GREEN" "  deploy               Deploy to GitHub Pages"
      print_message "$GREEN" "  check                Check prerequisites"
      print_message "$GREEN" "  help                 Show this help message"
      print_message "$NC" ""
      print_message "$BLUE" "Examples:"
      print_message "$NC" "  $0 hugo server                     # Start Hugo server"
      print_message "$NC" "  $0 template generate templates/component.j2 template-data/component.yaml output.md"
      print_message "$NC" "                                       # Generate document from template"
      print_message "$NC" "  $0 check                           # Check prerequisites"
      ;;
  esac
}

# Run the main function with all arguments
main "$@"