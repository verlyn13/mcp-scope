package com.example.mcp.models

import kotlinx.serialization.Serializable

/**
 * Represents a discrete unit of work for an agent to process.
 */
@Serializable
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

/**
 * Priority levels for task scheduling.
 */
@Serializable
enum class TaskPriority {
    LOW, NORMAL, HIGH, CRITICAL
}

/**
 * Represents the outcome of a task execution.
 */
@Serializable
data class TaskResult(
    // ID of the task this is a result for
    val taskId: String,
    
    // Status code indicating success or failure
    val status: TaskStatus,
    
    // Optional result data
    val result: String? = null,
    
    // Error message if status is FAILED
    val errorMessage: String? = null,
    
    // Time taken to execute in milliseconds
    val executionTimeMs: Long,
    
    // Timestamp when the result was created
    val completedAt: Long = System.currentTimeMillis()
)

/**
 * Possible states of a task in the system.
 */
@Serializable
enum class TaskStatus {
    PENDING,      // Task is waiting to be processed
    IN_PROGRESS,  // Task is currently being processed
    COMPLETED,    // Task completed successfully
    FAILED,       // Task failed to complete
    CANCELLED,    // Task was cancelled before completion
    TIMEOUT       // Task exceeded its allowed execution time
}