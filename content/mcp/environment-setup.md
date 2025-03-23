# MCP Development Environment Setup

This guide explains how to set up consistent development environments for the Multi-Agent Control Platform (MCP) project, supporting both local development and containerized deployments.

## Prerequisites

- JDK 17+ for Kotlin/Java components
- Python 3.11+ for Python agents
- NATS server for message passing
- Podman or Docker (optional, for containerized development)

## Local Development Environment Setup

### 1. Kotlin/JVM Components Setup

We recommend using SDKMAN for managing JDK and Kotlin installations:

```bash
# Install SDKMAN
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install JDK 17
sdk install java 17.0.8-tem

# Install Kotlin
sdk install kotlin

# Install Gradle
sdk install gradle 8.3
```

### 2. Python Environment Setup

We use virtual environments to isolate Python dependencies for each agent:

```bash
# Navigate to the Python agent directory
cd /home/verlyn13/Projects/mcp-scope/mcp-project/agents/python-processor

# Create a virtual environment
python -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. NATS Server Setup

For local development, you can run NATS directly on your machine:

```bash
# Install NATS server on Fedora
sudo dnf install nats-server

# Start NATS with the project configuration
nats-server -c /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf
```

## Hybrid Development Workflow

We recommend a hybrid approach that allows you to:

1. Develop and debug components locally for fast iteration
2. Test the integrated system with containers when needed

### Local Development Steps

1. **Run NATS server locally**
   ```bash
   nats-server -c /home/verlyn13/Projects/mcp-scope/mcp-project/nats/nats-server.conf
   ```

2. **Run MCP Core in a terminal**
   ```bash
   cd /home/verlyn13/Projects/mcp-scope/mcp-project/mcp-core
   ./gradlew run
   ```

3. **Run Camera Agent in another terminal**
   ```bash
   cd /home/verlyn13/Projects/mcp-scope/mcp-project/agents/camera-agent
   ./gradlew run
   ```

4. **Run Python Agent in a third terminal**
   ```bash
   cd /home/verlyn13/Projects/mcp-scope/mcp-project/agents/python-processor
   source venv/bin/activate
   python main.py
   ```

### Containerized Development (when needed)

The project includes container configurations that closely match the local development environment:

1. **Build and start containers**
   ```bash
   cd /home/verlyn13/Projects/mcp-scope/mcp-project
   podman-compose build
   podman-compose up -d
   ```

2. **View logs**
   ```bash
   podman-compose logs -f
   ```

3. **Stop containers**
   ```bash
   podman-compose down
   ```

## Environment Variables

To ensure consistent behavior between local and containerized environments, use these environment variables:

| Variable | Description | Local Default | Container Value |
|----------|-------------|---------------|----------------|
| `NATS_URL` | URL to connect to NATS | `nats://localhost:4222` | `nats://nats:4222` |

## IDE Setup

### IntelliJ IDEA / Android Studio

1. Open the project's `build.gradle.kts` file and import as a Gradle project
2. Configure the JDK to use version 17+
3. Set up run configurations for each component

### VS Code

1. Install the Kotlin and Python extensions
2. Configure Python virtual environments:
   ```json
   {
     "python.defaultInterpreterPath": "${workspaceFolder}/agents/python-processor/venv/bin/python"
   }
   ```

## Switching Between Environments

The project structure is designed to make switching between local and containerized development as seamless as possible:

1. **Local to Containerized**: Simply run `podman-compose up -d`
2. **Containerized to Local**: Run `podman-compose down` and start components locally

## Best Practices

1. Always develop new features locally for faster debugging
2. Test with containers before committing changes to ensure compatibility
3. Keep your virtual environments up to date with `requirements.txt`
4. Use environment variables to handle differences between environments