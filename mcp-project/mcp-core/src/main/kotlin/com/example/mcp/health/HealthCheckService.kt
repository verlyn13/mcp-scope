package com.example.mcp.health

import com.example.agents.McpAgent
import com.example.mcp.models.AgentState
import io.nats.client.Connection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Service for monitoring system and agent health and providing health check endpoints.
 */
class HealthCheckService(
    private val natsConnection: Connection,
    private val metricsCollectionInterval: Duration = 15.seconds,
    private val circuitBreakerThreshold: Int = 5,
    private val circuitBreakerResetTimeout: Duration = 30.seconds
) {
    private val logger = LoggerFactory.getLogger(HealthCheckService::class.java)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val json = Json { prettyPrint = true }
    
    private val metricsCollector = SystemMetricsCollector()
    private val healthCheckJob: Job
    
    // Store the latest collected metrics
    private val latestMetrics = AtomicReference<SystemMetrics>()
    
    // Map to track agent health status
    private val agentHealthStatus = ConcurrentHashMap<String, AgentHealthStatus>()
    
    // Circuit breaker state
    private val failureCounter = AtomicInteger(0)
    private val circuitOpen = AtomicBoolean(false)
    private var circuitResetJob: Job? = null
    
    init {
        // Start metrics collection job
        healthCheckJob = scope.launch {
            while (isActive) {
                try {
                    collectAndPublishMetrics()
                    delay(metricsCollectionInterval)
                } catch (e: Exception) {
                    logger.error("Error in health check job", e)
                    // Implement circuit breaker pattern
                    handleFailure()
                    delay(1.seconds) // Short delay before retry
                }
            }
        }
        
        // Set up NATS subscriptions for health check requests
        setupNatsSubscriptions()
        
        logger.info("Health check service initialized with collection interval: $metricsCollectionInterval")
    }
    
    /**
     * Gets the current system health status.
     * @return SystemHealthStatus containing health information
     */
    fun getSystemHealth(): SystemHealthStatus {
        val metrics = latestMetrics.get()
        val agents = agentHealthStatus.values.toList()
        
        return SystemHealthStatus(
            status = determineOverallStatus(agents),
            uptime = ManagementFactory.getRuntimeMXBean().uptime,
            agentCount = agents.size,
            metrics = metrics,
            agents = agents,
            circuitBreakerOpen = circuitOpen.get(),
            timestamp = System.currentTimeMillis()
        )
    }
    
    /**
     * Updates the health status for an agent.
     * @param agent The agent to update
     * @param state The current state of the agent
     */
    fun updateAgentHealth(agent: McpAgent, state: AgentState) {
        val status = agent.getStatus()
        val healthStatus = AgentHealthStatus(
            agentId = agent.agentId,
            status = mapStateToHealthStatus(state),
            capabilities = agent.capabilities.map { it.name },
            lastUpdateTimestamp = System.currentTimeMillis(),
            details = status.statusDetails
        )
        
        agentHealthStatus[agent.agentId] = healthStatus
        logger.debug("Updated health status for agent ${agent.agentId}: $state")
    }
    
    /**
     * Gets the health status for a specific agent.
     * @param agentId The ID of the agent
     * @return AgentHealthStatus or null if agent not found
     */
    fun getAgentHealth(agentId: String): AgentHealthStatus? {
        return agentHealthStatus[agentId]
    }
    
    /**
     * Collects metrics and publishes them via NATS.
     */
    private suspend fun collectAndPublishMetrics() {
        if (circuitOpen.get()) {
            logger.warn("Circuit is open, skipping metrics collection")
            return
        }
        
        try {
            val metrics = metricsCollector.collectMetrics()
            latestMetrics.set(metrics)
            
            // Publish metrics to NATS
            val metricsJson = json.encodeToString(metrics)
            natsConnection.publish("mcp.health.metrics", metricsJson.toByteArray())
            
            // Reset failure counter on success
            failureCounter.set(0)
            
            logger.debug("Collected and published system metrics")
        } catch (e: Exception) {
            logger.error("Failed to collect or publish metrics", e)
            handleFailure()
        }
    }
    
    /**
     * Sets up NATS subscriptions for health check requests.
     */
    private fun setupNatsSubscriptions() {
        // Subscribe to health check requests
        natsConnection.createDispatcher { msg ->
            scope.launch {
                try {
                    when (msg.subject) {
                        "mcp.health.system" -> {
                            val healthStatus = getSystemHealth()
                            val response = json.encodeToString(healthStatus)
                            msg.respond(response.toByteArray())
                        }
                        "mcp.health.agent" -> {
                            val agentId = String(msg.data)
                            val agentHealth = getAgentHealth(agentId)
                            val response = if (agentHealth != null) {
                                json.encodeToString(agentHealth)
                            } else {
                                "{\"error\":\"Agent not found\"}"
                            }
                            msg.respond(response.toByteArray())
                        }
                    }
                } catch (e: Exception) {
                    logger.error("Error processing health check request", e)
                    msg.respond("{\"error\":\"Internal error\"}".toByteArray())
                }
            }
        }.apply {
            subscribe("mcp.health.system")
            subscribe("mcp.health.agent")
        }
        
        logger.info("Health check NATS subscriptions established")
    }
    
    /**
     * Handles failures using the circuit breaker pattern.
     */
    private fun handleFailure() {
        val failures = failureCounter.incrementAndGet()
        
        if (failures >= circuitBreakerThreshold && !circuitOpen.get()) {
            // Open the circuit
            circuitOpen.set(true)
            logger.warn("Circuit breaker opened after $failures consecutive failures")
            
            // Schedule circuit reset
            circuitResetJob = scope.launch {
                delay(circuitBreakerResetTimeout)
                // Try to reset circuit
                resetCircuit()
            }
        }
    }
    
    /**
     * Resets the circuit breaker.
     */
    private fun resetCircuit() {
        circuitOpen.set(false)
        failureCounter.set(0)
        logger.info("Circuit breaker reset")
    }
    
    /**
     * Maps agent state to health status.
     */
    private fun mapStateToHealthStatus(state: AgentState): HealthStatus {
        return when (state) {
            is AgentState.Idle, is AgentState.Processing -> HealthStatus.HEALTHY
            is AgentState.Initializing -> HealthStatus.STARTING
            is AgentState.Error -> HealthStatus.UNHEALTHY
            is AgentState.ShuttingDown -> HealthStatus.STOPPING
        }
    }
    
    /**
     * Determines the overall system health status based on agent statuses.
     */
    private fun determineOverallStatus(agents: List<AgentHealthStatus>): HealthStatus {
        if (agents.isEmpty()) return HealthStatus.UNKNOWN
        
        val unhealthyCount = agents.count { it.status == HealthStatus.UNHEALTHY }
        val healthyCount = agents.count { it.status == HealthStatus.HEALTHY }
        
        return when {
            unhealthyCount == agents.size -> HealthStatus.UNHEALTHY
            unhealthyCount > 0 -> HealthStatus.DEGRADED
            healthyCount == agents.size -> HealthStatus.HEALTHY
            else -> HealthStatus.DEGRADED
        }
    }
    
    /**
     * Stops the health check service.
     */
    fun stop() {
        healthCheckJob.cancel()
        circuitResetJob?.cancel()
        logger.info("Health check service stopped")
    }
}

/**
 * Enum representing health status.
 */
enum class HealthStatus {
    HEALTHY,
    DEGRADED,
    UNHEALTHY,
    STARTING,
    STOPPING,
    UNKNOWN
}

/**
 * Data classes for health status information
 */
@Serializable
data class SystemHealthStatus(
    val status: HealthStatus,
    val uptime: Long,
    val agentCount: Int,
    val metrics: SystemMetrics?,
    val agents: List<AgentHealthStatus>,
    val circuitBreakerOpen: Boolean,
    val timestamp: Long
)

@Serializable
data class AgentHealthStatus(
    val agentId: String,
    val status: HealthStatus,
    val capabilities: List<String>,
    val lastUpdateTimestamp: Long,
    val details: String
)