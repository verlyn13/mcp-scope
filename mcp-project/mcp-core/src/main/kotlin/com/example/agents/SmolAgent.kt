package com.example.agents

import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import com.example.mcp.fsm.AgentStateMachine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.util.UUID
import java.util.concurrent.atomic.AtomicInteger

/**
 * A lightweight agent implementation with minimal dependencies.
 * 
 * SmolAgent provides a stripped-down implementation of the McpAgent interface
 * for development, testing, or resource-constrained environments. It leverages
 * the FSM framework but minimizes external dependencies and resource usage.
 */
class SmolAgent(
    override val agentId: String = UUID.randomUUID().toString(),
    override val agentType: String = "smol",
    override val capabilities: Set<Capability> = emptySet(),
    private val taskHandler: (AgentTask) -> TaskResult? = null
) : McpAgent {

    private val logger = LoggerFactory.getLogger("SmolAgent[$agentId]")
    private val stateMachine = AgentStateMachine(this)
    private val tasksCompleted = AtomicInteger(0)
    private val tasksFailed = AtomicInteger(0)
    private var currentTask: AgentTask? = null
    private var lastActiveTimestamp: Long? = null
    private val scope = CoroutineScope(Job() + Dispatchers.Default)
    
    /**
     * Initialize the agent with minimal setup.
     */
    override suspend fun initialize(): Boolean {
        logger.info("Initializing SmolAgent: $agentId")
        return true
    }
    
    /**
     * Process a task using the provided handler or default behavior.
     */
    override suspend fun processTask(task: AgentTask): TaskResult {
        val startTime = System.currentTimeMillis()
        logger.info("Processing task: ${task.taskId}")
        
        currentTask = task
        lastActiveTimestamp = startTime
        
        try {
            // Use the provided task handler if available, otherwise use default behavior
            val result = taskHandler?.invoke(task) ?: createDefaultResult(task, startTime)
            
            // Update stats based on result
            if (result.status == TaskStatus.COMPLETED) {
                tasksCompleted.incrementAndGet()
            } else if (result.status == TaskStatus.FAILED) {
                tasksFailed.incrementAndGet()
            }
            
            // Clear current task
            currentTask = null
            lastActiveTimestamp = System.currentTimeMillis()
            
            return result
        } catch (e: Exception) {
            logger.error("Error processing task ${task.taskId}", e)
            tasksFailed.incrementAndGet()
            currentTask = null
            lastActiveTimestamp = System.currentTimeMillis()
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.FAILED,
                errorMessage = "Exception during processing: ${e.message}",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
        }
    }
    
    /**
     * Get the current agent status.
     */
    override fun getStatus(): AgentStatus {
        return AgentStatus(
            agentId = agentId,
            state = stateMachine.getCurrentState().toString(),
            healthy = true,
            metrics = mapOf(
                "memory.usage_mb" to Runtime.getRuntime().totalMemory().toDouble() / (1024 * 1024),
                "tasks.completed" to tasksCompleted.get().toDouble(),
                "tasks.failed" to tasksFailed.get().toDouble()
            ),
            currentTask = currentTask,
            lastActiveTimestamp = lastActiveTimestamp,
            tasksCompleted = tasksCompleted.get(),
            tasksFailed = tasksFailed.get(),
            lastHeartbeatMs = System.currentTimeMillis()
        )
    }
    
    /**
     * Minimal shutdown implementation.
     */
    override suspend fun shutdown() {
        logger.info("Shutting down SmolAgent: $agentId")
        // No resources to release in this minimal implementation
    }
    
    /**
     * Handle an error condition.
     */
    override suspend fun handleError(error: Exception): Boolean {
        logger.error("Error in SmolAgent", error)
        // SmolAgent has minimal error handling - just log and return false
        return false
    }
    
    /**
     * Process an FSM event.
     */
    fun processEvent(event: AgentEvent) {
        logger.debug("Processing event: $event")
        stateMachine.process(event)
    }
    
    /**
     * Create a default task result when no handler is provided.
     */
    private fun createDefaultResult(task: AgentTask, startTime: Long): TaskResult {
        return TaskResult(
            taskId = task.taskId,
            status = TaskStatus.COMPLETED,
            result = "Task processed by SmolAgent",
            executionTimeMs = System.currentTimeMillis() - startTime
        )
    }
    
    companion object {
        /**
         * Create a SmolAgent with a simple lambda task handler.
         */
        fun withHandler(
            handler: (AgentTask) -> TaskResult,
            agentId: String = UUID.randomUUID().toString(),
            agentType: String = "smol",
            capabilities: Set<Capability> = emptySet()
        ): SmolAgent {
            return SmolAgent(agentId, agentType, capabilities, handler)
        }
    }
}