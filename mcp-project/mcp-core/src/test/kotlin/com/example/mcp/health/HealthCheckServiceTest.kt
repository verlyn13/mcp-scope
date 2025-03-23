package com.example.mcp.health

import com.example.agents.Capability
import com.example.agents.McpAgent
import com.example.mcp.models.AgentState
import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import io.mockk.coEvery
import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import io.nats.client.Connection
import io.nats.client.Dispatcher
import io.nats.client.Message
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds

@ExperimentalCoroutinesApi
class HealthCheckServiceTest {

    private lateinit var healthCheckService: HealthCheckService
    private lateinit var mockConnection: Connection
    private lateinit var mockDispatcher: Dispatcher
    private lateinit var mockAgent: McpAgent
    
    @BeforeEach
    fun setup() {
        // Create mock NATS connection and dispatcher
        mockDispatcher = mockk(relaxed = true)
        mockConnection = mockk(relaxed = true) {
            every { createDispatcher(any()) } returns mockDispatcher
        }
        
        // Create a mock agent
        mockAgent = mockk(relaxed = true) {
            every { agentId } returns "test-agent"
            every { capabilities } returns setOf(Capability.TESTING)
            every { getStatus() } returns AgentStatus("test-agent", AgentState.Idle, "Test Agent", "")
            coEvery { processTask(any()) } returns TaskResult(
                taskId = "test-task",
                status = TaskStatus.COMPLETED,
                result = "success",
                processingTimeMs = 100
            )
        }
        
        // Create the health check service with shorter intervals for testing
        healthCheckService = HealthCheckService(
            natsConnection = mockConnection,
            metricsCollectionInterval = 5.seconds,
            circuitBreakerThreshold = 3,
            circuitBreakerResetTimeout = 10.seconds
        )
    }
    
    @AfterEach
    fun tearDown() {
        healthCheckService.stop()
    }
    
    @Test
    fun `initialization should set up NATS subscriptions`() {
        // Verify subscriptions were created
        verify(exactly = 1) {
            mockDispatcher.subscribe("mcp.health.system")
            mockDispatcher.subscribe("mcp.health.agent")
        }
    }
    
    @Test
    fun `getSystemHealth should return valid system health status`() {
        // When
        val healthStatus = healthCheckService.getSystemHealth()
        
        // Then
        assertNotNull(healthStatus)
        // No agents registered yet, so status should be UNKNOWN
        assertEquals(HealthStatus.UNKNOWN, healthStatus.status)
        assertEquals(0, healthStatus.agentCount)
        assertNotNull(healthStatus.timestamp)
        assertEquals(false, healthStatus.circuitBreakerOpen)
    }
    
    @Test
    fun `updateAgentHealth should update agent status correctly`() {
        // When
        healthCheckService.updateAgentHealth(mockAgent, AgentState.Idle)
        
        // Then
        val agentHealth = healthCheckService.getAgentHealth("test-agent")
        assertNotNull(agentHealth)
        assertEquals("test-agent", agentHealth.agentId)
        assertEquals(HealthStatus.HEALTHY, agentHealth.status)
        assertEquals(listOf("TESTING"), agentHealth.capabilities)
    }
    
    @Test
    fun `getAgentHealth should return null for unknown agent`() {
        // When
        val result = healthCheckService.getAgentHealth("unknown-agent")
        
        // Then
        assertNull(result)
    }
    
    @Test
    fun `system health status should reflect agent states`() = runTest {
        // Given - register agents in different states
        val mockAgent1 = mockk<McpAgent>(relaxed = true) {
            every { agentId } returns "agent1"
            every { capabilities } returns setOf(Capability.TESTING)
            every { getStatus() } returns AgentStatus("agent1", AgentState.Idle, "Agent 1", "")
        }
        
        val mockAgent2 = mockk<McpAgent>(relaxed = true) {
            every { agentId } returns "agent2"
            every { capabilities } returns setOf(Capability.CAMERA_DETECTION)
            every { getStatus() } returns AgentStatus("agent2", AgentState.Error, "Agent 2", "")
        }
        
        // When - update health status for both agents
        healthCheckService.updateAgentHealth(mockAgent1, AgentState.Idle)
        healthCheckService.updateAgentHealth(mockAgent2, AgentState.Error)
        
        // Then - system health should be DEGRADED due to one unhealthy agent
        val systemHealth = healthCheckService.getSystemHealth()
        assertEquals(HealthStatus.DEGRADED, systemHealth.status)
        assertEquals(2, systemHealth.agentCount)
    }
    
    @Test
    fun `NATS message handler should respond to health check requests`() = runTest {
        // Given - capture the message handler
        val handlerSlot = slot<(Message) -> Unit>()
        verify { mockConnection.createDispatcher(capture(handlerSlot)) }
        
        // Register an agent
        healthCheckService.updateAgentHealth(mockAgent, AgentState.Idle)
        
        // Create mock messages
        val systemHealthMsg = mockk<Message>(relaxed = true) {
            every { subject } returns "mcp.health.system"
            justRun { respond(any()) }
        }
        
        val agentHealthMsg = mockk<Message>(relaxed = true) {
            every { subject } returns "mcp.health.agent"
            every { data } returns "test-agent".toByteArray()
            justRun { respond(any()) }
        }
        
        // When - call the handler with test messages
        handlerSlot.captured.invoke(systemHealthMsg)
        handlerSlot.captured.invoke(agentHealthMsg)
        
        // Advance time to allow coroutines to complete
        advanceTimeBy(1000)
        
        // Then - verify responses were sent
        verify(exactly = 1) {
            systemHealthMsg.respond(any())
            agentHealthMsg.respond(any())
        }
    }
}