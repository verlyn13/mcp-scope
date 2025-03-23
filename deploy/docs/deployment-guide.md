---
title: "Documentation Deployment Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/deploy/docs/deployment-architecture/"
  - "/deploy/docs/troubleshooting/"
tags: ["deployment", "documentation", "guide", "hugo", "github-pages"]
---

# Documentation Deployment Guide

{{< status >}}

This guide explains how to deploy the MCP documentation to GitHub Pages using the unified deployment system.

{{< callout "info" "Unified Deployment" >}}
The MCP project now uses a unified deployment system that automatically selects the optimal deployment strategy based on your environment.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Quick Start

To deploy the documentation with the default settings:

```bash
./deploy/unified-deploy.sh
```

This will automatically:
1. Analyze your environment
2. Select the best deployment strategy
3. Build the documentation site
4. Deploy to the `gh-pages` branch

## Deployment Modes

The unified deployment system supports multiple deployment modes:

### Auto Mode (Default)

Automatically selects the best deployment strategy based on your environment.

```bash
./deploy/unified-deploy.sh --mode auto
```

The system will:
1. Check for local Hugo installation
2. Check for container runtime (Podman/Docker)
3. Verify shortcode compatibility
4. Select the optimal deployment mode

### Container Mode

Forces deployment using a containerized Hugo environment.

```bash
./deploy/unified-deploy.sh --mode container
```

**Requirements:**
- Podman or Docker installed
- Network access for image pulling (first time)

**Benefits:**
- Consistent Hugo version across all environments
- No need for local Hugo installation
- Predictable output

### Local Mode

Forces deployment using a locally installed Hugo.

```bash
./deploy/unified-deploy.sh --mode local
```

**Requirements:**
- Hugo installed locally

**Benefits:**
- Faster deployment (no container overhead)
- Works offline once set up
- Direct access to Hugo features

### Minimal Mode

Creates a simplified site that bypasses shortcode complexities.

```bash
./deploy/unified-deploy.sh --mode minimal
```

**Requirements:**
- Git

**Benefits:**
- Works in any environment
- Bypasses shortcode issues
- Guaranteed to build successfully

## Advanced Options

### Output Control

Control the verbosity of console output:

```bash
# Verbose output with detailed information
./deploy/unified-deploy.sh --output verbose

# Quiet output with minimal information
./deploy/unified-deploy.sh --output quiet
```

### Skipping Steps

Skip verification or precaching steps:

```bash
# Skip verification steps
./deploy/unified-deploy.sh --skip-verify

# Skip container image precaching
./deploy/unified-deploy.sh --skip-precache
```

### Custom Target Branch

Deploy to a different branch:

```bash
# Deploy to 'documentation' branch
./deploy/unified-deploy.sh --branch documentation
```

### Custom Report Path

Specify a custom report directory:

```bash
# Save reports to a custom location
./deploy/unified-deploy.sh --report /path/to/reports
```

## Environment Setup

### Container Environment

To set up a container-based deployment environment:

1. Install Podman or Docker:
   ```bash
   # Fedora/RHEL
   sudo dnf install podman
   
   # Ubuntu/Debian
   sudo apt install docker.io
   ```

2. Pre-cache the Hugo image (optional):
   ```bash
   # The deployment script will do this automatically,
   # but you can run it manually for faster deployments
   ./deploy/scripts/precache-images.sh
   ```

### Local Hugo Environment

To set up a local Hugo deployment environment:

1. Install Hugo:
   ```bash
   # Fedora/RHEL
   sudo dnf install hugo
   
   # Ubuntu/Debian
   sudo apt install hugo
   
   # macOS
   brew install hugo
   ```

2. Verify your Hugo installation:
   ```bash
   hugo version
   ```

### Minimal Environment

The minimal deployment mode requires only Git, which is typically already installed in development environments.

## Deployment Process

The deployment process follows these steps:

1. **Preparation**
   - Environment analysis
   - Mode selection
   - Prerequisite verification

2. **Building**
   - Content processing
   - Hugo execution
   - Site generation

3. **Deployment**
   - Branch management
   - Content replacement
   - Commit and push

4. **Reporting**
   - Report generation
   - Status output

## Deployment Reports

The unified deployment system generates detailed reports for each deployment, stored in the `./deploy-reports` directory (or your custom report path).

Reports include:
- Deployment mode used
- System information
- Build details
- Deployment status
- Timestamp

## Troubleshooting

If you encounter issues during deployment, please refer to the [Troubleshooting Guide](/deploy/docs/troubleshooting/).

Common issues include:

### Container Issues

If container-based deployment fails:
- Ensure Podman or Docker is installed and running
- Check network connectivity for image pulling
- Try running with `--output verbose` for detailed error messages

### Hugo Issues

If local Hugo deployment fails:
- Verify Hugo is installed: `hugo version`
- Check for Hugo errors in the build log
- Try using container mode instead: `--mode container`

### Git Issues

If deployment fails during the Git steps:
- Ensure you have proper permissions for the repository
- Check for Git authentication issues
- Verify branch existence and permissions

## CI/CD Integration

The unified deployment system can be easily integrated into CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Deploy Documentation

on:
  push:
    branches: [ main ]
    paths:
      - 'content/**'
      - 'themes/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.110.0'
          extended: true
          
      - name: Deploy Documentation
        run: |
          chmod +x ./deploy/unified-deploy.sh
          ./deploy/unified-deploy.sh --mode local --output quiet
```

### GitLab CI Example

```yaml
deploy-docs:
  image: klakegg/hugo:0.110-ext-alpine
  script:
    - chmod +x ./deploy/unified-deploy.sh
    - ./deploy/unified-deploy.sh --mode local --output quiet
  only:
    - main
  changes:
    - content/**/*
    - themes/**/*
```

## Best Practices

### Recommended Workflows

1. **Local Development**:
   - Use `--mode local` for faster iterations
   - Skip verification for speed: `--skip-verify`

2. **Release Deployments**:
   - Use default auto mode for reliability
   - Keep all verification steps enabled
   - Use verbose output for detailed logs

3. **CI/CD Deployments**:
   - Use `--mode local` if Hugo is pre-installed
   - Use `--mode container` for consistent environments
   - Use quiet output: `--output quiet`

### Performance Tips

- Pre-cache container images during environment setup
- Use local mode for faster deployments when possible
- Skip verification steps during frequent iterations

## Related Documentation

{{< related-docs >}}