package com.example.mcp.models

sealed class AgentState {
    object Idle : AgentState()
    object Initializing : AgentState()
    object Processing : AgentState()
    object Error : AgentState()
    object ShuttingDown : AgentState()
}