"""
Tests for the configuration module.
"""

import os
import tempfile
from pathlib import Path
from unittest import mock

import pytest
import yaml
from pydantic import ValidationError

from python_bridge.config import load_config, AgentConfig, NatsConfig, ModelConfig


def test_load_config_valid():
    """Test loading a valid configuration file."""
    # Create a temporary config file
    with tempfile.NamedTemporaryFile(suffix=".yaml", delete=False) as temp:
        config_data = {
            "agent_id": "test-agent",
            "log_level": "INFO",
            "nats": {
                "server_url": "nats://localhost:4222"
            },
            "model": {
                "model_id": "Qwen/Qwen2.5-Coder-32B-Instruct"
            }
        }
        yaml.dump(config_data, temp)
    
    try:
        # Load the config
        config = load_config(temp.name)
        
        # Verify the loaded config
        assert config["agent_id"] == "test-agent"
        assert config["log_level"] == "INFO"
        assert config["nats"]["server_url"] == "nats://localhost:4222"
        assert config["model"]["model_id"] == "Qwen/Qwen2.5-Coder-32B-Instruct"
    finally:
        # Clean up
        os.unlink(temp.name)


def test_load_config_missing_file():
    """Test loading a nonexistent configuration file."""
    with pytest.raises(FileNotFoundError):
        load_config("/nonexistent/config.yaml")


def test_load_config_invalid():
    """Test loading an invalid configuration file."""
    # Create a temporary config file with invalid data
    with tempfile.NamedTemporaryFile(suffix=".yaml", delete=False) as temp:
        config_data = {
            "agent_id": "test-agent",
            "log_level": "INFO",
            # Missing required 'nats' section
            "model": {
                "model_id": "Qwen/Qwen2.5-Coder-32B-Instruct"
            }
        }
        yaml.dump(config_data, temp)
    
    try:
        # Attempt to load the config
        with pytest.raises(ValidationError):
            load_config(temp.name)
    finally:
        # Clean up
        os.unlink(temp.name)


def test_agent_config_validation():
    """Test AgentConfig validation."""
    # Valid config
    valid_config = {
        "agent_id": "test-agent",
        "log_level": "INFO",
        "nats": {
            "server_url": "nats://localhost:4222"
        },
        "model": {
            "model_id": "Qwen/Qwen2.5-Coder-32B-Instruct"
        }
    }
    config = AgentConfig(**valid_config)
    assert config.agent_id == "test-agent"
    assert config.log_level == "INFO"
    
    # Test default values
    assert config.health.check_interval == 30
    assert config.health.metrics_enabled is True
    assert config.model.use_local_model is False
    assert config.model.local_model_path is None


def test_nats_config_validation():
    """Test NatsConfig validation."""
    # Valid config
    config = NatsConfig(server_url="nats://localhost:4222")
    assert config.server_url == "nats://localhost:4222"
    assert config.reconnect_attempts == 10
    
    # Invalid config - missing required field
    with pytest.raises(ValidationError):
        NatsConfig()


def test_model_config_validation():
    """Test ModelConfig validation."""
    # Valid config
    config = ModelConfig(model_id="Qwen/Qwen2.5-Coder-32B-Instruct")
    assert config.model_id == "Qwen/Qwen2.5-Coder-32B-Instruct"
    assert config.use_local_model is False
    
    # Test with model kwargs
    config = ModelConfig(
        model_id="Qwen/Qwen2.5-Coder-32B-Instruct",
        model_kwargs={"temperature": 0.2}
    )
    assert config.model_kwargs["temperature"] == 0.2