package com.example.mcp

import io.mockk.every
import io.mockk.justRun
import io.mockk.mockk
import io.mockk.mockkStatic
import io.mockk.verify
import io.nats.client.Connection
import io.nats.client.Nats
import io.nats.client.Options
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class NatsConnectionManagerTest {

    private lateinit var connectionManager: NatsConnectionManager
    private lateinit var mockConnection: Connection

    @BeforeEach
    fun setup() {
        // Create mock Connection object
        mockConnection = mockk<Connection>(relaxed = true)
        
        // Reset the connection manager for each test
        connectionManager = NatsConnectionManager()
    }

    @Test
    fun `connect should establish connection successfully`() {
        // Mock static Nats.connect method
        mockkStatic(Nats::class)
        every { Nats.connect(any<Options>()) } returns mockConnection
        
        // Call connect method
        val result = connectionManager.connect()
        
        // Verify connection is established
        assertNotNull(result)
        assertEquals(mockConnection, result)
    }

    @Test
    fun `connect should use default server URL when not specified`() {
        // Mock static Nats.connect method to capture options
        mockkStatic(Nats::class)
        every { 
            Nats.connect(capture(slot<Options>()))
        } answers { 
            // Verify options contain default URL
            val opts = slot<Options>().captured
            // We can't directly inspect the server URLs in Options as they're private
            // But we can verify the connection was made
            mockConnection
        }
        
        // Call connect with default URL
        connectionManager.connect()
        
        // Verify Nats.connect was called
        verify { Nats.connect(any<Options>()) }
    }

    @Test
    fun `connect should use custom server URL when specified`() {
        val customUrl = "nats://custom.server:4222"
        
        // Mock static Nats.connect method
        mockkStatic(Nats::class)
        every { Nats.connect(any<Options>()) } returns mockConnection
        
        // Call connect with custom URL
        connectionManager.connect(customUrl)
        
        // Verify Nats.connect was called (can't easily verify URL in options)
        verify { Nats.connect(any<Options>()) }
    }

    @Test
    fun `getConnection should return established connection`() {
        // Setup connection
        mockkStatic(Nats::class)
        every { Nats.connect(any<Options>()) } returns mockConnection
        connectionManager.connect()
        
        // Get connection
        val result = connectionManager.getConnection()
        
        // Verify correct connection returned
        assertEquals(mockConnection, result)
    }

    @Test
    fun `getConnection should throw exception when connection not established`() {
        // Verify exception is thrown when no connection exists
        assertThrows<IllegalStateException> {
            connectionManager.getConnection()
        }
    }

    @Test
    fun `close should close the connection properly`() {
        // Setup connection
        mockkStatic(Nats::class)
        every { Nats.connect(any<Options>()) } returns mockConnection
        justRun { mockConnection.close() }
        
        connectionManager.connect()
        
        // Close connection
        connectionManager.close()
        
        // Verify close was called on the connection
        verify { mockConnection.close() }
        
        // Verify getting connection after close throws exception
        assertThrows<IllegalStateException> {
            connectionManager.getConnection()
        }
    }
}