# MCP Documentation System

This documentation system combines Hugo static site generation with Jinja2 template-based content creation for the Multi-Agent Control Platform (MCP) project.

## Quick Start

```bash
# Check prerequisites
./mcp-docs.sh check

# Start Hugo development server
./mcp-docs.sh hugo server

# Build static site
./mcp-docs.sh hugo build

# Generate document from template
./mcp-docs.sh template generate templates/test.j2 template-data/test-data.json test-output.md

# Deploy to GitHub Pages
./mcp-docs.sh deploy
```

## Architecture

The documentation system uses a dual approach:

1. **Hugo**: Static site generator for the final documentation site
2. **Jinja2**: Template system for efficient document creation

This combination gives you both the benefits of static site generation (speed, simplicity, deployment options) and the power of template-based content creation (consistency, efficiency, reusability).

## Directory Structure

```
/                               # Root directory
├── content/                    # Hugo content
│   ├── _index.md               # Home page
│   ├── architecture/           # Architecture documentation
│   ├── guides/                 # Implementation guides
│   ├── mcp/                    # MCP-specific documentation
│   ├── project/                # Project documentation
│   ├── standards/              # Standards and guidelines
│   └── templates/              # Templates (final Hugo output)
├── templates/                  # Jinja2 templates
│   ├── base/                   # Base templates
│   ├── architecture/           # Architecture templates
│   ├── implementation/         # Implementation guides
│   ├── api/                    # API documentation
│   └── components/             # Reusable components
├── template-data/              # Data for templates
│   ├── common/                 # Common data
│   ├── components/             # Component data
│   └── schemas/                # JSON schemas
├── docs/                       # Original documentation
│   └── tools/                  # Documentation tools
├── themes/                     # Hugo themes
│   └── mcp-theme/              # Custom MCP theme
├── config/                     # Hugo configuration
├── static/                     # Static assets
├── mcp-docs.sh                 # Main documentation script
├── Dockerfile.hugo             # Hugo container definition
└── Dockerfile.template         # Template container definition
```

## Installation

### Prerequisites

1. **Local Development**:
   - Hugo (Extended) >= 0.110.0
   - Python 3.10 or newer
   - Jinja2, PyYAML, jsonschema packages

2. **Container-based Development**:
   - Docker or Podman

### Automated Setup

The `mcp-docs.sh` script can automatically check and install some dependencies:

```bash
./mcp-docs.sh check
```

This will verify if you have the necessary tools and suggest installations if needed.

### Container Setup

If you prefer to use containers (recommended for consistent environments):

```bash
# Build Hugo container
podman build -t hugo-local -f Dockerfile.hugo .

# Build Template container
podman build -t template-processor -f Dockerfile.template .
```

## Usage

### Hugo Site Management

```bash
# Start development server
./mcp-docs.sh hugo server

# Build static site
./mcp-docs.sh hugo build

# Create new content
./mcp-docs.sh hugo new path/to/new-file.md
```

### Template Processing

```bash
# List available templates
./mcp-docs.sh template list

# Generate document from template
./mcp-docs.sh template generate <template-path> <data-path> <output-path>

# Validate template data
./mcp-docs.sh template validate <data-path> [schema-path]
```

### Deployment

```bash
# Deploy to GitHub Pages
./mcp-docs.sh deploy
```

## Template System

### Template Structure

Templates are Jinja2 files with the `.j2` extension. They support:

- Template inheritance (extending base templates)
- Variable substitution
- Conditional logic
- Loops and iterations
- Macros and includes

### Data Structure

Template data is stored in YAML or JSON files, typically with this structure:

```yaml
# Basic metadata
title: "Document Title"
status: "Draft"
version: "0.1"
contributors:
  - "Author Name"
tags:
  - "tag1"
  - "tag2"

# Content-specific data
overview: "Brief description of the document purpose."
responsibilities:
  - "Responsibility 1"
  - "Responsibility 2"
implementation_status:
  "Feature 1":
    status: "Active"
    percentage: 70
```

### Creating New Documents

The general workflow for creating new documentation:

1. Choose an appropriate template
2. Create a data file with your content
3. Generate the document
4. Review and edit if needed
5. Commit to the repository

Example:

```bash
# Create data file
cat > template-data/components/my-component.yaml << EOF
title: "My Component"
status: "Draft"
version: "0.1"
contributors:
  - "Your Name"
tags:
  - "architecture"
  - "component"
overview: "Description of my component"
responsibilities:
  - "Handle important tasks"
  - "Process data efficiently"
EOF

# Generate document
./mcp-docs.sh template generate templates/architecture/component.j2 \
  template-data/components/my-component.yaml \
  content/architecture/my-component.md
```

## Best Practices

1. **Use templates for consistency**: Always use templates for new documentation to ensure consistency.

2. **Data-driven approach**: Keep content separate from presentation by storing data in YAML or JSON files.

3. **Validate before generating**: Use the validation tools to check your data before generating documents.

4. **Maintain both environments**: Keep both Hugo content and template data in sync.

5. **Regular deployments**: Deploy documentation updates regularly to keep the site current.

6. **Version control**: Commit both the generated content and the template data to version control.

## Troubleshooting

### Common Issues

1. **Hugo errors**:
   - Ensure Hugo is properly installed with the Extended version
   - Check for YAML syntax errors in front matter
   - Verify shortcode syntax

2. **Template processing errors**:
   - Check Jinja2 is installed (`pip install Jinja2`)
   - Validate template syntax
   - Ensure data files exist and have proper format

3. **Deployment issues**:
   - Verify GitHub repository permissions
   - Check GitHub Pages settings
   - Ensure gh-pages branch exists

### Getting Help

For additional assistance:

1. Check the error messages for specific issues
2. Run `./mcp-docs.sh check` to verify your environment
3. Try using the container-based approach for a consistent environment

## Easter Egg

Try running:

```bash
./mcp-docs.sh help --mcp-special
```

For a pleasant surprise! 🚀

## Advanced Topics

### Customizing Templates

To create a new template:

1. Create a base template in `templates/base/`
2. Create specialized templates that extend the base
3. Use blocks for customizable sections

Example:

```jinja
{% extends "base/document.j2" %}

{% block content %}
## Custom Content

This is the specialized content for this template.
{% endblock %}
```

### Schema Validation

Create JSON schemas in `template-data/schemas/` to validate your template data:

```json
{
  "type": "object",
  "required": ["title", "status", "version"],
  "properties": {
    "title": {
      "type": "string"
    },
    "status": {
      "type": "string",
      "enum": ["Draft", "Review", "Active", "Archived"]
    }
  }
}
```

Then validate your data:

```bash
./mcp-docs.sh template validate my-data.yaml my-schema.json
```

## Conclusion

This documentation system provides a powerful, flexible approach to maintaining the MCP project documentation. By combining Hugo and Jinja2, we get the best of both worlds: elegant presentation and efficient content creation.

The system is designed to grow with the project, providing a solid foundation for comprehensive, consistent, and maintainable documentation.