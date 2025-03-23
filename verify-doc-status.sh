#!/bin/bash

# Script to verify status fields in document front matter
# Checks for missing or invalid status fields in markdown files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valid status values
valid_statuses=("Draft" "Review" "Active" "Deprecated" "Archived")

echo -e "${BLUE}Verifying document status fields...${NC}"

# Find all markdown files
files=$(find content -name "*.md")
missing_status=0
invalid_status=0
valid_files=0

for file in $files; do
  # Extract the front matter
  front_matter=$(sed -n '/^---$/,/^---$/p' "$file")
  
  # Check if status field exists
  status_line=$(echo "$front_matter" | grep -E "^status: ")
  
  if [ -z "$status_line" ]; then
    echo -e "${YELLOW}Missing status field in $file${NC}"
    missing_status=$((missing_status + 1))
    continue
  fi
  
  # Extract status value
  status_value=$(echo "$status_line" | sed -E 's/^status: "?([^"]*)"?$/\1/')
  
  # Check if status value is valid
  is_valid=false
  for valid_status in "${valid_statuses[@]}"; do
    if [ "$status_value" = "$valid_status" ]; then
      is_valid=true
      break
    fi
  done
  
  if [ "$is_valid" = false ]; then
    echo -e "${RED}Invalid status '$status_value' in $file${NC}"
    echo -e "${YELLOW}Valid statuses: ${valid_statuses[*]}${NC}"
    invalid_status=$((invalid_status + 1))
  else
    valid_files=$((valid_files + 1))
    echo -e "${GREEN}✓ $file - Status: $status_value${NC}"
  fi
done

total_files=$(echo "$files" | wc -w)

echo -e "\n${BLUE}======= Status Verification Summary =======${NC}"
echo -e "${GREEN}Total documents: $total_files${NC}"
echo -e "${GREEN}Valid status fields: $valid_files${NC}"
echo -e "${YELLOW}Missing status fields: $missing_status${NC}"
echo -e "${RED}Invalid status fields: $invalid_status${NC}"

if [ $missing_status -eq 0 ] && [ $invalid_status -eq 0 ]; then
  echo -e "\n${GREEN}✅ All documents have valid status fields!${NC}"
  exit 0
else
  echo -e "\n${YELLOW}⚠️ Some documents need status field corrections.${NC}"
  echo -e "${YELLOW}Please update the missing or invalid status fields.${NC}"
  exit 1
fi