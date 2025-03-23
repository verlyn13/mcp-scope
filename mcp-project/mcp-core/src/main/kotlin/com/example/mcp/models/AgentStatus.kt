package com.example.mcp.models

import kotlinx.serialization.Serializable

@Serializable
data class AgentStatus(
    val agentId: String,
    val state: String,
    val healthCheck: Boolean,
    val activeTaskCount: Int = 0,
    val lastHeartbeatMs: Long = System.currentTimeMillis()
)