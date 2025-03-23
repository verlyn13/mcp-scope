#!/bin/bash

# Script to verify shortcodes in markdown files
# Focused on deployment verification (streamlined version)
# Uses basic shell tools without dependencies on awk

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
files=$(find content -name "*.md" 2>/dev/null)

# If no content directory, check at root level (might be a different structure)
if [ -z "$files" ]; then
  files=$(find . -maxdepth 2 -name "*.md" 2>/dev/null)
fi

# If still no files found, exit with error
if [ -z "$files" ]; then
  print_message "$RED" "No markdown files found. Is the content directory missing?"
  exit 1
fi

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
  
  # Simple method to filter out code blocks
  # We'll process the file line by line
  in_code_block=0
  filtered_content=""
  
  while IFS= read -r line; do
    # Check if this line starts/ends a code block
    if [[ "$line" =~ ^[\s]*\`\`\`.* ]]; then
      in_code_block=$((1 - in_code_block))
      continue
    fi
    
    # If not in a code block, add to filtered content
    if [ $in_code_block -eq 0 ]; then
      # Skip lines that show examples of shortcodes
      if [[ "$line" == *"Example"* && "$line" == *"{{<"* ]]; then
        continue
      fi
      
      # Skip lines that are clearly showing syntax examples
      if [[ "$line" == *"- ❌"* && "$line" == *"{{<"* ]] || 
         [[ "$line" == *"- ✅"* && "$line" == *"{{<"* ]]; then
        continue
      fi
      
      # Add this line to our filtered content
      filtered_content="${filtered_content}${line}\n"
    fi
  done < "$file"
  
  file_has_issues=0
  
  # Check paired shortcodes
  for shortcode in "${paired_shortcodes[@]}"; do
    # Count opening tags
    opening_count=$(echo -e "$filtered_content" | grep -c "{{< $shortcode")
    # Count closing tags
    closing_count=$(echo -e "$filtered_content" | grep -c "{{< /$shortcode")
    
    if [ $opening_count -ne $closing_count ]; then
      print_message "$RED" "  ✗ Unclosed shortcode: $shortcode (opens: $opening_count, closes: $closing_count)"
      
      # Find all instances of the opening shortcode for debugging
      line_num=1
      while IFS= read -r line; do
        if [[ "$line" == *"{{< $shortcode"* ]]; then
          print_message "$YELLOW" "    Line $line_num: $line"
        fi
        line_num=$((line_num + 1))
      done < "$file"
      
      file_has_issues=1
      found_issues=$((found_issues + 1))
    fi
  done
  
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