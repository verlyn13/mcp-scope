"""
NATS Client Wrapper for Python Bridge Agent

This module provides a wrapper around the NATS client with enhanced
connection handling, reconnection logic, and error handling.
"""

import asyncio
import json
from typing import Any, Callable, Dict, Optional

from loguru import logger
from nats.aio.client import Client as NATS
from nats.aio.msg import Msg


class NatsClient:
    """Wrapper for NATS client with reliable connection handling."""
    
    def __init__(self, 
                 server_url: str, 
                 reconnect_attempts: int = 10,
                 reconnect_timeout: float = 1.0,
                 max_reconnect_timeout: float = 15.0):
        """
        Initialize the NATS client wrapper.
        
        Args:
            server_url: NATS server URL
            reconnect_attempts: Number of reconnection attempts
            reconnect_timeout: Initial timeout between reconnection attempts
            max_reconnect_timeout: Maximum timeout between reconnection attempts
        """
        self.server_url = server_url
        self.reconnect_attempts = reconnect_attempts
        self.reconnect_timeout = reconnect_timeout
        self.max_reconnect_timeout = max_reconnect_timeout
        self.client = NATS()
        self._connected = False
        self._subscriptions = {}
        
    async def connect(self) -> bool:
        """
        Connect to NATS with retry logic.
        
        Returns:
            True if connection was successful, False otherwise
        """
        attempt = 0
        backoff_time = self.reconnect_timeout
        
        while attempt < self.reconnect_attempts:
            try:
                # Configure client with handlers for connection events
                await self.client.connect(
                    self.server_url,
                    reconnected_cb=self._on_reconnected,
                    disconnected_cb=self._on_disconnected,
                    error_cb=self._on_error,
                    closed_cb=self._on_closed,
                    max_reconnect_attempts=self.reconnect_attempts,
                )
                self._connected = True
                logger.info(f"Connected to NATS server at {self.server_url}")
                return True
            except Exception as e:
                attempt += 1
                logger.warning(f"Connection attempt {attempt} failed: {str(e)}")
                
                if attempt < self.reconnect_attempts:
                    logger.info(f"Retrying in {backoff_time} seconds...")
                    await asyncio.sleep(backoff_time)
                    backoff_time = min(backoff_time * 1.5, self.max_reconnect_timeout)
                
        logger.error(f"Failed to connect to NATS after {self.reconnect_attempts} attempts")
        return False
    
    async def publish(self, topic: str, data: Dict[str, Any]) -> bool:
        """
        Publish a message to a NATS topic.
        
        Args:
            topic: NATS topic to publish to
            data: Data to publish (will be serialized to JSON)
            
        Returns:
            True if message was published successfully, False otherwise
        """
        if not self._connected:
            logger.error("Cannot publish: not connected to NATS")
            return False
            
        try:
            message = json.dumps(data).encode()
            await self.client.publish(topic, message)
            logger.debug(f"Published to {topic}: {data}")
            return True
        except Exception as e:
            logger.error(f"Failed to publish to {topic}: {str(e)}")
            return False
            
    async def subscribe(self, topic: str, callback: Callable[[Msg], None], queue: str = None) -> bool:
        """
        Subscribe to a NATS topic with the given callback.
        
        Args:
            topic: NATS topic to subscribe to
            callback: Callback function to invoke when a message is received
            queue: Optional queue group name for load balancing
            
        Returns:
            True if subscription was successful, False otherwise
        """
        if not self._connected:
            logger.error("Cannot subscribe: not connected to NATS")
            return False
            
        try:
            sub = await self.client.subscribe(topic, cb=callback, queue=queue)
            self._subscriptions[topic] = sub
            logger.info(f"Subscribed to {topic}" + (f" with queue {queue}" if queue else ""))
            return True
        except Exception as e:
            logger.error(f"Failed to subscribe to {topic}: {str(e)}")
            return False
    
    async def unsubscribe(self, topic: str) -> bool:
        """
        Unsubscribe from a NATS topic.
        
        Args:
            topic: NATS topic to unsubscribe from
            
        Returns:
            True if unsubscription was successful, False otherwise
        """
        if topic not in self._subscriptions:
            logger.warning(f"Cannot unsubscribe: not subscribed to {topic}")
            return False
            
        try:
            await self._subscriptions[topic].unsubscribe()
            del self._subscriptions[topic]
            logger.info(f"Unsubscribed from {topic}")
            return True
        except Exception as e:
            logger.error(f"Failed to unsubscribe from {topic}: {str(e)}")
            return False
    
    async def close(self) -> None:
        """Close the NATS connection."""
        if self._connected:
            await self.client.close()
            self._connected = False
            self._subscriptions = {}
            logger.info("Closed NATS connection")
    
    def _on_reconnected(self) -> None:
        """Callback for when the client reconnects to a server."""
        logger.info(f"Reconnected to NATS server")
        self._connected = True
    
    def _on_disconnected(self) -> None:
        """Callback for when the client disconnects from a server."""
        logger.warning("Disconnected from NATS server")
        self._connected = False
    
    def _on_error(self, e: Exception) -> None:
        """Callback for when there is an error in the client."""
        logger.error(f"NATS client error: {str(e)}")
    
    def _on_closed(self) -> None:
        """Callback for when the client connection is closed."""
        logger.info("NATS connection closed")
        self._connected = False
        self._subscriptions = {}