package com.example.mcp.models

import kotlinx.serialization.Serializable

sealed class AgentState {
    // Initial state after agent creation but before initialization
    object Idle : AgentState()
    
    // Agent is preparing resources, connections, and dependencies
    object Initializing : AgentState()
    
    // Agent is actively processing a task
    object Processing : AgentState()
    
    // Agent has encountered an error and may need intervention
    data class Error(val message: String, val exception: Exception? = null) : AgentState()
    
    // Agent is releasing resources and preparing to terminate
    object ShuttingDown : AgentState()
}