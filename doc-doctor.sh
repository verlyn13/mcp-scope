#!/bin/bash

# Doc Doctor - Documentation Health Check System
# A unified framework for documentation quality assurance

# Version
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Severity levels
SEVERITY_CRITICAL="CRITICAL"
SEVERITY_WARNING="WARNING"
SEVERITY_INFO="INFO"
SEVERITY_SUCCESS="SUCCESS"

# Check directories
MODULES_DIR="./doc-doctor-modules"
TEMP_DIR="./.doc-doctor-temp"
REPORT_DIR="./doc-reports"

# Global check counters
total_checks=0
passed_checks=0
warning_checks=0
critical_checks=0

# Global settings
check_level="standard"  # quick, standard, comprehensive
output_format="terminal"  # terminal, markdown, json
focus_area="all"  # all, status, shortcodes, frontmatter, links, structure

# Function to print a banner
print_banner() {
  echo -e "${BLUE}"
  echo "  _____             _____            _             "
  echo " |  __ \\           |  __ \\          | |            "
  echo " | |  | | ___   ___| |  | | ___  ___| |_ ___  _ __ "
  echo " | |  | |/ _ \\ / __| |  | |/ _ \\/ __| __/ _ \\| '__|"
  echo " | |__| | (_) | (__| |__| | (_) \\__ \\ || (_) | |   "
  echo " |_____/ \\___/ \\___|_____/ \\___/|___/\\__\\___/|_|   "
  echo "                                                    "
  echo " Documentation Health Check System ${VERSION}        "
  echo -e "${NC}"
}

# Function to print colored messages
print_message() {
  local severity=$1
  local message=$2
  
  case $severity in
    $SEVERITY_CRITICAL)
      echo -e "${RED}[${severity}] ${message}${NC}"
      ;;
    $SEVERITY_WARNING)
      echo -e "${YELLOW}[${severity}] ${message}${NC}"
      ;;
    $SEVERITY_INFO)
      echo -e "${BLUE}[${severity}] ${message}${NC}"
      ;;
    $SEVERITY_SUCCESS)
      echo -e "${GREEN}[${severity}] ${message}${NC}"
      ;;
    *)
      echo -e "${NC}[${severity}] ${message}${NC}"
      ;;
  esac
}

# Function to log findings
log_finding() {
  local severity=$1
  local check_name=$2
  local message=$3
  local file=$4
  local line=$5
  
  # Increment counters
  total_checks=$((total_checks + 1))
  
  case $severity in
    $SEVERITY_CRITICAL)
      critical_checks=$((critical_checks + 1))
      ;;
    $SEVERITY_WARNING)
      warning_checks=$((warning_checks + 1))
      ;;
    $SEVERITY_SUCCESS)
      passed_checks=$((passed_checks + 1))
      ;;
  esac
  
  # Print to terminal
  if [ "$output_format" == "terminal" ] || [ "$output_format" == "all" ]; then
    local location=""
    if [ -n "$file" ]; then
      location=" in $file"
      if [ -n "$line" ]; then
        location="$location:$line"
      fi
    fi
    
    print_message "$severity" "$check_name$location: $message"
  fi
  
  # Log to JSON
  if [ "$output_format" == "json" ] || [ "$output_format" == "all" ]; then
    echo "{\"severity\": \"$severity\", \"check\": \"$check_name\", \"message\": \"$message\", \"file\": \"$file\", \"line\": \"$line\"}" >> "$TEMP_DIR/findings.json"
  fi
  
  # Log to Markdown
  if [ "$output_format" == "markdown" ] || [ "$output_format" == "all" ]; then
    local emoji="ℹ️"
    case $severity in
      $SEVERITY_CRITICAL) emoji="❌" ;;
      $SEVERITY_WARNING) emoji="⚠️" ;;
      $SEVERITY_SUCCESS) emoji="✅" ;;
    esac
    
    local location=""
    if [ -n "$file" ]; then
      location=" in \`$file\`"
      if [ -n "$line" ]; then
        location="$location:$line"
      fi
    fi
    
    echo "- $emoji **$check_name**$location: $message" >> "$TEMP_DIR/findings.md"
  fi
}

# Function to run a specific module
run_module() {
  local module=$1
  local module_script="${MODULES_DIR}/${module}.sh"
  
  if [ -f "$module_script" ] && [ -x "$module_script" ]; then
    print_message "$SEVERITY_INFO" "Running module: $module"
    # Execute module with current settings
    $module_script --check-level "$check_level" --output-format "none" --focus-area "$focus_area"
    # Source the module results
    if [ -f "$TEMP_DIR/${module}-results.sh" ]; then
      source "$TEMP_DIR/${module}-results.sh"
    fi
  else
    print_message "$SEVERITY_WARNING" "Module not found or not executable: $module"
  fi
}

# Function to show help
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --help                    Show this help message"
  echo "  --check-level LEVEL       Set check level (quick, standard, comprehensive)"
  echo "  --output-format FORMAT    Set output format (terminal, markdown, json, all)"
  echo "  --focus-area AREA         Set focus area (all, status, shortcodes, frontmatter, links, structure)"
  echo "  --report-dir DIR          Set report directory"
  echo ""
  echo "Examples:"
  echo "  $0 --check-level quick                     # Run quick health check"
  echo "  $0 --focus-area shortcodes                 # Focus on shortcode checks only"
  echo "  $0 --output-format markdown                # Generate markdown report"
  echo "  $0 --check-level comprehensive --output-format all    # Thorough check with all outputs"
}

# Parse command line arguments
parse_args() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --help)
        show_help
        exit 0
        ;;
      --check-level)
        check_level="$2"
        shift
        ;;
      --output-format)
        output_format="$2"
        shift
        ;;
      --focus-area)
        focus_area="$2"
        shift
        ;;
      --report-dir)
        REPORT_DIR="$2"
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
  
  # Validate check level
  if [[ ! "$check_level" =~ ^(quick|standard|comprehensive)$ ]]; then
    print_message "$SEVERITY_WARNING" "Invalid check level: $check_level. Using 'standard' instead."
    check_level="standard"
  fi
  
  # Validate output format
  if [[ ! "$output_format" =~ ^(terminal|markdown|json|all)$ ]]; then
    print_message "$SEVERITY_WARNING" "Invalid output format: $output_format. Using 'terminal' instead."
    output_format="terminal"
  fi
  
  # Validate focus area
  if [[ ! "$focus_area" =~ ^(all|status|shortcodes|frontmatter|links|structure)$ ]]; then
    print_message "$SEVERITY_WARNING" "Invalid focus area: $focus_area. Using 'all' instead."
    focus_area="all"
  fi
}

# Initialize working directories
initialize() {
  # Create modules directory if it doesn't exist
  if [ ! -d "$MODULES_DIR" ]; then
    mkdir -p "$MODULES_DIR"
    print_message "$SEVERITY_INFO" "Created modules directory: $MODULES_DIR"
  fi
  
  # Create temp directory if it doesn't exist
  if [ ! -d "$TEMP_DIR" ]; then
    mkdir -p "$TEMP_DIR"
  else
    # Clean up temp directory
    rm -f "$TEMP_DIR"/*
  fi
  
  # Create report directory if it doesn't exist
  if [ ! -d "$REPORT_DIR" ]; then
    mkdir -p "$REPORT_DIR"
    print_message "$SEVERITY_INFO" "Created report directory: $REPORT_DIR"
  fi
  
  # Initialize findings files
  if [ "$output_format" == "json" ] || [ "$output_format" == "all" ]; then
    echo "[" > "$TEMP_DIR/findings.json"
  fi
  
  if [ "$output_format" == "markdown" ] || [ "$output_format" == "all" ]; then
    echo "# Doc Doctor Health Check Report" > "$TEMP_DIR/findings.md"
    echo "" >> "$TEMP_DIR/findings.md"
    echo "Generated on: $(date +'%Y-%m-%d %H:%M:%S')" >> "$TEMP_DIR/findings.md"
    echo "" >> "$TEMP_DIR/findings.md"
    echo "## Check Level: $check_level" >> "$TEMP_DIR/findings.md"
    echo "## Focus Area: $focus_area" >> "$TEMP_DIR/findings.md"
    echo "" >> "$TEMP_DIR/findings.md"
    echo "## Findings" >> "$TEMP_DIR/findings.md"
    echo "" >> "$TEMP_DIR/findings.md"
  fi
}

# Run health checks based on focus area and check level
run_health_checks() {
  print_message "$SEVERITY_INFO" "Running health checks (Level: $check_level, Focus: $focus_area)"
  
  # Run the appropriate modules based on focus area
  if [ "$focus_area" == "all" ] || [ "$focus_area" == "status" ]; then
    run_module "status-check"
  fi
  
  if [ "$focus_area" == "all" ] || [ "$focus_area" == "shortcodes" ]; then
    run_module "shortcode-check"
  fi
  
  if [ "$focus_area" == "all" ] || [ "$focus_area" == "frontmatter" ]; then
    run_module "frontmatter-check"
  fi
  
  if [ "$focus_area" == "all" ] || [ "$focus_area" == "links" ]; then
    if [ "$check_level" != "quick" ]; then  # Skip link checks in quick mode
      run_module "link-check"
    fi
  fi
  
  if [ "$focus_area" == "all" ] || [ "$focus_area" == "structure" ]; then
    run_module "structure-check"
  fi
  
  # Run additional modules in comprehensive mode
  if [ "$check_level" == "comprehensive" ]; then
    run_module "image-check"
    run_module "style-check"
    run_module "template-check"
  fi
}

# Generate final reports
generate_reports() {
  local timestamp=$(date +'%Y%m%d_%H%M%S')
  
  # Finalize JSON report
  if [ "$output_format" == "json" ] || [ "$output_format" == "all" ]; then
    # Remove trailing comma if there are findings
    if [ -s "$TEMP_DIR/findings.json" ]; then
      sed -i '$ s/,$//' "$TEMP_DIR/findings.json"
    fi
    echo "]" >> "$TEMP_DIR/findings.json"
    cp "$TEMP_DIR/findings.json" "$REPORT_DIR/doc-health-report-$timestamp.json"
    print_message "$SEVERITY_INFO" "JSON report saved: $REPORT_DIR/doc-health-report-$timestamp.json"
  fi
  
  # Finalize Markdown report
  if [ "$output_format" == "markdown" ] || [ "$output_format" == "all" ]; then
    # Add summary
    echo "" >> "$TEMP_DIR/findings.md"
    echo "## Summary" >> "$TEMP_DIR/findings.md"
    echo "" >> "$TEMP_DIR/findings.md"
    echo "- Total Checks: $total_checks" >> "$TEMP_DIR/findings.md"
    echo "- Passed: $passed_checks" >> "$TEMP_DIR/findings.md"
    echo "- Warnings: $warning_checks" >> "$TEMP_DIR/findings.md"
    echo "- Critical Issues: $critical_checks" >> "$TEMP_DIR/findings.md"
    
    cp "$TEMP_DIR/findings.md" "$REPORT_DIR/doc-health-report-$timestamp.md"
    print_message "$SEVERITY_INFO" "Markdown report saved: $REPORT_DIR/doc-health-report-$timestamp.md"
  fi
  
  # Print summary to terminal
  print_message "$SEVERITY_INFO" "Health check complete!"
  echo -e "${BLUE}======= Health Check Summary =======${NC}"
  echo -e "${BLUE}Total Checks: ${NC}$total_checks"
  echo -e "${GREEN}Passed: ${NC}$passed_checks"
  echo -e "${YELLOW}Warnings: ${NC}$warning_checks"
  echo -e "${RED}Critical Issues: ${NC}$critical_checks"
  
  # Determine overall health
  if [ $critical_checks -gt 0 ]; then
    echo -e "${RED}Overall Health: Poor${NC}"
    echo -e "${YELLOW}Recommendation: Address critical issues before deploying.${NC}"
  elif [ $warning_checks -gt 0 ]; then
    echo -e "${YELLOW}Overall Health: Fair${NC}"
    echo -e "${YELLOW}Recommendation: Consider addressing warnings to improve documentation quality.${NC}"
  else
    echo -e "${GREEN}Overall Health: Excellent${NC}"
    echo -e "${GREEN}Recommendation: Documentation is ready for deployment.${NC}"
  fi
}

# Clean up
cleanup() {
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

# Main function
main() {
  print_banner
  parse_args "$@"
  initialize
  run_health_checks
  generate_reports
  cleanup
}

# Execute main function with all arguments
main "$@"