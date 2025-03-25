"""
UVC Camera Code Templates

This module provides templates and specialized knowledge for UVC camera
integration in Android/Kotlin.
"""

from typing import Dict, List, Optional


class UvcCodeTemplates:
    """Collection of templates for UVC camera integration code."""

    @staticmethod
    def get_camera_interface_template() -> str:
        """Get the template for a UVC camera interface."""
        return """
package {package}

/**
 * Interface for UVC camera operations.
 * Provides a common interface for interacting with UVC cameras.
 */
interface UvcCamera {
    /**
     * Initialize the camera and prepare it for operation.
     *
     * @param deviceId The USB device ID of the camera
     * @return True if initialization is successful, false otherwise
     */
    fun initialize(deviceId: String): Boolean
    
    /**
     * Start the camera stream.
     *
     * @return True if the camera stream started successfully, false otherwise
     */
    fun startPreview(): Boolean
    
    /**
     * Stop the camera stream.
     */
    fun stopPreview()
    
    /**
     * Capture a still image from the camera.
     *
     * @return ByteArray containing the image data, or null if capture failed
     */
    fun captureImage(): ByteArray?
    
    /**
     * Set the resolution for the camera.
     *
     * @param width The desired width in pixels
     * @param height The desired height in pixels
     * @return True if the resolution was set successfully, false otherwise
     */
    fun setResolution(width: Int, height: Int): Boolean
    
    /**
     * Get the current camera status.
     *
     * @return A string representing the current status of the camera
     */
    fun getStatus(): String
    
    /**
     * Release resources and clean up.
     */
    fun release()
}
"""

    @staticmethod
    def get_camera_impl_template() -> str:
        """Get the template for UVC camera implementation."""
        return """
package {package}

import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbManager
import android.util.Log
import java.nio.ByteBuffer
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Implementation of UVC camera interface using USB device connections.
 *
 * @property usbManager Android USB manager for device communication
 */
class UvcCameraImpl(
    private val usbManager: UsbManager
) : UvcCamera {
    private companion object {
        private const val TAG = "UvcCameraImpl"
        private const val DEFAULT_FRAME_WIDTH = 640
        private const val DEFAULT_FRAME_HEIGHT = 480
    }
    
    private var usbDevice: UsbDevice? = null
    private var usbConnection: UsbDeviceConnection? = null
    private var frameWidth: Int = DEFAULT_FRAME_WIDTH
    private var frameHeight: Int = DEFAULT_FRAME_HEIGHT
    private val isInitialized = AtomicBoolean(false)
    private val isStreaming = AtomicBoolean(false)
    
    override fun initialize(deviceId: String): Boolean {
        Log.d(TAG, "Initializing UVC camera with device ID: $deviceId")
        
        try {
            // Find the USB device by ID
            usbManager.deviceList.values.forEach { device ->
                if (device.deviceName == deviceId) {
                    usbDevice = device
                    return@forEach
                }
            }
            
            if (usbDevice == null) {
                Log.e(TAG, "Device not found: $deviceId")
                return false
            }
            
            // Request permission if needed
            if (!usbManager.hasPermission(usbDevice)) {
                Log.e(TAG, "No permission for device: $deviceId")
                return false
            }
            
            // Open connection to the device
            usbConnection = usbManager.openDevice(usbDevice)
            if (usbConnection == null) {
                Log.e(TAG, "Failed to open connection to device: $deviceId")
                return false
            }
            
            // Initialize UVC protocol communication
            if (!initializeUvcProtocol()) {
                Log.e(TAG, "Failed to initialize UVC protocol")
                return false
            }
            
            isInitialized.set(true)
            Log.d(TAG, "Camera initialization successful")
            return true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing camera: ${e.message}", e)
            release()
            return false
        }
    }
    
    override fun startPreview(): Boolean {
        if (!isInitialized.get()) {
            Log.e(TAG, "Cannot start preview, camera not initialized")
            return false
        }
        
        if (isStreaming.get()) {
            Log.w(TAG, "Preview already started")
            return true
        }
        
        try {
            // Start the streaming protocol
            if (!startUvcStreaming()) {
                Log.e(TAG, "Failed to start UVC streaming")
                return false
            }
            
            isStreaming.set(true)
            Log.d(TAG, "Preview started successfully")
            return true
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting preview: ${e.message}", e)
            return false
        }
    }
    
    override fun stopPreview() {
        if (!isStreaming.get()) {
            Log.w(TAG, "Preview not started, nothing to stop")
            return
        }
        
        try {
            // Stop the streaming protocol
            stopUvcStreaming()
            isStreaming.set(false)
            Log.d(TAG, "Preview stopped successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping preview: ${e.message}", e)
        }
    }
    
    override fun captureImage(): ByteArray? {
        if (!isInitialized.get()) {
            Log.e(TAG, "Cannot capture image, camera not initialized")
            return null
        }
        
        try {
            // Capture frame from the UVC stream
            val frame = captureUvcFrame()
            return frame
            
        } catch (e: Exception) {
            Log.e(TAG, "Error capturing image: ${e.message}", e)
            return null
        }
    }
    
    override fun setResolution(width: Int, height: Int): Boolean {
        if (!isInitialized.get()) {
            Log.e(TAG, "Cannot set resolution, camera not initialized")
            return false
        }
        
        // Check if the resolution is supported
        if (!isSupportedResolution(width, height)) {
            Log.e(TAG, "Unsupported resolution: ${width}x${height}")
            return false
        }
        
        // Store new resolution
        frameWidth = width
        frameHeight = height
        
        // Apply resolution to the device
        return setUvcResolution(width, height)
    }
    
    override fun getStatus(): String {
        val status = StringBuilder()
        status.append("UVC Camera Status:\\n")
        status.append("- Initialized: ${isInitialized.get()}\\n")
        status.append("- Streaming: ${isStreaming.get()}\\n")
        status.append("- Resolution: ${frameWidth}x${frameHeight}\\n")
        
        if (usbDevice != null) {
            status.append("- Device: ${usbDevice?.deviceName}\\n")
            status.append("- Product: ${usbDevice?.productName}\\n")
        }
        
        return status.toString()
    }
    
    override fun release() {
        Log.d(TAG, "Releasing camera resources")
        
        if (isStreaming.get()) {
            stopPreview()
        }
        
        try {
            releaseUvcResources()
            
            usbConnection?.close()
            usbConnection = null
            usbDevice = null
            
            isInitialized.set(false)
            Log.d(TAG, "Camera resources released successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing camera resources: ${e.message}", e)
        }
    }
    
    // Internal helper methods
    
    private fun initializeUvcProtocol(): Boolean {
        // TODO: Implement actual UVC protocol initialization
        // This would involve setting up the control and streaming interfaces
        // and configuring the UVC device according to the USB Video Class specification
        
        // For implementation purposes, return true
        return true
    }
    
    private fun startUvcStreaming(): Boolean {
        // TODO: Implement actual UVC streaming start
        // This would involve setting up streaming parameters and
        // starting the isochronous transfer for video data
        
        // For implementation purposes, return true
        return true
    }
    
    private fun stopUvcStreaming() {
        // TODO: Implement actual UVC streaming stop
        // This would involve stopping the isochronous transfer
        // and resetting streaming parameters
    }
    
    private fun captureUvcFrame(): ByteArray {
        // TODO: Implement actual frame capture from UVC stream
        // This would involve grabbing the latest frame from the
        // stream and converting it to a ByteArray
        
        // For implementation purposes, return an empty ByteArray
        val frameSize = frameWidth * frameHeight * 3 // RGB format
        return ByteArray(frameSize)
    }
    
    private fun isSupportedResolution(width: Int, height: Int): Boolean {
        // TODO: Check if the resolution is supported by the device
        // This would involve querying the device capabilities
        
        // For implementation purposes, accept common resolutions
        val supportedResolutions = listOf(
            Pair(640, 480),
            Pair(1280, 720),
            Pair(1920, 1080)
        )
        
        return supportedResolutions.contains(Pair(width, height))
    }
    
    private fun setUvcResolution(width: Int, height: Int): Boolean {
        // TODO: Implement actual resolution setting in UVC protocol
        // This would involve sending control requests to the device
        
        // For implementation purposes, return true
        return true
    }
    
    private fun releaseUvcResources() {
        // TODO: Implement actual resource cleanup for UVC device
        // This would involve releasing any allocated resources
        // and resetting the device state
    }
}
"""

    @staticmethod
    def get_camera_manager_template() -> str:
        """Get the template for UVC camera manager."""
        return """
package {package}

import android.content.Context
import android.hardware.usb.UsbManager
import android.util.Log
import java.util.concurrent.ConcurrentHashMap

/**
 * Manager for UVC cameras.
 * Handles camera discovery, connection, and lifecycle management.
 *
 * @property context Android context
 */
class UvcCameraManager(
    private val context: Context
) {
    private companion object {
        private const val TAG = "UvcCameraManager"
    }
    
    private val usbManager: UsbManager by lazy {
        context.getSystemService(Context.USB_SERVICE) as UsbManager
    }
    
    private val cameras = ConcurrentHashMap<String, UvcCamera>()
    
    /**
     * Get a list of available UVC camera devices.
     *
     * @return List of device IDs for available UVC cameras
     */
    fun getAvailableCameras(): List<String> {
        val deviceList = usbManager.deviceList
        val uvcDevices = mutableListOf<String>()
        
        Log.d(TAG, "Found ${deviceList.size} USB devices")
        
        deviceList.values.forEach { device ->
            // Check if the device is a UVC camera
            // UVC devices typically have interface class 14 (Video)
            device.interfaceCount.let { count ->
                for (i in 0 until count) {
                    val intf = device.getInterface(i)
                    if (intf.interfaceClass == 14) { // Video class
                        uvcDevices.add(device.deviceName)
                        Log.d(TAG, "Found UVC device: ${device.deviceName}, Product: ${device.productName}")
                        break
                    }
                }
            }
        }
        
        return uvcDevices
    }
    
    /**
     * Open a UVC camera by device ID.
     *
     * @param deviceId The USB device ID of the camera
     * @return The UvcCamera instance if successful, null otherwise
     */
    fun openCamera(deviceId: String): UvcCamera? {
        // Check if camera is already open
        if (cameras.containsKey(deviceId)) {
            Log.d(TAG, "Camera already open: $deviceId")
            return cameras[deviceId]
        }
        
        Log.d(TAG, "Opening camera: $deviceId")
        
        val camera = UvcCameraImpl(usbManager)
        if (camera.initialize(deviceId)) {
            cameras[deviceId] = camera
            return camera
        }
        
        return null
    }
    
    /**
     * Close a UVC camera.
     *
     * @param deviceId The USB device ID of the camera to close
     */
    fun closeCamera(deviceId: String) {
        Log.d(TAG, "Closing camera: $deviceId")
        
        cameras[deviceId]?.let { camera ->
            camera.release()
            cameras.remove(deviceId)
        }
    }
    
    /**
     * Close all open cameras.
     */
    fun closeAllCameras() {
        Log.d(TAG, "Closing all cameras")
        
        cameras.keys().toList().forEach { deviceId ->
            closeCamera(deviceId)
        }
    }
}
"""

    @staticmethod
    def get_frame_processor_template() -> str:
        """Get the template for frame processor."""
        return """
package {package}

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.util.Log
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executor
import java.util.concurrent.Executors

/**
 * Processor for camera frames.
 * Handles frame conversion, processing, and analysis.
 */
class UvcFrameProcessor {
    private companion object {
        private const val TAG = "UvcFrameProcessor"
    }
    
    private val processingExecutor: Executor = Executors.newSingleThreadExecutor()
    private var frameListener: FrameListener? = null
    
    /**
     * Process a raw frame from the camera.
     *
     * @param frameData Raw frame data
     * @param width Frame width
     * @param height Frame height
     * @param format Frame format (e.g., ImageFormat.YUV_420_888)
     */
    fun processFrame(frameData: ByteArray, width: Int, height: Int, format: Int) {
        processingExecutor.execute {
            try {
                // Convert the frame to a bitmap for easier processing
                val bitmap = convertFrameToBitmap(frameData, width, height, format)
                
                // Apply any frame processing here
                val processedBitmap = applyFrameProcessing(bitmap)
                
                // Notify the listener
                frameListener?.onFrameProcessed(processedBitmap)
                
            } catch (e: Exception) {
                Log.e(TAG, "Error processing frame: ${e.message}", e)
            }
        }
    }
    
    /**
     * Set a listener for processed frames.
     *
     * @param listener The frame listener
     */
    fun setFrameListener(listener: FrameListener) {
        this.frameListener = listener
    }
    
    /**
     * Convert a raw frame to a bitmap.
     *
     * @param frameData Raw frame data
     * @param width Frame width
     * @param height Frame height
     * @param format Frame format
     * @return Bitmap representation of the frame
     */
    private fun convertFrameToBitmap(frameData: ByteArray, width: Int, height: Int, format: Int): Bitmap {
        // For YUV format (common in camera preview)
        if (format == ImageFormat.YUV_420_888 || format == ImageFormat.NV21) {
            val yuvImage = YuvImage(frameData, format, width, height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
            val jpegBytes = out.toByteArray()
            return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
        }
        
        // For RGB format
        else {
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            bitmap.copyPixelsFromBuffer(java.nio.ByteBuffer.wrap(frameData))
            return bitmap
        }
    }
    
    /**
     * Apply processing to a frame bitmap.
     *
     * @param bitmap Input bitmap
     * @return Processed bitmap
     */
    private fun applyFrameProcessing(bitmap: Bitmap): Bitmap {
        // TODO: Implement frame processing algorithms
        // This could include filters, object detection, etc.
        
        // For now, return the original bitmap
        return bitmap
    }
    
    /**
     * Interface for frame processing listeners.
     */
    interface FrameListener {
        /**
         * Called when a frame has been processed.
         *
         * @param processedFrame The processed frame as a bitmap
         */
        fun onFrameProcessed(processedFrame: Bitmap)
    }
}
"""


def get_template(template_type: str, package: str) -> str:
    """
    Get a specific template with the package filled in.
    
    Args:
        template_type: The type of template to get
        package: The package name to use in the template
        
    Returns:
        The template with the package filled in
    """
    if template_type == "interface":
        template = UvcCodeTemplates.get_camera_interface_template()
    elif template_type == "implementation":
        template = UvcCodeTemplates.get_camera_impl_template()
    elif template_type == "manager":
        template = UvcCodeTemplates.get_camera_manager_template()
    elif template_type == "processor":
        template = UvcCodeTemplates.get_frame_processor_template()
    else:
        raise ValueError(f"Unknown template type: {template_type}")
    
    return template.format(package=package)


def get_template_set(package: str) -> Dict[str, str]:
    """
    Get a complete set of templates for UVC camera implementation.
    
    Args:
        package: The package name to use in the templates
        
    Returns:
        Dictionary mapping filenames to template contents
    """
    return {
        "UvcCamera.kt": get_template("interface", package),
        "UvcCameraImpl.kt": get_template("implementation", package),
        "UvcCameraManager.kt": get_template("manager", package),
        "UvcFrameProcessor.kt": get_template("processor", package)
    }


def get_common_resolutions() -> List[Dict[str, int]]:
    """
    Get a list of common UVC camera resolutions.
    
    Returns:
        List of common resolutions as width/height dictionaries
    """
    return [
        {"width": 640, "height": 480},      # VGA
        {"width": 800, "height": 600},      # SVGA
        {"width": 1024, "height": 768},     # XGA
        {"width": 1280, "height": 720},     # HD 720p
        {"width": 1920, "height": 1080},    # Full HD 1080p
        {"width": 2560, "height": 1440},    # QHD
        {"width": 3840, "height": 2160}     # 4K UHD
    ]


def get_requirements_prompt(package: str, requirements: str) -> str:
    """
    Generate a prompt for the AI model based on requirements.
    
    Args:
        package: The target package name
        requirements: The requirements text
        
    Returns:
        A formatted prompt for the AI model
    """
    return f"""
# UVC Camera Code Generation

## Target Package
{package}

## Requirements
{requirements}

## Task
Generate a complete set of Kotlin files for implementing UVC camera integration in Android
according to the requirements above. 

Include these core components:
1. UVC camera interface
2. Implementation class for the interface
3. Camera manager for discovery and lifecycle
4. Frame processor for handling camera frames

The code should follow Android best practices and include proper error handling.
"""


def get_build_gradle_template() -> str:
    """
    Get a template for build.gradle file for UVC camera integration.
    
    Returns:
        Template string for build.gradle
    """
    return """
plugins {
    id 'com.android.library'
    id 'kotlin-android'
}

android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
    }
    
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation "androidx.core:core-ktx:1.10.1"
    implementation "androidx.appcompat:appcompat:1.6.1"
    implementation "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.1"
    
    // UVC camera libraries
    implementation "com.serenegiant:common:8.13.0"
    
    // Testing
    testImplementation "junit:junit:4.13.2"
    androidTestImplementation "androidx.test.ext:junit:1.1.5"
    androidTestImplementation "androidx.test.espresso:espresso-core:3.5.1"
}
"""