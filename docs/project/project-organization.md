---
title: "Dual-Layer Project Organization"
status: "Active"
version: "1.1"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/README.md"
  - "/docs/README.md"
  - "/mcp-project/docs/README.md"
  - "/mcp-project/docs/standards/documentation-guidelines.md"
tags: ["project-wide", "organization", "structure", "paths", "dual-layer"]
---

# Dual-Layer Project Organization

🟢 **Active**

[↩️ Back to Documentation Hub](/docs/README.md)

## Overview

The ScopeCam MCP project uses a **dual-layer architecture** for both code and documentation. This document clarifies this organizational approach to ensure consistent development and documentation practices across the project.

## Dual-Layer Project Structure

The project is organized into two distinct but related layers:

<table>
  <tr>
    <th>Layer</th>
    <th>Purpose</th>
    <th>Primary Path</th>
    <th>Documentation Path</th>
  </tr>
  <tr>
    <td><b>Root Project Layer</b></td>
    <td>ScopeCam project that integrates MCP for microscope control</td>
    <td><code>/home/verlyn13/Projects/mcp-scope/</code></td>
    <td><code>/docs/</code></td>
  </tr>
  <tr>
    <td><b>MCP Implementation Layer</b></td>
    <td>Multi-Agent Control Platform implementation</td>
    <td><code>/home/verlyn13/Projects/mcp-scope/mcp-project/</code></td>
    <td><code>/mcp-project/docs/</code></td>
  </tr>
</table>

### Visual Representation of Layers

```
/home/verlyn13/Projects/mcp-scope/     # ROOT PROJECT LAYER
├── README.md                          # Root README dashboard
├── docs/                              # ROOT DOCUMENTATION LAYER
│   ├── README.md                      # Documentation hub
│   └── project/
│       └── project-organization.md    # This file
│
└── mcp-project/                       # MCP IMPLEMENTATION LAYER
    ├── README.md                      # MCP README
    ├── mcp-core/                      # Core platform code
    ├── agents/                        # Agent implementations
    │   ├── camera-agent/              # Camera integration
    │   └── python-processor/          # Python processing
    ├── nats/                          # NATS configuration
    │
    └── docs/                          # MCP DOCUMENTATION LAYER
        ├── README.md                  # MCP docs index
        ├── project/                   # Project information
        ├── architecture/              # Architecture design
        ├── implementation/            # Implementation guides
        └── standards/                 # Project standards
```

## Documentation Layer Purpose and Scope

Each documentation layer has a specific purpose and scope:

### Root Documentation Layer (`/docs/`)

**Purpose**: Provide project-wide context and integration information for the ScopeCam project.

**Appropriate Content**:
- Project vision and goals
- Integration of MCP with ScopeCam hardware
- Project-wide organizational documents
- High-level architectural decisions affecting both layers
- Project history and background

**Examples**:
- Project organization (this document)
- Integration guides
- Project roadmap

### MCP Documentation Layer (`/mcp-project/docs/`)

**Purpose**: Provide detailed technical documentation for the MCP implementation.

**Appropriate Content**:
- MCP architecture specifications
- Implementation guides for MCP components
- Agent development documentation
- API specifications
- Development environment setup

**Examples**:
- Architecture overview
- Agent implementation guides
- Development environment setup

## Consistent Documentation Standards

While split into two layers, **all documentation follows the same standards**:

1. **Identical Status System**
   - 🟢 **Active**: Current, reviewed and approved
   - 🟡 **Draft**: Work in progress, subject to change
   - 🟠 **Review**: Complete but pending final approval
   - 🔴 **Outdated**: Contains older information that needs updating
   - ⚫ **Archived**: Historical information, no longer applicable

2. **Consistent Front Matter**
   - All documents use YAML front matter with the same fields
   - Tags indicate the layer, document type, and content area
   - Cross-references connect related documents across layers

3. **Unified Layout and Formatting**
   - Same heading hierarchy
   - Same section organization
   - Consistent use of admonitions and callouts

## Layer-Specific Document Tags

To distinguish which layer a document belongs to, use these tags:

- **Root documentation tags**:
  - `project-wide` - Applies to the entire project
  - `integration` - Related to ScopeCam hardware integration
  - `organization` - Project organization and structure

- **MCP documentation tags**:
  - `mcp-core` - Related to the core MCP platform
  - `mcp-agent` - Related to MCP agents
  - `implementation` - Detailed implementation information

## Path References Between Layers

When referencing documents across layers:

1. **Root to MCP references**:
   - Use repository-relative paths: `/mcp-project/docs/architecture/overview.md`

2. **MCP to Root references**:
   - Use repository-relative paths: `/docs/project/project-organization.md`

3. **Visual indicators**:
   - When referencing a document in another layer, use a 🔄 symbol:
     ```markdown
     [🔄 MCP Architecture Overview](/mcp-project/docs/architecture/overview.md)
     ```

## Development Path Best Practices

When working with code and running commands:

1. **Always be aware of your current working directory**:
   - Root commands run from: `/home/verlyn13/Projects/mcp-scope/`
   - MCP implementation commands run from: `/home/verlyn13/Projects/mcp-scope/mcp-project/`

2. **Specify the project context** when discussing development:
   - "From the root project directory..."
   - "From the MCP implementation directory..."

3. **Use relative paths** within each layer:
   - Root project: `./docs/project/project-organization.md`
   - MCP project: `./agents/camera-agent/src/main/kotlin/...`

## Benefit of the Dual-Layer Approach

This dual-layer approach provides several benefits:

1. **Clear Separation of Concerns**
   - ScopeCam-specific integration separated from MCP implementation
   - Allows MCP to potentially be reused in other projects

2. **Focused Documentation**
   - Stakeholders can focus on their area of interest
   - Reduces documentation complexity within each layer

3. **Parallel with Code Structure**
   - Documentation organization mirrors code organization
   - Makes documentation more discoverable

## Document Naming Conventions

Document naming conventions apply to both layers:

1. **Use lowercase kebab-case** for all document names:
   - `project-organization.md` (✅ correct)
   - `Project Organization.md` (❌ incorrect)

2. **Use consistent suffixes** for specific document types:
   - Implementation guides: `-guide.md`
   - Technical specifications: `-spec.md`
   - Architecture decisions: `-adr.md`

## Changelog

- 1.1.0 (2025-03-22): Enhanced with layer-specific tagging and path guidance
- 1.0.0 (2025-03-22): Initial release