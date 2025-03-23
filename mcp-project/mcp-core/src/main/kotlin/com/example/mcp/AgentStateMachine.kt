package com.example.mcp

import com.example.agents.McpAgent
import com.example.mcp.models.AgentEvent
import com.example.mcp.models.AgentState
import com.tinder.StateMachine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory

class AgentStateMachine(private val agent: McpAgent) {
    private val logger = LoggerFactory.getLogger("${AgentStateMachine::class.java.name}:${agent.agentId}")
    private val scope = CoroutineScope(Dispatchers.Default)
    
    private val stateMachine = StateMachine.create<AgentState, AgentEvent, Unit> {
        initialState(AgentState.Idle)
        
        state<AgentState.Idle> {
            on<AgentEvent.Initialize> {
                logger.info("Agent ${agent.agentId} initializing")
                transitionTo(AgentState.Initializing)
            }
            
            on<AgentEvent.Process> {
                logger.info("Agent ${agent.agentId} processing task ${it.task.taskId}")
                transitionTo(AgentState.Processing)
            }
            
            on<AgentEvent.Shutdown> {
                logger.info("Agent ${agent.agentId} shutting down")
                transitionTo(AgentState.ShuttingDown)
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
                transitionTo(AgentState.Idle)
            }
            
            on<AgentEvent.Error> {
                transitionTo(AgentState.Error)
            }
        }
        
        state<AgentState.Processing> {
            on<AgentEvent.Process> {
                // Continue processing
                dontTransition()
            }
            
            on<AgentEvent.Error> {
                transitionTo(AgentState.Error)
            }
            
            on<AgentEvent.Shutdown> {
                transitionTo(AgentState.ShuttingDown)
            }
        }
        
        state<AgentState.Error> {
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
                        logger.info("Agent ${agent.agentId} shut down successfully")
                    } catch (e: Exception) {
                        logger.error("Agent ${agent.agentId} shutdown failed", e)
                    }
                }
            }
        }
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