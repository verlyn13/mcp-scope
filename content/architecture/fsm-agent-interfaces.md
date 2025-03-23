# FSM Framework and Core Agent Interfaces Specification

## Overview

This document specifies the design of the Finite State Machine (FSM) framework and core agent interfaces for the Multi-Agent Control Platform (MCP). These interfaces establish the foundation for all agent interactions and lifecycle management within the system.

## Core Components

### 1. Agent State Model

Agents in the MCP follow a well-defined lifecycle represented by the following states:

```kotlin
sealed class AgentState {
    // Initial state after agent creation but before initialization
    object Idle : AgentState()
    
    // Agent is preparing resources, connections, and dependencies
    object Initializing : AgentState()
    
    // Agent is actively processing a task
    object Processing : AgentState()
    
    // Agent has encountered an error and may need intervention
    data class Error(val message: String, val exception: Exception? = null) : AgentState()
    
    // Agent is releasing resources and preparing to terminate
    object ShuttingDown : AgentState()
}
```

### 2. Agent Events

Events trigger transitions between agent states:

```kotlin
sealed class AgentEvent {
    // Triggers initialization of the agent
    object Initialize : AgentEvent()
    
    // Signals the agent to process a specific task
    data class Process(val task: AgentTask) : AgentEvent()
    
    // Indicates that a task has been completed
    data class Complete(val result: TaskResult) : AgentEvent()
    
    // Signals an error during processing
    data class Error(val exception: Exception, val message: String? = null) : AgentEvent()
    
    // Triggers the shutdown sequence
    object Shutdown : AgentEvent()
    
    // Requests the current status of the agent
    object RequestStatus : AgentEvent()
}
```

### 3. Core Agent Interface

The fundamental interface that all agents must implement:

```kotlin
interface McpAgent {
    // Unique identifier for the agent instance
    val agentId: String
    
    // Type of agent (e.g., "camera", "build", "code-gen")
    val agentType: String
    
    // Set of capabilities this agent provides
    val capabilities: Set<Capability>
    
    // Initialize the agent and prepare resources
    suspend fun initialize(): Boolean
    
    // Process a specific task and return the result
    suspend fun processTask(task: AgentTask): TaskResult
    
    // Get the current status of the agent
    fun getStatus(): AgentStatus
    
    // Release resources and perform cleanup
    suspend fun shutdown()
    
    // Handle an error condition
    suspend fun handleError(error: Exception): Boolean
}
```

### 4. Agent State Machine

The FSM that manages agent lifecycle:

```kotlin
class AgentStateMachine(private val agent: McpAgent) {
    private val stateMachine = StateMachine.create<AgentState, AgentEvent, Unit> {
        initialState(AgentState.Idle)
        
        state<AgentState.Idle> {
            on<AgentEvent.Initialize> {
                transitionTo(AgentState.Initializing)
            }
        }
        
        state<AgentState.Initializing> {
            onEnter {
                try {
                    val success = agent.initialize()
                    if (success) {
                        transitionTo(AgentState.Idle)
                    } else {
                        transitionTo(AgentState.Error("Initialization failed"))
                    }
                } catch (e: Exception) {
                    transitionTo(AgentState.Error("Initialization error", e))
                }
            }
        }
        
        state<AgentState.Idle> {
            on<AgentEvent.Process> { event ->
                transitionTo(AgentState.Processing)
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown)
            }
        }
        
        state<AgentState.Processing> {
            onEnter { state ->
                val currentState = state as AgentState.Processing
                try {
                    // This would be implemented to process the current task
                    transitionTo(AgentState.Idle)
                } catch (e: Exception) {
                    transitionTo(AgentState.Error("Processing error", e))
                }
            }
            
            on<AgentEvent.Complete> {
                transitionTo(AgentState.Idle)
            }
            
            on<AgentEvent.Error> { event ->
                transitionTo(AgentState.Error(event.message ?: "Unknown error", event.exception))
            }
        }
        
        state<AgentState.Error> {
            onEnter { state ->
                val errorState = state as AgentState.Error
                try {
                    val recovered = agent.handleError(errorState.exception ?: Exception(errorState.message))
                    if (recovered) {
                        transitionTo(AgentState.Idle)
                    }
                    // Stay in Error state if not recovered
                } catch (e: Exception) {
                    // Still in Error state, but with new exception details
                    transitionTo(AgentState.Error("Error during recovery", e))
                }
            }
            
            on<AgentEvent.Initialize> {
                transitionTo(AgentState.Initializing)
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown)
            }
        }
        
        state<AgentState.ShuttingDown> {
            onEnter {
                try {
                    agent.shutdown()
                    // Terminal state, no transition
                } catch (e: Exception) {
                    // Even if shutdown fails, we consider the agent terminated
                    // Log the exception but don't transition
                }
            }
        }
    }
    
    // Process an event through the state machine
    fun process(event: AgentEvent) {
        stateMachine.transition(event)
    }
    
    // Get the current state
    fun getCurrentState(): AgentState = stateMachine.state
}
```

## Data Models

### 1. Agent Task

Represents a discrete unit of work for an agent to process:

```kotlin
data class AgentTask(
    // Unique identifier for the task
    val taskId: String,
    
    // Type of task to execute
    val taskType: String,
    
    // Task priority for scheduling
    val priority: TaskPriority = TaskPriority.NORMAL,
    
    // Task-specific parameters
    val parameters: Map<String, Any> = emptyMap(),
    
    // Optional timeout in milliseconds
    val timeoutMs: Long? = null,
    
    // Optional deadline (absolute timestamp)
    val deadlineTimestamp: Long? = null,
    
    // IDs of tasks that must complete before this one
    val dependencies: List<String> = emptyList(),
    
    // Task creation timestamp
    val createdAt: Long = System.currentTimeMillis()
)

enum class TaskPriority {
    LOW, NORMAL, HIGH, CRITICAL
}
```

### 2. Task Result

Represents the outcome of a task execution:

```kotlin
data class TaskResult(
    // ID of the task this is a result for
    val taskId: String,
    
    // Status code indicating success or failure
    val status: TaskStatus,
    
    // Optional result data
    val result: Any? = null,
    
    // Error message if status is FAILED
    val errorMessage: String? = null,
    
    // Time taken to execute in milliseconds
    val executionTimeMs: Long,
    
    // Timestamp when the result was created
    val completedAt: Long = System.currentTimeMillis()
)

enum class TaskStatus {
    PENDING,      // Task is waiting to be processed
    IN_PROGRESS,  // Task is currently being processed
    COMPLETED,    // Task completed successfully
    FAILED,       // Task failed to complete
    CANCELLED,    // Task was cancelled before completion
    TIMEOUT       // Task exceeded its allowed execution time
}
```

### 3. Agent Status

Represents the current state and health of an agent:

```kotlin
data class AgentStatus(
    // Agent's unique identifier
    val agentId: String,
    
    // Agent's current state
    val state: AgentState,
    
    // Whether the agent is functioning correctly
    val healthy: Boolean,
    
    // Resource utilization metrics
    val metrics: Map<String, Double> = emptyMap(),
    
    // Current task being processed (if any)
    val currentTask: AgentTask? = null,
    
    // Timestamp of the last completed task
    val lastActiveTimestamp: Long? = null,
    
    // Number of tasks completed since startup
    val tasksCompleted: Int = 0,
    
    // Number of tasks failed since startup
    val tasksFailed: Int = 0
)
```

### 4. Agent Capability

Defines specific functionalities an agent can perform:

```kotlin
sealed class Capability {
    // Camera-related capabilities
    object CameraDetection : Capability()
    object CameraConfiguration : Capability()
    object FrameCapture : Capability()
    
    // Code generation capabilities
    object BoilerplateGeneration : Capability()
    object JniBindingGeneration : Capability()
    
    // Build system capabilities
    object GradleExecution : Capability()
    object DependencyManagement : Capability()
    
    // Testing capabilities
    object UnitTestExecution : Capability()
    object IntegrationTestExecution : Capability()
    
    // Static analysis capabilities
    object CodeQualityAnalysis : Capability()
    object SecurityAnalysis : Capability()
    
    // Documentation capabilities
    object ApiDocGeneration : Capability()
    object UsageExampleGeneration : Capability()
    
    // Custom capability with name
    data class Custom(val name: String) : Capability()
}
```

## Implementation Guidelines

### 1. Agent Implementation Best Practices

1. **Idempotent Operations**: Design agent tasks to be idempotent whenever possible to allow for safe retries.
2. **Graceful Degradation**: Agents should provide partial functionality when dependencies are unavailable.
3. **Resource Management**: Properly acquire and release resources during initialization and shutdown.
4. **Error Handling**: Implement comprehensive error handling with meaningful error messages.
5. **Timeout Handling**: Support task timeouts and prevent resource leaks if a task exceeds its time limit.

### 2. Agent Registration Process

1. Agent is created with a unique ID and type
2. Agent registers with the orchestrator, providing its capabilities
3. Orchestrator acknowledges registration and adds agent to its registry
4. Agent enters Idle state, ready to receive tasks

### 3. Agent Shutdown Process

1. Orchestrator sends Shutdown event to agent
2. Agent transitions to ShuttingDown state
3. Agent completes any in-progress tasks or gracefully terminates them
4. Agent releases all resources and connections
5. Agent notifies orchestrator of successful shutdown

### 4. State Persistence Considerations

For reliability, consider persisting agent states to allow recovery after system restarts:

1. Use event sourcing pattern to record all state transitions
2. Periodically snapshot agent states to disk
3. On startup, restore agents to their previous states from snapshots and event logs

## Next Steps

After implementing the FSM framework and core agent interfaces:

1. Create the Orchestrator that will manage agent instances
2. Implement the NATS messaging integration for inter-agent communication
3. Develop a simple Camera Integration Agent using these interfaces
4. Add basic health monitoring leveraging the AgentStatus model