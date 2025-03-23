---
title: "MCP Containerized Development Environment"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/guides/build-engineer-implementation-guide.md"
  - "/docs/guides/build-engineer-onboarding-checklist.md"
  - "/docs/guides/build-engineer-tech-specs.md"
tags: ["podman", "containers", "development-environment", "nats", "system-setup"]
---

# Containerized Development Environment for MCP

[↩️ Back to Start Here](/docs/START_HERE.md) | [↩️ Back to Documentation Index](/docs/README.md)

## Overview

This guide details the recommended containerized development environment for the Multi-Agent Control Platform (MCP) using Podman and Podman Compose. This setup provides environment consistency, isolation, and resource efficiency while maintaining development speed.

## Why Podman?

Podman is particularly well-suited for the MCP development on Fedora Linux for several key reasons:

1. **Lower Resource Overhead**: Podman is a daemonless container engine that consumes fewer resources than Docker's daemon-based approach
2. **Native to Fedora**: Podman comes pre-installed or easily available on Fedora, making it a natural fit
3. **Docker Compose Compatibility**: Podman supports Docker Compose files through `podman-compose`
4. **Rootless Containers**: Podman allows running containers without root privileges, improving security
5. **Systemd Integration**: Better integration with Linux systemd for service management

## Prerequisites

Before setting up the containerized environment, ensure you have the following installed:

```bash
# Update system packages
sudo dnf update -y

# Install Podman and related tools
sudo dnf install -y podman podman-compose

# Verify installation
podman --version
podman-compose --version
```

## Directory Structure

Create the following directory structure for your containerized MCP development:

```
mcp-project/
├── podman-compose.yml           # Main compose file for all services
├── mcp-core/                    # Core orchestrator
│   ├── Dockerfile.dev           # Development Dockerfile for core
│   ├── build.gradle.kts         # Gradle build file
│   └── src/                     # Source code
├── agents/                      # Agent implementations
│   ├── camera-agent/            # Camera integration agent
│   │   └── Dockerfile.dev       # Development Dockerfile for camera agent
│   └── python-processor/        # Optional Python-based agent
│       └── Dockerfile.python    # Python agent Dockerfile
└── nats/                        # NATS configuration
    └── nats-server.conf         # NATS server configuration
```

## Podman Compose Configuration

Create a `podman-compose.yml` file in the project root with the following content:

```yaml
version: '3'

services:
  # Core MCP Orchestrator
  mcp-core:
    build:
      context: ./mcp-core
      dockerfile: Dockerfile.dev
    volumes:
      - ./mcp-core:/app
      - ~/.gradle:/root/.gradle
    ports:
      - "8080:8080"
    restart: unless-stopped
    environment:
      - NATS_URL=nats://nats:4222
    depends_on:
      - nats

  # Messaging Bus (NATS for Agent Communication)
  nats:
    image: nats:latest
    ports:
      - "4222:4222"  # Client connections
      - "8222:8222"  # HTTP monitoring
    volumes:
      - ./nats/nats-server.conf:/etc/nats/nats-server.conf
    command: ["--config", "/etc/nats/nats-server.conf"]
    restart: unless-stopped

  # Optional: Add specialized agent containers as needed
  # Example for a Python-based agent:
  python-processor:
    build:
      context: ./agents/python-processor
      dockerfile: Dockerfile.python
    volumes:
      - ./agents/python-processor:/app
    environment:
      - NATS_URL=nats://nats:4222
    depends_on:
      - nats
      - mcp-core
    restart: unless-stopped

  # Camera Integration Agent with USB device passthrough
  camera-agent:
    build:
      context: ./agents/camera-agent
      dockerfile: Dockerfile.dev
    volumes:
      - ./agents/camera-agent:/app
    devices:
      - /dev/bus/usb:/dev/bus/usb  # USB device passthrough
    environment:
      - NATS_URL=nats://nats:4222
    depends_on:
      - nats
      - mcp-core
    restart: unless-stopped
```

## Dockerfiles

### Core MCP Orchestrator (Kotlin)

Create `mcp-core/Dockerfile.dev`:

```dockerfile
# Development Dockerfile for MCP Core
FROM eclipse-temurin:17-jdk

WORKDIR /app

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy just the build files first (for better caching)
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
COPY gradlew ./

# Make gradlew executable
RUN chmod +x ./gradlew

# Volume mount will provide the actual source code
CMD ["./gradlew", "run", "--continuous"]
```

### Camera Integration Agent

Create `agents/camera-agent/Dockerfile.dev`:

```dockerfile
# Development Dockerfile for Camera Integration Agent
FROM eclipse-temurin:17-jdk

WORKDIR /app

# Install tools and libraries for USB/Camera access
RUN apt-get update && apt-get install -y --no-install-recommends \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# Copy build files (similar to core)
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
COPY gradlew ./

# Make gradlew executable
RUN chmod +x ./gradlew

# Volume mount will provide the actual source code
CMD ["./gradlew", "run", "--continuous"]
```

### Python Processor Agent (Optional)

Create `agents/python-processor/Dockerfile.python`:

```dockerfile
# Dockerfile for Python-based processing agent
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Volume mount will provide the actual source code
CMD ["python", "main.py"]
```

## NATS Configuration

Create `nats/nats-server.conf`:

```
# Basic NATS Server configuration
port: 4222
http_port: 8222

# Logging
debug: false
trace: false

# Maximum payload size (5MB)
max_payload: 5242880
```

## Development Workflow

### Starting the Environment

To start the entire MCP development environment:

```bash
# Navigate to project directory
cd mcp-project

# Start all services in detached mode
podman-compose up -d

# View container logs
podman-compose logs -f
```

### Stopping the Environment

To stop all services:

```bash
# Stop all containers but preserve data
podman-compose down

# Stop and remove all containers including volumes (clean start)
podman-compose down -v
```

### Rebuilding Services

When Dockerfiles or dependencies change:

```bash
# Rebuild specific service
podman-compose build mcp-core

# Rebuild and restart a service
podman-compose up -d --build mcp-core
```

### Development Loop

1. Start the environment with `podman-compose up -d`
2. Develop in your IDE with code mounted into the containers
3. Changes to Kotlin/Java code trigger automatic recompilation via Gradle's continuous mode
4. View logs with `podman-compose logs -f service-name`
5. Test your changes directly

## USB Device Passthrough for Camera Development

For UVC camera development, the container needs access to USB devices:

1. **Device Mapping**: The `--device=/dev/bus/usb:/dev/bus/usb` flag passes the entire USB bus to the container

2. **Persistent Device Rules**: For consistent device naming, create udev rules:
   ```bash
   # Create a udev rule for your camera
   sudo bash -c 'cat > /etc/udev/rules.d/99-uvc-camera.rules << EOF
   SUBSYSTEM=="usb", ATTRS{idVendor}=="VENDOR_ID", ATTRS{idProduct}=="PRODUCT_ID", MODE="0666", SYMLINK+="uvc-camera"
   EOF'
   
   # Reload udev rules
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```
   
   Replace `VENDOR_ID` and `PRODUCT_ID` with your camera's IDs (can be found using `lsusb`).

3. **Container Configuration**: Update the camera-agent service in `podman-compose.yml`:
   ```yaml
   camera-agent:
     # ...
     devices:
       - /dev/uvc-camera:/dev/uvc-camera  # Use the symlink created by udev
   ```

## Hybrid Approach Benefits

This containerized approach provides several advantages for MCP development:

1. **Consistent Environment**: All developers work with identical service configurations
2. **Isolated Dependencies**: Each service has its own dependencies without conflicts
3. **Hot Reload Development**: Source code volumes enable real-time development
4. **Resource Efficiency**: Podman's daemonless approach conserves system resources
5. **Service Independence**: Services can be started/stopped independently as needed

## Troubleshooting

### USB Device Access Issues

If the container can't access USB devices:

```bash
# Check USB devices visible to the host
lsusb

# Check USB devices visible to the container
podman exec -it camera-agent lsusb

# Check permissions on USB devices
ls -la /dev/bus/usb/*/

# Make sure you're in the correct group
sudo usermod -aG plugdev $USER  # Restart session after this
```

### Network Connectivity Issues

If services can't communicate:

```bash
# Check if NATS is reachable from other containers
podman exec -it mcp-core ping nats

# Check if NATS is running and listening
podman exec -it nats netstat -tulpn

# Check NATS logs
podman-compose logs nats
```

### Container Build Failures

If container builds fail:

```bash
# View detailed build logs
podman-compose build --no-cache service-name

# Check for disk space issues
df -h

# Verify Dockerfile syntax
podman-compose config
```

## Next Steps

After setting up the containerized environment:

1. Proceed to the [Build Engineer Implementation Guide](/docs/guides/build-engineer-implementation-guide.md) for implementing the core MCP components
2. Refer to [Build Engineer Onboarding Checklist](/docs/guides/build-engineer-onboarding-checklist.md) for a sequential implementation plan
3. Use [Build Engineer Technical Specifications](/docs/guides/build-engineer-tech-specs.md) as a reference during development

## References

- [Podman Documentation](https://podman.io/docs)
- [Podman Compose GitHub](https://github.com/containers/podman-compose)
- [NATS Docker Documentation](https://hub.docker.com/_/nats)
- [Eclipse Temurin JDK](https://hub.docker.com/_/eclipse-temurin)