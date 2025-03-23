---
title: "MCP Project Setup Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
related_docs:
  - "/guides/containerized-dev-environment/"
  - "/mcp/docs/environment-setup/"
  - "/guides/build-engineer-implementation-guide/"
  - "/guides/build-engineer-quick-start/"
tags: ["project", "setup", "structure", "gradle", "architecture"]
---

# MCP Project Setup Guide

{{< status >}}

This guide provides detailed information about the Multi-Agent Control Platform (MCP) project structure, components, and initial setup.

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
│   ├── environment-setup.md   # Environment setup guide
│   ├── local-development-guide.md  # Local development guide
│   └── containerized-development-guide.md  # Container guide
│
├── podman-compose.yml         # Container orchestration
└── settings.gradle.kts        # Gradle project settings
```

## Initial Setup

### Prerequisites

Before beginning, ensure you have completed the [Environment Setup](/mcp/docs/environment-setup/) and have the following installed:

- **JDK 17 or later** for Kotlin components
- **Python 3.11 or later** for Python agents
- **Gradle 8.0+** for building JVM components
- **NATS Server** for local message transport
- **Podman** or **Docker** (optional, for containerized development)

### Setting Up the Project

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

## Implementation Progress

| Component | Status | Completion |
|-----------|--------|------------|
| Project Structure | 🟢 Active | {{< progress value="100" >}} |
| Core Components | 🟢 Active | {{< progress value="90" >}} |
| Camera Agent | 🟢 Active | {{< progress value="85" >}} |
| Python Agent | 🟢 Active | {{< progress value="80" >}} |
| NATS Configuration | 🟢 Active | {{< progress value="100" >}} |
| Documentation | 🟢 Active | {{< progress value="75" >}} |

## Running the System

Once the setup is complete, you can run the system with the following steps:

1. **Start NATS server**:
   ```bash
   # In a new terminal
   nats-server -c nats/nats-server.conf
   ```

2. **Run the core orchestrator**:
   ```bash
   # In a new terminal, from the mcp-core directory
   ./gradlew run
   ```

3. **Run the camera agent**:
   ```bash
   # In a new terminal, from the agents/camera-agent directory
   ./gradlew run
   ```

4. **Run the Python agent**:
   ```bash
   # In a new terminal, from the agents/python-processor directory
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   python main.py
   ```

## Core Components Overview

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

## Agent Lifecycle

Agents follow a state machine with these primary states:
- **Idle**: Agent initialized but not processing
- **Initializing**: Agent setting up resources
- **Processing**: Agent actively working on tasks
- **Error**: Agent encountered an issue
- **ShuttingDown**: Agent cleaning up resources

## Task Processing Flow

Tasks are distributed from the orchestrator to agents via NATS:
1. Client submits a task to the orchestrator
2. Orchestrator identifies appropriate agent based on capabilities
3. Agent receives task via NATS subscription
4. Agent processes task and returns result
5. Result is published back to the orchestrator

## NATS Communication Patterns

The system uses several NATS communication patterns:
- **Request-Reply**: For direct queries requiring a response
- **Pub-Sub**: For broadcasting events and status updates
- **Queue Groups**: For distributing tasks among similar agents

## Development Workflows

MCP supports two primary development workflows:

### Local Development (Recommended for daily work)

Advantages:
- Faster iteration cycles
- Easier debugging
- Direct access to local tools

### Containerized Development

Advantages:
- Consistent environment across all machines
- Isolated dependencies
- Closer to production environment

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

## Debugging Tips

- Use Kotlin Debug with breakpoints for JVM components
- For Python, use `debugpy` or IDE-based Python debugging
- Monitor NATS messages using `nats sub "mcp.task.>"`
- Check logs for each component

## FAQs

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

## Related Documentation

{{< related-docs >}}