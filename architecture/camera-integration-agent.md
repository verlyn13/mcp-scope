# Camera Integration Agent Specification

## Overview

This document specifies the design of the Camera Integration Agent for the Multi-Agent Control Platform (MCP). This agent is responsible for detecting, communicating with, and managing USB UVC (USB Video Class) camera devices. It serves as the foundation for all camera-related operations in the platform.

## Core Components

### 1. Camera Integration Agent Implementation

The Camera Integration Agent implements the McpAgent interface and provides specialized camera functionality:

```kotlin
class CameraIntegrationAgent(
    override val agentId: String,
    private val natsConnection: Connection,
    private val config: CameraAgentConfig
) : McpAgent {
    // Agent type identifier
    override val agentType: String = "camera-integration"
    
    // Camera-specific capabilities
    override val capabilities: Set<Capability> = setOf(
        Capability.CameraDetection,
        Capability.CameraConfiguration,
        Capability.FrameCapture
    )
    
    // Logger for the agent
    private val logger = LoggerFactory.getLogger(CameraIntegrationAgent::class.java)
    
    // Device manager for USB camera detection and communication
    private val deviceManager = UsbDeviceManager()
    
    // Frame processor for handling camera frames
    private val frameProcessor = FrameProcessor()
    
    // State machine for lifecycle management
    private val stateMachine = AgentStateMachine(this)
    
    // Coroutine scope for the agent
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    // Initialize the agent
    override suspend fun initialize(): Boolean {
        try {
            logger.info("[$agentId] Initializing camera integration agent")
            
            // Initialize USB device manager
            deviceManager.initialize()
            
            // Initialize frame processor
            frameProcessor.initialize()
            
            // Set up NATS subscriptions
            setupSubscriptions()
            
            // Start periodic device scanning
            startDeviceScanning()
            
            logger.info("[$agentId] Camera integration agent initialized successfully")
            return true
        } catch (e: Exception) {
            logger.error("[$agentId] Failed to initialize camera integration agent", e)
            return false
        }
    }
    
    // Process camera-related tasks
    override suspend fun processTask(task: AgentTask): TaskResult {
        logger.info("[$agentId] Processing task: ${task.taskId} (${task.taskType})")
        
        val startTime = System.currentTimeMillis()
        
        try {
            val result = when (task.taskType) {
                "detect-devices" -> detectCameraDevices(task)
                "connect-device" -> connectToDevice(task)
                "disconnect-device" -> disconnectFromDevice(task)
                "get-device-info" -> getDeviceInfo(task)
                "capture-frame" -> captureFrame(task)
                "configure-camera" -> configureCamera(task)
                else -> throw IllegalArgumentException("Unknown task type: ${task.taskType}")
            }
            
            val endTime = System.currentTimeMillis()
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.COMPLETED,
                result = result,
                executionTimeMs = endTime - startTime
            )
        } catch (e: Exception) {
            logger.error("[$agentId] Error processing task: ${task.taskId}", e)
            
            val endTime = System.currentTimeMillis()
            
            return TaskResult(
                taskId = task.taskId,
                status = TaskStatus.FAILED,
                errorMessage = e.message ?: "Unknown error",
                executionTimeMs = endTime - startTime
            )
        }
    }
    
    // Get the current status of the agent
    override fun getStatus(): AgentStatus {
        val connectedDevices = deviceManager.getConnectedDevices()
        
        return AgentStatus(
            agentId = agentId,
            state = stateMachine.getCurrentState(),
            healthy = deviceManager.isInitialized(),
            metrics = mapOf(
                "connectedDeviceCount" to connectedDevices.size.toDouble(),
                "frameProcessingRate" to frameProcessor.getProcessingRate()
            ),
            currentTask = null, // Updated during task processing
            lastActiveTimestamp = deviceManager.getLastActivityTimestamp(),
            tasksCompleted = 0,  // Track this in the real implementation
            tasksFailed = 0      // Track this in the real implementation
        )
    }
    
    // Handle error conditions
    override suspend fun handleError(error: Exception): Boolean {
        logger.error("[$agentId] Handling error in camera integration agent", error)
        
        try {
            // Attempt to recover from USB errors
            if (error is UsbException) {
                logger.info("[$agentId] Attempting USB device reset")
                deviceManager.resetAllDevices()
                return true
            }
            
            // Attempt to recover from frame processing errors
            if (error is FrameProcessingException) {
                logger.info("[$agentId] Resetting frame processor")
                frameProcessor.reset()
                return true
            }
            
            return false
        } catch (e: Exception) {
            logger.error("[$agentId] Error recovery failed", e)
            return false
        }
    }
    
    // Release resources during shutdown
    override suspend fun shutdown() {
        logger.info("[$agentId] Shutting down camera integration agent")
        
        try {
            // Cancel scanning job
            cancelDeviceScanning()
            
            // Disconnect from all devices
            deviceManager.disconnectAll()
            
            // Shut down frame processor
            frameProcessor.shutdown()
            
            // Cancel all coroutines
            scope.cancel()
            
            logger.info("[$agentId] Camera integration agent shut down successfully")
        } catch (e: Exception) {
            logger.error("[$agentId] Error during shutdown", e)
        }
    }
    
    // Set up NATS subscriptions
    private fun setupSubscriptions() {
        val dispatcher = natsConnection.createDispatcher { message ->
            scope.launch {
                handleNatsMessage(message)
            }
        }
        
        // Subscribe to agent-specific messages
        dispatcher.subscribe("mcp.agent.$agentId.task")
    }
    
    // Handle NATS messages
    private suspend fun handleNatsMessage(message: Message) {
        try {
            val taskMessage = Json.decodeFromString<TaskAssignmentMessage>(
                String(message.data)
            )
            
            // Process the task
            val result = processTask(taskMessage.task)
            
            // Publish the result
            val resultMessage = TaskResultMessage(
                result = result
            )
            
            natsConnection.publish(
                "mcp.agent.$agentId.result",
                Json.encodeToString(resultMessage).toByteArray()
            )
        } catch (e: Exception) {
            logger.error("[$agentId] Error handling NATS message", e)
        }
    }
    
    // Start periodic device scanning
    private fun startDeviceScanning() {
        scope.launch {
            while (isActive) {
                try {
                    deviceManager.scanForDevices()
                    
                    // Publish device discovery events
                    val devices = deviceManager.getDetectedDevices()
                    publishDeviceDiscoveryEvent(devices)
                    
                    delay(config.scanIntervalMs)
                } catch (e: Exception) {
                    logger.error("[$agentId] Error during device scanning", e)
                    delay(1000) // Short delay before retry
                }
            }
        }
    }
    
    // Cancel device scanning
    private fun cancelDeviceScanning() {
        scope.cancel()
    }
    
    // Publish device discovery event
    private fun publishDeviceDiscoveryEvent(devices: List<UsbDeviceInfo>) {
        val eventMessage = SystemEventMessage(
            eventType = SystemEventType.DEVICE_DISCOVERY,
            payload = DeviceDiscoveryPayload(
                agentId = agentId,
                devices = devices
            )
        )
        
        natsConnection.publish(
            "mcp.orchestrator.system.event",
            Json.encodeToString(eventMessage).toByteArray()
        )
    }
    
    // Implement camera-specific task handlers
    
    private fun detectCameraDevices(task: AgentTask): CameraDeviceList {
        // Force an immediate scan
        deviceManager.scanForDevices()
        
        // Return detected devices
        val devices = deviceManager.getDetectedDevices()
        return CameraDeviceList(devices)
    }
    
    private fun connectToDevice(task: AgentTask): ConnectionResult {
        val deviceId = task.parameters["deviceId"] as? String
            ?: throw IllegalArgumentException("Missing deviceId parameter")
        
        val success = deviceManager.connectToDevice(deviceId)
        return ConnectionResult(success)
    }
    
    private fun disconnectFromDevice(task: AgentTask): ConnectionResult {
        val deviceId = task.parameters["deviceId"] as? String
            ?: throw IllegalArgumentException("Missing deviceId parameter")
        
        val success = deviceManager.disconnectFromDevice(deviceId)
        return ConnectionResult(success)
    }
    
    private fun getDeviceInfo(task: AgentTask): UsbDeviceInfo {
        val deviceId = task.parameters["deviceId"] as? String
            ?: throw IllegalArgumentException("Missing deviceId parameter")
        
        return deviceManager.getDeviceInfo(deviceId)
            ?: throw IllegalArgumentException("Device not found: $deviceId")
    }
    
    private fun captureFrame(task: AgentTask): FrameCaptureResult {
        val deviceId = task.parameters["deviceId"] as? String
            ?: throw IllegalArgumentException("Missing deviceId parameter")
        
        val format = task.parameters["format"] as? String ?: "MJPEG"
        val resolution = task.parameters["resolution"] as? String ?: "640x480"
        
        val frameData = deviceManager.captureFrame(deviceId, format, resolution)
        val processedFrame = frameProcessor.processFrame(frameData)
        
        return FrameCaptureResult(
            deviceId = deviceId,
            timestamp = System.currentTimeMillis(),
            format = format,
            resolution = resolution,
            frameData = processedFrame,
            metadata = buildFrameMetadata(deviceId, format, resolution)
        )
    }
    
    private fun configureCamera(task: AgentTask): ConfigurationResult {
        val deviceId = task.parameters["deviceId"] as? String
            ?: throw IllegalArgumentException("Missing deviceId parameter")
        
        val configParams = task.parameters["config"] as? Map<String, Any>
            ?: throw IllegalArgumentException("Missing config parameters")
        
        val success = deviceManager.configureDevice(deviceId, configParams)
        return ConfigurationResult(success)
    }
    
    private fun buildFrameMetadata(deviceId: String, format: String, resolution: String): Map<String, Any> {
        val device = deviceManager.getDeviceInfo(deviceId)
        
        return mapOf(
            "deviceName" to (device?.name ?: "Unknown"),
            "deviceVendor" to (device?.vendorId?.toString() ?: "Unknown"),
            "deviceProduct" to (device?.productId?.toString() ?: "Unknown"),
            "format" to format,
            "resolution" to resolution,
            "captureTimestamp" to System.currentTimeMillis()
        )
    }
}

data class CameraAgentConfig(
    val scanIntervalMs: Long = 5000,
    val connectionTimeoutMs: Long = 10000,
    val frameProcessingThreads: Int = 2
)
```

### 2. USB Device Manager

The UsbDeviceManager is responsible for detecting and communicating with USB UVC devices:

```kotlin
class UsbDeviceManager {
    private val logger = LoggerFactory.getLogger(UsbDeviceManager::class.java)
    
    // Map of detected device IDs to their info
    private val detectedDevices = ConcurrentHashMap<String, UsbDeviceInfo>()
    
    // Map of connected device IDs to their handlers
    private val connectedDevices = ConcurrentHashMap<String, UsbDeviceHandler>()
    
    // Last activity timestamp
    private val lastActivityTimestamp = AtomicLong(System.currentTimeMillis())
    
    // Is the device manager initialized
    private var initialized = AtomicBoolean(false)
    
    // Native USB library interface
    private lateinit var usbLibrary: UsbLibrary
    
    // Initialize the USB device manager
    fun initialize() {
        try {
            // Load native USB library
            usbLibrary = loadUsbLibrary()
            
            // Initialize USB context
            usbLibrary.initialize()
            
            initialized.set(true)
            logger.info("USB device manager initialized successfully")
        } catch (e: Exception) {
            logger.error("Failed to initialize USB device manager", e)
            throw e
        }
    }
    
    // Scan for USB UVC devices
    fun scanForDevices() {
        updateLastActivityTimestamp()
        
        try {
            val devices = usbLibrary.enumerateDevices()
            
            // Update detected devices map
            val currentDeviceIds = detectedDevices.keys.toSet()
            val newDeviceIds = devices.map { it.deviceId }.toSet()
            
            // Add new devices
            devices.forEach { device ->
                detectedDevices[device.deviceId] = device
            }
            
            // Remove devices that are no longer present
            val removedDeviceIds = currentDeviceIds - newDeviceIds
            removedDeviceIds.forEach { deviceId ->
                detectedDevices.remove(deviceId)
                
                // Disconnect if connected
                if (connectedDevices.containsKey(deviceId)) {
                    disconnectFromDevice(deviceId)
                }
            }
        } catch (e: Exception) {
            logger.error("Error scanning for USB devices", e)
        }
    }
    
    // Connect to a specific USB device
    fun connectToDevice(deviceId: String): Boolean {
        updateLastActivityTimestamp()
        
        if (connectedDevices.containsKey(deviceId)) {
            logger.info("Device already connected: $deviceId")
            return true
        }
        
        val deviceInfo = detectedDevices[deviceId]
        if (deviceInfo == null) {
            logger.error("Cannot connect to unknown device: $deviceId")
            return false
        }
        
        try {
            val handler = UsbDeviceHandler(deviceInfo, usbLibrary)
            handler.connect()
            
            connectedDevices[deviceId] = handler
            logger.info("Connected to device: $deviceId")
            return true
        } catch (e: Exception) {
            logger.error("Failed to connect to device: $deviceId", e)
            return false
        }
    }
    
    // Disconnect from a specific USB device
    fun disconnectFromDevice(deviceId: String): Boolean {
        updateLastActivityTimestamp()
        
        val handler = connectedDevices[deviceId]
        if (handler == null) {
            logger.info("Device not connected: $deviceId")
            return true
        }
        
        try {
            handler.disconnect()
            connectedDevices.remove(deviceId)
            logger.info("Disconnected from device: $deviceId")
            return true
        } catch (e: Exception) {
            logger.error("Failed to disconnect from device: $deviceId", e)
            return false
        }
    }
    
    // Disconnect from all devices
    fun disconnectAll() {
        updateLastActivityTimestamp()
        
        val deviceIds = connectedDevices.keys.toList()
        deviceIds.forEach { deviceId ->
            disconnectFromDevice(deviceId)
        }
    }
    
    // Reset all devices (for error recovery)
    fun resetAllDevices() {
        updateLastActivityTimestamp()
        
        // Disconnect all devices
        disconnectAll()
        
        // Reset USB library
        try {
            usbLibrary.reset()
            logger.info("USB library reset successfully")
        } catch (e: Exception) {
            logger.error("Failed to reset USB library", e)
        }
    }
    
    // Capture a frame from a specific device
    fun captureFrame(deviceId: String, format: String, resolution: String): ByteArray {
        updateLastActivityTimestamp()
        
        val handler = connectedDevices[deviceId]
            ?: throw IllegalArgumentException("Device not connected: $deviceId")
            
        return handler.captureFrame(format, resolution)
    }
    
    // Configure a specific device
    fun configureDevice(deviceId: String, config: Map<String, Any>): Boolean {
        updateLastActivityTimestamp()
        
        val handler = connectedDevices[deviceId]
            ?: throw IllegalArgumentException("Device not connected: $deviceId")
            
        return handler.configure(config)
    }
    
    // Get information about a specific device
    fun getDeviceInfo(deviceId: String): UsbDeviceInfo? {
        return detectedDevices[deviceId]
    }
    
    // Get list of all detected devices
    fun getDetectedDevices(): List<UsbDeviceInfo> {
        return detectedDevices.values.toList()
    }
    
    // Get list of connected devices
    fun getConnectedDevices(): List<UsbDeviceInfo> {
        return connectedDevices.keys
            .mapNotNull { detectedDevices[it] }
    }
    
    // Check if the device manager is initialized
    fun isInitialized(): Boolean {
        return initialized.get()
    }
    
    // Get the last activity timestamp
    fun getLastActivityTimestamp(): Long {
        return lastActivityTimestamp.get()
    }
    
    // Update the last activity timestamp
    private fun updateLastActivityTimestamp() {
        lastActivityTimestamp.set(System.currentTimeMillis())
    }
    
    // Load the native USB library
    private fun loadUsbLibrary(): UsbLibrary {
        // Implementation would load the appropriate native library
        // based on the operating system and architecture
        return UsbLibraryImpl()
    }
}

// Native USB library interface
interface UsbLibrary {
    fun initialize()
    fun enumerateDevices(): List<UsbDeviceInfo>
    fun openDevice(deviceId: String): Long
    fun closeDevice(handle: Long)
    fun controlTransfer(handle: Long, request: Int, value: Int, index: Int, data: ByteArray): Int
    fun bulkTransfer(handle: Long, endpoint: Int, data: ByteArray, timeout: Int): Int
    fun reset()
}

// USB device handler for individual device operations
class UsbDeviceHandler(
    private val deviceInfo: UsbDeviceInfo,
    private val usbLibrary: UsbLibrary
) {
    private val logger = LoggerFactory.getLogger(UsbDeviceHandler::class.java)
    
    // Device handle for native operations
    private var deviceHandle: Long = 0
    
    // Connect to the device
    fun connect() {
        deviceHandle = usbLibrary.openDevice(deviceInfo.deviceId)
        if (deviceHandle == 0L) {
            throw UsbException("Failed to open device: ${deviceInfo.deviceId}")
        }
        
        // Initialize UVC device
        initializeUvcDevice()
    }
    
    // Initialize UVC-specific features
    private fun initializeUvcDevice() {
        // Implementation would configure the UVC device
        // (control transfers, stream negotiation, etc.)
    }
    
    // Disconnect from the device
    fun disconnect() {
        if (deviceHandle != 0L) {
            usbLibrary.closeDevice(deviceHandle)
            deviceHandle = 0
        }
    }
    
    // Capture a frame from the device
    fun captureFrame(format: String, resolution: String): ByteArray {
        if (deviceHandle == 0L) {
            throw UsbException("Device not connected")
        }
        
        // Implementation would:
        // 1. Configure the format and resolution
        // 2. Start the streaming if not already started
        // 3. Capture a frame using bulk transfers
        // 4. Process the raw frame data
        
        return ByteArray(0) // Placeholder
    }
    
    // Configure the device
    fun configure(config: Map<String, Any>): Boolean {
        if (deviceHandle == 0L) {
            throw UsbException("Device not connected")
        }
        
        try {
            // Implementation would apply configuration parameters
            // using UVC control requests
            
            return true
        } catch (e: Exception) {
            logger.error("Failed to configure device: ${deviceInfo.deviceId}", e)
            return false
        }
    }
}
```

### 3. Frame Processor

The FrameProcessor handles image processing operations on camera frames:

```kotlin
class FrameProcessor {
    private val logger = LoggerFactory.getLogger(FrameProcessor::class.java)
    
    // Thread pool for frame processing
    private lateinit var processingExecutor: ExecutorService
    
    // Processing rate tracking
    private val processingRateTracker = RateTracker(100)
    
    // Initialize the frame processor
    fun initialize() {
        // Create a fixed thread pool for processing
        processingExecutor = Executors.newFixedThreadPool(
            Runtime.getRuntime().availableProcessors()
        )
        
        logger.info("Frame processor initialized with ${Runtime.getRuntime().availableProcessors()} threads")
    }
    
    // Process a raw frame
    fun processFrame(frameData: ByteArray): ByteArray {
        processingRateTracker.increment()
        
        try {
            // Basic frame processing would:
            // 1. Decode the frame (MJPEG, H.264, etc.)
            // 2. Apply any required transformations
            // 3. Optionally re-encode to a different format
            
            return frameData // Placeholder
        } catch (e: Exception) {
            logger.error("Error processing frame", e)
            throw FrameProcessingException("Frame processing failed", e)
        }
    }
    
    // Reset the frame processor
    fun reset() {
        // Implementation would reset any internal state
        logger.info("Frame processor reset")
    }
    
    // Shut down the frame processor
    fun shutdown() {
        processingExecutor.shutdown()
        try {
            if (!processingExecutor.awaitTermination(5, TimeUnit.SECONDS)) {
                processingExecutor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            processingExecutor.shutdownNow()
        }
        
        logger.info("Frame processor shut down")
    }
    
    // Get the current processing rate (frames per second)
    fun getProcessingRate(): Double {
        return processingRateTracker.getRate()
    }
}

// Rate tracker utility for performance monitoring
class RateTracker(private val windowSizeMs: Long) {
    private val timestamps = ConcurrentLinkedQueue<Long>()
    
    // Record an event
    fun increment() {
        val now = System.currentTimeMillis()
        timestamps.add(now)
        
        // Remove old timestamps
        while (!timestamps.isEmpty()) {
            val oldest = timestamps.peek()
            if (now - oldest > windowSizeMs) {
                timestamps.poll()
            } else {
                break
            }
        }
    }
    
    // Calculate events per second
    fun getRate(): Double {
        val count = timestamps.size
        return count * (1000.0 / windowSizeMs)
    }
}
```

## Data Models

### 1. USB Device Models

```kotlin
data class UsbDeviceInfo(
    val deviceId: String,
    val name: String,
    val vendorId: Int,
    val productId: Int,
    val serialNumber: String?,
    val isUvcCompliant: Boolean,
    val supportedFormats: List<FormatInfo>,
    val controlEndpoint: Int,
    val inEndpoint: Int?,
    val outEndpoint: Int?
)

data class FormatInfo(
    val format: String,
    val supportedResolutions: List<ResolutionInfo>
)

data class ResolutionInfo(
    val width: Int,
    val height: Int,
    val frameRates: List<Double>
)
```

### 2. Task Result Models

```kotlin
data class CameraDeviceList(
    val devices: List<UsbDeviceInfo>
)

data class ConnectionResult(
    val success: Boolean,
    val message: String? = null
)

data class FrameCaptureResult(
    val deviceId: String,
    val timestamp: Long,
    val format: String,
    val resolution: String,
    val frameData: ByteArray,
    val metadata: Map<String, Any>
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        
        other as FrameCaptureResult
        
        if (deviceId != other.deviceId) return false
        if (timestamp != other.timestamp) return false
        if (format != other.format) return false
        if (resolution != other.resolution) return false
        if (!frameData.contentEquals(other.frameData)) return false
        if (metadata != other.metadata) return false
        
        return true
    }
    
    override fun hashCode(): Int {
        var result = deviceId.hashCode()
        result = 31 * result + timestamp.hashCode()
        result = 31 * result + format.hashCode()
        result = 31 * result + resolution.hashCode()
        result = 31 * result + frameData.contentHashCode()
        result = 31 * result + metadata.hashCode()
        return result
    }
}

data class ConfigurationResult(
    val success: Boolean,
    val message: String? = null
)

data class DeviceDiscoveryPayload(
    val agentId: String,
    val devices: List<UsbDeviceInfo>
)
```

### 3. Exception Types

```kotlin
class UsbException(message: String, cause: Throwable? = null) : Exception(message, cause)

class FrameProcessingException(message: String, cause: Throwable? = null) : Exception(message, cause)
```

## UVC Protocol Integration

### 1. UVC Standard Implementation

The USB Video Class (UVC) specification defines how video streaming devices should communicate over USB. The implementation should handle:

1. **Device Enumeration**: Detecting UVC-compliant devices
2. **Descriptors Parsing**: Reading UVC-specific descriptors for capabilities
3. **Control Interfaces**: Setting camera parameters like exposure, focus, etc.
4. **Streaming Interfaces**: Managing video streams

### 2. Key UVC Features

```kotlin
class UvcProtocolHandler(private val deviceHandle: Long, private val usbLibrary: UsbLibrary) {
    // Get camera terminal controls (zoom, focus, etc.)
    fun getCameraControls(): CameraControls {
        // Implementation would read UVC camera terminal descriptor
        // and return available controls
        return CameraControls()
    }
    
    // Get processing unit controls (brightness, contrast, etc.)
    fun getProcessingControls(): ProcessingControls {
        // Implementation would read UVC processing unit descriptor
        // and return available controls
        return ProcessingControls()
    }
    
    // Get supported video formats
    fun getVideoFormats(): List<VideoFormat> {
        // Implementation would parse format descriptors
        return emptyList()
    }
    
    // Set a camera control value
    fun setCameraControl(controlId: Int, value: Int): Boolean {
        // Implementation would send the appropriate UVC control request
        return false
    }
    
    // Get a camera control value
    fun getCameraControl(controlId: Int): Int {
        // Implementation would send the appropriate UVC control request
        return 0
    }
    
    // Negotiate video stream parameters
    fun negotiateVideoStream(format: VideoFormat): Boolean {
        // Implementation would:
        // 1. Select the video format
        // 2. Commit the interface
        // 3. Configure endpoints
        return false
    }
    
    // Start video streaming
    fun startStreaming(): Boolean {
        // Implementation would send UVC_VS_COMMIT_CONTROL
        return false
    }
    
    // Stop video streaming
    fun stopStreaming(): Boolean {
        // Implementation would clear UVC_VS_COMMIT_CONTROL
        return false
    }
}

data class CameraControls(
    val supportsZoom: Boolean = false,
    val supportsFocus: Boolean = false,
    val supportsPan: Boolean = false,
    val supportsTilt: Boolean = false
)

data class ProcessingControls(
    val supportsBrightness: Boolean = false,
    val supportsContrast: Boolean = false,
    val supportsSaturation: Boolean = false,
    val supportsSharpness: Boolean = false
)

data class VideoFormat(
    val formatIndex: Int,
    val formatType: String, // "MJPEG", "UNCOMPRESSED", "H264", etc.
    val frameDescriptors: List<FrameDescriptor>
)

data class FrameDescriptor(
    val frameIndex: Int,
    val width: Int,
    val height: Int,
    val defaultFrameInterval: Int,
    val frameIntervals: List<Int>
)
```

## Implementation Guidelines

### 1. USB Communication Best Practices

1. **Error Handling**: Handle USB errors gracefully with appropriate retries
2. **Resource Management**: Properly acquire and release device resources
3. **Thread Safety**: Ensure USB communications are thread-safe
4. **Timeout Handling**: Implement appropriate timeouts for USB operations
5. **Permissions**: Consider USB permission requirements on different platforms

### 2. Frame Processing Considerations

1. **Performance**: Optimize for low-latency frame processing
2. **Memory Management**: Implement efficient buffer management to avoid GC pressure
3. **Format Support**: Handle common UVC formats (MJPEG, YUV, H.264)
4. **Error Resilience**: Recover from corrupted frames and streaming errors
5. **Metrics Collection**: Track frame rates, latency, and error rates

### 3. Platform-Specific Considerations

1. **Linux**: Use libusb or similar library for direct USB access
2. **Windows**: Consider WinUSB or LibUSB-Win32
3. **macOS**: Use IOKit for USB device access
4. **Android**: Use Android USB Host API

## Testing Strategy

### 1. Unit Tests

1. Test device detection logic with mock USB library
2. Test frame processing algorithms with sample frames
3. Test UVC protocol handling with controlled inputs

### 2. Integration Tests

1. Test end-to-end frame capture pipeline with real devices
2. Test error recovery mechanisms with simulated failures
3. Test performance under sustained operation

### 3. Compliance Tests

1. Verify UVC specification compliance
2. Test with a variety of UVC camera models
3. Verify proper resource cleanup

## Next Steps

After implementing the Camera Integration Agent:

1. Develop a simple front-end to visualize camera outputs
2. Integrate with Code Generation Agent to generate camera-specific APIs
3. Implement advanced frame processing capabilities
4. Add support for camera-specific features beyond the UVC standard