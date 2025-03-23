package com.example.mcp.models

import kotlinx.serialization.Serializable

@Serializable
data class AgentTask(
    val taskId: String,
    val agentType: String,
    val payload: String,
    val priority: Int = 0,
    val timeoutMs: Long = 30000
)

@Serializable
data class TaskResult(
    val taskId: String,
    val status: TaskStatus,
    val result: String? = null,
    val error: String? = null,
    val processingTimeMs: Long? = null
)

enum class TaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    FAILED
}