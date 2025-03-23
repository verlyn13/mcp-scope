# ScopeCam MCP Documentation - Hugo Site

This directory contains a Hugo-based static site implementation of the ScopeCam MCP documentation, designed for deployment on GitHub Pages.

## Quick Start

To work with this documentation site, you have several options:

### Option 1: Use the test script

```bash
# Make the script executable if not already done
chmod +x test-hugo.sh

# Run the script (requires Hugo to be installed)
./test-hugo.sh
```

### Option 2: Use Docker/Podman

```bash
# Build the container
docker build -t hugo-local -f Dockerfile.hugo .

# Run the container
docker run --rm -it -v $(pwd):/src:z -p 1313:1313 hugo-local server --bind=0.0.0.0
```

### Option 3: Use the run-hugo.sh script

```bash
# Make the script executable if not already done
chmod +x run-hugo.sh

# Run the script (works with either Docker or Podman)
./run-hugo.sh server
```

## Directory Structure

```
.
├── config/               # Hugo configuration
│   ├── _default/         # Base configuration
│   ├── development/      # Development environment settings
│   └── production/       # Production environment settings
├── content/              # Documentation content (Markdown files)
│   ├── _index.md         # Homepage
│   ├── getting-started.md # Entry point document
│   ├── project/          # Project documentation
│   ├── guides/           # Implementation guides
│   ├── architecture/     # Architecture documentation
│   ├── standards/        # Standards documentation
│   └── mcp/              # MCP-specific documentation
├── themes/               # Hugo themes
│   └── mcp-theme/        # Custom MCP theme
├── Dockerfile.hugo       # Container definition for Hugo
├── run-hugo.sh           # Script to run Hugo in container
├── test-hugo.sh          # Simple test script without containers
└── .github/workflows/    # GitHub Actions workflows
    └── hugo-deploy.yml   # Deployment workflow for GitHub Pages
```

## Adding New Content

To add new documentation:

1. Determine the appropriate section (project, guides, architecture, etc.)
2. Create a new Markdown file with proper front matter:

```yaml
---
title: "Document Title"
status: "Active"  # Active, Draft, Review, Outdated, or Archived
version: "1.0"
date_created: "YYYY-MM-DD"
last_updated: "YYYY-MM-DD"
contributors: ["Your Name"]
related_docs:
  - "/path/to/related/document/"
tags: ["tag1", "tag2"]
---

# Document Title

{{< status >}}

Your content here...
```

## Available Shortcodes

The following custom shortcodes are available:

1. **status**: Displays document status
   ```
   {{< status >}}
   ```

2. **progress**: Shows a progress bar
   ```
   {{< progress value="75" >}}
   ```

3. **related-docs**: Lists related documents
   ```
   {{< related-docs >}}
   ```

See [Hugo Shortcodes Reference](hugo-shortcodes-reference.md) for more details.

## GitHub Pages Deployment

The site is automatically deployed to GitHub Pages when changes are pushed to the main branch. The deployment workflow is defined in `.github/workflows/hugo-deploy.yml`.

To manually trigger a deployment:
1. Go to the Actions tab in the GitHub repository
2. Select the "Deploy Hugo Site to GitHub Pages" workflow
3. Click "Run workflow"

## Migration Status

The migration from the original documentation structure to Hugo is tracked in [Migration Progress](migration-progress.md).

## Documentation

For more information, refer to these documents:

- [Hugo Migration Executive Summary](hugo-migration-executive-summary.md)
- [Hugo Migration File Mapping](hugo-migration-file-mapping.md)
- [Hugo Implementation Steps](hugo-implementation-steps-update.md)
- [Hugo Theme Design](hugo-theme-design.md)
- [Documentation Compliance Check](documentation-compliance-check.md)
- [Content Inventory and Prioritization](content-inventory-and-prioritization.md)
- [Hugo Shortcodes Reference](hugo-shortcodes-reference.md)

## Troubleshooting

If you encounter issues:

1. **Hugo server not starting**: Check if Hugo is installed correctly or try using the Docker approach
2. **Missing theme components**: Ensure all theme files are in place
3. **Deployment failures**: Check the GitHub Actions logs for details
4. **Content not appearing**: Verify front matter format is correct

For detailed troubleshooting, see the [Hugo Implementation Steps](hugo-implementation-steps-update.md) document.