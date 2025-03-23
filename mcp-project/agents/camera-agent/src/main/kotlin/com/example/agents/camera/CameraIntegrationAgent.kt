package com.example.agents.camera

import com.example.agents.Capability
import com.example.agents.McpAgent
import com.example.mcp.models.AgentStatus
import com.example.mcp.models.AgentTask
import com.example.mcp.models.TaskResult
import com.example.mcp.models.TaskStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.util.UUID

/**
 * Agent responsible for managing camera detection and operations
 */
class CameraIntegrationAgent(
    override val agentId: String = "camera-integration-agent-${UUID.randomUUID().toString().substring(0, 8)}"
) : McpAgent {
    private val logger = LoggerFactory.getLogger(CameraIntegrationAgent::class.java)
    private val scope = CoroutineScope(Dispatchers.Default + Job())
    private val usbManager = MockUsbManager()
    
    // Define capabilities of this agent
    override val capabilities: Set<Capability> = setOf(Capability.CAMERA_DETECTION)
    
    // Track agent status
    private var currentState = "Idle"
    private var activeTaskCount = 0
    private var healthy = true
    
    /**
     * Initialize the agent and start USB monitoring
     */
    override suspend fun initialize() {
        logger.info("Initializing Camera Integration Agent: $agentId")
        currentState = "Initializing"
        
        try {
            // Start the USB manager
            usbManager.start()
            
            // Subscribe to USB device events
            usbManager.deviceEvents.onEach { event ->
                when (event) {
                    is UsbDeviceEvent.DeviceConnected -> {
                        logger.info("USB camera connected: ${event.device.deviceId} (${event.device.product})")
                    }
                    is UsbDeviceEvent.DeviceDisconnected -> {
                        logger.info("USB camera disconnected: ${event.deviceId}")
                    }
                }
            }.launchIn(scope)
            
            currentState = "Ready"
            healthy = true
            logger.info("Camera Integration Agent initialized successfully")
        } catch (e: Exception) {
            logger.error("Failed to initialize Camera Integration Agent", e)
            currentState = "Error"
            healthy = false
            throw e
        }
    }
    
    /**
     * Process camera-related tasks
     */
    override suspend fun processTask(task: AgentTask): TaskResult {
        logger.info("Processing task: ${task.taskId} (${task.agentType})")
        val startTime = System.currentTimeMillis()
        
        try {
            activeTaskCount++
            currentState = "Processing"
            
            // Parse the task payload
            val payload = Json.decodeFromString<CameraTaskPayload>(task.payload)
            
            // Process the task based on the action
            val result = when (payload.action) {
                CameraAction.LIST_DEVICES -> {
                    // Get list of connected devices
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
                    Json.encodeToString(response)
                }
                
                CameraAction.GET_DEVICE_INFO -> {
                    // Get detailed info for a specific device
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
                        Json.encodeToString(response)
                    }
                }
                
                CameraAction.CAPTURE_FRAME -> {
                    // Simulate capturing a frame from the camera
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
                        // Here we just return a mock response with the image dimensions.
                        val response = CameraFrameCaptureResponse(
                            success = true,
                            width = 640,
                            height = 480,
                            format = "RGB",
                            message = "Frame captured successfully"
                        )
                        Json.encodeToString(response)
                    }
                }
            }
            
            val processingTime = System.currentTimeMillis() - startTime
            activeTaskCount--
            currentState = "Ready"
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = result,
                processingTimeMs = processingTime
            )
        } catch (e: Exception) {
            logger.error("Error processing task ${task.taskId}", e)
            activeTaskCount--
            currentState = "Ready"
            
            return createErrorResult(task.taskId, e.message ?: "Unknown error", startTime)
        }
    }
    
    /**
     * Get the current agent status
     */
    override fun getStatus(): AgentStatus {
        return AgentStatus(
            agentId = agentId,
            state = currentState,
            healthCheck = healthy,
            activeTaskCount = activeTaskCount,
            lastHeartbeatMs = System.currentTimeMillis()
        )
    }
    
    /**
     * Shutdown the agent and release resources
     */
    override suspend fun shutdown() {
        logger.info("Shutting down Camera Integration Agent: $agentId")
        currentState = "ShuttingDown"
        
        try {
            // Cancel all coroutines
            scope.cancel()
            
            currentState = "Shutdown"
            logger.info("Camera Integration Agent shut down successfully")
        } catch (e: Exception) {
            logger.error("Error shutting down Camera Integration Agent", e)
            throw e
        }
    }
    
    /**
     * Helper method to create an error result
     */
    private fun createErrorResult(taskId: String, errorMessage: String, startTime: Long): TaskResult {
        val processingTime = System.currentTimeMillis() - startTime
        return TaskResult(
            taskId = taskId,
            status = TaskStatus.FAILED,
            error = errorMessage,
            processingTimeMs = processingTime
        )
    }
}

/**
 * Camera task payload for parsing task requests
 */
@kotlinx.serialization.Serializable
data class CameraTaskPayload(
    val action: CameraAction,
    val deviceId: String? = null
)

/**
 * Possible camera actions
 */
@kotlinx.serialization.Serializable
enum class CameraAction {
    LIST_DEVICES,
    GET_DEVICE_INFO,
    CAPTURE_FRAME
}

/**
 * Response for the LIST_DEVICES action
 */
@kotlinx.serialization.Serializable
data class CameraListDevicesResponse(
    val devices: List<DeviceInfo>
)

/**
 * Simplified device info for responses
 */
@kotlinx.serialization.Serializable
data class DeviceInfo(
    val id: String,
    val manufacturer: String,
    val product: String,
    val vendorId: Int,
    val productId: Int
)

/**
 * Response for the GET_DEVICE_INFO action
 */
@kotlinx.serialization.Serializable
data class CameraDeviceInfoResponse(
    val deviceInfo: String
)

/**
 * Response for the CAPTURE_FRAME action
 */
@kotlinx.serialization.Serializable
data class CameraFrameCaptureResponse(
    val success: Boolean,
    val width: Int? = null,
    val height: Int? = null,
    val format: String? = null,
    val message: String
)