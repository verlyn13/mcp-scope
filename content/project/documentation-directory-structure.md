---
title: "Documentation Directory Structure"
status: "Active"
version: "1.1"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/"
  - "/project/documentation-migration-plan/"
  - "/standards/documentation-guidelines/"
  - "/project/phase3-progress/"
tags: ["documentation", "organization", "structure", "hugo"]
---

# Documentation Directory Structure

{{< status >}}

[↩️ Back to Project Documentation](/project/) | [↩️ Back to Documentation Index](/docs/)

## Overview

This document provides a visual representation of the MCP documentation system's directory structure in both the original repository format and the new Hugo static site format. It serves as a map for navigating and maintaining the documentation.

{{< callout "info" "Directory Structure" >}}
Understanding the documentation structure is essential for correct file placement, navigation, and cross-referencing across the project.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Original Repository Structure

The original repository used this directory structure:

```
docs/
├── README.md                                # Documentation system index
│
├── project/                                 # Project-level information
│   ├── project-overview.md                  # Project introduction and goals
│   ├── strategic-plan.md                    # Overall project strategy
│   ├── first-steps.md                       # Initial setup and onboarding
│   ├── implementation-roadmap.md            # Phase-by-phase implementation plan
│   ├── issues-registry.md                   # Known issues and pitfalls
│   └── documentation-migration-plan.md      # Plan for documentation migration
│
├── architecture/                            # System design documentation
│   ├── overview.md                          # High-level architecture overview
│   ├── fsm-agent-interfaces.md              # Core agent framework specification
│   ├── orchestrator-nats-integration.md     # Orchestrator design
│   ├── camera-integration-agent.md          # Camera agent specification
│   ├── health-monitoring-framework.md       # Health monitoring framework
│   │
│   └── decision-records/                    # Architecture decision records
│       ├── template.md                      # ADR template
│       ├── 0001-kotlin-selection.md         # Decision to use Kotlin
│       └── 0002-nats-messaging.md           # Decision to use NATS
│
├── implementation/                          # Implementation guides
│   ├── project-setup.md                     # Environment and project setup
│   ├── core-framework.md                    # FSM implementation guide
│   ├── nats-configuration.md                # NATS messaging setup
│   ├── camera-agent-implementation.md       # Camera agent implementation
│   ├── health-monitoring-implementation.md  # Health monitoring implementation
│   │
│   └── examples/                            # Implementation examples
│       ├── basic-agent.md                   # Basic agent implementation
│       └── orchestrator-setup.md            # Orchestrator setup example
│
├── standards/                               # Guidelines and standards
│   ├── documentation-guidelines.md          # Documentation format and process
│   ├── coding-conventions.md                # Kotlin coding standards
│   └── testing-standards.md                 # Testing approach and standards
│
├── templates/                               # Document templates
│   ├── architecture-component-template.md   # For architecture components
│   ├── implementation-guide-template.md     # For implementation guides
│   └── api-documentation-template.md        # For API documentation
│
└── consolidated/                            # Single-source-of-truth copies
    ├── mcp-complete-architecture.md         # Complete architecture in one file
    └── mcp-implementation-handbook.md       # Complete implementation guide
```

## Hugo Content Structure

The Hugo documentation site uses this content structure:

```
content/                                     # Hugo content root
├── _index.md                                # Site homepage
│
├── docs/                                    # Documentation index
│   └── _index.md                            # Documentation home page
│
├── project/                                 # Project-level information
│   ├── _index.md                            # Project section index
│   ├── current-focus.md                     # Current project focus
│   ├── implementation-roadmap.md            # Implementation plan
│   ├── issues-registry.md                   # Known issues registry
│   ├── path-reference-guide.md              # Path reference guide
│   ├── project-organization.md              # Project organization info
│   ├── documentation-migration-plan.md      # Documentation migration plan
│   ├── documentation-directory-structure.md # This file
│   ├── build-engineer-next-steps.md         # Build engineer tasks
│   ├── contributing.md                      # Contribution guidelines
│   └── phase3-progress.md                   # Migration progress tracking
│
├── architecture/                            # Architecture documentation
│   ├── _index.md                            # Architecture section index
│   ├── overview.md                          # Architecture overview
│   ├── fsm-agent-interfaces.md              # Agent interfaces
│   ├── orchestrator-nats-integration.md     # NATS integration
│   ├── camera-integration-agent.md          # Camera agent
│   └── health-monitoring-framework.md       # Health monitoring
│
├── guides/                                  # Implementation guides
│   ├── _index.md                            # Guides section index
│   ├── build-engineer-implementation-guide.md  # Implementation guide
│   ├── build-engineer-onboarding-checklist.md # Onboarding checklist
│   ├── build-engineer-quick-start.md        # Quick start guide
│   ├── build-engineer-tech-specs.md         # Technical specifications
│   ├── containerized-dev-environment.md     # Container environment
│   ├── health-monitoring-guide.md           # Health monitoring
│   └── testing-guide.md                     # Testing guide
│
├── standards/                               # Guidelines and standards
│   ├── _index.md                            # Standards section index
│   └── documentation-guidelines.md          # Documentation guidelines
│
├── templates/                               # Document templates
│   ├── _index.md                            # Templates section index
│   ├── architecture-component-template.md   # Architecture template
│   ├── implementation-guide-template.md     # Implementation template
│   └── api-documentation-template.md        # API documentation template
│
└── mcp/                                     # MCP-specific documentation
    ├── _index.md                            # MCP section index
    ├── docs/                                # MCP general docs
    │   ├── _index.md                        # MCP docs index
    │   ├── environment-setup.md             # Environment setup
    │   ├── getting-started.md               # Getting started
    │   └── project-setup.md                 # Project setup
    ├── architecture/                        # MCP architecture docs
    │   ├── _index.md                        # MCP architecture index
    │   └── overview.md                      # MCP architecture overview
    └── implementation/                      # MCP implementation docs
        └── _index.md                        # MCP implementation index
```

## Implementation Progress

| Directory | Status | Completion |
|-----------|--------|------------|
| Project Documentation | 🟢 Active | {{< progress value="90" >}} |
| Architecture Documentation | 🟢 Active | {{< progress value="100" >}} |
| Guides | 🟢 Active | {{< progress value="100" >}} |
| Standards | 🟢 Active | {{< progress value="70" >}} |
| Templates | 🟡 Draft | {{< progress value="10" >}} |
| MCP Documentation | 🟢 Active | {{< progress value="75" >}} |
| Section Indices | 🟢 Active | {{< progress value="80" >}} |

## Key Directory Purposes

### Project Documentation (`/project/`)

The `project/` directory contains high-level information about the MCP project, including:

- Project overview and goals
- Strategic planning
- Implementation roadmap
- Issues registry
- Documentation management

These documents provide context and direction for the entire project.

### Architecture Documentation (`/architecture/`)

The `architecture/` directory contains system design documentation, including:

- High-level architecture overview
- Component specifications
- Architecture Decision Records (ADRs)

Architecture documents focus on the "what" and "why" of the system design.

### Implementation Guides (`/guides/`)

The `guides/` directory contains practical guides for developers, including:

- Setup instructions
- Implementation guides for specific components
- Configuration details
- Examples and code snippets

Implementation documents focus on the "how" of building the system.

### Standards Documentation (`/standards/`)

The `standards/` directory contains guidelines and best practices, including:

- Documentation standards
- Coding conventions
- Testing standards

These documents ensure consistency across the project.

### Templates (`/templates/`)

The `templates/` directory contains standardized formats for different document types to ensure consistency.

### MCP-specific Documentation (`/mcp/`)

The `mcp/` directory contains documentation specific to the MCP implementation, organized into:

- General documentation (`/mcp/docs/`)
- Architecture documentation (`/mcp/architecture/`)
- Implementation documentation (`/mcp/implementation/`)

## Hugo-Specific Features

{{< callout "tip" "Hugo Organization" >}}
Hugo's content organization relies on section folders with `_index.md` files that define section properties and provide landing pages for each section.
{{< /callout >}}

### Section Index Files

Each directory in the Hugo content structure includes an `_index.md` file that:

1. Defines the section's title, description, and metadata
2. Provides a landing page for that section
3. Can include a list of pages in that section

Example:

```yaml
---
title: "Project Documentation"
description: "Project-level information including roadmaps, plans, and organization."
weight: 2
---

# Project Documentation

This section contains high-level information about the MCP project...
```

### Content Organization

Hugo content is organized by:

1. **Sections**: Top-level directories in the `content/` folder
2. **Pages**: Individual content files within sections
3. **Taxonomy**: Tags and categories that cross-reference content

## Navigation Principles

1. **Index-First Navigation**: Section index pages serve as the entry point
2. **Hierarchical Structure**: Documents are organized in a logical hierarchy
3. **Cross-References**: Related documents are linked via front matter and shortcodes
4. **Breadcrumb Links**: Each document includes navigation links to parent sections

## Maintenance Guidelines

1. **Directory Consistency**: Maintain the established directory structure
2. **File Naming**: Follow kebab-case naming convention
3. **New Sections**: When creating new sections, add an `_index.md` file
4. **Status Updates**: Keep document status indicators current
5. **Cross-References**: Update related_docs in front matter when adding new relationships

## Future Expansion

The structure is designed to accommodate future growth:

1. **Additional Component Documentation**: New architecture components can be added
2. **Expanded Implementation Guides**: As implementation progresses
3. **Additional Standards**: As development practices evolve
4. **API Documentation**: Dedicated section for API references may be added
5. **User Guides**: End-user documentation may be added in later phases

## Related Documentation

{{< related-docs >}}

## Changelog

- 1.1.0 (2025-03-23): Updated for Hugo structure and added implementation progress
- 1.0.0 (2025-03-22): Initial release