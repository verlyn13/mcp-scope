# SmolAgent: Lightweight Agent Implementation Guide

## Overview

SmolAgent provides a lightweight, minimal-dependency implementation of the McpAgent interface. It's designed for development, testing, and resource-constrained environments where a full agent implementation with NATS integration might be excessive.

## Key Features

- **Minimal Dependencies**: No NATS or external messaging dependencies
- **FSM Integration**: Uses the core state machine framework
- **Customizable**: Configurable with lambda-based task handlers
- **Low Resource Usage**: Minimal memory and CPU footprint
- **Quick Startup**: Fast initialization with no external connections

## Use Cases

1. **Development & Testing**: Ideal for unit and integration testing
2. **Proof of Concept**: Quick implementation for validating concepts
3. **Resource-Constrained Environments**: When memory or CPU resources are limited
4. **Offline Operation**: For environments without NATS connectivity
5. **Fast Prototyping**: For rapidly testing new agent functionality

## Implementation Example

```kotlin
// Create a basic SmolAgent
val basicAgent = SmolAgent(
    agentId = "my-test-agent",
    agentType = "test",
    capabilities = setOf(Capability.Custom("testing"))
)

// Create a SmolAgent with custom task handler
val customAgent = SmolAgent.withHandler(
    handler = { task ->
        // Custom task processing logic
        TaskResult(
            taskId = task.taskId,
            status = TaskStatus.COMPLETED,
            result = "Custom result for ${task.taskType}",
            executionTimeMs = 100
        )
    },
    agentId = "custom-agent",
    capabilities = setOf(Capability.Custom("custom-processing"))
)

// Process a task
val task = AgentTask(
    taskId = UUID.randomUUID().toString(),
    taskType = "test.task",
    parameters = mapOf("param1" to "value1")
)

val result = customAgent.processTask(task)
println("Task result: ${result.status} - ${result.result}")
```

## SmolAgent vs. BaseAgent

| Feature | SmolAgent | BaseAgent |
|---------|-----------|-----------|
| State Machine | ✅ Yes | ✅ Yes |
| NATS Integration | ❌ No | ✅ Yes |
| Heartbeat Mechanism | ❌ No | ✅ Yes |
| Dynamic Registration | ❌ No | ✅ Yes |
| Resource Usage | Low | Medium |
| Implementation Complexity | Low | Medium |
| Startup Time | Fast | Medium |
| Error Recovery | Basic | Advanced |
| Metrics | Basic | Comprehensive |

## Integration with Orchestrator

While SmolAgent doesn't connect to NATS directly, it can still be used with the Orchestrator in a local configuration:

```kotlin
// Create orchestrator
val orchestrator = Orchestrator(natsConnection)

// Create a SmolAgent
val agent = SmolAgent(agentId = "local-agent")

// Manually register with orchestrator
orchestrator.registerLocalAgent(agent)

// Now the orchestrator can directly dispatch tasks to the agent
// without going through NATS
```

## Best Practices

1. **Task Handlers**: Use the `withHandler` factory method to create agents with specific task processing logic
2. **Error Handling**: Implement robust error handling in your task lambdas
3. **State Management**: Use the state machine for proper lifecycle management
4. **Testing**: SmolAgent is ideal for creating test doubles and mocks

## Implementation Details

SmolAgent implements the full McpAgent interface but minimizes external dependencies:

- Doesn't connect to NATS or other external systems
- Uses the same state machine implementation as BaseAgent
- Provides simplified status reporting with basic metrics
- Supports custom task handlers via lambda functions

## Development Workflow

1. **Create SmolAgent**: Instantiate with custom ID and capabilities
2. **Define Task Handler**: Use the `withHandler` factory or provide a handler lambda
3. **Initialize**: Call `initialize()` to prepare the agent
4. **Process Tasks**: Call `processTask()` with AgentTask instances
5. **Monitor Status**: Use `getStatus()` to check agent health and metrics
6. **Shutdown**: Call `shutdown()` when finished

## Example: Creating a Test Double

SmolAgent is particularly useful for creating test doubles:

```kotlin
// Create a test double for a camera agent
val mockCameraAgent = SmolAgent.withHandler(
    handler = { task ->
        when (task.taskType) {
            "camera.scan" -> TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = """{"devices": [{"id": "mock-1", "name": "Test Camera"}]}""",
                executionTimeMs = 50
            )
            "camera.capture" -> TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = """{"width": 640, "height": 480, "format": "JPEG"}""",
                executionTimeMs = 100
            )
            else -> TaskResult(
                taskId = task.taskId,
                status = TaskStatus.FAILED,
                errorMessage = "Unsupported task type: ${task.taskType}",
                executionTimeMs = 10
            )
        }
    },
    agentType = "camera",
    capabilities = setOf(Capability.CameraDetection, Capability.FrameCapture)
)
```

## Conclusion

SmolAgent provides a lightweight alternative to the full BaseAgent implementation, suitable for development, testing, and resource-constrained environments. It maintains compatibility with the core FSM framework while minimizing external dependencies and resource usage.