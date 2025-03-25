package com.example.mcp.models

import kotlinx.serialization.Serializable

sealed class AgentEvent {
    // Triggers initialization of the agent
    object Initialize : AgentEvent()
    
    // Signals the agent to process a specific task
    data class Process(val task: AgentTask) : AgentEvent()
    
    // Indicates that a task has been completed
    data class Complete(val result: TaskResult) : AgentEvent()
    
    // Signals an error during processing
    data class Error(val exception: Exception, val message: String? = null) : AgentEvent()
    
    // Triggers the shutdown sequence
    object Shutdown : AgentEvent()
    
    // Requests the current status of the agent
    object RequestStatus : AgentEvent()
}