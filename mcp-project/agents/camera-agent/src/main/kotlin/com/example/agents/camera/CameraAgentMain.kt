package com.example.agents.camera

import com.example.mcp.NatsConnectionManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.UUID

/**
 * Main entry point for the Camera Integration Agent
 */
fun main() = runBlocking {
    val logger = LoggerFactory.getLogger("CameraAgent")
    logger.info("Starting Camera Integration Agent...")
    
    // Connect to NATS server
    val natsManager = NatsConnectionManager()
    val natsConnection = natsManager.connect(
        System.getenv("NATS_URL") ?: "nats://localhost:4222"
    )
    
    // Create the agent
    val agent = CameraIntegrationAgent()
    
    try {
        // Initialize the agent
        logger.info("Initializing agent: ${agent.agentId}")
        agent.initialize()
        
        // Register agent with orchestrator via NATS
        val registerMessage = Json.encodeToString(
            mapOf(
                "agentId" to agent.agentId,
                "capabilities" to agent.capabilities.map { it.name },
                "status" to agent.getStatus()
            )
        )
        natsConnection.publish("mcp.agent.register", registerMessage.toByteArray())
        logger.info("Agent registered: ${agent.agentId}")
        
        // Set up subscription for tasks
        natsConnection.createDispatcher { msg ->
            runBlocking {
                try {
                    // Parse the task message
                    val taskJson = String(msg.data)
                    val task = Json.decodeFromString<com.example.mcp.models.AgentTask>(taskJson)
                    
                    logger.info("Received task: ${task.taskId}")
                    
                    // Process the task
                    val result = agent.processTask(task)
                    
                    // Publish the result
                    val resultJson = Json.encodeToString(result)
                    natsConnection.publish("mcp.task.${task.taskId}.result", resultJson.toByteArray())
                    
                    logger.info("Completed task: ${task.taskId} with status: ${result.status}")
                } catch (e: Exception) {
                    logger.error("Error processing task message", e)
                }
            }
        }.subscribe("mcp.task.${agent.agentId}")
        
        // Set up periodic heartbeat
        while (true) {
            val status = agent.getStatus()
            val statusJson = Json.encodeToString(status)
            natsConnection.publish("mcp.agent.heartbeat", statusJson.toByteArray())
            
            // Every 10 seconds
            delay(10000)
        }
    } catch (e: Exception) {
        logger.error("Camera agent error", e)
    } finally {
        // Add shutdown hook
        Runtime.getRuntime().addShutdownHook(Thread {
            runBlocking {
                logger.info("Shutting down Camera Integration Agent...")
                agent.shutdown()
                natsManager.close()
                logger.info("Camera Integration Agent shutdown complete")
            }
        })
    }
}