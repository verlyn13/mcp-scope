#!/bin/bash

# Run Doc Doctor Health Check System
# This is a convenience script for running the Doc Doctor system

# Default settings
CHECK_LEVEL="standard"
OUTPUT_FORMAT="terminal"
FOCUS_AREA="all"
REPORT_DIR="./doc-reports"

# Function to print help message
show_help() {
  echo "Usage: ./run-doc-doctor.sh [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help                Show this help message"
  echo "  -l, --level LEVEL         Set check level (quick, standard, comprehensive)"
  echo "  -f, --format FORMAT       Set output format (terminal, markdown, json, all)"
  echo "  -a, --area AREA           Set focus area (all, status, shortcodes, frontmatter, links, structure)"
  echo "  -r, --report-dir DIR      Set report directory"
  echo ""
  echo "Examples:"
  echo "  ./run-doc-doctor.sh                                        # Run standard check"
  echo "  ./run-doc-doctor.sh -l quick                               # Run quick check"
  echo "  ./run-doc-doctor.sh -l comprehensive -f markdown           # Run comprehensive check with markdown report"
  echo "  ./run-doc-doctor.sh -a shortcodes                          # Focus on shortcode checks only"
  echo ""
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -l|--level)
      CHECK_LEVEL="$2"
      shift
      ;;
    -f|--format)
      OUTPUT_FORMAT="$2"
      shift
      ;;
    -a|--area)
      FOCUS_AREA="$2"
      shift
      ;;
    -r|--report-dir)
      REPORT_DIR="$2"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

# Validate check level
if [[ ! "$CHECK_LEVEL" =~ ^(quick|standard|comprehensive)$ ]]; then
  echo "Invalid check level: $CHECK_LEVEL. Using 'standard' instead."
  CHECK_LEVEL="standard"
fi

# Validate output format
if [[ ! "$OUTPUT_FORMAT" =~ ^(terminal|markdown|json|all)$ ]]; then
  echo "Invalid output format: $OUTPUT_FORMAT. Using 'terminal' instead."
  OUTPUT_FORMAT="terminal"
fi

# Validate focus area
if [[ ! "$FOCUS_AREA" =~ ^(all|status|shortcodes|frontmatter|links|structure)$ ]]; then
  echo "Invalid focus area: $FOCUS_AREA. Using 'all' instead."
  FOCUS_AREA="all"
fi

# Run Doc Doctor with the specified parameters
./doc-doctor.sh --check-level "$CHECK_LEVEL" --output-format "$OUTPUT_FORMAT" --focus-area "$FOCUS_AREA" --report-dir "$REPORT_DIR"

# Exit with the same status as Doc Doctor
exit $?