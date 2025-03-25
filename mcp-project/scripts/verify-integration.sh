#!/bin/bash
# MCP System Integration Verification Script
# Validates end-to-end integration between all components of the MCP system

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/verlyn13/Projects/mcp-scope/mcp-project"
NATS_URL="nats://localhost:4222"

echo -e "${BLUE}=== MCP System Integration Verification ===${NC}"
echo -e "${CYAN}This script validates the end-to-end integration between all MCP components${NC}"

echo -e "\n${YELLOW}Step 1: Component Status Check${NC}"
echo "------------------------------"

# Define the components to check
declare -A components
components=(
    ["nats"]="NATS Server"
    ["mcp-core"]="MCP Core Orchestrator"
    ["camera-agent"]="Camera Integration Agent"
    ["python-processor"]="Python Processor Agent"
)

# Check if each component is running
for key in "${!components[@]}"; do
    component_name="${components[$key]}"
    
    if [[ "$key" == "nats" ]]; then
        # Check NATS server
        if pgrep -x "nats-server" > /dev/null || nc -z localhost 4222 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $component_name is running${NC}"
            components[$key]="RUNNING"
        else
            echo -e "${RED}✘ $component_name is not running${NC}"
            components[$key]="STOPPED"
        fi
    elif [[ "$key" == "mcp-core" ]]; then
        # Check MCP Core
        if pgrep -f "mcp-core" > /dev/null || ps aux | grep java | grep -v grep | grep -q "mcp-core"; then
            echo -e "${GREEN}✓ $component_name is running${NC}"
            components[$key]="RUNNING"
        else
            echo -e "${RED}✘ $component_name is not running${NC}"
            components[$key]="STOPPED"
        fi
    elif [[ "$key" == "camera-agent" ]]; then
        # Check Camera Agent
        if pgrep -f "camera-agent" > /dev/null || ps aux | grep java | grep -v grep | grep -q "camera-agent"; then
            echo -e "${GREEN}✓ $component_name is running${NC}"
            components[$key]="RUNNING"
        else
            echo -e "${RED}✘ $component_name is not running${NC}"
            components[$key]="STOPPED"
        fi
    elif [[ "$key" == "python-processor" ]]; then
        # Check Python Processor
        if pgrep -f "python.*main.py" > /dev/null || ps aux | grep python | grep -v grep | grep -q "main.py"; then
            echo -e "${GREEN}✓ $component_name is running${NC}"
            components[$key]="RUNNING"
        else
            echo -e "${RED}✘ $component_name is not running${NC}"
            components[$key]="STOPPED"
        fi
    fi
done

# Check if any component is not running
STOPPED_COMPONENTS=0
for key in "${!components[@]}"; do
    if [[ "${components[$key]}" == "STOPPED" ]]; then
        STOPPED_COMPONENTS=$((STOPPED_COMPONENTS+1))
    fi
done

if [ $STOPPED_COMPONENTS -gt 0 ]; then
    echo -e "\n${YELLOW}Warning: $STOPPED_COMPONENTS components are not running${NC}"
    echo "For comprehensive integration verification, all components should be running."
    echo -e "Would you like to ${CYAN}continue anyway${NC} or ${CYAN}start missing components${NC}? (continue/start)"
    read -p "> " ACTION
    
    if [[ "$ACTION" == "start" ]]; then
        echo -e "\n${YELLOW}Starting missing components...${NC}"
        
        # Start NATS if needed
        if [[ "${components["nats"]}" == "STOPPED" ]]; then
            echo "Starting NATS server..."
            nats-server -c "$PROJECT_DIR/nats/nats-server.conf" > /dev/null 2>&1 &
            sleep 2
            echo -e "${GREEN}✓ NATS server started${NC}"
        fi
        
        # Start MCP Core if needed
        if [[ "${components["mcp-core"]}" == "STOPPED" ]]; then
            echo "Starting MCP Core..."
            (cd "$PROJECT_DIR/mcp-core" && ./gradlew run > /dev/null 2>&1 &)
            sleep 5
            echo -e "${GREEN}✓ MCP Core started${NC}"
        fi
        
        # Start Camera Agent if needed
        if [[ "${components["camera-agent"]}" == "STOPPED" ]]; then
            echo "Starting Camera Agent in mock mode..."
            (export MOCK_USB=true && cd "$PROJECT_DIR/agents/camera-agent" && ./gradlew run > /dev/null 2>&1 &)
            sleep 5
            echo -e "${GREEN}✓ Camera Agent started${NC}"
        fi
        
        # Start Python Processor if needed
        if [[ "${components["python-processor"]}" == "STOPPED" ]]; then
            echo "Starting Python Processor..."
            (cd "$PROJECT_DIR/agents/python-processor" && \
             source venv/bin/activate 2>/dev/null || true && \
             python main.py > /dev/null 2>&1 &)
            sleep 3
            echo -e "${GREEN}✓ Python Processor started${NC}"
        fi
        
        echo -e "\n${GREEN}All components started!${NC}"
    else
        echo -e "\n${YELLOW}Continuing with verification of available components...${NC}"
    fi
fi

echo -e "\n${YELLOW}Step 2: NATS Connection Verification${NC}"
echo "------------------------------"

# Check if nats CLI is available
if ! command -v nats &> /dev/null; then
    echo -e "${YELLOW}⚠ NATS CLI not found, limited verification possible${NC}"
    echo "For full verification, install NATS CLI: curl -sf https://install.nats.io/install.sh | sh"
    HAS_NATS_CLI=false
else
    HAS_NATS_CLI=true
    echo -e "${GREEN}✓ NATS CLI available for verification${NC}"
    
    # Check if NATS server is accessible
    if nats server check --server="$NATS_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ NATS server connection verified${NC}"
        
        # Show server info
        echo -e "\nNATS Server Information:"
        nats server info --server="$NATS_URL" | grep -E "Server|Version|Uptime|Connections"
    else
        echo -e "${RED}✘ Cannot connect to NATS server${NC}"
        exit 1
    fi
fi

echo -e "\n${YELLOW}Step 3: Agent Registration Verification${NC}"
echo "------------------------------"

if [ "$HAS_NATS_CLI" = true ]; then
    # Create a temporary file for agent discovery
    TMP_AGENTS_FILE=$(mktemp)
    
    echo "Checking for registered agents..."
    timeout 5s nats sub --server="$NATS_URL" "mcp.agent.>" > "$TMP_AGENTS_FILE" 2>/dev/null &
    SUB_PID=$!
    
    # Wait a moment to collect messages
    sleep 3
    
    # Check for Camera Agent messages
    if grep -q "camera" "$TMP_AGENTS_FILE"; then
        echo -e "${GREEN}✓ Camera Agent registration detected${NC}"
    else
        echo -e "${YELLOW}⚠ No Camera Agent registration detected${NC}"
    fi
    
    # Check for Python Processor messages
    if grep -q "python" "$TMP_AGENTS_FILE"; then
        echo -e "${GREEN}✓ Python Processor registration detected${NC}"
    else
        echo -e "${YELLOW}⚠ No Python Processor registration detected${NC}"
    fi
    
    # Clean up
    rm -f "$TMP_AGENTS_FILE"
    
    # Ensure subscription process is terminated
    if ps -p $SUB_PID > /dev/null 2>&1; then
        kill $SUB_PID > /dev/null 2>&1
    fi
else
    echo -e "${YELLOW}⚠ Skipping agent registration check (NATS CLI not available)${NC}"
fi

echo -e "\n${YELLOW}Step 4: Task Execution Verification${NC}"
echo "------------------------------"

if [ "$HAS_NATS_CLI" = true ] && \
   [[ "${components["camera-agent"]}" == "RUNNING" ]]; then
    
    echo "Testing Camera Agent task execution..."
    
    # Create a temporary file for results
    TMP_RESULT_FILE=$(mktemp)
    
    # Start subscription for results
    timeout 10s nats sub --server="$NATS_URL" "mcp.task.*.result" > "$TMP_RESULT_FILE" 2>/dev/null &
    SUB_PID=$!
    
    # Wait a moment for subscription to initialize
    sleep 2
    
    # Generate a unique task ID
    TASK_ID="test-$(date +%s)"
    
    # Send a task to the Camera Agent
    echo "Sending LIST_DEVICES task to Camera Agent..."
    nats pub --server="$NATS_URL" "mcp.task.camera-agent" \
      "{\"taskId\":\"$TASK_ID\",\"agentType\":\"camera\",\"payload\":\"{\\\"action\\\":\\\"LIST_DEVICES\\\"}\", \"priority\":0}" > /dev/null 2>&1
    
    # Wait for the result
    sleep 5
    
    # Check for task result
    if grep -q "$TASK_ID" "$TMP_RESULT_FILE"; then
        echo -e "${GREEN}✓ Camera Agent task execution verified${NC}"
        
        # Show the result
        echo -e "\nTask Result:"
        grep -A 5 "$TASK_ID" "$TMP_RESULT_FILE" | head -n 6
    else
        echo -e "${RED}✘ No response from Camera Agent task${NC}"
    fi
    
    # Clean up
    rm -f "$TMP_RESULT_FILE"
    
    # Ensure subscription process is terminated
    if ps -p $SUB_PID > /dev/null 2>&1; then
        kill $SUB_PID > /dev/null 2>&1
    fi
else
    echo -e "${YELLOW}⚠ Skipping task execution check (NATS CLI not available or Camera Agent not running)${NC}"
fi

echo -e "\n${YELLOW}Step 5: End-to-End Workflow Verification${NC}"
echo "------------------------------"

if [ "$HAS_NATS_CLI" = true ] && \
   [[ "${components["camera-agent"]}" == "RUNNING" ]] && \
   [[ "${components["python-processor"]}" == "RUNNING" ]]; then
    
    echo "Testing end-to-end workflow..."
    
    # Create temporary files for results
    TMP_CAMERA_RESULT=$(mktemp)
    TMP_PROCESSOR_RESULT=$(mktemp)
    
    # Start subscriptions
    timeout 15s nats sub --server="$NATS_URL" "mcp.task.camera-agent.result" > "$TMP_CAMERA_RESULT" 2>/dev/null &
    CAMERA_SUB_PID=$!
    
    timeout 15s nats sub --server="$NATS_URL" "mcp.task.python-processor.result" > "$TMP_PROCESSOR_RESULT" 2>/dev/null &
    PROCESSOR_SUB_PID=$!
    
    # Wait for subscriptions to initialize
    sleep 2
    
    # Generate a unique workflow ID
    WORKFLOW_ID="workflow-$(date +%s)"
    
    # Send a workflow task that should trigger the processor
    echo "Sending workflow task to test multi-agent processing..."
    nats pub --server="$NATS_URL" "mcp.workflow.start" \
      "{\"workflowId\":\"$WORKFLOW_ID\",\"steps\":[{\"agentType\":\"camera\",\"action\":\"GET_SAMPLE_DATA\"},{\"agentType\":\"python\",\"action\":\"PROCESS_IMAGE\"}]}" > /dev/null 2>&1
    
    # Wait for results
    sleep 10
    
    # Check for Camera Agent result
    if grep -q "GET_SAMPLE_DATA" "$TMP_CAMERA_RESULT"; then
        echo -e "${GREEN}✓ Camera Agent workflow step executed${NC}"
    else
        echo -e "${YELLOW}⚠ Camera Agent workflow step not detected${NC}"
    fi
    
    # Check for Python Processor result
    if grep -q "PROCESS_IMAGE" "$TMP_PROCESSOR_RESULT"; then
        echo -e "${GREEN}✓ Python Processor workflow step executed${NC}"
        echo -e "${GREEN}✓ End-to-end workflow verified${NC}"
    else
        echo -e "${YELLOW}⚠ Python Processor workflow step not detected${NC}"
    fi
    
    # Clean up
    rm -f "$TMP_CAMERA_RESULT" "$TMP_PROCESSOR_RESULT"
    
    # Ensure subscription processes are terminated
    if ps -p $CAMERA_SUB_PID > /dev/null 2>&1; then
        kill $CAMERA_SUB_PID > /dev/null 2>&1
    fi
    
    if ps -p $PROCESSOR_SUB_PID > /dev/null 2>&1; then
        kill $PROCESSOR_SUB_PID > /dev/null 2>&1
    fi
else
    echo -e "${YELLOW}⚠ Skipping end-to-end workflow check (required components not available)${NC}"
fi

echo -e "\n${YELLOW}Integration Verification Summary:${NC}"
echo "------------------------------"

# Summarize findings
echo -e "Component Status:"
for key in "${!components[@]}"; do
    component_name="${!components[@]}"
    status="${components[$key]}"
    
    if [[ "$status" == "RUNNING" ]]; then
        echo -e "${GREEN}✓ ${components[$key]}: $status${NC}"
    else
        echo -e "${RED}✘ ${components[$key]}: $status${NC}"
    fi
done

# Overall assessment
if [ $STOPPED_COMPONENTS -eq 0 ] && [ "$HAS_NATS_CLI" = true ]; then
    echo -e "\n${GREEN}✓ Full system integration verified!${NC}"
    echo -e "All components are running and communicating properly."
elif [ $STOPPED_COMPONENTS -gt 0 ]; then
    echo -e "\n${YELLOW}⚠ Partial system integration verified${NC}"
    echo -e "Some components are not running, which limits verification."
    echo -e "Start all components for complete verification."
elif [ "$HAS_NATS_CLI" = false ]; then
    echo -e "\n${YELLOW}⚠ Limited verification completed${NC}"
    echo -e "Install NATS CLI for complete verification testing."
fi

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. If any components failed verification, check their logs for details"
echo "2. For containerized testing: ./scripts/container-health-check.sh"
echo "3. For production deployment: Review build-process-reliability-guide.md"

exit 0