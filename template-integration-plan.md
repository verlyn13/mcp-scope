# Jinja2 Template Integration Plan for ScopeCam Documentation

## Overview

This document outlines the plan for integrating Jinja2 templating into the ScopeCam MCP documentation workflow. The integration will enhance the existing documentation system with template-based content generation while maintaining compatibility with the Hugo static site generator.

## Current Status Assessment

### Existing Documentation Tools

- **doc-manager.py**: Python tool that manages documentation structure, validation, and migration
- **Hugo migration**: In-progress migration of documentation to Hugo static site (Phase 3: 82% complete)
- **Containerized environment**: Development setup using podman-compose

### Current Documentation Structure

- Primary content in `/docs/` and `/mcp-project/docs/`
- Markdown files with YAML front matter
- Documentation organized by function (architecture, implementation, standards, etc.)
- Current migration to Hugo content structure in `/content/`

## Jinja2 Integration Strategy

### 1. Template Infrastructure Setup

#### Directory Structure

```
/docs/
├── tools/
│   ├── doc-manager.py               # Existing documentation manager
│   ├── template-manager.py          # New template processing tool
│   └── requirements.txt             # Python dependencies
├── templates/
│   ├── base/                        # Base templates
│   │   ├── document.j2              # Base document template
│   │   ├── architecture.j2          # Base architecture template
│   │   ├── implementation.j2        # Base implementation template
│   │   └── api.j2                   # Base API template
│   ├── components/                  # Reusable template components
│   │   ├── header.j2                # Document header
│   │   ├── footer.j2                # Document footer
│   │   ├── status.j2                # Status indicator
│   │   └── toc.j2                   # Table of contents
│   ├── architecture/                # Architecture document templates
│   │   ├── component.j2             # Architecture component template
│   │   └── decision.j2              # Architecture decision record template
│   ├── implementation/              # Implementation document templates
│   │   ├── guide.j2                 # Implementation guide template
│   │   └── example.j2               # Code example template
│   └── api/                         # API document templates
│       ├── endpoint.j2              # API endpoint template
│       └── model.j2                 # Data model template
└── template-data/                   # Data for template variables
    ├── common.yaml                  # Common variables
    ├── components/                  # Component-specific data
    ├── apis/                        # API-specific data
    └── schema/                      # Data validation schemas
```

#### Python Dependencies

```
# requirements.txt
Jinja2==3.1.2
PyYAML==6.0
MarkupSafe==2.1.3
jsonschema==4.19.0
```

### 2. Template Manager Implementation

#### Core Functionality

1. **Template Loading**: Load Jinja2 templates from the templates directory
2. **Data Loading**: Load and validate data from YAML files
3. **Variable Substitution**: Process templates with provided variables
4. **Output Generation**: Generate Markdown files with Hugo-compatible front matter
5. **Integration with doc-manager.py**: Work alongside existing documentation tools

#### Command-Line Interface

```python
"""
Template Manager for ScopeCam Documentation

This script manages Jinja2 templates for generating MCP documentation, with support for:
- Listing available templates
- Generating documents from templates
- Validating template data
- Creating new templates

Usage:
  python template-manager.py [command] [options]

Commands:
  list        List available templates
  generate    Generate document from template
  validate    Validate template data
  create      Create a new template
  help        Show this help message
"""
```

### 3. Template Development

#### Base Template Structure

```jinja
{# Base document template (document.j2) #}
---
title: "{{ title }}"
status: "{{ status | default('Draft') }}"
version: "{{ version | default('0.1') }}"
date_created: "{{ date_created | default(today) }}"
last_updated: "{{ last_updated | default(today) }}"
contributors: [
  {%- for contributor in contributors %}
  "{{ contributor }}"{% if not loop.last %},{% endif %}
  {%- endfor %}
]
related_docs:
  {%- for doc in related_docs %}
  - "{{ doc }}"
  {%- endfor %}
tags: [
  {%- for tag in tags %}
  "{{ tag }}"{% if not loop.last %},{% endif %}
  {%- endfor %}
]
---

# {{ title }}

{{"{{"}} < status > {{"}}"}}

[↩️ Back to {{ parent_section_name }}]({{ parent_section_path }}) | [↩️ Back to Documentation Index](/docs/)

## Overview

{{ overview | default('*Brief description of the document purpose.*') }}

## Table of Contents

{{"{{"}} < toc > {{"}}"}}

{% block content %}
## Main Content

*Main content goes here*
{% endblock %}

## Related Documentation

{{"{{"}} < related-docs > {{"}}"}}

{% if changelog %}
## Changelog

{% for version, changes in changelog %}
- {{ version }} ({{ changes.date }}): {{ changes.description }}
{% endfor %}
{% endif %}
```

#### Architecture Component Template

```jinja
{% extends "base/architecture.j2" %}

{% block content %}
## Core Responsibilities

{% for responsibility in responsibilities %}
- {{ responsibility }}
{% endfor %}

## Implementation Progress

| Feature | Status | Completion |
|---------|--------|------------|
{% for feature, status in implementation_status.items() %}
| {{ feature }} | {{ status.status }} | {{"{{"}} < progress value="{{ status.percentage }}" > {{"}}"}} |
{% endfor %}

## Component Architecture

```
{{ architecture_diagram }}
```

## Core Interfaces

```kotlin
{% for interface in interfaces %}
{{ interface }}
{% endfor %}
```

{# ... Additional sections ... #}
{% endblock %}
```

### 4. Integration with Existing Workflow

#### Extending doc-manager.py

Add template-related commands to doc-manager.py:

```python
# New commands in doc-manager.py
elif command == 'create-from-template':
    if len(sys.argv) < 4:
        print("ERROR: Missing arguments for create-from-template command")
        print("Usage: python doc-manager.py create-from-template TEMPLATE_NAME TARGET_PATH DATA_FILE")
        print("Example: python doc-manager.py create-from-template architecture/component docs/architecture/new-component.md template-data/components/new-component.yaml")
        return
    
    template_name = sys.argv[2]
    target_path = sys.argv[3]
    data_file = sys.argv[4] if len(sys.argv) > 4 else None
    
    # Import template_manager and use it
    from template_manager import TemplateManager
    template_mgr = TemplateManager(os.path.join(DOCS_ROOT, 'templates'))
    template_mgr.generate_document(template_name, target_path, data_file)
```

#### Integration with Hugo Generation

Modify the Hugo migration process to use templates:

```python
# In hugo-migrate.py
def convert_to_hugo_with_templates(source_path, dest_path, template_name=None):
    """Convert a document to Hugo format, optionally using a template."""
    if template_name:
        # Extract data from existing document
        with open(source_path, 'r') as f:
            content = f.read()
        front_matter = extract_front_matter(content)
        
        # Generate new document from template
        from template_manager import TemplateManager
        template_mgr = TemplateManager(os.path.join(DOCS_ROOT, 'templates'))
        template_mgr.generate_document(template_name, dest_path, data=front_matter)
    else:
        # Use regular conversion
        subprocess.run(['python3', 'docs/tools/doc-manager.py',
                       '--convert-to-hugo', source_path,
                       '--output', dest_path])
```

### 5. Jinja2 Template Editor Integration

Create a simple web-based editor for templates that:

1. Lists available templates
2. Allows editing template content
3. Provides a preview of rendered templates
4. Facilitates template data creation and validation

## Implementation Plan

### Phase 1: Foundation (2 days)

1. **Environment Setup**
   - Create requirements.txt with Jinja2 dependencies
   - Set up Python environment
   - Create basic directory structure

2. **Basic Template Manager**
   - Implement core template loading and rendering
   - Create basic CLI interface
   - Implement document generation from template

3. **Convert Existing Architecture Template**
   - Create Jinja2 version of architecture component template
   - Test template rendering with sample data

### Phase 2: Integration (3 days)

1. **Extend doc-manager.py**
   - Add template-related commands
   - Ensure compatibility with existing functionality

2. **Develop Data Schema**
   - Create JSON schemas for template data validation
   - Implement data validation in template manager

3. **Setup Hugo Integration**
   - Ensure generated content works with Hugo
   - Update Hugo migration process to use templates

### Phase 3: Content Migration (3 days)

1. **Convert Implementation Templates**
   - Create Jinja2 version of implementation guide template
   - Test with sample data

2. **Convert API Templates**
   - Create Jinja2 version of API documentation template
   - Test with sample data

3. **Update Template Data**
   - Create template data for existing documents
   - Test regeneration of existing content

### Phase 4: Workflow Optimization (2 days)

1. **Documentation**
   - Document template usage process
   - Create template development guide
   - Update contribution guidelines

2. **Automation**
   - Add CI/CD integration for template validation
   - Create pre-commit hooks for template validation

## Technical Considerations

### Template Variables

Define standard variables across all templates:

```yaml
# Common variables (common.yaml)
project_name: "ScopeCam MCP"
repository_url: "https://github.com/username/mcp-scope"
copyright_year: "2025"
status_options:
  - "Active"
  - "Draft"
  - "Review"
  - "Outdated"
  - "Archived"
navigation:
  docs_index: "/docs/"
  architecture: "/architecture/"
  implementation: "/implementation/"
  standards: "/standards/"
```

### Data Validation

Implement JSON Schema validation for template data:

```yaml
# Architecture component schema (schema/architecture-component.yaml)
type: object
required:
  - title
  - responsibilities
  - interfaces
properties:
  title:
    type: string
  responsibilities:
    type: array
    items:
      type: string
  interfaces:
    type: array
    items:
      type: string
  implementation_status:
    type: object
    additionalProperties:
      type: object
      properties:
        status:
          type: string
          enum: ["Active", "Draft", "Review", "Outdated", "Archived"]
        percentage:
          type: integer
          minimum: 0
          maximum: 100
```

### Error Handling

Implement comprehensive error handling:

1. **Template errors**: Clear error messages for template syntax issues
2. **Data validation errors**: Detailed feedback on invalid template data
3. **File operation errors**: Proper handling of file I/O issues

## Usage Examples

### Creating a New Architecture Component

```bash
# Create data file
cat > docs/template-data/components/messaging-service.yaml << EOF
title: "Messaging Service"
status: "Draft"
version: "0.1"
contributors: ["Documentation Architect"]
tags: ["architecture", "component", "messaging", "nats"]
parent_section_name: "Architecture"
parent_section_path: "/architecture/"
overview: "The Messaging Service provides reliable message handling between MCP components."
responsibilities:
  - "Message routing between agents"
  - "Handling message serialization/deserialization"
  - "Ensuring reliable message delivery"
interfaces:
  - "interface MessageService {\n    fun publishMessage(topic: String, payload: ByteArray)\n    suspend fun subscribeToTopic(topic: String): Flow<Message>\n}"
implementation_status:
  "Core Messaging": 
    status: "Active"
    percentage: 85
  "Error Handling": 
    status: "Draft"
    percentage: 50
  "Reconnection Logic": 
    status: "Draft"
    percentage: 30
EOF

# Generate document from template
python docs/tools/template-manager.py generate architecture/component content/architecture/messaging-service.md docs/template-data/components/messaging-service.yaml
```

### Updating an Existing Document

```bash
# Extract data from existing document
python docs/tools/template-manager.py extract docs/architecture/fsm-agent-interfaces.md docs/template-data/components/fsm-agent.yaml

# Edit the data file as needed

# Regenerate document with updated data
python docs/tools/template-manager.py generate architecture/component content/architecture/fsm-agent-interfaces.md docs/template-data/components/fsm-agent.yaml
```

## Conclusion

This integration plan provides a comprehensive approach to incorporating Jinja2 templating into the ScopeCam documentation workflow. By building on the existing documentation infrastructure and maintaining compatibility with Hugo, we can enhance the documentation creation process while ensuring a smooth transition to the new templating system.

The phased implementation approach allows for incremental adoption and validation of the templating system, with clear milestones and deliverables for each phase.