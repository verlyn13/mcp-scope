package com.example.mcp

import com.example.mcp.models.Task
import com.example.mcp.models.TaskSchemas
import com.example.mcp.registry.AgentRegistry
import org.slf4j.LoggerFactory

/**
 * Exception thrown when no agent is available for a task.
 */
class AgentNotFoundException(message: String) : RuntimeException(message)

/**
 * Implementation of the TaskRouter interface.
 *
 * This class is responsible for routing tasks to the appropriate agent based on task type
 * and agent capabilities.
 */
class TaskRouterImpl(private val agentRegistry: AgentRegistry) : TaskRouter {
    
    private val logger = LoggerFactory.getLogger(TaskRouterImpl::class.java)
    
    /**
     * Routes a task to the appropriate agent based on task type and agent capabilities.
     *
     * @param task The task to route
     * @return The agent reference to which the task should be routed
     * @throws AgentNotFoundException if no suitable agent is found
     */
    override fun routeTask(task: Task): AgentRef {
        logger.debug("Routing task of type: ${task.type}")
        
        // Validate task
        val validationErrors = TaskSchemas.validateTask(task)
        if (validationErrors.isNotEmpty()) {
            throw IllegalArgumentException("Invalid task: ${validationErrors.joinToString()}")
        }
        
        // Route based on task type
        return when (task.type) {
            // AI-related tasks routed to python-bridge agent
            "code-generation" -> agentRegistry.getAgentByType("python-bridge") 
                ?: throw AgentNotFoundException("No python-bridge agent available for code generation")
            
            "documentation-generation" -> agentRegistry.getAgentByType("python-bridge")
                ?: throw AgentNotFoundException("No python-bridge agent available for documentation generation")
            
            "uvc-analysis" -> agentRegistry.getAgentByType("python-bridge")
                ?: throw AgentNotFoundException("No python-bridge agent available for UVC analysis")
            
            // Camera-related tasks
            "uvc-camera" -> agentRegistry.getAgentByType("camera-integration")
                ?: throw AgentNotFoundException("No camera-integration agent available")
            
            // Data analysis tasks
            "data-analysis" -> agentRegistry.getAgentByType("data-processor")
                ?: throw AgentNotFoundException("No data-processor agent available")
            
            // Fall back to default routing for other task types
            else -> defaultRouting(task)
        }
    }
    
    /**
     * Default routing strategy when no specific route is defined.
     * Attempts to find an agent with matching capabilities.
     *
     * @param task The task to route
     * @return The agent reference to which the task should be routed
     * @throws AgentNotFoundException if no suitable agent is found
     */
    fun defaultRouting(task: Task): AgentRef {
        logger.debug("Using default routing for task type: ${task.type}")
        
        // Try to find an agent that explicitly supports this task type
        val agentsByCapability = agentRegistry.getAgentsByCapability(task.type)
        if (agentsByCapability.isNotEmpty()) {
            // For simplicity, return the first matching agent
            // In a production environment, consider load balancing or other selection criteria
            return agentsByCapability.first()
        }
        
        // If no agent explicitly supports this task type, try to find a general-purpose agent
        val generalAgent = agentRegistry.getAgentByType("general-purpose")
        if (generalAgent != null) {
            return generalAgent
        }
        
        // No suitable agent found
        throw AgentNotFoundException("No agent found capable of handling task type: ${task.type}")
    }
}

/**
 * Interface for task routing.
 */
interface TaskRouter {
    /**
     * Routes a task to the appropriate agent.
     *
     * @param task The task to route
     * @return The agent reference to which the task should be routed
     */
    fun routeTask(task: Task): AgentRef
}

/**
 * Reference to an agent.
 *
 * @property agentId Unique identifier for the agent
 * @property agentType Type of the agent
 */
data class AgentRef(
    val agentId: String,
    val agentType: String
)