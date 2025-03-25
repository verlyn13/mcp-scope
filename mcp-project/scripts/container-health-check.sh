#!/bin/bash
# MCP Container Health Check Script
# Verifies the health of all containers in the MCP environment

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== MCP Container Health Check ==="
echo "Verifying container status and health..."

# Get list of running containers
CONTAINERS=$(podman ps --format "{{.Names}}" | grep -E 'mcp|nats|camera|python')

if [ -z "$CONTAINERS" ]; then
    echo -e "${RED}No MCP containers running! Run podman-compose up -d first.${NC}"
    exit 1
fi

FAILED=0
DEGRADED=0
HEALTHY=0

# Check each container
echo -e "\n${YELLOW}Individual Container Status:${NC}"
echo "------------------------------"

check_container() {
    local container=$1
    local status=$(podman inspect --format "{{.State.Status}}" "$container" 2>/dev/null)
    
    if [ "$status" != "running" ]; then
        echo -e "${RED}✘ $container is not running (Status: $status)${NC}"
        echo "  → Container logs:"
        podman logs --tail 10 "$container"
        FAILED=$((FAILED+1))
        return 1
    else
        # Advanced health check based on container type
        if [[ $container == *"nats"* ]]; then
            # Check NATS health
            if podman exec "$container" sh -c "curl -s http://localhost:8222/varz" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ $container is healthy${NC}"
                HEALTHY=$((HEALTHY+1))
            else
                echo -e "${YELLOW}⚠ $container is running but health check failed${NC}"
                DEGRADED=$((DEGRADED+1))
            fi
        elif [[ $container == *"mcp-core"* ]]; then
            # Check MCP Core health
            if podman exec "$container" sh -c "ps aux | grep -v grep | grep -q java"; then
                echo -e "${GREEN}✓ $container is healthy${NC}"
                HEALTHY=$((HEALTHY+1))
            else
                echo -e "${YELLOW}⚠ $container is running but Java process not found${NC}"
                DEGRADED=$((DEGRADED+1))
            fi
        elif [[ $container == *"camera-agent"* ]]; then
            # Check Camera Agent health
            if podman exec "$container" sh -c "ps aux | grep -v grep | grep -q java"; then
                echo -e "${GREEN}✓ $container is healthy${NC}"
                HEALTHY=$((HEALTHY+1))
            else
                echo -e "${YELLOW}⚠ $container is running but Java process not found${NC}"
                DEGRADED=$((DEGRADED+1))
            fi
        elif [[ $container == *"python"* ]]; then
            # Check Python Agent health
            if podman exec "$container" sh -c "ps aux | grep -v grep | grep -q python"; then
                echo -e "${GREEN}✓ $container is healthy${NC}"
                HEALTHY=$((HEALTHY+1))
            else
                echo -e "${YELLOW}⚠ $container is running but Python process not found${NC}"
                DEGRADED=$((DEGRADED+1))
            fi
        else
            echo -e "${GREEN}✓ $container is running${NC} (basic check only)"
            HEALTHY=$((HEALTHY+1))
        fi
    fi
}

# Check each container's health
for container in $CONTAINERS; do
    check_container "$container"
done

# Check network connectivity between containers
echo -e "\n${YELLOW}Inter-Container Connectivity:${NC}"
echo "------------------------------"

# Test if MCP Core can reach NATS
if echo "$CONTAINERS" | grep -q "mcp-core"; then
    if podman exec mcp-core sh -c "nc -z nats 4222" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ MCP Core → NATS connectivity verified${NC}"
    else
        echo -e "${RED}✘ MCP Core cannot connect to NATS${NC}"
        DEGRADED=$((DEGRADED+1))
    fi
fi

# Test if Camera Agent can reach NATS
if echo "$CONTAINERS" | grep -q "camera-agent"; then
    if podman exec camera-agent sh -c "nc -z nats 4222" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Camera Agent → NATS connectivity verified${NC}"
    else
        echo -e "${RED}✘ Camera Agent cannot connect to NATS${NC}"
        DEGRADED=$((DEGRADED+1))
    fi
fi

# Test if Python Processor can reach NATS
if echo "$CONTAINERS" | grep -q "python-processor"; then
    if podman exec python-processor sh -c "nc -z nats 4222" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Python Processor → NATS connectivity verified${NC}"
    else
        echo -e "${RED}✘ Python Processor cannot connect to NATS${NC}"
        DEGRADED=$((DEGRADED+1))
    fi
fi

# Resource usage check
echo -e "\n${YELLOW}Container Resource Usage:${NC}"
echo "------------------------------"
podman stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E 'mcp|nats|camera|python'

# Summary
echo -e "\n${YELLOW}Health Check Summary:${NC}"
echo "------------------------------"
echo -e "Healthy: ${GREEN}$HEALTHY${NC}"
echo -e "Degraded: ${YELLOW}$DEGRADED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ $FAILED -gt 0 ]; then
    echo -e "\n${RED}Critical issues detected!${NC} Some containers have failed."
    echo "Run 'podman logs <container-name>' for detailed logs."
    exit 1
elif [ $DEGRADED -gt 0 ]; then
    echo -e "\n${YELLOW}System is degraded.${NC} Some components have issues but are running."
    echo "Check individual container logs for more information."
    exit 2
else
    echo -e "\n${GREEN}All systems operational!${NC} The MCP container environment is healthy."
    exit 0
fi