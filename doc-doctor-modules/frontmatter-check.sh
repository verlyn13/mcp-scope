#!/bin/bash

# Doc Doctor Module: Front Matter Check
# Validates front matter completeness and consistency across documents

# Module information
MODULE_NAME="frontmatter-check"
TEMP_DIR="./.doc-doctor-temp"

# Required front matter fields
required_fields=("title" "status")

# Recommended front matter fields
recommended_fields=("version" "date_created" "last_updated" "contributors" "tags")

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
missing_required=0
missing_recommended=0
invalid_date_format=0
complete_frontmatter=0
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

# Function to validate date format (YYYY-MM-DD)
validate_date() {
  local date=$1
  if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    return 1
  fi
  
  # Extract parts
  local year=$(echo "$date" | cut -d- -f1)
  local month=$(echo "$date" | cut -d- -f2)
  local day=$(echo "$date" | cut -d- -f3)
  
  # Basic validation
  if [ "$month" -lt 1 ] || [ "$month" -gt 12 ]; then
    return 1
  fi
  
  if [ "$day" -lt 1 ] || [ "$day" -gt 31 ]; then
    return 1
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
      echo "Unknown parameter for frontmatter-check module: $1"
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
print_message "$SEVERITY_INFO" "Running front matter check module (Level: $check_level)"

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
  # Extract front matter
  front_matter=$(sed -n '/^---$/,/^---$/p' "$file")
  
  # Skip files without front matter
  if [ -z "$front_matter" ]; then
    log_finding "$SEVERITY_CRITICAL" "Missing Front Matter" "Document has no front matter" "$file" ""
    missing_required=$((missing_required + 1))
    continue
  fi
  
  # Check required fields
  missing_fields=0
  for field in "${required_fields[@]}"; do
    field_line=$(echo "$front_matter" | grep -E "^${field}: ")
    if [ -z "$field_line" ]; then
      log_finding "$SEVERITY_CRITICAL" "Missing Required Field" "Required field '$field' is missing" "$file" ""
      missing_fields=$((missing_fields + 1))
    fi
  done
  
  if [ $missing_fields -gt 0 ]; then
    missing_required=$((missing_required + 1))
    continue
  fi
  
  # Check recommended fields
  missing_rec=0
  for field in "${recommended_fields[@]}"; do
    field_line=$(echo "$front_matter" | grep -E "^${field}: ")
    if [ -z "$field_line" ]; then
      log_finding "$SEVERITY_WARNING" "Missing Recommended Field" "Recommended field '$field' is missing" "$file" ""
      missing_rec=$((missing_rec + 1))
    fi
  done
  
  if [ $missing_rec -gt 0 ]; then
    missing_recommended=$((missing_recommended + 1))
  fi
  
  # In comprehensive mode, do additional checks
  if [ "$check_level" == "comprehensive" ]; then
    # Validate date formats
    for date_field in "date_created" "last_updated"; do
      date_line=$(echo "$front_matter" | grep -E "^${date_field}: ")
      if [ -n "$date_line" ]; then
        date_value=$(echo "$date_line" | sed -E "s/^${date_field}: \"?([^\"]*?)\"?$/\1/")
        
        if ! validate_date "$date_value"; then
          log_finding "$SEVERITY_WARNING" "Invalid Date Format" "Field '$date_field' has invalid date format: $date_value (should be YYYY-MM-DD)" "$file" "$(grep -n "${date_field}: " "$file" | cut -d: -f1)"
          invalid_date_format=$((invalid_date_format + 1))
        fi
      fi
    done
  fi
  
  # Document passed all required checks
  if [ $missing_fields -eq 0 ]; then
    if [ $missing_rec -eq 0 ]; then
      log_finding "$SEVERITY_SUCCESS" "Complete Front Matter" "Document has all required and recommended front matter fields" "$file" ""
      complete_frontmatter=$((complete_frontmatter + 1))
    else
      log_finding "$SEVERITY_SUCCESS" "Valid Front Matter" "Document has all required front matter fields" "$file" ""
    fi
  fi
done

# Create results file for the main script to source
cat > "$TEMP_DIR/${MODULE_NAME}-results.sh" << EOF
# Front matter check results
frontmatter_check_total_docs=$total_docs
frontmatter_check_missing_required=$missing_required
frontmatter_check_missing_recommended=$missing_recommended
frontmatter_check_invalid_date_format=$invalid_date_format
frontmatter_check_complete_frontmatter=$complete_frontmatter
frontmatter_check_total_checks=$total_checks
frontmatter_check_passed_checks=$passed_checks
frontmatter_check_warning_checks=$warning_checks
frontmatter_check_critical_checks=$critical_checks

# Update global counters
total_checks=\$((total_checks + $total_checks))
passed_checks=\$((passed_checks + $passed_checks))
warning_checks=\$((warning_checks + $warning_checks))
critical_checks=\$((critical_checks + $critical_checks))
EOF

# Print summary
print_message "$SEVERITY_INFO" "Front matter check complete!"
print_message "$SEVERITY_INFO" "Total documents checked: $total_docs"
print_message "$SEVERITY_SUCCESS" "Complete front matter: $complete_frontmatter"
print_message "$SEVERITY_CRITICAL" "Missing required fields: $missing_required"
print_message "$SEVERITY_WARNING" "Missing recommended fields: $missing_recommended"

if [ "$check_level" == "comprehensive" ]; then
  print_message "$SEVERITY_WARNING" "Invalid date formats: $invalid_date_format"
fi

exit 0