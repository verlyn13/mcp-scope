---
title: "ScopeCam MCP Documentation"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect", "Build Engineer"]
tags: ["documentation-hub", "organization", "navigation"]
---

# ScopeCam MCP Documentation

🟢 **Active**

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

## Documentation Layers

This project uses a dual-layer documentation approach for clear organization:

1. **Root Documentation Layer** 
   - **Purpose**: Project-wide information and ScopeCam integration
   - **Audience**: All stakeholders, system integrators, project managers
   - **Content**: Project vision, integration guides, organizational structure

2. **MCP Documentation Layer**
   - **Purpose**: Detailed MCP implementation guides and technical information
   - **Audience**: Developers implementing or extending the MCP
   - **Content**: Architecture details, implementation guides, API specifications

## Documentation Status System

Both documentation layers follow the same status system:

| Status | Indicator | Description | 
|--------|-----------|-------------|
| 🟢 **Active** | `🟢 **Active**` | Current, reviewed and approved |
| 🟡 **Draft** | `🟡 **Draft**` | Work in progress, subject to change |
| 🟠 **Review** | `🟠 **Review**` | Complete but pending final approval |
| 🔴 **Outdated** | `🔴 **Outdated**` | Contains older information that needs updating |
| ⚫ **Archived** | `⚫ **Archived**` | Historical information, no longer applicable |

## Key Documentation

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

- **Start here** for implementation and development-focused documentation

Key MCP documents:

- [First Steps Guide](/mcp/project/first-steps/) - Getting started with MCP development 🟢
- [Architecture Overview](/mcp/architecture/overview/) - System design and components 🟢
- [Project Setup](/mcp/implementation/project-setup/) - Development environment setup 🟢

## Project Dashboard

<table>
  <tr>
    <td width="33%" align="center">
      <img src="https://via.placeholder.com/80x80?text=📡" alt="MCP Core" width="80" height="80"/><br/>
      <b>MCP Core</b><br/>
      <span>Orchestration Engine</span><br/>
      <img src="https://progress-bar.dev/100" width="100" alt="100%">
    </td>
    <td width="33%" align="center">
      <img src="https://via.placeholder.com/80x80?text=📷" alt="ScopeCam" width="80" height="80"/><br/>
      <b>ScopeCam Integration</b><br/>
      <span>USB Camera Management</span><br/>
      <img src="https://progress-bar.dev/80" width="100" alt="80%">
    </td>
    <td width="33%" align="center">
      <img src="https://via.placeholder.com/80x80?text=🔄" alt="Agents" width="80" height="80"/><br/>
      <b>Agent Network</b><br/>
      <span>Collaborative Processing</span><br/>
      <img src="https://progress-bar.dev/90" width="100" alt="90%">
    </td>
  </tr>
</table>

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

3. **Follow the [Documentation Guidelines](/standards/documentation-guidelines/)**

4. **Update relevant index files** with links to the new document