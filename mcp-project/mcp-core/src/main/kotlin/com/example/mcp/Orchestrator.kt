package com.example.mcp

import com.example.agents.McpAgent
import com.example.mcp.health.HealthCheckService
import com.example.mcp.models.AgentEvent
import io.nats.client.Connection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration.Companion.seconds

class Orchestrator(
    private val natsConnection: Connection
) {
    private val logger = LoggerFactory.getLogger(Orchestrator::class.java)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val agents = mutableListOf<McpAgent>()
    private val agentStateMachines = ConcurrentHashMap<String, AgentStateMachine>()
    private val healthCheckService = HealthCheckService(natsConnection)
    private val json = Json { prettyPrint = true }
    
    fun start() {
        logger.info("Orchestrator starting")
        
        // Initialize agents (will be dynamically loaded in a more advanced implementation)
        // Register agents here when implemented
        
        // Initialize all registered agents
        agents.forEach { agent ->
            val stateMachine = AgentStateMachine(agent)
            agentStateMachines[agent.agentId] = stateMachine
            
            // Set up state change listener
            stateMachine.addStateChangeListener { oldState, newState ->
                logger.info("Agent ${agent.agentId} state changed from $oldState to $newState")
                // Update health status
                healthCheckService.updateAgentHealth(agent, newState)
                
                // Publish state change to NATS
                publishAgentStateChange(agent.agentId, oldState, newState)
            }
            
            stateMachine.initialize()
            logger.info("Registered agent: ${agent.agentId} with capabilities: ${agent.capabilities}")
        }
        
        // Set up NATS subscriptions
        setupTaskDistribution()
        setupHealthCheck()
        
        logger.info("Orchestrator started successfully")
    }
    
    private fun setupTaskDistribution() {
        // Subscribe to task requests
        natsConnection.createDispatcher { msg ->
            scope.launch {
                try {
                    val taskId = msg.subject.substringAfterLast('.')
                    logger.info("Received task request: $taskId")
                    // Implementation will be added later
                    
                    // Reply with acknowledgement
                    msg.respond("Acknowledged: $taskId".toByteArray())
                } catch (e: Exception) {
                    logger.error("Error processing task request", e)
                    msg.respond("Error: ${e.message}".toByteArray())
                }
            }
        }.subscribe("mcp.task.>")
        
        logger.info("Task distribution setup complete")
    }
    
    private fun setupHealthCheck() {
        // Subscribe to agent health check requests
        natsConnection.createDispatcher { msg ->
            scope.launch {
                try {
                    when (msg.subject) {
                        "mcp.orchestrator.status" -> {
                            // Return orchestrator status
                            val status = mapOf(
                                "status" to "running",
                                "agentCount" to agents.size,
                                "timestamp" to System.currentTimeMillis()
                            )
                            msg.respond(json.encodeToString(status).toByteArray())
                        }
                        "mcp.orchestrator.agents" -> {
                            // Return list of registered agents
                            val agentList = agents.map { agent ->
                                mapOf(
                                    "agentId" to agent.agentId,
                                    "state" to agentStateMachines[agent.agentId]?.getCurrentState().toString(),
                                    "capabilities" to agent.capabilities.map { it.name }
                                )
                            }
                            msg.respond(json.encodeToString(agentList).toByteArray())
                        }
                    }
                } catch (e: Exception) {
                    logger.error("Error processing health check request", e)
                    msg.respond("Error: ${e.message}".toByteArray())
                }
            }
        }.apply {
            subscribe("mcp.orchestrator.status")
            subscribe("mcp.orchestrator.agents")
        }
        
        logger.info("Health check endpoints setup complete")
    }
    
    private fun publishAgentStateChange(agentId: String, oldState: com.example.mcp.models.AgentState, newState: com.example.mcp.models.AgentState) {
        val stateChange = mapOf(
            "agentId" to agentId,
            "oldState" to oldState.toString(),
            "newState" to newState.toString(),
            "timestamp" to System.currentTimeMillis()
        )
        
        natsConnection.publish(
            "mcp.agent.state.$agentId",
            json.encodeToString(stateChange).toByteArray()
        )
    }
    
    fun stop() {
        runBlocking {
            logger.info("Stopping orchestrator")
            
            // Shutdown all agent state machines
            agentStateMachines.values.forEach { it.shutdown() }
            
            // Stop health check service
            healthCheckService.stop()
            
            logger.info("Orchestrator stopped")
        }
    }

    // Method to register an agent with the orchestrator
    fun registerAgent(agent: McpAgent) {
        logger.info("Registering agent: ${agent.agentId}")
        agents.add(agent)
        
        val stateMachine = AgentStateMachine(agent)
        
        // Set up state change listener
        stateMachine.addStateChangeListener { oldState, newState ->
            logger.info("Agent ${agent.agentId} state changed from $oldState to $newState")
            // Update health status
            healthCheckService.updateAgentHealth(agent, newState)
            
            // Publish state change to NATS
            publishAgentStateChange(agent.agentId, oldState, newState)
        }
        
        agentStateMachines[agent.agentId] = stateMachine
        stateMachine.initialize()
        
        // Register with health check service
        healthCheckService.updateAgentHealth(agent, stateMachine.getCurrentState())
        
        logger.info("Agent registered successfully: ${agent.agentId} with capabilities: ${agent.capabilities}")
    }
    
    // Method to distribute a task to an agent with the appropriate capability
    fun distributeTask(task: com.example.mcp.models.AgentTask): Boolean {
        logger.info("Distributing task: ${task.taskId} for agent type: ${task.agentType}")
        
        // Find an agent with the required capability
        val agent = agents.find { agent ->
            agent.capabilities.any { it.name == task.agentType }
        }
        
        if (agent == null) {
            logger.warn("No agent found for task ${task.taskId} with type ${task.agentType}")
            return false
        }
        
        // Get the agent's state machine
        val stateMachine = agentStateMachines[agent.agentId]
        if (stateMachine == null) {
            logger.error("State machine not found for agent ${agent.agentId}")
            return false
        }
        
        // Process the task
        logger.info("Sending task ${task.taskId} to agent ${agent.agentId}")
        stateMachine.processTask(AgentEvent.Process(task))
        return true
    }
}