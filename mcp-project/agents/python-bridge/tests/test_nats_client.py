"""
Tests for the NATS client wrapper.
"""

import asyncio
from unittest import mock

import pytest
from nats.aio.client import Client as NATS
from nats.aio.msg import Msg

from python_bridge.nats_client import NatsClient


@pytest.fixture
def mock_nats():
    """Fixture for mocking the NATS client."""
    with mock.patch('python_bridge.nats_client.NATS') as mock_nats:
        # Mock the client instance
        mock_client = mock.MagicMock()
        mock_nats.return_value = mock_client
        yield mock_client


@pytest.mark.asyncio
async def test_connect_success(mock_nats):
    """Test successful connection to NATS server."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    
    # Test
    result = await client.connect()
    
    # Verify
    assert result is True
    assert client._connected is True
    mock_nats.connect.assert_called_once_with(
        "nats://localhost:4222",
        reconnected_cb=client._on_reconnected,
        disconnected_cb=client._on_disconnected,
        error_cb=client._on_error,
        closed_cb=client._on_closed,
        max_reconnect_attempts=10
    )


@pytest.mark.asyncio
async def test_connect_failure(mock_nats):
    """Test failed connection to NATS server."""
    # Set up
    client = NatsClient("nats://localhost:4222", reconnect_attempts=2)
    mock_nats.connect.side_effect = Exception("Connection failed")
    
    # Test
    result = await client.connect()
    
    # Verify
    assert result is False
    assert client._connected is False
    assert mock_nats.connect.call_count == 2


@pytest.mark.asyncio
async def test_publish_success(mock_nats):
    """Test successful message publishing."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = True
    
    # Test
    result = await client.publish("test.topic", {"key": "value"})
    
    # Verify
    assert result is True
    mock_nats.publish.assert_called_once()
    args, _ = mock_nats.publish.call_args
    assert args[0] == "test.topic"
    assert b'"key": "value"' in args[1]


@pytest.mark.asyncio
async def test_publish_not_connected(mock_nats):
    """Test publishing when not connected."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = False
    
    # Test
    result = await client.publish("test.topic", {"key": "value"})
    
    # Verify
    assert result is False
    mock_nats.publish.assert_not_called()


@pytest.mark.asyncio
async def test_subscribe_success(mock_nats):
    """Test successful subscription."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = True
    mock_subscription = mock.MagicMock()
    mock_nats.subscribe.return_value = mock_subscription
    callback = mock.AsyncMock()
    
    # Test
    result = await client.subscribe("test.topic", callback)
    
    # Verify
    assert result is True
    mock_nats.subscribe.assert_called_once_with(
        "test.topic", cb=callback, queue=None
    )
    assert "test.topic" in client._subscriptions
    assert client._subscriptions["test.topic"] == mock_subscription


@pytest.mark.asyncio
async def test_subscribe_with_queue(mock_nats):
    """Test subscription with queue group."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = True
    mock_subscription = mock.MagicMock()
    mock_nats.subscribe.return_value = mock_subscription
    callback = mock.AsyncMock()
    
    # Test
    result = await client.subscribe("test.topic", callback, queue="workers")
    
    # Verify
    assert result is True
    mock_nats.subscribe.assert_called_once_with(
        "test.topic", cb=callback, queue="workers"
    )


@pytest.mark.asyncio
async def test_subscribe_not_connected(mock_nats):
    """Test subscribing when not connected."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = False
    callback = mock.AsyncMock()
    
    # Test
    result = await client.subscribe("test.topic", callback)
    
    # Verify
    assert result is False
    mock_nats.subscribe.assert_not_called()


@pytest.mark.asyncio
async def test_unsubscribe_success(mock_nats):
    """Test successful unsubscription."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = True
    mock_subscription = mock.MagicMock()
    client._subscriptions["test.topic"] = mock_subscription
    
    # Test
    result = await client.unsubscribe("test.topic")
    
    # Verify
    assert result is True
    mock_subscription.unsubscribe.assert_called_once()
    assert "test.topic" not in client._subscriptions


@pytest.mark.asyncio
async def test_unsubscribe_not_subscribed(mock_nats):
    """Test unsubscribing from a topic not subscribed to."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    
    # Test
    result = await client.unsubscribe("test.topic")
    
    # Verify
    assert result is False


@pytest.mark.asyncio
async def test_close(mock_nats):
    """Test closing the connection."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    client._connected = True
    client._subscriptions = {"test.topic": mock.MagicMock()}
    
    # Test
    await client.close()
    
    # Verify
    mock_nats.close.assert_called_once()
    assert client._connected is False
    assert client._subscriptions == {}


def test_reconnection_callbacks():
    """Test reconnection callbacks."""
    # Set up
    client = NatsClient("nats://localhost:4222")
    
    # Test reconnected callback
    client._connected = False
    client._on_reconnected()
    assert client._connected is True
    
    # Test disconnected callback
    client._connected = True
    client._on_disconnected()
    assert client._connected is False
    
    # Test closed callback
    client._connected = True
    client._subscriptions = {"test.topic": mock.MagicMock()}
    client._on_closed()
    assert client._connected is False
    assert client._subscriptions == {}