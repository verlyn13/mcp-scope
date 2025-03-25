package com.example.mcp.messaging

import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * Base interface for all NATS messages in the MCP system.
 */
interface NatsMessage {
    val messageId: String
    val timestamp: Long
}

/**
 * Agent registration data used for the registration process.
 */
@Serializable
data class AgentRegistration(
    val agentId: String,
    val agentType: String,
    val capabilities: List<String>,
    val metadata: Map<String, String> = emptyMap()
)

/**
 * Agent registration message sent when an agent wants to join the system.
 */
@Serializable
data class AgentRegistrationMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val registration: AgentRegistration
) : NatsMessage

/**
 * Task assignment message sent from orchestrator to an agent.
 */
@Serializable
data class TaskAssignmentMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val task: AgentTask
) : NatsMessage

/**
 * Task result message sent from an agent back to the orchestrator.
 */
@Serializable
data class TaskResultMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val result: TaskResult
) : NatsMessage

/**
 * Agent status message sent periodically to report health and state.
 */
@Serializable
data class AgentStatusMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val status: AgentStatus
) : NatsMessage

/**
 * Heartbeat message to track agent liveness.
 */
@Serializable
data class HeartbeatMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val agentId: String,
    val metrics: Map<String, Double> = emptyMap()
) : NatsMessage

/**
 * Message for submitting a task to the orchestrator.
 */
@Serializable
data class TaskSubmissionMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val task: AgentTask,
    val preferredAgentId: String? = null
) : NatsMessage

/**
 * Response message for task submission confirmation.
 */
@Serializable
data class TaskSubmissionResponse(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val taskId: String
) : NatsMessage

/**
 * System-wide event message for broadcasting significant events.
 */
@Serializable
data class SystemEventMessage(
    override val messageId: String = UUID.randomUUID().toString(),
    override val timestamp: Long = System.currentTimeMillis(),
    val eventType: SystemEventType,
    val payload: String? = null
) : NatsMessage

/**
 * Types of system-wide events that can be broadcast.
 */
@Serializable
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