package com.example.mcp

import com.example.mcp.messaging.NatsMessage
import io.nats.client.Connection
import io.nats.client.Dispatcher
import io.nats.client.Message
import io.nats.client.MessageHandler
import io.nats.client.Nats
import io.nats.client.Options
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.nio.charset.StandardCharsets
import java.time.Duration

/**
 * Manages NATS connections and provides utilities for publishing and subscribing to topics.
 * This class centralizes NATS messaging operations and provides a higher-level API for
 * handling messages with Kotlin serialization support.
 */
class NatsConnectionManager {
    private val logger = LoggerFactory.getLogger(NatsConnectionManager::class.java)
    private var connection: Connection? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    // JSON serializer with pretty printing and lenient options
    private val json = Json {
        prettyPrint = true
        isLenient = true
        ignoreUnknownKeys = true
    }
    
    /**
     * Connect to the NATS server with the specified configuration.
     *
     * @param serverUrl The URL of the NATS server
     * @param connectionTimeoutMs Connection timeout in milliseconds
     * @param reconnectWaitMs Wait time between reconnection attempts
     * @param maxReconnects Maximum number of reconnection attempts (-1 for unlimited)
     * @return The established NATS connection
     */
    fun connect(
        serverUrl: String = "nats://localhost:4222",
        connectionTimeoutMs: Long = 5000,
        reconnectWaitMs: Long = 1000,
        maxReconnects: Int = -1
    ): Connection {
        logger.info("Connecting to NATS server at $serverUrl")
        
        val options = Options.Builder()
            .server(serverUrl)
            .connectionTimeout(Duration.ofMillis(connectionTimeoutMs))
            .maxReconnects(maxReconnects)
            .reconnectWait(Duration.ofMillis(reconnectWaitMs))
            .build()
        
        return Nats.connect(options).also {
            connection = it
            logger.info("Connected to NATS server successfully")
        }
    }
    
    /**
     * Get the current NATS connection or throw an exception if not connected.
     *
     * @return The current NATS connection
     * @throws IllegalStateException if the connection has not been established
     */
    fun getConnection(): Connection {
        return connection ?: throw IllegalStateException("NATS connection not established. Call connect() first.")
    }
    
    /**
     * Close the NATS connection.
     */
    fun close() {
        connection?.let {
            logger.info("Closing NATS connection")
            it.close()
            connection = null
        }
    }
    
    /**
     * Check if connected to NATS server.
     *
     * @return True if connected, false otherwise
     */
    fun isConnected(): Boolean {
        return connection?.status == Connection.Status.CONNECTED
    }
    
    /**
     * Publish a message to a topic.
     *
     * @param topic The topic to publish to
     * @param message The message object to serialize and publish
     * @throws IllegalStateException if the connection has not been established
     */
    inline fun <reified T : NatsMessage> publish(topic: String, message: T) {
        val jsonString = json.encodeToString(message)
        getConnection().publish(topic, jsonString.toByteArray(StandardCharsets.UTF_8))
        logger.debug("Published message to topic: $topic")
    }
    
    /**
     * Subscribe to a topic with a handler for processing messages.
     *
     * @param topic The topic to subscribe to
     * @param handler The handler for processing received messages
     * @return The dispatcher for managing the subscription
     * @throws IllegalStateException if the connection has not been established
     */
    fun subscribe(topic: String, handler: MessageHandler): Dispatcher {
        val dispatcher = getConnection().createDispatcher(handler)
        dispatcher.subscribe(topic)
        logger.info("Subscribed to topic: $topic")
        return dispatcher
    }
    
    /**
     * Subscribe to a topic with a typed handler for processing deserialized messages.
     *
     * @param topic The topic to subscribe to
     * @param handler The handler for processing deserialized messages
     * @return The dispatcher for managing the subscription
     * @throws IllegalStateException if the connection has not been established
     */
    inline fun <reified T : NatsMessage> subscribeWithHandler(
        topic: String,
        crossinline handler: suspend (T) -> Unit
    ): Dispatcher {
        return subscribe(topic) { message ->
            scope.launch {
                try {
                    val messageStr = String(message.data, StandardCharsets.UTF_8)
                    val typedMessage = json.decodeFromString<T>(messageStr)
                    handler(typedMessage)
                } catch (e: Exception) {
                    logger.error("Error processing message from topic $topic", e)
                }
            }
        }
    }
    
    /**
     * Request-reply pattern implementation.
     *
     * @param topic The topic to send the request to
     * @param message The message object to serialize and send
     * @param timeoutMs The timeout in milliseconds
     * @return The response message
     * @throws IllegalStateException if the connection has not been established
     * @throws Exception if the request times out
     */
    inline fun <reified T : NatsMessage, reified R> requestReply(
        topic: String,
        message: T,
        timeoutMs: Long = 5000
    ): R {
        val jsonString = json.encodeToString(message)
        val response = getConnection().request(
            topic,
            jsonString.toByteArray(StandardCharsets.UTF_8),
            Duration.ofMillis(timeoutMs)
        )
        
        val responseStr = String(response.data, StandardCharsets.UTF_8)
        return json.decodeFromString<R>(responseStr)
    }
    
    /**
     * Standard NATS topics used in the MCP system.
     */
    object Topics {
        private const val PREFIX = "mcp"
        
        // Agent-related topics
        const val AGENT_REGISTER = "$PREFIX.agent.register"
        fun agentTask(agentId: String) = "$PREFIX.agent.$agentId.task"
        fun agentResult(agentId: String) = "$PREFIX.agent.$agentId.result"
        fun agentStatus(agentId: String) = "$PREFIX.agent.$agentId.status"
        fun agentHeartbeat(agentId: String) = "$PREFIX.agent.$agentId.heartbeat"
        
        // Orchestrator-related topics
        const val TASK_SUBMIT = "$PREFIX.orchestrator.task.submit"
        const val SYSTEM_EVENT = "$PREFIX.orchestrator.system.event"
        const val ORCHESTRATOR_HEALTH = "$PREFIX.orchestrator.health"
        
        // Wildcards for subscription
        const val ALL_AGENT_TASKS = "$PREFIX.agent.*.task"
        const val ALL_AGENT_RESULTS = "$PREFIX.agent.*.result"
        const val ALL_AGENT_STATUSES = "$PREFIX.agent.*.status"
        const val ALL_AGENT_HEARTBEATS = "$PREFIX.agent.*.heartbeat"
    }
}