# First Steps for Multi-Agent Control Platform (MCP) Development

This guide outlines the initial steps for both the architect and coder to begin developing the Multi-Agent Control Platform (MCP) for Android UVC camera development. It covers environment setup, project structure, and initial implementation tasks.

## 1. Environment Setup

### 1.1. Install Required Packages

```bash
sudo dnf update -y
sudo dnf install -y git curl unzip \
    java-17-openjdk-devel \
    python3 python3-pip \
    podman \
    nats-server
```

> **Note**:  
> - Ensure you have **Java 17** or higher for Kotlin/Gradle
> - You can install `nats-server` from [NATS releases](https://github.com/nats-io/nats-server/releases) if needed

### 1.2. Install Kotlin and Gradle (Optional)

```bash
# Using SDKMAN (recommended for version management)
sdk install kotlin
sdk install gradle

# Or using package manager
sudo dnf install kotlin gradle
```

## 2. Project Structure

Create the following directory structure:

```
mcp-project/
├─ README.md
├─ settings.gradle.kts
├─ build.gradle.kts
├─ gradle/
├─ src/
│  ├─ main/
│  │  ├─ kotlin/
│  │  │  ├─ com/example/mcp/   <-- core orchestrator classes
│  │  │  ├─ com/example/agents/ <-- specialized agents
│  │  │  └─ ...
│  │  └─ resources/
│  └─ test/
│     └─ kotlin/
└─ nats/
   └─ nats-server.conf
```

## 3. Gradle Configuration

### 3.1. settings.gradle.kts

```kotlin
rootProject.name = "mcp-project"
```

### 3.2. build.gradle.kts

```kotlin
plugins {
    kotlin("jvm") version "1.8.10"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(kotlin("stdlib"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
    implementation("io.nats:jnats:2.16.8") // NATS Java client
    // Add FSM library (e.g., Tinder's StateMachine)
    implementation("com.tinder.statemachine:statemachine:0.2.0")
    // Add logging
    implementation("org.slf4j:slf4j-api:1.7.36")
    implementation("ch.qos.logback:logback-classic:1.2.11")
}

application {
    mainClass.set("com.example.mcp.MainKt")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
```

## 4. Architect - Initial Tasks

### 4.1. Deep Dive into the Strategic Plan

- Review the strategic plan thoroughly to understand the architecture, technology choices, and roadmap
- Identify areas requiring further clarification or refinement

### 4.2. High-Level System Design

- Create a detailed diagram of the core architecture:
  ```
  [MCP Core Orchestrator (Kotlin)] ---(NATS)---> [Specialized Agents]
                    ↑                                 | Status/Results
                    | Event Triggers                  ↓
  [Android App] ---(HTTP/WebSocket)---> [MCP Core Orchestrator]
  ```

- Define core responsibilities for each initial agent:
  - **Core Orchestrator**: FSM management, agent lifecycle, task scheduling
  - **Camera Integration Agent**: Basic USB device detection
  - **Code Generation Agent**: Simple boilerplate code generation
  - **Build System Agent**: Basic build process interaction

### 4.3. Technology Stack Confirmation

- Confirm Kotlin for the core components
- Investigate lightweight Kotlin FSM libraries (e.g., Tinder's StateMachine)
- Research Kotlin NATS client libraries
- Consider Ktor for HTTP/WebSocket communication with Android apps
- Plan the logging framework (SLF4J + Logback)

### 4.4. Project Structure Planning

- Finalize the directory structure for the MCP server project
- Outline the organization of Gradle build files

### 4.5. Phase 1 Refinement

- Break down Phase 1 tasks from the roadmap into smaller, manageable steps
- Estimate time requirements for each sub-task

## 5. Coder - Initial Tasks

### 5.1. Development Environment Setup

- Install and configure IntelliJ IDEA or preferred Kotlin IDE
- Ensure Gradle is properly installed and configured

### 5.2. Create the MCP Server Project

- Create a new Kotlin project using Gradle
- Set up the project structure following the architect's plan

### 5.3. Implement Basic FSM Framework

- Add the FSM library dependency to `build.gradle.kts`
- Create basic implementation of `AgentState` and `AgentEvent` sealed classes:
  
```kotlin
sealed class AgentState {
    object Idle : AgentState()
    object Initializing : AgentState()
    object Processing : AgentState()
    object Error : AgentState()
    object ShuttingDown : AgentState()
}

sealed class AgentEvent {
    object Initialize : AgentEvent()
    data class Process(val task: AgentTask) : AgentEvent()
    data class Error(val exception: Exception) : AgentEvent()
    object Shutdown : AgentEvent()
}
```

### 5.4. Implement the McpAgent Interface

```kotlin
interface McpAgent {
    val agentId: String
    val capabilities: Set<Capability>
    suspend fun processTask(task: AgentTask): TaskResult
    fun getStatus(): AgentStatus
    suspend fun initialize()
    suspend fun shutdown()
}

data class AgentTask(
    val taskId: String,
    val payload: String
)

data class TaskResult(
    val taskId: String,
    val status: TaskStatus,
    val result: String?
)
```

### 5.5. Set Up NATS Client

- Add the NATS client library dependency
- Write a basic test to connect to a local NATS server

### 5.6. Implement Basic Logging

- Add SLF4J and Logback dependencies
- Configure basic logging in `logback.xml`
- Add logging statements to your FSM and agent implementations

## 6. Basic Implementation Code

### 6.1. Main.kt

```kotlin
package com.example.mcp

import kotlinx.coroutines.runBlocking
import io.nats.client.Connection
import io.nats.client.Nats
import org.slf4j.LoggerFactory

fun main() = runBlocking {
    val logger = LoggerFactory.getLogger("MCP")
    logger.info("Starting MCP...")

    // Connect to NATS
    val natsConnection: Connection = Nats.connect("nats://localhost:4222")

    // Initialize orchestrator
    val orchestrator = Orchestrator(natsConnection)
    orchestrator.start()

    // Keep application running
    Runtime.getRuntime().addShutdownHook(Thread {
        runBlocking {
            logger.info("Shutting down MCP...")
            orchestrator.stop()
            natsConnection.close()
        }
    })

    // Block main thread to keep application running
    while (true) {
        kotlinx.coroutines.delay(1000)
    }
}
```

### 6.2. Orchestrator.kt

```kotlin
package com.example.mcp

import io.nats.client.Connection
import kotlinx.coroutines.*
import org.slf4j.LoggerFactory

class Orchestrator(
    private val natsConnection: Connection
) {
    private val logger = LoggerFactory.getLogger(Orchestrator::class.java)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val agents = mutableListOf<McpAgent>()

    fun start() {
        logger.info("Orchestrator started")
        
        // Initialize agents
        val cameraAgent = CameraIntegrationAgent("camera-agent-1")
        agents.add(cameraAgent)

        // Launch agent initialization
        scope.launch {
            agents.forEach { agent ->
                try {
                    agent.initialize()
                } catch (e: Exception) {
                    logger.error("Failed to initialize agent ${agent.agentId}", e)
                }
            }
        }
        
        // Set up NATS subscriptions for task distribution
        setupTaskDistribution()
    }

    private fun setupTaskDistribution() {
        // Subscribe to task request topics
        natsConnection.createDispatcher { msg ->
            scope.launch {
                val taskId = msg.subject.substringAfterLast('.')
                logger.info("Received task request: $taskId")
                // Process task distribution logic
            }
        }.subscribe("mcp.task.>")
    }

    fun stop() {
        runBlocking {
            agents.forEach { it.shutdown() }
        }
        scope.cancel()
        logger.info("Orchestrator stopped")
    }
}
```

### 6.3. CameraIntegrationAgent.kt

```kotlin
package com.example.mcp

import kotlinx.coroutines.delay
import org.slf4j.LoggerFactory

class CameraIntegrationAgent(
    override val agentId: String
) : McpAgent {
    private val logger = LoggerFactory.getLogger(CameraIntegrationAgent::class.java)
    override val capabilities = setOf(Capability.CAMERA_DETECTION)

    override suspend fun initialize() {
        logger.info("[$agentId] Initializing camera integration...")
        // TODO: Add USB UVC camera device detection logic here
        delay(500) // simulating initialization
        logger.info("[$agentId] Camera integration ready")
    }

    override suspend fun processTask(task: AgentTask): TaskResult {
        logger.info("[$agentId] Processing task: ${task.taskId}")
        // TODO: Add camera-specific task processing
        delay(200) // simulating work
        return TaskResult(
            taskId = task.taskId,
            status = TaskStatus.COMPLETED,
            result = "Camera device detection simulated"
        )
    }

    override fun getStatus(): AgentStatus {
        return AgentStatus(
            agentId = agentId,
            state = "ACTIVE",
            healthCheck = true
        )
    }

    override suspend fun shutdown() {
        logger.info("[$agentId] Shutting down")
        // Clean up resources, close camera connections
        delay(200) // simulating cleanup
    }
}

enum class Capability {
    CAMERA_DETECTION,
    CODE_GENERATION,
    BUILD_SYSTEM,
    TESTING
}

data class AgentStatus(
    val agentId: String,
    val state: String,
    val healthCheck: Boolean
)

enum class TaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    FAILED
}
```

## 7. Build and Run Instructions

### 7.1. Start NATS Server

```bash
# Using default configuration
nats-server

# Or with custom config
nats-server -c nats/nats-server.conf
```

### 7.2. Build and Run the MCP

```bash
# Using Gradle wrapper
./gradlew build
./gradlew run

# Or using global Gradle
gradle build
gradle run
```

## 8. Next Steps (Joint - Architect and Coder)

1. **Review and Refine**: Evaluate the initial implementations and adjust as needed
2. **Enhance Core Orchestrator**: Implement full FSM-based agent lifecycle management
3. **Develop Camera Integration Agent**: Implement actual USB device detection
4. **Implement Inter-agent Communication**: Set up proper NATS message patterns
5. **Create Health Check Endpoints**: Implement basic health monitoring
6. **Develop Testing Framework**: Set up unit and integration tests

## 9. References and Resources

- [NATS Documentation](https://docs.nats.io/)
- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-overview.html)
- [Tinder StateMachine](https://github.com/Tinder/StateMachine)
- [Gradle Documentation](https://docs.gradle.org/current/userguide/)

---

This guide provides a starting point for both the architect and coder to begin developing the Multi-Agent Control Platform. Remember to iterate and adapt your approach as you progress through the development process. Good luck with your MCP project!