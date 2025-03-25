#!/bin/bash
# Camera Agent Verification Script
# Validates the Camera Integration Agent component functionality

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CAMERA_AGENT_DIR="/home/verlyn13/Projects/mcp-scope/mcp-project/agents/camera-agent"
DEFAULT_NATS_URL="nats://localhost:4222"

echo -e "${BLUE}=== Camera Agent Verification ===${NC}"

# Check if the Camera Agent directory exists
if [ ! -d "$CAMERA_AGENT_DIR" ]; then
    echo -e "${RED}Error: Camera Agent directory not found at $CAMERA_AGENT_DIR${NC}"
    exit 1
fi

# Check for Gradle wrapper
if [ ! -f "$CAMERA_AGENT_DIR/gradlew" ]; then
    echo -e "${RED}Error: Gradle wrapper not found in Camera Agent directory${NC}"
    echo "You may need to generate the Gradle wrapper:"
    echo "cd $CAMERA_AGENT_DIR && gradle wrapper --gradle-version 8.3"
    exit 1
fi

echo -e "\n${YELLOW}Build Configuration Check:${NC}"
echo "------------------------------"

# Check build.gradle.kts
if [ -f "$CAMERA_AGENT_DIR/build.gradle.kts" ]; then
    echo -e "${GREEN}✓ build.gradle.kts file exists${NC}"
    
    # Check for essential dependencies
    echo "Checking for essential dependencies..."
    
    DEPENDENCY_CHECKS=(
        "io.nats:jnats" 
        "org.jetbrains.kotlinx:kotlinx-coroutines-core"
        "com.fasterxml.jackson.module:jackson-module-kotlin"
        "ch.qos.logback:logback-classic"
        "org.usb4java:usb4java" # USB library specifically for Camera Agent
    )
    
    for dep in "${DEPENDENCY_CHECKS[@]}"; do
        if grep -q "$dep" "$CAMERA_AGENT_DIR/build.gradle.kts"; then
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
if [ -f "$CAMERA_AGENT_DIR/settings.gradle.kts" ]; then
    echo -e "${GREEN}✓ settings.gradle.kts file exists${NC}"
else
    echo -e "${YELLOW}⚠ settings.gradle.kts file not found${NC}"
fi

# Check for source directories
if [ -d "$CAMERA_AGENT_DIR/src/main/kotlin" ]; then
    echo -e "${GREEN}✓ Source directory exists${NC}"
    
    # Count Kotlin files
    KOTLIN_FILES=$(find "$CAMERA_AGENT_DIR/src/main/kotlin" -name "*.kt" | wc -l)
    echo -e "${GREEN}✓ Found $KOTLIN_FILES Kotlin source files${NC}"
else
    echo -e "${RED}✘ Source directory not found${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Camera Integration Component Check:${NC}"
echo "------------------------------"

# Check for critical camera components
COMPONENT_CHECKS=(
    "UsbManager"
    "CameraDevice"
    "CameraIntegrationAgent"
    "UsbDevice"
)

for component in "${COMPONENT_CHECKS[@]}"; do
    if find "$CAMERA_AGENT_DIR/src" -type f -name "*$component*.kt" | grep -q .; then
        echo -e "${GREEN}✓ Found camera component: $component${NC}"
    else
        echo -e "${YELLOW}⚠ Could not find camera component: $component${NC}"
    fi
done

# Check for USB mock implementations for testing
if find "$CAMERA_AGENT_DIR/src" -type f -name "Mock*.kt" | grep -q .; then
    echo -e "${GREEN}✓ Found mock implementations for testing${NC}"
    MOCK_FILES=$(find "$CAMERA_AGENT_DIR/src" -type f -name "Mock*.kt" | wc -l)
    echo -e "${GREEN}✓ $MOCK_FILES mock implementation files found${NC}"
else
    echo -e "${YELLOW}⚠ No mock implementations found for testing${NC}"
    echo "Mock implementations are recommended for testing without real hardware"
fi

# Check for resources directory and configuration files
if [ -d "$CAMERA_AGENT_DIR/src/main/resources" ]; then
    echo -e "${GREEN}✓ Resources directory exists${NC}"
    
    # Check for logback.xml
    if [ -f "$CAMERA_AGENT_DIR/src/main/resources/logback.xml" ]; then
        echo -e "${GREEN}✓ logback.xml configuration found${NC}"
    else
        echo -e "${YELLOW}⚠ logback.xml configuration not found${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Resources directory not found${NC}"
fi

echo -e "\n${YELLOW}Gradle Build Verification:${NC}"
echo "------------------------------"

# First make gradlew executable if it's not
chmod +x "$CAMERA_AGENT_DIR/gradlew" 2>/dev/null || true

# Check if we can build the project
echo "Attempting to build Camera Agent (this may take a moment)..."
if cd "$CAMERA_AGENT_DIR" && ./gradlew clean build -x test --console=plain --info 2>&1 | grep -q "BUILD SUCCESSFUL"; then
    echo -e "${GREEN}✓ Gradle build successful${NC}"
else
    echo -e "${RED}✘ Gradle build failed${NC}"
    echo "To see detailed build errors, run:"
    echo "cd $CAMERA_AGENT_DIR && ./gradlew clean build -x test --info"
    exit 1
fi

echo -e "\n${YELLOW}USB Subsystem Check:${NC}"
echo "------------------------------"

# Check if the USB libraries are available on the system
if ldconfig -p 2>/dev/null | grep -q "libusb"; then
    echo -e "${GREEN}✓ USB libraries found on system${NC}"
else
    echo -e "${YELLOW}⚠ USB libraries not found on system${NC}"
    echo "You may need to install libusb for hardware support:"
    echo "sudo apt-get install libusb-1.0-0 libusb-1.0-0-dev"
fi

# Check for USB device access
if [ -d "/dev/bus/usb" ]; then
    echo -e "${GREEN}✓ USB device directory exists${NC}"
    
    # Check if we have permissions to access USB devices
    if ls -la /dev/bus/usb/*/001 2>/dev/null >/dev/null; then
        echo -e "${GREEN}✓ USB devices are accessible${NC}"
    else
        echo -e "${YELLOW}⚠ USB devices may not be accessible due to permissions${NC}"
        echo "You may need to add your user to the plugdev group:"
        echo "sudo usermod -aG plugdev $USER"
    fi
else
    echo -e "${YELLOW}⚠ USB device directory not found${NC}"
    echo "Camera functionality may be limited without USB access"
fi

echo -e "\n${YELLOW}NATS Connectivity Check:${NC}"
echo "------------------------------"

# Check if NATS server is running
if nc -z localhost 4222 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ NATS server is reachable on port 4222${NC}"
    
    # Check for connectivity code in the codebase
    if grep -r "nats://" "$CAMERA_AGENT_DIR/src" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ NATS connection configuration found in code${NC}"
    else
        echo -e "${YELLOW}⚠ NATS connection configuration not found in code${NC}"
    fi
else
    echo -e "${RED}✘ NATS server is not reachable${NC}"
    echo "Please start NATS server before running Camera Agent:"
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

# Enable mock mode for testing without real hardware
echo "Setting MOCK_USB=true for testing without real hardware"
export MOCK_USB=true

# Try running the application with a timeout
echo "Attempting to start Camera Agent in mock mode (with 10s timeout for verification)..."
(cd "$CAMERA_AGENT_DIR" && timeout 10s ./gradlew run) > "$TEMP_LOG" 2>&1 &
RUN_PID=$!

# Wait a moment for startup
sleep 5

# Check if the process is still running
if ps -p $RUN_PID > /dev/null; then
    echo -e "${GREEN}✓ Camera Agent started successfully in mock mode${NC}"
    
    # Extract interesting log lines
    STARTUP_LOGS=$(grep -E "Starting|Connecting|Initialized|Ready|Listening|Camera|USB|Device" "$TEMP_LOG" || true)
    if [ -n "$STARTUP_LOGS" ]; then
        echo "Startup log highlights:"
        echo "$STARTUP_LOGS"
    fi
    
    # Check for mock devices
    MOCK_DEVICES=$(grep -E "MockUsbDevice|mock device|Simulated" "$TEMP_LOG" || true)
    if [ -n "$MOCK_DEVICES" ]; then
        echo -e "${GREEN}✓ Mock USB devices initialized${NC}"
    else
        echo -e "${YELLOW}⚠ Could not confirm mock USB device initialization${NC}"
    fi
    
    # Kill the process as we only needed it for verification
    kill $RUN_PID > /dev/null 2>&1 || true
    wait $RUN_PID 2>/dev/null || true
    echo -e "${GREEN}✓ Verification complete, stopped test instance${NC}"
else
    echo -e "${RED}✘ Camera Agent failed to start${NC}"
    echo "Error details:"
    grep -E "Error|Exception|Failed" "$TEMP_LOG" || cat "$TEMP_LOG"
fi

# Clean up
rm -f "$TEMP_LOG"

echo -e "\n${YELLOW}Verification Summary:${NC}"
echo "------------------------------"

# Provide summary and next steps
echo -e "${GREEN}✓ Camera Agent verification completed${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo "1. To run Camera Agent: cd $CAMERA_AGENT_DIR && ./gradlew run"
echo "2. For real hardware testing, remove the MOCK_USB=true setting"
echo "3. Make sure MCP Core is running before starting Camera Agent"
echo "4. To verify Python Processor: ./scripts/verify-python-processor.sh"
echo "5. To verify full system integration: ./scripts/verify-integration.sh"

exit 0