#!/usr/bin/env python3
"""
Simple Template Test for MCP Documentation

This script is a simplified version of the template manager for testing.
It doesn't include all the features but tests the basic Jinja2 functionality.

Usage: python simple-template.py <template-file> <data-file> <output-file>
"""

import sys
import os
import json
import yaml
import datetime
from pathlib import Path

try:
    from jinja2 import Environment, FileSystemLoader, Template
except ImportError:
    print("ERROR: Jinja2 not found. Install with: pip install Jinja2")
    sys.exit(1)

def main():
    if len(sys.argv) != 4:
        print("Usage: python simple-template.py <template-file> <data-file> <output-file>")
        sys.exit(1)
    
    template_file = sys.argv[1]
    data_file = sys.argv[2]
    output_file = sys.argv[3]
    
    # Load template directly from file
    try:
        with open(template_file, 'r', encoding='utf-8') as f:
            template_content = f.read()
        template = Template(template_content)
    except Exception as e:
        print(f"ERROR: Failed to load template from {template_file}: {e}")
        sys.exit(1)
    
    # Set global variables
    template.globals['today'] = datetime.date.today().strftime('%Y-%m-%d')
    
    # Load data
    try:
        with open(data_file, 'r', encoding='utf-8') as f:
            if data_file.endswith('.json'):
                data = json.load(f)
            elif data_file.endswith('.yaml') or data_file.endswith('.yml'):
                data = yaml.safe_load(f)
            else:
                print(f"ERROR: Unsupported data file format: {data_file}")
                sys.exit(1)
    except Exception as e:
        print(f"ERROR: Failed to load data from {data_file}: {e}")
        sys.exit(1)
    
    # Render template
    try:
        output = template.render(**data)
    except Exception as e:
        print(f"ERROR: Failed to render template: {e}")
        sys.exit(1)
    
    # Write output
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(output)
        print(f"✅ Generated document: {output_file}")
    except Exception as e:
        print(f"ERROR: Failed to write output: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()