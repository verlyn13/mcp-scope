# MCP Server Quick Start Guide

This guide will help you quickly set up and run the Multi-Agent Control Platform (MCP) Server.

## Prerequisites

- Java 17 or later
- Gradle 7.5 or later (optional, wrapper included)
- NATS server (optional, can run in container)
- Podman or Docker (for containerized deployment)

## Option 1: Running Locally

### Build the Application

```bash
cd mcp-project
./gradlew :mcp-core:build
```

This will create a runnable JAR file in `mcp-core/build/libs/`.

### Start NATS Server

Start a NATS server:

```bash
# Using the NATS server directly
nats-server -c nats/nats-server.conf

# Or using podman/docker
podman run -p 4222:4222 -p 8222:8222 nats:2.9-alpine
```

### Run the MCP Server

```bash
java -jar mcp-core/build/libs/mcp-core-1.0.0.jar
```

With test agents:

```bash
java -jar mcp-core/build/libs/mcp-core-1.0.0.jar --register-test-agents
```

## Option 2: Using Podman Compose

The easiest way to run the MCP Server with all required components is using Podman Compose:

```bash
cd mcp-project
podman-compose -f mcp-server-compose.yml up
```

This will start:
- NATS server for messaging
- MCP Server with test agents enabled

### Running With Specific Agent Types

To include specific agent types:

```bash
podman-compose -f mcp-server-compose.yml --profile with-agents up
```

## Testing the Server

Once the server is running, you can interact with it using the built-in test agents:

### 1. Echo Agent Test

Send a task to the echo agent:

```bash
curl -X POST http://localhost:8080/api/task \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "test-echo-1",
    "taskType": "test.echo",
    "parameters": {
      "message": "Hello, World!"
    },
    "priority": "NORMAL"
  }'
```

### 2. Delay Agent Test

Send a task with a specified delay:

```bash
curl -X POST http://localhost:8080/api/task \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "test-delay-1",
    "taskType": "test.delay",
    "parameters": {
      "delayMs": "3000"
    },
    "priority": "NORMAL"
  }'
```

### 3. Check Server Status

Get the current system status:

```bash
curl http://localhost:8080/api/status
```

## Common Operations

### Registering a Custom Agent

To register a custom agent programmatically:

```kotlin
// Create agent registration
val registration = AgentRegistration(
    agentId = "my-custom-agent",
    agentType = "custom",
    capabilities = listOf("custom.capability")
)

// Send to MCP Server
natsConnection.publish(
    "mcp.agent.register",
    Json.encodeToString(AgentRegistrationMessage(registration = registration))
)
```

### Submitting a Task

To submit a task:

```kotlin
// Create task
val task = AgentTask(
    taskId = "task-" + UUID.randomUUID().toString(),
    taskType = "custom.task",
    parameters = mapOf("param1" to "value1"),
    priority = TaskPriority.NORMAL
)

// Send to MCP Server
natsConnection.publish(
    "mcp.orchestrator.task.submit",
    Json.encodeToString(TaskSubmissionMessage(task = task))
)
```

## Next Steps

After you have the MCP Server running, consider:

1. Creating your own custom agents by extending BaseAgent or using SmolAgent
2. Integrating with your existing applications
3. Setting up monitoring for production use

## Troubleshooting

### Server Won't Start

If the server fails to start:

1. Check Java version: `java -version` (should be 17+)
2. Ensure NATS server is running and accessible
3. Check for port conflicts (8080 for API, 4222 for NATS)
4. Review logs for specific error messages

### No Agents Appearing

If agents don't register:

1. Verify NATS connection is working
2. Check agent logs for registration attempts
3. Ensure agent IDs are unique
4. Try using `--register-test-agents` to verify server operation

## Additional Resources

- [Complete MCP Server Guide](mcp-server-guide.md)
- [FSM Implementation Summary](fsm-implementation-summary.md)
- [SmolAgent Guide](smol-agent-guide.md)
- [Containerized Development Guide](containerized-dev-environment.md)