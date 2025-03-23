---
title: "Documentation Directory Structure"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/README.md"
  - "/docs/project/documentation-migration-plan.md"
  - "/docs/standards/documentation-guidelines.md"
tags: ["documentation", "organization", "structure"]
---

# Documentation Directory Structure

[↩️ Back to Documentation Index](/docs/README.md)

## Overview

This document provides a visual representation of the MCP documentation system's directory structure. It serves as a map for navigating and maintaining the documentation.

## Complete Directory Structure

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

## Key Directory Purposes

### Project Documentation

The `project/` directory contains high-level information about the MCP project, including:

- Project overview and goals
- Strategic planning
- Implementation roadmap
- Issues registry
- Documentation management

These documents provide context and direction for the entire project.

### Architecture Documentation

The `architecture/` directory contains system design documentation, including:

- High-level architecture overview
- Component specifications
- Architecture Decision Records (ADRs)

Architecture documents focus on the "what" and "why" of the system design.

### Implementation Documentation

The `implementation/` directory contains practical guides for developers, including:

- Setup instructions
- Implementation guides for specific components
- Configuration details
- Examples and code snippets

Implementation documents focus on the "how" of building the system.

### Standards Documentation

The `standards/` directory contains guidelines and best practices, including:

- Documentation standards
- Coding conventions
- Testing standards

These documents ensure consistency across the project.

### Templates

The `templates/` directory contains standardized formats for different document types to ensure consistency.

### Consolidated Documentation

The `consolidated/` directory contains comprehensive reference documents that bring together information from multiple sources for easier reference.

## Status Tracking

Each document includes a status indicator in its front matter:

| Status | Description | Count |
|--------|-------------|-------|
| 🟢 **Active** | Current, reviewed and approved | 6 |
| 🟡 **Draft** | Work in progress, subject to change | 10 |
| 🟠 **Review** | Complete but pending final approval | 0 |
| 🔴 **Outdated** | Contains older information that needs updating | 0 |
| ⚫ **Archived** | Historical information, no longer applicable | 0 |

## Navigation Principles

1. **Index-First Navigation**: The main README.md serves as the central index
2. **Hierarchical Structure**: Documents are organized in a logical hierarchy
3. **Cross-References**: Related documents are linked via front matter and inline references
4. **Breadcrumb Links**: Each document includes navigation links to parent sections

## Maintenance Guidelines

1. **Directory Consistency**: Maintain the established directory structure
2. **File Naming**: Follow kebab-case naming convention
3. **New Sections**: When creating new sections, update the main index
4. **Status Updates**: Keep document status indicators current
5. **Cross-References**: Update related_docs in front matter when adding new relationships

## Future Expansion

The structure is designed to accommodate future growth:

1. **Additional Component Documentation**: New architecture components can be added
2. **Expanded Implementation Guides**: As implementation progresses
3. **Additional Standards**: As development practices evolve
4. **API Documentation**: Dedicated section for API references may be added
5. **User Guides**: End-user documentation may be added in later phases

## Hugo Migration Path

When migrating to Hugo, this structure maps cleanly to Hugo's content organization:

- Each directory becomes a section in Hugo
- Front matter is already Hugo-compatible
- README.md files become _index.md files
- The structure supports Hugo's taxonomy system for tags