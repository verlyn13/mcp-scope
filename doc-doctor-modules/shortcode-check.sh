#!/bin/bash

# Doc Doctor Module: Shortcode Check
# Checks shortcode syntax and consistency across documents

# Module information
MODULE_NAME="shortcode-check"
TEMP_DIR="./.doc-doctor-temp"

# Shortcodes that require closing tags
paired_shortcodes=("callout" "tab" "tabs" "code" "highlight" "figure")

# All known shortcodes we expect to see
known_shortcodes=("callout" "tab" "tabs" "code" "highlight" "figure" "toc" "status" "progress" "related-docs")

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
unclosed_shortcodes=0
unknown_shortcodes=0
missing_templates=0
malformed_shortcodes=0
proper_shortcodes=0
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

# Function to check if a string is in an array
contains_element() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
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
      echo "Unknown parameter for shortcode-check module: $1"
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
print_message "$SEVERITY_INFO" "Running shortcode check module (Level: $check_level)"

# Find all markdown files
files=$(find content -name "*.md")
total_docs=$(echo "$files" | wc -l)

# Quick check just samples files
if [ "$check_level" == "quick" ]; then
  # Sample approximately 20% of files
  files=$(echo "$files" | sort -R | head -n $((total_docs / 5 + 1)))
  print_message "$SEVERITY_INFO" "Quick check: Sampling ${#files[@]} of $total_docs files"
fi

# Check if shortcode templates exist
if [ "$check_level" != "quick" ]; then
  print_message "$SEVERITY_INFO" "Checking shortcode templates..."
  missing_template_count=0
  
  for shortcode in "${known_shortcodes[@]}"; do
    template_path="themes/mcp-theme/layouts/shortcodes/${shortcode}.html"
    if [ ! -f "$template_path" ]; then
      log_finding "$SEVERITY_CRITICAL" "Missing Template" "Shortcode template file not found" "$template_path" ""
      missing_template_count=$((missing_template_count + 1))
    else
      log_finding "$SEVERITY_SUCCESS" "Template Found" "Shortcode template exists" "$template_path" ""
    fi
  done
  
  missing_templates=$missing_template_count
fi

# Process each file
for file in $files; do
  # Skip checking inside code blocks
  content=$(awk '
    BEGIN { in_code_block = 0; }
    /^```/ { in_code_block = !in_code_block; next; }
    !in_code_block { print; }
  ' "$file")
  
  # Check for paired shortcodes
  for shortcode in "${paired_shortcodes[@]}"; do
    opening_tags=$(echo "$content" | grep -c "{{< $shortcode")
    closing_tags=$(echo "$content" | grep -c "{{< /$shortcode")
    
    if [ $opening_tags -ne $closing_tags ]; then
      line_num=$(grep -n "{{< $shortcode" "$file" | head -1 | cut -d: -f1)
      log_finding "$SEVERITY_CRITICAL" "Unclosed Shortcode" "Found $opening_tags opening and $closing_tags closing tags for '$shortcode'" "$file" "$line_num"
      unclosed_shortcodes=$((unclosed_shortcodes + 1))
    elif [ $opening_tags -gt 0 ]; then
      log_finding "$SEVERITY_SUCCESS" "Properly Closed Shortcode" "All '$shortcode' tags are properly closed" "$file" ""
      proper_shortcodes=$((proper_shortcodes + 1))
    fi
  done
  
  # In comprehensive mode, check for unknown shortcodes and malformed syntax
  if [ "$check_level" == "comprehensive" ]; then
    # Extract all shortcodes
    all_shortcodes=$(echo "$content" | grep -o "{{<[^>]*>" | sed 's/{{< \///g' | sed 's/{{< //g' | sed 's/ >.*//g' | sort | uniq)
    
    # Check each shortcode
    for sc in $all_shortcodes; do
      # Ignore empty matches
      if [ -z "$sc" ]; then
        continue
      fi
      
      # Check if it's a known shortcode
      if ! contains_element "$sc" "${known_shortcodes[@]}"; then
        line_num=$(grep -n "{{< $sc" "$file" | head -1 | cut -d: -f1)
        log_finding "$SEVERITY_WARNING" "Unknown Shortcode" "Using unknown shortcode: '$sc'" "$file" "$line_num"
        unknown_shortcodes=$((unknown_shortcodes + 1))
      fi
      
      # Check for malformed syntax (missing quotes around parameters for paired shortcodes)
      if contains_element "$sc" "${paired_shortcodes[@]}"; then
        malformed=$(echo "$content" | grep -E "{{< $sc [^\"]*[^\">\"]* >}" | wc -l)
        if [ $malformed -gt 0 ]; then
          line_num=$(grep -n "{{< $sc [^\"]*[^\">\"]* >}" "$file" | head -1 | cut -d: -f1)
          log_finding "$SEVERITY_WARNING" "Malformed Shortcode" "Parameters should be quoted: '{{< $sc ... }}'" "$file" "$line_num"
          malformed_shortcodes=$((malformed_shortcodes + 1))
        fi
      fi
    done
  fi
done

# Create results file for the main script to source
cat > "$TEMP_DIR/${MODULE_NAME}-results.sh" << EOF
# Shortcode check results
shortcode_check_total_docs=$total_docs
shortcode_check_unclosed_shortcodes=$unclosed_shortcodes
shortcode_check_unknown_shortcodes=$unknown_shortcodes
shortcode_check_missing_templates=$missing_templates
shortcode_check_malformed_shortcodes=$malformed_shortcodes
shortcode_check_proper_shortcodes=$proper_shortcodes
shortcode_check_total_checks=$total_checks
shortcode_check_passed_checks=$passed_checks
shortcode_check_warning_checks=$warning_checks
shortcode_check_critical_checks=$critical_checks

# Update global counters
total_checks=\$((total_checks + $total_checks))
passed_checks=\$((passed_checks + $passed_checks))
warning_checks=\$((warning_checks + $warning_checks))
critical_checks=\$((critical_checks + $critical_checks))
EOF

# Print summary
print_message "$SEVERITY_INFO" "Shortcode check complete!"
print_message "$SEVERITY_INFO" "Total documents checked: $total_docs"
print_message "$SEVERITY_SUCCESS" "Properly closed shortcodes: $proper_shortcodes"
print_message "$SEVERITY_CRITICAL" "Unclosed shortcodes: $unclosed_shortcodes"

if [ "$check_level" != "quick" ]; then
  print_message "$SEVERITY_CRITICAL" "Missing shortcode templates: $missing_templates"
fi

if [ "$check_level" == "comprehensive" ]; then
  print_message "$SEVERITY_WARNING" "Unknown shortcodes: $unknown_shortcodes"
  print_message "$SEVERITY_WARNING" "Malformed shortcodes: $malformed_shortcodes"
fi

exit 0