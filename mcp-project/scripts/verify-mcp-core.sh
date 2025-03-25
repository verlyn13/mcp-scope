#!/bin/bash
# MCP Core Verification Script
# Validates the MCP Core orchestrator component functionality

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MCP_CORE_DIR="/home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core"
DEFAULT_NATS_URL="nats://localhost:4222"

echo -e "${BLUE}=== MCP Core Verification ===${NC}"

# Check if the MCP Core directory exists
if [ ! -d "$MCP_CORE_DIR" ]; then
    echo -e "${RED}Error: MCP Core directory not found at $MCP_CORE_DIR${NC}"
    exit 1
fi

# Check for Gradle wrapper
if [ ! -f "$MCP_CORE_DIR/gradlew" ]; then
    echo -e "${RED}Error: Gradle wrapper not found in MCP Core directory${NC}"
    echo "You may need to generate the Gradle wrapper:"
    echo "cd $MCP_CORE_DIR && gradle wrapper --gradle-version 8.3"
    exit 1
fi

echo -e "\n${YELLOW}Build Configuration Check:${NC}"
echo "------------------------------"

# Check build.gradle.kts
if [ -f "$MCP_CORE_DIR/build.gradle.kts" ]; then
    echo -e "${GREEN}✓ build.gradle.kts file exists${NC}"
    
    # Check for essential dependencies
    echo "Checking for essential dependencies..."
    
    DEPENDENCY_CHECKS=(
        "io.nats:jnats" 
        "org.jetbrains.kotlinx:kotlinx-coroutines-core"
        "com.fasterxml.jackson.module:jackson-module-kotlin"
        "ch.qos.logback:logback-classic"
    )
    
    for dep in "${DEPENDENCY_CHECKS[@]}"; do
        if grep -q "$dep" "$MCP_CORE_DIR/build.gradle.kts"; then
            echo -e "${GREEN}✓ Found dependency: $dep${NC}"
        else
            echo -e "${YELLOW}⚠ Missing dependency: $dep${NC}"
        fi
    done
else
    echo -e "${RED}✘ build.gradle.kts file not found${NC}"
    exit 1
fi

# Check settings.gradle.kts
if [ -f "$MCP_CORE_DIR/settings.gradle.kts" ]; then
    echo -e "${GREEN}✓ settings.gradle.kts file exists${NC}"
else
    echo -e "${YELLOW}⚠ settings.gradle.kts file not found${NC}"
fi

# Check for source directories
if [ -d "$MCP_CORE_DIR/src/main/kotlin" ]; then
    echo -e "${GREEN}✓ Source directory exists${NC}"
    
    # Count Kotlin files
    KOTLIN_FILES=$(find "$MCP_CORE_DIR/src/main/kotlin" -name "*.kt" | wc -l)
    echo -e "${GREEN}✓ Found $KOTLIN_FILES Kotlin source files${NC}"
else
    echo -e "${RED}✘ Source directory not found${NC}"
    exit 1
fi

# Check for resources directory and configuration files
if [ -d "$MCP_CORE_DIR/src/main/resources" ]; then
    echo -e "${GREEN}✓ Resources directory exists${NC}"
    
    # Check for logback.xml
    if [ -f "$MCP_CORE_DIR/src/main/resources/logback.xml" ]; then
        echo -e "${GREEN}✓ logback.xml configuration found${NC}"
    else
        echo -e "${YELLOW}⚠ logback.xml configuration not found${NC}"
    fi
    
    # Check for application.conf if exists
    if [ -f "$MCP_CORE_DIR/src/main/resources/application.conf" ]; then
        echo -e "${GREEN}✓ application.conf configuration found${NC}"
    else
        echo -e "${YELLOW}⚠ application.conf not found, may be using environment variables${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Resources directory not found${NC}"
fi

echo -e "\n${YELLOW}Gradle Build Verification:${NC}"
echo "------------------------------"

# First make gradlew executable if it's not
chmod +x "$MCP_CORE_DIR/gradlew" 2>/dev/null || true

# Check if we can build the project
echo "Attempting to build MCP Core (this may take a moment)..."
if cd "$MCP_CORE_DIR" && ./gradlew clean build -x test --console=plain --info 2>&1 | grep -q "BUILD SUCCESSFUL"; then
    echo -e "${GREEN}✓ Gradle build successful${NC}"
else
    echo -e "${RED}✘ Gradle build failed${NC}"
    echo "To see detailed build errors, run:"
    echo "cd $MCP_CORE_DIR && ./gradlew clean build -x test --info"
    exit 1
fi

echo -e "\n${YELLOW}NATS Connectivity Check:${NC}"
echo "------------------------------"

# Check if NATS server is running
if nc -z localhost 4222 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ NATS server is reachable on port 4222${NC}"
    
    # Check for connectivity code in the codebase
    if grep -r "nats://" "$MCP_CORE_DIR/src" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ NATS connection configuration found in code${NC}"
    else
        echo -e "${YELLOW}⚠ NATS connection configuration not found in code${NC}"
    fi
else
    echo -e "${RED}✘ NATS server is not reachable${NC}"
    echo "Please start NATS server before running MCP Core:"
    echo "nats-server -c /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf"
fi

echo -e "\n${YELLOW}Runtime Verification:${NC}"
echo "------------------------------"

# Create a temporary log file
TEMP_LOG=$(mktemp)

# Try running the application with a timeout
echo "Attempting to start MCP Core (with 10s timeout for verification)..."
(cd "$MCP_CORE_DIR" && timeout 10s ./gradlew run) > "$TEMP_LOG" 2>&1 &
RUN_PID=$!

# Wait a moment for startup
sleep 5

# Check if the process is still running
if ps -p $RUN_PID > /dev/null; then
    echo -e "${GREEN}✓ MCP Core started successfully${NC}"
    
    # Extract interesting log lines
    STARTUP_LOGS=$(grep -E "Starting|Connecting|Initialized|Ready|Listening" "$TEMP_LOG" || true)
    if [ -n "$STARTUP_LOGS" ]; then
        echo "Startup log highlights:"
        echo "$STARTUP_LOGS"
    fi
    
    # Kill the process as we only needed it for verification
    kill $RUN_PID > /dev/null 2>&1 || true
    wait $RUN_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Verification complete, stopped test instance${NC}"
else
    echo -e "${RED}✘ MCP Core failed to start${NC}"
    echo "Error details:"
    grep -E "Error|Exception|Failed" "$TEMP_LOG" || cat "$TEMP_LOG"
fi

# Clean up
rm -f "$TEMP_LOG"

echo -e "\n${YELLOW}Component Structure Verification:${NC}"
echo "------------------------------"

# Check for essential component packages and classes
declare -A essential_components
essential_components=(
    ["orchestrator"]="Orchestrator or McpServer main class" 
    ["agent"]="Agent interface or implementations"
    ["task"]="Task management classes"
    ["nats"]="NATS messaging integration"
    ["model"]="Data models"
    ["config"]="Configuration classes"
)

for component in "${!essential_components[@]}"; do
    if find "$MCP_CORE_DIR/src" -type d -name "*$component*" | grep -q . || \
       find "$MCP_CORE_DIR/src" -type f -name "*$component*" | grep -q .; then
        echo -e "${GREEN}✓ Found ${essential_components[$component]}${NC}"
    else
        echo -e "${YELLOW}⚠ Could not find ${essential_components[$component]}${NC}"
    fi
done

echo -e "\n${YELLOW}Verification Summary:${NC}"
echo "------------------------------"

# Provide summary and next steps
echo -e "${GREEN}✓ MCP Core verification completed${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo "1. To run MCP Core: cd $MCP_CORE_DIR && ./gradlew run"
echo "2. To verify Camera Agent: ./scripts/verify-camera-agent.sh"
echo "3. To verify system integration: ./scripts/verify-integration.sh"

exit 0