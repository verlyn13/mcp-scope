package com.example.agents

import com.example.mcp.NatsConnectionManager
import com.example.mcp.fsm.AgentStateMachine
import com.example.mcp.messaging.AgentRegistrationMessage
import com.example.mcp.messaging.AgentStatusMessage
import com.example.mcp.messaging.HeartbeatMessage
import com.example.mcp.messaging.TaskResultMessage
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Base implementation of the McpAgent interface that handles common agent functionality.
 * 
 * This class provides a foundation for specific agent implementations by handling:
 * - State management via FSM
 * - NATS messaging integration
 * - Registration with orchestrator
 * - Heartbeat mechanism
 * - Task processing lifecycle
 */
abstract class BaseAgent(
    override val agentId: String = UUID.randomUUID().toString(),
    override val agentType: String,
    override val capabilities: Set<Capability>,
    private val natsUrl: String = "nats://localhost:4222"
) : McpAgent {
    
    private val logger = LoggerFactory.getLogger("${this.javaClass.simpleName}[$agentId]")
    
    // FSM for state management
    protected lateinit var stateMachine: AgentStateMachine
    
    // NATS connection manager
    protected lateinit var natsManager: NatsConnectionManager
    
    // Coroutine scope for agent operations
    protected val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Heartbeat job
    private var heartbeatJob: Job? = null
    
    // Status tracking
    private val tasksCompleted = AtomicInteger(0)
    private val tasksFailed = AtomicInteger(0)
    private var currentTask: AgentTask? = null
    private var lastActiveTimestamp: Long? = null
    
    // Metrics for tracking resource usage
    protected val metrics = ConcurrentHashMap<String, Double>()
    
    /**
     * Initialize the agent, setting up NATS connection, FSM, and registering with orchestrator.
     * 
     * @return True if initialization was successful, false otherwise
     */
    override suspend fun initialize(): Boolean {
        try {
            logger.info("Initializing $agentType agent")
            
            // Create state machine
            stateMachine = AgentStateMachine(this)
            
            // Setup state change listener
            stateMachine.onStateChanged = { oldState, newState ->
                onStateChanged(oldState, newState)
            }
            
            // Initialize NATS
            initializeNats()
            
            // Register with orchestrator
            registerWithOrchestrator()
            
            // Start heartbeat
            startHeartbeat()
            
            // Perform agent-specific initialization
            val success = doInitialize()
            
            logger.info("Initialization ${if (success) "successful" else "failed"}")
            return success
        } catch (e: Exception) {
            logger.error("Initialization failed", e)
            return false
        }
    }
    
    /**
     * Process a specific task and return the result.
     * 
     * @param task The task to process
     * @return The result of the task execution
     */
    override suspend fun processTask(task: AgentTask): TaskResult {
        val startTime = System.currentTimeMillis()
        logger.info("Processing task: ${task.taskId}, type: ${task.taskType}")
        
        currentTask = task
        lastActiveTimestamp = startTime
        updateAgentStatus()
        
        try {
            // Process the task with timing
            val result = doProcessTask(task)
            
            // Update stats based on result
            if (result.status == TaskStatus.COMPLETED) {
                tasksCompleted.incrementAndGet()
            } else if (result.status == TaskStatus.FAILED) {
                tasksFailed.incrementAndGet()
            }
            
            // Clear current task
            currentTask = null
            lastActiveTimestamp = System.currentTimeMillis()
            updateAgentStatus()
            
            // Send result via NATS
            natsManager.publish(
                NatsConnectionManager.Topics.agentResult(agentId),
                TaskResultMessage(result = result)
            )
            
            // Return the result
            return result
        } catch (e: Exception) {
            logger.error("Error processing task ${task.taskId}", e)
            
            // Increment failure count
            tasksFailed.incrementAndGet()
            
            // Clear current task
            currentTask = null
            lastActiveTimestamp = System.currentTimeMillis()
            updateAgentStatus()
            
            // Create and send error result
            val errorResult = TaskResult(
                taskId = task.taskId,
                status = TaskStatus.FAILED,
                errorMessage = "Exception during processing: ${e.message}",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
            
            natsManager.publish(
                NatsConnectionManager.Topics.agentResult(agentId),
                TaskResultMessage(result = errorResult)
            )
            
            return errorResult
        }
    }
    
    /**
     * Get the current status of the agent.
     * 
     * @return The current agent status
     */
    override fun getStatus(): AgentStatus {
        return AgentStatus(
            agentId = agentId,
            state = stateMachine.getCurrentState(),
            healthy = stateMachine.getCurrentState() !is AgentState.Error,
            metrics = metrics,
            currentTask = currentTask,
            lastActiveTimestamp = lastActiveTimestamp,
            tasksCompleted = tasksCompleted.get(),
            tasksFailed = tasksFailed.get(),
            lastHeartbeatMs = System.currentTimeMillis()
        )
    }
    
    /**
     * Release resources and perform cleanup.
     */
    override suspend fun shutdown() {
        logger.info("Shutting down $agentType agent")
        
        try {
            // Stop heartbeat
            heartbeatJob?.cancel()
            
            // Perform agent-specific shutdown
            doShutdown()
            
            // Close NATS connection
            if (::natsManager.isInitialized) {
                natsManager.close()
            }
            
            // Cancel coroutine scope
            scope.cancel()
            
            logger.info("Shutdown completed successfully")
        } catch (e: Exception) {
            logger.error("Error during shutdown", e)
        }
    }
    
    /**
     * Handle an error condition.
     * 
     * @param error The exception that caused the error
     * @return True if the error was handled and the agent can recover, false otherwise
     */
    override suspend fun handleError(error: Exception): Boolean {
        logger.error("Handling error", error)
        
        try {
            // Attempt agent-specific error handling
            val recovered = doHandleError(error)
            
            if (recovered) {
                logger.info("Successfully recovered from error")
            } else {
                logger.warn("Could not recover from error")
            }
            
            return recovered
        } catch (e: Exception) {
            logger.error("Error during error handling", e)
            return false
        }
    }
    
    /**
     * Process an FSM event.
     * 
     * @param event The event to process
     */
    fun processEvent(event: AgentEvent) {
        logger.debug("Processing event: $event")
        stateMachine.process(event)
    }
    
    // Protected methods for agent-specific implementations
    
    /**
     * Agent-specific initialization logic.
     * 
     * @return True if initialization was successful, false otherwise
     */
    protected abstract suspend fun doInitialize(): Boolean
    
    /**
     * Agent-specific task processing logic.
     * 
     * @param task The task to process
     * @return The result of the task execution
     */
    protected abstract suspend fun doProcessTask(task: AgentTask): TaskResult
    
    /**
     * Agent-specific shutdown logic.
     */
    protected abstract suspend fun doShutdown()
    
    /**
     * Agent-specific error handling logic.
     * 
     * @param error The exception that caused the error
     * @return True if the error was handled and the agent can recover, false otherwise
     */
    protected abstract suspend fun doHandleError(error: Exception): Boolean
    
    /**
     * Called when the agent's state changes.
     * 
     * @param oldState The previous state
     * @param newState The new state
     */
    protected open fun onStateChanged(oldState: AgentState, newState: AgentState) {
        logger.info("State changed from $oldState to $newState")
        updateAgentStatus()
    }
    
    /**
     * Collect agent-specific metrics.
     * 
     * @return Map of metric name to value
     */
    protected open fun collectMetrics(): Map<String, Double> {
        // Default implementation with basic JVM metrics
        val runtime = Runtime.getRuntime()
        val usedMemory = (runtime.totalMemory() - runtime.freeMemory()).toDouble() / (1024 * 1024)
        val totalMemory = runtime.totalMemory().toDouble() / (1024 * 1024)
        val cpuCount = runtime.availableProcessors()
        
        return mapOf(
            "memory.used_mb" to usedMemory,
            "memory.total_mb" to totalMemory,
            "memory.usage_percent" to (usedMemory / totalMemory * 100.0),
            "cpu.count" to cpuCount.toDouble()
        )
    }
    
    // Private implementation methods
    
    /**
     * Initialize NATS connection and subscriptions.
     */
    private fun initializeNats() {
        logger.info("Initializing NATS connection to $natsUrl")
        natsManager = NatsConnectionManager()
        natsManager.connect(natsUrl)
        
        // Subscribe to task assignments
        natsManager.subscribeWithHandler<AgentTask>(
            NatsConnectionManager.Topics.agentTask(agentId)
        ) { task ->
            scope.launch {
                processEvent(AgentEvent.Process(task))
                processTask(task)
            }
        }
    }
    
    /**
     * Register the agent with the orchestrator.
     */
    private fun registerWithOrchestrator() {
        logger.info("Registering with orchestrator")
        
        val registration = com.example.mcp.messaging.AgentRegistration(
            agentId = agentId,
            agentType = agentType,
            capabilities = capabilities.map { 
                when (it) {
                    is Capability.Custom -> it.name
                    else -> it.javaClass.simpleName
                }
            }
        )
        
        natsManager.publish(
            NatsConnectionManager.Topics.AGENT_REGISTER,
            AgentRegistrationMessage(registration = registration)
        )
    }
    
    /**
     * Start sending periodic heartbeats.
     */
    private fun startHeartbeat() {
        logger.info("Starting heartbeat")
        
        heartbeatJob = scope.launch {
            while (isActive) {
                try {
                    // Update metrics
                    metrics.clear()
                    metrics.putAll(collectMetrics())
                    
                    // Send heartbeat
                    natsManager.publish(
                        NatsConnectionManager.Topics.agentHeartbeat(agentId),
                        HeartbeatMessage(
                            agentId = agentId,
                            metrics = metrics
                        )
                    )
                    
                    // Send status update
                    updateAgentStatus()
                } catch (e: Exception) {
                    logger.error("Error sending heartbeat", e)
                }
                
                delay(30000) // 30 seconds
            }
        }
    }
    
    /**
     * Update and publish the agent's status.
     */
    private fun updateAgentStatus() {
        try {
            val status = getStatus()
            
            natsManager.publish(
                NatsConnectionManager.Topics.agentStatus(agentId),
                AgentStatusMessage(status = status)
            )
        } catch (e: Exception) {
            logger.error("Error updating agent status", e)
        }
    }
}