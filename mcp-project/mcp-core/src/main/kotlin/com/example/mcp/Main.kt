package com.example.mcp

import com.example.mcp.messaging.AgentRegistration
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskPriority
import com.example.mcp.orchestration.Orchestrator
import com.example.mcp.orchestration.OrchestratorConfig
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory
import java.util.UUID
import kotlin.system.exitProcess

/**
 * Main entry point for the MCP Core service.
 * 
 * This class initializes the NATS connection, sets up the orchestrator,
 * and provides a simple control interface for system management.
 */
object Main {
    private val logger = LoggerFactory.getLogger(Main::class.java)
    private lateinit var natsManager: NatsConnectionManager
    private lateinit var orchestrator: Orchestrator
    
    @JvmStatic
    fun main(args: Array<String>) = runBlocking {
        logger.info("Starting MCP Core service")
        
        try {
            // Parse command-line arguments
            val config = parseArguments(args)
            
            // Initialize NATS connection
            initializeNats(config.natsUrl)
            
            // Initialize and start orchestrator
            initializeOrchestrator(config)
            
            // Register shutdown hook
            setupShutdownHook()
            
            // Start system control loop
            startCommandLoop()
            
        } catch (e: Exception) {
            logger.error("Error starting MCP Core service", e)
            exitProcess(1)
        }
    }
    
    /**
     * Initialize the NATS connection manager.
     */
    private fun initializeNats(natsUrl: String) {
        logger.info("Initializing NATS connection to $natsUrl")
        
        natsManager = NatsConnectionManager()
        natsManager.connect(natsUrl)
        
        logger.info("NATS connection established")
    }
    
    /**
     * Initialize and start the orchestrator.
     */
    private suspend fun initializeOrchestrator(config: McpConfig) {
        logger.info("Initializing orchestrator")
        
        val orchestratorConfig = OrchestratorConfig(
            maxConcurrentTasks = config.maxConcurrentTasks,
            healthCheckIntervalMs = config.healthCheckIntervalMs,
            agentTimeoutMs = config.agentTimeoutMs,
            enablePersistence = config.enablePersistence,
            persistenceFilePath = config.persistenceFilePath
        )
        
        orchestrator = Orchestrator(
            natsConnection = natsManager.getConnection(),
            config = orchestratorConfig
        )
        
        orchestrator.start()
        
        logger.info("Orchestrator started successfully")
    }
    
    /**
     * Set up a shutdown hook to ensure clean termination.
     */
    private fun setupShutdownHook() {
        Runtime.getRuntime().addShutdownHook(Thread {
            logger.info("Shutdown hook triggered, shutting down MCP Core service gracefully")
            
            runBlocking {
                if (::orchestrator.isInitialized) {
                    orchestrator.shutdown()
                }
                
                if (::natsManager.isInitialized) {
                    natsManager.close()
                }
            }
            
            logger.info("MCP Core service has shut down cleanly")
        })
    }
    
    /**
     * Parse command-line arguments.
     */
    private fun parseArguments(args: Array<String>): McpConfig {
        val config = McpConfig()
        
        args.forEach { arg ->
            when {
                arg.startsWith("--nats-url=") -> {
                    config.natsUrl = arg.substringAfter("=")
                }
                arg.startsWith("--max-concurrent-tasks=") -> {
                    config.maxConcurrentTasks = arg.substringAfter("=").toInt()
                }
                arg.startsWith("--health-check-interval=") -> {
                    config.healthCheckIntervalMs = arg.substringAfter("=").toLong()
                }
                arg.startsWith("--agent-timeout=") -> {
                    config.agentTimeoutMs = arg.substringAfter("=").toLong()
                }
                arg.startsWith("--enable-persistence=") -> {
                    config.enablePersistence = arg.substringAfter("=").toBoolean()
                }
                arg.startsWith("--persistence-file=") -> {
                    config.persistenceFilePath = arg.substringAfter("=")
                }
                arg == "--help" -> {
                    printHelp()
                    exitProcess(0)
                }
            }
        }
        
        return config
    }
    
    /**
     * Print help information.
     */
    private fun printHelp() {
        println("""
            MCP Core service
            
            Options:
              --nats-url=<url>                 NATS server URL (default: nats://localhost:4222)
              --max-concurrent-tasks=<count>   Maximum concurrent tasks (default: available processors)
              --health-check-interval=<ms>     Health check interval in ms (default: 30000)
              --agent-timeout=<ms>             Agent timeout in ms (default: 60000)
              --enable-persistence=<bool>      Enable persistence (default: false)
              --persistence-file=<path>        Persistence file path
              --help                           Print this help message
        """.trimIndent())
    }
    
    /**
     * Start a simple command loop for system control.
     * 
     * This provides a basic interactive interface for managing the MCP system.
     */
    private suspend fun startCommandLoop() {
        println("\nMCP Core service is running. Type 'help' for available commands.")
        
        while (true) {
            print("> ")
            val input = readLine() ?: continue
            val parts = input.split(" ")
            
            when (parts[0].lowercase()) {
                "help" -> {
                    println("""
                        Available commands:
                          status                         Show system status
                          register <id> <type>           Register a mock agent
                          task <agent-type> <payload>    Submit a task
                          shutdown                       Shutdown the service
                          exit, quit                     Exit the command loop
                    """.trimIndent())
                }
                "status" -> {
                    val status = orchestrator.getSystemStatus()
                    println("System Status:")
                    println("  Orchestrator: ${status.orchestratorStatus}")
                    println("  Agents: ${status.agentCount} (${status.healthyAgentCount} healthy, ${status.unhealthyAgentCount} unhealthy)")
                    println("  Tasks: ${status.activeTaskCount} active, ${status.queuedTaskCount} queued")
                    
                    if (status.agentStatuses.isNotEmpty()) {
                        println("\nAgent Status:")
                        status.agentStatuses.forEach { agentStatus ->
                            println("  ${agentStatus.agentId}: ${agentStatus.state}, healthy=${agentStatus.healthy}")
                        }
                    }
                }
                "register" -> {
                    if (parts.size < 3) {
                        println("Usage: register <id> <type>")
                        continue
                    }
                    
                    val agentId = parts[1]
                    val agentType = parts[2]
                    
                    val registration = AgentRegistration(
                        agentId = agentId,
                        agentType = agentType,
                        capabilities = listOf("mock.capability")
                    )
                    
                    val success = orchestrator.registerAgent(registration)
                    if (success) {
                        println("Agent $agentId registered successfully")
                    } else {
                        println("Failed to register agent $agentId")
                    }
                }
                "task" -> {
                    if (parts.size < 3) {
                        println("Usage: task <agent-type> <payload>")
                        continue
                    }
                    
                    val agentType = parts[1]
                    val payload = parts.drop(2).joinToString(" ")
                    
                    val task = AgentTask(
                        taskId = UUID.randomUUID().toString(),
                        taskType = "test.task",
                        priority = TaskPriority.NORMAL,
                        parameters = mapOf("payload" to payload)
                    )
                    
                    val taskId = orchestrator.submitTask(task)
                    println("Task submitted with ID: $taskId")
                }
                "shutdown" -> {
                    println("Shutting down MCP Core service...")
                    orchestrator.shutdown()
                    natsManager.close()
                    println("Shutdown complete")
                    exitProcess(0)
                }
                "exit", "quit" -> {
                    println("Exiting command loop")
                    break
                }
                else -> {
                    println("Unknown command: ${parts[0]}")
                    println("Type 'help' for available commands")
                }
            }
        }
    }
    
    /**
     * Configuration for the MCP Core service.
     */
    data class McpConfig(
        var natsUrl: String = "nats://localhost:4222",
        var maxConcurrentTasks: Int = Runtime.getRuntime().availableProcessors(),
        var healthCheckIntervalMs: Long = 30000,
        var agentTimeoutMs: Long = 60000,
        var enablePersistence: Boolean = false,
        var persistenceFilePath: String? = null
    )
}