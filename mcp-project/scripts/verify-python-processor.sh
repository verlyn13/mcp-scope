#!/bin/bash
# Python Processor Verification Script
# Validates the Python-based processing agent component functionality

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PYTHON_AGENT_DIR="/home/verlyn13/Projects/mcp-scope/mcp-project/agents/python-processor"
DEFAULT_NATS_URL="nats://localhost:4222"

echo -e "${BLUE}=== Python Processor Verification ===${NC}"

# Check if the Python Processor directory exists
if [ ! -d "$PYTHON_AGENT_DIR" ]; then
    echo -e "${RED}Error: Python Processor directory not found at $PYTHON_AGENT_DIR${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Python Environment Check:${NC}"
echo "------------------------------"

# Check for Python executable
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}Error: Python not found. Please install Python 3.11+${NC}"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version | awk '{print $2}')
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

echo -e "${GREEN}✓ Found Python $PYTHON_VERSION${NC}"

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 11 ]); then
    echo -e "${YELLOW}⚠ Python version is below recommended (3.11+)${NC}"
fi

# Check for virtual environment
if [ -d "$PYTHON_AGENT_DIR/venv" ]; then
    echo -e "${GREEN}✓ Python virtual environment exists${NC}"
    
    # Activate the virtual environment for subsequent checks
    source "$PYTHON_AGENT_DIR/venv/bin/activate" 2>/dev/null || true
    
    # Verify activation
    if [[ "$VIRTUAL_ENV" == *"venv"* ]]; then
        echo -e "${GREEN}✓ Virtual environment activated successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Could not activate virtual environment${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Python virtual environment not found${NC}"
    echo "Consider creating a virtual environment:"
    echo "cd $PYTHON_AGENT_DIR && python -m venv venv && source venv/bin/activate"
fi

echo -e "\n${YELLOW}Dependency Check:${NC}"
echo "------------------------------"

# Check for requirements.txt
if [ -f "$PYTHON_AGENT_DIR/requirements.txt" ]; then
    echo -e "${GREEN}✓ requirements.txt file exists${NC}"
    
    # Count number of dependencies
    REQ_COUNT=$(wc -l < "$PYTHON_AGENT_DIR/requirements.txt")
    echo -e "${GREEN}✓ Found $REQ_COUNT dependencies in requirements.txt${NC}"
    
    # Check for essential packages
    ESSENTIAL_PACKAGES=("nats-py" "asyncio" "pydantic" "python-dotenv")
    
    for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
        if grep -q "$pkg" "$PYTHON_AGENT_DIR/requirements.txt"; then
            echo -e "${GREEN}✓ Found essential package: $pkg${NC}"
        else
            echo -e "${YELLOW}⚠ Missing essential package: $pkg${NC}"
        fi
    done
    
    # Verify packages are installed in the environment
    echo -e "\nVerifying installed packages:"
    
    if command -v pip &> /dev/null; then
        MISSING_PACKAGES=0
        
        for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
            pkg_base=$(echo "$pkg" | cut -d'[' -f1 | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | tr -d ' ')
            if pip list | grep -i "$pkg_base" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Package installed: $pkg_base${NC}"
            else
                echo -e "${YELLOW}⚠ Package not installed: $pkg_base${NC}"
                MISSING_PACKAGES=$((MISSING_PACKAGES+1))
            fi
        done
        
        if [ $MISSING_PACKAGES -gt 0 ]; then
            echo -e "\n${YELLOW}Some packages appear to be missing. Try:${NC}"
            echo "cd $PYTHON_AGENT_DIR && source venv/bin/activate && pip install -r requirements.txt"
        fi
    else
        echo -e "${YELLOW}⚠ pip command not found, can't verify installed packages${NC}"
    fi
else
    echo -e "${RED}✘ requirements.txt file not found${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Source Code Check:${NC}"
echo "------------------------------"

# Check for main.py and other essential files
if [ -f "$PYTHON_AGENT_DIR/main.py" ]; then
    echo -e "${GREEN}✓ main.py file exists${NC}"
else
    echo -e "${RED}✘ main.py file not found${NC}"
    exit 1
fi

# Check for other Python modules
PYTHON_FILES=$(find "$PYTHON_AGENT_DIR" -maxdepth 1 -name "*.py" | wc -l)
echo -e "${GREEN}✓ Found $PYTHON_FILES Python files in the project${NC}"

# Check for essential code components
COMPONENT_CHECKS=(
    "nats.aio" 
    "asyncio.run"
    "class Processor" 
    "def process" 
    "async def"
)

for component in "${COMPONENT_CHECKS[@]}"; do
    if grep -r "$component" "$PYTHON_AGENT_DIR"/*.py > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Found component: $component${NC}"
    else
        echo -e "${YELLOW}⚠ Could not find component: $component${NC}"
    fi
done

echo -e "\n${YELLOW}NATS Connectivity Check:${NC}"
echo "------------------------------"

# Check if NATS server is running
if nc -z localhost 4222 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ NATS server is reachable on port 4222${NC}"
    
    # Check for NATS connectivity code
    if grep -r "nats://" "$PYTHON_AGENT_DIR"/*.py > /dev/null 2>&1; then
        echo -e "${GREEN}✓ NATS connection configuration found in code${NC}"
    else
        echo -e "${YELLOW}⚠ NATS connection configuration not found in code${NC}"
    fi
else
    echo -e "${RED}✘ NATS server is not reachable${NC}"
    echo "Please start NATS server before running Python Processor:"
    echo "nats-server -c /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf"
fi

echo -e "\n${YELLOW}Runtime Verification:${NC}"
echo "------------------------------"

# Check if MCP Core is running (required for proper interaction)
if pgrep -f "mcp-core" > /dev/null || \
   ps aux | grep java | grep -v grep | grep -q "mcp-core"; then
    echo -e "${GREEN}✓ MCP Core appears to be running${NC}"
    MCP_RUNNING=true
else
    echo -e "${YELLOW}⚠ MCP Core does not appear to be running${NC}"
    echo "For full functionality, MCP Core should be running"
    MCP_RUNNING=false
fi

# Create a temporary log file
TEMP_LOG=$(mktemp)

# Try running the application with a timeout
echo "Attempting to start Python Processor (with 10s timeout for verification)..."

if [ -d "$PYTHON_AGENT_DIR/venv" ]; then
    # Run with virtual environment if it exists
    (cd "$PYTHON_AGENT_DIR" && \
     source venv/bin/activate && \
     timeout 10s python main.py) > "$TEMP_LOG" 2>&1 &
else
    # Otherwise use system Python
    (cd "$PYTHON_AGENT_DIR" && \
     timeout 10s $PYTHON_CMD main.py) > "$TEMP_LOG" 2>&1 &
fi

RUN_PID=$!

# Wait a moment for startup
sleep 5

# Check if the process is still running
if ps -p $RUN_PID > /dev/null; then
    echo -e "${GREEN}✓ Python Processor started successfully${NC}"
    
    # Extract interesting log lines
    STARTUP_LOGS=$(grep -E "Starting|Connecting|Initialized|Ready|Listening|Processing" "$TEMP_LOG" || true)
    if [ -n "$STARTUP_LOGS" ]; then
        echo "Startup log highlights:"
        echo "$STARTUP_LOGS"
    fi
    
    # Kill the process as we only needed it for verification
    kill $RUN_PID > /dev/null 2>&1 || true
    wait $RUN_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Verification complete, stopped test instance${NC}"
else
    echo -e "${RED}✘ Python Processor failed to start${NC}"
    echo "Error details:"
    grep -E "Error|Exception|Failed|Traceback" "$TEMP_LOG" || cat "$TEMP_LOG"
fi

# Clean up
rm -f "$TEMP_LOG"

echo -e "\n${YELLOW}Verification Summary:${NC}"
echo "------------------------------"

# Provide summary and next steps
echo -e "${GREEN}✓ Python Processor verification completed${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo "1. To run Python Processor: cd $PYTHON_AGENT_DIR && source venv/bin/activate && python main.py"
echo "2. Make sure MCP Core is running before starting Python Processor"
echo "3. If you encounter dependency issues: pip install -r requirements.txt"
echo "4. To verify full system integration: ./scripts/verify-integration.sh"

exit 0