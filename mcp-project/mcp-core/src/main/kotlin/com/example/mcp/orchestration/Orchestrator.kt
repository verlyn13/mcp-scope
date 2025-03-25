package com.example.mcp.orchestration

import com.example.agents.McpAgent
import com.example.mcp.NatsConnectionManager
import com.example.mcp.fsm.AgentStateMachine
import com.example.mcp.messaging.*
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import io.nats.client.Connection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/**
 * Central orchestration component responsible for managing agent lifecycles, 
 * distributing tasks, and monitoring system health.
 */
class Orchestrator(
    private val natsConnection: Connection,
    private val config: OrchestratorConfig = OrchestratorConfig()
) {
    private val logger = LoggerFactory.getLogger(Orchestrator::class.java)
    
    // Registry of all active agents
    private val agentRegistry = ConcurrentHashMap<String, AgentInfo>()
    
    // Task scheduler for managing task execution
    private val taskScheduler = TaskScheduler(config.maxConcurrentTasks)
    
    // Coroutine scope for orchestrator operations
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // NATS connection manager for messaging
    private val natsManager = NatsConnectionManager()
    
    // Health check job
    private var healthCheckJob: Job? = null
    
    // Current status of the orchestrator
    private val status = AtomicReference(OrchestratorStatus.INITIALIZING)
    
    /**
     * Initialize the orchestrator and setup necessary components.
     */
    suspend fun start() {
        logger.info("Starting Orchestrator")
        status.set(OrchestratorStatus.INITIALIZING)
        
        // Setup subscriptions
        setupSubscriptions()
        
        // Start health checks
        startHealthChecks()
        
        // Load persistent state if enabled
        if (config.enablePersistence) {
            loadPersistentState()
        }
        
        // Start the task scheduler
        taskScheduler.start()
        
        // Broadcast orchestrator started event
        broadcastSystemEvent(SystemEventType.ORCHESTRATOR_STARTED)
        
        status.set(OrchestratorStatus.RUNNING)
        logger.info("Orchestrator started successfully")
    }
    
    /**
     * Register a new agent with the orchestrator.
     * 
     * @param registration The agent registration details
     * @return True if registration was successful
     */
    suspend fun registerAgent(registration: AgentRegistration): Boolean {
        logger.info("Registering agent: ${registration.agentId} of type ${registration.agentType}")
        
        // Check if agent is already registered
        if (agentRegistry.containsKey(registration.agentId)) {
            logger.warn("Agent ${registration.agentId} is already registered")
            return false
        }
        
        // Create agent info and add to registry
        val agentInfo = AgentInfo(
            registration = registration,
            stateMachine = createDummyStateMachine(registration.agentId),  // In reality, would create proper FSM
            lastHeartbeat = AtomicLong(System.currentTimeMillis())
        )
        
        agentRegistry[registration.agentId] = agentInfo
        
        // Broadcast agent registration event
        broadcastSystemEvent(
            SystemEventType.AGENT_REGISTERED, 
            "Agent ${registration.agentId} registered"
        )
        
        // Send confirmation to agent
        natsManager.publish(
            NatsConnectionManager.Topics.agentStatus(registration.agentId),
            AgentStatusMessage(
                status = AgentStatus(
                    agentId = registration.agentId,
                    state = AgentState.Idle,
                    healthy = true
                )
            )
        )
        
        logger.info("Agent ${registration.agentId} registered successfully")
        return true
    }
    
    /**
     * Submit a task for execution by an appropriate agent.
     * 
     * @param task The task to execute
     * @return The task ID for tracking
     */
    suspend fun submitTask(task: AgentTask): String {
        logger.info("Submitting task: ${task.taskId}")
        
        // Enqueue the task in the scheduler
        val taskId = taskScheduler.enqueueTask(task)
        
        // Broadcast task submission event
        broadcastSystemEvent(
            SystemEventType.TASK_SUBMITTED,
            "Task $taskId submitted"
        )
        
        return taskId
    }
    
    /**
     * Get the current status of the entire system.
     * 
     * @return SystemStatus object containing system-wide status information
     */
    fun getSystemStatus(): SystemStatus {
        val agentStatuses = agentRegistry.values.map { it.getAgentStatus() }
        
        val healthyCount = agentStatuses.count { it.healthy }
        val unhealthyCount = agentStatuses.size - healthyCount
        
        return SystemStatus(
            orchestratorStatus = status.get().name,
            agentCount = agentRegistry.size,
            activeTaskCount = taskScheduler.getActiveTaskCount(),
            queuedTaskCount = taskScheduler.getQueuedTaskCount(),
            healthyAgentCount = healthyCount,
            unhealthyAgentCount = unhealthyCount,
            agentStatuses = agentStatuses
        )
    }
    
    /**
     * Gracefully shutdown the orchestrator and all agents.
     */
    suspend fun shutdown() {
        logger.info("Initiating orchestrator shutdown sequence")
        status.set(OrchestratorStatus.SHUTTING_DOWN)
        
        // Broadcast shutdown event
        broadcastSystemEvent(SystemEventType.ORCHESTRATOR_STOPPING)
        
        // Cancel health check job
        healthCheckJob?.cancel()
        
        // Stop task scheduler
        taskScheduler.stop()
        
        // Shutdown all agents
        agentRegistry.forEach { (agentId, _) ->
            natsManager.publish(
                NatsConnectionManager.Topics.agentTask(agentId),
                TaskAssignmentMessage(
                    task = AgentTask(
                        taskId = "shutdown-${System.currentTimeMillis()}",
                        taskType = "system.shutdown",
                        priority = TaskPriority.CRITICAL
                    )
                )
            )
        }
        
        // Give agents time to shutdown
        delay(config.shutdownGracePeriodMs)
        
        // Cancel coroutine scope
        scope.cancel()
        
        status.set(OrchestratorStatus.STOPPED)
        logger.info("Orchestrator shutdown complete")
    }
    
    /**
     * Setup NATS subscriptions for handling messages.
     */
    private fun setupSubscriptions() {
        logger.info("Setting up NATS subscriptions")
        
        // Agent registration subscription
        natsManager.subscribeWithHandler<AgentRegistrationMessage>(
            NatsConnectionManager.Topics.AGENT_REGISTER
        ) { message ->
            registerAgent(message.registration)
        }
        
        // Task result subscription
        natsManager.subscribeWithHandler<TaskResultMessage>(
            NatsConnectionManager.Topics.ALL_AGENT_RESULTS
        ) { message ->
            taskScheduler.completeTask(message.result.taskId, message.result)
            
            if (message.result.status == TaskStatus.COMPLETED) {
                broadcastSystemEvent(SystemEventType.TASK_COMPLETED)
            } else if (message.result.status == TaskStatus.FAILED) {
                broadcastSystemEvent(SystemEventType.TASK_FAILED)
            }
        }
        
        // Heartbeat subscription
        natsManager.subscribeWithHandler<HeartbeatMessage>(
            NatsConnectionManager.Topics.ALL_AGENT_HEARTBEATS
        ) { message ->
            agentRegistry[message.agentId]?.let { agentInfo ->
                agentInfo.lastHeartbeat.set(System.currentTimeMillis())
                agentInfo.metrics.putAll(message.metrics)
            }
        }
        
        // Status update subscription
        natsManager.subscribeWithHandler<AgentStatusMessage>(
            NatsConnectionManager.Topics.ALL_AGENT_STATUSES
        ) { message ->
            updateAgentStatus(message.status)
        }
        
        // Task submission subscription
        natsManager.subscribeWithHandler<TaskSubmissionMessage>(
            NatsConnectionManager.Topics.TASK_SUBMIT
        ) { message ->
            submitTask(message.task)
        }
    }
    
    /**
     * Start periodic health checks of all registered agents.
     */
    private fun startHealthChecks() {
        logger.info("Starting agent health checks")
        
        healthCheckJob = scope.launch {
            while (isActive) {
                checkAgentHealth()
                delay(config.healthCheckIntervalMs)
            }
        }
    }
    
    /**
     * Check the health of all registered agents.
     */
    private suspend fun checkAgentHealth() {
        val now = System.currentTimeMillis()
        
        agentRegistry.forEach { (agentId, agentInfo) ->
            val lastHeartbeat = agentInfo.lastHeartbeat.get()
            val timeSinceLastHeartbeat = now - lastHeartbeat
            
            val currentStatus = agentInfo.getAgentStatus()
            
            // Check if agent is unhealthy
            if (timeSinceLastHeartbeat > config.agentTimeoutMs) {
                // Update agent as unhealthy
                val updatedStatus = currentStatus.copy(healthy = false)
                updateAgentStatus(updatedStatus)
                
                logger.warn("Agent $agentId is unresponsive (last heartbeat: $timeSinceLastHeartbeat ms ago)")
                
                // If agent has been unhealthy for too long, mark as lost
                if (timeSinceLastHeartbeat > config.agentTimeoutMs * 3) {
                    logger.error("Agent $agentId considered lost and will be removed from registry")
                    agentRegistry.remove(agentId)
                    broadcastSystemEvent(SystemEventType.AGENT_LOST, "Agent $agentId lost")
                }
            }
        }
    }
    
    /**
     * Load persistent state from storage if enabled.
     */
    private suspend fun loadPersistentState() {
        if (config.persistenceFilePath == null) {
            logger.warn("Persistence enabled but no file path specified")
            return
        }
        
        logger.info("Loading persistent state from ${config.persistenceFilePath}")
        // In a real implementation, this would load state from disk
    }
    
    /**
     * Update the status of an agent in the registry.
     */
    private fun updateAgentStatus(status: AgentStatus) {
        agentRegistry[status.agentId]?.let { agentInfo ->
            // Update agent status
            agentInfo.currentStatus.set(status)
        }
    }
    
    /**
     * Broadcast a system event to all listeners.
     */
    private fun broadcastSystemEvent(eventType: SystemEventType, payload: String? = null) {
        natsManager.publish(
            NatsConnectionManager.Topics.SYSTEM_EVENT,
            SystemEventMessage(
                eventType = eventType,
                payload = payload
            )
        )
    }
    
    /**
     * Create a dummy state machine for testing. 
     * In a real implementation, this would use the actual agent instance.
     */
    private fun createDummyStateMachine(agentId: String): AgentStateMachine {
        // In a real implementation, this would create a proper state machine
        // For now, just return a dummy implementation
        val dummyAgent = object : McpAgent {
            override val agentId = agentId
            override val agentType = "dummy"
            override val capabilities = emptySet<com.example.agents.Capability>()
            
            override suspend fun initialize() = true
            override suspend fun processTask(task: AgentTask) = TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                executionTimeMs = 0
            )
            override fun getStatus() = AgentStatus(
                agentId = agentId,
                state = AgentState.Idle,
                healthy = true
            )
            override suspend fun shutdown() {}
            override suspend fun handleError(error: Exception) = false
        }
        
        return AgentStateMachine(dummyAgent)
    }
    
    /**
     * Agent information stored in the registry.
     */
    inner class AgentInfo(
        val registration: AgentRegistration,
        val stateMachine: AgentStateMachine,
        val lastHeartbeat: AtomicLong = AtomicLong(System.currentTimeMillis()),
        val metrics: ConcurrentHashMap<String, Double> = ConcurrentHashMap(),
        val currentStatus: AtomicReference<AgentStatus> = AtomicReference(
            AgentStatus(
                agentId = registration.agentId,
                state = AgentState.Idle,
                healthy = true
            )
        )
    ) {
        fun getAgentStatus(): AgentStatus = currentStatus.get()
    }
}

/**
 * Configuration for the orchestrator.
 */
data class OrchestratorConfig(
    val maxConcurrentTasks: Int = Runtime.getRuntime().availableProcessors(),
    val healthCheckIntervalMs: Long = 30000,
    val agentTimeoutMs: Long = 60000,
    val enablePersistence: Boolean = false,
    val persistenceFilePath: String? = null,
    val shutdownGracePeriodMs: Long = 5000
)

/**
 * Possible states of the orchestrator.
 */
enum class OrchestratorStatus {
    INITIALIZING,
    RUNNING,
    SHUTTING_DOWN,
    STOPPED
}

/**
 * System-wide status information.
 */
data class SystemStatus(
    val orchestratorStatus: String,
    val agentCount: Int,
    val activeTaskCount: Int,
    val queuedTaskCount: Int,
    val healthyAgentCount: Int,
    val unhealthyAgentCount: Int,
    val agentStatuses: List<AgentStatus>
)