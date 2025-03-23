---
title: "Build Engineer Implementation Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Build Engineer", "Documentation Architect"]
related_docs:
  - "/guides/containerized-dev-environment/"
  - "/guides/build-engineer-quick-start/"
  - "/guides/build-engineer-tech-specs/"
  - "/guides/testing-guide/"
tags: ["guide", "implementation", "build-engineer", "mcp", "setup"]
---

# Build Engineer Implementation Guide: Getting Started with MCP

{{< status >}}

## Overview

This guide provides a clear path for the build engineer to begin implementation of the Multi-Agent Control Platform (MCP). It translates the architectural specifications into concrete setup steps and initial development tasks.

> **⚠️ IMPORTANT:** The recommended development approach uses a containerized environment with Podman.
>
> For the containerized setup, refer to the [Containerized Development Environment](/guides/containerized-dev-environment/) guide.
>
> This guide covers both containerized and traditional setup options.

## Development Environment Options

You have two options for setting up your development environment:

1. **[Recommended] Containerized Environment with Podman**: Provides isolation, consistency, and proper service orchestration
   - See detailed setup instructions in the [Containerized Development Environment](/guides/containerized-dev-environment/) guide
   - Uses Podman and Podman Compose to manage all services
   - Includes USB device passthrough for camera development
   - Offers hot reload capabilities for faster development

2. **Traditional Environment**: Direct installation on the host system
   - Simpler to set up initially but may lead to dependency conflicts
   - Requires manual service management
   - Documented in this guide as an alternative option

## Prerequisites for Traditional Setup

If not using the containerized approach, ensure the following prerequisites are installed:

```bash
# Core dependencies
sudo dnf update -y
sudo dnf install -y git curl unzip \
    java-17-openjdk-devel \
    python3 python3-pip \
    podman \
    nats-server

# Optional: Install Kotlin and Gradle with SDKMAN (recommended)
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install kotlin
sdk install gradle
```

Verify your environment:
- Java 17+: `java -version`
- Kotlin: `kotlin -version`
- Gradle: `gradle -version`
- NATS: `nats-server -v`

## Project Setup

### 1. Create Project Structure

Start by creating the base project structure:

```bash
# Create project directory
mkdir -p mcp-project

# Navigate to project directory
cd mcp-project

# Create core directories
mkdir -p src/main/kotlin/com/example/mcp
mkdir -p src/main/kotlin/com/example/agents
mkdir -p src/main/resources
mkdir -p src/test/kotlin/com/example/mcp
mkdir -p nats
```

### 2. Configure Gradle

Create the build configuration files:

**settings.gradle.kts**
```kotlin
rootProject.name = "mcp-project"
```

**build.gradle.kts**
```kotlin
plugins {
    kotlin("jvm") version "1.8.10"
    kotlin("plugin.serialization") version "1.8.10"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    // Kotlin standard library and coroutines
    implementation(kotlin("stdlib"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
    
    // NATS messaging
    implementation("io.nats:jnats:2.16.8")
    
    // Tinder StateMachine for FSM
    implementation("com.tinder.statemachine:statemachine:0.2.0")
    
    // Kotlin serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.5.0")
    
    // Logging
    implementation("org.slf4j:slf4j-api:1.7.36")
    implementation("ch.qos.logback:logback-classic:1.2.11")
    
    // Testing
    testImplementation("org.jetbrains.kotlin:kotlin-test:1.8.10")
    testImplementation("io.mockk:mockk:1.13.4")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")
    testImplementation("org.junit.jupiter:junit-jupiter:5.9.2")
}

application {
    mainClass.set("com.example.mcp.MainKt")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
```

### 3. Configure Logging

Create **src/main/resources/logback.xml**:

```xml
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <root level="info">
        <appender-ref ref="STDOUT" />
    </root>
</configuration>
```

### 4. Set Up NATS Configuration

Create **nats/nats-server.conf**:

```
# Basic NATS Server configuration
port: 4222
http_port: 8222

# Logging
debug: false
trace: false

# Maximum payload size (5MB)
max_payload: 5242880
```

### 5. Initialize Git Repository

```bash
git init
echo "build/" > .gitignore
echo ".gradle/" >> .gitignore
echo ".idea/" >> .gitignore
echo "*.iml" >> .gitignore
echo "out/" >> .gitignore
echo ".DS_Store" >> .gitignore
git add .
git commit -m "Initial project structure"
```

## Implementation: Core Components

Follow this sequence for implementing the core components:

### 1. Core Agent Framework

Start by implementing the core data models and interfaces:

**src/main/kotlin/com/example/mcp/models/AgentState.kt**
```kotlin
package com.example.mcp.models

sealed class AgentState {
    object Idle : AgentState()
    object Initializing : AgentState()
    object Processing : AgentState()
    object Error : AgentState()
    object ShuttingDown : AgentState()
}
```

**src/main/kotlin/com/example/mcp/models/AgentEvent.kt**
```kotlin
package com.example.mcp.models

sealed class AgentEvent {
    object Initialize : AgentEvent()
    data class Process(val task: AgentTask) : AgentEvent()
    data class Error(val exception: Exception) : AgentEvent()
    object Shutdown : AgentEvent()
}
```

**src/main/kotlin/com/example/mcp/models/AgentTask.kt**
```kotlin
package com.example.mcp.models

import kotlinx.serialization.Serializable

@Serializable
data class AgentTask(
    val taskId: String,
    val agentType: String,
    val payload: String,
    val priority: Int = 0,
    val timeoutMs: Long = 30000
)

@Serializable
data class TaskResult(
    val taskId: String,
    val status: TaskStatus,
    val result: String? = null,
    val error: String? = null,
    val processingTimeMs: Long? = null
)

enum class TaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    FAILED
}
```

**src/main/kotlin/com/example/mcp/models/AgentStatus.kt**
```kotlin
package com.example.mcp.models

import kotlinx.serialization.Serializable

@Serializable
data class AgentStatus(
    val agentId: String,
    val state: String,
    val healthCheck: Boolean,
    val activeTaskCount: Int = 0,
    val lastHeartbeatMs: Long = System.currentTimeMillis()
)
```

**src/main/kotlin/com/example/agents/McpAgent.kt**
```kotlin
package com.example.agents

import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult

interface McpAgent {
    val agentId: String
    val capabilities: Set<Capability>
    
    suspend fun processTask(task: AgentTask): TaskResult
    fun getStatus(): AgentStatus
    suspend fun initialize()
    suspend fun shutdown()
}

enum class Capability {
    CAMERA_DETECTION,
    CODE_GENERATION,
    BUILD_SYSTEM,
    TESTING
}
```

### 2. NATS Integration

Implement the NATS connection manager:

**src/main/kotlin/com/example/mcp/NatsConnectionManager.kt**
```kotlin
package com.example.mcp

import io.nats.client.Connection
import io.nats.client.Nats
import io.nats.client.Options
import org.slf4j.LoggerFactory
import java.time.Duration

class NatsConnectionManager {
    private val logger = LoggerFactory.getLogger(NatsConnectionManager::class.java)
    private var connection: Connection? = null
    
    fun connect(serverUrl: String = "nats://localhost:4222"): Connection {
        logger.info("Connecting to NATS server at $serverUrl")
        
        val options = Options.Builder()
            .server(serverUrl)
            .connectionTimeout(Duration.ofSeconds(5))
            .maxReconnects(-1) // Unlimited reconnects
            .reconnectWait(Duration.ofSeconds(1))
            .build()
        
        return Nats.connect(options).also {
            connection = it
            logger.info("Connected to NATS server successfully")
        }
    }
    
    fun getConnection(): Connection {
        return connection ?: throw IllegalStateException("NATS connection not established. Call connect() first.")
    }
    
    fun close() {
        connection?.let {
            logger.info("Closing NATS connection")
            it.close()
            connection = null
        }
    }
}
```

### 3. Basic Agent StateMachine

Implement the agent state machine using Tinder's StateMachine library:

**src/main/kotlin/com/example/mcp/AgentStateMachine.kt**
```kotlin
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
```

### 4. Main Application

Implement the application entry point:

**src/main/kotlin/com/example/mcp/Main.kt**
```kotlin
package com.example.mcp

import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory

fun main() = runBlocking {
    val logger = LoggerFactory.getLogger("MCP")
    logger.info("Starting MCP...")
    
    // Connect to NATS
    val natsManager = NatsConnectionManager()
    val natsConnection = natsManager.connect()
    
    // Initialize orchestrator
    val orchestrator = Orchestrator(natsConnection)
    orchestrator.start()
    
    // Add shutdown hook
    Runtime.getRuntime().addShutdownHook(Thread {
        runBlocking {
            logger.info("Shutting down MCP...")
            orchestrator.stop()
            natsManager.close()
        }
    })
    
    // Keep application running
    logger.info("MCP running. Press Ctrl+C to exit.")
    while (true) {
        kotlinx.coroutines.delay(1000)
    }
}
```

### 5. Simple Orchestrator

**src/main/kotlin/com/example/mcp/Orchestrator.kt**
```kotlin
package com.example.mcp

import com.example.agents.McpAgent
import io.nats.client.Connection
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory

class Orchestrator(
    private val natsConnection: Connection
) {
    private val logger = LoggerFactory.getLogger(Orchestrator::class.java)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val agents = mutableListOf<McpAgent>()
    private val agentStateMachines = mutableMapOf<String, AgentStateMachine>()
    
    fun start() {
        logger.info("Orchestrator starting")
        
        // Initialize agents (will be dynamically loaded in a more advanced implementation)
        // Register agents here when implemented
        
        // Initialize all registered agents
        agents.forEach { agent ->
            val stateMachine = AgentStateMachine(agent)
            agentStateMachines[agent.agentId] = stateMachine
            stateMachine.initialize()
            logger.info("Registered agent: ${agent.agentId} with capabilities: ${agent.capabilities}")
        }
        
        // Set up NATS subscriptions
        setupTaskDistribution()
        
        logger.info("Orchestrator started successfully")
    }
    
    private fun setupTaskDistribution() {
        // Subscribe to task requests
        natsConnection.createDispatcher { msg ->
            scope.launch {
                val taskId = msg.subject.substringAfterLast('.')
                logger.info("Received task request: $taskId")
                // Implementation will be added later
            }
        }.subscribe("mcp.task.>")
        
        logger.info("Task distribution setup complete")
    }
    
    fun stop() {
        runBlocking {
            logger.info("Stopping orchestrator")
            
            // Shutdown all agent state machines
            agentStateMachines.values.forEach { it.shutdown() }
            
            logger.info("Orchestrator stopped")
        }
    }
}
```

## Building and Running

### Build the Project

```bash
# Navigate to project directory
cd mcp-project

# Build with Gradle
./gradlew build
```

### Start NATS Server

```bash
# Start NATS with default configuration
nats-server

# Or with custom config
nats-server -c nats/nats-server.conf
```

### Run the MCP

```bash
# Run with Gradle
./gradlew run
```

## Implementation Progress

Current implementation progress across major components:

| Component | Status | Completion |
|-----------|--------|------------|
| Project Setup | 🟢 Active | {{< progress value="100" >}} |
| Core Agent Framework | 🟢 Active | {{< progress value="90" >}} |
| NATS Integration | 🟢 Active | {{< progress value="85" >}} |
| Agent State Machine | 🟢 Active | {{< progress value="80" >}} |
| Orchestrator | 🟡 Draft | {{< progress value="60" >}} |
| Camera Integration Agent | 🟡 Draft | {{< progress value="40" >}} |
| Health Monitoring | 🟡 Draft | {{< progress value="30" >}} |
| Testing | 🟡 Draft | {{< progress value="20" >}} |

## Next Implementation Steps

After completing the core setup, proceed with these next steps:

1. **Implement the Camera Integration Agent**
   - Create a basic implementation that can detect USB devices
   - Add NATS subscription for camera-specific tasks
   - Implement task handlers for device listing and basic operations

2. **Add Task Scheduler to Orchestrator**
   - Implement priority-based scheduling
   - Add dependency resolution between tasks
   - Create task queue management

3. **Implement Health Monitoring**
   - Add agent health checks
   - Set up system metrics collection
   - Implement circuit breaker and retry policies

4. **Add Unit and Integration Tests**
   - Test agent state transitions
   - Test NATS message routing
   - Test orchestrator functionality

## Testing Strategy

1. **Unit Testing**
   - Test state transitions in isolation
   - Mock dependencies with MockK
   - Test both success and failure cases

2. **Integration Testing**
   - Test agent registration and communication
   - Verify task scheduling and execution
   - Test error handling and recovery

3. **Manual Testing**
   - Verify NATS connectivity
   - Check agent initialization
   - Test task submission and execution

## Troubleshooting Guide

### Common Issues

1. **NATS Connection Failure**
   - Verify NATS server is running: `nats-server -DV`
   - Check connection URL in NatsConnectionManager
   - Ensure no firewall blocking port 4222

2. **Agent Initialization Failures**
   - Check logs for specific error messages
   - Verify agent implementation of initialize() method
   - Check for resource constraints or missing dependencies

3. **Task Processing Issues**
   - Verify task format and required fields
   - Check agent capabilities match the task requirements
   - Look for exceptions in the agent's processTask method

## Resources and References

- [NATS Documentation](https://docs.nats.io/)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-overview.html)
- [Tinder StateMachine](https://github.com/Tinder/StateMachine)
- [Gradle User Guide](https://docs.gradle.org/current/userguide/userguide.html)
- [SLF4J Documentation](https://www.slf4j.org/manual.html)

## Conclusion

This guide provides a clear starting path for implementing the MCP project. Begin with the core infrastructure setup and gradually add more functionality as you progress. The implementation follows the architectural plan with a focus on creating a solid foundation for the specialized agents and advanced features that will be added in later phases.

## Related Documentation

{{< related-docs >}}