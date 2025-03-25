package com.example.agents.camera

import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskPriority
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory
import java.util.Scanner
import java.util.UUID
import kotlin.system.exitProcess

/**
 * Main entry point for the Enhanced Camera Integration Agent that uses the FSM framework.
 */
object EnhancedCameraAgentMain {
    private val logger = LoggerFactory.getLogger(EnhancedCameraAgentMain::class.java)
    
    @JvmStatic
    fun main(args: Array<String>) = runBlocking {
        logger.info("Starting Enhanced Camera Integration Agent...")
        
        // Parse arguments
        val config = parseArguments(args)
        
        // Create USB manager
        val usbManager = MockUsbManager()
        
        // Create the agent
        val agent = EnhancedCameraAgent(
            agentId = config.agentId,
            usbManager = usbManager,
            natsUrl = config.natsUrl
        )
        
        // Add shutdown hook for graceful termination
        Runtime.getRuntime().addShutdownHook(Thread {
            runBlocking {
                logger.info("Shutdown hook triggered, shutting down agent...")
                agent.shutdown()
                logger.info("Agent shutdown complete")
            }
        })
        
        try {
            // Initialize the agent (this will also connect to NATS and register with orchestrator)
            logger.info("Initializing agent: ${agent.agentId}")
            val success = agent.initialize()
            
            if (!success) {
                logger.error("Failed to initialize agent")
                exitProcess(1)
            }
            
            logger.info("Agent initialized successfully with ID: ${agent.agentId}")
            
            // If running in interactive mode, start command loop
            if (config.interactive) {
                logger.info("Starting interactive mode. Type 'help' for available commands.")
                startCommandLoop(agent)
            } else {
                // Otherwise, just keep the agent running
                logger.info("Agent running in non-interactive mode. Press Ctrl+C to exit.")
                
                // Keep the agent running until interrupted
                while (true) {
                    delay(1000)
                }
            }
        } catch (e: CancellationException) {
            logger.info("Agent execution cancelled")
        } catch (e: Exception) {
            logger.error("Error in agent execution", e)
            exitProcess(1)
        }
    }
    
    /**
     * Parse command line arguments.
     */
    private fun parseArguments(args: Array<String>): AgentConfig {
        val config = AgentConfig()
        
        args.forEach { arg ->
            when {
                arg.startsWith("--agent-id=") -> {
                    config.agentId = arg.substringAfter("=")
                }
                arg.startsWith("--nats-url=") -> {
                    config.natsUrl = arg.substringAfter("=")
                }
                arg == "--interactive" -> {
                    config.interactive = true
                }
                arg == "--help" -> {
                    printHelp()
                    exitProcess(0)
                }
            }
        }
        
        // Check for environment variables if not specified in args
        if (!args.any { it.startsWith("--nats-url=") }) {
            val envNatsUrl = System.getenv("NATS_URL")
            if (!envNatsUrl.isNullOrBlank()) {
                config.natsUrl = envNatsUrl
            }
        }
        
        return config
    }
    
    /**
     * Print help information.
     */
    private fun printHelp() {
        println("""
            Enhanced Camera Integration Agent
            
            Options:
              --agent-id=<id>      Specify agent ID (default: auto-generated)
              --nats-url=<url>     NATS server URL (default: nats://localhost:4222)
              --interactive        Run in interactive mode with command prompt
              --help               Print this help message
            
            Environment Variables:
              NATS_URL             NATS server URL (alternative to --nats-url)
        """.trimIndent())
    }
    
    /**
     * Start an interactive command loop for testing.
     */
    private suspend fun startCommandLoop(agent: EnhancedCameraAgent) {
        val scanner = Scanner(System.`in`)
        
        while (true) {
            print("> ")
            val input = scanner.nextLine() ?: continue
            val parts = input.split(" ")
            
            when (parts[0].lowercase()) {
                "help" -> {
                    println("""
                        Available commands:
                          status                Get agent status
                          scan                  Scan for connected camera devices
                          capture <deviceId>    Capture a frame from a device
                          info <deviceId>       Get detailed info for a device
                          event <type>          Send an event to the agent (initialize, shutdown)
                          exit, quit            Exit the program
                    """.trimIndent())
                }
                "status" -> {
                    val status = agent.getStatus()
                    println("Agent Status:")
                    println("  ID: ${status.agentId}")
                    println("  State: ${status.state}")
                    println("  Healthy: ${status.healthy}")
                    println("  Tasks Completed: ${status.tasksCompleted}")
                    println("  Tasks Failed: ${status.tasksFailed}")
                    println("  Current Task: ${status.currentTask?.taskId ?: "None"}")
                    println("  Active Since: ${status.lastActiveTimestamp?.let { java.util.Date(it) } ?: "N/A"}")
                    
                    println("\nMetrics:")
                    status.metrics.entries.sortedBy { it.key }.forEach { (key, value) ->
                        println("  $key: $value")
                    }
                }
                "scan" -> {
                    val task = AgentTask(
                        taskId = "manual-scan-${UUID.randomUUID()}",
                        taskType = "camera.scan",
                        priority = TaskPriority.NORMAL
                    )
                    
                    println("Submitting scan task: ${task.taskId}")
                    val result = agent.processTask(task)
                    println("Result: ${result.status} - ${result.result ?: result.errorMessage}")
                }
                "capture" -> {
                    if (parts.size < 2) {
                        println("Usage: capture <deviceId>")
                        continue
                    }
                    
                    val deviceId = parts[1]
                    val task = AgentTask(
                        taskId = "manual-capture-${UUID.randomUUID()}",
                        taskType = "camera.capture",
                        priority = TaskPriority.NORMAL,
                        parameters = mapOf("deviceId" to deviceId)
                    )
                    
                    println("Submitting capture task: ${task.taskId}")
                    val result = agent.processTask(task)
                    println("Result: ${result.status} - ${result.result ?: result.errorMessage}")
                }
                "info" -> {
                    if (parts.size < 2) {
                        println("Usage: info <deviceId>")
                        continue
                    }
                    
                    val deviceId = parts[1]
                    val task = AgentTask(
                        taskId = "manual-info-${UUID.randomUUID()}",
                        taskType = "camera.configure",
                        priority = TaskPriority.NORMAL,
                        parameters = mapOf("deviceId" to deviceId)
                    )
                    
                    println("Submitting info task: ${task.taskId}")
                    val result = agent.processTask(task)
                    println("Result: ${result.status} - ${result.result ?: result.errorMessage}")
                }
                "event" -> {
                    if (parts.size < 2) {
                        println("Usage: event <type>")
                        println("Event types: initialize, shutdown")
                        continue
                    }
                    
                    when (parts[1].lowercase()) {
                        "initialize" -> {
                            println("Sending Initialize event")
                            agent.processEvent(AgentEvent.Initialize)
                        }
                        "shutdown" -> {
                            println("Sending Shutdown event")
                            agent.processEvent(AgentEvent.Shutdown)
                        }
                        else -> {
                            println("Unknown event type: ${parts[1]}")
                            println("Event types: initialize, shutdown")
                        }
                    }
                }
                "exit", "quit" -> {
                    println("Exiting...")
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
     * Configuration for the camera agent.
     */
    data class AgentConfig(
        var agentId: String = "camera-agent-${UUID.randomUUID().toString().substring(0, 8)}",
        var natsUrl: String = "nats://localhost:4222",
        var interactive: Boolean = false
    )
}