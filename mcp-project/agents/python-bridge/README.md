# Python Bridge Agent

The Python Bridge Agent integrates smolagents AI capabilities with the Multi-Agent Control Platform (MCP), providing code generation and documentation generation services.

## Features

- AI-powered code generation for UVC camera implementations
- Documentation generation for existing code
- Seamless integration with MCP's task distribution system
- Robust NATS messaging communication
- Containerized deployment

## Quick Start

### Local Development

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -e .
   ```

3. Start the agent:
   ```bash
   python -m python_bridge.main
   ```

### Using Docker/Podman

1. Build the image:
   ```bash
   docker build -t python-bridge .
   ```

2. Run the container:
   ```bash
   docker run -p 8080:8080 -e NATS_SERVER=nats://your-nats-server:4222 python-bridge
   ```

### Using Podman Compose

The agent is configured in the main `podman-compose.yml` file and will be started automatically with:

```bash
cd ../../
podman-compose up
```

## Configuration

Configuration is stored in `config.yaml` and can be overridden with environment variables:

| Environment Variable | Default | Description |
|----------------------|---------|-------------|
| NATS_SERVER | nats://localhost:4222 | NATS server URL |
| MODEL_NAME | Qwen/Qwen2.5-Coder-32B-Instruct | AI model to use |
| HEARTBEAT_INTERVAL | 30 | Health check interval in seconds |
| API_HOST | 0.0.0.0 | API service host |
| API_PORT | 8080 | API service port |

## API Endpoints

- `GET /health` - Health check endpoint
- `POST /task` - Submit a task for processing
- `GET /task/{task_id}` - Get task status and result
- `GET /metrics` - Get agent metrics
- `GET /capabilities` - Get agent capabilities
- `GET /status` - Get agent status
- `POST /shutdown` - Shutdown the agent gracefully

## Directory Structure

```
python-bridge/
├── Dockerfile               # Container configuration
├── README.md                # This document
├── config.yaml              # Default configuration
├── entrypoint.sh            # Container entry point
├── requirements.txt         # Python dependencies
├── setup.py                 # Package configuration
├── src/
│   └── python_bridge/       # Main package
│       ├── __init__.py
│       ├── __main__.py      # Module entry point
│       ├── agent.py         # Agent implementation
│       ├── api.py           # API service
│       ├── config.py        # Configuration handling
│       ├── main.py          # Main entry point
│       ├── nats_client.py   # NATS communication
│       ├── smolagents_manager.py  # AI framework integration
│       └── tools/           # AI tools
│           ├── __init__.py
│           ├── code_generation.py     # Code generation
│           ├── documentation.py       # Documentation generation
│           └── uvc_code_templates.py  # UVC camera templates
└── tests/                   # Test suite
    ├── __init__.py
    ├── test_config.py       # Configuration tests
    ├── test_nats_integration.py  # NATS integration tests
    └── test_tools.py        # Tool tests
```

## Running Tests

Run the tests with pytest:

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=python_bridge

# Run only unit tests
pytest tests/ -k "not integration"

# Run only integration tests
pytest tests/ -k "integration"
```

## Task Types

The agent supports the following task types:

### Code Generation

```json
{
  "taskId": "task-123",
  "type": "code-generation",
  "parameters": {
    "requirements": "Implement a UVC camera frame grabber...",
    "targetPackage": "com.example.uvc.camera",
    "cameraType": "UVC"
  }
}
```

### Documentation Generation

```json
{
  "taskId": "task-456",
  "type": "documentation-generation",
  "parameters": {
    "code": "public class UvcCamera { ... }",
    "targetFormat": "markdown",
    "docType": "api"
  }
}
```

### UVC Analysis

```json
{
  "taskId": "task-789",
  "type": "uvc-analysis",
  "parameters": {
    "deviceData": "Device descriptor data...",
    "analysisType": "compatibility"
  }
}
```

## Logging

Logs are stored in the `logs` directory with rotation and retention policies. The default log level is INFO, which can be changed in the configuration.