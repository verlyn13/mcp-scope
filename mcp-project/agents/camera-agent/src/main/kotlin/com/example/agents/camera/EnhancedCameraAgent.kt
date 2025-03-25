package com.example.agents.camera

import com.example.agents.BaseAgent
import com.example.agents.Capability
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Enhanced Camera Integration Agent that uses the FSM framework.
 * 
 * This implementation leverages the BaseAgent class to handle common functionality
 * while focusing on camera-specific operations.
 */
class EnhancedCameraAgent(
    agentId: String = "camera-agent-${UUID.randomUUID().toString().substring(0, 8)}",
    private val usbManager: MockUsbManager = MockUsbManager(),
    natsUrl: String = "nats://localhost:4222"
) : BaseAgent(
    agentId = agentId,
    agentType = "camera",
    capabilities = setOf(
        Capability.CameraDetection,
        Capability.CameraConfiguration,
        Capability.FrameCapture
    ),
    natsUrl = natsUrl
) {
    private val logger = LoggerFactory.getLogger(EnhancedCameraAgent::class.java)
    private val isInitialized = AtomicBoolean(false)
    private val activeDevices = ConcurrentHashMap<String, DeviceInfo>()
    private val json = Json { ignoreUnknownKeys = true }
    
    /**
     * Initialize camera resources and scanning.
     */
    override suspend fun doInitialize(): Boolean {
        logger.info("Initializing camera resources")
        
        try {
            // Start the USB manager
            usbManager.start()
            
            // Scan for initially connected devices
            updateConnectedDevices()
            
            // Subscribe to USB device events
            usbManager.deviceEvents.onEach { event ->
                when (event) {
                    is UsbDeviceEvent.DeviceConnected -> {
                        val device = event.device
                        logger.info("USB camera connected: ${device.deviceId} (${device.product})")
                        updateDeviceInfo(device)
                    }
                    is UsbDeviceEvent.DeviceDisconnected -> {
                        logger.info("USB camera disconnected: ${event.deviceId}")
                        activeDevices.remove(event.deviceId)
                    }
                }
                
                // Update metrics after device change
                updateDeviceMetrics()
            }.launchIn(scope)
            
            isInitialized.set(true)
            return true
        } catch (e: Exception) {
            logger.error("Failed to initialize camera resources", e)
            return false
        }
    }
    
    /**
     * Process camera-related tasks.
     */
    override suspend fun doProcessTask(task: AgentTask): TaskResult {
        logger.info("Processing camera task: ${task.taskId}, type: ${task.taskType}")
        val startTime = System.currentTimeMillis()
        
        return try {
            // Determine the action from the task type or parameters
            val action = determineTaskAction(task)
            
            when (action) {
                "camera.scan" -> handleScanTask(task, startTime)
                "camera.capture" -> handleCaptureTask(task, startTime)
                "camera.configure" -> handleConfigureTask(task, startTime)
                else -> {
                    // For backward compatibility, try to parse the legacy JSON payload
                    try {
                        handleLegacyTask(task, startTime)
                    } catch (e: Exception) {
                        createErrorResult(
                            task.taskId,
                            "Unsupported task type: ${task.taskType}",
                            startTime
                        )
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Error processing task ${task.taskId}", e)
            createErrorResult(
                task.taskId,
                "Exception during processing: ${e.message}",
                startTime
            )
        }
    }
    
    /**
     * Release camera resources during shutdown.
     */
    override suspend fun doShutdown() {
        logger.info("Releasing camera resources")
        
        try {
            // Nothing specific to close in the mock implementation
            activeDevices.clear()
        } catch (e: Exception) {
            logger.error("Error during camera shutdown", e)
        }
    }
    
    /**
     * Handle camera-specific errors.
     */
    override suspend fun doHandleError(error: Exception): Boolean {
        logger.error("Handling camera error", error)
        
        // Attempt to recover by rescanning devices
        try {
            updateConnectedDevices()
            logger.info("Successfully recovered by rescanning devices")
            return true
        } catch (e: Exception) {
            logger.error("Recovery attempt failed", e)
            return false
        }
    }
    
    /**
     * Collect camera-specific metrics.
     */
    override fun collectMetrics(): Map<String, Double> {
        val baseMetrics = super.collectMetrics().toMutableMap()
        
        // Add camera-specific metrics
        updateDeviceMetrics()
        
        return baseMetrics
    }
    
    /**
     * Update metrics related to connected devices.
     */
    private fun updateDeviceMetrics() {
        metrics["camera.devices.count"] = activeDevices.size.toDouble()
        
        // Count devices by manufacturer
        val manufacturerCounts = activeDevices.values
            .groupingBy { it.manufacturer }
            .eachCount()
        
        manufacturerCounts.forEach { (manufacturer, count) ->
            metrics["camera.devices.manufacturer.${manufacturer.lowercase()}"] = count.toDouble()
        }
    }
    
    /**
     * Update the list of connected devices.
     */
    private fun updateConnectedDevices() {
        val devices = usbManager.getConnectedDevices()
        
        // Clear and update active devices map
        activeDevices.clear()
        devices.forEach { device ->
            updateDeviceInfo(device)
        }
        
        updateDeviceMetrics()
    }
    
    /**
     * Update device info in the active devices map.
     */
    private fun updateDeviceInfo(device: MockUsbDevice) {
        activeDevices[device.deviceId] = DeviceInfo(
            id = device.deviceId,
            manufacturer = device.manufacturer,
            product = device.product,
            vendorId = device.vendorId,
            productId = device.productId
        )
    }
    
    /**
     * Determine the action to take based on the task.
     */
    private fun determineTaskAction(task: AgentTask): String {
        // First check if the task type directly specifies the action
        if (task.taskType.startsWith("camera.")) {
            return task.taskType
        }
        
        // Otherwise, look for an action parameter
        val action = task.parameters["action"]
        if (action != null && action.startsWith("camera.")) {
            return action
        }
        
        // Default to the task type
        return task.taskType
    }
    
    /**
     * Handle a device scanning task.
     */
    private suspend fun handleScanTask(task: AgentTask, startTime: Long): TaskResult {
        try {
            updateConnectedDevices()
            
            val deviceList = activeDevices.values.toList()
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = "Found ${deviceList.size} USB camera devices",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
        } catch (e: Exception) {
            return createErrorResult(
                task.taskId,
                "Failed to scan devices: ${e.message}",
                startTime
            )
        }
    }
    
    /**
     * Handle a frame capture task.
     */
    private suspend fun handleCaptureTask(task: AgentTask, startTime: Long): TaskResult {
        val deviceId = task.parameters["deviceId"]
        
        if (deviceId == null) {
            return createErrorResult(
                task.taskId,
                "Missing deviceId parameter",
                startTime
            )
        }
        
        val device = usbManager.getDeviceById(deviceId)
        if (device == null || !device.isConnected) {
            return createErrorResult(
                task.taskId,
                "Device not found or disconnected: $deviceId",
                startTime
            )
        }
        
        try {
            // In a real implementation, would capture a frame from the device
            // For now, just simulate a frame capture
            delay(500) // Simulate capture time
            
            val response = CameraFrameCaptureResponse(
                success = true,
                width = 640,
                height = 480,
                format = "RGB",
                message = "Frame captured successfully from device $deviceId"
            )
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = json.encodeToString(response),
                executionTimeMs = System.currentTimeMillis() - startTime
            )
        } catch (e: Exception) {
            return createErrorResult(
                task.taskId,
                "Failed to capture frame: ${e.message}",
                startTime
            )
        }
    }
    
    /**
     * Handle a device configuration task.
     */
    private suspend fun handleConfigureTask(task: AgentTask, startTime: Long): TaskResult {
        val deviceId = task.parameters["deviceId"]
        
        if (deviceId == null) {
            return createErrorResult(
                task.taskId,
                "Missing deviceId parameter",
                startTime
            )
        }
        
        val device = usbManager.getDeviceById(deviceId)
        if (device == null || !device.isConnected) {
            return createErrorResult(
                task.taskId,
                "Device not found or disconnected: $deviceId",
                startTime
            )
        }
        
        try {
            // In a real implementation, would configure the device with parameters
            // For now, just simulate configuration
            delay(300) // Simulate configuration time
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = "Configured device $deviceId successfully",
                executionTimeMs = System.currentTimeMillis() - startTime
            )
        } catch (e: Exception) {
            return createErrorResult(
                task.taskId,
                "Failed to configure device: ${e.message}",
                startTime
            )
        }
    }
    
    /**
     * Handle a task using the legacy format (for backward compatibility).
     */
    private suspend fun handleLegacyTask(task: AgentTask, startTime: Long): TaskResult {
        // Parse the task payload
        val payload = json.decodeFromString<CameraTaskPayload>(task.parameters["payload"] ?: task.parameters.toString())
        
        // Process based on action
        return when (payload.action) {
            CameraAction.LIST_DEVICES -> {
                val devices = usbManager.getConnectedDevices()
                val response = CameraListDevicesResponse(
                    devices = devices.map { 
                        DeviceInfo(
                            id = it.deviceId,
                            manufacturer = it.manufacturer,
                            product = it.product,
                            vendorId = it.vendorId,
                            productId = it.productId
                        )
                    }
                )
                TaskResult(
                    taskId = task.taskId,
                    status = TaskStatus.COMPLETED,
                    result = json.encodeToString(response),
                    executionTimeMs = System.currentTimeMillis() - startTime
                )
            }
            
            CameraAction.GET_DEVICE_INFO -> {
                val deviceId = payload.deviceId ?: return createErrorResult(
                    task.taskId, 
                    "No deviceId provided for GET_DEVICE_INFO action",
                    startTime
                )
                
                val device = usbManager.getDeviceById(deviceId)
                if (device == null) {
                    createErrorResult(task.taskId, "Device not found: $deviceId", startTime)
                } else {
                    val deviceInfo = device.getDeviceInfo()
                    val response = CameraDeviceInfoResponse(
                        deviceInfo = deviceInfo
                    )
                    TaskResult(
                        taskId = task.taskId,
                        status = TaskStatus.COMPLETED,
                        result = json.encodeToString(response),
                        executionTimeMs = System.currentTimeMillis() - startTime
                    )
                }
            }
            
            CameraAction.CAPTURE_FRAME -> {
                val deviceId = payload.deviceId ?: return createErrorResult(
                    task.taskId, 
                    "No deviceId provided for CAPTURE_FRAME action",
                    startTime
                )
                
                val device = usbManager.getDeviceById(deviceId)
                if (device == null || !device.isConnected) {
                    createErrorResult(task.taskId, "Device not found or disconnected: $deviceId", startTime)
                } else {
                    // In a real implementation, this would capture an actual frame.
                    val response = CameraFrameCaptureResponse(
                        success = true,
                        width = 640,
                        height = 480,
                        format = "RGB",
                        message = "Frame captured successfully"
                    )
                    TaskResult(
                        taskId = task.taskId,
                        status = TaskStatus.COMPLETED,
                        result = json.encodeToString(response),
                        executionTimeMs = System.currentTimeMillis() - startTime
                    )
                }
            }
        }
    }
    
    /**
     * Helper method to create an error result.
     */
    private fun createErrorResult(taskId: String, errorMessage: String, startTime: Long): TaskResult {
        val processingTime = System.currentTimeMillis() - startTime
        return TaskResult(
            taskId = taskId,
            status = TaskStatus.FAILED,
            errorMessage = errorMessage,
            executionTimeMs = processingTime
        )
    }
}