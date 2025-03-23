---
title: "Hugo Containerized Setup for MCP Documentation"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/guides/containerized-dev-environment.md"
  - "/docs/guides/build-engineer-implementation-guide.md"
  - "/hugo-site-plan.md"
  - "/hugo-implementation-steps.md"
  - "/github-workflow-setup.md"
tags: ["documentation", "hugo", "containerization", "automation", "devops"]
---

# Hugo Containerized Setup for MCP Documentation

🟢 **Active**

[↩️ Back to Hugo Migration Executive Summary](/hugo-migration-executive-summary.md)

## Overview

This document outlines how to integrate the Hugo static site documentation system with the existing ScopeCam MCP containerized development environment. It provides configuration details for developing, testing, and building the documentation site in a containerized environment consistent with the project's established patterns.

## Prerequisites

- Familiarity with the [Containerized Development Environment](/docs/guides/containerized-dev-environment.md)
- Docker or Podman installed locally
- Basic understanding of the Hugo static site generator
- Access to the project repository

## Container Configuration

### Dockerfile for Hugo Development

Create a `Dockerfile.hugo` in the project root with the following content:

```dockerfile
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
```

### Integration with Podman Compose

Add the following service to the existing `podman-compose.yml` file:

```yaml
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
```

## Development Workflow

### Starting the Documentation Container

```bash
# Start the existing development environment
podman-compose up -d

# Start only the documentation service
podman-compose up -d docs

# View logs
podman-compose logs -f docs
```

### Local Development with Hot Reload

The Hugo development server will automatically reload when files change:

1. Edit markdown files in the `/content` directory
2. View changes at `http://localhost:1313`
3. Use the Hugo CLI inside the container:

```bash
# Run Hugo commands in the container
podman-compose exec docs hugo new content/project/new-document.md

# Build the static site
podman-compose exec docs hugo --minify
```

## CI/CD Integration

### Automated Build Process

Integrate Hugo building into the existing CI pipeline:

1. **Step 1**: Update the GitHub Actions workflow to include documentation building
2. **Step 2**: Add documentation validation to the pre-commit checks
3. **Step 3**: Integrate with the existing testing framework

### Example CI Workflow Addition

Add the following job to your existing CI workflow:

```yaml
  docs-validation:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: recursive
          fetch-depth: 0
      
      - name: Validate Documentation Structure
        run: python3 docs/tools/doc-manager.py validate
      
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.110.0'
          extended: true
      
      - name: Build Documentation
        run: hugo --minify --baseURL "${GITHUB_REPOSITORY_OWNER}.github.io/${GITHUB_REPOSITORY#*/}/"
      
      - name: Check for Broken Links
        run: |
          pip install html5validator linkchecker
          linkchecker ./public/
```

## Integration with Existing Documentation Tools

### Using doc-manager.py with Hugo

Extend the existing `doc-manager.py` tool to support the Hugo structure:

```bash
# Generate Hugo-compatible front matter
python3 docs/tools/doc-manager.py hugo-front-matter --input docs/project/current-focus.md

# Validate Hugo content structure
python3 docs/tools/doc-manager.py validate-hugo
```

### Automated Status Tracking

Integrate the status system with Hugo taxonomies:

1. Create a status taxonomy in Hugo configuration
2. Use the existing status indicators (🟢, 🟡, 🟠, 🔴, ⚫)
3. Generate status reports using both systems

## Testing Environment

### Multi-environment Configuration

Configure Hugo for different environments:

```
└── config/
    ├── _default/
    │   ├── config.toml      # Base configuration
    │   ├── params.toml      # Parameters
    │   └── menus.toml       # Navigation menus
    ├── development/         # Development environment
    │   └── config.toml      # Development overrides  
    └── production/          # Production environment
        └── config.toml      # Production overrides
```

Start Hugo with the appropriate environment:

```bash
# Development
podman-compose exec docs hugo server --environment development

# Production
podman-compose exec docs hugo --environment production
```

## Health Monitoring Integration

### Documentation Build Status

Integrate documentation build status into the health monitoring framework:

1. Add documentation build status to the health dashboard
2. Set up alerts for documentation build failures
3. Track documentation coverage and status metrics

### Implementation Example

```kotlin
// Add to HealthCheckService.kt
fun checkDocumentationStatus(): HealthStatus {
    val docsStatus = try {
        // Check documentation build status
        val process = ProcessBuilder("hugo", "check").start()
        val exitCode = process.waitFor()
        if (exitCode == 0) HealthStatus.HEALTHY else HealthStatus.DEGRADED
    } catch (e: Exception) {
        HealthStatus.UNKNOWN
    }
    
    return HealthStatus(
        component = "documentation",
        status = docsStatus,
        message = "Documentation build status",
        timestamp = System.currentTimeMillis()
    )
}
```

## Troubleshooting

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Hugo server not accessible | Check the `--bind` setting and port mapping in podman-compose.yml |
| CSS not loading | Verify the baseURL setting in Hugo config |
| Build failing in CI | Check Hugo version compatibility and verify submodule access |
| Front matter validation errors | Use doc-manager.py to validate and fix front matter |

### Debugging Containerized Hugo

```bash
# Get an interactive shell in the container
podman-compose exec docs /bin/sh

# Run Hugo with verbose output
podman-compose exec docs hugo --verbose

# Check Hugo environment variables
podman-compose exec docs env | grep HUGO
```

## Conclusion

This containerized setup enables seamless integration of the Hugo documentation system with the existing ScopeCam MCP development environment. It ensures that documentation remains synchronized with code, follows the project's standards, and can be validated through the same CI/CD pipelines.

The configuration supports both local development with hot reloading and containerized builds for CI/CD, providing a consistent experience across all environments.

## Next Steps

1. Implement the Dockerfile.hugo and update podman-compose.yml
2. Extend doc-manager.py to support Hugo
3. Update CI/CD pipelines to include documentation validation
4. Integrate documentation health metrics with the monitoring system

## Changelog

- 1.0.0 (2025-03-23): Initial version