"""
API Service for Python Bridge Agent

This module provides HTTP API endpoints for the Python Bridge Agent,
including health check and task management.
"""

import asyncio
import time
from typing import Any, Dict, List, Optional, Union

import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks, Response, status
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
from pydantic import BaseModel, Field

from python_bridge.agent import PythonBridgeAgent


class HealthResponse(BaseModel):
    """Health check response model."""
    status: str = Field(..., description="Current agent status")
    uptime: float = Field(..., description="Uptime in seconds")
    version: str = Field(..., description="Agent version")
    agent_id: str = Field(..., description="Agent ID")


class TaskRequest(BaseModel):
    """Task request model."""
    type: str = Field(..., description="Task type")
    parameters: Dict[str, Any] = Field(..., description="Task parameters")


class TaskResponse(BaseModel):
    """Task response model."""
    task_id: str = Field(..., description="Task ID")
    status: str = Field(..., description="Task status")
    result: Optional[Dict[str, Any]] = Field(None, description="Task result")
    error: Optional[str] = Field(None, description="Error message if task failed")


class AgentMetrics(BaseModel):
    """Agent metrics model."""
    active_tasks: int = Field(..., description="Number of active tasks")
    completed_tasks: int = Field(..., description="Number of completed tasks")
    failed_tasks: int = Field(..., description="Number of failed tasks")
    average_processing_time: float = Field(..., description="Average processing time in ms")
    uptime: float = Field(..., description="Uptime in seconds")


class ApiService:
    """API service for the Python Bridge Agent."""
    
    def __init__(self, agent: PythonBridgeAgent, host: str = "0.0.0.0", port: int = 8080):
        """
        Initialize the API service.
        
        Args:
            agent: Python Bridge Agent instance
            host: Host to bind to
            port: Port to bind to
        """
        self.agent = agent
        self.host = host
        self.port = port
        self.app = FastAPI(
            title="Python Bridge Agent API",
            description="API for the Python Bridge Agent with smolagents integration",
            version="0.1.0"
        )
        
        self.start_time = time.time()
        self.metrics = {
            "active_tasks": 0,
            "completed_tasks": 0,
            "failed_tasks": 0,
            "processing_times": [],
        }
        
        # Set up CORS
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
        
        # Set up routes
        self._setup_routes()
        
    def _setup_routes(self):
        """Set up API routes."""
        
        @self.app.get("/health", response_model=HealthResponse)
        async def health_check():
            """
            Health check endpoint.
            
            Returns:
                Health status response
            """
            return {
                "status": self.agent.status,
                "uptime": time.time() - self.start_time,
                "version": "0.1.0",
                "agent_id": self.agent.agent_id
            }
        
        @self.app.post("/task", response_model=TaskResponse)
        async def submit_task(task: TaskRequest, background_tasks: BackgroundTasks):
            """
            Submit a task to be processed.
            
            Args:
                task: Task request
                background_tasks: Background tasks object
            
            Returns:
                Task response with task ID
            """
            # Generate a task ID
            import uuid
            task_id = str(uuid.uuid4())
            
            # Update metrics
            self.metrics["active_tasks"] += 1
            
            # Submit the task
            background_tasks.add_task(
                self._process_task, 
                task_id, 
                task.type, 
                task.parameters
            )
            
            return {
                "task_id": task_id,
                "status": "submitted",
                "result": None,
                "error": None
            }
        
        @self.app.get("/task/{task_id}", response_model=TaskResponse)
        async def get_task_status(task_id: str):
            """
            Get the status of a task.
            
            Args:
                task_id: Task ID
            
            Returns:
                Task response with status and result if available
            """
            # Check if task exists
            if task_id not in self.agent._task_results:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Task {task_id} not found"
                )
            
            # Return task status
            task_info = self.agent._task_results[task_id]
            return {
                "task_id": task_id,
                "status": task_info["status"],
                "result": task_info.get("result"),
                "error": task_info.get("error")
            }
        
        @self.app.get("/metrics", response_model=AgentMetrics)
        async def get_metrics():
            """
            Get agent metrics.
            
            Returns:
                Agent metrics
            """
            # Calculate average processing time
            avg_time = 0.0
            if self.metrics["processing_times"]:
                avg_time = sum(self.metrics["processing_times"]) / len(self.metrics["processing_times"])
            
            return {
                "active_tasks": self.metrics["active_tasks"],
                "completed_tasks": self.metrics["completed_tasks"],
                "failed_tasks": self.metrics["failed_tasks"],
                "average_processing_time": avg_time,
                "uptime": time.time() - self.start_time
            }
        
        @self.app.get("/capabilities", response_model=List[str])
        async def get_capabilities():
            """
            Get agent capabilities.
            
            Returns:
                List of agent capabilities
            """
            return self.agent.capabilities
        
        @self.app.get("/status")
        async def get_status():
            """
            Get agent status.
            
            Returns:
                Agent status
            """
            return {"status": self.agent.status}
        
        @self.app.post("/shutdown")
        async def shutdown():
            """
            Shut down the agent gracefully.
            
            Returns:
                Confirmation message
            """
            # Trigger agent shutdown
            await self.agent.stop()
            return {"message": "Agent shutting down"}
    
    async def _process_task(self, task_id: str, task_type: str, parameters: Dict[str, Any]):
        """
        Process a task in the background.
        
        Args:
            task_id: Task ID
            task_type: Task type
            parameters: Task parameters
        """
        logger.info(f"Processing task {task_id} of type {task_type}")
        
        start_time = time.time()
        
        try:
            # Process the task
            result = await self.agent._ai_manager.process_task(task_type, parameters)
            
            # Record success
            self.agent._task_results[task_id] = {
                "status": "completed",
                "result": result
            }
            
            # Update metrics
            self.metrics["completed_tasks"] += 1
            
        except Exception as e:
            logger.error(f"Error processing task {task_id}: {str(e)}")
            
            # Record failure
            self.agent._task_results[task_id] = {
                "status": "failed",
                "error": str(e)
            }
            
            # Update metrics
            self.metrics["failed_tasks"] += 1
            
        finally:
            # Calculate processing time
            processing_time = (time.time() - start_time) * 1000  # ms
            self.metrics["processing_times"].append(processing_time)
            
            # Update metrics
            self.metrics["active_tasks"] -= 1
    
    async def start(self):
        """Start the API service."""
        loop = asyncio.get_event_loop()
        config = uvicorn.Config(
            app=self.app,
            host=self.host,
            port=self.port,
            loop=loop
        )
        server = uvicorn.Server(config)
        await server.serve()
    
    def start_in_background(self):
        """Start the API service in the background."""
        loop = asyncio.get_event_loop()
        asyncio.create_task(self.start())