#!/usr/bin/env python3
"""
Template Manager for MCP Documentation

This script manages Jinja2 templates for generating MCP documentation, with support for:
- Listing available templates
- Generating documents from templates
- Validating template data
- Creating new templates
- Extracting data from existing documents

Usage:
  python template-manager.py [command] [options]

Commands:
  list        List available templates
  generate    Generate document from template
  validate    Validate template data
  extract     Extract data from existing document
  create      Create a new template
  help        Show this help message
"""

import os
import sys
import re
import yaml
import json
import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional, Union

try:
    from jinja2 import Environment, FileSystemLoader, select_autoescape
    from jinja2.exceptions import TemplateError
    import jsonschema
except ImportError:
    print("ERROR: Required dependencies not found. Please install with:")
    print("pip install Jinja2 PyYAML jsonschema")
    sys.exit(1)

# Configuration
TEMPLATES_DIR = Path(os.path.dirname(os.path.abspath(__file__))).parent.parent / "templates"
TEMPLATE_DATA_DIR = Path(os.path.dirname(os.path.abspath(__file__))).parent.parent / "template-data"
SCHEMAS_DIR = TEMPLATE_DATA_DIR / "schemas"
CONTENT_DIR = Path(os.path.dirname(os.path.abspath(__file__))).parent.parent / "content"
FRONT_MATTER_PATTERN = re.compile(r'^---\s*\n(.*?)\n---\s*\n', re.DOTALL)
TODAY = datetime.date.today().strftime('%Y-%m-%d')