import asyncio
import json
import os
import signal
import sys
import uuid
from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional

import nats
from loguru import logger
from pydantic import BaseModel

# Configure logging
logger.remove()
logger.add(sys.stderr, format="<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> [Python-Agent] <level>{level: <8}</level> <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>")


class TaskStatus(str, Enum):
    """Task status enum to match Kotlin's TaskStatus."""
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class AgentTask(BaseModel):
    """Model for an agent task that matches the Kotlin AgentTask."""
    taskId: str
    agentType: str
    payload: str
    priority: int = 0
    timeoutMs: int = 30000


class TaskResult(BaseModel):
    """Model for a task result that matches the Kotlin TaskResult."""
    taskId: str
    status: TaskStatus
    result: Optional[str] = None
    error: Optional[str] = None
    processingTimeMs: Optional[int] = None


class AgentStatus(BaseModel):
    """Model for agent status that matches the Kotlin AgentStatus."""
    agentId: str
    state: str
    healthCheck: bool
    activeTaskCount: int = 0
    lastHeartbeatMs: int = int(datetime.now().timestamp() * 1000)


class PyProcessorAgent:
    """Python implementation of an MCP agent for data processing tasks."""

    def __init__(self):
        self.agent_id = f"python-processor-{str(uuid.uuid4())[:8]}"
        self.capabilities = ["DATA_PROCESSING", "ANALYSIS"]
        self.state = "Idle"
        self.active_task_count = 0
        self.healthy = True
        self.nats_client = None
        self.running = True

    async def initialize(self):
        """Initialize the agent and connect to NATS."""
        logger.info(f"Initializing Python Processor Agent: {self.agent_id}")
        self.state = "Initializing"

        try:
            # Connect to NATS
            nats_url = os.environ.get("NATS_URL", "nats://localhost:4222")
            self.nats_client = await nats.connect(nats_url)
            logger.info(f"Connected to NATS server at {nats_url}")

            # Subscribe to task requests
            await self.nats_client.subscribe(
                f"mcp.task.{self.agent_id}",
                cb=self.process_task_message
            )

            # Register with orchestrator
            register_msg = {
                "agentId": self.agent_id,
                "capabilities": self.capabilities,
                "status": self.get_status().dict()
            }
            await self.nats_client.publish(
                "mcp.agent.register",
                json.dumps(register_msg).encode()
            )
            logger.info(f"Agent registered: {self.agent_id}")

            self.state = "Ready"
            self.healthy = True
            logger.info("Python Processor Agent initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Python Processor Agent: {str(e)}")
            self.state = "Error"
            self.healthy = False
            raise e

    async def process_task_message(self, msg):
        """Process a task message received from NATS."""
        try:
            # Parse the task message
            task_json = msg.data.decode()
            task = AgentTask.parse_raw(task_json)
            
            logger.info(f"Received task: {task.taskId}")
            
            # Process the task
            result = await self.process_task(task)
            
            # Publish the result
            await self.nats_client.publish(
                f"mcp.task.{task.taskId}.result",
                json.dumps(result.dict()).encode()
            )
            
            logger.info(f"Completed task: {task.taskId} with status: {result.status}")
        except Exception as e:
            logger.error(f"Error processing task message: {str(e)}")

    async def process_task(self, task: AgentTask) -> TaskResult:
        """Process a task and return a result."""
        logger.info(f"Processing task: {task.taskId} ({task.agentType})")
        start_time = int(datetime.now().timestamp() * 1000)
        
        try:
            self.active_task_count += 1
            self.state = "Processing"
            
            # Parse the task payload
            payload = json.loads(task.payload)
            
            # Process based on the action (This is a simple example)
            action = payload.get("action", "UNKNOWN")
            
            if action == "PROCESS_DATA":
                # Simulate data processing
                data = payload.get("data", [])
                processed = [item * 2 for item in data] if isinstance(data, list) else []
                result = {
                    "processedData": processed,
                    "count": len(processed),
                    "timestamp": datetime.now().isoformat()
                }
                result_str = json.dumps(result)
            elif action == "CALCULATE_STATS":
                # Simulate statistics calculation
                data = payload.get("data", [])
                if not isinstance(data, list) or not data:
                    return self._create_error_result(
                        task.taskId,
                        "Invalid or empty data for CALCULATE_STATS action",
                        start_time
                    )
                
                result = {
                    "min": min(data),
                    "max": max(data),
                    "avg": sum(data) / len(data),
                    "count": len(data),
                    "timestamp": datetime.now().isoformat()
                }
                result_str = json.dumps(result)
            else:
                return self._create_error_result(
                    task.taskId,
                    f"Unknown action: {action}",
                    start_time
                )
            
            processing_time = int(datetime.now().timestamp() * 1000) - start_time
            self.active_task_count -= 1
            self.state = "Ready"
            
            return TaskResult(
                taskId=task.taskId,
                status=TaskStatus.COMPLETED,
                result=result_str,
                processingTimeMs=processing_time
            )
        except Exception as e:
            logger.error(f"Error processing task {task.taskId}: {str(e)}")
            self.active_task_count -= 1
            self.state = "Ready"
            
            return self._create_error_result(task.taskId, str(e), start_time)

    def _create_error_result(self, task_id: str, error_message: str, start_time: int) -> TaskResult:
        """Helper method to create an error result."""
        processing_time = int(datetime.now().timestamp() * 1000) - start_time
        return TaskResult(
            taskId=task_id,
            status=TaskStatus.FAILED,
            error=error_message,
            processingTimeMs=processing_time
        )

    def get_status(self) -> AgentStatus:
        """Get the current agent status."""
        return AgentStatus(
            agentId=self.agent_id,
            state=self.state,
            healthCheck=self.healthy,
            activeTaskCount=self.active_task_count,
            lastHeartbeatMs=int(datetime.now().timestamp() * 1000)
        )

    async def send_heartbeat(self):
        """Send periodic heartbeats to the orchestrator."""
        while self.running:
            try:
                status = self.get_status()
                await self.nats_client.publish(
                    "mcp.agent.heartbeat",
                    json.dumps(status.dict()).encode()
                )
                await asyncio.sleep(10)  # Send heartbeat every 10 seconds
            except Exception as e:
                logger.error(f"Error sending heartbeat: {str(e)}")
                await asyncio.sleep(5)  # Retry after 5 seconds on error

    async def shutdown(self):
        """Shutdown the agent and release resources."""
        logger.info(f"Shutting down Python Processor Agent: {self.agent_id}")
        self.state = "ShuttingDown"
        self.running = False
        
        try:
            # Close NATS connection
            if self.nats_client:
                await self.nats_client.drain()
            
            self.state = "Shutdown"
            logger.info("Python Processor Agent shut down successfully")
        except Exception as e:
            logger.error(f"Error shutting down Python Processor Agent: {str(e)}")
            raise e


async def main():
    """Main entry point for the Python Processor Agent."""
    agent = PyProcessorAgent()
    
    # Set up signal handling for graceful shutdown
    def signal_handler():
        logger.info("Received shutdown signal")
        return asyncio.create_task(agent.shutdown())
    
    for sig in (signal.SIGINT, signal.SIGTERM):
        asyncio.get_event_loop().add_signal_handler(sig, signal_handler)
    
    try:
        # Initialize the agent
        await agent.initialize()
        
        # Start heartbeat task
        heartbeat_task = asyncio.create_task(agent.send_heartbeat())
        
        # Keep the agent running
        logger.info("Python Processor Agent running. Press Ctrl+C to exit.")
        while agent.running:
            await asyncio.sleep(1)
            
    except Exception as e:
        logger.error(f"Error in main loop: {str(e)}")
    finally:
        # Ensure proper shutdown
        if agent.running:
            await agent.shutdown()


if __name__ == "__main__":
    asyncio.run(main())