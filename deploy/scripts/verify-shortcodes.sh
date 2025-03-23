#!/bin/bash

# Script to verify shortcodes in markdown files
# Checks for unclosed or invalid shortcodes

# Colors for output
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

print_message "$BLUE" "Verifying shortcodes in markdown files..."

# Find all markdown files
files=$(find content -name "*.md")
found_issues=0

# Paired shortcodes that require closing tags
paired_shortcodes=(
  "callout"
  "tab"
  "tabs"
  "code"
  "highlight"
  "figure"
)

# Check each file
for file in $files; do
  print_message "$BLUE" "Checking $file"
  
  # Skip checking inside code blocks (use awk to avoid false positives)
  content=$(awk '
    BEGIN { in_code_block = 0; }
    /^```/ { in_code_block = !in_code_block; next; }
    !in_code_block { print; }
  ' "$file")
  
  file_has_issues=0
  
  # Check paired shortcodes
  for shortcode in "${paired_shortcodes[@]}"; do
    opening_count=$(echo "$content" | grep -c "{{< $shortcode")
    closing_count=$(echo "$content" | grep -c "{{< /$shortcode")
    
    if [ $opening_count -ne $closing_count ]; then
      print_message "$RED" "  ✗ Unclosed shortcode: $shortcode (opens: $opening_count, closes: $closing_count)"
      
      # Show lines with opening tags
      echo "$content" | grep -n "{{< $shortcode" | while read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        print_message "$YELLOW" "    Line $line_num: $(echo "$line" | cut -d: -f2-)"
      done
      
      file_has_issues=1
      found_issues=$((found_issues + 1))
    fi
  done
  
  # Check for common syntax errors in shortcodes
  syntax_errors=$(echo "$content" | grep -n -E '{{<[^}]*$' | wc -l)
  if [ $syntax_errors -gt 0 ]; then
    print_message "$RED" "  ✗ Malformed shortcode syntax"
    echo "$content" | grep -n -E '{{<[^}]*$' | while read -r line; do
      line_num=$(echo "$line" | cut -d: -f1)
      print_message "$YELLOW" "    Line $line_num: $(echo "$line" | cut -d: -f2-)"
    done
    
    file_has_issues=1
    found_issues=$((found_issues + 1))
  fi
  
  # Check for missing space after opening tag
  spacing_errors=$(echo "$content" | grep -n -E '{{<\w' | wc -l)
  if [ $spacing_errors -gt 0 ]; then
    print_message "$RED" "  ✗ Missing space after shortcode opening"
    echo "$content" | grep -n -E '{{<\w' | while read -r line; do
      line_num=$(echo "$line" | cut -d: -f1)
      print_message "$YELLOW" "    Line $line_num: $(echo "$line" | cut -d: -f2-)"
    done
    
    file_has_issues=1
    found_issues=$((found_issues + 1))
  fi
  
  if [ $file_has_issues -eq 0 ]; then
    print_message "$GREEN" "  ✓ No shortcode issues found"
  fi
done

# Summary
if [ $found_issues -eq 0 ]; then
  print_message "$GREEN" "✅ All shortcodes verified successfully!"
  exit 0
else
  print_message "$RED" "❌ Found $found_issues files with shortcode issues"
  print_message "$YELLOW" "Please fix these issues before deployment"
  exit 1
fi