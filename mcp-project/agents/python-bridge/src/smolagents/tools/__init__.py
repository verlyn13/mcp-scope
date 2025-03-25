"""
Smolagents Tools Package

This package contains custom tools for the smolagents framework,
providing specialized functionality for camera integration tasks.
"""

from .code_generation import generate_uvc_camera_code
from .documentation import generate_documentation
from .uvc_analysis import analyze_uvc_device

__all__ = [
    "generate_uvc_camera_code",
    "generate_documentation",
    "analyze_uvc_device"
]