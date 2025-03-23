package com.example.mcp.health

import org.junit.jupiter.api.Test
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class SystemMetricsCollectorTest {

    private val metricsCollector = SystemMetricsCollector()

    @Test
    fun `collectMetrics should return valid system metrics`() {
        // When
        val metrics = metricsCollector.collectMetrics()
        
        // Then
        with(metrics) {
            // Verify CPU metrics
            assertNotNull(cpuMetrics)
            assertTrue(cpuMetrics.availableProcessors > 0)
            
            // Verify memory metrics
            assertNotNull(memoryMetrics)
            assertTrue(memoryMetrics.totalMemoryBytes > 0)
            assertTrue(memoryMetrics.maxMemoryBytes > 0)
            assertTrue(memoryMetrics.heapUsed >= 0)
            assertTrue(memoryMetrics.heapCommitted > 0)
            
            // Verify thread metrics
            assertNotNull(threadMetrics)
            assertTrue(threadMetrics.threadCount > 0)
            assertTrue(threadMetrics.totalStartedThreadCount > 0)
            
            // Verify GC metrics
            assertNotNull(gcMetrics)
            // The list might be empty if no GC has occurred yet, but it should be non-null
            
            // Verify timestamp
            assertTrue(timestamp > 0)
        }
    }

    @Test
    fun `collectMetrics should handle JVM metrics correctly`() {
        // When
        val metrics = metricsCollector.collectMetrics()
        
        // Then - verify heap utilization is calculated correctly
        with(metrics.memoryMetrics) {
            val expected = (usedMemoryBytes.toDouble() / maxMemoryBytes * 100).toLong()
            assertTrue { 
                // Allow for small rounding differences
                kotlin.math.abs(heapUtilizationPercent - expected) <= 1
            }
        }
    }

    @Test
    fun `collectMetrics should return consistent values across multiple calls`() {
        // When
        val metrics1 = metricsCollector.collectMetrics()
        val metrics2 = metricsCollector.collectMetrics()
        
        // Then - values shouldn't drastically change between immediate calls
        // Note: This is a basic consistency check, not an exact equality check
        // as some values can change between calls
        with(metrics1) {
            assertTrue(cpuMetrics.availableProcessors == metrics2.cpuMetrics.availableProcessors)
            
            // Memory and thread values can change slightly between calls, but shouldn't be drastically different
            assertTrue { metrics1.memoryMetrics.maxMemoryBytes == metrics2.memoryMetrics.maxMemoryBytes }
            
            // Thread count should be fairly stable in these tests
            val threadCountDiff = kotlin.math.abs(
                metrics1.threadMetrics.threadCount - metrics2.threadMetrics.threadCount
            )
            assertTrue(threadCountDiff < 10, "Thread count changed too much between calls")
        }
    }
}