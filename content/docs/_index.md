---
title: "ScopeCam MCP Documentation Hub"
status: "Active"
version: "2.0"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
related_docs:
  - "/"
  - "/project/project-organization/"
  - "/project/path-reference-guide/"
  - "/project/build-engineer-next-steps/"
  - "/mcp/docs/"
tags: ["documentation-hub", "organization", "navigation", "dual-layer"]
---

# ScopeCam MCP Documentation Hub

{{< status >}}

[↩️ Back to Home](/)

## Documentation Organization Overview

The ScopeCam MCP project uses a **dual-layer documentation structure** that mirrors the code organization:

```
content/                              # HUGO ROOT
├── _index.md                         # Homepage
├── docs/                             # ROOT DOCUMENTATION LAYER
│   ├── _index.md                     # This document - Navigation hub
│   └── ...                           # Other documentation files
├── project/                          # Project-level information
│   ├── _index.md                     # Project section index
│   └── ...                           # Project documents
├── guides/                           # Implementation and technical guides
│   ├── _index.md                     # Guides section index
│   └── ...                           # Guide documents
├── architecture/                     # Architecture documentation
│   ├── _index.md                     # Architecture section index
│   └── ...                           # Architecture documents
├── standards/                        # Standards documentation
│   ├── _index.md                     # Standards section index
│   └── ...                           # Standards documents
├── templates/                        # Templates
│   ├── _index.md                     # Templates section index
│   └── ...                           # Template documents
└── mcp/                              # MCP IMPLEMENTATION LAYER
    ├── _index.md                     # MCP section overview
    ├── docs/                         # MCP DOCUMENTATION LAYER
    │   ├── _index.md                 # MCP documentation index
    │   └── ...                       # MCP documents
    ├── architecture/                 # MCP architecture details
    ├── implementation/               # Implementation guides
    └── project/                      # MCP project information
```

### Documentation Layers

This project uses a dual-layer documentation approach for clear organization:

1. **Root Documentation Layer** (placed in root content sections)
   - **Purpose**: Project-wide information and ScopeCam integration
   - **Audience**: All stakeholders, system integrators, project managers
   - **Content**: Project vision, integration guides, organizational structure

2. **MCP Documentation Layer** (placed in `/mcp/` subdirectories)
   - **Purpose**: Detailed MCP implementation guides and technical information
   - **Audience**: Developers implementing or extending the MCP
   - **Content**: Architecture details, implementation guides, API specifications

## Path References 

To ensure there are no path mixups, we have created a dedicated guide:

> ⚠️ **IMPORTANT**: Always review the [Path Reference Guide](/project/path-reference-guide/) before adding cross-references in documentation to ensure correct paths.

This guide provides examples, decision trees, and quick reference tables to eliminate path confusion. In Hugo, always use relative paths that start from the site root.

## Documentation Status System

Both documentation layers follow the same status system, implemented with Hugo shortcodes:

| Status | Indicator | Hugo Shortcode | Description | 
|--------|-----------|----------------|-------------|
| 🟢 **Active** | `🟢 **Active**` | `{{</* status "Active" */>}}` | Current, reviewed and approved |
| 🟡 **Draft** | `🟡 **Draft**` | `{{</* status "Draft" */>}}` | Work in progress, subject to change |
| 🟠 **Review** | `🟠 **Review**` | `{{</* status "Review" */>}}` | Complete but pending final approval |
| 🔴 **Outdated** | `🔴 **Outdated**` | `{{</* status "Outdated" */>}}` | Contains older information that needs updating |
| ⚫ **Archived** | `⚫ **Archived**` | `{{</* status "Archived" */>}}` | Historical information, no longer applicable |

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

- [Project Organization](/project/project-organization/) - Structure and organization 🟢
- [Path Reference Guide](/project/path-reference-guide/) - Definitive path usage guide 🟢
- [Build Engineer Next Steps](/project/build-engineer-next-steps/) - Task roadmap for build engineers 🟢

Technical Guides:

- [Testing Guide](/guides/testing-guide/) - Testing infrastructure and best practices 🟢
- [Health Monitoring Guide](/guides/health-monitoring-guide/) - Health monitoring system documentation 🟢
- [Containerized Development Environment](/guides/containerized-dev-environment/) - Development environment setup 🟢

### MCP Documentation Layer

- **Start at the [MCP Documentation Index](/mcp/docs/)** for implementation and development-focused documentation

Key MCP documents:

- [First Steps Guide](/mcp/project/first-steps/) - Getting started with MCP development 🟢
- [Architecture Overview](/mcp/architecture/overview/) - System design and components 🟢
- [Project Setup](/mcp/implementation/project-setup/) - Development environment setup 🟢

## Documentation Standards

All documentation in both layers follows the standards defined in:

- [Documentation Guidelines](/standards/documentation-guidelines/)

Key requirements across both layers:

1. YAML front matter with title, status, version, dates, contributors, related_docs, and tags
2. Status indicator immediately following the main heading (using the status shortcode)
3. Consistent section structure and formatting
4. Cross-references using Hugo-style paths (e.g., `/section/page/`)
5. Back navigation links to relevant index documents

## Hugo-Specific Features

The Hugo documentation site offers additional features:

1. **Shortcodes**:
   - `{{</* status */>}}` - Display document status based on front matter
   - `{{</* progress value="75" */>}}` - Display a progress bar
   - `{{</* related-docs */>}}` - Display related documents from front matter

2. **Section Navigation**:
   - Automatically generated section indices
   - Breadcrumb navigation
   - Table of contents for each page

3. **Search Functionality**:
   - Full-text search across all documentation

## Contributing to Documentation

When contributing new documentation:

1. **First, determine the appropriate layer**:
   - Project-wide or integration concerns → Root documentation layer
   - MCP implementation details → MCP documentation layer

2. **Then, determine the appropriate directory** within that layer based on the content type:
   - `project/` - Project information, planning, roadmaps
   - `guides/` - Technical guides and implementation instructions
   - `architecture/` - System design and component specifications
   - `standards/` - Guidelines and best practices
   - `templates/` - Document templates

3. **Follow the [Documentation Guidelines](/standards/documentation-guidelines/)**

4. **Use Hugo-style paths for links** (`/section/page/`)

5. **Update relevant index files** with links to the new document

## Project Team Resources

For team members working on specific aspects of the project:

- **For Build Engineers**: Start with [Build Engineer Next Steps](/project/build-engineer-next-steps/)
- **For Testing**: Use the [Testing Guide](/guides/testing-guide/)
- **For Health Monitoring**: Refer to the [Health Monitoring Guide](/guides/health-monitoring-guide/)
- **For Development Environment**: See the [Containerized Development Environment](/guides/containerized-dev-environment/)

## Available Sections

| Section | Description | Key Documents |
|---------|-------------|--------------|
| [Project](/project/) | Project information | [Project Organization](/project/project-organization/), [Current Focus](/project/current-focus/) |
| [Guides](/guides/) | Implementation guides | [Build Engineer Guides](/guides/build-engineer-implementation-guide/), [Containerized Development](/guides/containerized-dev-environment/) |
| [Architecture](/architecture/) | System design | [Architecture Overview](/architecture/overview/), [Component Specifications](/architecture/fsm-agent-interfaces/) |
| [Standards](/standards/) | Documentation standards | [Documentation Guidelines](/standards/documentation-guidelines/) |
| [Templates](/templates/) | Document templates | [Architecture Component Template](/templates/architecture-component-template/) |
| [MCP](/mcp/) | Implementation layer | [MCP Documentation](/mcp/docs/), [MCP Architecture](/mcp/architecture/) |

## Changelog

- 2.0.0 (2025-03-23): Updated for Hugo documentation site
- 1.4.0 (2025-03-23): Added new guides for testing, health monitoring, and containerized development
- 1.3.0 (2025-03-22): Added reference to Build Engineer Next Steps document
- 1.2.0 (2025-03-22): Added reference to the Path Reference Guide
- 1.1.0 (2025-03-22): Enhanced with dual-layer documentation explanation
- 1.0.0 (2025-03-22): Initial release