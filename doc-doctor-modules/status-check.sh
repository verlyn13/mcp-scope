#!/bin/bash

# Doc Doctor Module: Status Check
# Checks document status fields in front matter for validity and consistency

# Module information
MODULE_NAME="status-check"
TEMP_DIR="./.doc-doctor-temp"

# Valid status values
valid_statuses=("Draft" "Review" "Active" "Deprecated" "Archived")

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
missing_status=0
invalid_status=0
outdated_status=0
valid_status=0
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
      echo "Unknown parameter for status-check module: $1"
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
print_message "$SEVERITY_INFO" "Running status check module (Level: $check_level)"

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
  
  # Check if status field exists
  status_line=$(echo "$front_matter" | grep -E "^status: ")
  
  if [ -z "$status_line" ]; then
    log_finding "$SEVERITY_WARNING" "Missing Status" "Document is missing status field" "$file" ""
    missing_status=$((missing_status + 1))
    continue
  fi
  
  # Extract status value
  status_value=$(echo "$status_line" | sed -E 's/^status: "?([^"]*)"?$/\1/')
  
  # Check if status value is valid
  if ! contains_element "$status_value" "${valid_statuses[@]}"; then
    log_finding "$SEVERITY_CRITICAL" "Invalid Status" "Status '$status_value' is not a valid status" "$file" "$(grep -n "status: " "$file" | cut -d: -f1)"
    invalid_status=$((invalid_status + 1))
    continue
  fi
  
  # In comprehensive mode, do additional checks
  if [ "$check_level" == "comprehensive" ]; then
    # Check if last_updated is present and recent
    last_updated_line=$(echo "$front_matter" | grep -E "^last_updated: ")
    
    if [ -n "$last_updated_line" ]; then
      last_updated=$(echo "$last_updated_line" | sed -E 's/^last_updated: "?([^"]*)"?$/\1/')
      
      # Check if last_updated is more than 6 months old and status is Active
      if [ "$status_value" == "Active" ]; then
        # Parse date (assuming YYYY-MM-DD format)
        if [[ "$last_updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
          last_year=$(echo "$last_updated" | cut -d- -f1)
          last_month=$(echo "$last_updated" | cut -d- -f2)
          current_year=$(date +%Y)
          current_month=$(date +%m)
          
          # Calculate months difference (approximate)
          months_diff=$(( (current_year - last_year) * 12 + (current_month - last_month) ))
          
          if [ $months_diff -gt 6 ]; then
            log_finding "$SEVERITY_WARNING" "Outdated Document" "Active document not updated in $months_diff months" "$file" "$(grep -n "last_updated: " "$file" | cut -d: -f1)"
            outdated_status=$((outdated_status + 1))
            continue
          fi
        fi
      fi
    elif [ "$status_value" == "Active" ]; then
      # Active documents should have last_updated
      log_finding "$SEVERITY_WARNING" "Missing Last Updated" "Active document missing last_updated field" "$file" ""
      continue
    fi
  fi
  
  # Document passed all checks
  log_finding "$SEVERITY_SUCCESS" "Valid Status" "Document has valid status: $status_value" "$file" ""
  valid_status=$((valid_status + 1))
done

# Create results file for the main script to source
cat > "$TEMP_DIR/${MODULE_NAME}-results.sh" << EOF
# Status check results
status_check_total_docs=$total_docs
status_check_missing_status=$missing_status
status_check_invalid_status=$invalid_status
status_check_outdated_status=$outdated_status
status_check_valid_status=$valid_status
status_check_total_checks=$total_checks
status_check_passed_checks=$passed_checks
status_check_warning_checks=$warning_checks
status_check_critical_checks=$critical_checks

# Update global counters
total_checks=\$((total_checks + $total_checks))
passed_checks=\$((passed_checks + $passed_checks))
warning_checks=\$((warning_checks + $warning_checks))
critical_checks=\$((critical_checks + $critical_checks))
EOF

# Print summary
print_message "$SEVERITY_INFO" "Status check complete!"
print_message "$SEVERITY_INFO" "Total documents: $total_docs"
print_message "$SEVERITY_SUCCESS" "Valid status: $valid_status"
print_message "$SEVERITY_WARNING" "Missing status: $missing_status"
print_message "$SEVERITY_CRITICAL" "Invalid status: $invalid_status"
if [ "$check_level" == "comprehensive" ]; then
  print_message "$SEVERITY_WARNING" "Outdated status: $outdated_status"
fi

exit 0