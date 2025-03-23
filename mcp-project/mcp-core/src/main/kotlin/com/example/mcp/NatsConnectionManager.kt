package com.example.mcp

import io.nats.client.Connection
import io.nats.client.Nats
import io.nats.client.Options
import org.slf4j.LoggerFactory
import java.time.Duration

class NatsConnectionManager {
    private val logger = LoggerFactory.getLogger(NatsConnectionManager::class.java)
    private var connection: Connection? = null
    
    fun connect(serverUrl: String = "nats://localhost:4222"): Connection {
        logger.info("Connecting to NATS server at $serverUrl")
        
        val options = Options.Builder()
            .server(serverUrl)
            .connectionTimeout(Duration.ofSeconds(5))
            .maxReconnects(-1) // Unlimited reconnects
            .reconnectWait(Duration.ofSeconds(1))
            .build()
        
        return Nats.connect(options).also {
            connection = it
            logger.info("Connected to NATS server successfully")
        }
    }
    
    fun getConnection(): Connection {
        return connection ?: throw IllegalStateException("NATS connection not established. Call connect() first.")
    }
    
    fun close() {
        connection?.let {
            logger.info("Closing NATS connection")
            it.close()
            connection = null
        }
    }
}