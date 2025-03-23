# MCP Documentation Maintenance Guide

## Overview

This guide provides instructions for maintaining the MCP documentation system, including best practices for content creation, shortcode usage, and deployment procedures.

## Documentation System Architecture

The MCP documentation uses a dual approach:

1. **Hugo Static Site Generator**
   - Generates the final HTML site
   - Provides structure and navigation
   - Deploys to GitHub Pages

2. **Jinja2 Template System** 
   - Provides templates for standardized document creation
   - Separates content from presentation
   - Ensures consistent document structure

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
├── themes/                     # Hugo themes
│   └── mcp-theme/              # Custom MCP theme
│       └── layouts/            # Theme layouts
│           └── shortcodes/     # Hugo shortcodes
├── config/                     # Hugo configuration
└── static/                     # Static assets
```

## Shortcode System

### Available Shortcodes

The MCP documentation uses the following shortcodes:

1. **`status`**: Displays document status indicator
2. **`toc`**: Generates table of contents
3. **`callout`**: Creates styled information boxes
4. **`progress`**: Displays progress bars
5. **`related-docs`**: Lists related documents

### Shortcode Implementation

All shortcodes are implemented in the theme directory:

```
themes/mcp-theme/layouts/shortcodes/
```

These files define the HTML output for each shortcode used in content files.

## Content Maintenance Workflow

### Creating New Content

1. **Using Templates (Recommended)**
   - Choose the appropriate Jinja2 template
   - Create a data file with your content
   - Generate the document using the template system
   - Review and finalize the generated document

2. **Manual Creation**
   - Create a new markdown file in the appropriate content directory
   - Include proper front matter
   - Follow document structure standards
   - Use shortcodes consistently

### Updating Existing Content

1. **Update the source document in `content/`**
2. **Verify shortcodes are properly closed**
3. **Run verification tools**
4. **Build and test locally**
5. **Deploy when satisfied**

## Verification and Testing

### Shortcode Verification

Use the provided tools to verify shortcode integrity:

```bash
# Check for unclosed shortcodes
./find-unclosed-shortcodes-improved.sh
```

This tool will scan all content files for unclosed shortcodes and report any issues.

### Local Testing

Test the documentation site locally:

```bash
# Using Hugo directly
hugo server

# Using the containerized approach
./mcp-docs.sh hugo server
```

This starts a local server at http://localhost:1313/ where you can preview the site.

## Deployment Procedures

### Standard Deployment

The documentation can be deployed to GitHub Pages using:

```bash
# Complete deployment script with verification
./hugo-deploy.sh
```

This script:
1. Verifies shortcodes and theme setup
2. Builds the site
3. Commits to the gh-pages branch
4. Pushes to GitHub

### Deployment Flow

```
Content Changes → Verification → Local Testing → Deployment → GitHub Pages
```

## Maintenance Best Practices

### Documentation Standards

1. **Consistent Structure**
   - Follow the established document structure
   - Use proper heading hierarchy
   - Include standard sections (overview, table of contents, etc.)

2. **Front Matter**
   - Include complete front matter for all documents
   - Maintain consistent metadata fields
   - Use proper status indicators

3. **Shortcode Usage**
   - Follow the shortcode standards in `content/standards/shortcode-standards.md`
   - Always close paired shortcodes
   - Use consistent parameter formats

4. **Cross-Referencing**
   - Use Hugo-style paths without file extensions
   - Maintain bidirectional references
   - Ensure related documents are listed in front matter

### Common Issues and Solutions

1. **Hugo Build Fails**
   - Check for unclosed shortcodes
   - Verify theme is properly set up
   - Look for markdown syntax errors

2. **Shortcode Errors**
   - Ensure all required shortcodes have template files
   - Check for proper shortcode syntax
   - Verify paired shortcodes are closed

3. **Template Processing Fails**
   - Validate template data against schemas
   - Check for proper Jinja2 syntax
   - Ensure all required fields are present

## Tools Reference

| Tool | Purpose | Usage |
|------|---------|-------|
| `hugo-deploy.sh` | Deploy to GitHub Pages | `./hugo-deploy.sh` |
| `find-unclosed-shortcodes-improved.sh` | Find unclosed shortcodes | `./find-unclosed-shortcodes-improved.sh` |
| `mcp-docs.sh` | Manage Hugo site | `./mcp-docs.sh [command]` |
| `simple-template.py` | Process Jinja2 templates | `python3 simple-template.py [template] [data] [output]` |

## Maintenance Schedule

- **Daily**: Address content updates as needed
- **Weekly**: Run shortcode verification
- **Monthly**: Complete site review and validation
- **Quarterly**: Review and update standards documents

## Related Resources

- [Shortcode Usage Standards](/standards/shortcode-standards/)
- [Documentation Guidelines](/standards/documentation-guidelines/)
- [Hugo Documentation](https://gohugo.io/documentation/)
- [Jinja2 Documentation](https://jinja.palletsprojects.com/)

## Summary

Proper maintenance of the MCP documentation requires attention to both content quality and technical implementation. By following these guidelines and using the provided tools, you can ensure the documentation remains accurate, consistent, and accessible.