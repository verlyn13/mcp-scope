---
title: "MCP Testing Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
related_docs:
  - "/docs/guides/build-engineer-implementation-guide.md"
  - "/docs/guides/containerized-dev-environment.md"
  - "/docs/project/build-engineer-next-steps.md"
tags: ["testing", "junit", "mockk", "gradle", "kotlin-test"]
---

# MCP Testing Guide

[↩️ Back to Start Here](/docs/START_HERE.md) | [↩️ Back to Documentation Index](/docs/README.md)

## Overview

This guide documents the testing infrastructure for the Multi-Agent Control Platform (MCP). It covers unit testing, integration testing, and health monitoring tests. The guide also provides best practices for writing new tests and running tests in both local and containerized environments.

## Testing Infrastructure

The MCP project uses the following testing libraries:

- **JUnit 5**: Core testing framework
- **Mockk**: Mocking library for Kotlin
- **Kotlin Test**: Assertions and test utilities
- **Kotlinx Coroutines Test**: Utilities for testing coroutines

The testing configuration is defined in the Gradle build files:

```kotlin
dependencies {
    // Testing
    testImplementation("org.jetbrains.kotlin:kotlin-test:1.8.10")
    testImplementation("io.mockk:mockk:1.13.4")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")
    testImplementation("org.junit.jupiter:junit-jupiter:5.9.2")
}

tasks.withType<Test> {
    useJUnitPlatform()
}
```

## Test Structure

Unit tests are organized in a directory structure mirroring the main source code:

```
mcp-core/
├── src/
│   ├── main/kotlin/com/example/mcp/...
│   └── test/kotlin/com/example/mcp/
│       ├── AgentStateMachineTest.kt
│       ├── NatsConnectionManagerTest.kt
│       ├── OrchestratorTest.kt
│       └── health/
│           ├── SystemMetricsCollectorTest.kt
│           └── HealthCheckServiceTest.kt
```

## Running Tests

### Local Environment

To run tests on your local machine:

```bash
# Navigate to the project directory
cd mcp-project

# Run all tests
./gradlew test

# Run specific module tests
./gradlew :mcp-core:test

# Run a specific test class
./gradlew :mcp-core:test --tests "com.example.mcp.AgentStateMachineTest"

# Run a specific test method
./gradlew :mcp-core:test --tests "com.example.mcp.AgentStateMachineTest.initial state should be Idle"
```

### Containerized Environment

To run tests in the containerized environment:

```bash
# Run tests in the mcp-core container
podman exec -it mcp-project_mcp-core_1 ./gradlew test

# Run a specific test
podman exec -it mcp-project_mcp-core_1 ./gradlew test --tests "com.example.mcp.NatsConnectionManagerTest"
```

## Key Test Components

### Agent State Machine Tests

The `AgentStateMachineTest` class tests the state machine transitions and behavior of the agent lifecycle:

- Tests initial state
- Tests state transitions for initialize, process, and shutdown
- Tests error handling and recovery
- Tests task processing

### NATS Connection Tests

The `NatsConnectionManagerTest` class tests the NATS connection management:

- Tests connection establishment
- Tests connection error handling
- Tests connection configuration
- Tests proper resource cleanup

### Orchestrator Tests

The `OrchestratorTest` class tests the orchestrator's ability to manage agents:

- Tests agent registration
- Tests task distribution
- Tests communication with agents
- Tests orchestrator lifecycle

### Health Monitoring Tests

The health monitoring system includes tests for:

- System metrics collection
- Health check endpoints
- Circuit breaker pattern
- Resilience mechanisms

## Test Best Practices

### Mocking

Use Mockk to create mock objects for dependencies:

```kotlin
// Create a mock agent
val mockAgent = mockk<McpAgent>(relaxed = true) {
    every { agentId } returns "test-agent"
    every { capabilities } returns setOf(Capability.TESTING)
    coEvery { initialize() } returns Unit
}
```

### Testing Coroutines

Use the `runTest` function from `kotlinx.coroutines.test` for testing coroutines:

```kotlin
@Test
fun `test coroutine behavior`() = runTest {
    // Test code using coroutines
    val result = someCoroutineFunction()
    assertEquals(expectedValue, result)
    
    // Advance time if needed
    advanceTimeBy(1000)
    advanceUntilIdle()
}
```

### Testing States and Events

For testing state machines and event-driven code:

1. Set up the initial state
2. Trigger an event
3. Verify the new state
4. Verify side effects

Example:

```kotlin
@Test
fun `initialize should transition to Initializing state`() = runTest {
    // Initial state check
    assertEquals(AgentState.Idle, stateMachine.getCurrentState())
    
    // Trigger event
    stateMachine.initialize()
    
    // Verify state transition
    assertEquals(AgentState.Initializing, stateMachine.getCurrentState())
    
    // Allow coroutines to complete
    advanceUntilIdle()
    
    // Verify side effects
    coVerify { mockAgent.initialize() }
}
```

### Testing Error Scenarios

Always test both success and failure paths:

```kotlin
@Test
fun `failed initialization should transition to Error state`() = runTest {
    // Configure mock to throw exception
    coEvery { mockAgent.initialize() } throws Exception("Test error")
    
    // Trigger event
    stateMachine.initialize()
    
    // Allow coroutines to complete
    advanceUntilIdle()
    
    // Verify error state
    assertEquals(AgentState.Error, stateMachine.getCurrentState())
}
```

## Writing New Tests

When adding new functionality, follow these steps for test-driven development:

1. Write a test that describes the expected behavior
2. Implement the functionality to make the test pass
3. Refactor as needed while keeping tests passing

### Test Structure Template

```kotlin
@Test
fun `descriptive test name with expected behavior`() {
    // Arrange - set up test conditions
    val sut = SystemUnderTest()
    
    // Act - perform the action being tested
    val result = sut.methodBeingTested()
    
    // Assert - verify the expected outcome
    assertEquals(expectedValue, result)
}
```

## Integration Testing

Integration tests verify that components work together correctly:

1. **Agent-Orchestrator Integration**: Tests that agents properly register with the orchestrator and respond to commands
2. **NATS Messaging Integration**: Tests that messages flow correctly between components
3. **Health Monitoring Integration**: Tests that health metrics are collected and reported

## Test Performance

For maintaining test performance:

- Use appropriate scopes for test fixtures (method, class, or module level)
- Clean up resources after tests
- Be careful with time-dependent tests
- Use `@BeforeEach` and `@AfterEach` for setup and teardown

## Troubleshooting Tests

Common issues and solutions:

### Flaky Tests

- Tests that sometimes pass and sometimes fail often have timing issues
- Use `advanceUntilIdle()` instead of fixed delays
- Add logging to identify the issue

### Resource Leaks

- Always close resources in `@AfterEach` or use `use {}` blocks
- Watch for unclosed coroutine scopes

### Mock Configuration Issues

- Ensure mocks are properly configured for the right methods
- Check for missing or incorrect `every` or `coEvery` statements

## Continuous Improvement

The testing infrastructure is designed to evolve with the project:

1. Regularly review test coverage
2. Refactor tests as the codebase changes
3. Add new tests for bug fixes and new features

## References

- [JUnit 5 Documentation](https://junit.org/junit5/docs/current/user-guide/)
- [Mockk Documentation](https://mockk.io/)
- [Kotlin Test Documentation](https://kotlinlang.org/api/latest/kotlin.test/)
- [Kotlinx Coroutines Test Documentation](https://kotlin.github.io/kotlinx.coroutines/kotlinx-coroutines-test/)