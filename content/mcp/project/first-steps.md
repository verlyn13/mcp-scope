---
title: "Getting Started with MCP"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/README.md"
  - "/docs/implementation/project-setup.md"
  - "/docs/implementation/core-framework.md"
  - "/docs/architecture/overview.md"
tags: ["getting-started", "quick-start", "onboarding"]
---

# Getting Started with MCP

🟢 **Active**

[↩️ Back to Documentation Index](/docs/README.md)

## Overview

Welcome to the Multi-Agent Control Platform (MCP) project! This guide will help you set up your development environment and understand the project structure so you can start contributing quickly.

## Prerequisites

- JDK 17 or later for Kotlin components
- Python 3.11 or later for Python agents
- Gradle 8.0+ for building JVM components (or use the wrapper)
- NATS Server for local message transport
- Podman or Docker (optional, for containerized development)

## What is MCP?

MCP is a distributed system that orchestrates multiple specialized agents to perform coordinated tasks. The platform uses a message-based architecture with NATS as the communication backbone, allowing agents written in different languages to work together seamlessly.

## System Architecture Overview

```
┌────────────────┐
│                │
│    Client      │
│    Application │
│                │
└───────┬────────┘
         │
         ▼
┌────────────────┐      ┌───────────────┐
│                │      │               │
│  Orchestrator  │◄────►│  NATS Broker  │
│                │      │               │
└───────┬────────┘      └───────▲───────┘
         │                      │
         ▼                      │
┌────────────────┐              │
│                │              │
│   Agent FSM    │              │
│   Framework    │              │
│                │              │
└───────┬────────┘              │
         │                      │
┌────────▼────────┬─────────────┴───┬────────────────┐
│                 │                 │                │
│  Camera Agent   │  Python Agent   │  Other Agents  │
│  (Kotlin/JVM)   │  (Python)       │  (Any Lang)    │
│                 │                 │                │
└─────────────────┴─────────────────┴────────────────┘
```

Key components:
- **Orchestrator**: Central coordination unit managing agent lifecycles
- **NATS**: High-performance message broker for communication
- **Agent Framework**: Common interface and state machine for all agents
- **Specialized Agents**: Task-specific components (camera integration, data processing, etc.)

## Project Structure

The MCP project is organized into the following components:

```
mcp-project/
├── mcp-core/                 # Core orchestration platform (Kotlin)
│   ├── src/
│   │   └── main/kotlin/com/example/
│   │       ├── mcp/           # Core platform code
│   │       └── agents/        # Agent interfaces
│   ├── build.gradle.kts       # Gradle build configuration
│   └── Dockerfile.dev         # Development container config
│
├── agents/
│   ├── camera-agent/          # Camera integration agent (Kotlin)
│   │   ├── src/
│   │   └── build.gradle.kts
│   │
│   └── python-processor/      # Data processing agent (Python)
│       ├── main.py            # Agent implementation
│       └── requirements.txt   # Python dependencies
│
├── nats/                      # NATS configuration
│   └── nats-server.conf       # NATS server configuration
│
├── docs/                      # Documentation
│   ├── project/               # Project information
│   ├── architecture/          # Architecture design
│   ├── implementation/        # Implementation guides
│   └── standards/             # Project standards
│
├── podman-compose.yml         # Container orchestration
└── settings.gradle.kts        # Gradle project settings
```

## Quick Start

### Option 1: Local Development Setup

For the fastest way to get started with local development:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/example/mcp-project.git
   cd mcp-project
   ```

2. **Set up JVM components**:
   ```bash
   # Navigate to mcp-core
   cd mcp-core
   # Build the project (this will download dependencies)
   ./gradlew build
   ```

3. **Set up Python agent**:
   ```bash
   # Navigate to the Python agent directory
   cd ../agents/python-processor
   # Create and activate virtual environment
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   # Install dependencies
   pip install -r requirements.txt
   ```

4. **Start NATS server**:
   ```bash
   # In a new terminal
   nats-server -c nats/nats-server.conf
   ```

5. **Run the core orchestrator**:
   ```bash
   # In a new terminal, from the mcp-core directory
   ./gradlew run
   ```

For detailed instructions on local development, see the [Local Development Guide](/docs/implementation/local-development-guide.md).

### Option 2: Containerized Development Setup

If you prefer to use containers for development:

1. **Clone the repository**:
   ```bash
   git clone https://github.com/example/mcp-project.git
   cd mcp-project
   ```

2. **Build and start the containers**:
   ```bash
   podman-compose up -d
   ```

3. **View the logs**:
   ```bash
   podman-compose logs -f
   ```

For detailed instructions on containerized development, see the [Containerized Development Guide](/docs/implementation/containerized-development-guide.md).

## Development Environments

MCP supports two primary development workflows:

### Local Development (Recommended for daily work)

Advantages:
- Faster iteration cycles
- Easier debugging
- Direct access to local tools

Setup and workflow instructions are provided in the [Local Development Guide](/docs/implementation/local-development-guide.md).

### Containerized Development

Advantages:
- Consistent environment across all machines
- Isolated dependencies
- Closer to production environment

Setup and workflow instructions are provided in the [Containerized Development Guide](/docs/implementation/containerized-development-guide.md).

## Core Concepts

### 1. Agent Lifecycle

Agents follow a state machine with these primary states:
- **Idle**: Agent initialized but not processing
- **Initializing**: Agent setting up resources
- **Processing**: Agent actively working on tasks
- **Error**: Agent encountered an issue
- **ShuttingDown**: Agent cleaning up resources

### 2. Task Processing

Tasks are distributed from the orchestrator to agents via NATS:
1. Client submits a task to the orchestrator
2. Orchestrator identifies appropriate agent based on capabilities
3. Agent receives task via NATS subscription
4. Agent processes task and returns result
5. Result is published back to the orchestrator

### 3. NATS Communication Patterns

The system uses several NATS communication patterns:
- **Request-Reply**: For direct queries requiring a response
- **Pub-Sub**: For broadcasting events and status updates
- **Queue Groups**: For distributing tasks among similar agents

## Working with the Code

### MCP Core

The core orchestrator manages agent registration, task distribution, and system health monitoring. Key files:

- `Orchestrator.kt`: Central coordination component
- `AgentStateMachine.kt`: State machine for agent lifecycle
- `NatsConnectionManager.kt`: NATS messaging integration

### Camera Integration Agent

The camera agent provides USB camera detection and operation capabilities:

- `CameraIntegrationAgent.kt`: Main agent implementation
- `MockUsbManager.kt`: Mock implementation of USB device management
- `CameraAgentMain.kt`: Entry point for the camera agent

### Python Processor Agent

The Python agent demonstrates integration with Python-based services:

- `main.py`: Agent implementation and entry point
- `requirements.txt`: Python dependencies

## Common Development Tasks

### Creating a New Agent

1. Create a directory structure for your agent
2. Implement the `McpAgent` interface
3. Set up appropriate NATS subscriptions
4. Register with the orchestrator

### Extending the Platform

1. Identify the component to extend
2. Make your changes with appropriate tests
3. Update documentation if necessary
4. Test in both local and containerized environments

### Debugging Tips

- Use Kotlin Debug with breakpoints for JVM components
- For Python, use `debugpy` or IDE-based Python debugging
- Monitor NATS messages using `nats sub "mcp.task.>"`
- Check logs for each component

## Frequently Asked Questions

**Q: How do I add a new dependency?**
A: For Kotlin components, add dependencies to the appropriate `build.gradle.kts` file. For Python, add them to `requirements.txt` and update the virtual environment.

**Q: How do agents discover and register with the orchestrator?**
A: Agents publish their information to the `mcp.agent.register` NATS topic. The orchestrator subscribes to this topic and maintains an agent registry.

**Q: Can I develop and test a single component in isolation?**
A: Yes! You can run just the NATS server and the component you're working on. Mock any required interactions with other components.

## Next Steps

Now that you're set up, you might want to:

1. **Explore the code**: Understand how the different components interact
2. **Run the system**: Start all components and observe their interactions
3. **Make a small change**: Try implementing a new feature or fixing a bug
4. **Create a new agent**: Implement a new specialized agent for the platform

## Related Documents

- [Environment Setup](/docs/implementation/project-setup.md)
- [Local Development Guide](/docs/implementation/local-development-guide.md)
- [Containerized Development Guide](/docs/implementation/containerized-development-guide.md)
- [Architecture Overview](/docs/architecture/overview.md)

## Troubleshooting

See the environment-specific guides for troubleshooting information:
- [Local Development Guide](/docs/implementation/local-development-guide.md#troubleshooting-common-issues)
- [Containerized Development Guide](/docs/implementation/containerized-development-guide.md#troubleshooting-container-issues)

## Changelog

- 1.0.0 (2025-03-22): Initial release