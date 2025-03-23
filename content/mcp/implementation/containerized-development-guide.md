---
title: "MCP Containerized Development Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/README.md"
  - "/docs/project/first-steps.md"
  - "/docs/implementation/project-setup.md"
  - "/docs/implementation/local-development-guide.md"
tags: ["podman", "docker", "containers", "development", "workflow"]
---

# MCP Containerized Development Guide

🟢 **Active**

[↩️ Back to Documentation Index](/docs/README.md)

## Overview

This guide explains how to use the containerized development environment for the Multi-Agent Control Platform (MCP). Containerization ensures consistent behavior across different development machines and production environments.

## Prerequisites

- Podman (recommended) or Docker
- Podman Compose or Docker Compose

```bash
# Install on Fedora/RHEL
sudo dnf install -y podman podman-compose

# Verify installation
podman --version
podman-compose --version
```

## Benefits of Containerized Development

1. **Environment Consistency**: Identical development environments across all systems
2. **Dependency Isolation**: No conflicts between project dependencies
3. **Service Orchestration**: All components start in the correct order
4. **Resource Management**: Easy cleanup and resource allocation
5. **Cross-Platform**: Works the same on Linux, macOS, and Windows

## Container Architecture

The containerized environment consists of these services:

1. **NATS**: Message broker for inter-component communication
2. **MCP Core**: Orchestrator component (Kotlin/JVM)
3. **Camera Agent**: Camera integration with USB device support (Kotlin/JVM)
4. **Python Processor**: Data processing agent (Python)

## Working with Containers

### Starting the Environment

```bash
# Navigate to the project directory
cd /home/verlyn13/Projects/mcp-scope/mcp-project

# Build and start all containers
podman-compose up -d

# View logs
podman-compose logs -f
```

### Viewing Individual Component Logs

```bash
# View logs for a specific component
podman-compose logs -f mcp-core
podman-compose logs -f camera-agent
podman-compose logs -f python-processor
```

### Stopping the Environment

```bash
# Stop all containers but keep volumes
podman-compose down

# Stop and remove volumes (clean slate)
podman-compose down -v
```

### Rebuilding Components

After making changes to Dockerfiles or dependencies:

```bash
# Rebuild a specific component
podman-compose build mcp-core

# Rebuild and restart a component
podman-compose up -d --build mcp-core
```

## Development Workflow with Containers

### Volume Mounting for Live Code Changes

The `podman-compose.yml` configuration mounts your local source directories into the containers, enabling live code changes:

```yaml
volumes:
  - ./mcp-core:/app  # Mounts local mcp-core directory into container
```

This allows you to:
1. Make code changes in your local environment
2. See changes reflected immediately in the containers

### Hot Reload for Kotlin Components

The Kotlin containers are configured with Gradle's continuous build mode, which automatically detects changes:

```
CMD ["./gradlew", "run", "--continuous"]
```

When you modify Kotlin files in `mcp-core` or `camera-agent`, the application will rebuild and restart automatically.

### Testing Python Changes

For Python components, changes to Python files are immediately available because the container is directly running the mounted files.

### Container Lifecycle Management

For more complex operations:

```bash
# Restart a specific container
podman-compose restart python-processor

# Stop a specific container
podman-compose stop camera-agent

# Start a stopped container
podman-compose start camera-agent

# View resource usage
podman stats
```

## Working with USB Devices (Camera Agent)

The camera agent container is configured to access USB devices from the host:

```yaml
devices:
  - /dev/bus/usb:/dev/bus/usb  # USB device passthrough
```

When working with real camera hardware:

1. Connect the USB camera to your computer
2. The container will have access to the device
3. Use `lsusb` inside the container to verify device visibility:
   ```bash
   podman exec -it camera-agent lsusb
   ```

### Troubleshooting USB Access

If USB devices aren't visible in the container:

```bash
# Check USB devices on the host
lsusb

# Verify container access
podman exec -it camera-agent lsusb

# Check USB device permissions
ls -la /dev/bus/usb/*/

# Add your user to the correct group (usually 'plugdev')
sudo usermod -aG plugdev $USER
# Log out and back in for this to take effect
```

## Network Communication Between Containers

Containers communicate via the internal network created by Podman Compose:

1. **Service Discovery**: Containers can reach each other using service names as hostnames
2. **NATS Connection**: All services connect to NATS using `nats://nats:4222`
3. **Port Mapping**: Some services expose ports to the host (e.g., NATS on 4222, HTTP on 8080)

To debug network connectivity:

```bash
# Check if NATS is reachable from mcp-core
podman exec -it mcp-core ping nats

# Inspect the network
podman network inspect podman_default
```

## Hybrid Development Approach

You can combine local and containerized development:

1. **Start some services in containers**:
   ```bash
   # Only start NATS and mcp-core
   podman-compose up -d nats mcp-core
   ```

2. **Run other components locally**:
   ```bash
   # Run camera-agent locally, connecting to the containerized NATS
   NATS_URL=nats://localhost:4222 ./gradlew run
   ```

This approach allows you to debug specific components locally while using containers for others.

## Advanced Container Configurations

### Resource Limits

You can adjust container resource limits in `podman-compose.yml`:

```yaml
services:
  mcp-core:
    # ... other configuration ...
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

### Environment Variables

Environment variables are defined in `podman-compose.yml`:

```yaml
services:
  mcp-core:
    # ... other configuration ...
    environment:
      - NATS_URL=nats://nats:4222
      - LOG_LEVEL=INFO
```

You can override these at runtime:

```bash
podman-compose run -e LOG_LEVEL=DEBUG mcp-core
```

### Container Shell Access

For debugging or manual testing:

```bash
# Get a shell in a running container
podman exec -it mcp-core bash

# Run a one-off command
podman exec -it python-processor pip list
```

## Troubleshooting Container Issues

### Container Fails to Start

```bash
# Check container logs
podman logs mcp-core

# Verify image was built correctly
podman images

# Inspect container configuration
podman inspect mcp-core
```

### Container Network Issues

```bash
# Check if containers are on the same network
podman network inspect podman_default

# Verify service discovery
podman exec -it mcp-core getent hosts nats
```

### Volume Mount Problems

```bash
# Check if volumes are mounted correctly
podman inspect -f '{{ .Mounts }}' mcp-core

# Ensure file permissions are correct
sudo chown -R $(id -u):$(id -g) ./mcp-core
```

### Resource Constraints

```bash
# Check container resource usage
podman stats

# Increase available resources in podman-compose.yml
```

## CI/CD Integration

The containerized environment works well with CI/CD pipelines:

1. **Testing**: Use the same containers in CI pipelines for consistent testing
2. **Building**: Create production images based on the development Dockerfiles
3. **Deployment**: Push images to a registry for deployment

Example GitHub Actions workflow:

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Podman
        run: |
          sudo apt-get update
          sudo apt-get install -y podman podman-compose
      - name: Build and test
        run: |
          podman-compose build
          podman-compose up -d
          # Run tests...
          podman-compose down
```

## Best Practices for Containerized Development

1. **Keep container definitions up-to-date** with project dependencies
2. **Minimize image size** by using multi-stage builds when appropriate
3. **Use volume mounts** for development, but include all files in production builds
4. **Centralize configuration** in `podman-compose.yml` environment variables
5. **Ensure proper cleanup** with `podman-compose down` after development sessions
6. **Test container changes** before committing to version control

## Related Documents

- [Project Setup](/docs/implementation/project-setup.md)
- [First Steps Guide](/docs/project/first-steps.md)
- [Local Development Guide](/docs/implementation/local-development-guide.md)

## Changelog

- 1.0.0 (2025-03-22): Initial release