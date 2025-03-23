#!/bin/bash

# Wrapper script for backward compatibility with previous deployment scripts
# This redirects to the new unified deployment system

# Colors for output
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}┌────────────────────────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│ NOTE: This script is maintained for backward compatibility. │${NC}"
echo -e "${YELLOW}│ Please use the new unified deployment system instead:       │${NC}"
echo -e "${YELLOW}│                                                             │${NC}"
echo -e "${BLUE}│ ./deploy/unified-deploy.sh                                  │${NC}"
echo -e "${YELLOW}│                                                             │${NC}"
echo -e "${YELLOW}└────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Default parameters for the new system
DEPLOY_MODE="auto"
OUTPUT_MODE="normal"
SKIP_VERIFY="false"
SKIP_PRECACHE="false"
TARGET_BRANCH="gh-pages"

# Parse any parameters passed to the old script and map them to the new system
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --minimal)
      DEPLOY_MODE="minimal"
      shift
      ;;
    --container)
      DEPLOY_MODE="container"
      shift
      ;;
    --local)
      DEPLOY_MODE="local"
      shift
      ;;
    --verbose)
      OUTPUT_MODE="verbose"
      shift
      ;;
    --skip-verify)
      SKIP_VERIFY="true"
      shift
      ;;
    --branch)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1. Using defaults."
      shift
      ;;
  esac
done

echo "Translating command to new deployment system..."
echo ""

# Build the new command
COMMAND="./deploy/unified-deploy.sh --mode $DEPLOY_MODE --output $OUTPUT_MODE --branch $TARGET_BRANCH"

if [ "$SKIP_VERIFY" == "true" ]; then
  COMMAND="$COMMAND --skip-verify"
fi

if [ "$SKIP_PRECACHE" == "true" ]; then
  COMMAND="$COMMAND --skip-precache"
fi

# Show the command that will be executed
echo -e "${BLUE}Executing: ${COMMAND}${NC}"
echo ""

# Execute the new deployment script
exec $COMMAND

# If exec fails, show error
echo -e "${YELLOW}Failed to execute deployment script. Please run manually:${NC}"
echo -e "${BLUE}${COMMAND}${NC}"
exit 1