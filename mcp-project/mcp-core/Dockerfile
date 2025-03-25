# Multi-stage build for MCP Server
# Stage 1: Build the application
FROM gradle:7.6.1-jdk17 AS build

WORKDIR /app
COPY . /app/

# Build the application
RUN gradle build --no-daemon

# Stage 2: Create the runtime image
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy the built artifacts from the build stage
COPY --from=build /app/build/libs/*.jar /app/mcp-server.jar

# Create a non-root user to run the application
RUN addgroup -S mcp && adduser -S mcp -G mcp

# Create directories and set permissions
RUN mkdir -p /data /config /logs && \
    chown -R mcp:mcp /app /data /config /logs

# Switch to non-root user
USER mcp

# Set environment variables
ENV NATS_URL=nats://nats:4222 \
    MCP_ENABLE_HEALTH_CHECKS=true \
    MCP_PERSISTENCE_FILE=/data/mcp-state.json \
    MCP_MAX_TASKS=4 \
    MCP_PID_FILE=/app/mcp.pid \
    JAVA_OPTS="-Xms512m -Xmx1024m"

# Expose ports 
EXPOSE 8080

# Volume for persistent data
VOLUME ["/data", "/logs", "/config"]

# Define healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O- http://localhost:8080/health || exit 1

# Entry point
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/mcp-server.jar --nats-url=$NATS_URL --persistence --persistence-file=$MCP_PERSISTENCE_FILE --pid-file=$MCP_PID_FILE"]