#!/usr/bin/env python
"""
Python Bridge Agent Main Entry Point

This module provides the main entry point for the Python Bridge Agent,
initializing the agent and starting its operation.
"""

import argparse
import asyncio
import os
import signal
import sys
from pathlib import Path

from loguru import logger

from python_bridge.agent import PythonBridgeAgent
from python_bridge.config import load_config


def setup_logging(log_level="INFO"):
    """Configure logging for the application."""
    logger.remove()  # Remove default handler
    logger.add(
        sys.stderr,
        level=log_level,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
    )
    logger.add(
        "logs/python_bridge_{time}.log",
        rotation="10 MB",
        retention="7 days",
        level=log_level,
    )


async def run_agent(config_path=None):
    """Initialize and run the Python Bridge Agent."""
    # Load configuration
    config_path = config_path or os.environ.get("AGENT_CONFIG_PATH", "config.yaml")
    logger.info(f"Loading configuration from {config_path}")
    
    try:
        config = load_config(config_path)
    except Exception as e:
        logger.error(f"Failed to load configuration: {str(e)}")
        return 1
    
    # Set up logging with configuration
    setup_logging(config.get("log_level", "INFO"))
    
    # Get configuration values
    nats_server_url = config["nats"]["server_url"]
    agent_id = config.get("agent_id")
    capabilities = config.get("capabilities", ["code-generation", "documentation-generation", "uvc-analysis"])
    health_check_interval = config["health"]["check_interval"]
    
    # API configuration
    api_config = config.get("api", {})
    api_enabled = api_config.get("enabled", True)
    api_host = api_config.get("host", "0.0.0.0")
    api_port = api_config.get("port", 8080)
    
    # Create and start agent
    agent = PythonBridgeAgent(
        nats_server_url=nats_server_url,
        agent_id=agent_id,
        capabilities=capabilities,
        health_check_interval=health_check_interval,
        model_config=config.get("model", {}),
        api_enabled=api_enabled,
        api_host=api_host,
        api_port=api_port
    )
    
    # Start the agent
    try:
        if not await agent.start():
            logger.error("Failed to start the agent")
            return 1
        
        # Keep the agent running
        logger.info("Agent is running, press Ctrl+C to stop")
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("Received keyboard interrupt, shutting down")
    except Exception as e:
        logger.error(f"Error running agent: {str(e)}")
        return 1
    finally:
        # Ensure agent is properly stopped
        await agent.stop()
    
    return 0


def main():
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(description="Python Bridge Agent for MCP")
    parser.add_argument(
        "--config", "-c", help="Path to configuration file", default=None
    )
    args = parser.parse_args()
    
    # Create logs directory if it doesn't exist
    Path("logs").mkdir(exist_ok=True)
    
    # Set up basic logging before configuration is loaded
    setup_logging()
    
    try:
        sys.exit(asyncio.run(run_agent(args.config)))
    except KeyboardInterrupt:
        logger.info("Received shutdown signal, exiting")
        sys.exit(0)


if __name__ == "__main__":
    main()