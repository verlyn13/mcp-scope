---
title: "Dual-Layer Project Organization"
status: "Active"
version: "1.2"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/"
  - "/project/path-reference-guide/"
  - "/mcp/docs/"
  - "/standards/documentation-guidelines/"
tags: ["project-wide", "organization", "structure", "paths", "dual-layer", "hugo"]
---

# Dual-Layer Project Organization

{{< status >}}

[↩️ Back to Project Documentation](/project/) | [↩️ Back to Documentation Index](/docs/)

## Overview

The ScopeCam MCP project uses a **dual-layer architecture** for both code and documentation. This document clarifies this organizational approach to ensure consistent development and documentation practices across the project.

{{< callout "info" "Dual-Layer Architecture" >}}
Understanding the dual-layer approach is essential for correctly navigating the project structure, understanding documentation paths, and contributing to the right areas of the project.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Dual-Layer Project Structure

The project is organized into two distinct but related layers:

| Layer | Purpose | Primary Path | Documentation Path |
|-------|---------|--------------|-------------------|
| **Root Project Layer** | ScopeCam project that integrates MCP for microscope control | `/home/verlyn13/Projects/mcp-scope/` | `/docs/` |
| **MCP Implementation Layer** | Multi-Agent Control Platform implementation | `/home/verlyn13/Projects/mcp-scope/mcp-project/` | `/mcp-project/docs/` |

### Visual Representation of Original Repository Layers

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

### Hugo Documentation Structure

In the Hugo static site, the documentation is organized into these main sections:

```
content/                               # HUGO CONTENT ROOT
├── _index.md                          # Homepage
├── docs/                              # Documentation index
│   └── _index.md
├── architecture/                      # Architecture documents
│   ├── _index.md
│   └── ...
├── guides/                            # Implementation guides
│   ├── _index.md
│   └── ...
├── project/                           # Project documentation
│   ├── _index.md
│   └── project-organization.md        # This file
├── standards/                         # Standards and guidelines
│   ├── _index.md
│   └── ...
└── mcp/                               # MCP-specific documentation
    ├── _index.md
    ├── docs/                          # MCP general docs
    ├── architecture/                  # MCP architecture docs
    └── implementation/                # MCP implementation docs
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

### MCP Documentation Layer (`/mcp/`)

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

## Implementation Progress

| Component | Status | Completion |
|-----------|--------|------------|
| Root Documentation | 🟢 Active | {{< progress value="95" >}} |
| MCP Documentation | 🟢 Active | {{< progress value="85" >}} |
| Hugo Migration | 🟢 Active | {{< progress value="64" >}} |
| Documentation Standards | 🟢 Active | {{< progress value="100" >}} |
| Path References | 🟢 Active | {{< progress value="90" >}} |

## Consistent Documentation Standards

While split into two layers, **all documentation follows the same standards**:

{{< callout "tip" "Documentation Consistency" >}}
Using consistent standards across both layers ensures a seamless experience when navigating between different parts of the documentation.
{{< /callout >}}

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
   - Consistent use of callouts and admonitions

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

## Hugo Path References

In the Hugo static site, all internal links follow these conventions:

1. **No File Extensions**: URLs don't include `.md` or `.html` extensions
2. **Trailing Slash**: URLs typically end with a trailing slash
3. **Section Structure**: Content is organized into sections that correspond to top-level directories

Examples:

| Content Type | Original Repository Path | Hugo URL |
|--------------|--------------------------|----------|
| Root Document | `/docs/project/project-organization.md` | `/project/project-organization/` |
| MCP Document | `/mcp-project/docs/architecture/overview.md` | `/mcp/architecture/overview/` |

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

## Hugo Migration Considerations

{{< callout "note" "Hugo Migration" >}}
The migration to Hugo maintains the dual-layer concept while enhancing navigation and readability through Hugo's features.
{{< /callout >}}

When migrating documentation to Hugo:

1. **Preserve Layer Distinction**
   - Root documents remain in top-level sections
   - MCP documents are placed in the `/mcp/` section

2. **Update Path References**
   - Convert repository paths to Hugo URLs
   - Remove file extensions
   - Add trailing slashes

3. **Enhance with Hugo Features**
   - Use shortcodes for status, progress, and callouts
   - Add table of contents for navigation
   - Implement consistent section organization

## Related Documentation

For more information on documentation organization and paths, see:

- [Path Reference Guide](/project/path-reference-guide/)
- [Documentation Guidelines](/standards/documentation-guidelines/)
- [Documentation Migration Plan](/project/documentation-migration-plan/)

{{< related-docs >}}

## Changelog

- 1.2.0 (2025-03-23): Updated for Hugo migration with new path references
- 1.1.0 (2025-03-22): Enhanced with layer-specific tagging and path guidance
- 1.0.0 (2025-03-22): Initial release