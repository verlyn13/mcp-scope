# Orchestrator and NATS Messaging Integration Specification

## Overview

This document specifies the design of the Orchestrator component and NATS messaging integration for the Multi-Agent Control Platform (MCP). The Orchestrator is the central component responsible for managing agent lifecycles, distributing tasks, and monitoring system health. NATS provides the messaging infrastructure for efficient inter-component communication.

## Core Components

### 1. Orchestrator Design

The Orchestrator serves as the central coordination point for all agents in the system:

```kotlin
class Orchestrator(
    private val natsConnection: Connection,
    private val config: OrchestratorConfig
) {
    // Registry of all active agents
    private val agentRegistry = ConcurrentHashMap<String, AgentInfo>()
    
    // Task scheduler for managing task execution
    private val taskScheduler = TaskScheduler(config.maxConcurrentTasks)
    
    // Coroutine scope for orchestrator operations
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Initialize the orchestrator
    suspend fun start() {
        setupSubscriptions()
        startHealthChecks()
        loadPersistentState()
    }
    
    // Register a new agent
    suspend fun registerAgent(registration: AgentRegistration): Boolean {
        // Implementation details for agent registration
    }
    
    // Submit a task for execution
    suspend fun submitTask(task: AgentTask): String {
        // Implementation details for task submission
    }
    
    // Get status of all agents
    fun getSystemStatus(): SystemStatus {
        // Implementation details for gathering system status
    }
    
    // Shutdown the orchestrator and all agents
    suspend fun shutdown() {
        // Implementation details for graceful shutdown
    }
    
    // Set up NATS subscriptions
    private fun setupSubscriptions() {
        // Implementation details for NATS subscription setup
    }
    
    // Start periodic health checks
    private fun startHealthChecks() {
        // Implementation details for agent health monitoring
    }
    
    // Load persistent state (if enabled)
    private suspend fun loadPersistentState() {
        // Implementation details for state restoration
    }
}

data class OrchestratorConfig(
    val maxConcurrentTasks: Int = Runtime.getRuntime().availableProcessors(),
    val healthCheckIntervalMs: Long = 30000,
    val agentTimeoutMs: Long = 60000,
    val enablePersistence: Boolean = false,
    val persistenceFilePath: String? = null
)

data class AgentInfo(
    val registration: AgentRegistration,
    val stateMachine: AgentStateMachine,
    val lastHeartbeat: AtomicLong = AtomicLong(System.currentTimeMillis()),
    val metrics: ConcurrentHashMap<String, Double> = ConcurrentHashMap()
)

data class SystemStatus(
    val orchestratorStatus: String,
    val agentCount: Int,
    val activeTaskCount: Int,
    val queuedTaskCount: Int,
    val healthyAgentCount: Int,
    val unhealthyAgentCount: Int,
    val agentStatuses: List<AgentStatus>
)
```

### 2. Task Scheduler

The TaskScheduler manages task execution, respecting priorities and dependencies:

```kotlin
class TaskScheduler(private val maxConcurrentTasks: Int) {
    // Queue of pending tasks, ordered by priority
    private val taskQueue = PriorityQueue<QueuedTask> { a, b -> 
        a.task.priority.ordinal.compareTo(b.task.priority.ordinal)
    }
    
    // Currently executing tasks
    private val activeTasks = ConcurrentHashMap<String, QueuedTask>()
    
    // Tasks that are waiting for dependencies
    private val waitingTasks = ConcurrentHashMap<String, QueuedTask>()
    
    // Enqueue a new task
    suspend fun enqueueTask(task: AgentTask, targetAgentId: String? = null): String {
        // Implementation details for task enqueueing
    }
    
    // Process the next available task
    suspend fun processNextTask() {
        // Implementation details for task processing
    }
    
    // Complete a task and process any dependent tasks
    suspend fun completeTask(taskId: String, result: TaskResult) {
        // Implementation details for task completion
    }
    
    // Check if a task can be executed (dependencies satisfied)
    private fun canExecuteTask(task: AgentTask): Boolean {
        // Implementation details for dependency checking
    }
    
    // Find an appropriate agent for a task
    private fun findAgentForTask(task: AgentTask, preferredAgentId: String?): String? {
        // Implementation details for agent selection
    }
}

data class QueuedTask(
    val task: AgentTask,
    val targetAgentId: String?,
    val createdAt: Long = System.currentTimeMillis()
)
```

## NATS Messaging Integration

### 1. NATS Topic Structure

NATS topics are organized hierarchically for efficient routing:

```
mcp.agent.register            # Agent registration messages
mcp.agent.{agentId}.task      # Task assignments for specific agent
mcp.agent.{agentId}.result    # Task results from specific agent
mcp.agent.{agentId}.status    # Status updates from specific agent
mcp.agent.{agentId}.heartbeat # Health check heartbeats
mcp.orchestrator.task.submit  # Task submission to orchestrator
mcp.orchestrator.system.event # System-wide event broadcasts
mcp.orchestrator.health       # System health information
```

### 2. Message Schema Design

```kotlin
// Base message interface for all NATS messages
interface NatsMessage {
    val messageId: String
    val timestamp: Long
}

// Agent registration message
data class AgentRegistrationMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val registration: AgentRegistration
) : NatsMessage

// Task assignment message
data class TaskAssignmentMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val task: AgentTask
) : NatsMessage

// Task result message
data class TaskResultMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val result: TaskResult
) : NatsMessage

// Agent status message
data class AgentStatusMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val status: AgentStatus
) : NatsMessage

// Agent heartbeat message
data class HeartbeatMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val agentId: String,
    val metrics: Map<String, Double> = emptyMap()
) : NatsMessage

// System event message
data class SystemEventMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val eventType: SystemEventType,
    val payload: Any? = null
) : NatsMessage

enum class SystemEventType {
    ORCHESTRATOR_STARTED,
    ORCHESTRATOR_STOPPING,
    AGENT_REGISTERED,
    AGENT_LOST,
    TASK_SUBMITTED,
    TASK_COMPLETED,
    TASK_FAILED,
    SYSTEM_ERROR
}
```

### 3. NATS Connection Management

```kotlin
class NatsConnectionManager(private val config: NatsConfig) {
    private lateinit var connection: Connection
    
    // Initialize the NATS connection
    fun initialize(): Connection {
        val options = Options.Builder()
            .server(config.serverUrl)
            .connectionTimeout(Duration.ofMillis(config.connectionTimeoutMs))
            .reconnectWait(Duration.ofMillis(config.reconnectWaitMs))
            .maxReconnects(config.maxReconnects)
            .build()
            
        connection = Nats.connect(options)
        return connection
    }
    
    // Close the NATS connection
    fun close() {
        if (::connection.isInitialized && !connection.isClosed) {
            connection.close()
        }
    }
    
    // Check if connected to NATS
    fun isConnected(): Boolean {
        return ::connection.isInitialized && connection.status == Connection.Status.CONNECTED
    }
    
    // Publish a message to a topic
    fun <T : NatsMessage> publish(topic: String, message: T) {
        val jsonString = Json.encodeToString(message)
        connection.publish(topic, jsonString.toByteArray())
    }
    
    // Create a dispatcher for handling NATS messages
    fun createDispatcher(): Dispatcher {
        return connection.createDispatcher()
    }
}

data class NatsConfig(
    val serverUrl: String = "nats://localhost:4222",
    val connectionTimeoutMs: Long = 5000,
    val reconnectWaitMs: Long = 1000,
    val maxReconnects: Int = -1 // Unlimited reconnects
)
```

## Communication Patterns

### 1. Agent Registration Flow

```
1. Agent starts up and creates registration message
2. Agent publishes to: mcp.agent.register
3. Orchestrator processes registration and adds to registry
4. Orchestrator publishes confirmation to: mcp.agent.{agentId}.status
5. Agent begins sending heartbeats to: mcp.agent.{agentId}.heartbeat
```

### 2. Task Submission and Execution Flow

```
1. Client submits task to: mcp.orchestrator.task.submit
2. Orchestrator determines appropriate agent
3. Orchestrator publishes task to: mcp.agent.{agentId}.task
4. Agent processes task and publishes result to: mcp.agent.{agentId}.result
5. Orchestrator notifies client of completion
6. Orchestrator broadcasts event to: mcp.orchestrator.system.event
```

### 3. Health Check Flow

```
1. Agent publishes heartbeat to: mcp.agent.{agentId}.heartbeat periodically
2. Orchestrator monitors heartbeats and tracks last seen time
3. If agent misses heartbeats, orchestrator marks agent as unhealthy
4. If agent remains unhealthy for a threshold period, orchestrator marks it as lost
5. Orchestrator broadcasts agent loss event to: mcp.orchestrator.system.event
```

## Agent Discovery and Registration

### 1. Dynamic Agent Discovery

```kotlin
class AgentDiscoveryService(
    private val natsConnection: Connection,
    private val orchestrator: Orchestrator
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Start agent discovery
    fun start() {
        val dispatcher = natsConnection.createDispatcher { message ->
            scope.launch {
                handleRegistrationMessage(message)
            }
        }
        
        dispatcher.subscribe("mcp.agent.register")
    }
    
    // Handle agent registration message
    private suspend fun handleRegistrationMessage(message: Message) {
        try {
            val registrationMessage = Json.decodeFromString<AgentRegistrationMessage>(
                String(message.data)
            )
            
            orchestrator.registerAgent(registrationMessage.registration)
        } catch (e: Exception) {
            // Log error and continue
        }
    }
}
```

### 2. Agent Heartbeat Monitoring

```kotlin
class AgentHealthMonitor(
    private val natsConnection: Connection,
    private val agentRegistry: ConcurrentHashMap<String, AgentInfo>,
    private val config: HealthMonitorConfig
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var monitorJob: Job? = null
    
    // Start heartbeat monitoring
    fun start() {
        // Subscribe to heartbeat messages
        val dispatcher = natsConnection.createDispatcher { message ->
            scope.launch {
                handleHeartbeatMessage(message)
            }
        }
        
        dispatcher.subscribe("mcp.agent.*.heartbeat")
        
        // Start periodic health check
        monitorJob = scope.launch {
            while (isActive) {
                checkAgentHealth()
                delay(config.healthCheckIntervalMs)
            }
        }
    }
    
    // Stop heartbeat monitoring
    fun stop() {
        monitorJob?.cancel()
    }
    
    // Handle heartbeat message
    private fun handleHeartbeatMessage(message: Message) {
        try {
            val subject = message.subject
            val agentId = subject.split(".")[2] // Extract agent ID from topic
            
            val heartbeatMessage = Json.decodeFromString<HeartbeatMessage>(
                String(message.data)
            )
            
            // Update agent's last heartbeat timestamp
            agentRegistry[agentId]?.lastHeartbeat?.set(System.currentTimeMillis())
            
            // Update agent metrics
            agentRegistry[agentId]?.metrics?.putAll(heartbeatMessage.metrics)
        } catch (e: Exception) {
            // Log error and continue
        }
    }
    
    // Check agent health status
    private fun checkAgentHealth() {
        val now = System.currentTimeMillis()
        
        agentRegistry.forEach { (agentId, agentInfo) ->
            val lastHeartbeat = agentInfo.lastHeartbeat.get()
            val timeSinceLastHeartbeat = now - lastHeartbeat
            
            if (timeSinceLastHeartbeat > config.unhealthyThresholdMs) {
                // Mark agent as unhealthy
                // Implementation details
            }
            
            if (timeSinceLastHeartbeat > config.lostThresholdMs) {
                // Mark agent as lost
                // Implementation details
            }
        }
    }
}

data class HealthMonitorConfig(
    val healthCheckIntervalMs: Long = 30000,
    val unhealthyThresholdMs: Long = 60000,
    val lostThresholdMs: Long = 300000
)
```

## Task Distribution and Scheduling

### 1. Task Distribution Service

```kotlin
class TaskDistributionService(
    private val natsConnection: Connection,
    private val taskScheduler: TaskScheduler
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Start task distribution
    fun start() {
        // Subscribe to task submission
        val dispatcher = natsConnection.createDispatcher { message ->
            scope.launch {
                handleTaskSubmission(message)
            }
        }
        
        dispatcher.subscribe("mcp.orchestrator.task.submit")
        
        // Subscribe to task results
        dispatcher.subscribe("mcp.agent.*.result") { message ->
            scope.launch {
                handleTaskResult(message)
            }
        }
    }
    
    // Handle task submission
    private suspend fun handleTaskSubmission(message: Message) {
        try {
            val taskSubmission = Json.decodeFromString<TaskSubmissionMessage>(
                String(message.data)
            )
            
            val taskId = taskScheduler.enqueueTask(
                taskSubmission.task,
                taskSubmission.preferredAgentId
            )
            
            // Respond with task ID
            if (message.replyTo != null) {
                val response = TaskSubmissionResponse(
                    messageId = UUID.randomUUID().toString(),
                    timestamp = System.currentTimeMillis(),
                    taskId = taskId
                )
                
                natsConnection.publish(
                    message.replyTo,
                    Json.encodeToString(response).toByteArray()
                )
            }
        } catch (e: Exception) {
            // Log error and continue
        }
    }
    
    // Handle task result
    private suspend fun handleTaskResult(message: Message) {
        try {
            val resultMessage = Json.decodeFromString<TaskResultMessage>(
                String(message.data)
            )
            
            taskScheduler.completeTask(
                resultMessage.result.taskId,
                resultMessage.result
            )
        } catch (e: Exception) {
            // Log error and continue
        }
    }
}

data class TaskSubmissionMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val task: AgentTask,
    val preferredAgentId: String? = null
) : NatsMessage

data class TaskSubmissionResponse(
    override val messageId: String,
    override val timestamp: Long,
    val taskId: String
) : NatsMessage
```

### 2. Task Assignment Service

```kotlin
class TaskAssignmentService(
    private val natsConnection: Connection,
    private val agentRegistry: ConcurrentHashMap<String, AgentInfo>
) {
    // Assign task to agent
    suspend fun assignTask(agentId: String, task: AgentTask) {
        val message = TaskAssignmentMessage(
            task = task
        )
        
        // Publish task to agent's task topic
        natsConnection.publish(
            "mcp.agent.$agentId.task",
            Json.encodeToString(message).toByteArray()
        )
        
        // Update agent state in registry
        agentRegistry[agentId]?.stateMachine?.process(
            AgentEvent.Process(task)
        )
    }
}
```

## Implementation Guidelines

### 1. NATS Integration Best Practices

1. **Serialization Efficiency**: Use Kotlin Serialization for type-safe and efficient message encoding/decoding
2. **Topic Design**: Follow consistent naming patterns for topics to simplify subscription management
3. **Message Correlation**: Include correlation IDs for request-reply patterns
4. **Error Handling**: Implement error handling for all NATS operations
5. **Reconnection Logic**: Configure proper reconnection settings to handle network disruptions

### 2. Orchestrator Implementation Considerations

1. **Thread Safety**: Use thread-safe collections for shared data structures
2. **Resource Management**: Properly clean up resources during shutdown
3. **Coroutine Context**: Use appropriate coroutine dispatchers for CPU-bound vs. I/O-bound operations
4. **Supervisor Job**: Use supervisor jobs to prevent cascading failures
5. **Graceful Degradation**: Design the system to function with partial agent availability

### 3. Scaling Considerations

1. **Task Queue Management**: Implement backpressure mechanisms to handle task submission spikes
2. **Agent Load Balancing**: Distribute tasks based on agent capabilities and current load
3. **Resource Limits**: Implement configurable limits for concurrent tasks and queue sizes
4. **Timeout Management**: Handle tasks that exceed their execution time limits

## Next Steps

After implementing the Orchestrator and NATS messaging integration:

1. Create a simple Camera Integration Agent leveraging the core interfaces
2. Implement basic health monitoring for all components
3. Develop the API layer for external system interactions
4. Create a simple client for testing the infrastructure