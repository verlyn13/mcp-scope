package com.example.mcp

import com.example.agents.McpAgent
import io.nats.client.Connection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory

class Orchestrator(
    private val natsConnection: Connection
) {
    private val logger = LoggerFactory.getLogger(Orchestrator::class.java)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val agents = mutableListOf<McpAgent>()
    private val agentStateMachines = mutableMapOf<String, AgentStateMachine>()
    
    fun start() {
        logger.info("Orchestrator starting")
        
        // Initialize agents (will be dynamically loaded in a more advanced implementation)
        // Register agents here when implemented
        
        // Initialize all registered agents
        agents.forEach { agent ->
            val stateMachine = AgentStateMachine(agent)
            agentStateMachines[agent.agentId] = stateMachine
            stateMachine.initialize()
            logger.info("Registered agent: ${agent.agentId} with capabilities: ${agent.capabilities}")
        }
        
        // Set up NATS subscriptions
        setupTaskDistribution()
        
        logger.info("Orchestrator started successfully")
    }
    
    private fun setupTaskDistribution() {
        // Subscribe to task requests
        natsConnection.createDispatcher { msg ->
            scope.launch {
                val taskId = msg.subject.substringAfterLast('.')
                logger.info("Received task request: $taskId")
                // Implementation will be added later
            }
        }.subscribe("mcp.task.>")
        
        logger.info("Task distribution setup complete")
    }
    
    fun stop() {
        runBlocking {
            logger.info("Stopping orchestrator")
            
            // Shutdown all agent state machines
            agentStateMachines.values.forEach { it.shutdown() }
            
            logger.info("Orchestrator stopped")
        }
    }

    // Method to register an agent with the orchestrator
    fun registerAgent(agent: McpAgent) {
        logger.info("Registering agent: ${agent.agentId}")
        agents.add(agent)
        val stateMachine = AgentStateMachine(agent)
        agentStateMachines[agent.agentId] = stateMachine
        stateMachine.initialize()
        logger.info("Agent registered successfully: ${agent.agentId} with capabilities: ${agent.capabilities}")
    }
}