---
title: "Hugo Migration Implementation Steps"
status: "Active"
version: "1.1"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/project/documentation-directory-structure.md"
  - "/docs/standards/documentation-guidelines.md"
  - "/docs/guides/containerized-dev-environment.md"
  - "/hugo-site-plan.md"
  - "/hugo-containerized-setup.md"
  - "/github-workflow-setup.md"
tags: ["documentation", "hugo", "implementation", "integration", "containerization"]
---

# Hugo Migration Implementation Steps

🟢 **Active**

[↩️ Back to Hugo Migration Executive Summary](/hugo-migration-executive-summary.md)

## Overview

This document provides a detailed, step-by-step guide for implementing the ScopeCam MCP documentation migration to Hugo. The implementation process is designed to integrate seamlessly with the project's existing containerized development environment and automation frameworks.

## Prerequisites

- Access to the ScopeCam MCP repository
- Familiarity with the [Containerized Development Environment](/docs/guides/containerized-dev-environment.md)
- Docker or Podman installed locally
- Basic understanding of Hugo
- Git and GitHub access

## Phase 1: Foundation Setup

### 1.1 Container Setup

Instead of installing Hugo directly, we'll set up a containerized environment:

```bash
# Create the Hugo Dockerfile
cat > Dockerfile.hugo << EOF
FROM klakegg/hugo:ext-alpine-ci AS hugo-dev

# Install additional tools
RUN apk add --no-cache git nodejs npm python3 py3-pip

# Install Python dependencies for doc tooling
COPY docs/tools/requirements.txt /tmp/
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Set up working directory
WORKDIR /src

# Default to development server
ENTRYPOINT ["hugo"]
CMD ["server", "--bind=0.0.0.0", "--buildDrafts", "--buildFuture", "--disableFastRender"]
EOF

# Add Hugo service to podman-compose.yml
cat >> podman-compose.yml << EOF
  docs:
    build:
      context: .
      dockerfile: Dockerfile.hugo
    ports:
      - "1313:1313"
    volumes:
      - .:/src:z
    environment:
      - HUGO_ENVIRONMENT=development
      - HUGO_BASEURL=http://localhost:1313/
    networks:
      - mcp-network
EOF
```

### 1.2 Create Hugo Project Structure

```bash
# Create Hugo project structure within container
podman-compose run --rm docs hugo new site hugo-docs
mv hugo-docs/* .
rm -rf hugo-docs

# Initialize Git repository for theme management
git init
```

### 1.3 Configure Theme

```bash
# Add a documentation-focused theme like Docsy
git submodule add https://github.com/google/docsy.git themes/docsy

# Or create a custom theme
podman-compose run --rm docs hugo new theme mcp-theme
```

### 1.4 Configure Hugo

Create the Hugo configuration following the project's multi-environment pattern:

```bash
# Create config directory structure
mkdir -p config/_default config/development config/production

# Create base configuration
cat > config/_default/config.toml << EOF
baseURL = "https://example.github.io/mcp-scope/"
languageCode = "en-us"
title = "ScopeCam MCP Documentation"
theme = "mcp-theme"
enableGitInfo = true
enableEmoji = true

# Configure taxonomies
[taxonomies]
  tag = "tags"
  status = "status"
  contributor = "contributors"
EOF

# Create environment-specific configurations
cat > config/development/config.toml << EOF
baseURL = "http://localhost:1313/"
buildDrafts = true
buildFuture = true
EOF

cat > config/production/config.toml << EOF
baseURL = "https://example.github.io/mcp-scope/"
buildDrafts = false
buildFuture = false
minify = true
EOF
```

### 1.5 Set Up Directory Structure

Create the content structure matching the current documentation organization:

```bash
# Create content directories using the containerized environment
podman-compose run --rm docs hugo new content/_index.md
podman-compose run --rm docs hugo new content/project/_index.md
podman-compose run --rm docs hugo new content/guides/_index.md
podman-compose run --rm docs hugo new content/architecture/_index.md
podman-compose run --rm docs hugo new content/standards/_index.md
podman-compose run --rm docs hugo new content/templates/_index.md
podman-compose run --rm docs hugo new content/mcp/_index.md
podman-compose run --rm docs hugo new content/mcp/docs/_index.md
podman-compose run --rm docs hugo new content/mcp/architecture/_index.md
podman-compose run --rm docs hugo new content/mcp/implementation/_index.md
```

## Phase 2: Content Migration

### 2.1 Extend doc-manager.py for Hugo Support

Add Hugo functionality to the existing documentation management tool:

```bash
# Navigate to tools directory
cd docs/tools

# Create a backup of the original script
cp doc-manager.py doc-manager.py.bak

# Add Hugo support to doc-manager.py
cat >> doc-manager.py << EOF

# Hugo support functions
def convert_to_hugo(md_file, output_path):
    """Convert markdown file to Hugo format."""
    with open(md_file, 'r') as f:
        content = f.read()
    
    # Process front matter
    # Update internal links
    # Handle README.md to _index.md conversion
    
    with open(output_path, 'w') as f:
        f.write(content)
    
    print(f"Converted {md_file} to {output_path}")

def validate_hugo_content():
    """Validate Hugo content structure and front matter."""
    # Check front matter
    # Validate internal links
    # Ensure proper index files exist
    
    print("Hugo content validation complete")

# Add command line arguments for Hugo operations
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--convert-to-hugo', help='Convert markdown to Hugo format')
    parser.add_argument('--validate-hugo', action='store_true', help='Validate Hugo content')
    # ... existing arguments ...
    
    args = parser.parse_args()
    
    if args.convert_to_hugo:
        convert_to_hugo(args.convert_to_hugo, args.output or args.convert_to_hugo)
    elif args.validate_hugo:
        validate_hugo_content()
    # ... existing command handling ...
EOF
```

### 2.2 Add a Migration Script

Create a migration script that utilizes the extended doc-manager.py:

```bash
cat > docs/tools/hugo-migrate.py << EOF
#!/usr/bin/env python3

import os
import re
import shutil
import yaml
import subprocess
from pathlib import Path

# Define paths
SOURCE_ROOT = Path('/home/verlyn13/Projects/mcp-scope')
HUGO_ROOT = Path('.')
CONTENT_DIR = HUGO_ROOT / 'content'

# Load path mapping from file
def load_path_mapping():
    mapping = {}
    # Parse the hugo-migration-file-mapping.md file
    # and create a dictionary of paths
    return mapping

# Convert README.md to _index.md
def convert_readme_to_index(source_path, dest_path):
    subprocess.run(['python3', 'docs/tools/doc-manager.py', 
                   '--convert-to-hugo', source_path, 
                   '--output', dest_path])

# Update internal links
def update_internal_links(content, path_mapping):
    # Replace links based on path mapping
    return content

# Main migration function
def migrate_content():
    path_mapping = load_path_mapping()
    
    # Process each mapped file
    for source_path, hugo_path in path_mapping.items():
        source_file = SOURCE_ROOT / source_path.lstrip('/')
        dest_file = CONTENT_DIR / hugo_path.lstrip('/')
        
        # Ensure directory exists
        os.makedirs(dest_file.parent, exist_ok=True)
        
        # Handle README.md files
        if source_file.name == 'README.md':
            convert_readme_to_index(source_file, dest_file)
        else:
            # Copy and transform regular files
            subprocess.run(['python3', 'docs/tools/doc-manager.py', 
                           '--convert-to-hugo', str(source_file), 
                           '--output', str(dest_file)])

if __name__ == '__main__':
    migrate_content()
    # Validate the migration
    subprocess.run(['python3', 'docs/tools/doc-manager.py', '--validate-hugo'])
EOF

chmod +x docs/tools/hugo-migrate.py
```

### 2.3 Execute Content Migration

Run the migration script in the containerized environment:

```bash
# Start the docs container
podman-compose up -d docs

# Execute the migration script
podman-compose exec docs python3 docs/tools/hugo-migrate.py

# Verify migration results
podman-compose exec docs hugo check
```

### 2.4 Manual Content Refinement

After automated migration, perform these manual checks within the container:

```bash
# Enter the container for manual editing
podman-compose exec docs /bin/sh

# Fix any issues identified by validation
python3 docs/tools/doc-manager.py --validate-hugo --fix
```

## Phase 3: Theme Development

### 3.1 Implement Base Theme Components

Create custom theme components that match the project's styling:

```bash
# Create the status shortcode
mkdir -p layouts/shortcodes
cat > layouts/shortcodes/status.html << EOF
{{ \$status := .Get 0 | default (.Page.Params.status) }}
{{ if eq \$status "Active" }}
  <span class="status status-active">🟢 Active</span>
{{ else if eq \$status "Draft" }}
  <span class="status status-draft">🟡 Draft</span>
{{ else if eq \$status "Review" }}
  <span class="status status-review">🟠 Review</span>
{{ else if eq \$status "Outdated" }}
  <span class="status status-outdated">🔴 Outdated</span>
{{ else if eq \$status "Archived" }}
  <span class="status status-archived">⚫ Archived</span>
{{ end }}
EOF
```

### 3.2 Implement Layer Navigation

Create navigation components for the dual-layer structure:

```bash
mkdir -p layouts/partials
cat > layouts/partials/layer-navigation.html << EOF
<div class="layer-switch">
  <button class="layer-button {{ if eq .Site.Params.currentLayer "root" }}active{{ end }}" 
          data-layer="root">
    Root Documentation
  </button>
  <button class="layer-button {{ if eq .Site.Params.currentLayer "mcp" }}active{{ end }}" 
          data-layer="mcp">
    MCP Documentation
  </button>
</div>
EOF
```

### 3.3 Add Theme Customization

Create theme styling that matches the project's visual identity:

```bash
mkdir -p assets/scss
cat > assets/scss/main.scss << EOF
// Import variables
@import "variables";

// Import status styles
@import "status";

// Import layout components
@import "layout";

// Import dual-layer navigation styles
@import "layer-navigation";

// Import responsive styles
@import "responsive";
EOF
```

## Phase 4: Integration with Development Environment

### 4.1 Set Up Automated Validation

Create validation actions as part of the CI pipeline:

```bash
mkdir -p .github/workflows
cat > .github/workflows/docs-validation.yml << EOF
name: Docs Validation

on:
  pull_request:
    paths:
      - 'content/**'
      - 'layouts/**'
      - 'static/**'
      - 'config/**'
      - 'themes/**'
      - 'assets/**'

jobs:
  validate-docs:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          submodules: recursive
      
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.110.0'
          extended: true
      
      - name: Validate front matter
        run: python docs/tools/doc-manager.py --validate-hugo
      
      - name: Build site
        run: hugo --minify
      
      - name: Check links
        run: |
          pip install linkchecker
          linkchecker public/
EOF
```

### 4.2 Set Up Health Monitoring Integration

Create a health check module for documentation:

```bash
cat > mcp-project/mcp-core/src/main/kotlin/com/example/mcp/health/DocumentationHealthCheck.kt << EOF
package com.example.mcp.health

import java.io.File
import java.time.Instant
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit

/**
 * Health check for documentation status
 */
class DocumentationHealthCheck {

    /**
     * Check documentation health
     * @return HealthStatus for documentation
     */
    fun check(): HealthStatus {
        val lastBuildTimestamp = getLastBuildTimestamp()
        val buildAge = ChronoUnit.HOURS.between(lastBuildTimestamp, Instant.now())
        
        val status = when {
            buildAge < 24 -> HealthStatus.HEALTHY
            buildAge < 72 -> HealthStatus.DEGRADED
            else -> HealthStatus.CRITICAL
        }
        
        val message = "Documentation last built $buildAge hours ago"
        
        return HealthStatus(
            component = "documentation",
            status = status,
            message = message,
            timestamp = System.currentTimeMillis()
        )
    }
    
    private fun getLastBuildTimestamp(): Instant {
        // Implementation would check the timestamp of the last successful build
        // For now, return current time
        return Instant.now()
    }
}
EOF
```

### 4.3 Update Existing Documentation References

Update any references to documentation in existing code:

```bash
# Update README.md to reference the new documentation site
sed -i 's|Comprehensive documentation is available in the `mcp-project/docs` directory|Comprehensive documentation is available on our [documentation site](https://example.github.io/mcp-scope/)|g' README.md
```

## Phase 5: Testing & Deployment

### 5.1 Local Testing

Test the site in the containerized environment:

```bash
# Start Hugo development server
podman-compose up -d docs

# Access the site at http://localhost:1313
```

### 5.2 GitHub Pages Setup

Configure GitHub repository for GitHub Pages deployment:

1. Go to repository Settings > Pages
2. Set Source to "GitHub Actions"

### 5.3 Set Up GitHub Actions for Deployment

```bash
cat > .github/workflows/hugo-deploy.yml << EOF
name: Deploy Hugo Site to GitHub Pages

on:
  push:
    branches:
      - main
    paths:
      - 'content/**'
      - 'layouts/**'
      - 'static/**'
      - 'config/**'
      - 'themes/**'
      - 'assets/**'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

defaults:
  run:
    shell: bash

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.110.0'
          extended: true

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v3

      - name: Build with Hugo
        env:
          HUGO_ENVIRONMENT: production
        run: hugo --minify --baseURL "${{ steps.pages.outputs.base_url }}/"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
EOF
```

### 5.4 Initial Deployment

Trigger the initial deployment:

```bash
# Commit all changes
git add .
git commit -m "Implement Hugo documentation site"

# Push to GitHub to trigger deployment
git push origin main
```

## Phase 6: Post-Migration Tasks

### 6.1 Documentation Updates

Create guides for contributing to the new documentation system:

```bash
# Create a guide for documentation contributors
podman-compose exec docs hugo new content/guides/documentation-contribution-guide.md
```

### 6.2 Automation Updates

Update existing automation scripts to include documentation:

```bash
# Update build scripts to include documentation validation
echo 'echo "Validating documentation..."' >> scripts/pre-commit.sh
echo 'python docs/tools/doc-manager.py --validate-hugo || exit 1' >> scripts/pre-commit.sh
```

### 6.3 Training and Knowledge Transfer

Create training materials for the team:

```bash
# Create documentation workshop materials
podman-compose exec docs hugo new content/guides/hugo-documentation-workshop.md
```

## Maintenance Plan

### Regular Updates

Establish a process for keeping documentation up to date:

1. Include documentation updates in the Definition of Done for all tasks
2. Schedule regular documentation reviews
3. Use the health monitoring system to track documentation freshness

### Automation

Set up automated checks:

1. Pre-commit hooks for validating documentation changes
2. Regular link checker runs
3. Automated reporting on documentation status

### Integration with Development Workflow

Ensure documentation is integrated with the development workflow:

1. Documentation tasks in issue tracking
2. Documentation reviews in pull requests
3. Documentation health in system monitoring dashboard

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Container failed to start | Check for port conflicts on 1313 |
| Hugo build errors | Check front matter format and content structure |
| Missing theme assets | Verify submodules are correctly initialized |
| Deployment failures | Check GitHub Actions permissions and workflow configuration |

### Debugging Commands

```bash
# Check Hugo server logs
podman-compose logs docs

# Run Hugo with verbose output
podman-compose exec docs hugo --verbose

# Validate documentation structure
podman-compose exec docs python3 docs/tools/doc-manager.py --validate-hugo --verbose
```

## Conclusion

This implementation plan provides a comprehensive approach to migrating the ScopeCam MCP documentation to Hugo while fully integrating with the project's containerized development environment and automation frameworks. By following these steps, the documentation will maintain its structure and standards while gaining enhanced features and improved workflow integration.

## Changelog

- 1.1.0 (2025-03-23): Updated with containerization and automation integration
- 1.0.0 (2025-03-23): Initial version