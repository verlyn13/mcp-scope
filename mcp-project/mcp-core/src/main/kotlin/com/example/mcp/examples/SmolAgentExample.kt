package com.example.mcp.examples

import com.example.agents.Capability
import com.example.agents.SmolAgent
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskStatus
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import java.util.UUID

/**
 * Example showing how to use SmolAgent for testing and development.
 * 
 * This demonstrates creating, initializing, and using a SmolAgent
 * without requiring NATS or other external dependencies.
 */
fun main() = runBlocking {
    println("Starting SmolAgent Example")
    
    // Create a basic SmolAgent
    val basicAgent = SmolAgent(
        agentId = "example-agent-1",
        agentType = "demo",
        capabilities = setOf(Capability.Custom("example"))
    )
    
    // Initialize the agent
    println("Initializing basic agent...")
    val initSuccess = basicAgent.initialize()
    println("Initialization ${if (initSuccess) "succeeded" else "failed"}")
    
    // Process a simple task
    val task1 = AgentTask(
        taskId = "task-" + UUID.randomUUID().toString().substring(0, 8),
        taskType = "example.task",
        parameters = mapOf("param1" to "value1", "param2" to "value2")
    )
    
    println("Processing task: ${task1.taskId}")
    val result1 = basicAgent.processTask(task1)
    println("Task completed with status: ${result1.status}")
    println("Result: ${result1.result}")
    
    // Check agent status
    val status1 = basicAgent.getStatus()
    println("\nAgent Status:")
    println("  State: ${status1.state}")
    println("  Healthy: ${status1.healthy}")
    println("  Tasks Completed: ${status1.tasksCompleted}")
    println("  Tasks Failed: ${status1.tasksFailed}")
    
    println("\n----------------------------------------------\n")
    
    // Create a SmolAgent with custom task handler
    println("Creating agent with custom task handler...")
    val customAgent = SmolAgent.withHandler(
        handler = { task ->
            println("Custom handler processing: ${task.taskType}")
            // Simulate some processing time
            Thread.sleep(200)
            
            // Return different results based on task type
            when (task.taskType) {
                "example.success" -> com.example.mcp.models.TaskResult(
                    taskId = task.taskId,
                    status = TaskStatus.COMPLETED,
                    result = "Successfully processed task",
                    executionTimeMs = 200
                )
                "example.failure" -> com.example.mcp.models.TaskResult(
                    taskId = task.taskId,
                    status = TaskStatus.FAILED,
                    errorMessage = "Simulated failure",
                    executionTimeMs = 200
                )
                else -> com.example.mcp.models.TaskResult(
                    taskId = task.taskId,
                    status = TaskStatus.COMPLETED,
                    result = "Processed unknown task type: ${task.taskType}",
                    executionTimeMs = 200
                )
            }
        },
        agentId = "example-agent-2",
        agentType = "demo",
        capabilities = setOf(Capability.Custom("custom-handler"))
    )
    
    // Initialize custom agent
    customAgent.initialize()
    
    // Process successful task
    val task2 = AgentTask(
        taskId = "task-" + UUID.randomUUID().toString().substring(0, 8),
        taskType = "example.success",
        parameters = mapOf("data" to "test-data")
    )
    
    println("Processing successful task: ${task2.taskId}")
    val result2 = customAgent.processTask(task2)
    println("Task completed with status: ${result2.status}")
    println("Result: ${result2.result}")
    
    // Process failure task
    val task3 = AgentTask(
        taskId = "task-" + UUID.randomUUID().toString().substring(0, 8),
        taskType = "example.failure",
        parameters = mapOf("data" to "bad-data")
    )
    
    println("\nProcessing failure task: ${task3.taskId}")
    val result3 = customAgent.processTask(task3)
    println("Task completed with status: ${result3.status}")
    println("Error: ${result3.errorMessage}")
    
    // Check status after processing tasks
    val status2 = customAgent.getStatus()
    println("\nCustom Agent Status:")
    println("  State: ${status2.state}")
    println("  Healthy: ${status2.healthy}")
    println("  Tasks Completed: ${status2.tasksCompleted}")
    println("  Tasks Failed: ${status2.tasksFailed}")
    
    println("\n----------------------------------------------\n")
    
    // Demonstrate event processing
    println("Demonstrating event processing...")
    customAgent.processEvent(AgentEvent.Initialize)
    println("Sent Initialize event")
    delay(100)
    
    // Create a task event
    val taskEvent = AgentEvent.Process(AgentTask(
        taskId = "event-task-" + UUID.randomUUID().toString().substring(0, 8),
        taskType = "example.event",
        parameters = mapOf("source" to "event")
    ))
    
    customAgent.processEvent(taskEvent)
    println("Sent Process event with task: ${(taskEvent as AgentEvent.Process).task.taskId}")
    delay(100)
    
    // Send shutdown event
    customAgent.processEvent(AgentEvent.Shutdown)
    println("Sent Shutdown event")
    delay(100)
    
    // Check final status
    val finalStatus = customAgent.getStatus()
    println("\nFinal Agent Status:")
    println("  State: ${finalStatus.state}")
    
    println("\nExample completed successfully")
}

/**
 * Example output:
 * 
 * Starting SmolAgent Example
 * Initializing basic agent...
 * Initialization succeeded
 * Processing task: task-1234abcd
 * Task completed with status: COMPLETED
 * Result: Task processed by SmolAgent
 * 
 * Agent Status:
 *   State: Idle
 *   Healthy: true
 *   Tasks Completed: 1
 *   Tasks Failed: 0
 * 
 * ----------------------------------------------
 * 
 * Creating agent with custom task handler...
 * Processing successful task: task-5678efgh
 * Custom handler processing: example.success
 * Task completed with status: COMPLETED
 * Result: Successfully processed task
 * 
 * Processing failure task: task-9012ijkl
 * Custom handler processing: example.failure
 * Task completed with status: FAILED
 * Error: Simulated failure
 * 
 * Custom Agent Status:
 *   State: Idle
 *   Healthy: true
 *   Tasks Completed: 1
 *   Tasks Failed: 1
 * 
 * ----------------------------------------------
 * 
 * Demonstrating event processing...
 * Sent Initialize event
 * Sent Process event with task: event-task-3456mnop
 * Sent Shutdown event
 * 
 * Final Agent Status:
 *   State: ShuttingDown
 * 
 * Example completed successfully
 */