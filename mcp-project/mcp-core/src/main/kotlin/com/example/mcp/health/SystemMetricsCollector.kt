package com.example.mcp.health

import org.slf4j.LoggerFactory
import java.lang.management.ManagementFactory
import java.lang.management.MemoryUsage
import kotlin.math.roundToLong

/**
 * Collects system and JVM metrics for health monitoring.
 */
class SystemMetricsCollector {
    private val logger = LoggerFactory.getLogger(SystemMetricsCollector::class.java)
    private val runtime = Runtime.getRuntime()
    private val memoryMXBean = ManagementFactory.getMemoryMXBean()
    private val threadMXBean = ManagementFactory.getThreadMXBean()
    private val garbageCollectorMXBeans = ManagementFactory.getGarbageCollectorMXBeans()
    
    /**
     * Collects system metrics including CPU, memory, and thread usage.
     * @return SystemMetrics containing current usage data
     */
    fun collectMetrics(): SystemMetrics {
        logger.debug("Collecting system metrics")
        return SystemMetrics(
            cpuMetrics = collectCpuMetrics(),
            memoryMetrics = collectMemoryMetrics(),
            threadMetrics = collectThreadMetrics(),
            gcMetrics = collectGcMetrics()
        )
    }
    
    private fun collectCpuMetrics(): CpuMetrics {
        val osBean = ManagementFactory.getOperatingSystemMXBean()
        val processCpuLoad = when (osBean) {
            is com.sun.management.OperatingSystemMXBean -> osBean.processCpuLoad * 100
            else -> -1.0 // Not available
        }
        
        val systemCpuLoad = when (osBean) {
            is com.sun.management.OperatingSystemMXBean -> osBean.systemCpuLoad * 100
            else -> -1.0 // Not available
        }
        
        return CpuMetrics(
            availableProcessors = osBean.availableProcessors,
            systemLoadAverage = osBean.systemLoadAverage,
            processCpuLoad = processCpuLoad,
            systemCpuLoad = systemCpuLoad
        )
    }
    
    private fun collectMemoryMetrics(): MemoryMetrics {
        val heapMemoryUsage: MemoryUsage = memoryMXBean.heapMemoryUsage
        val nonHeapMemoryUsage: MemoryUsage = memoryMXBean.nonHeapMemoryUsage
        
        // Get system memory information
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val maxMemory = runtime.maxMemory()
        val usedMemory = totalMemory - freeMemory
        val heapUtilization = (usedMemory.toDouble() / maxMemory * 100).roundToLong()
        
        return MemoryMetrics(
            totalMemoryBytes = totalMemory,
            freeMemoryBytes = freeMemory,
            usedMemoryBytes = usedMemory,
            maxMemoryBytes = maxMemory,
            heapUtilizationPercent = heapUtilization,
            heapUsed = heapMemoryUsage.used,
            heapCommitted = heapMemoryUsage.committed,
            heapMax = heapMemoryUsage.max,
            nonHeapUsed = nonHeapMemoryUsage.used,
            nonHeapCommitted = nonHeapMemoryUsage.committed
        )
    }
    
    private fun collectThreadMetrics(): ThreadMetrics {
        return ThreadMetrics(
            threadCount = threadMXBean.threadCount,
            peakThreadCount = threadMXBean.peakThreadCount,
            daemonThreadCount = threadMXBean.daemonThreadCount,
            totalStartedThreadCount = threadMXBean.totalStartedThreadCount
        )
    }
    
    private fun collectGcMetrics(): List<GcMetrics> {
        return garbageCollectorMXBeans.map { gcBean ->
            GcMetrics(
                name = gcBean.name,
                collectionCount = gcBean.collectionCount,
                collectionTimeMs = gcBean.collectionTime
            )
        }
    }
}

/**
 * Data classes for storing metrics data
 */
data class SystemMetrics(
    val cpuMetrics: CpuMetrics,
    val memoryMetrics: MemoryMetrics,
    val threadMetrics: ThreadMetrics,
    val gcMetrics: List<GcMetrics>,
    val timestamp: Long = System.currentTimeMillis()
)

data class CpuMetrics(
    val availableProcessors: Int,
    val systemLoadAverage: Double,
    val processCpuLoad: Double,
    val systemCpuLoad: Double
)

data class MemoryMetrics(
    val totalMemoryBytes: Long,
    val freeMemoryBytes: Long,
    val usedMemoryBytes: Long,
    val maxMemoryBytes: Long,
    val heapUtilizationPercent: Long,
    val heapUsed: Long,
    val heapCommitted: Long,
    val heapMax: Long,
    val nonHeapUsed: Long,
    val nonHeapCommitted: Long
)

data class ThreadMetrics(
    val threadCount: Int,
    val peakThreadCount: Int,
    val daemonThreadCount: Int,
    val totalStartedThreadCount: Long
)

data class GcMetrics(
    val name: String,
    val collectionCount: Long,
    val collectionTimeMs: Long
)