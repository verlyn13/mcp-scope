"""
Code Generation Tool

This module provides tools for generating UVC camera-related code
using smolagents framework.
"""

import os
import re
from typing import Any, Dict, List, Optional

from loguru import logger
from smolagents import CodeAgent

from python_bridge.tools.uvc_code_templates import (
    get_template_set, 
    get_common_resolutions, 
    get_requirements_prompt,
    get_build_gradle_template
)


async def generate_uvc_camera_code(agent: CodeAgent, prompt: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate UVC camera code using smolagents.
    
    Args:
        agent: CodeAgent instance
        prompt: Task prompt
        params: Task parameters
        
    Returns:
        Dictionary containing generated code and explanation
    """
    logger.info(f"Generating UVC camera code for camera type: {params['cameraType']}")
    
    # Extract parameters
    requirements = params["requirements"]
    target_package = params["targetPackage"]
    camera_type = params["cameraType"]
    
    # Check if we should use templates or generate from scratch
    use_templates = camera_type.lower() in ["uvc", "usb"]
    
    if use_templates:
        return generate_from_templates(target_package, requirements, camera_type)
    else:
        return await generate_from_ai(agent, prompt, target_package, requirements, camera_type)


def generate_from_templates(
    target_package: str, 
    requirements: str, 
    camera_type: str
) -> Dict[str, Any]:
    """
    Generate code using predefined templates.
    
    Args:
        target_package: Target package name
        requirements: Requirements text
        camera_type: Type of camera
        
    Returns:
        Dictionary containing generated code and files
    """
    logger.info(f"Using templates for {camera_type} camera code generation")
    
    # Get templates for the target package
    templates = get_template_set(target_package)
    
    # Add a build.gradle file
    templates["build.gradle"] = get_build_gradle_template()
    
    # Create a consolidated code string
    consolidated_code = ""
    for filename, code in templates.items():
        consolidated_code += f"// File: {filename}\n\n{code}\n\n"
    
    # Generate explanatory text
    explanation = f"""
# UVC Camera Integration Code

I've generated a complete set of code files for integrating {camera_type} cameras into your Android application.
The implementation follows best practices and includes robust error handling.

## Generated Files

1. **UvcCamera.kt**: Interface defining the camera operations
2. **UvcCameraImpl.kt**: Implementation of the UVC camera interface
3. **UvcCameraManager.kt**: Manager for camera discovery and lifecycle
4. **UvcFrameProcessor.kt**: Processor for camera frames
5. **build.gradle**: Build configuration for the camera module

## Implementation Details

The code is organized around these key components:

- **UvcCamera Interface**: Defines the contract for camera operations including initialization, 
  preview control, image capture, and resource management.

- **UvcCameraImpl**: Implements the UVC protocol using Android's USB API. Handles the low-level
  communication with USB devices.

- **UvcCameraManager**: Provides discovery of UVC cameras and manages their lifecycle.
  Handles permission requests and maintains the collection of active cameras.

- **UvcFrameProcessor**: Processes camera frames for display or analysis.
  Provides interfaces for frame listeners.

## Usage Example

```kotlin
// Get the camera manager
val cameraManager = UvcCameraManager(context)

// Get available cameras
val cameras = cameraManager.getAvailableCameras()

// Open a camera
val camera = cameraManager.openCamera(cameras.first())

// Set resolution
camera.setResolution(1280, 720)

// Start preview
camera.startPreview()

// Capture an image
val imageData = camera.captureImage()

// When done
camera.stopPreview()
cameraManager.closeCamera(cameras.first())
```

## Next Steps

1. Implement the TODOs in UvcCameraImpl.kt with actual UVC protocol commands
2. Add frame listeners to process camera frames
3. Implement error handling for specific camera types
4. Add camera-specific features as needed
"""

    # Compile the result
    result = {
        "code": consolidated_code,
        "explanation": explanation,
        "files": templates,
        "targetPackage": target_package
    }
    
    return result


async def generate_from_ai(
    agent: CodeAgent, 
    prompt: str, 
    target_package: str, 
    requirements: str, 
    camera_type: str
) -> Dict[str, Any]:
    """
    Generate code using AI model.
    
    Args:
        agent: CodeAgent instance
        prompt: Original prompt
        target_package: Target package name
        requirements: Requirements text
        camera_type: Type of camera
        
    Returns:
        Dictionary containing generated code and explanation
    """
    logger.info(f"Using AI for {camera_type} camera code generation")
    
    # Enhance prompt with specific camera knowledge
    enhanced_prompt = f"""
    {prompt}
    
    ## Additional Technical Context
    
    For {camera_type.upper()} camera integration, consider the following:
    
    1. Device discovery and permission handling
    2. {camera_type.upper()} protocol specification compliance
    3. Frame processing and conversion
    4. Error handling for device disconnection
    5. Performance optimization for real-time video
    
    The code should be implemented in Kotlin for Android and should follow modern Android development practices.
    Use proper dependency injection and clean architecture principles.
    
    Target package: {target_package}
    Camera type: {camera_type}
    
    Provide a complete implementation including:
    1. Camera interface
    2. Implementation class
    3. Camera manager
    4. Frame processor
    5. Build.gradle configuration
    """
    
    # Create a custom prompt based on the requirements
    ai_prompt = get_requirements_prompt(target_package, requirements)
    
    # Execute the agent
    try:
        # Send the prompt to the AI model
        response = await agent.run(ai_prompt)
        
        # Extract code blocks from the response
        code_blocks = extract_code_blocks(response)
        
        # Process and organize the result
        result = process_code_generation_result(response, code_blocks, target_package)
        
        logger.info(f"Successfully generated {camera_type} camera code")
        return result
    except Exception as e:
        logger.error(f"Error generating code: {str(e)}")
        return {
            "code": "",
            "explanation": f"Error generating code: {str(e)}",
            "error": str(e)
        }


def extract_code_blocks(text: str) -> Dict[str, str]:
    """
    Extract code blocks from the response text.
    
    Args:
        text: Response text containing code blocks
        
    Returns:
        Dictionary mapping file names to code contents
    """
    # Pattern to match code blocks with file names
    pattern = r"```(?:kotlin|java|gradle)?\s*(?://\s*([^\n]+\.(?:kt|java|gradle))\s*)?\n(.*?)```"
    
    # Find all code blocks
    matches = re.finditer(pattern, text, re.DOTALL)
    
    code_blocks = {}
    untitled_count = 1
    
    for match in matches:
        filename = match.group(1)
        code = match.group(2).strip()
        
        # If no filename is specified, try to infer from the content
        if not filename:
            if "interface UvcCamera" in code or "interface Camera" in code:
                filename = "UvcCamera.kt"
            elif "class UvcCameraImpl" in code or "class CameraImpl" in code:
                filename = "UvcCameraImpl.kt"
            elif "class UvcCameraManager" in code or "class CameraManager" in code:
                filename = "UvcCameraManager.kt"
            elif "class UvcFrameProcessor" in code or "class FrameProcessor" in code:
                filename = "UvcFrameProcessor.kt"
            elif "plugins {" in code and ("com.android.library" in code or "kotlin-android" in code):
                filename = "build.gradle"
            else:
                filename = f"UntitledFile{untitled_count}.kt"
                untitled_count += 1
            
        code_blocks[filename] = code
    
    return code_blocks


def process_code_generation_result(response: str, code_blocks: Dict[str, str], target_package: str) -> Dict[str, Any]:
    """
    Process and organize the code generation result.
    
    Args:
        response: Full response text
        code_blocks: Extracted code blocks
        target_package: Target package name
        
    Returns:
        Processed result
    """
    # Extract explanation (text outside of code blocks)
    explanation = re.sub(r"```.*?```", "", response, flags=re.DOTALL).strip()
    
    # Create a unified code representation
    unified_code = ""
    for filename, code in code_blocks.items():
        unified_code += f"// File: {filename}\n\n{code}\n\n"
    
    result = {
        "code": unified_code,
        "explanation": explanation,
        "files": code_blocks,
        "targetPackage": target_package
    }
    
    return result


def organize_generated_files(code_blocks: Dict[str, str], output_dir: str) -> List[str]:
    """
    Organize generated files into the appropriate directory structure.
    
    Args:
        code_blocks: Dictionary mapping filenames to code content
        output_dir: Base output directory
        
    Returns:
        List of created file paths
    """
    created_files = []
    
    for filename, content in code_blocks.items():
        if filename.endswith(".kt"):
            # Kotlin files go in the src directory
            file_path = os.path.join(output_dir, "src", "main", "kotlin", filename)
        elif filename.endswith(".gradle"):
            # Gradle files go in the root
            file_path = os.path.join(output_dir, filename)
        else:
            # Other files go in the root
            file_path = os.path.join(output_dir, filename)
        
        # Create the directory if it doesn't exist
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        
        # Write the file
        with open(file_path, "w") as f:
            f.write(content)
        
        created_files.append(file_path)
    
    return created_files