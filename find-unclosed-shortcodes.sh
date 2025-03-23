#!/bin/bash

# Script to find unclosed shortcodes in markdown files

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
  # Get shortcodes that need closing
  opening_callouts=$(grep -n "{{< callout" "$file" | wc -l)
  closing_callouts=$(grep -n "{{< /callout" "$file" | wc -l)
  
  # Check if counts don't match
  if [ $opening_callouts -ne $closing_callouts ]; then
    echo -e "${RED}Found unclosed callout in $file${NC}"
    echo -e "${YELLOW}Opening tags: $opening_callouts, Closing tags: $closing_callouts${NC}"
    
    # Show the opening callouts
    echo -e "${BLUE}Opening callouts:${NC}"
    grep -n "{{< callout" "$file"
    
    # Show the closing callouts
    echo -e "${BLUE}Closing callouts:${NC}"
    grep -n "{{< /callout" "$file"
    
    found=$((found + 1))
  fi
done

if [ $found -eq 0 ]; then
  echo -e "${GREEN}No unclosed callout shortcodes found!${NC}"
else
  echo -e "${RED}Found $found files with unclosed callout shortcodes.${NC}"
fi

# Check for other common shortcodes that need closing
echo -e "\n${BLUE}Checking other shortcodes that might need closing...${NC}"

for shortcode in "figure" "tab" "tabs" "code" "highlight"; do
  echo -e "${YELLOW}Checking for unclosed '$shortcode' shortcodes...${NC}"
  found=0
  
  for file in $files; do
    opening=$(grep -c "{{< $shortcode" "$file")
    closing=$(grep -c "{{< /$shortcode" "$file")
    
    if [ $opening -ne $closing ] && [ $opening -gt 0 ]; then
      echo -e "${RED}Found unclosed $shortcode in $file${NC}"
      echo -e "${YELLOW}Opening tags: $opening, Closing tags: $closing${NC}"
      found=$((found + 1))
    fi
  done
  
  if [ $found -eq 0 ]; then
    echo -e "${GREEN}No unclosed $shortcode shortcodes found!${NC}"
  else
    echo -e "${RED}Found $found files with unclosed $shortcode shortcodes.${NC}"
  fi
done

echo -e "\n${BLUE}Scan complete.${NC}"