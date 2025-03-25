"""
Main Entry Point for Python Bridge Agent

This module serves as the entry point for the Python Bridge Agent,
handling initialization, main event loop, and graceful shutdown.
"""

import asyncio
import argparse
import logging
import os
import signal
import sys
from typing import Dict, Any

from .agent import PythonBridgeAgent

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Python Bridge Agent for MCP')
    
    parser.add_argument(
        '--nats-server',
        type=str,
        default=os.environ.get('NATS_SERVER', 'nats://localhost:4222'),
        help='NATS server URL (default: nats://localhost:4222)'
    )
    
    parser.add_argument(
        '--heartbeat-interval',
        type=int,
        default=int(os.environ.get('HEARTBEAT_INTERVAL', '30')),
        help='Heartbeat interval in seconds (default: 30)'
    )
    
    parser.add_argument(
        '--model-name',
        type=str,
        default=os.environ.get('MODEL_NAME', 'Qwen/Qwen2.5-Coder-32B-Instruct'),
        help='Hugging Face model name (default: Qwen/Qwen2.5-Coder-32B-Instruct)'
    )
    
    return parser.parse_args()


async def heartbeat_loop(agent: PythonBridgeAgent, interval: int) -> None:
    """Run a loop to send periodic heartbeats."""
    while True:
        try:
            await agent.send_heartbeat()
            await asyncio.sleep(interval)
        except asyncio.CancelledError:
            logger.info("Heartbeat loop cancelled")
            break
        except Exception as e:
            logger.error(f"Error in heartbeat loop: {str(e)}")
            await asyncio.sleep(interval)


async def start_health_server(agent: PythonBridgeAgent, port: int = 8080) -> None:
    """Start a simple health check HTTP server."""
    from aiohttp import web
    
    async def health_handler(request):
        """Handle health check requests."""
        if agent.state == "ERROR":
            return web.Response(status=500, text="Agent in ERROR state")
        return web.Response(text="Healthy")
    
    app = web.Application()
    app.router.add_get('/health', health_handler)
    
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', port)
    await site.start()
    logger.info(f"Health check server started on port {port}")


async def main() -> None:
    """Main entry point for the Python Bridge Agent."""
    args = parse_args()
    
    # Create agent
    agent = PythonBridgeAgent(nats_server=args.nats_server)
    
    # Setup signal handlers for graceful shutdown
    loop = asyncio.get_running_loop()
    
    def signal_handler():
        logger.info("Shutdown signal received")
        asyncio.create_task(shutdown(agent))
    
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, signal_handler)
    
    try:
        # Initialize the agent
        success = await agent.initialize()
        if not success:
            logger.error("Agent initialization failed")
            return
        
        # Start health check server
        await start_health_server(agent)
        
        # Start heartbeat loop
        heartbeat_task = asyncio.create_task(
            heartbeat_loop(agent, args.heartbeat_interval)
        )
        
        # Keep the agent running
        while True:
            await asyncio.sleep(1)
            
    except asyncio.CancelledError:
        logger.info("Main task cancelled")
    except Exception as e:
        logger.error(f"Unexpected error in main loop: {str(e)}")
    finally:
        await shutdown(agent)


async def shutdown(agent: PythonBridgeAgent) -> None:
    """Perform graceful shutdown of the agent."""
    logger.info("Shutting down Python Bridge Agent")
    
    try:
        # Shutdown the agent
        await agent.shutdown()
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")
    
    # Give pending tasks a chance to complete
    tasks = [t for t in asyncio.all_tasks() if t is not asyncio.current_task()]
    if tasks:
        logger.info(f"Waiting for {len(tasks)} pending tasks to complete")
        await asyncio.gather(*tasks, return_exceptions=True)
    
    logger.info("Shutdown complete")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Agent stopped by keyboard interrupt")
    except Exception as e:
        logger.error(f"Fatal error: {str(e)}")
        sys.exit(1)