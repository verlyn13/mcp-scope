---
title: "MCP Documentation Index"
status: "Active"
version: "1.1"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/mcp-project/README.md"
  - "/docs/README.md"
  - "/docs/project/project-organization.md"
tags: ["mcp-core", "documentation", "index", "navigation"]
---

# MCP Documentation Index

🟢 **Active**

[↩️ Back to MCP Project](/mcp-project/README.md) | [↩️ Back to Documentation Hub](/docs/README.md)

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

For information about the overall ScopeCam project and project organization, please refer to the [Root Documentation Hub](/docs/README.md).

## MCP Documentation Sections

### Project Information

- [First Steps Guide](/mcp-project/docs/project/first-steps.md) - Getting started with MCP development

### Architecture Documentation

- [Architecture Overview](/mcp-project/docs/architecture/overview.md) - Comprehensive system design description

### Implementation Guides

- [Project Setup](/mcp-project/docs/implementation/project-setup.md) - Environment setup instructions
- [Local Development Guide](/mcp-project/docs/implementation/local-development-guide.md) - Local development workflow
- [Containerized Development Guide](/mcp-project/docs/implementation/containerized-development-guide.md) - Container-based development

### Standards and Guidelines

- [Documentation Guidelines](/mcp-project/docs/standards/documentation-guidelines.md) - Documentation format and standards

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

1. Follow the [Project Setup Guide](/mcp-project/docs/implementation/project-setup.md)
2. Choose between [local](/mcp-project/docs/implementation/local-development-guide.md) or [containerized](/mcp-project/docs/implementation/containerized-development-guide.md) development
3. Start with the [First Steps Guide](/mcp-project/docs/project/first-steps.md)

### Developing New Features

1. Understand the [Architecture Overview](/mcp-project/docs/architecture/overview.md)
2. Set up your development environment
3. Implement following the appropriate development guide

### Cross-Layer Documentation

For project-wide documentation and integration with the broader ScopeCam project, refer to:

- [🔄 ScopeCam Documentation Hub](/docs/README.md) - Root documentation index
- [🔄 Dual-Layer Project Organization](/docs/project/project-organization.md) - Project structure explanation

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

- [Documentation Guidelines](/mcp-project/docs/standards/documentation-guidelines.md)

These standards ensure consistency with the root documentation layer while focusing on MCP-specific technical content.

## Contributing to MCP Documentation

When contributing to MCP documentation:

1. Determine the appropriate section based on the content type:
   - `project/` - MCP project information and getting started
   - `architecture/` - MCP architecture and design
   - `implementation/` - Development guides and how-to content
   - `standards/` - MCP-specific standards and guidelines

2. Follow the [Documentation Guidelines](/mcp-project/docs/standards/documentation-guidelines.md)

3. Use the `mcp-core` or `mcp-agent` tags in your front matter to indicate MCP-specific content

4. Update this index when adding new documents

5. Use the 🔄 symbol when referencing documents in the root documentation layer

## Changelog

- 1.1.0 (2025-03-22): Updated with dual-layer documentation context
- 1.0.0 (2025-03-22): Initial release