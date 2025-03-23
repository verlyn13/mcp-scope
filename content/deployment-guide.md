# MCP Documentation: Deployment Guide

This guide explains the deployment options for the MCP documentation system and when to use each approach.

## Deployment Options

The system offers two deployment methods:

1. **Container-based Deployment** (`mcp-docs.sh`)
2. **Direct Deployment** (`direct-deploy.sh`)

Both methods accomplish the same result: building the Hugo site and deploying it to the gh-pages branch for GitHub Pages hosting.

## When to Use Each Method

### Use Container-based Deployment When:

- You're working in a containerized environment
- You want to ensure consistent Hugo version across different machines
- You don't want to install Hugo locally
- Your network/system can access container registries

```bash
# Pre-cache images once during setup (recommended)
./precache-images.sh

# Deploy using containers
./mcp-docs deploy
```

### Use Direct Deployment When:

- You're working in a non-containerized environment
- Containers (Docker/Podman) are not available on your system
- You prefer to use a local Hugo installation
- You encounter persistent container registry issues
- You need a simpler, more direct deployment process

```bash
# Install Hugo locally if not already installed
# (See https://gohugo.io/installation/)

# Deploy directly
./direct-deploy.sh
```

## Decision Flow Chart

```
Start
 │
 ├─ Do you have Hugo installed locally?
 │   │
 │   ├─ Yes ──┐
 │   │        │
 │   └─ No ───┘
 │            │
 ├─ Do you have Docker or Podman available?
 │   │
 │   ├─ Yes ── Use ./mcp-docs deploy
 │   │           (Will try local Hugo first if available)
 │   │
 │   └─ No ─── Install Hugo locally and use ./direct-deploy.sh
 │
 ├─ Are you experiencing container registry issues?
 │   │
 │   ├─ Yes ── Use ./direct-deploy.sh
 │   │
 │   └─ No ─── Use ./mcp-docs deploy
 │
End
```

## Environment-Specific Recommendations

### Development Workstation

If you regularly work on documentation, we recommend:
- Install Hugo locally
- Install a container runtime (Podman or Docker)
- Run `./precache-images.sh` once during setup
- Use either deployment method as needed

### CI/CD Server

For automated deployments:
- Use the container-based approach for consistency
- Pre-cache images in the CI setup phase
- Have a fallback to direct deployment if container issues occur

### Limited Environments

For restricted environments (no containers allowed):
- Install Hugo locally
- Use `./direct-deploy.sh` exclusively

## Summary

Both deployment methods are maintained and will continue to be supported. Choose the one that best fits your environment and preferences.