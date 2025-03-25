"""
Python Bridge Agent Implementation

This module provides the main Python Bridge Agent implementation,
including agent lifecycle management, registration with the orchestrator,
and task handling.
"""

import asyncio
import json
import os
import signal
import time
import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional, Set

from loguru import logger
from nats.aio.msg import Msg

from python_bridge.api import ApiService
from python_bridge.nats_client import NatsClient
from python_bridge.smolagents_manager import SmolagentsManager


class AgentStatus:
    """Agent status constants."""
    INITIALIZING = "initializing"
    REGISTERING = "registering"
    READY = "ready"
    PROCESSING = "processing"
    ERROR = "error"
    STOPPING = "stopping"
    STOPPED = "stopped"


class PythonBridgeAgent:
    """Main Python Bridge Agent implementation."""
    
    def __init__(self, 
                 nats_server_url: str, 
                 agent_id: Optional[str] = None,
                 capabilities: Optional[List[str]] = None,
                 health_check_interval: int = 30,
                 model_config: Optional[Dict[str, Any]] = None,
                 api_enabled: bool = True,
                 api_host: str = "0.0.0.0",
                 api_port: int = 8080):
        """
        Initialize the Python Bridge Agent.
        
        Args:
            nats_server_url: NATS server URL
            agent_id: Optional agent ID (generated if not provided)
            capabilities: List of agent capabilities
            health_check_interval: Health check interval in seconds
            model_config: Configuration for the AI model
            api_enabled: Whether to enable the API server
            api_host: API server host
            api_port: API server port
        """
        self.agent_id = agent_id or f"python-bridge-{uuid.uuid4().hex[:8]}"
        self.nats_client = NatsClient(nats_server_url)
        self.capabilities = capabilities or [
            "code-generation",
            "documentation-generation",
            "uvc-analysis"
        ]
        self.status = AgentStatus.INITIALIZING
        self._health_check_interval = health_check_interval
        self._health_check_task = None
        self._active_tasks: Dict[str, Dict[str, Any]] = {}
        self._task_results: Dict[str, Dict[str, Any]] = {}
        self._model_config = model_config or {}
        self._ai_manager = None
        self._start_time = time.time()
        self._api_enabled = api_enabled
        self._api_service = None
        self._api_host = api_host
        self._api_port = api_port
        
    async def start(self) -> bool:
        """
        Start the agent and register with the orchestrator.
        
        Returns:
            True if the agent started successfully, False otherwise
        """
        logger.info(f"Starting Python Bridge Agent {self.agent_id}")
        
        # Set up signal handlers for graceful shutdown
        await self._setup_signal_handlers()
        
        # Connect to NATS
        connected = await self.nats_client.connect()
        if not connected:
            logger.error("Failed to connect to NATS, agent cannot start")
            return False
            
        # Initialize AI manager
        try:
            self._ai_manager = SmolagentsManager(**self._model_config)
        except Exception as e:
            logger.error(f"Failed to initialize AI manager: {str(e)}")
            await self.nats_client.close()
            return False
        
        # Register with orchestrator
        self.status = AgentStatus.REGISTERING
        registered = await self.register_with_orchestrator()
        if not registered:
            logger.error("Failed to register with orchestrator")
            await self.nats_client.close()
            return False
            
        # Subscribe to agent's task topic
        task_topic = f"agent.{self.agent_id}.task"
        await self.nats_client.subscribe(task_topic, self._handle_task)
        
        # Subscribe to control topic
        control_topic = f"agent.{self.agent_id}.control"
        await self.nats_client.subscribe(control_topic, self._handle_control)
        
        # Start health check reporting
        self._health_check_task = asyncio.create_task(self._report_health_status())
        
        # Start API service if enabled
        if self._api_enabled:
            try:
                self._api_service = ApiService(self, self._api_host, self._api_port)
                self._api_service.start_in_background()
                logger.info(f"API service started on {self._api_host}:{self._api_port}")
            except Exception as e:
                logger.error(f"Failed to start API service: {str(e)}")
                # Continue without API service
        
        self.status = AgentStatus.READY
        logger.info(f"Python Bridge Agent {self.agent_id} started successfully")
        return True
        
    async def stop(self) -> None:
        """Stop the agent gracefully."""
        logger.info(f"Stopping Python Bridge Agent {self.agent_id}")
        self.status = AgentStatus.STOPPING
        
        # Cancel health check task
        if self._health_check_task:
            self._health_check_task.cancel()
            try:
                await self._health_check_task
            except asyncio.CancelledError:
                pass
            
        # Complete active tasks
        for task_id, task_data in list(self._active_tasks.items()):
            logger.info(f"Completing active task {task_id} before shutdown")
            try:
                result = await self._complete_task(task_id, task_data, cancelled=True)
                logger.info(f"Task {task_id} completed with status: {result.get('status')}")
            except Exception as e:
                logger.error(f"Error completing task {task_id}: {str(e)}")
        
        # Unregister from orchestrator
        try:
            await self._unregister_from_orchestrator()
        except Exception as e:
            logger.error(f"Error unregistering from orchestrator: {str(e)}")
        
        # Close NATS connection
        await self.nats_client.close()
        
        self.status = AgentStatus.STOPPED
        logger.info(f"Python Bridge Agent {self.agent_id} stopped")
        
    async def register_with_orchestrator(self) -> bool:
        """
        Register this agent with the MCP orchestrator.
        
        Returns:
            True if registration was successful, False otherwise
        """
        registration_data = {
            "agentId": self.agent_id,
            "agentType": "python-bridge",
            "capabilities": self.capabilities,
            "status": self.status,
            "registrationTime": datetime.utcnow().isoformat() + "Z",
            "version": "0.1.0"
        }
        
        return await self.nats_client.publish("agent.registration", registration_data)
    
    async def _unregister_from_orchestrator(self) -> bool:
        """
        Unregister this agent from the MCP orchestrator.
        
        Returns:
            True if unregistration was successful, False otherwise
        """
        unregistration_data = {
            "agentId": self.agent_id,
            "status": AgentStatus.STOPPED,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        
        return await self.nats_client.publish("agent.unregistration", unregistration_data)
    
    async def _report_health_status(self) -> None:
        """Periodically report health status to the orchestrator."""
        while True:
            try:
                # Collect basic metrics
                metrics = await self._collect_metrics()
                
                health_data = {
                    "agentId": self.agent_id,
                    "status": self.status,
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "metrics": metrics,
                    "activeTasks": len(self._active_tasks)
                }
                
                await self.nats_client.publish("agent.health", health_data)
                await asyncio.sleep(self._health_check_interval)
            except asyncio.CancelledError:
                logger.info("Health check task cancelled")
                break
            except Exception as e:
                logger.error(f"Error reporting health status: {str(e)}")
                await asyncio.sleep(self._health_check_interval)
    
    async def _collect_metrics(self) -> Dict[str, Any]:
        """
        Collect agent metrics.
        
        Returns:
            Dictionary of metrics
        """
        # Get resource usage
        import psutil
        
        process = psutil.Process(os.getpid())
        
        try:
            memory_info = process.memory_info()
            cpu_percent = process.cpu_percent(interval=0.1)
            
            return {
                "memoryUsage": memory_info.rss / (1024 * 1024),  # MB
                "cpuUsage": cpu_percent,
                "activeTaskCount": len(self._active_tasks),
                "uptime": time.time() - self._start_time
            }
        except Exception as e:
            logger.error(f"Error collecting metrics: {str(e)}")
            return {
                "memoryUsage": 0,
                "cpuUsage": 0,
                "activeTaskCount": len(self._active_tasks),
                "uptime": time.time() - self._start_time
            }
    
    async def _handle_task(self, msg: Msg) -> None:
        """
        Handle incoming task messages.
        
        Args:
            msg: NATS message
        """
        try:
            # Decode the message
            data = json.loads(msg.data.decode())
            task_id = data.get("taskId")
            task_type = data.get("type")
            parameters = data.get("parameters", {})
            
            if not task_id:
                logger.error(f"Received task without taskId: {data}")
                return
                
            if not task_type:
                logger.error(f"Received task without type: {data}")
                # Send error response
                error_response = {
                    "taskId": task_id,
                    "status": "failed",
                    "error": {
                        "message": "Task type not specified",
                        "type": "ValidationError"
                    }
                }
                await self.nats_client.publish(f"task.{task_id}.result", error_response)
                return
                
            logger.info(f"Received task {task_id} of type {task_type}")
            
            # Store the task
            self._active_tasks[task_id] = {
                "type": task_type,
                "parameters": parameters,
                "received_time": datetime.utcnow().isoformat() + "Z"
            }
            
            # Update status
            previous_status = self.status
            self.status = AgentStatus.PROCESSING
            
            # Process the task asynchronously
            asyncio.create_task(self._process_task(task_id, task_type, parameters))
            
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding task message: {str(e)}")
        except Exception as e:
            logger.error(f"Error handling task: {str(e)}")
            self.status = previous_status
    
    async def _handle_control(self, msg: Msg) -> None:
        """
        Handle incoming control messages.
        
        Args:
            msg: NATS message
        """
        try:
            # Decode the message
            data = json.loads(msg.data.decode())
            command = data.get("command")
            
            logger.info(f"Received control command: {command}")
            
            if command == "stop":
                # Initiate graceful shutdown
                asyncio.create_task(self.stop())
            elif command == "status":
                # Report current status
                status_data = {
                    "agentId": self.agent_id,
                    "status": self.status,
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "activeTasks": len(self._active_tasks)
                }
                await self.nats_client.publish(data.get("replyTo", f"agent.{self.agent_id}.status"), status_data)
            elif command == "restart":
                # Restart the agent
                logger.info("Restarting agent")
                await self.stop()
                asyncio.create_task(self.start())
            elif command == "clearTasks":
                # Clear completed tasks
                self._task_results = {
                    task_id: result for task_id, result in self._task_results.items()
                    if task_id in self._active_tasks
                }
                logger.info(f"Cleared completed tasks, remaining: {len(self._task_results)}")
            else:
                logger.warning(f"Unknown control command: {command}")
                
        except json.JSONDecodeError as e:
            logger.error(f"Error decoding control message: {str(e)}")
        except Exception as e:
            logger.error(f"Error handling control message: {str(e)}")
    
    async def _process_task(self, task_id: str, task_type: str, parameters: Dict[str, Any]) -> None:
        """
        Process a task using the AI manager.
        
        Args:
            task_id: Task ID
            task_type: Task type
            parameters: Task parameters
        """
        try:
            # Check if the task type is supported
            if task_type not in self.capabilities:
                logger.error(f"Unsupported task type: {task_type}")
                # Send error response
                error_response = {
                    "taskId": task_id,
                    "status": "failed",
                    "error": {
                        "message": f"Unsupported task type: {task_type}",
                        "type": "UnsupportedTaskError"
                    }
                }
                await self.nats_client.publish(f"task.{task_id}.result", error_response)
                return
            
            # Process the task with the AI manager
            logger.info(f"Processing task {task_id} with AI manager")
            start_time = time.time()
            result = await self._ai_manager.process_task(task_type, parameters)
            processing_time = time.time() - start_time
            
            # Prepare response
            if result.get("success", False):
                response = {
                    "taskId": task_id,
                    "status": "completed",
                    "result": result.get("data", {}),
                    "processingTime": processing_time
                }
                logger.info(f"Task {task_id} completed successfully in {processing_time:.2f}s")
            else:
                response = {
                    "taskId": task_id,
                    "status": "failed",
                    "error": result.get("error", {"message": "Unknown error"}),
                    "processingTime": processing_time
                }
                logger.error(f"Task {task_id} failed: {result.get('error', {}).get('message', 'Unknown error')}")
            
            # Store the result
            self._task_results[task_id] = response
            
            # Send the result
            await self.nats_client.publish(f"task.{task_id}.result", response)
            
        except Exception as e:
            logger.error(f"Error processing task {task_id}: {str(e)}")
            
            # Send error response
            error_response = {
                "taskId": task_id,
                "status": "failed",
                "error": {
                    "message": str(e),
                    "type": type(e).__name__
                }
            }
            
            # Store the result
            self._task_results[task_id] = error_response
            
            await self.nats_client.publish(f"task.{task_id}.result", error_response)
        finally:
            # Update agent status and remove task from active tasks
            if task_id in self._active_tasks:
                del self._active_tasks[task_id]
                
            # Update status if no more active tasks
            if not self._active_tasks and self.status == AgentStatus.PROCESSING:
                self.status = AgentStatus.READY
    
    async def _complete_task(self, task_id: str, task_data: Dict[str, Any], cancelled: bool = False) -> Dict[str, Any]:
        """
        Complete a task and send the result.
        
        Args:
            task_id: Task ID
            task_data: Task data
            cancelled: Whether the task was cancelled
            
        Returns:
            Task result
        """
        if cancelled:
            # Create a cancelled result
            result = {
                "taskId": task_id,
                "status": "cancelled",
                "error": {
                    "message": "Task cancelled due to agent shutdown",
                    "type": "TaskCancelled"
                }
            }
        else:
            # Process the task normally (fallback)
            try:
                task_type = task_data.get("type")
                parameters = task_data.get("parameters", {})
                result_data = await self._ai_manager.process_task(task_type, parameters)
                
                result = {
                    "taskId": task_id,
                    "status": "completed",
                    "result": result_data
                }
            except Exception as e:
                result = {
                    "taskId": task_id,
                    "status": "failed",
                    "error": {
                        "message": str(e),
                        "type": type(e).__name__
                    }
                }
        
        # Store the result
        self._task_results[task_id] = result
        
        # Send the result
        await self.nats_client.publish(f"task.{task_id}.result", result)
        
        return result
    
    async def _setup_signal_handlers(self):
        """Set up signal handlers for graceful shutdown."""
        loop = asyncio.get_running_loop()
        
        for sig in (signal.SIGINT, signal.SIGTERM):
            loop.add_signal_handler(
                sig, 
                lambda: asyncio.create_task(self._handle_shutdown_signal())
            )
    
    async def _handle_shutdown_signal(self):
        """Handle shutdown signal."""
        logger.info("Received shutdown signal")
        await self.stop()