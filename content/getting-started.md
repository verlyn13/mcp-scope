---
title: "MCP Documentation Entry Point"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/"
  - "/project/current-focus/"
  - "/standards/documentation-guidelines/"
  - "/guides/build-engineer-implementation-guide/"
  - "/guides/build-engineer-onboarding-checklist/"
  - "/guides/build-engineer-tech-specs/"
tags: ["entry-point", "getting-started", "orientation"]
---

# START HERE: Multi-Agent Control Platform Documentation

{{< status >}}

## Welcome to the MCP Documentation System

This document is the **mandatory first stop** for all team members working on the Multi-Agent Control Platform. It will direct you to the information you need based on your role and the current project focus.

## Current Project Focus

> 🔍 **CURRENT FOCUS**: Phase 1 Implementation - Core Infrastructure
>
> We are currently focused on implementing the core infrastructure components of the MCP platform, including the FSM framework, agent interfaces, NATS messaging integration, and basic health monitoring.

For detailed information on the current focus area, see the [Current Focus](/project/current-focus/) document, which is updated weekly.

## Documentation Navigation by Role

### 👷 Implementers & Developers

1. First, review the [Current Focus](/project/current-focus/) document
2. Then, check the relevant [Implementation Guide](/mcp/implementation/) for your assigned component
3. Reference the corresponding [Architecture Specification](/architecture/) for design details
4. Be aware of any [Known Issues](/project/issues-registry/) related to your component

### 🔧 Build Engineers

1. **[Build Engineer Quick Start](/guides/build-engineer-quick-start/)** ⬅️ START HERE (5-minute guide)
2. Set up the [Containerized Development Environment](/guides/containerized-dev-environment/)
3. Follow the [Build Engineer Onboarding Checklist](/guides/build-engineer-onboarding-checklist/) for implementation sequence
4. Use the detailed [Build Engineer Implementation Guide](/guides/build-engineer-implementation-guide/) for step-by-step instructions
5. Reference the [Technical Specifications](/guides/build-engineer-tech-specs/) for architecture details
6. Review the [Implementation Roadmap](/architecture/implementation-roadmap/) for development sequence

### 🏛️ Architects

1. Start with the [Architecture Overview](/architecture/overview/)
2. Review the [Strategic Plan](/project/strategic-plan/)
3. Check the [Implementation Roadmap](/architecture/implementation-roadmap/)
4. Monitor the [Issues Registry](/project/issues-registry/) for design challenges

### 📝 Documentation Contributors

1. Review the [Documentation Guidelines](/standards/documentation-guidelines/)
2. Follow the [Documentation Migration Plan](/project/documentation-migration-plan/)
3. Use the appropriate [Document Templates](/templates/)
4. Update document status according to the guidelines

### 🔍 Reviewers & Auditors

1. Start with the [Current Focus](/project/current-focus/) document
2. Review relevant [Architecture Specifications](/architecture/)
3. Check the [Implementation Status](/project/implementation-status/)
4. Validate against the [Issues Registry](/project/issues-registry/)

## Documentation Status Legend

All documents in the system include a status indicator:

| Status | Description | Action Required |
|--------|-------------|-----------------|
| 🟢 **Active** | Current, reviewed and approved | Follow as authoritative guidance |
| 🟡 **Draft** | Work in progress, subject to change | Consider provisional, verify with team |
| 🟠 **Review** | Complete but pending final approval | Review and provide feedback |
| 🔴 **Outdated** | Contains older information that needs updating | Use with caution, check for newer versions |
| ⚫ **Archived** | Historical information, no longer applicable | For reference only |

## Documentation System Rules

1. **Always Start Here**: Return to this document whenever starting a new task
2. **Follow the Index**: Use the [Documentation Index](/) to navigate the system
3. **Check Status**: Verify document status before relying on its content
4. **Update as You Go**: Maintain documentation alongside code changes
5. **Reference Explicitly**: Use full document paths when referencing (e.g., `/project/document-name/`)
6. **Report Issues**: Flag documentation problems in the [Issues Registry](/project/issues-registry/)

## Complete Documentation Index

For a comprehensive view of all available documentation, see the [Documentation Index](/).

## Weekly Updates

The following documents are updated weekly to reflect current project status:

1. [Current Focus](/project/current-focus/) - Updated every Monday
2. [Implementation Status](/project/implementation-status/) - Updated every Friday
3. [Issues Registry](/project/issues-registry/) - Updated as issues are discovered/resolved

***

> **IMPORTANT**: If this is your first time accessing the MCP documentation system, please take 10 minutes to review the [Documentation Guidelines](/standards/documentation-guidelines/) to understand our documentation standards and processes.