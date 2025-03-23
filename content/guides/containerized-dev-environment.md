---
title: "MCP Containerized Development Environment"
status: "Active"
version: "1.1"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
related_docs:
  - "/guides/build-engineer-implementation-guide/"
  - "/guides/build-engineer-onboarding-checklist/"
  - "/guides/build-engineer-tech-specs/"
  - "/guides/build-engineer-quick-start/"
tags: ["podman", "containers", "development-environment", "nats", "system-setup", "gradle"]
---

# Containerized Development Environment for MCP

{{< status >}}

[↩️ Back to Start Here](/getting-started/) | [↩️ Back to Documentation Index](/docs/)

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

## Gradle 8.12 Setup

The MCP project requires Gradle 8.12 for building and testing. Here's how to set it up:

### Local Development Environment

```bash
# Download and install Gradle 8.12
wget https://services.gradle.org/distributions/gradle-8.12-bin.zip
sudo mkdir -p /opt/gradle
sudo unzip -d /opt/gradle gradle-8.12-bin.zip
sudo ln -s /opt/gradle/gradle-8.12/bin/gradle /usr/local/bin/gradle

# Verify installation
gradle --version

# Configure Gradle wrapper in the project
cd mcp-project
gradle wrapper
```

### Containerized Environment

The Docker images are configured to use Gradle 8.12. If you need to update them:

1. Modify the Dockerfiles to use Gradle 8.12
2. Rebuild the containers

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

# Install Gradle 8.12
ENV GRADLE_VERSION=8.12
RUN curl -L https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv gradle-${GRADLE_VERSION} /opt/gradle \
    && ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle

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
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Gradle 8.12
ENV GRADLE_VERSION=8.12
RUN curl -L https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv gradle-${GRADLE_VERSION} /opt/gradle \
    && ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle

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

### Running Tests

In the local environment:

```bash
# Run all tests
cd mcp-project
./gradlew test

# Run specific tests
./gradlew :mcp-core:test
```

In the containerized environment:

```bash
# Run tests in the container
podman exec -it mcp-project_mcp-core_1 ./gradlew test

# Run specific tests
podman exec -it mcp-project_mcp-core_1 ./gradlew :test --tests "com.example.mcp.AgentStateMachineTest"
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
4. Run tests with `./gradlew test` or within containers
5. View logs with `podman-compose logs -f service-name`
6. Test your changes directly

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

## Implementation Progress

| Component | Status | Completion |
|-----------|--------|------------|
| Environment Setup | 🟢 Active | {{< progress value="100" >}} |
| Podman Configuration | 🟢 Active | {{< progress value="100" >}} |
| NATS Integration | 🟢 Active | {{< progress value="100" >}} |
| Gradle Setup | 🟢 Active | {{< progress value="100" >}} |
| Camera Agent Setup | 🟢 Active | {{< progress value="85" >}} |
| Python Agent Setup | 🟢 Active | {{< progress value="90" >}} |
| USB Device Passthrough | 🟢 Active | {{< progress value="80" >}} |

## Hybrid Approach Benefits

This containerized approach provides several advantages for MCP development:

1. **Consistent Environment**: All developers work with identical service configurations
2. **Isolated Dependencies**: Each service has its own dependencies without conflicts
3. **Hot Reload Development**: Source code volumes enable real-time development
4. **Resource Efficiency**: Podman's daemonless approach conserves system resources
5. **Service Independence**: Services can be started/stopped independently as needed

## Troubleshooting

### Gradle Issues

If you encounter Gradle-related issues:

```bash
# Check Gradle version
gradle --version

# Check for configuration issues
./gradlew --info

# Clear Gradle caches
rm -rf ~/.gradle/caches/

# Validate Gradle wrapper
./gradlew wrapper --gradle-version=8.12
```

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

1. Proceed to the [Build Engineer Implementation Guide](/guides/build-engineer-implementation-guide/) for implementing the core MCP components
2. Refer to [Build Engineer Onboarding Checklist](/guides/build-engineer-onboarding-checklist/) for a sequential implementation plan
3. Use [Build Engineer Technical Specifications](/guides/build-engineer-tech-specs/) as a reference during development

## References

- [Podman Documentation](https://podman.io/docs)
- [Podman Compose GitHub](https://github.com/containers/podman-compose)
- [NATS Docker Documentation](https://hub.docker.com/_/nats)
- [Eclipse Temurin JDK](https://hub.docker.com/_/eclipse-temurin)
- [Gradle 8.12 Documentation](https://docs.gradle.org/)

## Related Documentation

{{< related-docs >}}

## Changelog

- 1.1.0 (2025-03-23): Added Gradle 8.12 setup instructions and testing information
- 1.0.0 (2025-03-22): Initial release