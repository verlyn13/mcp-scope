#!/bin/bash
set -e

# Set default environment variables if not provided
NATS_SERVER=${NATS_SERVER:-"nats://localhost:4222"}
MODEL_NAME=${MODEL_NAME:-"Qwen/Qwen2.5-Coder-32B-Instruct"}
HEARTBEAT_INTERVAL=${HEARTBEAT_INTERVAL:-30}
API_HOST=${API_HOST:-"0.0.0.0"}
API_PORT=${API_PORT:-8080}

echo "Starting Python Bridge Agent with the following configuration:"
echo "NATS_SERVER: $NATS_SERVER"
echo "MODEL_NAME: $MODEL_NAME"
echo "HEARTBEAT_INTERVAL: $HEARTBEAT_INTERVAL"
echo "API_HOST: $API_HOST"
echo "API_PORT: $API_PORT"

# Create config.yaml file from environment variables
cat > /app/config.yaml << EOL
# Python Bridge Agent Configuration

# Agent identification
agent_id: null  # Set to null to auto-generate

# Logging level (DEBUG, INFO, WARNING, ERROR)
log_level: "INFO"

# NATS Messaging Configuration
nats:
  server_url: "${NATS_SERVER}"
  reconnect_attempts: 10
  reconnect_timeout: 1.0
  max_reconnect_timeout: 15.0

# Health Monitoring
health:
  check_interval: ${HEARTBEAT_INTERVAL}
  metrics_enabled: true

# API Service
api:
  enabled: true
  host: "${API_HOST}"
  port: ${API_PORT}

# AI Model Configuration
model:
  model_id: "${MODEL_NAME}"
  use_local_model: false
  local_model_path: null
  model_kwargs:
    temperature: 0.2
    max_tokens: 4096
    top_p: 0.95

# Agent capabilities
capabilities:
  - "code-generation"
  - "documentation-generation"
  - "uvc-analysis"
EOL

# Ensure directories exist
mkdir -p /app/logs

# Run the agent
exec python -m python_bridge.main