# MCP Server Guide

## Overview

The Multi-Agent Control Platform (MCP) Server is the central component of the MCP system. It manages agent lifecycles, coordinates tasks, and provides the infrastructure for agent communication and orchestration.

This guide covers:
- Server configuration and setup
- Running the server
- Registering and managing agents
- Monitoring system health
- Troubleshooting common issues

## Server Architecture

The MCP Server consists of these main components:

1. **NATS Connection Manager**: Handles messaging infrastructure
2. **Orchestrator**: Coordinates agents and task distribution
3. **Task Scheduler**: Manages task execution and dependencies
4. **Health Monitor**: Tracks system and agent health
5. **Agent Registry**: Maintains the roster of available agents

These components work together to provide a robust platform for agent-based operations.

## Running the Server

### Command-line Options

The MCP Server can be configured using command-line options:

```bash
java -jar mcp-server.jar [options]
```

Available options:

| Option | Description | Default |
|--------|-------------|---------|
| `--help`, `-h` | Show help message | - |
| `--nats-url=<url>` | NATS server URL | nats://localhost:4222 |
| `--max-tasks=<num>` | Maximum concurrent tasks | CPU core count |
| `--health-interval=<ms>` | Health check interval in ms | 30000 |
| `--agent-timeout=<ms>` | Agent timeout in ms | 60000 |
| `--persistence` | Enable persistence | false |
| `--persistence-file=<path>` | Persistence file path | null |
| `--shutdown-grace=<ms>` | Shutdown grace period in ms | 5000 |
| `--no-health-checks` | Disable health checks | false |
| `--pid-file=<path>` | Path to write PID file | null |
| `--register-test-agents` | Register built-in test agents | false |

### Environment Variables

The server can also be configured using environment variables:

| Variable | Description | Equivalent Option |
|----------|-------------|-------------------|
| `NATS_URL` | NATS server URL | `--nats-url` |
| `MCP_MAX_TASKS` | Maximum concurrent tasks | `--max-tasks` |
| `MCP_HEALTH_INTERVAL` | Health check interval in ms | `--health-interval` |
| `MCP_AGENT_TIMEOUT` | Agent timeout in ms | `--agent-timeout` |
| `MCP_ENABLE_PERSISTENCE` | Enable persistence (true/false) | `--persistence` |
| `MCP_PERSISTENCE_FILE` | Persistence file path | `--persistence-file` |
| `MCP_SHUTDOWN_GRACE` | Shutdown grace period in ms | `--shutdown-grace` |
| `MCP_ENABLE_HEALTH_CHECKS` | Enable health checks (true/false) | `--no-health-checks` |
| `MCP_PID_FILE` | Path to write PID file | `--pid-file` |
| `MCP_REGISTER_TEST_AGENTS` | Register test agents (true/false) | `--register-test-agents` |

### Examples

Basic startup:
```bash
java -jar mcp-server.jar
```

Custom NATS server:
```bash
java -jar mcp-server.jar --nats-url=nats://nats-server:4222
```

With persistence:
```bash
java -jar mcp-server.jar --persistence --persistence-file=/var/lib/mcp/state.json
```

With test agents:
```bash
java -jar mcp-server.jar --register-test-agents
```

## Containerized Deployment

The MCP Server can be run in a containerized environment:

```bash
# Run with Podman
podman run -p 8080:8080 \
  -e NATS_URL=nats://nats-server:4222 \
  -v /var/lib/mcp:/data \
  mcp-server:latest
```

See the [Containerized Development Environment](containerized-dev-environment.md) guide for detailed information on container setup.

## Built-in Test Agents

When started with the `--register-test-agents` flag, the server registers these test agents:

1. **Echo Agent**: Echoes back the task parameters
   - Capability: `echo`
   - Use for testing basic connectivity

2. **Random Agent**: Randomly succeeds or fails (70% success rate)
   - Capability: `random`
   - Use for testing error handling

3. **Delay Agent**: Simulates long-running tasks
   - Capability: `delay`
   - Accepts `delayMs` parameter to control execution time
   - Use for testing timeout and concurrency

Example task for Delay Agent:
```json
{
  "taskId": "test-123",
  "taskType": "test.delay",
  "parameters": {
    "delayMs": "5000"
  },
  "priority": "NORMAL"
}
```

## Programmatic Usage

You can also embed the MCP Server in your application:

```kotlin
// Create server with custom configuration
val config = McpServerConfig(
    natsUrl = "nats://localhost:4222",
    maxConcurrentTasks = 4,
    enableHealthChecks = true
)

// Create and start server
val server = McpServer(config)
server.start()

// Register a custom agent
val myAgent = SmolAgent.withHandler { task ->
    // Process task
    TaskResult(
        taskId = task.taskId,
        status = TaskStatus.COMPLETED,
        result = "Processed: ${task.parameters}",
        executionTimeMs = 100
    )
}
server.registerAgent(myAgent)

// Get server status
val status = server.getStatus()
println("Server running: ${status.isRunning}")
println("Agents: ${status.orchestratorStatus?.agentCount ?: 0}")

// Shut down server when done
server.stop()
```

## Health Monitoring

The MCP Server includes a health monitoring system that:

1. Tracks agent heartbeats
2. Detects unresponsive agents
3. Monitors system resource usage
4. Reports status via logging and metrics

Health check frequency can be configured with the `--health-interval` option.

## Persistence

When persistence is enabled (`--persistence`), the server stores:

1. Agent registrations
2. Task status and history
3. System configuration

This allows the server to recover its state after a restart.

## Common Issues and Troubleshooting

### NATS Connection Issues

If the server fails to connect to NATS:

1. Verify NATS server is running: `nats-server -DV`
2. Check connection URL in configuration
3. Ensure no firewall blocking port 4222
4. Try with `nats://localhost:4222` to verify localhost connectivity

### Agent Registration Failures

If agents fail to register:

1. Check agent is properly initialized
2. Verify NATS connectivity from agent
3. Ensure agent ID is unique
4. Check for serialization errors in registration message

### Task Processing Issues

If tasks aren't being processed:

1. Check task format and required fields
2. Verify agent with matching capabilities is registered
3. Look for exceptions in agent processTask method
4. Check for timeout settings that might be too short

## Conclusion

The MCP Server provides a robust foundation for agent-based applications. By following this guide, you can configure and run the server, register agents, and monitor the system's health.

For more advanced usage, refer to:

- [FSM Implementation Summary](fsm-implementation-summary.md)
- [Build Engineer Profile](build-engineer-profile.md)
- [SmolAgent Guide](smol-agent-guide.md)