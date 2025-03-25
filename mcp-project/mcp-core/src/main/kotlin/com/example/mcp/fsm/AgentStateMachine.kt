package com.example.mcp.fsm

import com.example.agents.McpAgent
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.tinder.StateMachine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory

/**
 * The Finite State Machine (FSM) that manages agent lifecycle transitions.
 * 
 * This class wraps the Tinder StateMachine implementation and provides a 
 * higher-level interface for managing agent state transitions based on events.
 */
class AgentStateMachine(private val agent: McpAgent) {
    private val logger = LoggerFactory.getLogger(AgentStateMachine::class.java)
    
    // Coroutine scope for async operations
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // State change listener for external observers
    var onStateChanged: ((oldState: AgentState, newState: AgentState) -> Unit)? = null
    
    // Internal state machine implementation using Tinder StateMachine
    private val stateMachine = StateMachine.create<AgentState, AgentEvent, Unit> {
        initialState(AgentState.Idle)
        
        state<AgentState.Idle> {
            on<AgentEvent.Initialize> {
                transitionTo(AgentState.Initializing)
            }
        }
        
        state<AgentState.Initializing> {
            onEnter {
                scope.launch {
                    try {
                        val success = agent.initialize()
                        if (success) {
                            transitionTo(AgentState.Idle)
                        } else {
                            transitionTo(AgentState.Error("Initialization failed"))
                        }
                    } catch (e: Exception) {
                        logger.error("Error during agent initialization", e)
                        transitionTo(AgentState.Error("Initialization error", e))
                    }
                }
            }
        }
        
        state<AgentState.Idle> {
            on<AgentEvent.Process> { event ->
                transitionTo(AgentState.Processing)
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown)
            }
        }
        
        state<AgentState.Processing> {
            onEnter {
                try {
                    // This would be implemented to actually process the task
                    // For now, just transition back to Idle
                    transitionTo(AgentState.Idle)
                } catch (e: Exception) {
                    logger.error("Error during task processing", e)
                    transitionTo(AgentState.Error("Processing error", e))
                }
            }
            
            on<AgentEvent.Complete> {
                transitionTo(AgentState.Idle)
            }
            
            on<AgentEvent.Error> { event ->
                transitionTo(AgentState.Error(event.message ?: "Unknown error", event.exception))
            }
        }
        
        state<AgentState.Error> {
            onEnter { state ->
                val errorState = state as AgentState.Error
                scope.launch {
                    try {
                        val recovered = agent.handleError(errorState.exception ?: Exception(errorState.message))
                        if (recovered) {
                            transitionTo(AgentState.Idle)
                        }
                        // Stay in Error state if not recovered
                    } catch (e: Exception) {
                        // Still in Error state, but with new exception details
                        logger.error("Error during recovery attempt", e)
                        transitionTo(AgentState.Error("Error during recovery", e))
                    }
                }
            }
            
            on<AgentEvent.Initialize> {
                transitionTo(AgentState.Initializing)
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown)
            }
        }
        
        state<AgentState.ShuttingDown> {
            onEnter {
                scope.launch {
                    try {
                        agent.shutdown()
                        // Terminal state, no transition
                        logger.info("Agent ${agent.agentId} has shut down successfully")
                    } catch (e: Exception) {
                        // Even if shutdown fails, we consider the agent terminated
                        logger.error("Error during agent shutdown", e)
                        // Log the exception but don't transition
                    }
                }
            }
        }
        
        onTransition { transition ->
            val oldState = transition.fromState
            val newState = transition.toState
            
            // Log the transition
            logger.info("Agent ${agent.agentId} transitioning from $oldState to $newState")
            
            // Notify observers
            onStateChanged?.invoke(oldState, newState)
        }
    }
    
    /**
     * Process an event through the state machine.
     * This will trigger state transitions according to the defined rules.
     * 
     * @param event The event to process
     */
    fun process(event: AgentEvent) {
        logger.debug("Processing event $event for agent ${agent.agentId}")
        stateMachine.transition(event)
    }
    
    /**
     * Get the current state of the agent.
     * 
     * @return The current AgentState
     */
    fun getCurrentState(): AgentState = stateMachine.state
}