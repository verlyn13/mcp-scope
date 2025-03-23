---
title: "MCP Local Development Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/README.md"
  - "/docs/project/first-steps.md"
  - "/docs/implementation/project-setup.md"
  - "/docs/implementation/containerized-development-guide.md"
tags: ["development", "local", "workflow", "gradle", "python"]
---

# MCP Local Development Guide

🟢 **Active**

[↩️ Back to Documentation Index](/docs/README.md)

## Overview

This guide provides instructions for setting up and working with the Multi-Agent Control Platform (MCP) in a local development environment.

## Prerequisites

Before following this guide, ensure you have completed the [Project Setup](/docs/implementation/project-setup.md) to install required software.

## Setting Up Your Local Environment

### Gradle Wrapper Setup for Kotlin Projects

To ensure consistent builds across developer machines, we use Gradle wrapper. If you're creating a new Kotlin component or the wrapper is missing, set it up:

```bash
# Navigate to the project directory (mcp-core or camera-agent)
cd /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core

# Generate the Gradle wrapper
gradle wrapper --gradle-version 8.3
chmod +x ./gradlew
```

This creates:
- `gradlew` - Unix shell script
- `gradlew.bat` - Windows batch file
- `gradle/wrapper/` directory with JAR and properties files

### Python Virtual Environment Setup

For Python agents, set up isolated virtual environments:

```bash
# Navigate to the Python agent directory
cd /home/verlyn13/Projects/mcp-scope/mcp-project/agents/python-processor

# Create a virtual environment
python -m venv venv

# Activate the virtual environment (Linux/macOS)
source venv/bin/activate

# Activate the virtual environment (Windows PowerShell)
# .\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

### Environment Variables for Local Development

Create a `.env` file in each component directory for local settings. These values will override container environments when running locally:

**For mcp-core and camera-agent (`.env` file)**:
```
NATS_URL=nats://localhost:4222
LOG_LEVEL=INFO
```

**For Python agent (`.env` file)**:
```
NATS_URL=nats://localhost:4222
LOG_LEVEL=INFO
```

## Running Components Locally

### 1. Start NATS Server

First, start the NATS message broker:

```bash
# Start NATS with the project configuration
nats-server -c /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf
```

### 2. Run MCP Core

In a new terminal:

```bash
cd /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core
./gradlew run
```

### 3. Run Camera Integration Agent

In another terminal:

```bash
cd /home/verlyn13/Projects/mcp-scope/mcp-project/agents/camera-agent
./gradlew run
```

### 4. Run Python Processor Agent

In yet another terminal:

```bash
cd /home/verlyn13/Projects/mcp-scope/mcp-project/agents/python-processor
source venv/bin/activate
python main.py
```

## Local Development Workflow

Follow these steps for an efficient development process:

1. **Make code changes** to the component you're working on
2. **Rebuild and restart** just that component:
   - For Kotlin components: `./gradlew run` (restarts automatically)
   - For Python agent: Stop with Ctrl+C and restart with `python main.py`
3. **Test your changes** using logs and UI interactions
4. **When ready to integrate**, test with all components running

## Working with Multiple Components

Strategies for effective local development with multiple components:

### Using Terminal Multiplexers

[tmux](https://github.com/tmux/tmux/wiki) or [screen](https://www.gnu.org/software/screen/) let you manage multiple terminal sessions:

```bash
# Start a new tmux session
tmux new -s mcp

# Create multiple panes (Ctrl+b then ")
# Switch between panes (Ctrl+b then arrow keys)
```

### Using IDE Run Configurations

Configure your IDE to run multiple components:

**IntelliJ IDEA / Android Studio**:
1. Create Gradle run configurations for Kotlin components
2. Create Python run configurations for Python agents
3. Use the "Compound" configuration to start multiple components

**VS Code**:
1. Create launch configurations in `.vscode/launch.json`
2. Use the "compounds" section to define multi-component launches

## Debugging

### Debugging Kotlin Components

1. In IntelliJ or VS Code, start the component in debug mode
2. Set breakpoints in the code
3. Trigger actions via NATS messages or UI interactions

Example VS Code launch configuration:

```json
{
  "type": "kotlin",
  "request": "launch",
  "name": "MCP Core",
  "projectRoot": "${workspaceFolder}/mcp-core",
  "mainClass": "com.example.mcp.MainKt"
}
```

### Debugging Python Agents

1. Set breakpoints in the Python code
2. Start the agent with debugging enabled:
   ```bash
   python -m debugpy --listen 5678 --wait-for-client main.py
   ```
3. Attach your IDE to port 5678

## Testing NATS Interactions Manually

Use the NATS CLI to publish messages and test your components:

```bash
# Install NATS CLI
curl -sf https://install.nats.io/install.sh | sh

# Subscribe to task results
nats sub "mcp.task.*.result"

# Publish a test task (from another terminal)
nats pub "mcp.task.camera-integration-agent" '{"taskId":"test-123","agentType":"camera","payload":"{\"action\":\"LIST_DEVICES\"}", "priority":0}'
```

## Best Practices for Local Development

1. **Use consistent environment variables** between local and containerized setups
2. **Commit Gradle wrapper files** to source control for consistent builds
3. **Don't commit virtual environments** (they're in `.gitignore`)
4. **Document any changes** to dependencies in README files
5. **Test both locally and in containers** before submitting pull requests
6. **Use feature flags** for in-development features to avoid breaking other components

## Troubleshooting Common Issues

### NATS Connection Issues

If components can't connect to NATS:

```bash
# Check if NATS is running
ps aux | grep nats-server

# Verify NATS is listening on the expected port
netstat -tuln | grep 4222
```

### Gradle Build Failures

For Kotlin component build issues:

```bash
# Clean build files
./gradlew clean

# Try with --info for more details
./gradlew build --info
```

### Python Dependency Issues

For Python agent dependency problems:

```bash
# Recreate the virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Agent Registration Problems

If agents aren't registering with the orchestrator:

1. Check NATS connectivity
2. Verify agent IDs are unique
3. Make sure environment variables are set correctly
4. Check logs for serialization/deserialization errors

## Related Documents

- [Project Setup](/docs/implementation/project-setup.md)
- [First Steps Guide](/docs/project/first-steps.md)
- [Containerized Development Guide](/docs/implementation/containerized-development-guide.md)

## Changelog

- 1.0.0 (2025-03-22): Initial release