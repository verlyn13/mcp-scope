# MCP Architecture Overview

This document provides a comprehensive overview of the Multi-Agent Control Platform (MCP) architecture, explaining the core components, their interactions, and the underlying design principles.

## System Architecture

The MCP system follows a message-driven, distributed architecture built around a central orchestrator and specialized agents:

```
┌─────────────────────┐
│                     │
│ Android Application │
│                     │
└─────────┬───────────┘
           │ HTTP/WebSocket
           ▼
┌─────────────────────┐
│   MCP Orchestrator  │◄────┐
│  ┌───────────────┐  │     │
│  │   FSM Engine  │  │     │ Agent
│  └───────────────┘  │     │ Registration
└─────────┬───────────┘     │
           │ NATS            │
           ▼                 │
┌─────────────────────┐     │
│   Agent Framework   │─────┘
│  ┌───────┐ ┌──────┐ │
│  │Agent 1│ │Agent2│ │
│  └───────┘ └──────┘ │
└─────────────────────┘
```

### Key Components

1. **MCP Orchestrator**
   - Central coordination component
   - Manages agent lifecycle and registration
   - Distributes tasks to appropriate agents
   - Monitors system health

2. **Agent Framework**
   - Provides common interface for all agents
   - Implements state machine for agent lifecycle
   - Handles communication with orchestrator
   - Enables consistent behavior across different agent types

3. **NATS Messaging System**
   - High-performance message broker
   - Enables asynchronous communication between components
   - Supports various messaging patterns (request-reply, pub-sub, queue groups)
   - Provides reliable message delivery

4. **Specialized Agents**
   - Camera Integration Agent: Handles USB camera detection and operations
   - Python Processor Agent: Provides data processing capabilities
   - Future agents: Build system, testing, code generation, etc.

5. **Client Applications**
   - Android applications that consume MCP services
   - Web interfaces for system monitoring and control
   - Command-line tools for development and testing

## Message Flow

The system uses message-driven communication with the following patterns:

### Agent Registration Flow

```
┌─────────┐                 ┌───────────┐                ┌──────┐
│ Agent   │                 │Orchestrator│                │ NATS │
└────┬────┘                 └─────┬─────┘                └───┬──┘
     │                            │                          │
     │ Initialize                 │                          │
     │────────────────────────────────────────────────────►│
     │                            │                          │
     │                            │ Subscribe to             │
     │                            │ mcp.agent.register       │
     │                            │◄─────────────────────────│
     │                            │                          │
     │ Publish to                 │                          │
     │ mcp.agent.register         │                          │
     │────────────────────────────────────────────────────►│
     │                            │                          │
     │                            │ Receive registration     │
     │                            │◄─────────────────────────│
     │                            │                          │
     │                            │ Add agent to registry    │
     │                            │─────┐                    │
     │                            │     │                    │
     │                            │◄────┘                    │
```

### Task Distribution Flow

```
┌─────────┐                 ┌───────────┐                ┌──────┐                ┌──────┐
│ Client  │                 │Orchestrator│                │ NATS │                │ Agent│
└────┬────┘                 └─────┬─────┘                └───┬──┘                └───┬──┘
     │                            │                          │                       │
     │ Submit task                │                          │                       │
     │ (HTTP or NATS)             │                          │                       │
     │───────────────────────────►│                          │                       │
     │                            │                          │                       │
     │                            │ Find suitable agent      │                       │
     │                            │─────┐                    │                       │
     │                            │     │                    │                       │
     │                            │◄────┘                    │                       │
     │                            │                          │                       │
     │                            │ Publish to               │                       │
     │                            │ mcp.task.{agentId}       │                       │
     │                            │─────────────────────────►│                       │
     │                            │                          │                       │
     │                            │                          │ Deliver task          │
     │                            │                          │──────────────────────►│
     │                            │                          │                       │
     │                            │                          │                       │ Process
     │                            │                          │                       │ task
     │                            │                          │                       │─────┐
     │                            │                          │                       │     │
     │                            │                          │                       │◄────┘
     │                            │                          │                       │
     │                            │                          │ Publish result to     │
     │                            │                          │ mcp.task.{id}.result  │
     │                            │                          │◄─────────────────────│
     │                            │                          │                       │
     │                            │ Receive result           │                       │
     │                            │◄─────────────────────────│                       │
     │                            │                          │                       │
     │ Return result              │                          │                       │
     │◄───────────────────────────│                          │                       │
```

### Health Monitoring Flow

```
┌──────────┐              ┌───────────┐               ┌──────┐               ┌──────┐
│ Monitor  │              │Orchestrator│               │ NATS │               │ Agent│
└────┬─────┘              └─────┬─────┘               └───┬──┘               └───┬──┘
     │                          │                         │                      │
     │                          │                         │ Publish heartbeat    │
     │                          │                         │ mcp.agent.heartbeat  │
     │                          │                         │◄─────────────────────│
     │                          │                         │                      │
     │                          │ Receive heartbeat       │                      │
     │                          │◄────────────────────────│                      │
     │                          │                         │                      │
     │                          │ Update agent status     │                      │
     │                          │──────┐                  │                      │
     │                          │      │                  │                      │
     │                          │◄─────┘                  │                      │
     │                          │                         │                      │
     │ Request system status    │                         │                      │
     │─────────────────────────►│                         │                      │
     │                          │                         │                      │
     │ Return system status     │                         │                      │
     │◄─────────────────────────│                         │                      │
     │                          │                         │                      │
```

## Agent State Machine

The agent lifecycle is governed by a finite state machine with the following states and transitions:

```
┌─────────┐
│         │
│  Idle   │◄────────────────┐
│         │                 │
└────┬────┘                 │
     │                      │
     │ Initialize           │
     ▼                      │
┌─────────┐          ┌──────────┐
│         │          │          │
│ Initial-│──Error──►│  Error   │
│  izing  │          │          │
│         │          └──────┬───┘
└────┬────┘                 │
     │                      │
     │ Process              │ Initialize
     ▼                      │
┌─────────┐                 │
│         │                 │
│ Process-│─────────────────┘
│   ing   │
│         │
└────┬────┘
     │
     │ Shutdown
     ▼
┌─────────┐
│ Shutting│
│  Down   │
│         │
└─────────┘
```

## Core Data Models

### Agent Management

- **AgentState**: Sealed class representing the different states in the agent lifecycle
- **AgentEvent**: Sealed class for events that trigger state transitions
- **AgentStatus**: Data class containing the current status of an agent
- **McpAgent**: Interface that all agents must implement

### Task Processing

- **AgentTask**: Data class representing a task to be executed by an agent
- **TaskResult**: Data class containing the result of a task execution
- **TaskStatus**: Enum representing the different states of a task

## Communication Protocols

### NATS Topic Structure

- `mcp.agent.register`: Agent registration
- `mcp.agent.heartbeat`: Agent heartbeat messages
- `mcp.task.submit`: Task submission
- `mcp.task.{taskId}.status`: Task status updates
- `mcp.task.{taskId}.result`: Task results
- `mcp.system.health`: System health monitoring

### Message Formats

All messages are serialized using JSON (via Kotlin Serialization in JVM components and standard libraries in Python components).

## Design Principles

### 1. Loose Coupling

Components communicate exclusively through messages, with no direct dependencies between agents or between agents and the orchestrator.

### 2. Single Responsibility

Each component has a clear, well-defined responsibility:
- Orchestrator: Task distribution and agent management
- Agents: Specialized domain-specific operations
- NATS: Message delivery and routing

### 3. Resilience

The system is designed to be resilient to failures:
- Stateless communication
- Automatic reconnection to NATS
- Exponential backoff for retries
- Circuit breakers for failing components

### 4. Extensibility

New agents can be added without modifying existing components, as long as they implement the McpAgent interface and follow the messaging protocols.

### 5. Observability

The system provides comprehensive monitoring and logging:
- Agent heartbeats for health monitoring
- Detailed task status tracking
- Structured logging

## Security Considerations

The current implementation focuses on functionality rather than security. In a production environment, consider:

1. **Authentication and Authorization**:
   - Secure access to NATS with username/password or certificates
   - Implement fine-grained access control for topics

2. **Network Security**:
   - Use TLS for all communications
   - Implement network segmentation

3. **Data Protection**:
   - Encrypt sensitive data in messages
   - Implement secure storage for credentials

## Scalability Considerations

The architecture supports horizontal scaling through:

1. **Agent Replication**:
   - Multiple instances of the same agent type can run simultaneously
   - NATS queue groups ensure each task is processed only once

2. **NATS Clustering**:
   - NATS can be configured as a cluster for higher throughput
   - NATS superclusters can span multiple regions

3. **Orchestrator Statelessness**:
   - The orchestrator can be scaled horizontally by using a shared database for agent registrations

## Future Architectural Enhancements

Potential future enhancements to the architecture include:

1. **Task Scheduling**: Add priority-based scheduling and task dependencies
2. **Agent Discovery**: Dynamic discovery of agents across networks
3. **Distributed Tracing**: Add tracing for end-to-end visibility of task processing
4. **Reactive Execution Model**: Move to a fully reactive execution model with backpressure support
5. **Multi-Tenancy**: Support for multiple isolated environments within the same infrastructure

## References

- [NATS Documentation](https://docs.nats.io/)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-overview.html)
- [Tinder StateMachine](https://github.com/Tinder/StateMachine)
- [Reactive Systems Architecture](https://www.reactivemanifesto.org/)