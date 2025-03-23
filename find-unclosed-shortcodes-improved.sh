#!/bin/bash

# Improved script to find unclosed shortcodes in markdown files
# Ignores shortcodes inside code blocks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Scanning for unclosed shortcodes in markdown files...${NC}"

# Find all markdown files
files=$(find content -name "*.md")
found=0

for file in $files; do
  echo -e "${YELLOW}Checking $file${NC}"
  
  # Extract content, ignoring code blocks for analysis
  content=$(awk '
    BEGIN { in_code_block = 0; in_inline_code = 0; }
    /^```/ { in_code_block = !in_code_block; next; }
    /`/ { 
      if (!in_code_block) {
        gsub(/`[^`]*`/, ""); # Remove inline code
      }
    }
    !in_code_block { print; }
  ' "$file")
  
  # Count opening and closing callout tags in the filtered content
  opening_callouts=$(echo "$content" | grep -c "{{< callout")
  closing_callouts=$(echo "$content" | grep -c "{{< /callout")
  
  # Check if counts don't match
  if [ $opening_callouts -ne $closing_callouts ]; then
    echo -e "${RED}Found unclosed callout in $file${NC}"
    echo -e "${YELLOW}Opening tags: $opening_callouts, Closing tags: $closing_callouts${NC}"
    
    # Extract line numbers
    line_numbers=$(grep -n "{{< callout" "$file" | grep -v '```' | cut -d: -f1)
    echo -e "${BLUE}Opening callouts at lines: $line_numbers${NC}"
    
    found=$((found + 1))
  else 
    echo -e "${GREEN}✓ All callout shortcodes properly closed${NC}"
  fi
done

if [ $found -eq 0 ]; then
  echo -e "${GREEN}No unclosed callout shortcodes found!${NC}"
else
  echo -e "${RED}Found $found files with unclosed callout shortcodes.${NC}"
fi

echo -e "\n${BLUE}Scan complete.${NC}"