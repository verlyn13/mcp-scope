---
title: "System Integration Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/deploy/docs/deployment-architecture/"
  - "/tools/doc-doctor-guide/"
tags: ["integration", "documentation", "health", "deployment", "verification"]
---

# System Integration Guide

{{< status >}}

This guide explains how the MCP Documentation Deployment System and Doc Doctor health check system remain separate but can optionally work together.

{{< callout "info" "Separate but Complementary Systems" >}}
The MCP project maintains two separate systems with distinct purposes:
1. **Doc Doctor**: Comprehensive documentation health checks for quality assurance
2. **Unified Deployment System**: Streamlined documentation publishing for reliable deployment

While these systems have different focuses, they can be integrated when needed.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## System Overview

The MCP project maintains two distinct systems that serve different purposes:

1. **Doc Doctor Health Check System**
   - **Primary Purpose**: Comprehensive documentation quality analysis
   - **Key Features**: Multiple check modules, various check levels, detailed reporting
   - **Intended Use**: Regular maintenance, quality assurance, content creation
   - **Key Scripts**: `doc-doctor.sh`, modules in `doc-doctor-modules/`
   
2. **Unified Deployment System**
   - **Primary Purpose**: Building and publishing documentation reliably
   - **Key Features**: Multiple deployment strategies, streamlined workflow, reliable publishing
   - **Intended Use**: Documentation deployment, site generation, GitHub Pages publishing
   - **Key Scripts**: `deploy/unified-deploy.sh`, scripts in `deploy/scripts/`

Each system has its own specialized verification capabilities:

- **Doc Doctor's `shortcode-check.sh`**: 
  - Thorough, comprehensive verification of shortcodes
  - Multiple check levels (quick, standard, comprehensive)
  - Integrated with other health checks
  - Detailed reporting

- **Deployment's `verify-shortcodes.sh`**:
  - Streamlined, deployment-focused verification
  - Optimized for speed during deployment workflow
  - Focused on critical issues that would break builds
  - Simplified output format

## Maintaining Separation

These systems are intentionally kept separate to:

1. **Maintain Focus**: Each system focuses on what it does best
2. **Reduce Complexity**: Simpler, more focused codebases
3. **Enable Independent Evolution**: Each system can evolve separately
4. **Optimize for Purpose**: Each verification is tuned for its specific use case

## Optional Integration Points

While the systems remain separate, they can optionally work together through:

### Deployment Using Doc Doctor Verification

The deployment system can use Doc Doctor for verification when desired:

```bash
# Use Doc Doctor for more thorough verification before deployment
./deploy/unified-deploy.sh --use-doc-doctor
```

This flag causes the deployment system to use Doc Doctor's more comprehensive shortcode checks instead of its own built-in verification.

### Sequential Workflow

You can use both systems sequentially in your workflow:

```bash
# First run a comprehensive health check
./doc-doctor.sh --check-level comprehensive

# Then deploy if health check passes
if [ $? -eq 0 ]; then
  ./deploy/unified-deploy.sh --skip-verify
else
  echo "Fix documentation issues before deploying"
  exit 1
fi
```

### Shared Standards

Both systems enforce the same standards:

- Shortcode syntax and closing requirements
- Content structure expectations
- Documentation best practices

## When to Use Each System

### Use Doc Doctor When:

- Performing regular quality checks
- Creating new documentation content
- Training new contributors
- Analyzing documentation health trends
- Running comprehensive reviews

```bash
# Regular quality check
./doc-doctor.sh --check-level standard

# Focused check on specific area
./doc-doctor.sh --focus-area shortcodes

# Comprehensive review
./doc-doctor.sh --check-level comprehensive --output-format markdown
```

### Use Deployment System When:

- Publishing documentation to GitHub Pages
- Building the site for local preview
- Running in CI/CD pipelines
- Needing guaranteed deployment options

```bash
# Standard deployment
./deploy/unified-deploy.sh

# Quick local preview
./deploy/unified-deploy.sh --mode local --skip-verify

# Guaranteed deployment for important releases
./deploy/unified-deploy.sh --mode minimal
```

### Use Both Together When:

- Deploying critical releases that need thorough verification
- Setting up CI/CD pipelines with comprehensive quality gates
- Training new team members on full documentation workflow

```bash
# Thorough verification using Doc Doctor, then deploy
./doc-doctor.sh --check-level comprehensive
./deploy/unified-deploy.sh --skip-verify  # Skip redundant verification

# Or use the integrated approach
./deploy/unified-deploy.sh --use-doc-doctor  # Use Doc Doctor for verification
```

## Integration Examples

### CI/CD Pipeline with Separate Systems

```yaml
name: Documentation Pipeline

on:
  push:
    branches: [ main ]
    paths:
      - 'content/**'
      - 'themes/**'

jobs:
  quality-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Doc Doctor
        run: |
          chmod +x ./doc-doctor.sh
          ./doc-doctor.sh --check-level standard
        
  deploy:
    needs: quality-check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy Documentation
        run: |
          chmod +x ./deploy/unified-deploy.sh
          ./deploy/unified-deploy.sh --skip-verify  # Skip since we already verified
```

### CI/CD Pipeline with Integrated Approach

```yaml
name: Documentation Pipeline

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
      
      - name: Deploy Documentation with Doc Doctor verification
        run: |
          chmod +x ./deploy/unified-deploy.sh
          ./deploy/unified-deploy.sh --use-doc-doctor
```

### Local Development Workflow

For local development:

1. Use Doc Doctor during content creation:
   ```bash
   # Check specific content changes
   ./doc-doctor.sh --focus-area shortcodes
   ```

2. Use deployment system for local preview:
   ```bash
   # Quick local preview
   ./deploy/unified-deploy.sh --mode local --skip-verify
   ```

3. Final deployment pipeline:
   ```bash
   # Use Doc Doctor for thorough check
   ./doc-doctor.sh --check-level comprehensive
   
   # Skip verify since we already did thorough check
   ./deploy/unified-deploy.sh --skip-verify
   ```

## Benefits of This Approach

Maintaining separate systems with optional integration points provides several benefits:

1. **Specialized Tools**: Each system focuses on what it does best
2. **Clarity of Purpose**: Clear distinction between quality assurance and deployment
3. **Flexibility**: Use the right tool for each specific task
4. **Efficiency**: Optimized workflows for different scenarios
5. **Clean Architecture**: Well-organized codebase with clear responsibilities

## Related Documentation

{{< related-docs >}}