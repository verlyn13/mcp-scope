#!/bin/bash
# Setup MCP Verification Tools
# Makes all verification scripts executable and configures the scripts directory

set -e

# Color definitions for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPTS_DIR="/home/verlyn13/Projects/mcp-scope/mcp-project/scripts"

echo -e "${BLUE}=== Setting up MCP Verification Tools ===${NC}"

# Make all scripts executable
echo "Making verification scripts executable..."
chmod +x "$SCRIPTS_DIR"/*.sh

# Count the scripts
SCRIPT_COUNT=$(find "$SCRIPTS_DIR" -name "*.sh" | wc -l)
echo -e "${GREEN}✓ Made $SCRIPT_COUNT scripts executable${NC}"

# List all available verification tools
echo -e "\n${BLUE}Available Verification Tools:${NC}"
for script in "$SCRIPTS_DIR"/*.sh; do
    if [ -f "$script" ]; then
        SCRIPT_NAME=$(basename "$script")
        DESCRIPTION=""
        
        # Extract descriptions based on script name
        case "$SCRIPT_NAME" in
            "container-health-check.sh")
                DESCRIPTION="Verifies the health of all containers in the MCP environment"
                ;;
            "setup-verification-tools.sh")
                DESCRIPTION="This script - makes all verification scripts executable"
                ;;
            "verify-nats.sh")
                DESCRIPTION="Validates the NATS messaging server setup and functionality"
                ;;
            "verify-mcp-core.sh")
                DESCRIPTION="Validates the MCP Core orchestrator component functionality"
                ;;
            "verify-camera-agent.sh")
                DESCRIPTION="Validates the Camera Integration Agent component functionality"
                ;;
            "verify-python-processor.sh")
                DESCRIPTION="Validates the Python-based processing agent component functionality"
                ;;
            "verify-integration.sh")
                DESCRIPTION="Validates end-to-end integration between all components of the MCP system"
                ;;
            *)
                DESCRIPTION="Verification script"
                ;;
        esac
        
        echo -e "${GREEN}→ $SCRIPT_NAME${NC}: $DESCRIPTION"
    fi
done

echo -e "\n${BLUE}Usage Examples:${NC}"
echo "./scripts/verify-nats.sh            # Verify NATS server"
echo "./scripts/verify-mcp-core.sh        # Verify MCP Core"
echo "./scripts/container-health-check.sh # Check container health"
echo "./scripts/verify-integration.sh     # Verify full system integration"

echo -e "\n${GREEN}Verification tools setup complete!${NC}"
echo -e "You can now run these scripts to verify your MCP environment."

exit 0