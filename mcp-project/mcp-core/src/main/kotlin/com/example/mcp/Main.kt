package com.example.mcp

import com.example.mcp.health.HealthCheckService
import com.example.mcp.health.SystemMetricsCollector
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import org.slf4j.LoggerFactory
import kotlin.time.Duration.Companion.seconds

fun main() = runBlocking {
    val logger = LoggerFactory.getLogger("MCP")
    logger.info("Starting MCP...")
    
    try {
        // Connect to NATS
        val natsManager = NatsConnectionManager()
        val natsConnection = natsManager.connect(
            System.getenv("NATS_URL") ?: "nats://localhost:4222"
        )
        
        // Initialize health monitoring
        logger.info("Initializing health monitoring system...")
        val metricsCollector = SystemMetricsCollector()
        val healthCheckService = HealthCheckService(
            natsConnection = natsConnection,
            metricsCollectionInterval = 15.seconds
        )
        
        // Initialize orchestrator
        val orchestrator = Orchestrator(natsConnection)
        orchestrator.start()
        
        // Log startup metrics
        val initialMetrics = metricsCollector.collectMetrics()
        logger.info("Startup metrics - CPU cores: ${initialMetrics.cpuMetrics.availableProcessors}, " +
                   "Memory: ${initialMetrics.memoryMetrics.totalMemoryBytes / (1024 * 1024)}MB, " +
                   "Heap usage: ${initialMetrics.memoryMetrics.heapUtilizationPercent}%")
        
        // Add shutdown hook
        Runtime.getRuntime().addShutdownHook(Thread {
            runBlocking {
                logger.info("Shutting down MCP...")
                
                // Stop services in reverse order
                orchestrator.stop()
                
                // Stop health monitoring
                withContext(Dispatchers.Default) {
                    logger.info("Stopping health monitoring...")
                    healthCheckService.stop()
                }
                
                // Close NATS connection
                natsManager.close()
                
                logger.info("MCP shutdown complete")
            }
        })
        
        // Keep application running
        logger.info("MCP running. Health monitoring active. Press Ctrl+C to exit.")
        while (true) {
            kotlinx.coroutines.delay(1000)
        }
    } catch (e: Exception) {
        logger.error("Fatal error in MCP: ${e.message}", e)
        throw e
    }
}