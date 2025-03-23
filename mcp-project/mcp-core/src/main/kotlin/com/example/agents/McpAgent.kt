package com.example.agents

import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult

interface McpAgent {
    val agentId: String
    val capabilities: Set<Capability>
    
    suspend fun processTask(task: AgentTask): TaskResult
    fun getStatus(): AgentStatus
    suspend fun initialize()
    suspend fun shutdown()
}

enum class Capability {
    CAMERA_DETECTION,
    CODE_GENERATION,
    BUILD_SYSTEM,
    TESTING
}