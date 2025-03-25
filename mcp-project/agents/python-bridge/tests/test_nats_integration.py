"""
Integration tests for the NATS client and agent integration.

These tests require a running NATS server.
"""

import asyncio
import json
import os
import pytest
import uuid
from typing import Dict, Any

from python_bridge.nats_client import NatsClient


# Skip all tests if NATS_SERVER_URL environment variable is not set
pytestmark = pytest.mark.skipif(
    not os.environ.get("NATS_SERVER_URL"), 
    reason="NATS_SERVER_URL environment variable not set"
)

# Use environment variable or default
NATS_SERVER_URL = os.environ.get("NATS_SERVER_URL", "nats://localhost:4222")


@pytest.fixture
async def nats_client():
    """Fixture to provide a NATS client."""
    client = NatsClient(NATS_SERVER_URL)
    connected = await client.connect()
    assert connected, "Failed to connect to NATS server"
    yield client
    await client.close()


@pytest.mark.asyncio
async def test_nats_publish_subscribe(nats_client):
    """Test publishing and subscribing to NATS topics."""
    # Generate a unique topic for this test
    test_topic = f"test.{uuid.uuid4()}"
    test_message = {"key": "value", "id": uuid.uuid4().hex}
    received_messages = []
    
    # Define a message handler
    async def message_handler(msg):
        """Handle incoming message."""
        data = json.loads(msg.data.decode())
        received_messages.append(data)
    
    # Subscribe to the test topic
    await nats_client.subscribe(test_topic, message_handler)
    
    # Publish a message
    published = await nats_client.publish(test_topic, test_message)
    assert published, "Failed to publish message"
    
    # Wait for the message to be processed
    for _ in range(5):  # Try up to 5 times with 100ms delay
        await asyncio.sleep(0.1)
        if received_messages:
            break
    
    # Verify the message was received
    assert len(received_messages) == 1, "Message was not received"
    assert received_messages[0] == test_message, "Received message does not match sent message"


@pytest.mark.asyncio
async def test_nats_queue_subscription(nats_client):
    """Test queue group subscriptions."""
    # Generate a unique topic and queue for this test
    test_topic = f"test.{uuid.uuid4()}"
    test_queue = f"queue.{uuid.uuid4()}"
    test_message = {"key": "value", "id": uuid.uuid4().hex}
    received_counts = {
        "subscriber1": 0,
        "subscriber2": 0
    }
    
    # Define message handlers for each subscriber
    async def message_handler1(msg):
        """Handle incoming message for subscriber 1."""
        received_counts["subscriber1"] += 1
    
    async def message_handler2(msg):
        """Handle incoming message for subscriber 2."""
        received_counts["subscriber2"] += 1
    
    # Subscribe both handlers to the same topic with the same queue group
    await nats_client.subscribe(test_topic, message_handler1, queue=test_queue)
    await nats_client.subscribe(test_topic, message_handler2, queue=test_queue)
    
    # Publish multiple messages
    for _ in range(10):
        await nats_client.publish(test_topic, test_message)
    
    # Wait for the messages to be processed
    await asyncio.sleep(0.5)
    
    # Verify that messages were distributed between subscribers
    total_received = received_counts["subscriber1"] + received_counts["subscriber2"]
    assert total_received == 10, f"Expected 10 messages, got {total_received}"
    
    # Queue subscription should distribute messages, so neither subscriber should have 0
    assert received_counts["subscriber1"] > 0, "Subscriber 1 didn't receive any messages"
    assert received_counts["subscriber2"] > 0, "Subscriber 2 didn't receive any messages"


@pytest.mark.asyncio
async def test_nats_reconnection(monkeypatch, nats_client):
    """Test NATS client reconnection logic."""
    # Mock the client's connect method to simulate connection loss
    original_connect = nats_client.client.connect
    connect_called = 0
    
    async def mock_connect(*args, **kwargs):
        """Mock implementation that fails on first attempt."""
        nonlocal connect_called
        connect_called += 1
        if connect_called == 1:
            raise Exception("Simulated connection failure")
        else:
            return await original_connect(*args, **kwargs)
    
    # Apply the mock
    monkeypatch.setattr(nats_client.client, "connect", mock_connect)
    
    # Test reconnection
    nats_client._connected = False
    reconnected = await nats_client.connect()
    
    # Should have reconnected after the simulated failure
    assert reconnected, "Failed to reconnect after simulated failure"
    assert connect_called == 2, "Expected 2 connection attempts"


@pytest.mark.asyncio
async def test_nats_error_handling(nats_client, monkeypatch):
    """Test NATS client error handling."""
    # Test publish when not connected
    nats_client._connected = False
    published = await nats_client.publish("test.topic", {"key": "value"})
    assert not published, "Should not publish when not connected"
    
    # Test subscribe when not connected
    subscribed = await nats_client.subscribe("test.topic", lambda msg: None)
    assert not subscribed, "Should not subscribe when not connected"
    
    # Reconnect for the next tests
    nats_client._connected = True
    
    # Mock publishing to cause an error
    async def mock_publish(*args, **kwargs):
        """Mock implementation that raises an exception."""
        raise Exception("Simulated publishing error")
    
    monkeypatch.setattr(nats_client.client, "publish", mock_publish)
    published = await nats_client.publish("test.topic", {"key": "value"})
    assert not published, "Should handle publishing errors gracefully"