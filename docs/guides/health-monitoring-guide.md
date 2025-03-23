---
title: "MCP Health Monitoring Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
related_docs:
  - "/docs/guides/testing-guide.md"
  - "/docs/guides/containerized-dev-environment.md"
  - "/docs/project/build-engineer-next-steps.md"
tags: ["health", "monitoring", "metrics", "resilience", "circuit-breaker"]
---

# MCP Health Monitoring Guide

[↩️ Back to Start Here](/docs/START_HERE.md) | [↩️ Back to Documentation Index](/docs/README.md)

## Overview

This guide documents the health monitoring system implemented for the Multi-Agent Control Platform (MCP). The health monitoring system provides real-time metrics collection, health status reporting, and resilience mechanisms to ensure system reliability and observability.

## Health Monitoring Components

### System Architecture

The health monitoring system consists of the following components:

1. **SystemMetricsCollector**: Collects JVM and system-level metrics
2. **HealthCheckService**: Provides health check endpoints and manages agent health status
3. **Circuit Breaker Pattern**: Prevents cascading failures during outages
4. **Agent State Monitoring**: Tracks agent state transitions for health assessment
5. **NATS Health Endpoints**: For querying system and agent health status

![Health Monitoring Architecture](../images/health-monitoring-architecture.png)

## Metrics Collection

The `SystemMetricsCollector` gathers various system and JVM metrics:

### CPU Metrics
- Available processors
- Process CPU load
- System CPU load
- System load average

### Memory Metrics
- Total memory
- Free memory
- Used memory
- Max memory
- Heap utilization
- Non-heap memory usage

### Thread Metrics
- Active thread count
- Peak thread count
- Daemon thread count
- Total started thread count

### Garbage Collection Metrics
- GC collection count
- GC collection time

### Usage Example

```kotlin
// Initialize the metrics collector
val metricsCollector = SystemMetricsCollector()

// Collect metrics
val metrics = metricsCollector.collectMetrics()

// Access specific metrics
val cpuLoad = metrics.cpuMetrics.processCpuLoad
val heapUsage = metrics.memoryMetrics.heapUtilizationPercent
val threadCount = metrics.threadMetrics.threadCount

println("CPU Load: $cpuLoad%, Heap Usage: $heapUsage%, Threads: $threadCount")
```

## Health Check Service

The `HealthCheckService` provides health check endpoints via NATS and manages agent health status tracking:

### Features
- Periodic health status collection and publishing
- Agent health status tracking
- Circuit breaker pattern for failure handling
- Health check endpoints via NATS

### Health Status Levels
- `HEALTHY`: Component is functioning normally
- `DEGRADED`: Component is functioning but with reduced capabilities
- `UNHEALTHY`: Component is not functioning correctly
- `STARTING`: Component is initializing
- `STOPPING`: Component is shutting down
- `UNKNOWN`: Component's status cannot be determined

### Usage Example

```kotlin
// Initialize the service
val healthCheckService = HealthCheckService(
    natsConnection = natsConnection,
    metricsCollectionInterval = 15.seconds
)

// Update agent health
healthCheckService.updateAgentHealth(agent, AgentState.Idle)

// Get system health
val systemHealth = healthCheckService.getSystemHealth()
println("System status: ${systemHealth.status}")
println("Agent count: ${systemHealth.agentCount}")
```

## Health Check Endpoints

The health monitoring system exposes the following NATS endpoints:

### System Health
- Subject: `mcp.health.system`
- Returns: Overall system health status, agent counts, metrics

### Agent Health
- Subject: `mcp.health.agent`
- Message: Agent ID
- Returns: Status of the specified agent, capabilities, last update

### Orchestrator Status
- Subject: `mcp.orchestrator.status`
- Returns: Orchestrator running status, agent count, timestamp

### Agent Listing
- Subject: `mcp.orchestrator.agents`
- Returns: List of registered agents with state and capabilities

### Query Example

```bash
# Using NATS CLI to query system health
nats req mcp.health.system ""

# Query specific agent health
nats req mcp.health.agent "camera-agent-1"
```

## Circuit Breaker Pattern

The health monitoring system implements the circuit breaker pattern to prevent cascading failures:

### States
1. **Closed**: Normal operation, all requests processed
2. **Open**: Failure threshold exceeded, requests fail fast
3. **Half-Open**: Trial period after timeout, limited requests to test recovery

### Configuration
- Failure threshold: Number of consecutive failures before opening the circuit
- Reset timeout: Time to wait before trying to close the circuit again

### Implementation Details

```kotlin
// Health check service circuit breaker configuration
val healthCheckService = HealthCheckService(
    natsConnection = natsConnection,
    metricsCollectionInterval = 15.seconds,
    circuitBreakerThreshold = 5,
    circuitBreakerResetTimeout = 30.seconds
)
```

## Agent State Monitoring

The system tracks agent state transitions to monitor health:

### State Transitions
- Each agent has a state machine with well-defined states
- State changes trigger health status updates
- Unexpected transitions may indicate issues

### State Change Listeners

```kotlin
// Add a state change listener to monitor transitions
stateMachine.addStateChangeListener { oldState, newState ->
    println("Agent ${agent.agentId} changed from $oldState to $newState")
    // Update health status based on new state
    healthCheckService.updateAgentHealth(agent, newState)
}
```

## Health Visualization

The health monitoring data can be visualized using:

1. **NATS CLI**: For quick checks and debugging
2. **Prometheus/Grafana**: For long-term monitoring (integration guide coming soon)
3. **Custom Dashboard**: A simple web dashboard is planned

### NATS CLI Visualization

```bash
# Watch system health in real-time
nats sub "mcp.health.metrics" --json
```

## Setting Up Health Monitoring

To set up the health monitoring system:

1. Ensure the NATS server is running
2. Initialize the health monitoring components in the main application
3. Configure agents to report their status

### Main Application Setup

```kotlin
// In your Main.kt:
fun main() = runBlocking {
    // Connect to NATS
    val natsManager = NatsConnectionManager()
    val natsConnection = natsManager.connect()
    
    // Initialize health monitoring
    val metricsCollector = SystemMetricsCollector()
    val healthCheckService = HealthCheckService(natsConnection)
    
    // Initialize orchestrator with health monitoring
    val orchestrator = Orchestrator(natsConnection)
    orchestrator.start()
    
    // Keep application running
    while (true) {
        delay(1000)
    }
}
```

## Best Practices

### Monitoring Frequency
- Balance between timely data and system overhead
- 15-30 second intervals for most metrics
- 1-5 minute intervals for less critical metrics

### Alert Thresholds
- CPU: Alert at 80% sustained utilization
- Memory: Alert at 85% heap utilization
- Threads: Alert on abnormal thread count increases
- GC: Alert on high GC frequency or duration

### Health Status Interpretation
- `DEGRADED` status requires investigation but not immediate action
- `UNHEALTHY` status requires immediate attention
- Multiple agents in `UNHEALTHY` state may indicate system-wide issues

### Resource Management
- Implement resource limits in containers
- Monitor resource trends over time
- Scale resources based on historical usage patterns

## Troubleshooting

### Common Issues

#### High CPU Usage
- Check for infinite loops or inefficient algorithms
- Look for thread contention
- Examine GC activity

#### Memory Leaks
- Monitor heap usage over time
- Check for objects that aren't being garbage collected
- Use memory profiling tools if needed

#### Agent Communication Issues
- Check NATS connection status
- Verify agent registration
- Look for timeout errors in logs

#### Circuit Breaker Activation
- Check logs for "Circuit breaker opened" messages
- Investigate root cause of failures
- Allow time for automatic reset or manually reset if necessary

## Future Enhancements

Planned enhancements for the health monitoring system:

1. **Web Dashboard**: A real-time web UI for system health visualization
2. **Prometheus Integration**: Export metrics to Prometheus for advanced monitoring
3. **Alerting System**: Configurable alerts for critical health issues
4. **Historical Data**: Long-term storage and analysis of health metrics
5. **Predictive Analytics**: Machine learning models to predict potential issues

## References

- [Metrics Collection in JVM](https://docs.oracle.com/en/java/javase/17/management/monitoring-and-management-using-jmx-technology.html)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [NATS Request-Reply](https://docs.nats.io/nats-concepts/core-nats/reqreply)
- [Health Check API Best Practices](https://microservices.io/patterns/observability/health-check-api.html)