---
title: "MCP Containerized Development Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/guides/containerized-dev-environment/"
  - "/mcp/docs/environment-setup/"
  - "/mcp/docs/local-development-guide/"
tags: ["mcp", "containerization", "development", "podman", "docker"]
---

# MCP Containerized Development Guide

{{< status >}}

[↩️ Back to MCP Documentation](/mcp/docs/) | [↩️ Back to Documentation Index](/docs/)

{{< callout "info" "Redirect Notice" >}}
This content has been consolidated with the main [Containerized Development Environment](/guides/containerized-dev-environment/) guide for better maintainability.
{{< /callout >}}

## Overview

For complete instructions on containerized development with MCP, please refer to the consolidated [Containerized Development Environment](/guides/containerized-dev-environment/) guide, which covers:

1. Setting up podman/docker for MCP development
2. Running MCP components in containers
3. Containerized development workflows
4. Troubleshooting containerization issues

## Key Configuration References

For quick reference, here are direct links to key configuration files:

- [podman-compose.yml](/mcp/docs/project-setup/#podman-compose-configuration)
- [mcp-core/Dockerfile.dev](/mcp/docs/project-setup/#mcp-core-dockerfile)
- [agents/camera-agent/Dockerfile.dev](/mcp/docs/project-setup/#camera-agent-dockerfile)
- [agents/python-processor/Dockerfile.python](/mcp/docs/project-setup/#python-processor-dockerfile)

## Related Documentation

{{< related-docs >}}