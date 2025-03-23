package com.example.agents.camera

import com.example.agents.camera.model.MockUsbDevice
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.util.UUID
import kotlin.random.Random

/**
 * Simulates USB device management for development and testing
 */
class MockUsbManager {
    private val logger = LoggerFactory.getLogger(MockUsbManager::class.java)
    private val scope = CoroutineScope(Dispatchers.Default)
    
    // Available devices (mutable to simulate connect/disconnect)
    private val _devices = MockUsbDevice.SAMPLE_DEVICES.toMutableList()
    
    // Event flow for device connection/disconnection events
    private val _deviceEvents = MutableSharedFlow<UsbDeviceEvent>()
    val deviceEvents: SharedFlow<UsbDeviceEvent> = _deviceEvents
    
    // Start the manager and simulate random events
    fun start() {
        logger.info("Starting Mock USB Manager")
        
        // Simulate occasional device events
        scope.launch {
            while (true) {
                delay(Random.nextLong(10000, 30000)) // Random delay between events
                
                when (Random.nextInt(3)) {
                    0 -> simulateDeviceConnected()
                    1 -> simulateDeviceDisconnected()
                    // 2 - do nothing (no event)
                }
            }
        }
    }
    
    // Get currently connected devices
    fun getConnectedDevices(): List<MockUsbDevice> {
        return _devices.filter { it.isConnected }.toList()
    }
    
    // Get a specific device by ID
    fun getDeviceById(deviceId: String): MockUsbDevice? {
        return _devices.find { it.deviceId == deviceId }
    }
    
    // Simulate a new device connection
    private suspend fun simulateDeviceConnected() {
        val disconnectedDevices = _devices.filter { !it.isConnected }
        
        if (disconnectedDevices.isNotEmpty()) {
            // Reconnect a previously disconnected device
            val deviceToConnect = disconnectedDevices.random()
            val index = _devices.indexOfFirst { it.deviceId == deviceToConnect.deviceId }
            
            if (index >= 0) {
                _devices[index] = deviceToConnect.copy(isConnected = true)
                logger.info("Device reconnected: ${deviceToConnect.deviceId}")
                _deviceEvents.emit(UsbDeviceEvent.DeviceConnected(_devices[index]))
            }
        } else {
            // Create a completely new device
            val newDevice = MockUsbDevice(
                deviceId = "mock-camera-${UUID.randomUUID().toString().substring(0, 8)}",
                vendorId = 0x046d,
                productId = 0x082d + Random.nextInt(0, 100),
                manufacturer = "Mock Manufacturer",
                product = "UVC Camera ${Random.nextInt(1000, 9999)}",
                serialNumber = "SN${Random.nextInt(10000, 99999)}",
                isConnected = true
            )
            
            _devices.add(newDevice)
            logger.info("New device connected: ${newDevice.deviceId}")
            _deviceEvents.emit(UsbDeviceEvent.DeviceConnected(newDevice))
        }
    }
    
    // Simulate a device disconnection
    private suspend fun simulateDeviceDisconnected() {
        val connectedDevices = _devices.filter { it.isConnected }
        
        if (connectedDevices.isNotEmpty()) {
            val deviceToDisconnect = connectedDevices.random()
            val index = _devices.indexOfFirst { it.deviceId == deviceToDisconnect.deviceId }
            
            if (index >= 0) {
                _devices[index] = deviceToDisconnect.copy(isConnected = false)
                logger.info("Device disconnected: ${deviceToDisconnect.deviceId}")
                _deviceEvents.emit(UsbDeviceEvent.DeviceDisconnected(_devices[index].deviceId))
            }
        }
    }
}

// Events for USB device connections/disconnections
sealed class UsbDeviceEvent {
    data class DeviceConnected(val device: MockUsbDevice) : UsbDeviceEvent()
    data class DeviceDisconnected(val deviceId: String) : UsbDeviceEvent()
}