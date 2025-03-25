"""
Unit tests for the Python Bridge Agent
"""

import asyncio
import json
import pytest
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

from src.bridge.agent import PythonBridgeAgent


@pytest.fixture
def agent():
    """Fixture to create a test agent instance."""
    return PythonBridgeAgent(nats_server="nats://localhost:4222")


@pytest.mark.asyncio
async def test_initialize(agent):
    """Test agent initialization."""
    # Mock the NATS client
    with patch('src.bridge.agent.NATS') as mock_nats:
        # Configure the mock
        mock_client = AsyncMock()
        mock_nats.return_value = mock_client
        
        # Mock register_with_orchestrator
        agent.register_with_orchestrator = AsyncMock()
        
        # Call initialize
        result = await agent.initialize()
        
        # Assert results
        assert result is True
        assert agent.state == "READY"
        mock_client.connect.assert_called_once_with("nats://localhost:4222")
        mock_client.subscribe.assert_called()
        agent.register_with_orchestrator.assert_called_once()


@pytest.mark.asyncio
async def test_register_with_orchestrator(agent):
    """Test agent registration with orchestrator."""
    # Mock the NATS client
    agent.nats_client = AsyncMock()
    
    # Call register_with_orchestrator
    await agent.register_with_orchestrator()
    
    # Assert that publish was called with correct subject
    agent.nats_client.publish.assert_called_once()
    args = agent.nats_client.publish.call_args[0]
    assert args[0] == "mcp.agent.register"
    
    # Verify the registration message format
    registration_data = json.loads(args[1].decode())
    assert "messageId" in registration_data
    assert "timestamp" in registration_data
    assert "registration" in registration_data
    assert registration_data["registration"]["agentId"] == agent.agent_id
    assert registration_data["registration"]["agentType"] == "python-bridge"
    assert "capabilities" in registration_data["registration"]


@pytest.mark.asyncio
async def test_process_task(agent):
    """Test task processing."""
    # Setup task data
    task_id = str(uuid.uuid4())
    task = {
        "taskId": task_id,
        "taskType": "code_generation",
        "parameters": {
            "requirements": "Test requirements"
        }
    }
    
    # Process the task
    result = await agent.process_task(task)
    
    # Verify results
    assert "messageId" in result
    assert "timestamp" in result
    assert "result" in result
    assert result["result"]["status"] == "COMPLETED"
    assert result["result"]["taskId"] == task_id
    assert "Simulated result" in result["result"]["result"]
    assert agent.tasks_completed == 1


@pytest.mark.asyncio
async def test_task_handler(agent):
    """Test the NATS message handler for tasks."""
    # Mock the NATS client
    agent.nats_client = AsyncMock()
    
    # Mock process_task to return a result
    task_id = str(uuid.uuid4())
    mock_result = {
        "messageId": str(uuid.uuid4()),
        "timestamp": 123456789,
        "result": {
            "status": "COMPLETED",
            "result": "Test result",
            "taskId": task_id,
            "executionTimeMs": 100
        }
    }
    agent.process_task = AsyncMock(return_value=mock_result)
    
    # Create a mock message
    msg = MagicMock()
    msg.subject = f"mcp.agent.{agent.agent_id}.task"
    msg.data = json.dumps({
        "taskId": task_id,
        "taskType": "code_generation",
        "parameters": {}
    }).encode()
    
    # Call the task handler
    await agent.task_handler(msg)
    
    # Verify the handler called process_task
    agent.process_task.assert_called_once()
    
    # Verify the result was published
    agent.nats_client.publish.assert_called_once()
    args = agent.nats_client.publish.call_args[0]
    assert args[0] == f"mcp.agent.{agent.agent_id}.result"
    result_data = json.loads(args[1].decode())
    assert result_data == mock_result


@pytest.mark.asyncio
async def test_get_status(agent):
    """Test getting agent status."""
    # Set some state for the test
    agent.state = "READY"
    agent.tasks_completed = 5
    agent.tasks_failed = 2
    
    # Get status
    status = agent.get_status()
    
    # Verify status
    assert "messageId" in status
    assert "timestamp" in status
    assert "status" in status
    assert status["status"]["agent_id"] == agent.agent_id
    assert status["status"]["state"] == "READY"
    assert status["status"]["healthy"] is True
    assert status["status"]["tasks_completed"] == 5
    assert status["status"]["tasks_failed"] == 2


@pytest.mark.asyncio
async def test_shutdown(agent):
    """Test agent shutdown."""
    # Mock the NATS client
    agent.nats_client = AsyncMock()
    
    # Call shutdown
    await agent.shutdown()
    
    # Verify the NATS client was drained
    agent.nats_client.drain.assert_called_once()
    
    # Verify the state was updated
    assert agent.state == "SHUTDOWN"