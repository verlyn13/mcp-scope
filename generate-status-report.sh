#!/bin/bash

# Script to generate a status report for all documents
# Creates a CSV file with document details and statuses

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Generating document status report...${NC}"

# Set output file
report_file="document-status-report.csv"

# Create CSV header
echo "Document Path,Title,Status,Version,Created Date,Last Updated,Contributors" > "$report_file"

# Find all markdown files
files=$(find content -name "*.md")
status_counts=()
declare -A status_map

# Initialize counts
status_map["Draft"]=0
status_map["Review"]=0
status_map["Active"]=0
status_map["Deprecated"]=0
status_map["Archived"]=0
status_map["Missing"]=0

process_count=0
total_files=$(echo "$files" | wc -w)

for file in $files; do
  process_count=$((process_count + 1))
  
  # Show progress
  if [ $((process_count % 10)) -eq 0 ] || [ $process_count -eq $total_files ]; then
    echo -e "${YELLOW}Processing file $process_count of $total_files...${NC}"
  fi
  
  # Extract front matter
  front_matter=$(sed -n '/^---$/,/^---$/p' "$file")
  
  # Extract fields (with fallbacks)
  title=$(echo "$front_matter" | grep -E "^title: " | sed -E 's/^title: "?([^"]*)"?$/\1/')
  title=${title:-"Untitled"}
  
  status=$(echo "$front_matter" | grep -E "^status: " | sed -E 's/^status: "?([^"]*)"?$/\1/')
  if [ -z "$status" ]; then
    status="Missing"
  fi
  
  version=$(echo "$front_matter" | grep -E "^version: " | sed -E 's/^version: "?([^"]*)"?$/\1/')
  version=${version:-"N/A"}
  
  created=$(echo "$front_matter" | grep -E "^date_created: " | sed -E 's/^date_created: "?([^"]*)"?$/\1/')
  created=${created:-"N/A"}
  
  updated=$(echo "$front_matter" | grep -E "^last_updated: " | sed -E 's/^last_updated: "?([^"]*)"?$/\1/')
  updated=${updated:-"N/A"}
  
  # Extract contributors (may be a list)
  contributors=$(echo "$front_matter" | sed -n '/^contributors:/,/^[a-z]/{/^contributors:/d; /^[a-z]/d; p}' | \
                grep -Eo '"[^"]+"' | tr '\n' '|' | sed 's/|$//')
  contributors=${contributors:-"N/A"}
  
  # Escape any commas in fields
  title=$(echo "$title" | sed 's/,/\\,/g')
  
  # Write to CSV
  echo "$file,$title,$status,$version,$created,$updated,$contributors" >> "$report_file"
  
  # Increment status count
  status_map["$status"]=$((status_map["$status"] + 1))
done

# Generate summary report
summary_file="document-status-summary.md"

echo "# Document Status Summary" > "$summary_file"
echo "" >> "$summary_file"
echo "Generated on: $(date +'%Y-%m-%d %H:%M:%S')" >> "$summary_file"
echo "" >> "$summary_file"
echo "## Status Distribution" >> "$summary_file"
echo "" >> "$summary_file"
echo "| Status | Count | Percentage |" >> "$summary_file"
echo "|--------|-------|------------|" >> "$summary_file"

# Calculate total documents (excluding index files)
total_docs=$(($total_files - $(grep -c "_index.md" <<< "$files")))

# Add status counts to summary
for status in "Active" "Review" "Draft" "Deprecated" "Archived" "Missing"; do
  count=${status_map["$status"]}
  percentage=$(( (count * 100) / total_docs ))
  echo "| $status | $count | ${percentage}% |" >> "$summary_file"
done

# Add recently updated documents
echo "" >> "$summary_file"
echo "## Recently Updated Documents" >> "$summary_file"
echo "" >> "$summary_file"
echo "| Document | Status | Last Updated |" >> "$summary_file"
echo "|----------|--------|--------------|" >> "$summary_file"

# Sort by last updated date (recent first) and take top 10
recent_updates=$(sort -t, -k6,6r "$report_file" | head -n 10)
while IFS=, read -r path title status version created updated contributors; do
  if [ "$updated" != "N/A" ] && [ "$path" != "Document Path" ]; then
    # Remove 'content/' prefix from path for cleaner display
    display_path=$(echo "$path" | sed 's|^content/||')
    echo "| $display_path | $status | $updated |" >> "$summary_file"
  fi
done <<< "$recent_updates"

echo -e "${GREEN}✅ Status report generated successfully!${NC}"
echo -e "${BLUE}CSV report: ${YELLOW}$report_file${NC}"
echo -e "${BLUE}Summary report: ${YELLOW}$summary_file${NC}"

# Print summary to terminal
echo -e "\n${BLUE}======= Status Summary =======${NC}"
for status in "Active" "Review" "Draft" "Deprecated" "Archived" "Missing"; do
  count=${status_map["$status"]}
  percentage=$(( (count * 100) / total_docs ))
  
  # Choose color based on status
  color=$NC
  case $status in
    "Active") color=$GREEN ;;
    "Review") color=$BLUE ;;
    "Draft") color=$YELLOW ;;
    "Missing") color=$RED ;;
    *) color=$NC ;;
  esac
  
  echo -e "${color}$status: $count (${percentage}%)${NC}"
done

echo -e "\n${GREEN}Total documents: $total_docs${NC}"