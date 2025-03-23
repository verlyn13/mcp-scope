# Health Monitoring and Resilience Framework Specification

## Overview

This document specifies the design of the Health Monitoring and Resilience Framework for the Multi-Agent Control Platform (MCP). This framework ensures system stability, provides visibility into component health, and implements recovery mechanisms for fault tolerance.

## Core Components

### 1. Health Monitoring Service

The Health Monitoring Service regularly checks the health of all system components:

```kotlin
class HealthMonitoringService(
    private val natsConnection: Connection,
    private val orchestrator: Orchestrator,
    private val config: HealthMonitorConfig
) {
    private val logger = LoggerFactory.getLogger(HealthMonitoringService::class.java)
    
    // Coroutine scope for monitoring activities
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Agent health states
    private val agentHealthStates = ConcurrentHashMap<String, AgentHealthState>()
    
    // System metrics
    private val systemMetrics = SystemMetricsCollector()
    
    // Initialize and start the monitoring service
    fun start() {
        logger.info("Starting health monitoring service")
        
        // Set up NATS subscriptions
        setupSubscriptions()
        
        // Start periodic health check
        startPeriodicHealthCheck()
        
        // Start system metrics collection
        startMetricsCollection()
        
        logger.info("Health monitoring service started")
    }
    
    // Stop the monitoring service
    fun stop() {
        logger.info("Stopping health monitoring service")
        
        scope.cancel()
        
        logger.info("Health monitoring service stopped")
    }
    
    // Set up NATS subscriptions
    private fun setupSubscriptions() {
        val dispatcher = natsConnection.createDispatcher { message ->
            scope.launch {
                handleNatsMessage(message)
            }
        }
        
        // Subscribe to heartbeat messages from all agents
        dispatcher.subscribe("mcp.agent.*.heartbeat")
        
        // Subscribe to status messages from all agents
        dispatcher.subscribe("mcp.agent.*.status")
        
        // Subscribe to health check requests
        dispatcher.subscribe("mcp.health.check")
    }
    
    // Start periodic health check
    private fun startPeriodicHealthCheck() {
        scope.launch {
            while (isActive) {
                try {
                    performHealthCheck()
                    delay(config.healthCheckIntervalMs)
                } catch (e: Exception) {
                    logger.error("Error during periodic health check", e)
                    delay(1000) // Short delay before retry
                }
            }
        }
    }
    
    // Start system metrics collection
    private fun startMetricsCollection() {
        scope.launch {
            while (isActive) {
                try {
                    collectSystemMetrics()
                    delay(config.metricsCollectionIntervalMs)
                } catch (e: Exception) {
                    logger.error("Error during metrics collection", e)
                    delay(1000) // Short delay before retry
                }
            }
        }
    }
    
    // Handle NATS messages
    private fun handleNatsMessage(message: Message) {
        when {
            message.subject.matches(Regex("mcp\\.agent\\.(.*)\\.heartbeat")) -> {
                handleHeartbeatMessage(message)
            }
            message.subject.matches(Regex("mcp\\.agent\\.(.*)\\.status")) -> {
                handleStatusMessage(message)
            }
            message.subject == "mcp.health.check" -> {
                handleHealthCheckRequest(message)
            }
        }
    }
    
    // Handle heartbeat message from an agent
    private fun handleHeartbeatMessage(message: Message) {
        try {
            val subject = message.subject
            val agentId = subject.split(".")[2] // Extract agent ID from topic
            
            val heartbeatMessage = Json.decodeFromString<HeartbeatMessage>(
                String(message.data)
            )
            
            // Update agent health state
            val healthState = agentHealthStates.getOrPut(agentId) {
                AgentHealthState(agentId)
            }
            
            healthState.lastHeartbeat = System.currentTimeMillis()
            healthState.metrics = heartbeatMessage.metrics
            healthState.consecutiveFailures = 0
            
            logger.debug("Received heartbeat from agent: $agentId")
        } catch (e: Exception) {
            logger.error("Error handling heartbeat message", e)
        }
    }
    
    // Handle status message from an agent
    private fun handleStatusMessage(message: Message) {
        try {
            val subject = message.subject
            val agentId = subject.split(".")[2] // Extract agent ID from topic
            
            val statusMessage = Json.decodeFromString<AgentStatusMessage>(
                String(message.data)
            )
            
            // Update agent health state
            val healthState = agentHealthStates.getOrPut(agentId) {
                AgentHealthState(agentId)
            }
            
            healthState.lastStatus = statusMessage.status
            healthState.lastStatusTimestamp = System.currentTimeMillis()
            
            // Check if agent is in error state
            if (statusMessage.status.state is AgentState.Error) {
                handleAgentInErrorState(agentId, statusMessage.status)
            }
            
            logger.debug("Received status update from agent: $agentId")
        } catch (e: Exception) {
            logger.error("Error handling status message", e)
        }
    }
    
    // Handle health check request
    private fun handleHealthCheckRequest(message: Message) {
        try {
            // Generate health report
            val healthReport = generateHealthReport()
            
            // Respond if reply-to is set
            if (message.replyTo != null) {
                val response = HealthCheckResponse(
                    messageId = UUID.randomUUID().toString(),
                    timestamp = System.currentTimeMillis(),
                    healthReport = healthReport
                )
                
                natsConnection.publish(
                    message.replyTo,
                    Json.encodeToString(response).toByteArray()
                )
            }
            
            logger.debug("Processed health check request")
        } catch (e: Exception) {
            logger.error("Error handling health check request", e)
        }
    }
    
    // Perform health check on all agents
    private suspend fun performHealthCheck() {
        logger.debug("Performing system health check")
        
        val now = System.currentTimeMillis()
        val agentIds = orchestrator.getRegisteredAgentIds()
        
        for (agentId in agentIds) {
            val healthState = agentHealthStates[agentId]
            
            if (healthState == null) {
                // Agent has never reported health
                requestAgentStatus(agentId)
                continue
            }
            
            // Check if heartbeat is overdue
            val heartbeatAge = now - healthState.lastHeartbeat
            if (heartbeatAge > config.heartbeatTimeoutMs) {
                logger.warn("Agent $agentId has not sent heartbeat for ${heartbeatAge}ms")
                
                // Increment consecutive failures
                healthState.consecutiveFailures++
                
                // Request agent status
                requestAgentStatus(agentId)
                
                // Check if agent should be considered dead
                if (healthState.consecutiveFailures >= config.maxConsecutiveFailures) {
                    handleDeadAgent(agentId)
                }
            }
        }
        
        // Generate and publish health report
        val healthReport = generateHealthReport()
        publishHealthReport(healthReport)
    }
    
    // Request status from an agent
    private fun requestAgentStatus(agentId: String) {
        try {
            val requestMessage = AgentStatusRequestMessage(
                messageId = UUID.randomUUID().toString(),
                timestamp = System.currentTimeMillis()
            )
            
            natsConnection.publish(
                "mcp.agent.$agentId.status.request",
                Json.encodeToString(requestMessage).toByteArray()
            )
            
            logger.debug("Requested status from agent: $agentId")
        } catch (e: Exception) {
            logger.error("Error requesting agent status", e)
        }
    }
    
    // Handle an agent that is considered dead
    private suspend fun handleDeadAgent(agentId: String) {
        logger.warn("Agent $agentId is considered dead, initiating recovery")
        
        // Get agent info from orchestrator
        val agentInfo = orchestrator.getAgentInfo(agentId)
        if (agentInfo == null) {
            logger.error("Agent $agentId not found in registry")
            return
        }
        
        // Publish agent lost event
        publishAgentLostEvent(agentId, agentInfo.registration.agentType)
        
        // Attempt restart if configured
        if (config.autoRestartAgents) {
            orchestrator.restartAgent(agentId)
        }
    }
    
    // Handle an agent in error state
    private fun handleAgentInErrorState(agentId: String, status: AgentStatus) {
        logger.warn("Agent $agentId is in error state: ${(status.state as AgentState.Error).message}")
        
        // Publish agent error event
        publishAgentErrorEvent(agentId, status)
    }
    
    // Collect system metrics
    private fun collectSystemMetrics() {
        logger.debug("Collecting system metrics")
        
        // Update system metrics
        systemMetrics.update()
        
        // Publish metrics
        publishSystemMetrics(systemMetrics.getMetrics())
    }
    
    // Generate health report
    private fun generateHealthReport(): HealthReport {
        val now = System.currentTimeMillis()
        
        // Compile agent health statuses
        val agentHealths = agentHealthStates.values.map { healthState ->
            val isHealthy = healthState.lastHeartbeat > now - config.heartbeatTimeoutMs
            
            AgentHealth(
                agentId = healthState.agentId,
                isHealthy = isHealthy,
                lastHeartbeat = healthState.lastHeartbeat,
                lastStatus = healthState.lastStatus,
                metrics = healthState.metrics
            )
        }
        
        return HealthReport(
            timestamp = now,
            orchestratorHealth = OrchestratorHealth(
                isHealthy = true, // Determined by the orchestrator itself
                uptime = ManagementFactory.getRuntimeMXBean().uptime,
                activeThreads = Thread.activeCount(),
                metrics = systemMetrics.getMetrics()
            ),
            agentHealths = agentHealths,
            overallSystemHealth = determineOverallHealth(agentHealths)
        )
    }
    
    // Determine overall system health
    private fun determineOverallHealth(agentHealths: List<AgentHealth>): SystemHealthStatus {
        val unhealthyCount = agentHealths.count { !it.isHealthy }
        
        return when {
            unhealthyCount == 0 -> SystemHealthStatus.HEALTHY
            unhealthyCount < agentHealths.size / 2 -> SystemHealthStatus.DEGRADED
            else -> SystemHealthStatus.UNHEALTHY
        }
    }
    
    // Publish health report
    private fun publishHealthReport(report: HealthReport) {
        try {
            val message = HealthReportMessage(
                messageId = UUID.randomUUID().toString(),
                timestamp = System.currentTimeMillis(),
                healthReport = report
            )
            
            natsConnection.publish(
                "mcp.health.report",
                Json.encodeToString(message).toByteArray()
            )
            
            logger.debug("Published health report")
        } catch (e: Exception) {
            logger.error("Error publishing health report", e)
        }
    }
    
    // Publish agent lost event
    private fun publishAgentLostEvent(agentId: String, agentType: String) {
        try {
            val eventMessage = SystemEventMessage(
                eventType = SystemEventType.AGENT_LOST,
                payload = AgentLostPayload(
                    agentId = agentId,
                    agentType = agentType,
                    timestamp = System.currentTimeMillis()
                )
            )
            
            natsConnection.publish(
                "mcp.orchestrator.system.event",
                Json.encodeToString(eventMessage).toByteArray()
            )
            
            logger.warn("Published agent lost event for agent: $agentId")
        } catch (e: Exception) {
            logger.error("Error publishing agent lost event", e)
        }
    }
    
    // Publish agent error event
    private fun publishAgentErrorEvent(agentId: String, status: AgentStatus) {
        try {
            val eventMessage = SystemEventMessage(
                eventType = SystemEventType.AGENT_ERROR,
                payload = AgentErrorPayload(
                    agentId = agentId,
                    errorMessage = (status.state as AgentState.Error).message,
                    exception = (status.state as AgentState.Error).exception?.toString(),
                    timestamp = System.currentTimeMillis()
                )
            )
            
            natsConnection.publish(
                "mcp.orchestrator.system.event",
                Json.encodeToString(eventMessage).toByteArray()
            )
            
            logger.warn("Published agent error event for agent: $agentId")
        } catch (e: Exception) {
            logger.error("Error publishing agent error event", e)
        }
    }
    
    // Publish system metrics
    private fun publishSystemMetrics(metrics: Map<String, Double>) {
        try {
            val metricsMessage = SystemMetricsMessage(
                messageId = UUID.randomUUID().toString(),
                timestamp = System.currentTimeMillis(),
                metrics = metrics
            )
            
            natsConnection.publish(
                "mcp.metrics.system",
                Json.encodeToString(metricsMessage).toByteArray()
            )
            
            logger.debug("Published system metrics")
        } catch (e: Exception) {
            logger.error("Error publishing system metrics", e)
        }
    }
}

data class HealthMonitorConfig(
    val healthCheckIntervalMs: Long = 30000,
    val metricsCollectionIntervalMs: Long = 60000,
    val heartbeatTimeoutMs: Long = 60000,
    val maxConsecutiveFailures: Int = 3,
    val autoRestartAgents: Boolean = true
)

// Internal health state for tracking agent health
data class AgentHealthState(
    val agentId: String,
    var lastHeartbeat: Long = 0,
    var lastStatusTimestamp: Long = 0,
    var lastStatus: AgentStatus? = null,
    var metrics: Map<String, Double> = emptyMap(),
    var consecutiveFailures: Int = 0
)
```

### 2. System Metrics Collector

The SystemMetricsCollector gathers performance metrics from the host system:

```kotlin
class SystemMetricsCollector {
    private val logger = LoggerFactory.getLogger(SystemMetricsCollector::class.java)
    
    // Java runtime
    private val runtime = Runtime.getRuntime()
    
    // Operating system MXBean
    private val osMXBean = ManagementFactory.getOperatingSystemMXBean()
    
    // Memory MXBean
    private val memoryMXBean = ManagementFactory.getMemoryMXBean()
    
    // Metrics storage
    private val metrics = ConcurrentHashMap<String, Double>()
    
    // Update system metrics
    fun update() {
        try {
            // Update CPU metrics
            updateCpuMetrics()
            
            // Update memory metrics
            updateMemoryMetrics()
            
            // Update thread metrics
            updateThreadMetrics()
            
            // Update JVM metrics
            updateJvmMetrics()
        } catch (e: Exception) {
            logger.error("Error updating system metrics", e)
        }
    }
    
    // Get current metrics
    fun getMetrics(): Map<String, Double> {
        return metrics.toMap()
    }
    
    // Update CPU metrics
    private fun updateCpuMetrics() {
        metrics["system.cpu.load"] = osMXBean.systemLoadAverage.takeIf { it >= 0 } ?: 0.0
        
        // On supported platforms, get process CPU load
        if (osMXBean is com.sun.management.OperatingSystemMXBean) {
            metrics["system.cpu.process"] = osMXBean.processCpuLoad
        }
    }
    
    // Update memory metrics
    private fun updateMemoryMetrics() {
        // JVM memory
        val heapMemoryUsage = memoryMXBean.heapMemoryUsage
        val nonHeapMemoryUsage = memoryMXBean.nonHeapMemoryUsage
        
        metrics["jvm.memory.heap.used"] = heapMemoryUsage.used.toDouble()
        metrics["jvm.memory.heap.committed"] = heapMemoryUsage.committed.toDouble()
        metrics["jvm.memory.heap.max"] = heapMemoryUsage.max.toDouble()
        metrics["jvm.memory.nonheap.used"] = nonHeapMemoryUsage.used.toDouble()
        
        // System memory
        metrics["system.memory.free"] = runtime.freeMemory().toDouble()
        metrics["system.memory.total"] = runtime.totalMemory().toDouble()
        metrics["system.memory.max"] = runtime.maxMemory().toDouble()
    }
    
    // Update thread metrics
    private fun updateThreadMetrics() {
        val threadMXBean = ManagementFactory.getThreadMXBean()
        
        metrics["jvm.threads.count"] = threadMXBean.threadCount.toDouble()
        metrics["jvm.threads.peak"] = threadMXBean.peakThreadCount.toDouble()
        metrics["jvm.threads.daemon"] = threadMXBean.daemonThreadCount.toDouble()
    }
    
    // Update JVM metrics
    private fun updateJvmMetrics() {
        // GC metrics
        val gcMXBeans = ManagementFactory.getGarbageCollectorMXBeans()
        
        var totalGcCount = 0L
        var totalGcTime = 0L
        
        for (gcBean in gcMXBeans) {
            totalGcCount += gcBean.collectionCount
            totalGcTime += gcBean.collectionTime
        }
        
        metrics["jvm.gc.count"] = totalGcCount.toDouble()
        metrics["jvm.gc.time"] = totalGcTime.toDouble()
        
        // Uptime
        metrics["jvm.uptime"] = ManagementFactory.getRuntimeMXBean().uptime.toDouble()
    }
}
```

### 3. Circuit Breaker

The CircuitBreaker pattern prevents cascading failures by suspending operations after repeated failures:

```kotlin
class CircuitBreaker(
    private val name: String,
    private val failureThreshold: Int = 5,
    private val resetTimeoutMs: Long = 30000
) {
    private val logger = LoggerFactory.getLogger(CircuitBreaker::class.java)
    
    // Circuit state
    enum class State { CLOSED, OPEN, HALF_OPEN }
    
    // Current state
    private val state = AtomicReference(State.CLOSED)
    
    // Failure count
    private val failureCount = AtomicInteger(0)
    
    // Last failure timestamp
    private val lastFailureTime = AtomicLong(0)
    
    // Execute an operation with circuit breaker protection
    suspend fun <T> execute(operation: suspend () -> T): T {
        // Check if circuit is open
        when (state.get()) {
            State.OPEN -> {
                // Check if reset timeout has elapsed
                val timeElapsed = System.currentTimeMillis() - lastFailureTime.get()
                if (timeElapsed >= resetTimeoutMs) {
                    // Transition to half-open state
                    if (state.compareAndSet(State.OPEN, State.HALF_OPEN)) {
                        logger.info("Circuit $name transitioned from OPEN to HALF_OPEN")
                    }
                } else {
                    // Circuit is still open
                    throw CircuitBreakerOpenException("Circuit $name is open")
                }
            }
            else -> {
                // Circuit is closed or half-open, continue
            }
        }
        
        try {
            // Execute the operation
            val result = operation()
            
            // Operation succeeded, reset failure count
            if (state.get() != State.CLOSED) {
                // Transition to closed state
                state.set(State.CLOSED)
                logger.info("Circuit $name transitioned to CLOSED")
            }
            
            failureCount.set(0)
            
            return result
        } catch (e: Exception) {
            // Record failure
            handleFailure(e)
            throw e
        }
    }
    
    // Handle operation failure
    private fun handleFailure(exception: Exception) {
        // Increment failure count
        val currentFailures = failureCount.incrementAndGet()
        lastFailureTime.set(System.currentTimeMillis())
        
        // Check if threshold reached
        if (currentFailures >= failureThreshold && state.get() == State.CLOSED) {
            // Transition to open state
            state.set(State.OPEN)
            logger.warn("Circuit $name transitioned to OPEN after $currentFailures failures")
        }
        
        // If in half-open state, immediately open on failure
        if (state.get() == State.HALF_OPEN) {
            state.set(State.OPEN)
            logger.warn("Circuit $name transitioned from HALF_OPEN back to OPEN")
        }
    }
    
    // Get current state
    fun getState(): State {
        return state.get()
    }
    
    // Reset the circuit breaker
    fun reset() {
        state.set(State.CLOSED)
        failureCount.set(0)
        logger.info("Circuit $name manually reset to CLOSED")
    }
}

class CircuitBreakerOpenException(message: String) : Exception(message)
```

## Health Models

### 1. Health Report Models

```kotlin
data class HealthReport(
    val timestamp: Long,
    val orchestratorHealth: OrchestratorHealth,
    val agentHealths: List<AgentHealth>,
    val overallSystemHealth: SystemHealthStatus
)

data class OrchestratorHealth(
    val isHealthy: Boolean,
    val uptime: Long,
    val activeThreads: Int,
    val metrics: Map<String, Double>
)

data class AgentHealth(
    val agentId: String,
    val isHealthy: Boolean,
    val lastHeartbeat: Long,
    val lastStatus: AgentStatus?,
    val metrics: Map<String, Double>
)

enum class SystemHealthStatus {
    HEALTHY,    // All components functioning normally
    DEGRADED,   // Some components have issues but system is operational
    UNHEALTHY   // Critical components are failing
}
```

### 2. Health-Related Messages

```kotlin
data class HealthReportMessage(
    override val messageId: String,
    override val timestamp: Long,
    val healthReport: HealthReport
) : NatsMessage

data class HealthCheckResponse(
    override val messageId: String,
    override val timestamp: Long,
    val healthReport: HealthReport
) : NatsMessage

data class AgentStatusRequestMessage(
    override val messageId: String,
    override val timestamp: Long
) : NatsMessage

data class SystemMetricsMessage(
    override val messageId: String,
    override val timestamp: Long,
    val metrics: Map<String, Double>
) : NatsMessage

data class AgentLostPayload(
    val agentId: String,
    val agentType: String,
    val timestamp: Long
)

data class AgentErrorPayload(
    val agentId: String,
    val errorMessage: String,
    val exception: String?,
    val timestamp: Long
)
```

## Fault Tolerance Mechanisms

### 1. Retry Mechanism

A generic retry utility for transient failures:

```kotlin
class RetryPolicy(
    private val maxAttempts: Int = 3,
    private val initialDelayMs: Long = 100,
    private val maxDelayMs: Long = 5000,
    private val multiplier: Double = 2.0,
    private val retryableExceptions: Set<KClass<out Throwable>> = setOf(
        IOException::class,
        TimeoutException::class
    )
) {
    private val logger = LoggerFactory.getLogger(RetryPolicy::class.java)
    
    // Execute with retries
    suspend fun <T> execute(operation: suspend () -> T): T {
        var currentDelay = initialDelayMs
        var attempt = 1
        
        while (true) {
            try {
                // Attempt the operation
                return operation()
            } catch (e: Throwable) {
                // Check if exception is retryable
                if (e::class !in retryableExceptions) {
                    throw e
                }
                
                // Check if max attempts reached
                if (attempt >= maxAttempts) {
                    logger.warn("Retry policy exhausted after $attempt attempts", e)
                    throw e
                }
                
                // Log retry attempt
                logger.info("Operation failed, retrying (${attempt}/${maxAttempts}) after ${currentDelay}ms: ${e.message}")
                
                // Delay before retry
                delay(currentDelay)
                
                // Increase delay for next attempt (exponential backoff)
                currentDelay = (currentDelay * multiplier).toLong().coerceAtMost(maxDelayMs)
                
                // Increment attempt counter
                attempt++
            }
        }
    }
}
```

### 2. Supervisor Strategy

A supervisor pattern for managing agent lifecycles:

```kotlin
class AgentSupervisor(
    private val orchestrator: Orchestrator,
    private val config: SupervisorConfig
) {
    private val logger = LoggerFactory.getLogger(AgentSupervisor::class.java)
    
    // Supervisor scope
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Agent failure counts
    private val agentFailures = ConcurrentHashMap<String, Int>()
    
    // Monitor agent health
    fun monitorAgent(agentId: String, health: AgentHealth) {
        if (!health.isHealthy) {
            // Increment failure count
            val failures = agentFailures.compute(agentId) { _, count ->
                (count ?: 0) + 1
            } ?: 1
            
            logger.warn("Agent $agentId is unhealthy, failure count: $failures")
            
            // Check supervision strategy
            when {
                failures <= config.restartThreshold -> {
                    // Restart the agent
                    restartAgent(agentId)
                }
                failures <= config.escalationThreshold -> {
                    // Restart with escalation (e.g., notify admin)
                    restartWithEscalation(agentId)
                }
                else -> {
                    // Stop the agent
                    stopAgent(agentId)
                }
            }
        } else {
            // Reset failure count for healthy agent
            agentFailures.remove(agentId)
        }
    }
    
    // Restart an agent
    private fun restartAgent(agentId: String) {
        logger.info("Supervisor restarting agent: $agentId")
        
        scope.launch {
            try {
                orchestrator.restartAgent(agentId)
                logger.info("Agent $agentId restarted successfully")
            } catch (e: Exception) {
                logger.error("Failed to restart agent $agentId", e)
            }
        }
    }
    
    // Restart with escalation
    private fun restartWithEscalation(agentId: String) {
        logger.warn("Supervisor restarting agent with escalation: $agentId")
        
        // Notify administrators (e.g., email, SMS, etc.)
        notifyAdministrators(agentId)
        
        // Restart the agent
        restartAgent(agentId)
    }
    
    // Stop an agent
    private fun stopAgent(agentId: String) {
        logger.warn("Supervisor stopping agent due to excessive failures: $agentId")
        
        scope.launch {
            try {
                orchestrator.stopAgent(agentId)
                logger.info("Agent $agentId stopped successfully")
            } catch (e: Exception) {
                logger.error("Failed to stop agent $agentId", e)
            }
        }
    }
    
    // Notify administrators
    private fun notifyAdministrators(agentId: String) {
        // Implementation would send notifications to administrators
        // (e.g., email, SMS, etc.)
        logger.warn("Administrator notification would be sent for agent: $agentId")
    }
}

data class SupervisorConfig(
    val restartThreshold: Int = 3,
    val escalationThreshold: Int = 5,
    val notificationEnabled: Boolean = true
)
```

### 3. Graceful Degradation

A strategy for maintaining partial functionality when components fail:

```kotlin
class GracefulDegradationManager(
    private val orchestrator: Orchestrator
) {
    private val logger = LoggerFactory.getLogger(GracefulDegradationManager::class.java)
    
    // Track critical capabilities
    private val criticalCapabilities = ConcurrentHashMap<Capability, MutableList<String>>()
    
    // Initialize with registered agents
    fun initialize() {
        // Build capability map from registered agents
        val agents = orchestrator.getRegisteredAgents()
        
        for (agent in agents) {
            for (capability in agent.capabilities) {
                criticalCapabilities.getOrPut(capability) {
                    CopyOnWriteArrayList()
                }.add(agent.agentId)
            }
        }
        
        logger.info("Graceful degradation manager initialized with ${criticalCapabilities.size} capabilities")
    }
    
    // Update capability map when agents register or unregister
    fun updateCapabilityMap(agentId: String, capabilities: Set<Capability>, register: Boolean) {
        if (register) {
            // Add agent to capability lists
            for (capability in capabilities) {
                criticalCapabilities.getOrPut(capability) {
                    CopyOnWriteArrayList()
                }.add(agentId)
            }
        } else {
            // Remove agent from capability lists
            for (capability in capabilities) {
                criticalCapabilities[capability]?.remove(agentId)
            }
        }
    }
    
    // Check if a capability is available
    fun isCapabilityAvailable(capability: Capability): Boolean {
        val agentsWithCapability = criticalCapabilities[capability] ?: return false
        return agentsWithCapability.isNotEmpty()
    }
    
    // Find an agent with a specific capability
    fun findAgentForCapability(capability: Capability): String? {
        val agentsWithCapability = criticalCapabilities[capability] ?: return null
        return agentsWithCapability.firstOrNull()
    }
    
    // Get available capabilities
    fun getAvailableCapabilities(): Set<Capability> {
        return criticalCapabilities.keys
            .filter { isCapabilityAvailable(it) }
            .toSet()
    }
    
    // Handle capability loss
    fun handleCapabilityLoss(capability: Capability) {
        logger.warn("Capability lost: $capability")
        
        // Check if this is a critical capability
        if (isCriticalCapability(capability)) {
            logger.error("Critical capability lost: $capability")
            
            // Attempt recovery
            attemptCapabilityRecovery(capability)
        }
    }
    
    // Check if a capability is critical
    private fun isCriticalCapability(capability: Capability): Boolean {
        // Implementation would define which capabilities are critical
        return when (capability) {
            is Capability.CameraDetection,
            is Capability.CameraConfiguration -> true
            else -> false
        }
    }
    
    // Attempt to recover a lost capability
    private fun attemptCapabilityRecovery(capability: Capability) {
        logger.info("Attempting to recover capability: $capability")
        
        // Implementation would attempt to recover the capability
        // (e.g., restart agents, provision new agents, etc.)
    }
}
```

## HTTP Health Endpoints

### 1. Health API Controller

```kotlin
class HealthApiController(
    private val natsConnection: Connection,
    private val healthMonitoringService: HealthMonitoringService
) {
    private val logger = LoggerFactory.getLogger(HealthApiController::class.java)
    
    // Configure Ktor routing
    fun configureRoutes(routing: Routing) {
        routing {
            route("/health") {
                // Basic health check endpoint
                get {
                    call.respond(HttpStatusCode.OK, mapOf("status" to "UP"))
                }
                
                // Detailed health report
                get("/report") {
                    val healthReport = requestHealthReport()
                    
                    val statusCode = when (healthReport.overallSystemHealth) {
                        SystemHealthStatus.HEALTHY -> HttpStatusCode.OK
                        SystemHealthStatus.DEGRADED -> HttpStatusCode.OK
                        SystemHealthStatus.UNHEALTHY -> HttpStatusCode.ServiceUnavailable
                    }
                    
                    call.respond(statusCode, healthReport)
                }
                
                // Agent-specific health
                get("/agents/{agentId}") {
                    val agentId = call.parameters["agentId"]
                        ?: return@get call.respond(HttpStatusCode.BadRequest, mapOf("error" to "Missing agentId"))
                    
                    val healthReport = requestHealthReport()
                    val agentHealth = healthReport.agentHealths.find { it.agentId == agentId }
                    
                    if (agentHealth == null) {
                        call.respond(HttpStatusCode.NotFound, mapOf("error" to "Agent not found"))
                    } else {
                        val statusCode = if (agentHealth.isHealthy) HttpStatusCode.OK else HttpStatusCode.ServiceUnavailable
                        call.respond(statusCode, agentHealth)
                    }
                }
                
                // System metrics
                get("/metrics") {
                    val healthReport = requestHealthReport()
                    call.respond(HttpStatusCode.OK, healthReport.orchestratorHealth.metrics)
                }
            }
        }
    }
    
    // Request health report via NATS
    private suspend fun requestHealthReport(): HealthReport {
        return try {
            val future = CompletableFuture<HealthReport>()
            
            val subscription = natsConnection.subscribe("mcp.health.report.response.${UUID.randomUUID()}")
            subscription.use { sub ->
                // Set up message handler
                sub.dispatcher.subscribe(sub.subject) { message ->
                    try {
                        val response = Json.decodeFromString<HealthCheckResponse>(
                            String(message.data)
                        )
                        
                        future.complete(response.healthReport)
                    } catch (e: Exception) {
                        future.completeExceptionally(e)
                    }
                }
                
                // Send request
                natsConnection.publish(
                    "mcp.health.check",
                    null,
                    sub.subject
                )
                
                // Wait for response with timeout
                withTimeout(5000) {
                    future.await()
                }
            }
        } catch (e: Exception) {
            logger.error("Error requesting health report", e)
            
            // Return a basic unhealthy report
            HealthReport(
                timestamp = System.currentTimeMillis(),
                orchestratorHealth = OrchestratorHealth(
                    isHealthy = false,
                    uptime = 0,
                    activeThreads = 0,
                    metrics = emptyMap()
                ),
                agentHealths = emptyList(),
                overallSystemHealth = SystemHealthStatus.UNHEALTHY
            )
        }
    }
}
```

## Implementation Guidelines

### 1. Health Monitoring Best Practices

1. **Heartbeat Frequency**: Adjust heartbeat intervals based on agent criticality
2. **Monitoring Overhead**: Balance monitoring detail with performance impact
3. **Fault Detection**: Distinguish between transient and permanent failures
4. **Metric Collection**: Focus on actionable metrics that indicate system health
5. **Alert Thresholds**: Set appropriate thresholds to avoid alert fatigue

### 2. Resilience Implementation Considerations

1. **Fault Isolation**: Ensure failures in one component don't cascade to others
2. **Recovery Strategies**: Implement appropriate recovery mechanisms for different failure types
3. **Resource Protection**: Implement timeouts and circuit breakers for external dependencies
4. **Graceful Degradation**: Design for partial functionality when components fail
5. **Error Handling**: Standardize error handling and logging practices

### 3. Circuit Breaker Implementation

1. **Threshold Configuration**: Set appropriate failure thresholds based on expected error rates
2. **Reset Strategy**: Implement progressive reset for circuit breakers (half-open state)
3. **Timeout Management**: Set timeouts based on expected operation duration
4. **Monitoring**: Track circuit breaker state changes for system health analysis
5. **Testing**: Verify circuit breaker behavior under different failure scenarios

## Logging Strategy

### 1. Structured Logging

```kotlin
// Sample logger configuration using structured logging with Logback
object LoggingSetup {
    fun configure() {
        val context = LoggerFactory.getILoggerFactory() as LoggerContext
        
        // Reset existing configuration
        context.reset()
        
        // Configure console appender
        val consoleAppender = ConsoleAppender<ILoggingEvent>().apply {
            name = "CONSOLE"
            
            val encoder = PatternLayoutEncoder().apply {
                pattern = "%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"
                context = context
                start()
            }
            
            this.encoder = encoder
            
            context = context
            start()
        }
        
        // Configure root logger
        val rootLogger = context.getLogger(Logger.ROOT_LOGGER_NAME)
        rootLogger.level = Level.INFO
        rootLogger.addAppender(consoleAppender)
    }
}
```

### 2. Logging Guidelines

1. **Log Levels**: Use appropriate log levels (ERROR, WARN, INFO, DEBUG)
2. **Context Information**: Include relevant context in log messages
3. **Correlation IDs**: Use correlation IDs to track requests across components
4. **Structured Format**: Use structured logging for machine-readable logs
5. **Sensitive Data**: Avoid logging sensitive information

## Next Steps

After implementing the Health Monitoring and Resilience Framework:

1. Create a simple dashboard to visualize system health
2. Implement integration tests for failure scenarios
3. Configure alerting mechanisms for critical failures
4. Document recovery procedures for common failure scenarios