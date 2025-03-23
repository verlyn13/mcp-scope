#!/bin/bash

# Doc Doctor Module: Structure Check
# Analyzes document structure for proper organization and heading hierarchy

# Module information
MODULE_NAME="structure-check"
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

# Expected sections for different document types
# Format: document_pattern|required_sections
declare -a document_types=(
  "architecture/|Overview,Components,Interfaces,Dependencies"
  "guides/|Overview,Prerequisites,Usage,Examples"
  "standards/|Overview,Guidelines,Examples,References"
  "project/|Overview,Status,Timeline,Next Steps"
)

# Init counters
total_docs=0
invalid_hierarchy=0
missing_sections=0
missing_toc=0
navigation_issues=0
valid_structure=0
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

# Function to check heading hierarchy
check_heading_hierarchy() {
  local file=$1
  local content=$2
  
  # Extract headings
  local headings=$(echo "$content" | grep -E "^#+ " | sed -E 's/^(#+) (.*)/\1/')
  
  # Check for proper hierarchy
  local prev_level=0
  local line_num=1
  local is_valid=true
  local first_issue_line=""
  local first_issue_msg=""
  
  while IFS= read -r heading; do
    # Skip empty lines
    if [ -z "$heading" ]; then
      line_num=$((line_num + 1))
      continue
    fi
    
    # Get current heading level
    local level=${#heading}
    
    # Check first heading is h1
    if [ $prev_level -eq 0 ] && [ $level -ne 1 ]; then
      is_valid=false
      first_issue_line=$line_num
      first_issue_msg="Document should start with an H1 (# Title), found H$level"
      break
    fi
    
    # Check heading levels don't skip
    if [ $prev_level -gt 0 ] && [ $level -gt $((prev_level + 1)) ]; then
      is_valid=false
      first_issue_line=$line_num
      first_issue_msg="Heading level skipped from H$prev_level to H$level (should be H$((prev_level + 1)))"
      break
    fi
    
    prev_level=$level
    line_num=$((line_num + 1))
  done <<< "$headings"
  
  if [ "$is_valid" = false ]; then
    log_finding "$SEVERITY_WARNING" "Invalid Heading Hierarchy" "$first_issue_msg" "$file" "$first_issue_line"
    invalid_hierarchy=$((invalid_hierarchy + 1))
    return 1
  fi
  
  return 0
}

# Function to check expected sections
check_expected_sections() {
  local file=$1
  local content=$2
  
  # Determine document type
  local doc_type=""
  local expected_sections=""
  
  for type_info in "${document_types[@]}"; do
    local pattern=$(echo "$type_info" | cut -d'|' -f1)
    if [[ "$file" == *"$pattern"* ]]; then
      doc_type=$pattern
      expected_sections=$(echo "$type_info" | cut -d'|' -f2)
      break
    fi
  done
  
  # Skip if no matching document type
  if [ -z "$doc_type" ]; then
    return 0
  fi
  
  # Check for expected sections
  local missing=""
  
  IFS=',' read -ra SECTIONS <<< "$expected_sections"
  for section in "${SECTIONS[@]}"; do
    if ! echo "$content" | grep -q "## $section" && ! echo "$content" | grep -q "^# $section"; then
      if [ -z "$missing" ]; then
        missing="$section"
      else
        missing="$missing, $section"
      fi
    fi
  done
  
  if [ -n "$missing" ]; then
    log_finding "$SEVERITY_WARNING" "Missing Expected Sections" "Document missing expected sections: $missing" "$file" ""
    missing_sections=$((missing_sections + 1))
    return 1
  fi
  
  return 0
}

# Function to check for table of contents
check_toc() {
  local file=$1
  local content=$2
  
  # Documents over a certain length should have a TOC
  local line_count=$(echo "$content" | wc -l)
  
  if [ $line_count -gt 50 ]; then
    # Check for TOC heading or shortcode
    if ! echo "$content" | grep -q "## Table of Contents" && ! echo "$content" | grep -q "{{< toc >}}"; then
      log_finding "$SEVERITY_WARNING" "Missing TOC" "Long document ($line_count lines) should have a table of contents" "$file" ""
      missing_toc=$((missing_toc + 1))
      return 1
    fi
  fi
  
  return 0
}

# Function to check navigation links
check_navigation() {
  local file=$1
  local content=$2
  
  # Check for back links in documents not at root
  if [[ "$file" != "content/_index.md" && "$file" != "content/index.md" ]]; then
    if ! echo "$content" | grep -q "\[.*Back.*\]\|← Back"; then
      log_finding "$SEVERITY_WARNING" "Missing Navigation" "Document should have navigation/back links" "$file" ""
      navigation_issues=$((navigation_issues + 1))
      return 1
    fi
  fi
  
  return 0
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
      echo "Unknown parameter for structure-check module: $1"
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
print_message "$SEVERITY_INFO" "Running structure check module (Level: $check_level)"

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
  # Skip if _index.md file in quick mode
  if [ "$check_level" == "quick" ] && [[ "$file" == *"_index.md" ]]; then
    continue
  fi
  
  # Read file content
  content=$(cat "$file")
  
  # Skip files with no content
  if [ -z "$content" ]; then
    log_finding "$SEVERITY_WARNING" "Empty Document" "Document has no content" "$file" ""
    continue
  fi
  
  # Run checks based on check level
  valid=true
  
  # All check levels: heading hierarchy
  if ! check_heading_hierarchy "$file" "$content"; then
    valid=false
  fi
  
  # Standard and comprehensive: Expected sections and TOC
  if [ "$check_level" != "quick" ]; then
    if ! check_expected_sections "$file" "$content"; then
      valid=false
    fi
    
    if ! check_toc "$file" "$content"; then
      valid=false
    fi
  fi
  
  # Comprehensive only: Navigation links
  if [ "$check_level" == "comprehensive" ]; then
    if ! check_navigation "$file" "$content"; then
      valid=false
    fi
  fi
  
  # Document passed all checks
  if [ "$valid" = true ]; then
    log_finding "$SEVERITY_SUCCESS" "Valid Structure" "Document structure meets all requirements" "$file" ""
    valid_structure=$((valid_structure + 1))
  fi
done

# Create results file for the main script to source
cat > "$TEMP_DIR/${MODULE_NAME}-results.sh" << EOF
# Structure check results
structure_check_total_docs=$total_docs
structure_check_invalid_hierarchy=$invalid_hierarchy
structure_check_missing_sections=$missing_sections
structure_check_missing_toc=$missing_toc
structure_check_navigation_issues=$navigation_issues
structure_check_valid_structure=$valid_structure
structure_check_total_checks=$total_checks
structure_check_passed_checks=$passed_checks
structure_check_warning_checks=$warning_checks
structure_check_critical_checks=$critical_checks

# Update global counters
total_checks=\$((total_checks + $total_checks))
passed_checks=\$((passed_checks + $passed_checks))
warning_checks=\$((warning_checks + $warning_checks))
critical_checks=\$((critical_checks + $critical_checks))
EOF

# Print summary
print_message "$SEVERITY_INFO" "Structure check complete!"
print_message "$SEVERITY_INFO" "Total documents checked: $total_docs"
print_message "$SEVERITY_SUCCESS" "Valid structure: $valid_structure"
print_message "$SEVERITY_WARNING" "Invalid heading hierarchy: $invalid_hierarchy"

if [ "$check_level" != "quick" ]; then
  print_message "$SEVERITY_WARNING" "Missing sections: $missing_sections"
  print_message "$SEVERITY_WARNING" "Missing TOC: $missing_toc"
fi

if [ "$check_level" == "comprehensive" ]; then
  print_message "$SEVERITY_WARNING" "Navigation issues: $navigation_issues"
fi

exit 0