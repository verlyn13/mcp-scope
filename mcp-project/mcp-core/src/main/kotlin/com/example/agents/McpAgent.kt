package com.example.agents

import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult

/**
 * Core interface that all agents must implement to participate in the MCP platform.
 */
interface McpAgent {
    // Unique identifier for the agent instance
    val agentId: String
    
    // Type of agent (e.g., "camera", "build", "code-gen")
    val agentType: String
    
    // Set of capabilities this agent provides
    val capabilities: Set<Capability>
    
    // Initialize the agent and prepare resources
    suspend fun initialize(): Boolean
    
    // Process a specific task and return the result
    suspend fun processTask(task: AgentTask): TaskResult
    
    // Get the current status of the agent
    fun getStatus(): AgentStatus
    
    // Release resources and perform cleanup
    suspend fun shutdown()
    
    // Handle an error condition
    suspend fun handleError(error: Exception): Boolean
}

/**
 * Defines specific functionalities an agent can perform.
 */
sealed class Capability {
    // Camera-related capabilities
    object CameraDetection : Capability()
    object CameraConfiguration : Capability()
    object FrameCapture : Capability()
    
    // Code generation capabilities
    object BoilerplateGeneration : Capability()
    object JniBindingGeneration : Capability()
    
    // Build system capabilities
    object GradleExecution : Capability()
    object DependencyManagement : Capability()
    
    // Testing capabilities
    object UnitTestExecution : Capability()
    object IntegrationTestExecution : Capability()
    
    // Static analysis capabilities
    object CodeQualityAnalysis : Capability()
    object SecurityAnalysis : Capability()
    
    // Documentation capabilities
    object ApiDocGeneration : Capability()
    object UsageExampleGeneration : Capability()
    
    // Custom capability with name
    data class Custom(val name: String) : Capability()
}