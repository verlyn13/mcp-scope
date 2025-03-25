package com.example.mcp.orchestration

import com.example.mcp.NatsConnectionManager
import com.example.mcp.messaging.TaskAssignmentMessage
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
import java.util.PriorityQueue
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Manages task scheduling, execution, and completion respecting priorities and dependencies.
 */
class TaskScheduler(
    private val maxConcurrentTasks: Int,
    private val natsManager: NatsConnectionManager? = null
) {
    private val logger = LoggerFactory.getLogger(TaskScheduler::class.java)
    
    // Queue of pending tasks, ordered by priority
    private val taskQueue = PriorityQueue<QueuedTask> { a, b ->
        // Higher priority values indicate higher priority tasks
        b.task.priority.ordinal - a.task.priority.ordinal
    }
    
    // Currently executing tasks
    private val activeTasks = ConcurrentHashMap<String, QueuedTask>()
    
    // Tasks that are waiting for dependencies
    private val waitingTasks = ConcurrentHashMap<String, QueuedTask>()
    
    // Completed task results
    private val completedTasks = ConcurrentHashMap<String, TaskResult>()
    
    // Coroutine scope for scheduler operations
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Task processing job
    private var processingJob: Job? = null
    
    // Timeout check job
    private var timeoutJob: Job? = null
    
    /**
     * Start the task scheduler.
     */
    fun start() {
        logger.info("Starting task scheduler")
        
        // Start task processing job
        processingJob = scope.launch {
            while (isActive) {
                if (activeTasks.size < maxConcurrentTasks && taskQueue.isNotEmpty()) {
                    processNextTask()
                }
                delay(100) // Small delay to prevent tight CPU loop
            }
        }
        
        // Start timeout checking job
        timeoutJob = scope.launch {
            while (isActive) {
                checkTaskTimeouts()
                delay(1000) // Check timeouts every second
            }
        }
    }
    
    /**
     * Stop the task scheduler.
     */
    fun stop() {
        logger.info("Stopping task scheduler")
        processingJob?.cancel()
        timeoutJob?.cancel()
        scope.cancel()
    }
    
    /**
     * Enqueue a new task for execution.
     * 
     * @param task The task to enqueue
     * @param targetAgentId Optional agent ID to target for this task
     * @return The task ID
     */
    suspend fun enqueueTask(
        task: AgentTask, 
        targetAgentId: String? = null
    ): String {
        val taskId = task.taskId.ifEmpty { UUID.randomUUID().toString() }
        
        // Create a new task with the generated ID if needed
        val updatedTask = if (task.taskId.isEmpty()) {
            task.copy(taskId = taskId)
        } else {
            task
        }
        
        logger.info("Enqueueing task: $taskId, priority: ${task.priority}, targetAgent: $targetAgentId")
        
        val queuedTask = QueuedTask(
            task = updatedTask,
            targetAgentId = targetAgentId
        )
        
        // If task has dependencies, check if they're satisfied
        if (updatedTask.dependencies.isNotEmpty()) {
            if (canExecuteTask(updatedTask)) {
                taskQueue.add(queuedTask)
            } else {
                waitingTasks[taskId] = queuedTask
                logger.info("Task $taskId is waiting for dependencies to complete")
            }
        } else {
            taskQueue.add(queuedTask)
        }
        
        return taskId
    }
    
    /**
     * Process the next available task from the queue.
     */
    suspend fun processNextTask() {
        val queuedTask = taskQueue.poll() ?: return
        val task = queuedTask.task
        
        logger.info("Processing task: ${task.taskId}")
        
        // Find an appropriate agent for this task
        val agentId = queuedTask.targetAgentId ?: findAgentForTask(task)
        
        if (agentId == null) {
            logger.warn("No suitable agent found for task ${task.taskId}")
            // Re-queue the task with a delay
            scope.launch {
                delay(5000) // Wait 5 seconds before re-queueing
                taskQueue.add(queuedTask)
            }
            return
        }
        
        // Add task to active tasks
        activeTasks[task.taskId] = queuedTask
        
        // Send task to agent if we have a NATS manager
        natsManager?.let { nats ->
            nats.publish(
                NatsConnectionManager.Topics.agentTask(agentId),
                TaskAssignmentMessage(task = task)
            )
        }
    }
    
    /**
     * Complete a task and process any dependent tasks.
     * 
     * @param taskId The ID of the completed task
     * @param result The result of the task execution
     */
    suspend fun completeTask(taskId: String, result: TaskResult) {
        logger.info("Completing task: $taskId with status: ${result.status}")
        
        // Remove from active tasks
        activeTasks.remove(taskId)
        
        // Store the result
        completedTasks[taskId] = result
        
        // Check if any waiting tasks can now be executed
        val tasksToQueue = mutableListOf<QueuedTask>()
        
        waitingTasks.values.filter { queuedTask ->
            canExecuteTask(queuedTask.task)
        }.forEach { queuedTask ->
            waitingTasks.remove(queuedTask.task.taskId)
            tasksToQueue.add(queuedTask)
        }
        
        // Queue the tasks that are now ready
        tasksToQueue.forEach { taskQueue.add(it) }
    }
    
    /**
     * Get the number of active tasks.
     */
    fun getActiveTaskCount(): Int = activeTasks.size
    
    /**
     * Get the number of queued tasks.
     */
    fun getQueuedTaskCount(): Int = taskQueue.size + waitingTasks.size
    
    /**
     * Check if a task can be executed (dependencies satisfied).
     */
    private fun canExecuteTask(task: AgentTask): Boolean {
        if (task.dependencies.isEmpty()) {
            return true
        }
        
        return task.dependencies.all { dependencyId ->
            val result = completedTasks[dependencyId]
            result != null && result.status == TaskStatus.COMPLETED
        }
    }
    
    /**
     * Check for and handle task timeouts.
     */
    private suspend fun checkTaskTimeouts() {
        val now = System.currentTimeMillis()
        
        // Check active tasks for timeouts
        val timedOutTasks = activeTasks.entries
            .filter { (_, queuedTask) ->
                val task = queuedTask.task
                
                // Check if task has a timeout and has exceeded it
                val hasTimeoutExceeded = task.timeoutMs?.let { timeout ->
                    (now - queuedTask.startTime) > timeout
                } ?: false
                
                // Check if task has a deadline and has exceeded it
                val hasDeadlineExceeded = task.deadlineTimestamp?.let { deadline ->
                    now > deadline
                } ?: false
                
                hasTimeoutExceeded || hasDeadlineExceeded
            }
            .map { it.key }
            
        // Handle timed out tasks
        timedOutTasks.forEach { taskId ->
            logger.warn("Task $taskId has timed out")
            val queuedTask = activeTasks[taskId] ?: return@forEach
            
            // Create a timeout result
            val result = TaskResult(
                taskId = taskId,
                status = TaskStatus.TIMEOUT,
                errorMessage = "Task exceeded its allowed execution time",
                executionTimeMs = now - queuedTask.startTime
            )
            
            // Complete the task with the timeout result
            completeTask(taskId, result)
        }
    }
    
    /**
     * Find an appropriate agent for a task.
     * In a real implementation, this would use agent capabilities and load balancing.
     * 
     * @param task The task to find an agent for
     * @param preferredAgentId Optional preferred agent ID
     * @return The selected agent ID, or null if none is suitable
     */
    private fun findAgentForTask(
        task: AgentTask, 
        preferredAgentId: String? = null
    ): String? {
        // This is a stub implementation
        // In a real system, this would query the agent registry and match capabilities
        return preferredAgentId
    }
}

/**
 * Represents a task queued for execution.
 */
data class QueuedTask(
    val task: AgentTask,
    val targetAgentId: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val startTime: Long = System.currentTimeMillis()
)