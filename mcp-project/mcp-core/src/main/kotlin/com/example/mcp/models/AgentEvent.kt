package com.example.mcp.models

sealed class AgentEvent {
    object Initialize : AgentEvent()
    data class Process(val task: AgentTask?) : AgentEvent()
    data class Error(val exception: Exception) : AgentEvent()
    object Shutdown : AgentEvent()
}