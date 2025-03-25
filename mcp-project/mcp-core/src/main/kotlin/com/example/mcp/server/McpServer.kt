package com.example.mcp.server

import com.example.agents.McpAgent
import com.example.mcp.NatsConnectionManager
import com.example.mcp.orchestration.Orchestrator
import com.example.mcp.orchestration.OrchestratorConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory
import java.nio.file.Files
import java.nio.file.Paths
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Main server component for the Multi-Agent Control Platform.
 * 
 * This class manages the lifecycle of the MCP system including:
 * - NATS connection management
 * - Orchestrator initialization and configuration
 * - Health monitoring and reporting
 * - Graceful startup and shutdown
 */
class McpServer(
    private val config: McpServerConfig = McpServerConfig()
) {
    private val logger = LoggerFactory.getLogger(McpServer::class.java)
    private val natsManager = NatsConnectionManager()
    private lateinit var orchestrator: Orchestrator
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val isRunning = AtomicBoolean(false)
    private val preRegisteredAgents = ConcurrentHashMap<String, McpAgent>()
    private var healthCheckJob: Job? = null
    
    /**
     * Start the MCP server and all its components.
     * 
     * @return True if server started successfully, false otherwise
     */
    suspend fun start(): Boolean {
        if (isRunning.get()) {
            logger.warn("Server is already running")
            return true
        }
        
        logger.info("Starting MCP Server with config: $config")
        
        try {
            // Connect to NATS
            val natsConnection = natsManager.connect(config.natsUrl)
            logger.info("Connected to NATS at ${config.natsUrl}")
            
            // Create and start orchestrator
            val orchestratorConfig = OrchestratorConfig(
                maxConcurrentTasks = config.maxConcurrentTasks,
                healthCheckIntervalMs = config.healthCheckIntervalMs,
                agentTimeoutMs = config.agentTimeoutMs,
                enablePersistence = config.enablePersistence,
                persistenceFilePath = config.persistenceFilePath,
                shutdownGracePeriodMs = config.shutdownGracePeriodMs
            )
            
            orchestrator = Orchestrator(natsConnection, orchestratorConfig)
            orchestrator.start()
            logger.info("Orchestrator started successfully")
            
            // Register any pre-registered agents
            preRegisteredAgents.forEach { (_, agent) ->
                logger.info("Registering pre-registered agent: ${agent.agentId}")
                // This would typically involve messaging, but for pre-registered agents 
                // we can use direct registration
                val agentRegistration = com.example.mcp.messaging.AgentRegistration(
                    agentId = agent.agentId,
                    agentType = agent.javaClass.simpleName,
                    capabilities = agent.capabilities.map { 
                        when (it) {
                            is com.example.agents.Capability.Custom -> it.name
                            else -> it.javaClass.simpleName
                        }
                    }
                )
                orchestrator.registerAgent(agentRegistration)
            }
            
            // Start health check if enabled
            if (config.enableHealthChecks) {
                startHealthCheck()
            }
            
            // Write PID file if configured
            if (config.pidFile != null) {
                val pid = ProcessHandle.current().pid().toString()
                Files.writeString(Paths.get(config.pidFile), pid)
                logger.info("Wrote PID $pid to ${config.pidFile}")
            }
            
            isRunning.set(true)
            logger.info("MCP Server started successfully")
            return true
        } catch (e: Exception) {
            logger.error("Failed to start MCP Server", e)
            stop()
            return false
        }
    }
    
    /**
     * Stop the MCP server and all its components.
     * 
     * @return True if server stopped successfully, false otherwise
     */
    suspend fun stop(): Boolean {
        if (!isRunning.get() && !::orchestrator.isInitialized) {
            logger.warn("Server is not running")
            return true
        }
        
        logger.info("Stopping MCP Server")
        
        try {
            // Stop health check
            healthCheckJob?.cancel()
            
            // Stop orchestrator if initialized
            if (::orchestrator.isInitialized) {
                orchestrator.shutdown()
                logger.info("Orchestrator stopped successfully")
            }
            
            // Close NATS connection
            natsManager.close()
            logger.info("NATS connection closed")
            
            // Cancel scope
            scope.cancel()
            
            // Remove PID file if it exists
            if (config.pidFile != null) {
                val pidFile = Paths.get(config.pidFile)
                if (Files.exists(pidFile)) {
                    Files.delete(pidFile)
                    logger.info("Removed PID file: ${config.pidFile}")
                }
            }
            
            isRunning.set(false)
            logger.info("MCP Server stopped successfully")
            return true
        } catch (e: Exception) {
            logger.error("Error stopping MCP Server", e)
            return false
        }
    }
    
    /**
     * Pre-register an agent with the server.
     * This agent will be automatically registered when the server starts.
     * 
     * @param agent The agent to pre-register
     * @return This server instance for chaining
     */
    fun registerAgent(agent: McpAgent): McpServer {
        if (!isRunning.get()) {
            logger.info("Pre-registering agent: ${agent.agentId}")
            preRegisteredAgents[agent.agentId] = agent
        } else {
            logger.warn("Server is already running, can't pre-register agent: ${agent.agentId}")
        }
        return this
    }
    
    /**
     * Get the system status including orchestrator and agent status.
     * 
     * @return The current system status
     */
    fun getStatus(): McpServerStatus {
        val orchestratorStatus = if (::orchestrator.isInitialized && isRunning.get()) {
            orchestrator.getSystemStatus()
        } else {
            null
        }
        
        return McpServerStatus(
            isRunning = isRunning.get(),
            uptime = if (isRunning.get()) System.currentTimeMillis() - startTime else 0,
            orchestratorStatus = orchestratorStatus,
            natsConnected = natsManager.isConnected(),
            healthCheckActive = healthCheckJob?.isActive ?: false
        )
    }
    
    /**
     * Start the health check job to monitor system health.
     */
    private fun startHealthCheck() {
        logger.info("Starting health check (interval: ${config.healthCheckIntervalMs}ms)")
        
        healthCheckJob = scope.launch {
            while (isActive) {
                try {
                    val status = getStatus()
                    logger.debug("Health check: running=${status.isRunning}, agents=${status.orchestratorStatus?.agentCount ?: 0}")
                    
                    // In a more sophisticated implementation, this would report to monitoring systems
                    // or take corrective actions based on the health status
                    
                } catch (e: Exception) {
                    logger.error("Error in health check", e)
                }
                
                delay(config.healthCheckIntervalMs)
            }
        }
    }
    
    companion object {
        private val startTime = System.currentTimeMillis()
        
        /**
         * Run the server in blocking mode until interrupted.
         * 
         * @param config The server configuration
         */
        @JvmStatic
        fun runBlocking(config: McpServerConfig = McpServerConfig()) {
            val server = McpServer(config)
            
            // Add shutdown hook
            Runtime.getRuntime().addShutdownHook(Thread {
                kotlinx.coroutines.runBlocking {
                    server.stop()
                }
            })
            
            kotlinx.coroutines.runBlocking {
                if (server.start()) {
                    logger.info("Server running. Press Ctrl+C to stop.")
                    
                    try {
                        // Keep server running until interrupted
                        while (server.isRunning.get()) {
                            delay(1000)
                        }
                    } catch (e: InterruptedException) {
                        // Normal shutdown due to Ctrl+C
                        logger.info("Server interrupted")
                    } finally {
                        server.stop()
                    }
                }
            }
        }
        
        private val logger = LoggerFactory.getLogger(McpServer::class.java)
    }
}

/**
 * Configuration for the MCP server.
 */
data class McpServerConfig(
    val natsUrl: String = "nats://localhost:4222",
    val maxConcurrentTasks: Int = Runtime.getRuntime().availableProcessors(),
    val healthCheckIntervalMs: Long = 30000,
    val agentTimeoutMs: Long = 60000,
    val enablePersistence: Boolean = false,
    val persistenceFilePath: String? = null,
    val shutdownGracePeriodMs: Long = 5000,
    val enableHealthChecks: Boolean = true,
    val pidFile: String? = null
)

/**
 * Status of the MCP server.
 */
data class McpServerStatus(
    val isRunning: Boolean,
    val uptime: Long,
    val orchestratorStatus: com.example.mcp.orchestration.SystemStatus?,
    val natsConnected: Boolean,
    val healthCheckActive: Boolean
)