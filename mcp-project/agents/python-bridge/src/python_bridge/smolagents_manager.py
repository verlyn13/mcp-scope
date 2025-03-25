"""
Smolagents Framework Integration

This module provides integration with the smolagents framework for AI-powered
code generation and documentation generation.
"""

import asyncio
from typing import Any, Dict, List, Optional, Callable

from loguru import logger
from smolagents import CodeAgent, HfApiModel

from python_bridge.tools.code_generation import generate_uvc_camera_code
from python_bridge.tools.documentation import generate_documentation


class SmolagentsManager:
    """Manager for smolagents framework integration."""
    
    def __init__(self, 
                 model_id: str = "Qwen/Qwen2.5-Coder-32B-Instruct",
                 model_kwargs: Optional[Dict[str, Any]] = None,
                 use_local_model: bool = False,
                 local_model_path: Optional[str] = None):
        """
        Initialize with the specified model.
        
        Args:
            model_id: HuggingFace model ID
            model_kwargs: Additional model parameters
            use_local_model: Whether to use a local model
            local_model_path: Path to local model weights
        """
        logger.info(f"Initializing smolagents manager with model: {model_id}")
        self.model_id = model_id
        self.model_kwargs = model_kwargs or {
            "temperature": 0.2,
            "max_tokens": 4096,
            "top_p": 0.95
        }
        
        # Initialize model
        if use_local_model and local_model_path:
            logger.info(f"Using local model from: {local_model_path}")
            # TODO: Implement local model loading
            raise NotImplementedError("Local model support not yet implemented")
        else:
            self.model = HfApiModel(model_id=model_id, **self.model_kwargs)
        
        # Initialize tools
        self.tools = {
            "code-generation": generate_uvc_camera_code,
            "documentation-generation": generate_documentation,
            # Add other tools as they are implemented
        }
        
        # Initialize agents dictionary
        self.agents = {}
        
    async def process_task(self, task_type: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process a task using the appropriate AI agent and tool.
        
        Args:
            task_type: Type of task to process
            params: Task parameters
            
        Returns:
            Task result
            
        Raises:
            ValueError: If the task type is not supported
        """
        logger.info(f"Processing task of type: {task_type}")
        
        if task_type not in self.tools:
            raise ValueError(f"Unsupported task type: {task_type}")
        
        # Get or create agent for this task type
        agent = await self._get_agent(task_type)
        
        # Process the task
        try:
            # Validate parameters
            self._validate_task_params(task_type, params)
            
            # Build prompt
            prompt = self._build_prompt(task_type, params)
            
            # Execute the tool with the agent
            tool_fn = self.tools[task_type]
            result = await tool_fn(agent, prompt, params)
            
            # Format the result
            formatted_result = self._format_result(task_type, result)
            
            return {
                "success": True,
                "data": formatted_result
            }
        except Exception as e:
            logger.error(f"Error processing {task_type} task: {str(e)}")
            return {
                "success": False,
                "error": {
                    "message": str(e),
                    "type": type(e).__name__
                }
            }
    
    async def _get_agent(self, task_type: str) -> CodeAgent:
        """
        Get or create an agent for the specified task type.
        
        Args:
            task_type: Task type
            
        Returns:
            CodeAgent instance
        """
        if task_type not in self.agents:
            logger.info(f"Creating new agent for task type: {task_type}")
            self.agents[task_type] = CodeAgent(llm=self.model)
        
        return self.agents[task_type]
    
    def _validate_task_params(self, task_type: str, params: Dict[str, Any]) -> None:
        """
        Validate task parameters for the specified task type.
        
        Args:
            task_type: Task type
            params: Task parameters
            
        Raises:
            ValueError: If the parameters are invalid
        """
        if task_type == "code-generation":
            required_params = ["requirements", "targetPackage", "cameraType"]
            for param in required_params:
                if param not in params:
                    raise ValueError(f"Missing required parameter: {param}")
        
        elif task_type == "documentation-generation":
            required_params = ["code", "targetFormat", "docType"]
            for param in required_params:
                if param not in params:
                    raise ValueError(f"Missing required parameter: {param}")
        
        elif task_type == "uvc-analysis":
            required_params = ["deviceData", "analysisType"]
            for param in required_params:
                if param not in params:
                    raise ValueError(f"Missing required parameter: {param}")
    
    def _build_prompt(self, task_type: str, params: Dict[str, Any]) -> str:
        """
        Build a prompt for the specified task type and parameters.
        
        Args:
            task_type: Task type
            params: Task parameters
            
        Returns:
            Prompt string
        """
        if task_type == "code-generation":
            return f"""
            # Code Generation Task
            
            ## Requirements
            {params['requirements']}
            
            ## Target Package
            {params['targetPackage']}
            
            ## Camera Type
            {params['cameraType']}
            
            Please generate high-quality, well-documented code that meets these requirements.
            The code should follow best practices for Android and Kotlin development.
            Include appropriate error handling and comments.
            """
        
        elif task_type == "documentation-generation":
            return f"""
            # Documentation Generation Task
            
            ## Code to Document
            ```
            {params['code']}
            ```
            
            ## Target Format
            {params['targetFormat']}
            
            ## Documentation Type
            {params['docType']}
            
            Please generate comprehensive documentation for this code.
            The documentation should explain the purpose, usage, and behavior of the code.
            Follow best practices for {params['targetFormat']} format.
            """
        
        elif task_type == "uvc-analysis":
            return f"""
            # UVC Device Analysis Task
            
            ## Device Data
            ```
            {params['deviceData']}
            ```
            
            ## Analysis Type
            {params['analysisType']}
            
            Please analyze the UVC device data and provide insights.
            Focus on {params['analysisType']} aspects of the device.
            """
        
        else:
            raise ValueError(f"Unsupported task type: {task_type}")
    
    def _format_result(self, task_type: str, result: Dict[str, Any]) -> Dict[str, Any]:
        """
        Format the result for the specified task type.
        
        Args:
            task_type: Task type
            result: Raw result from the tool
            
        Returns:
            Formatted result
        """
        if task_type == "code-generation":
            return {
                "code": result.get("code", ""),
                "explanation": result.get("explanation", ""),
                "files": result.get("files", {}),
                "targetPackage": result.get("targetPackage", "")
            }
        
        elif task_type == "documentation-generation":
            return {
                "documentation": result.get("documentation", ""),
                "format": result.get("format", "markdown"),
                "explanation": result.get("explanation", ""),
                "sections": result.get("sections", {})
            }
        
        elif task_type == "uvc-analysis":
            return {
                "analysis": result.get("analysis", ""),
                "findings": result.get("findings", []),
                "recommendations": result.get("recommendations", [])
            }
        
        else:
            return {"raw_result": result}


class ModelRegistry:
    """Registry for AI models."""
    
    def __init__(self):
        """Initialize the model registry."""
        self.models = {}
        
    def register_model(self, model_name: str, model_config: Dict[str, Any]) -> None:
        """
        Register a model with the registry.
        
        Args:
            model_name: Name for the model
            model_config: Model configuration
        """
        self.models[model_name] = model_config
        
    def get_model(self, model_name: str) -> Optional[Dict[str, Any]]:
        """
        Get a model configuration by name.
        
        Args:
            model_name: Name of the model
            
        Returns:
            Model configuration or None if not found
        """
        return self.models.get(model_name)
        
    def list_models(self) -> List[str]:
        """
        Get a list of registered model names.
        
        Returns:
            List of model names
        """
        return list(self.models.keys())


class ToolRegistry:
    """Registry for AI tools."""
    
    def __init__(self):
        """Initialize the tool registry."""
        self.tools = {}
        
    def register_tool(self, tool_name: str, tool_function: Callable, description: str) -> None:
        """
        Register a tool with the registry.
        
        Args:
            tool_name: Name for the tool
            tool_function: Tool function
            description: Tool description
        """
        self.tools[tool_name] = {
            "function": tool_function,
            "description": description
        }
        
    def get_tool(self, tool_name: str) -> Optional[Dict[str, Any]]:
        """
        Get a tool by name.
        
        Args:
            tool_name: Name of the tool
            
        Returns:
            Tool configuration or None if not found
        """
        return self.tools.get(tool_name)
        
    def list_tools(self) -> List[str]:
        """
        Get a list of registered tool names.
        
        Returns:
            List of tool names
        """
        return list(self.tools.keys())