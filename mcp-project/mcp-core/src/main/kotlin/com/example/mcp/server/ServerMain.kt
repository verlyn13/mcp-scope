package com.example.mcp.server

import com.example.agents.SmolAgent
import org.slf4j.LoggerFactory
import java.io.File
import java.nio.file.Paths
import kotlin.system.exitProcess

/**
 * Main entry point for the MCP Server application.
 * 
 * This class handles parsing command-line arguments, configuring
 * the server, and starting it up. It can also register built-in agents
 * for testing and development purposes.
 */
object ServerMain {
    private val logger = LoggerFactory.getLogger(ServerMain::class.java)
    
    @JvmStatic
    fun main(args: Array<String>) {
        logger.info("Starting MCP Server Application")
        
        val config = parseArguments(args)
        
        if (config.printHelp) {
            printHelp()
            return
        }
        
        // Check if NATS server is specified as a file
        if (config.natsUrl.startsWith("file://")) {
            val filePath = config.natsUrl.substring(7)
            try {
                val fileContent = File(filePath).readText().trim()
                logger.info("Loaded NATS URL from file: $filePath")
                config.copy(natsUrl = fileContent)
            } catch (e: Exception) {
                logger.error("Failed to read NATS URL from file: $filePath", e)
                exitProcess(1)
            }
        }
        
        // Create server with configuration
        val server = McpServer(config)
        
        // Register built-in agents if enabled
        if (config.registerTestAgents) {
            registerTestAgents(server)
        }
        
        // Run server
        try {
            McpServer.runBlocking(config)
        } catch (e: Exception) {
            logger.error("Error running MCP Server", e)
            exitProcess(1)
        }
    }
    
    /**
     * Parse command-line arguments into server configuration.
     */
    private fun parseArguments(args: Array<String>): McpServerConfig {
        val config = McpServerConfig()
        var mutableConfig = config.copy()
        var printHelp = false
        
        args.forEach { arg ->
            when {
                arg == "--help" || arg == "-h" -> {
                    printHelp = true
                }
                arg.startsWith("--nats-url=") -> {
                    val value = arg.substringAfter("=")
                    mutableConfig = mutableConfig.copy(natsUrl = value)
                }
                arg.startsWith("--max-tasks=") -> {
                    val value = arg.substringAfter("=").toIntOrNull()
                    if (value != null && value > 0) {
                        mutableConfig = mutableConfig.copy(maxConcurrentTasks = value)
                    }
                }
                arg.startsWith("--health-interval=") -> {
                    val value = arg.substringAfter("=").toLongOrNull()
                    if (value != null && value > 0) {
                        mutableConfig = mutableConfig.copy(healthCheckIntervalMs = value)
                    }
                }
                arg.startsWith("--agent-timeout=") -> {
                    val value = arg.substringAfter("=").toLongOrNull()
                    if (value != null && value > 0) {
                        mutableConfig = mutableConfig.copy(agentTimeoutMs = value)
                    }
                }
                arg == "--persistence" -> {
                    mutableConfig = mutableConfig.copy(enablePersistence = true)
                }
                arg.startsWith("--persistence-file=") -> {
                    val value = arg.substringAfter("=")
                    mutableConfig = mutableConfig.copy(
                        enablePersistence = true,
                        persistenceFilePath = value
                    )
                }
                arg.startsWith("--shutdown-grace=") -> {
                    val value = arg.substringAfter("=").toLongOrNull()
                    if (value != null && value > 0) {
                        mutableConfig = mutableConfig.copy(shutdownGracePeriodMs = value)
                    }
                }
                arg == "--no-health-checks" -> {
                    mutableConfig = mutableConfig.copy(enableHealthChecks = false)
                }
                arg.startsWith("--pid-file=") -> {
                    val value = arg.substringAfter("=")
                    mutableConfig = mutableConfig.copy(pidFile = value)
                }
                arg == "--register-test-agents" -> {
                    registerTestAgents = true
                }
            }
        }
        
        // Also check environment variables
        System.getenv("NATS_URL")?.let { mutableConfig = mutableConfig.copy(natsUrl = it) }
        System.getenv("MCP_MAX_TASKS")?.toIntOrNull()?.let { mutableConfig = mutableConfig.copy(maxConcurrentTasks = it) }
        System.getenv("MCP_HEALTH_INTERVAL")?.toLongOrNull()?.let { mutableConfig = mutableConfig.copy(healthCheckIntervalMs = it) }
        System.getenv("MCP_AGENT_TIMEOUT")?.toLongOrNull()?.let { mutableConfig = mutableConfig.copy(agentTimeoutMs = it) }
        System.getenv("MCP_ENABLE_PERSISTENCE")?.toBoolean()?.let { mutableConfig = mutableConfig.copy(enablePersistence = it) }
        System.getenv("MCP_PERSISTENCE_FILE")?.let { mutableConfig = mutableConfig.copy(persistenceFilePath = it) }
        System.getenv("MCP_SHUTDOWN_GRACE")?.toLongOrNull()?.let { mutableConfig = mutableConfig.copy(shutdownGracePeriodMs = it) }
        System.getenv("MCP_ENABLE_HEALTH_CHECKS")?.toBoolean()?.let { mutableConfig = mutableConfig.copy(enableHealthChecks = it) }
        System.getenv("MCP_PID_FILE")?.let { mutableConfig = mutableConfig.copy(pidFile = it) }
        System.getenv("MCP_REGISTER_TEST_AGENTS")?.toBoolean()?.let { registerTestAgents = it }
        
        return object : McpServerConfig(
            natsUrl = mutableConfig.natsUrl,
            maxConcurrentTasks = mutableConfig.maxConcurrentTasks,
            healthCheckIntervalMs = mutableConfig.healthCheckIntervalMs,
            agentTimeoutMs = mutableConfig.agentTimeoutMs,
            enablePersistence = mutableConfig.enablePersistence,
            persistenceFilePath = mutableConfig.persistenceFilePath,
            shutdownGracePeriodMs = mutableConfig.shutdownGracePeriodMs,
            enableHealthChecks = mutableConfig.enableHealthChecks,
            pidFile = mutableConfig.pidFile
        ) {
            val printHelp = printHelp
        }
    }
    
    /**
     * Print help information.
     */
    private fun printHelp() {
        println("""
            MCP Server - Multi-Agent Control Platform
            
            Usage: java -jar mcp-server.jar [options]
            
            Options:
              --help, -h                 Show this help message
              --nats-url=<url>           NATS server URL (default: nats://localhost:4222)
              --max-tasks=<num>          Maximum concurrent tasks (default: CPU cores)
              --health-interval=<ms>     Health check interval in ms (default: 30000)
              --agent-timeout=<ms>       Agent timeout in ms (default: 60000)
              --persistence              Enable persistence (default: false)
              --persistence-file=<path>  Persistence file path
              --shutdown-grace=<ms>      Shutdown grace period in ms (default: 5000)
              --no-health-checks         Disable health checks
              --pid-file=<path>          Path to write PID file
              --register-test-agents     Register built-in test agents
            
            Environment Variables:
              NATS_URL                   NATS server URL
              MCP_MAX_TASKS              Maximum concurrent tasks
              MCP_HEALTH_INTERVAL        Health check interval in ms
              MCP_AGENT_TIMEOUT          Agent timeout in ms
              MCP_ENABLE_PERSISTENCE     Enable persistence (true/false)
              MCP_PERSISTENCE_FILE       Persistence file path
              MCP_SHUTDOWN_GRACE         Shutdown grace period in ms
              MCP_ENABLE_HEALTH_CHECKS   Enable health checks (true/false)
              MCP_PID_FILE               Path to write PID file
              MCP_REGISTER_TEST_AGENTS   Register built-in test agents (true/false)
        """.trimIndent())
    }
    
    /**
     * Register built-in test agents with the server.
     * 
     * These agents are useful for testing and development.
     */
    private fun registerTestAgents(server: McpServer) {
        logger.info("Registering test agents")
        
        // Echo agent - simply echoes back the task parameters
        val echoAgent = SmolAgent.withHandler(
            handler = { task ->
                logger.info("Echo agent processing task: ${task.taskId}")
                com.example.mcp.models.TaskResult(
                    taskId = task.taskId,
                    status = com.example.mcp.models.TaskStatus.COMPLETED,
                    result = "Echo response: ${task.parameters}",
                    executionTimeMs = 100
                )
            },
            agentId = "echo-agent",
            agentType = "test",
            capabilities = setOf(com.example.agents.Capability.Custom("echo"))
        )
        
        // Random failure agent - randomly succeeds or fails
        val randomAgent = SmolAgent.withHandler(
            handler = { task ->
                logger.info("Random agent processing task: ${task.taskId}")
                val success = Math.random() > 0.3 // 70% success rate
                if (success) {
                    com.example.mcp.models.TaskResult(
                        taskId = task.taskId,
                        status = com.example.mcp.models.TaskStatus.COMPLETED,
                        result = "Random success",
                        executionTimeMs = 200
                    )
                } else {
                    com.example.mcp.models.TaskResult(
                        taskId = task.taskId,
                        status = com.example.mcp.models.TaskStatus.FAILED,
                        errorMessage = "Random failure",
                        executionTimeMs = 200
                    )
                }
            },
            agentId = "random-agent",
            agentType = "test",
            capabilities = setOf(com.example.agents.Capability.Custom("random"))
        )
        
        // Delay agent - simulates a long-running task
        val delayAgent = SmolAgent.withHandler(
            handler = { task ->
                logger.info("Delay agent processing task: ${task.taskId}")
                val delayMs = task.parameters["delayMs"]?.toLongOrNull() ?: 2000
                Thread.sleep(delayMs)
                com.example.mcp.models.TaskResult(
                    taskId = task.taskId,
                    status = com.example.mcp.models.TaskStatus.COMPLETED,
                    result = "Completed after ${delayMs}ms delay",
                    executionTimeMs = delayMs
                )
            },
            agentId = "delay-agent",
            agentType = "test",
            capabilities = setOf(com.example.agents.Capability.Custom("delay"))
        )
        
        // Register the agents
        server.registerAgent(echoAgent)
        server.registerAgent(randomAgent)
        server.registerAgent(delayAgent)
    }
    
    // Flag to register test agents
    private var registerTestAgents = false
}

// Extension to allow access to printHelp property
private val McpServerConfig.printHelp: Boolean
    get() = (this as? ServerMain.`parseArguments$1`)?.printHelp ?: false