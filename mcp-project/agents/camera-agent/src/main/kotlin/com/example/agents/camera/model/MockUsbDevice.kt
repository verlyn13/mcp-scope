package com.example.agents.camera.model

import kotlinx.serialization.Serializable

/**
 * Represents a mock USB camera device for testing and development
 */
@Serializable
data class MockUsbDevice(
    val deviceId: String,
    val vendorId: Int,
    val productId: Int,
    val manufacturer: String,
    val product: String,
    val serialNumber: String,
    val isConnected: Boolean = true
) {
    companion object {
        // Predefined mock devices for testing
        val SAMPLE_DEVICES = listOf(
            MockUsbDevice(
                deviceId = "mock-camera-001",
                vendorId = 0x046d,
                productId = 0x082d,
                manufacturer = "Logitech",
                product = "HD Pro Webcam C920",
                serialNumber = "L0001"
            ),
            MockUsbDevice(
                deviceId = "mock-camera-002",
                vendorId = 0x1871,
                productId = 0x0142,
                manufacturer = "Aveo Technology Corp.",
                product = "UVC Camera",
                serialNumber = "A0001"
            ),
            MockUsbDevice(
                deviceId = "mock-camera-003",
                vendorId = 0x0c45,
                productId = 0x6366,
                manufacturer = "Microdia",
                product = "USB 2.0 Camera",
                serialNumber = "M0001"
            )
        )
    }
    
    // Simulate capturing a frame
    fun captureFrame(): ByteArray {
        // Return a mock frame (just some random data)
        return ByteArray(640 * 480 * 3) { (it % 255).toByte() }
    }
    
    // Get device information in a formatted string
    fun getDeviceInfo(): String {
        return """
            |Device ID: $deviceId
            |Vendor ID: 0x${vendorId.toString(16).padStart(4, '0')}
            |Product ID: 0x${productId.toString(16).padStart(4, '0')}
            |Manufacturer: $manufacturer
            |Product: $product
            |Serial Number: $serialNumber
            |Connection Status: ${if (isConnected) "Connected" else "Disconnected"}
        """.trimMargin()
    }
}