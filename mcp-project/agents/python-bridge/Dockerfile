FROM python:3.10-slim

WORKDIR /app

# Install required system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libc6-dev \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Make entry point script executable
RUN chmod +x /app/entrypoint.sh

# Install the package in development mode
RUN pip install -e .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV AGENT_CONFIG_PATH=/app/config.yaml
ENV NATS_SERVER=nats://localhost:4222
ENV MODEL_NAME=Qwen/Qwen2.5-Coder-32B-Instruct
ENV HEARTBEAT_INTERVAL=30
ENV API_HOST=0.0.0.0
ENV API_PORT=8080

# Create log directory
RUN mkdir -p /app/logs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the agent using the entry point script
ENTRYPOINT ["/app/entrypoint.sh"]