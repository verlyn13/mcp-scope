package com.example.mcp.models

import kotlinx.serialization.Serializable

/**
 * Represents the current state and health of an agent.
 */
@Serializable
data class AgentStatus(
    // Agent's unique identifier
    val agentId: String,
    
    // Agent's current state
    val state: String,
    
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
    val tasksFailed: Int = 0,
    
    // Last heartbeat timestamp
    val lastHeartbeatMs: Long = System.currentTimeMillis()
)