"""
Documentation Generation Tool

This module provides tools for generating documentation for code
using smolagents framework.
"""

import re
from typing import Any, Dict, List, Optional

from loguru import logger
from smolagents import CodeAgent


async def generate_documentation(agent: CodeAgent, prompt: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate documentation for provided code using smolagents.
    
    Args:
        agent: CodeAgent instance
        prompt: Task prompt
        params: Task parameters
        
    Returns:
        Dictionary containing generated documentation
    """
    logger.info(f"Generating documentation in format: {params['targetFormat']}")
    
    # Extract parameters
    code = params["code"]
    target_format = params["targetFormat"].lower()
    doc_type = params["docType"].lower()
    
    # Enhance prompt with documentation-specific guidance
    enhanced_prompt = f"""
    {prompt}
    
    ## Documentation Guidelines
    
    For {doc_type} documentation in {target_format} format, please follow these guidelines:
    
    1. Provide clear descriptions of classes, methods, and parameters
    2. Explain the purpose and behavior of the code
    3. Include usage examples where appropriate
    4. Document any exceptions or errors that might occur
    5. Follow standard conventions for {target_format}
    
    For Kotlin code, follow KDoc conventions. For Java code, follow JavaDoc conventions.
    If generating Markdown, use proper headings, code blocks, and formatting.
    
    The documentation should be comprehensive but concise, focusing on what developers need to know.
    """
    
    # Use template-based generation for specific formats and types
    if target_format in ["kdoc", "javadoc"] and doc_type in ["uvc", "camera"]:
        return generate_from_template(code, target_format, doc_type)
    
    # Otherwise, use AI-based generation
    return await generate_from_ai(agent, enhanced_prompt, code, target_format, doc_type)


def generate_from_template(code: str, target_format: str, doc_type: str) -> Dict[str, Any]:
    """
    Generate documentation using templates.
    
    Args:
        code: Code to document
        target_format: Target documentation format
        doc_type: Type of documentation
        
    Returns:
        Documentation result
    """
    logger.info(f"Using templates for {doc_type} documentation in {target_format} format")
    
    # Parse the code to identify classes, methods, etc.
    class_names = extract_class_names(code)
    methods = extract_methods(code)
    interfaces = extract_interfaces(code)
    
    # Generate documentation based on the format
    if target_format == "kdoc":
        documentation = generate_kdoc(code, class_names, methods, interfaces, doc_type)
    elif target_format == "javadoc":
        documentation = generate_javadoc(code, class_names, methods, interfaces, doc_type)
    else:
        documentation = generate_markdown(code, class_names, methods, interfaces, doc_type)
    
    # Generate explanatory text
    explanation = f"""
# Documentation Generation

I've generated {doc_type} documentation in {target_format} format for the provided code.
The documentation follows standard conventions and includes detailed descriptions of:

- Classes and interfaces
- Methods and parameters
- Return values
- Exceptions

## Documentation Format

The documentation is formatted according to {target_format.upper()} standards and includes:

- Class/interface descriptions
- Method descriptions with parameter details
- Usage examples
- Error handling notes

## Usage

For {target_format.upper()} documentation, add it directly to your code files.
"""

    result = {
        "documentation": documentation,
        "format": target_format,
        "explanation": explanation,
        "docType": doc_type
    }
    
    return result


async def generate_from_ai(
    agent: CodeAgent, 
    prompt: str, 
    code: str, 
    target_format: str, 
    doc_type: str
) -> Dict[str, Any]:
    """
    Generate documentation using AI model.
    
    Args:
        agent: CodeAgent instance
        prompt: Enhanced prompt
        code: Code to document
        target_format: Target documentation format
        doc_type: Type of documentation
        
    Returns:
        Documentation result
    """
    logger.info(f"Using AI for {doc_type} documentation in {target_format} format")
    
    # Create a custom prompt based on the code and format
    ai_prompt = f"""
# Documentation Generation Task

## Code to Document
```kotlin
{code}
```

## Documentation Format
{target_format.upper()}

## Documentation Type
{doc_type.upper()}

## Task
Generate comprehensive documentation for the provided code in {target_format.upper()} format.
The documentation should:

1. Follow standard {target_format.upper()} conventions
2. Explain the purpose and behavior of classes and methods
3. Document parameters, return values, and exceptions
4. Include usage examples where appropriate
5. Be clear, concise, and developer-friendly

If generating KDoc or JavaDoc, format the output as comment blocks that can be directly inserted
into the code. If generating Markdown, use proper headings, code blocks, and formatting.
"""
    
    # Execute the agent
    try:
        # Send the prompt to the AI model
        response = await agent.run(ai_prompt)
        
        # Process the result based on the target format
        result = process_documentation_result(response, target_format, doc_type)
        
        logger.info(f"Successfully generated {doc_type} documentation in {target_format} format")
        return result
    except Exception as e:
        logger.error(f"Error generating documentation: {str(e)}")
        return {
            "documentation": "",
            "format": target_format,
            "error": str(e),
            "docType": doc_type
        }


def process_documentation_result(response: str, target_format: str, doc_type: str) -> Dict[str, Any]:
    """
    Process and format the documentation generation result.
    
    Args:
        response: Full response text from the AI model
        target_format: Target documentation format
        doc_type: Type of documentation
        
    Returns:
        Processed documentation result
    """
    # Clean up the response
    cleaned_response = response.strip()
    
    # Extract the actual documentation (might be in code blocks)
    doc_pattern = r"```(?:kotlin|java|markdown)?\s*(.*?)```"
    doc_matches = re.findall(doc_pattern, cleaned_response, re.DOTALL)
    
    if doc_matches:
        # Join all doc blocks if there are multiple
        documentation = "\n\n".join([match.strip() for match in doc_matches])
    else:
        # If no doc blocks, use the entire response
        documentation = cleaned_response
    
    # For specific formats, apply post-processing
    if target_format == "markdown":
        # Ensure proper markdown formatting
        documentation = format_markdown_documentation(documentation)
    elif target_format in ["kdoc", "javadoc"]:
        # Extract and format code documentation
        documentation = format_code_documentation(documentation, target_format)
    
    # Prepare result
    explanation = re.sub(r"```.*?```", "", response, flags=re.DOTALL).strip()
    
    result = {
        "documentation": documentation,
        "format": target_format,
        "explanation": explanation,
        "docType": doc_type,
        "sections": extract_documentation_sections(documentation, target_format)
    }
    
    return result


def format_markdown_documentation(text: str) -> str:
    """
    Format documentation as Markdown.
    
    Args:
        text: Raw documentation text
        
    Returns:
        Formatted Markdown documentation
    """
    # Ensure headers start at the beginning of line
    text = re.sub(r'^(\s+)(#+\s)', r'\2', text, flags=re.MULTILINE)
    
    # Fix code blocks
    if not re.search(r'```', text):
        # Add proper code blocks if missing
        text = re.sub(r'(?m)^( {4,}|\t+)(.+)$', r'```kotlin\n\2\n```', text)
    
    # Ensure there's a top-level header
    if not re.match(r'^#\s', text):
        lines = text.split('\n')
        for i, line in enumerate(lines):
            if re.match(r'^##\s', line):
                # Found a second-level header, insert a top-level header before it
                lines.insert(i, "# Documentation")
                text = '\n'.join(lines)
                break
        else:
            # No second-level header found, add a top-level header at the beginning
            text = "# Documentation\n\n" + text
    
    return text


def format_code_documentation(text: str, doc_format: str) -> str:
    """
    Format documentation as KDoc or JavaDoc.
    
    Args:
        text: Raw documentation text
        doc_format: Documentation format (kdoc or javadoc)
        
    Returns:
        Formatted code documentation
    """
    # Remove markdown-style headers if present
    text = re.sub(r'^#+\s+(.*?)$', r'* \1:', text, flags=re.MULTILINE)
    
    # Format as KDoc/JavaDoc if not already formatted
    if not text.strip().startswith("/**") and not text.strip().startswith("/*"):
        # Split into paragraphs
        paragraphs = text.split("\n\n")
        formatted_text = []
        
        for paragraph in paragraphs:
            # Format each paragraph
            lines = paragraph.strip().split("\n")
            formatted_paragraph = " * " + lines[0]
            
            for line in lines[1:]:
                formatted_paragraph += "\n * " + line
            
            formatted_text.append(formatted_paragraph)
        
        # Join the formatted paragraphs
        combined = "\n *\n".join(formatted_text)
        text = "/**\n" + combined + "\n */"
    
    return text


def extract_documentation_sections(documentation: str, target_format: str) -> Dict[str, str]:
    """
    Extract sections from the documentation.
    
    Args:
        documentation: Documentation text
        target_format: Documentation format
        
    Returns:
        Dictionary of section names and contents
    """
    sections = {}
    
    if target_format == "markdown":
        # Extract markdown sections based on headers
        section_pattern = r'^(#+)\s+(.*?)$(.*?)(?=^#+\s+|\Z)'
        matches = re.finditer(section_pattern, documentation, re.MULTILINE | re.DOTALL)
        
        for match in matches:
            level = len(match.group(1))
            title = match.group(2).strip()
            content = match.group(3).strip()
            sections[title] = content
    elif target_format in ["kdoc", "javadoc"]:
        # Extract sections from KDoc/JavaDoc based on tags
        tag_pattern = r'@(\w+)\s+(.*?)(?=@\w+\s+|\*/|\Z)'
        matches = re.finditer(tag_pattern, documentation, re.DOTALL)
        
        for match in matches:
            tag = match.group(1).strip()
            content = match.group(2).strip()
            sections[tag] = content
    
    # Add the full documentation as a special section
    sections["full"] = documentation
    
    return sections


def extract_class_names(code: str) -> List[str]:
    """
    Extract class names from the code.
    
    Args:
        code: Source code
        
    Returns:
        List of class names
    """
    pattern = r'(?:public\s+)?(?:abstract\s+)?class\s+(\w+)'
    return re.findall(pattern, code)


def extract_methods(code: str) -> List[Dict[str, str]]:
    """
    Extract methods from the code.
    
    Args:
        code: Source code
        
    Returns:
        List of method information dictionaries
    """
    # Find methods with return type, name, and parameters
    pattern = r'(?:public|private|protected)?\s+(?:fun|void|\w+(?:<.+?>)?)\s+(\w+)\s*\((.*?)\)(?:\s*:\s*(\w+(?:<.+?>)?))?\s*(?:\{|=)'
    
    methods = []
    for match in re.finditer(pattern, code, re.DOTALL):
        method_name = match.group(1)
        parameters = match.group(2).strip() if match.group(2) else ""
        return_type = match.group(3) if match.group(3) else "void"
        
        methods.append({
            "name": method_name,
            "parameters": parameters,
            "return_type": return_type
        })
    
    return methods


def extract_interfaces(code: str) -> List[str]:
    """
    Extract interface names from the code.
    
    Args:
        code: Source code
        
    Returns:
        List of interface names
    """
    pattern = r'(?:public\s+)?interface\s+(\w+)'
    return re.findall(pattern, code)


def generate_kdoc(
    code: str, 
    class_names: List[str], 
    methods: List[Dict[str, str]], 
    interfaces: List[str],
    doc_type: str
) -> str:
    """
    Generate KDoc documentation.
    
    Args:
        code: Source code
        class_names: List of class names
        methods: List of method information
        interfaces: List of interface names
        doc_type: Type of documentation
        
    Returns:
        KDoc documentation
    """
    documentation = []
    
    # Generate documentation for classes
    for class_name in class_names:
        class_doc = f"""
/**
 * {class_name} class for {doc_type} functionality.
 *
 * This class provides implementation for {doc_type}-related operations
 * such as device communication, frame processing, and error handling.
 *
 * @property usbManager USB manager for device access
 */
"""
        documentation.append(class_doc)
    
    # Generate documentation for interfaces
    for interface_name in interfaces:
        interface_doc = f"""
/**
 * Interface for {doc_type} functionality.
 *
 * This interface defines the contract for {doc_type} implementations,
 * including device initialization, streaming, and resource management.
 */
"""
        documentation.append(interface_doc)
    
    # Generate documentation for methods
    for method in methods:
        method_doc = f"""
/**
 * {method['name'].capitalize()} operation.
 *
 * @param {method['parameters']} Parameters for the operation
 * @return {method['return_type']} Result of the operation
 * @throws IllegalArgumentException If invalid parameters are provided
 * @throws IllegalStateException If operation is called in an invalid state
 */
"""
        documentation.append(method_doc)
    
    return "\n".join(documentation)


def generate_javadoc(
    code: str, 
    class_names: List[str], 
    methods: List[Dict[str, str]], 
    interfaces: List[str],
    doc_type: str
) -> str:
    """
    Generate JavaDoc documentation.
    
    Args:
        code: Source code
        class_names: List of class names
        methods: List of method information
        interfaces: List of interface names
        doc_type: Type of documentation
        
    Returns:
        JavaDoc documentation
    """
    # JavaDoc is similar to KDoc in format
    return generate_kdoc(code, class_names, methods, interfaces, doc_type)


def generate_markdown(
    code: str, 
    class_names: List[str], 
    methods: List[Dict[str, str]], 
    interfaces: List[str],
    doc_type: str
) -> str:
    """
    Generate Markdown documentation.
    
    Args:
        code: Source code
        class_names: List of class names
        methods: List of method information
        interfaces: List of interface names
        doc_type: Type of documentation
        
    Returns:
        Markdown documentation
    """
    documentation = [f"# {doc_type.upper()} API Documentation\n"]
    
    # Add overview
    documentation.append(f"""
## Overview

This document provides comprehensive documentation for the {doc_type.upper()} API.
The API enables developers to integrate {doc_type} functionality into their applications.
""")
    
    # Add interfaces
    if interfaces:
        documentation.append("## Interfaces\n")
        for interface_name in interfaces:
            documentation.append(f"""
### {interface_name}

Interface for {doc_type} functionality. Defines the contract for {doc_type} implementations,
including device initialization, streaming, and resource management.
""")
    
    # Add classes
    if class_names:
        documentation.append("## Classes\n")
        for class_name in class_names:
            documentation.append(f"""
### {class_name}

Class for {doc_type} functionality. Provides implementation for {doc_type}-related operations
such as device communication, frame processing, and error handling.
""")
    
    # Add methods
    if methods:
        documentation.append("## Methods\n")
        for method in methods:
            documentation.append(f"""
### {method['name']}

**Parameters:**
- {method['parameters']}

**Returns:** {method['return_type']}

**Description:**
Performs {method['name']} operation for the {doc_type} functionality.

**Exceptions:**
- `IllegalArgumentException`: If invalid parameters are provided
- `IllegalStateException`: If operation is called in an invalid state
""")
    
    # Add usage examples
    documentation.append(f"""
## Usage Examples

```kotlin
// Initialize the {doc_type} functionality
val manager = {doc_type.capitalize()}Manager(context)
val device = manager.getAvailableDevices().first()

// Open and configure
val camera = manager.openCamera(device)
camera.setResolution(1280, 720)

// Start operations
camera.startPreview()

// Perform actions
val result = camera.captureImage()

// Clean up
camera.stopPreview()
camera.release()
```
""")
    
    return "\n".join(documentation)