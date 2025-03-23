package com.example.mcp

import com.example.agents.McpAgent
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.tinder.StateMachine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.util.concurrent.CopyOnWriteArrayList

// Type alias for state change listener function
typealias StateChangeListener = (oldState: AgentState, newState: AgentState) -> Unit

class AgentStateMachine(private val agent: McpAgent) {
    private val logger = LoggerFactory.getLogger("${AgentStateMachine::class.java.name}:${agent.agentId}")
    private val scope = CoroutineScope(Dispatchers.Default)
    private val stateChangeListeners = CopyOnWriteArrayList<StateChangeListener>()
    
    private val stateMachine = StateMachine.create<AgentState, AgentEvent, Unit> {
        initialState(AgentState.Idle)
        
        state<AgentState.Idle> {
            on<AgentEvent.Initialize> {
                logger.info("Agent ${agent.agentId} initializing")
                transitionTo(AgentState.Initializing, notifyStateChange(AgentState.Idle))
            }
            
            on<AgentEvent.Process> {
                logger.info("Agent ${agent.agentId} processing task ${it.task?.taskId ?: "<no task>"}")
                transitionTo(AgentState.Processing, notifyStateChange(AgentState.Idle))
            }
            
            on<AgentEvent.Shutdown> {
                logger.info("Agent ${agent.agentId} shutting down")
                transitionTo(AgentState.ShuttingDown, notifyStateChange(AgentState.Idle))
            }
        }
        
        state<AgentState.Initializing> {
            onEnter {
                scope.launch {
                    try {
                        agent.initialize()
                        logger.info("Agent ${agent.agentId} initialized successfully")
                        stateMachine.transition(AgentEvent.Process(null))
                    } catch (e: Exception) {
                        logger.error("Agent ${agent.agentId} initialization failed", e)
                        stateMachine.transition(AgentEvent.Error(e))
                    }
                }
            }
            
            on<AgentEvent.Process> {
                transitionTo(AgentState.Idle, notifyStateChange(AgentState.Initializing))
            }
            
            on<AgentEvent.Error> {
                transitionTo(AgentState.Error, notifyStateChange(AgentState.Initializing))
            }
        }
        
        state<AgentState.Processing> {
            onEnter {
                // Process the task if available
                val task = stateMachine.state.transition.event.task
                if (task != null) {
                    scope.launch {
                        try {
                            logger.info("Agent ${agent.agentId} processing task ${task.taskId}")
                            val result = agent.processTask(task)
                            logger.info("Agent ${agent.agentId} completed task ${task.taskId} with status ${result.status}")
                            
                            // Transition back to idle when completed
                            stateMachine.transition(AgentEvent.Process(null))
                        } catch (e: Exception) {
                            logger.error("Agent ${agent.agentId} failed to process task ${task.taskId}", e)
                            stateMachine.transition(AgentEvent.Error(e))
                        }
                    }
                } else {
                    // If there's no task, go back to idle
                    stateMachine.transition(AgentEvent.Process(null))
                }
            }
            
            on<AgentEvent.Process> {
                if (it.task == null) {
                    // Back to idle if no task
                    transitionTo(AgentState.Idle, notifyStateChange(AgentState.Processing))
                } else {
                    // Stay in processing if there's a task
                    dontTransition()
                }
            }
            
            on<AgentEvent.Error> {
                transitionTo(AgentState.Error, notifyStateChange(AgentState.Processing))
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown, notifyStateChange(AgentState.Processing))
            }
        }
        
        state<AgentState.Error> {
            on<AgentEvent.Initialize> {
                transitionTo(AgentState.Initializing, notifyStateChange(AgentState.Error))
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown, notifyStateChange(AgentState.Error))
            }
            
            // Allow retry from error state
            on<AgentEvent.Process> {
                if (it.task != null) {
                    transitionTo(AgentState.Processing, notifyStateChange(AgentState.Error))
                }
            }
        }
        
        state<AgentState.ShuttingDown> {
            onEnter {
                scope.launch {
                    try {
                        agent.shutdown()
                        logger.info("Agent ${agent.agentId} shut down successfully")
                    } catch (e: Exception) {
                        logger.error("Agent ${agent.agentId} shutdown failed", e)
                    }
                }
            }
        }
    }
    
    // Helper function to create a state transition callback that notifies listeners
    private fun notifyStateChange(oldState: AgentState): (AgentState) -> Unit = { newState ->
        stateChangeListeners.forEach { listener ->
            try {
                listener(oldState, newState)
            } catch (e: Exception) {
                logger.error("Error in state change listener", e)
            }
        }
    }
    
    /**
     * Adds a listener that will be called whenever the agent's state changes.
     * @param listener A function that takes the old state and new state as parameters
     */
    fun addStateChangeListener(listener: StateChangeListener) {
        stateChangeListeners.add(listener)
    }
    
    /**
     * Removes a previously added state change listener.
     * @param listener The listener to remove
     */
    fun removeStateChangeListener(listener: StateChangeListener) {
        stateChangeListeners.remove(listener)
    }
    
    fun initialize() {
        stateMachine.transition(AgentEvent.Initialize)
    }
    
    fun processTask(event: AgentEvent.Process) {
        stateMachine.transition(event)
    }
    
    fun shutdown() {
        stateMachine.transition(AgentEvent.Shutdown)
    }
    
    fun reportError(exception: Exception) {
        stateMachine.transition(AgentEvent.Error(exception))
    }
    
    fun getCurrentState(): AgentState = stateMachine.state
}