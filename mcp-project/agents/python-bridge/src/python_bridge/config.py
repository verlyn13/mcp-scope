"""
Configuration module for the Python Bridge Agent

This module provides functionality to load and validate configuration
from YAML files.
"""

import os
from pathlib import Path
from typing import Any, Dict, Optional

import yaml
from loguru import logger
from pydantic import BaseModel, Field, ValidationError


class NatsConfig(BaseModel):
    """NATS connection configuration."""
    server_url: str = Field(..., description="NATS server URL")
    reconnect_attempts: int = Field(10, description="Number of reconnection attempts")
    reconnect_timeout: float = Field(1.0, description="Initial timeout between reconnection attempts")
    max_reconnect_timeout: float = Field(15.0, description="Maximum timeout between reconnection attempts")


class HealthConfig(BaseModel):
    """Health monitoring configuration."""
    check_interval: int = Field(30, description="Health check interval in seconds")
    metrics_enabled: bool = Field(True, description="Whether to collect and report metrics")


class ModelConfig(BaseModel):
    """AI model configuration."""
    model_id: str = Field(..., description="Model ID to use with smolagents")
    model_kwargs: Dict[str, Any] = Field(default_factory=dict, description="Additional model parameters")
    local_model_path: Optional[str] = Field(None, description="Path to local model weights")
    use_local_model: bool = Field(False, description="Whether to use a local model instead of API")


class AgentConfig(BaseModel):
    """Main agent configuration."""
    agent_id: Optional[str] = Field(None, description="Agent ID (generated if not provided)")
    log_level: str = Field("INFO", description="Logging level")
    nats: NatsConfig
    health: HealthConfig = Field(default_factory=HealthConfig)
    model: ModelConfig
    capabilities: list[str] = Field(default_factory=list, description="Agent capabilities")


def load_config(config_path: str) -> Dict[str, Any]:
    """
    Load configuration from a YAML file.
    
    Args:
        config_path: Path to the configuration file
        
    Returns:
        Validated configuration dictionary
        
    Raises:
        FileNotFoundError: If the configuration file doesn't exist
        ValidationError: If the configuration is invalid
    """
    path = Path(config_path)
    
    if not path.exists():
        raise FileNotFoundError(f"Configuration file not found: {config_path}")
    
    with open(path, "r") as f:
        config_data = yaml.safe_load(f)
    
    try:
        validated_config = AgentConfig(**config_data)
        return validated_config.model_dump()
    except ValidationError as e:
        logger.error(f"Configuration validation error: {e}")
        raise