# MCP Build Verification Tools

This directory contains scripts for verifying the build process and component health of the Multi-Agent Control Platform (MCP).

## Overview

The verification tools in this directory are designed to systematically test, validate, and diagnose the MCP build process and runtime components. These tools implement the strategy outlined in the [Build Process Reliability Guide](../docs/consolidated/build-process-reliability-guide.md).

## Getting Started

1. Make all scripts executable:
   ```bash
   ./setup-verification-tools.sh
   ```

2. Run the verification scripts in this recommended order:
   ```bash
   # 1. Verify NATS server
   ./verify-nats.sh
   
   # 2. Verify MCP Core
   ./verify-mcp-core.sh
   
   # 3. Verify Camera Agent
   ./verify-camera-agent.sh
   
   # 4. Verify Python Processor
   ./verify-python-processor.sh
   
   # 5. Verify system integration
   ./verify-integration.sh
   
   # 6. If using containers, check container health
   ./container-health-check.sh
   ```

## Available Tools

| Script | Description |
|--------|-------------|
| `setup-verification-tools.sh` | Makes all verification scripts executable |
| `verify-nats.sh` | Validates the NATS messaging server setup and functionality |
| `verify-mcp-core.sh` | Validates the MCP Core orchestrator component functionality |
| `verify-camera-agent.sh` | Validates the Camera Integration Agent component functionality |
| `verify-python-processor.sh` | Validates the Python-based processing agent component functionality |
| `verify-integration.sh` | Validates end-to-end integration between all components of the MCP system |
| `container-health-check.sh` | Verifies the health of all containers in the MCP environment |

## Recommended Workflow

The verification tools support this workflow for reliable builds:

1. **Environment Setup**
   - Verify prerequisites are installed
   - Configure environment variables if needed

2. **Component Verification**
   - Verify each component individually
   - Fix any component-specific issues

3. **Integration Verification**
   - Verify all components work together
   - Identify and resolve integration issues

4. **Containerization Verification**
   - Verify containerized environment if used
   - Compare with local environment results

## Error Response Process

When an error is detected:

1. **Identify the component** where the error occurred
2. **Consult the error output** for detailed information
3. **Refer to the [Build Process Reliability Guide](../docs/consolidated/build-process-reliability-guide.md)** for resolution strategies
4. **Fix the underlying issue** following recommended practices
5. **Re-run the verification** to confirm the fix

## Integrating with CI/CD

These verification scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Verify build
  run: |
    chmod +x ./mcp-project/scripts/setup-verification-tools.sh
    ./mcp-project/scripts/setup-verification-tools.sh
    ./mcp-project/scripts/verify-nats.sh
    ./mcp-project/scripts/verify-mcp-core.sh
    ./mcp-project/scripts/verify-camera-agent.sh
    ./mcp-project/scripts/verify-python-processor.sh
    ./mcp-project/scripts/verify-integration.sh
```

## Contributing

When adding new components to the MCP system:

1. Create a corresponding verification script
2. Follow the established pattern for consistency
3. Update this README.md to include the new script
4. Update the Build Process Reliability Guide as needed

## Related Documentation

- [Build Process Reliability Guide](../docs/consolidated/build-process-reliability-guide.md)
- [Environment Setup Guide](../docs/environment-setup.md)
- [Local Development Guide](../docs/local-development-guide.md)
- [Containerized Development Guide](../docs/containerized-development-guide.md)