---
title: "ScopeCam MCP Documentation Hub"
status: "Active"
version: "1.4"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
related_docs:
  - "/README.md"
  - "/docs/project/project-organization.md"
  - "/docs/project/path-reference-guide.md"
  - "/docs/project/build-engineer-next-steps.md"
  - "/mcp-project/docs/README.md"
tags: ["documentation-hub", "organization", "navigation", "dual-layer"]
---

# ScopeCam MCP Documentation Hub

🟢 **Active**

[↩️ Back to Project Root](/README.md)

## Documentation Organization Overview

The ScopeCam MCP project uses a **dual-layer documentation structure** that mirrors the code organization:

```
/home/verlyn13/Projects/mcp-scope/       # ROOT PROJECT LAYER
├── README.md                            # Root project dashboard
├── docs/                                # ROOT DOCUMENTATION LAYER
│   ├── README.md                        # This document - Navigation hub
│   ├── project/                         # Project-level information
│   └── guides/                          # Implementation and technical guides
└── mcp-project/                         # MCP IMPLEMENTATION LAYER
    ├── README.md                        # MCP implementation dashboard
    └── docs/                            # MCP DOCUMENTATION LAYER
        ├── README.md                    # MCP documentation index
        ├── project/                     # MCP project information
        ├── architecture/                # MCP architecture details
        ├── implementation/              # Implementation guides
        └── standards/                   # Documentation standards
```

### Documentation Layers

This project uses a dual-layer documentation approach for clear organization:

1. **Root Documentation Layer** (📁 `/docs/`)
   - **Purpose**: Project-wide information and ScopeCam integration
   - **Audience**: All stakeholders, system integrators, project managers
   - **Content**: Project vision, integration guides, organizational structure

2. **MCP Documentation Layer** (📁 `/mcp-project/docs/`)
   - **Purpose**: Detailed MCP implementation guides and technical information
   - **Audience**: Developers implementing or extending the MCP
   - **Content**: Architecture details, implementation guides, API specifications

## Path References 

To ensure there are no path mixups, we have created a dedicated guide:

> ⚠️ **IMPORTANT**: Always review the [Path Reference Guide](/docs/project/path-reference-guide.md) before adding cross-references in documentation to ensure correct paths.

This guide provides examples, decision trees, and quick reference tables to eliminate path confusion. Always use repository-relative paths with the correct layer prefix.

## Documentation Status System

Both documentation layers follow the same status system:

| Status | Indicator | Description | 
|--------|-----------|-------------|
| 🟢 **Active** | `🟢 **Active**` | Current, reviewed and approved |
| 🟡 **Draft** | `🟡 **Draft**` | Work in progress, subject to change |
| 🟠 **Review** | `🟠 **Review**` | Complete but pending final approval |
| 🔴 **Outdated** | `🔴 **Outdated**` | Contains older information that needs updating |
| ⚫ **Archived** | `⚫ **Archived**` | Historical information, no longer applicable |

## Tagging System

All documentation uses YAML front matter with tags following these conventions:

- **Layer-specific tags**: 
  - Root docs: `project-wide`, `integration`, `scope`, `organization`
  - MCP docs: `implementation`, `architecture`, `technical`

- **Common tags**:
  - Topic areas: `camera`, `agents`, `nats`, `orchestration`, `testing`, `health`
  - Doc types: `guide`, `reference`, `specification`, `tutorial`
  - Status: `active`, `draft`, `review`

## Navigating Documentation

### Root Documentation Layer 

- **Start here** for project-wide concerns and understanding how MCP fits into the broader ScopeCam project

Documents in this layer:

- [Project Organization](/docs/project/project-organization.md) - Structure and organization 🟢
- [Path Reference Guide](/docs/project/path-reference-guide.md) - Definitive path usage guide 🟢
- [Build Engineer Next Steps](/docs/project/build-engineer-next-steps.md) - Task roadmap for build engineers 🟢

Technical Guides:

- [Testing Guide](/docs/guides/testing-guide.md) - Testing infrastructure and best practices 🟢
- [Health Monitoring Guide](/docs/guides/health-monitoring-guide.md) - Health monitoring system documentation 🟢
- [Containerized Development Environment](/docs/guides/containerized-dev-environment.md) - Development environment setup 🟢

### MCP Documentation Layer

- **Start at the [MCP Documentation Index](/mcp-project/docs/README.md)** for implementation and development-focused documentation

Key MCP documents:

- [First Steps Guide](/mcp-project/docs/project/first-steps.md) - Getting started with MCP development 🟢
- [Architecture Overview](/mcp-project/docs/architecture/overview.md) - System design and components 🟢
- [Project Setup](/mcp-project/docs/implementation/project-setup.md) - Development environment setup 🟢

## Documentation Standards

All documentation in both layers follows the standards defined in:

- [Documentation Guidelines](/mcp-project/docs/standards/documentation-guidelines.md)

Key requirements across both layers:

1. YAML front matter with title, status, version, dates, contributors, related_docs, and tags
2. Status indicator immediately following the main heading
3. Consistent section structure and formatting
4. Cross-references using repository-relative paths
5. Back navigation links to relevant index documents

## Contributing to Documentation

When contributing new documentation:

1. **First, determine the appropriate layer**:
   - Project-wide or integration concerns → Root documentation layer
   - MCP implementation details → MCP documentation layer

2. **Then, determine the appropriate directory** within that layer based on the content type:
   - `project/` - Project information, planning, roadmaps
   - `guides/` - Technical guides and implementation instructions
   - `architecture/` - System design and component specifications
   - `implementation/` - Development guides and how-to content
   - `standards/` - Guidelines and best practices

3. **Follow the [Documentation Guidelines](/mcp-project/docs/standards/documentation-guidelines.md)**

4. **Use the [Path Reference Guide](/docs/project/path-reference-guide.md) to ensure correct paths**

5. **Update relevant index files** with links to the new document

## Project Team Resources

For team members working on specific aspects of the project:

- **For Build Engineers**: Start with [Build Engineer Next Steps](/docs/project/build-engineer-next-steps.md)
- **For Testing**: Use the [Testing Guide](/docs/guides/testing-guide.md)
- **For Health Monitoring**: Refer to the [Health Monitoring Guide](/docs/guides/health-monitoring-guide.md)
- **For Development Environment**: See the [Containerized Development Environment](/docs/guides/containerized-dev-environment.md)

## Changelog

- 1.4.0 (2025-03-23): Added new guides for testing, health monitoring, and containerized development
- 1.3.0 (2025-03-22): Added reference to Build Engineer Next Steps document
- 1.2.0 (2025-03-22): Added reference to the Path Reference Guide
- 1.1.0 (2025-03-22): Enhanced with dual-layer documentation explanation
- 1.0.0 (2025-03-22): Initial release