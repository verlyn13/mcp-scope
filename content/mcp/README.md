---
title: "MCP Documentation Index"
status: "Active"
version: "1.1"
date_created: "2025-03-22"
last_updated: "2025-03-24"
contributors: ["Documentation Architect"]
related_docs:
  - "/mcp/README/"
  - "/docs/"
  - "/project/documentation-directory-structure/"
tags: ["mcp-core", "documentation", "index", "navigation"]
---

# MCP Documentation Index

🟢 **Active**

[↩️ Back to MCP Project](/mcp/README/) | [↩️ Back to Documentation Hub](/docs/)

## Overview

This is the documentation index for the Multi-Agent Control Platform (MCP) implementation. This index serves as the starting point for all MCP-specific technical documentation.

### Documentation Layer Context

This documentation is part of the **MCP Implementation Layer** in our dual-layer documentation structure:

```
/home/verlyn13/Projects/mcp-scope/     # ROOT PROJECT LAYER
├── docs/                              # Root documentation layer
└── mcp-project/                       # MCP IMPLEMENTATION LAYER
    └── docs/                          # THIS DOCUMENTATION LAYER
```

For information about the overall ScopeCam project and project organization, please refer to the [Root Documentation Hub](/docs/).

## MCP Documentation Sections

### Project Information

- [First Steps Guide](/mcp/getting-started/) - Getting started with MCP development

### Architecture Documentation

- [Architecture Overview](/mcp/architecture/overview/) - Comprehensive system design description

### Implementation Guides

- [Project Setup](/mcp/environment-setup/) - Environment setup instructions
- [Local Development Guide](/mcp/local-development-guide/) - Local development workflow
- [Containerized Development Guide](/mcp/containerized-development-guide/) - Container-based development

### Standards and Guidelines

- [Documentation Guidelines](/mcp/standards/documentation-guidelines/) - Documentation format and standards

## Core Components

The MCP implementation consists of these core components:

- **MCP Core**
  - Orchestrator - Central coordination component
  - Agent State Machine - State management for agents
  - NATS Connection Manager - Messaging infrastructure

- **Specialized Agents**
  - Camera Integration Agent - USB camera detection and control
  - Python Processor Agent - Data processing example in Python

## Common Tasks

### Setting Up Your Development Environment

1. Follow the [Project Setup Guide](/mcp/environment-setup/)
2. Choose between [local](/mcp/local-development-guide/) or [containerized](/mcp/containerized-development-guide/) development
3. Start with the [First Steps Guide](/mcp/getting-started/)

### Developing New Features

1. Understand the [Architecture Overview](/mcp/architecture/overview/)
2. Set up your development environment
3. Implement following the appropriate development guide

### Cross-Layer Documentation

For project-wide documentation and integration with the broader ScopeCam project, refer to:

- [🔄 ScopeCam Documentation Hub](/docs/) - Root documentation index
- [🔄 Dual-Layer Project Organization](/project/documentation-directory-structure/) - Project structure explanation

## Documentation Status System

All MCP documentation follows this status system:

| Status | Indicator | Description | 
|--------|-----------|-------------|
| 🟢 **Active** | `🟢 **Active**` | Current, reviewed and approved |
| 🟡 **Draft** | `🟡 **Draft**` | Work in progress, subject to change |
| 🟠 **Review** | `🟠 **Review**` | Complete but pending final approval |
| 🔴 **Outdated** | `🔴 **Outdated**` | Contains older information that needs updating |
| ⚫ **Archived** | `⚫ **Archived**` | Historical information, no longer applicable |

## Documentation Standards

All MCP documentation follows the standards defined in:

- [Documentation Guidelines](/mcp/standards/documentation-guidelines/)

These standards ensure consistency with the root documentation layer while focusing on MCP-specific technical content.

## Contributing to MCP Documentation

When contributing to MCP documentation:

1. Determine the appropriate section based on the content type:
   - `project/` - MCP project information and getting started
   - `architecture/` - MCP architecture and design
   - `implementation/` - Development guides and how-to content
   - `standards/` - MCP-specific standards and guidelines

2. Follow the [Documentation Guidelines](/mcp/standards/documentation-guidelines/)

3. Use the `mcp-core` or `mcp-agent` tags in your front matter to indicate MCP-specific content

4. Update this index when adding new documents

5. Use the 🔄 symbol when referencing documents in the root documentation layer

## Changelog

- 1.1.1 (2025-03-24): Updated all documentation links to use Hugo-compatible paths
- 1.1.0 (2025-03-22): Updated with dual-layer documentation context
- 1.0.0 (2025-03-22): Initial release