package com.example.mcp

import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory

fun main() = runBlocking {
    val logger = LoggerFactory.getLogger("MCP")
    logger.info("Starting MCP...")
    
    // Connect to NATS
    val natsManager = NatsConnectionManager()
    val natsConnection = natsManager.connect(
        System.getenv("NATS_URL") ?: "nats://localhost:4222"
    )
    
    // Initialize orchestrator
    val orchestrator = Orchestrator(natsConnection)
    orchestrator.start()
    
    // Add shutdown hook
    Runtime.getRuntime().addShutdownHook(Thread {
        runBlocking {
            logger.info("Shutting down MCP...")
            orchestrator.stop()
            natsManager.close()
        }
    })
    
    // Keep application running
    logger.info("MCP running. Press Ctrl+C to exit.")
    while (true) {
        kotlinx.coroutines.delay(1000)
    }
}