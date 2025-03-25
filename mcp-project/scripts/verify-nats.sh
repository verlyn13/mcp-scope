#!/bin/bash
# NATS Server Verification Script
# Validates the NATS messaging server setup and functionality

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_PATH="/home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf"
NATS_URL="nats://localhost:4222"

echo -e "${BLUE}=== NATS Server Verification ===${NC}"

# Check if nats-server is installed
if ! command -v nats-server &> /dev/null; then
    echo -e "${RED}Error: nats-server is not installed${NC}"
    echo "Please install NATS server following the instructions in environment-setup.md"
    exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}Error: NATS configuration file not found at $CONFIG_PATH${NC}"
    exit 1
fi

echo -e "\n${YELLOW}NATS Configuration Check:${NC}"
echo "------------------------------"

# Validate configuration file format
if nats-server --config_check "$CONFIG_PATH" &> /dev/null; then
    echo -e "${GREEN}✓ Configuration file syntax is valid${NC}"
else
    echo -e "${RED}✘ Configuration file syntax is invalid${NC}"
    echo "Trying to check with verbose output:"
    nats-server --config_check "$CONFIG_PATH" -DV
    exit 1
fi

# Check configuration content
echo -e "\n${YELLOW}Configuration Details:${NC}"
echo "------------------------------"

# Extract and display key settings
LISTEN_PORT=$(grep -E "^port:" "$CONFIG_PATH" | awk '{print $2}')
HTTP_PORT=$(grep -E "^http_port:" "$CONFIG_PATH" | awk '{print $2}')
MAX_PAYLOAD=$(grep -E "^max_payload:" "$CONFIG_PATH" | awk '{print $2}')

[ -n "$LISTEN_PORT" ] && echo -e "${GREEN}✓ NATS client port:${NC} $LISTEN_PORT" || echo -e "${YELLOW}⚠ NATS client port not defined, using default (4222)${NC}"
[ -n "$HTTP_PORT" ] && echo -e "${GREEN}✓ HTTP monitoring port:${NC} $HTTP_PORT" || echo -e "${YELLOW}⚠ HTTP monitoring port not defined${NC}"
[ -n "$MAX_PAYLOAD" ] && echo -e "${GREEN}✓ Maximum payload size:${NC} $MAX_PAYLOAD" || echo -e "${YELLOW}⚠ Maximum payload size not defined, using default${NC}"

# Check if NATS is running
echo -e "\n${YELLOW}NATS Server Status:${NC}"
echo "------------------------------"

NATS_RUNNING=false
if pgrep -x "nats-server" > /dev/null; then
    echo -e "${GREEN}✓ NATS server is running${NC}"
    NATS_RUNNING=true
else
    echo -e "${YELLOW}⚠ NATS server is not running${NC}"
    
    # Offer to start NATS
    read -p "Do you want to start NATS server? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting NATS server with configuration at $CONFIG_PATH"
        nats-server -c "$CONFIG_PATH" > /dev/null 2>&1 &
        NATS_PID=$!
        sleep 2
        
        if ps -p $NATS_PID > /dev/null; then
            echo -e "${GREEN}✓ NATS server started successfully (PID: $NATS_PID)${NC}"
            NATS_RUNNING=true
        else
            echo -e "${RED}✘ Failed to start NATS server${NC}"
            exit 1
        fi
    fi
fi

# If NATS is running, perform additional checks
if [ "$NATS_RUNNING" = true ]; then
    # Check connectivity
    if nc -z localhost ${LISTEN_PORT:-4222} > /dev/null 2>&1; then
        echo -e "${GREEN}✓ NATS server is accepting connections on port ${LISTEN_PORT:-4222}${NC}"
    else
        echo -e "${RED}✘ Cannot connect to NATS server on port ${LISTEN_PORT:-4222}${NC}"
        exit 1
    fi
    
    # Check HTTP monitoring if enabled
    if [ -n "$HTTP_PORT" ]; then
        if nc -z localhost $HTTP_PORT > /dev/null 2>&1; then
            echo -e "${GREEN}✓ NATS HTTP monitoring is accessible on port $HTTP_PORT${NC}"
            
            # Get server information through the monitoring endpoint
            if command -v curl &> /dev/null; then
                echo -e "\n${YELLOW}NATS Server Info:${NC}"
                echo "------------------------------"
                
                SERVER_INFO=$(curl -s http://localhost:$HTTP_PORT/varz | grep -E "version|server_id|uptime")
                if [ -n "$SERVER_INFO" ]; then
                    echo -e "$SERVER_INFO" | sed 's/"//' | sed 's/",//' | sed 's/{//' |
                    while IFS=":" read -r key value; do
                        echo -e "${GREEN}$key:${NC} $value"
                    done
                else
                    echo -e "${YELLOW}⚠ Could not retrieve server information${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠ NATS HTTP monitoring is not accessible on port $HTTP_PORT${NC}"
        fi
    fi
    
    # Test basic pub/sub functionality if nats CLI is available
    if command -v nats &> /dev/null; then
        echo -e "\n${YELLOW}Testing NATS Pub/Sub Functionality:${NC}"
        echo "------------------------------"
        
        # Generate a unique subject for testing
        TEST_SUBJECT="mcp.test.$(date +%s)"
        TEST_MESSAGE="Test message $(date +%s)"
        
        # Start a background subscription
        echo "Starting test subscriber on $TEST_SUBJECT..."
        
        # Create a temporary file for the subscription output
        TMP_SUB_FILE=$(mktemp)
        
        # Start subscription in background with timeout
        timeout 5s nats sub --server="$NATS_URL" "$TEST_SUBJECT" > "$TMP_SUB_FILE" 2>&1 &
        SUB_PID=$!
        
        # Allow subscription to initialize
        sleep 1
        
        # Publish test message
        echo "Publishing test message to $TEST_SUBJECT..."
        if nats pub --server="$NATS_URL" "$TEST_SUBJECT" "$TEST_MESSAGE" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Message published successfully${NC}"
            
            # Wait a moment for the message to be received
            sleep 2
            
            # Check if message was received
            if grep -q "$TEST_MESSAGE" "$TMP_SUB_FILE"; then
                echo -e "${GREEN}✓ Message received by subscriber${NC}"
                echo -e "${GREEN}✓ NATS pub/sub functionality verified${NC}"
            else
                echo -e "${RED}✘ Message was not received by subscriber${NC}"
                echo "Subscriber output:"
                cat "$TMP_SUB_FILE"
            fi
        else
            echo -e "${RED}✘ Failed to publish message${NC}"
        fi
        
        # Clean up
        rm -f "$TMP_SUB_FILE"
        
        # Ensure subscription process is terminated
        if ps -p $SUB_PID > /dev/null 2>&1; then
            kill $SUB_PID > /dev/null 2>&1
        fi
    else
        echo -e "${YELLOW}⚠ NATS CLI not found, skipping pub/sub test${NC}"
        echo "Install NATS CLI with: curl -sf https://install.nats.io/install.sh | sh"
    fi
fi

echo -e "\n${YELLOW}Verification Summary:${NC}"
echo "------------------------------"

if [ "$NATS_RUNNING" = true ]; then
    echo -e "${GREEN}✓ NATS server is properly configured and running${NC}"
    echo -e "${GREEN}✓ The messaging infrastructure is ready for MCP components${NC}"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "1. Verify MCP Core with: ./scripts/verify-mcp-core.sh"
    echo "2. Start additional components according to local-development-guide.md"
else
    echo -e "${RED}✘ NATS server is not running${NC}"
    echo -e "${YELLOW}Please start NATS server before running MCP components${NC}"
    
    echo -e "\n${BLUE}To start NATS:${NC}"
    echo "nats-server -c $CONFIG_PATH &"
fi

exit 0