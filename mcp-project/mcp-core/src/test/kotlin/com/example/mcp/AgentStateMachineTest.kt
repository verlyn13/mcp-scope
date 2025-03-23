package com.example.mcp

import com.example.agents.Capability
import com.example.agents.McpAgent
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

@ExperimentalCoroutinesApi
class AgentStateMachineTest {

    private lateinit var mockAgent: McpAgent
    private lateinit var stateMachine: AgentStateMachine

    @BeforeEach
    fun setup() {
        // Create a mock agent
        mockAgent = mockk(relaxed = true) {
            every { agentId } returns "test-agent"
            every { capabilities } returns setOf(Capability.TESTING)
            every { getStatus() } returns AgentStatus("test-agent", AgentState.Idle, "Test Agent", "")
            coEvery { initialize() } returns Unit
            coEvery { shutdown() } returns Unit
            coEvery { processTask(any()) } returns TaskResult(
                taskId = "test-task",
                status = TaskStatus.COMPLETED,
                result = "success",
                processingTimeMs = 100
            )
        }

        // Create the state machine with the mock agent
        stateMachine = AgentStateMachine(mockAgent)
    }

    @Test
    fun `initial state should be Idle`() {
        // Verify initial state
        assertEquals(AgentState.Idle, stateMachine.getCurrentState())
    }

    @Test
    fun `initialize should transition to Initializing state`() = runTest {
        // Call initialize
        stateMachine.initialize()
        
        // Verify state transition to Initializing
        assertEquals(AgentState.Initializing, stateMachine.getCurrentState())
        
        // Advance coroutine time to allow initialization to complete
        advanceUntilIdle()
        
        // Verify the initialize method was called on the agent
        coVerify { mockAgent.initialize() }
    }

    @Test
    fun `successful initialization should transition to Idle state`() = runTest {
        // Configure mock agent to successfully initialize
        coEvery { mockAgent.initialize() } returns Unit
        
        // Initialize the state machine
        stateMachine.initialize()
        
        // Advance coroutine time to allow initialization to complete
        advanceUntilIdle()
        
        // After successful initialization, should be in Idle state
        assertEquals(AgentState.Idle, stateMachine.getCurrentState())
    }

    @Test
    fun `failed initialization should transition to Error state`() = runTest {
        // Configure mock agent to throw exception during initialization
        coEvery { mockAgent.initialize() } throws Exception("Initialization failed")
        
        // Initialize the state machine
        stateMachine.initialize()
        
        // Advance coroutine time to allow initialization to complete
        advanceUntilIdle()
        
        // After failed initialization, should be in Error state
        assertEquals(AgentState.Error, stateMachine.getCurrentState())
    }

    @Test
    fun `process task should transition to Processing state`() = runTest {
        // Create a test task
        val task = AgentTask(
            taskId = "test-task", 
            agentType = "test-agent",
            payload = "{\"test\": \"data\"}"
        )
        
        // Start from Idle state
        stateMachine.initialize()
        advanceUntilIdle()
        
        // Process the task
        stateMachine.processTask(AgentEvent.Process(task))
        
        // Verify state transition to Processing
        assertEquals(AgentState.Processing, stateMachine.getCurrentState())
    }

    @Test
    fun `shutdown should transition to ShuttingDown state`() = runTest {
        // Call shutdown
        stateMachine.shutdown()
        
        // Verify state transition to ShuttingDown
        assertEquals(AgentState.ShuttingDown, stateMachine.getCurrentState())
        
        // Advance coroutine time to allow shutdown to complete
        advanceUntilIdle()
        
        // Verify the shutdown method was called on the agent
        coVerify { mockAgent.shutdown() }
    }

    @Test
    fun `reporting error should transition to Error state`() = runTest {
        // Report an error
        val exception = Exception("Test error")
        stateMachine.reportError(exception)
        
        // Verify state transition to Error
        assertEquals(AgentState.Error, stateMachine.getCurrentState())
    }
}