# Build Engineer Onboarding Checklist

This checklist provides a streamlined sequence of tasks to help you get started with the MCP implementation. Use this alongside the more detailed [Implementation Guide](build-engineer-implementation-guide.md) and [Containerized Development Environment](containerized-dev-environment.md) guide.

## Containerized Development Environment Setup ⬅️ PRIORITY

- [ ] Install Podman and Podman Compose:
  ```bash
  sudo dnf update -y
  sudo dnf install -y podman podman-compose
  ```

- [ ] Verify Podman installation:
  ```bash
  podman --version
  podman-compose --version
  ```

- [ ] Create project directory structure:
  ```bash
  mkdir -p mcp-project/{mcp-core,agents/camera-agent,agents/python-processor,nats}
  cd mcp-project
  ```

- [ ] Create containerization files:
  - [ ] Create `podman-compose.yml` in project root (see [Containerized Dev Environment](containerized-dev-environment.md))
  - [ ] Create `mcp-core/Dockerfile.dev`
  - [ ] Create `agents/camera-agent/Dockerfile.dev`
  - [ ] Create `nats/nats-server.conf`

- [ ] Build and start the containerized environment:
  ```bash
  podman-compose build
  podman-compose up -d
  ```

## Traditional Environment Setup (Alternative)

If not using containers, install dependencies directly:

- [ ] Install core dependencies:
  ```bash
  sudo dnf update -y
  sudo dnf install -y git curl unzip java-17-openjdk-devel python3 python3-pip podman nats-server
  ```

- [ ] Install Kotlin and Gradle (via SDKMAN recommended):
  ```bash
  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install kotlin
  sdk install gradle
  ```

- [ ] Verify installations:
  ```bash
  java -version       # Should show Java 17+
  kotlin -version     # Should show latest Kotlin
  gradle -version     # Should show latest Gradle
  nats-server -v      # Should show NATS server version
  ```

## Project Setup

- [ ] Create project directory structure:
  ```bash
  mkdir -p mcp-project/src/main/kotlin/com/example/mcp
  mkdir -p mcp-project/src/main/kotlin/com/example/agents
  mkdir -p mcp-project/src/main/resources
  mkdir -p mcp-project/src/test/kotlin/com/example/mcp
  mkdir -p mcp-project/nats
  cd mcp-project
  ```

- [ ] Create Gradle configuration files:
  - [ ] `settings.gradle.kts` with project name
  - [ ] `build.gradle.kts` with dependencies (see Implementation Guide)

- [ ] Configure logging with `logback.xml` in resources directory

- [ ] Set up NATS configuration with `nats-server.conf` in nats directory

- [ ] Initialize Git repository:
  ```bash
  git init
  # Add .gitignore with build/, .gradle/, etc.
  git add .
  git commit -m "Initial project structure"
  ```

## Core Implementation

- [ ] Implement core data models:
  - [ ] `AgentState.kt` sealed class
  - [ ] `AgentEvent.kt` sealed class
  - [ ] `AgentTask.kt` and `TaskResult.kt` data classes
  - [ ] `AgentStatus.kt` data class
  - [ ] `Capability.kt` enum

- [ ] Create agent interface:
  - [ ] `McpAgent.kt` interface with core methods

- [ ] Implement NATS integration:
  - [ ] `NatsConnectionManager.kt` with connection handling

- [ ] Create state machine:
  - [ ] `AgentStateMachine.kt` using Tinder's StateMachine library

- [ ] Implement orchestrator:
  - [ ] `Orchestrator.kt` with agent management and task distribution

- [ ] Create main application:
  - [ ] `Main.kt` with application bootstrap code

## Building & Testing

- [ ] Build the project:
  ```bash
  ./gradlew build
  ```

- [ ] Run NATS server:
  ```bash
  nats-server -c nats/nats-server.conf
  ```

- [ ] Run the MCP application:
  ```bash
  ./gradlew run
  ```

- [ ] Verify successful startup in logs:
  - Check for "MCP running" message
  - Verify NATS connection established
  - Confirm no errors in initialization

## First Agent Implementation

- [ ] Create a simple Camera Integration Agent:
  - [ ] Implement `CameraIntegrationAgent.kt` with mock device detection
  - [ ] Register the agent with the orchestrator in `Orchestrator.kt`
  - [ ] Add task handlers for basic camera operations

- [ ] Test the agent:
  - [ ] Write unit tests for agent lifecycle
  - [ ] Manually test agent initialization
  - [ ] Verify agent registration with orchestrator

## Next Steps

- [ ] Review the implementation roadmap in `architecture/implementation-roadmap.md`
- [ ] Add task scheduling to the orchestrator
- [ ] Implement health monitoring framework
- [ ] Add more specialized agents as needed

## Resources

- [Implementation Guide](build-engineer-implementation-guide.md) - Detailed implementation instructions
- [FSM and Agent Interfaces](../../architecture/fsm-agent-interfaces.md) - Core agent framework specifications
- [Orchestrator and NATS Integration](../../architecture/orchestrator-nats-integration.md) - Central coordination design
- [Implementation Roadmap](../../architecture/implementation-roadmap.md) - Phase 1 execution plan