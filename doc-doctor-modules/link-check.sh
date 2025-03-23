#!/bin/bash

# Doc Doctor Module: Link Check
# Validates internal and external links in documentation

# Module information
MODULE_NAME="link-check"
TEMP_DIR="./.doc-doctor-temp"

# Severity levels
SEVERITY_CRITICAL="CRITICAL"
SEVERITY_WARNING="WARNING"
SEVERITY_INFO="INFO"
SEVERITY_SUCCESS="SUCCESS"

# Default settings
check_level="standard"
output_format="terminal"
focus_area="all"

# Init counters
total_docs=0
broken_internal_links=0
broken_external_links=0
malformed_links=0
valid_links=0
total_checks=0
passed_checks=0
warning_checks=0
critical_checks=0

# Function to print colored messages (if output_format is terminal)
print_message() {
  if [ "$output_format" == "terminal" ] || [ "$output_format" == "all" ]; then
    local severity=$1
    local message=$2
    
    case $severity in
      $SEVERITY_CRITICAL)
        echo -e "\033[0;31m[${severity}] ${message}\033[0m"
        ;;
      $SEVERITY_WARNING)
        echo -e "\033[0;33m[${severity}] ${message}\033[0m"
        ;;
      $SEVERITY_INFO)
        echo -e "\033[0;34m[${severity}] ${message}\033[0m"
        ;;
      $SEVERITY_SUCCESS)
        echo -e "\033[0;32m[${severity}] ${message}\033[0m"
        ;;
      *)
        echo -e "\033[0m[${severity}] ${message}\033[0m"
        ;;
    esac
  fi
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
  
  # Track in temp file for the main script to read
  echo "$severity|$check_name|$message|$file|$line" >> "$TEMP_DIR/${MODULE_NAME}-findings.txt"
}

# Function to validate an internal link
validate_internal_link() {
  local link=$1
  local src_file=$2
  local line_num=$3
  
  # Remove anchor if present
  local target_path=${link%%#*}
  
  # Handle root-relative links (/docs/something)
  if [[ "$target_path" == /* ]]; then
    target_path="content${target_path}"
  # Handle relative links
  elif [[ "$target_path" != "http"* ]]; then
    # Get directory of source file
    local src_dir=$(dirname "$src_file")
    # Resolve relative path
    target_path="${src_dir}/${target_path}"
  else
    # Not an internal link
    return 1
  fi
  
  # Remove trailing slash if present
  target_path=${target_path%/}
  
  # Add .md extension if missing and not a directory
  if [[ ! -d "$target_path" && "$target_path" != *.md ]]; then
    target_path="${target_path}.md"
  # If it's a directory, check for index.md or _index.md
  elif [[ -d "$target_path" ]]; then
    if [[ -f "${target_path}/index.md" ]]; then
      target_path="${target_path}/index.md"
    elif [[ -f "${target_path}/_index.md" ]]; then
      target_path="${target_path}/_index.md"
    fi
  fi
  
  # Check if the file exists
  if [[ ! -f "$target_path" ]]; then
    log_finding "$SEVERITY_CRITICAL" "Broken Internal Link" "Link '$link' points to non-existent file" "$src_file" "$line_num"
    broken_internal_links=$((broken_internal_links + 1))
    return 1
  fi
  
  # If there's an anchor, check if it exists in the target file (comprehensive mode only)
  # This is a simplified check - a more robust version would parse the target file to extract headings
  if [[ "$check_level" == "comprehensive" && "$link" == *"#"* ]]; then
    local anchor=${link#*#}
    
    # Skip if anchor is empty
    if [[ -n "$anchor" ]]; then
      # Try to find a matching heading in the target file (simplified)
      local heading_pattern="# $anchor"
      if ! grep -qi "$heading_pattern" "$target_path"; then
        log_finding "$SEVERITY_WARNING" "Broken Anchor" "Anchor '#$anchor' not found in target file" "$src_file" "$line_num"
        broken_internal_links=$((broken_internal_links + 1))
        return 1
      fi
    fi
  fi
  
  return 0
}

# Function to validate an external link
validate_external_link() {
  local link=$1
  local src_file=$2
  local line_num=$3
  
  # Check URL format
  if ! [[ "$link" =~ ^https?:// ]]; then
    log_finding "$SEVERITY_WARNING" "Malformed URL" "URL '$link' should start with http:// or https://" "$src_file" "$line_num"
    malformed_links=$((malformed_links + 1))
    return 1
  fi
  
  # In comprehensive mode, check if the URL is accessible
  if [ "$check_level" == "comprehensive" ]; then
    # Skip this check if curl is not available
    if ! command -v curl &> /dev/null; then
      log_finding "$SEVERITY_INFO" "Skip External Check" "curl not available, skipping external link check" "$src_file" "$line_num"
      return 0
    fi
    
    # Try to access the URL with a HEAD request and follow redirects
    if ! curl --silent --head --fail --max-time 5 --location "$link" &> /dev/null; then
      log_finding "$SEVERITY_WARNING" "Inaccessible URL" "URL '$link' is not accessible" "$src_file" "$line_num"
      broken_external_links=$((broken_external_links + 1))
      return 1
    fi
  fi
  
  return 0
}

# Function to extract and validate links from content
check_links() {
  local file=$1
  local content=$2
  
  # Extract all markdown links [text](url)
  local links=$(echo "$content" | grep -o -E '\[.*?\]\(.*?\)' | sed -E 's/\[(.*?)\]\((.*?)\)/\2/g')
  
  # Extract line numbers for links
  local link_lines=$(echo "$content" | grep -n -E '\[.*?\]\(.*?\)')
  
  # No links found
  if [ -z "$links" ]; then
    return 0
  fi
  
  # Process each link
  local link_num=1
  local found_issue=false
  
  while IFS= read -r link; do
    # Skip empty links
    if [ -z "$link" ]; then
      link_num=$((link_num + 1))
      continue
    fi
    
    # Get line number for this link
    local line_info=$(echo "$link_lines" | sed -n "${link_num}p")
    local line_num=$(echo "$line_info" | cut -d: -f1)
    
    # Check if it's an internal or external link
    if [[ "$link" == "http"* ]]; then
      # External link
      if ! validate_external_link "$link" "$file" "$line_num"; then
        found_issue=true
      else
        valid_links=$((valid_links + 1))
        log_finding "$SEVERITY_SUCCESS" "Valid External Link" "URL '$link' is valid" "$file" "$line_num"
      fi
    else
      # Internal link
      if ! validate_internal_link "$link" "$file" "$line_num"; then
        found_issue=true
      else
        valid_links=$((valid_links + 1))
        log_finding "$SEVERITY_SUCCESS" "Valid Internal Link" "Link '$link' resolves correctly" "$file" "$line_num"
      fi
    fi
    
    link_num=$((link_num + 1))
  done <<< "$links"
  
  if [ "$found_issue" = false ]; then
    log_finding "$SEVERITY_SUCCESS" "All Links Valid" "All links in document are valid" "$file" ""
  fi
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
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
    *)
      echo "Unknown parameter for link-check module: $1"
      exit 1
      ;;
  esac
  shift
done

# Ensure temp directory exists
mkdir -p "$TEMP_DIR"

# Clean up previous findings
rm -f "$TEMP_DIR/${MODULE_NAME}-findings.txt"
rm -f "$TEMP_DIR/${MODULE_NAME}-results.sh"

# Initialize findings file
touch "$TEMP_DIR/${MODULE_NAME}-findings.txt"

# Print module start message
print_message "$SEVERITY_INFO" "Running link check module (Level: $check_level)"

# Find all markdown files
files=$(find content -name "*.md")
total_docs=$(echo "$files" | wc -l)

# Quick check just samples files
if [ "$check_level" == "quick" ]; then
  # Sample approximately 20% of files
  files=$(echo "$files" | sort -R | head -n $((total_docs / 5 + 1)))
  print_message "$SEVERITY_INFO" "Quick check: Sampling ${#files[@]} of $total_docs files"
fi

# Process each file
for file in $files; do
  # Read file content
  content=$(cat "$file")
  
  # Skip files with no content
  if [ -z "$content" ]; then
    continue
  fi
  
  # Check links
  check_links "$file" "$content"
done

# Create results file for the main script to source
cat > "$TEMP_DIR/${MODULE_NAME}-results.sh" << EOF
# Link check results
link_check_total_docs=$total_docs
link_check_broken_internal_links=$broken_internal_links
link_check_broken_external_links=$broken_external_links
link_check_malformed_links=$malformed_links
link_check_valid_links=$valid_links
link_check_total_checks=$total_checks
link_check_passed_checks=$passed_checks
link_check_warning_checks=$warning_checks
link_check_critical_checks=$critical_checks

# Update global counters
total_checks=\$((total_checks + $total_checks))
passed_checks=\$((passed_checks + $passed_checks))
warning_checks=\$((warning_checks + $warning_checks))
critical_checks=\$((critical_checks + $critical_checks))
EOF

# Print summary
print_message "$SEVERITY_INFO" "Link check complete!"
print_message "$SEVERITY_INFO" "Total documents checked: $total_docs"
print_message "$SEVERITY_SUCCESS" "Valid links: $valid_links"
print_message "$SEVERITY_CRITICAL" "Broken internal links: $broken_internal_links"
print_message "$SEVERITY_WARNING" "Malformed links: $malformed_links"

if [ "$check_level" == "comprehensive" ]; then
  print_message "$SEVERITY_WARNING" "Broken external links: $broken_external_links"
fi

exit 0