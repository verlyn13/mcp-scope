"""
Tests for the AI tools.
"""

import pytest

from python_bridge.tools.code_generation import extract_code_blocks, process_code_generation_result
from python_bridge.tools.documentation import format_markdown_documentation, extract_documentation_sections


def test_extract_code_blocks():
    """Test extracting code blocks from response text."""
    # Response with file names
    response = """
    Here's the implementation:

    ```kotlin
    // UvcFrameGrabber.kt
    package com.example.uvc

    class UvcFrameGrabber {
        fun grabFrame(): ByteArray {
            // Implementation
            return ByteArray(0)
        }
    }
    ```

    And here's the interface:

    ```kotlin
    // FrameGrabber.kt
    package com.example.uvc

    interface FrameGrabber {
        fun grabFrame(): ByteArray
    }
    ```
    """
    
    code_blocks = extract_code_blocks(response)
    
    assert len(code_blocks) == 2
    assert "UvcFrameGrabber.kt" in code_blocks
    assert "FrameGrabber.kt" in code_blocks
    assert "class UvcFrameGrabber" in code_blocks["UvcFrameGrabber.kt"]
    assert "interface FrameGrabber" in code_blocks["FrameGrabber.kt"]


def test_extract_code_blocks_no_filenames():
    """Test extracting code blocks without file names."""
    response = """
    Here's the implementation:

    ```kotlin
    class UvcFrameGrabber {
        fun grabFrame(): ByteArray {
            // Implementation
            return ByteArray(0)
        }
    }
    ```

    And here's the interface:

    ```kotlin
    interface FrameGrabber {
        fun grabFrame(): ByteArray
    }
    ```
    """
    
    code_blocks = extract_code_blocks(response)
    
    assert len(code_blocks) == 2
    assert "UntitledFile1.kt" in code_blocks
    assert "UntitledFile2.kt" in code_blocks
    assert "class UvcFrameGrabber" in code_blocks["UntitledFile1.kt"]
    assert "interface FrameGrabber" in code_blocks["UntitledFile2.kt"]


def test_process_code_generation_result():
    """Test processing code generation results."""
    response = """
    # UVC Frame Grabber Implementation

    This implementation provides a basic UVC frame grabber.

    ```kotlin
    // UvcFrameGrabber.kt
    package com.example.uvc

    class UvcFrameGrabber {
        fun grabFrame(): ByteArray {
            // Implementation
            return ByteArray(0)
        }
    }
    ```
    """
    
    code_blocks = extract_code_blocks(response)
    result = process_code_generation_result(response, code_blocks, "com.example.uvc")
    
    assert "code" in result
    assert "explanation" in result
    assert "files" in result
    assert "targetPackage" in result
    assert "UVC Frame Grabber Implementation" in result["explanation"]
    assert "// File: UvcFrameGrabber.kt" in result["code"]
    assert "UvcFrameGrabber.kt" in result["files"]
    assert result["targetPackage"] == "com.example.uvc"


def test_format_markdown_documentation():
    """Test formatting Markdown documentation."""
    # Test with proper formatting
    doc = """
    # API Documentation

    ## Overview
    This is an overview.

    ## Methods
    - grabFrame(): Grabs a frame.
    """
    
    formatted = format_markdown_documentation(doc)
    
    assert "# API Documentation" in formatted
    assert "## Overview" in formatted
    assert "## Methods" in formatted
    
    # Test with improper formatting (indented headers)
    doc = """
      # API Documentation

      ## Overview
    This is an overview.

      ## Methods
    - grabFrame(): Grabs a frame.
    """
    
    formatted = format_markdown_documentation(doc)
    
    assert "# API Documentation" in formatted
    assert "## Overview" in formatted
    assert "## Methods" in formatted


def test_extract_documentation_sections():
    """Test extracting documentation sections."""
    doc = """
    # API Documentation

    This is the main documentation.

    ## Overview
    
    This is an overview.

    ## Methods
    
    - grabFrame(): Grabs a frame.
    """
    
    sections = extract_documentation_sections(doc, "markdown")
    
    assert "API Documentation" in sections
    assert "Overview" in sections
    assert "Methods" in sections
    assert "full" in sections
    assert "This is an overview." in sections["Overview"]
    assert "grabFrame()" in sections["Methods"]