---
title: "Content Inventory and Migration Prioritization"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Build Engineer", "Documentation Architect"]
related_docs:
  - "/hugo-migration-checklist.md"
  - "/hugo-migration-file-mapping.md"
  - "/documentation-compliance-check.md"
tags: ["migration", "inventory", "prioritization", "content"]
---

# Content Inventory and Migration Prioritization

🟢 **Active**

## Overview

This document provides a complete inventory of all existing documentation to be migrated to the Hugo static site framework, along with a prioritized migration order. This structured approach ensures systematic migration of content while maintaining documentation availability throughout the process.

## Complete Content Inventory

The following tables list all documentation files in the current structure, organized by layer and section.

### Root Documentation Layer

#### Project Documentation

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/docs/README.md` | `/content/docs/_index.md` | 🟢 Active | 1 - Critical |
| `/docs/START_HERE.md` | `/content/getting-started.md` | 🟢 Active | 1 - Critical |
| `/docs/project/project-organization.md` | `/content/project/project-organization.md` | 🟢 Active | 1 - Critical |
| `/docs/project/documentation-directory-structure.md` | `/content/project/documentation-directory-structure.md` | 🟢 Active | 1 - Critical |
| `/docs/project/documentation-migration-plan.md` | `/content/project/documentation-migration-plan.md` | 🟢 Active | 2 - High |
| `/docs/project/issues-registry.md` | `/content/project/issues-registry.md` | 🟢 Active | 2 - High |
| `/docs/project/path-reference-guide.md` | `/content/project/path-reference-guide.md` | 🟢 Active | 2 - High |
| `/docs/project/current-focus.md` | `/content/project/current-focus.md` | 🟢 Active | 1 - Critical |
| `/docs/project/build-engineer-next-steps.md` | `/content/project/build-engineer-next-steps.md` | 🟢 Active | 2 - High |

#### Architecture Documentation

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/docs/architecture/overview.md` | `/content/architecture/overview.md` | 🟢 Active | 1 - Critical |
| `/architecture/camera-integration-agent.md` | `/content/architecture/camera-integration-agent.md` | 🟢 Active | 2 - High |
| `/architecture/fsm-agent-interfaces.md` | `/content/architecture/fsm-agent-interfaces.md` | 🟢 Active | 2 - High |
| `/architecture/health-monitoring-framework.md` | `/content/architecture/health-monitoring-framework.md` | 🟢 Active | 2 - High |
| `/architecture/implementation-roadmap.md` | `/content/architecture/implementation-roadmap.md` | 🟢 Active | 1 - Critical |
| `/architecture/orchestrator-nats-integration.md` | `/content/architecture/orchestrator-nats-integration.md` | 🟢 Active | 2 - High |
| `/architecture/README.md` | `/content/architecture/_index.md` | 🟢 Active | 1 - Critical |

#### Guides Documentation

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/docs/guides/build-engineer-implementation-guide.md` | `/content/guides/build-engineer-implementation-guide.md` | 🟢 Active | 1 - Critical |
| `/docs/guides/build-engineer-onboarding-checklist.md` | `/content/guides/build-engineer-onboarding-checklist.md` | 🟢 Active | 1 - Critical |
| `/docs/guides/build-engineer-quick-start.md` | `/content/guides/build-engineer-quick-start.md` | 🟢 Active | 1 - Critical |
| `/docs/guides/build-engineer-tech-specs.md` | `/content/guides/build-engineer-tech-specs.md` | 🟢 Active | 2 - High |
| `/docs/guides/containerized-dev-environment.md` | `/content/guides/containerized-dev-environment.md` | 🟢 Active | 1 - Critical |
| `/docs/guides/health-monitoring-guide.md` | `/content/guides/health-monitoring-guide.md` | 🟢 Active | 2 - High |
| `/docs/guides/testing-guide.md` | `/content/guides/testing-guide.md` | 🟢 Active | 2 - High |

#### Standards Documentation

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/docs/standards/documentation-guidelines.md` | `/content/standards/documentation-guidelines.md` | 🟢 Active | 1 - Critical |

#### Templates

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/docs/templates/api-documentation-template.md` | `/content/templates/api-documentation-template.md` | 🟢 Active | 3 - Medium |
| `/docs/templates/architecture-component-template.md` | `/content/templates/architecture-component-template.md` | 🟢 Active | 3 - Medium |
| `/docs/templates/implementation-guide-template.md` | `/content/templates/implementation-guide-template.md` | 🟢 Active | 3 - Medium |

### MCP Documentation Layer

#### MCP General Documentation

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/mcp-project/README.md` | `/content/mcp/_index.md` | 🟢 Active | 1 - Critical |
| `/mcp-project/docs/README.md` | `/content/mcp/docs/_index.md` | 🟢 Active | 1 - Critical |
| `/mcp-project/docs/containerized-development-guide.md` | `/content/mcp/docs/containerized-development-guide.md` | 🟢 Active | 2 - High |
| `/mcp-project/docs/CONTRIBUTING.md` | `/content/mcp/docs/contributing.md` | 🟢 Active | 2 - High |
| `/mcp-project/docs/environment-setup.md` | `/content/mcp/docs/environment-setup.md` | 🟢 Active | 1 - Critical |
| `/mcp-project/docs/getting-started.md` | `/content/mcp/docs/getting-started.md` | 🟢 Active | 1 - Critical |
| `/mcp-project/docs/local-development-guide.md` | `/content/mcp/docs/local-development-guide.md` | 🟢 Active | 2 - High |

#### MCP Architecture

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/mcp-project/docs/architecture/overview.md` | `/content/mcp/architecture/overview.md` | 🟢 Active | 1 - Critical |

#### MCP Implementation

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/mcp-project/docs/implementation/containerized-development-guide.md` | `/content/mcp/implementation/containerized-development-guide.md` | 🟢 Active | 2 - High |
| `/mcp-project/docs/implementation/local-development-guide.md` | `/content/mcp/implementation/local-development-guide.md` | 🟢 Active | 2 - High |
| `/mcp-project/docs/implementation/project-setup.md` | `/content/mcp/implementation/project-setup.md` | 🟢 Active | 1 - Critical |

#### MCP Project

| Current Path | Hugo Path | Status | Priority |
|--------------|-----------|--------|----------|
| `/mcp-project/docs/project/first-steps.md` | `/content/mcp/project/first-steps.md` | 🟢 Active | 1 - Critical |

## Migration Prioritization

Based on the inventory, the migration will proceed in the following prioritized order:

### Phase 1: Core Navigation and Entry Points (Priority 1 - Critical)

Migrate the essential navigation documents and entry points:

1. Homepage and documentation indices
   - `/docs/README.md` → `/content/docs/_index.md`
   - `/docs/START_HERE.md` → `/content/getting-started.md`
   - `/mcp-project/README.md` → `/content/mcp/_index.md`
   - `/mcp-project/docs/README.md` → `/content/mcp/docs/_index.md`
   - `/architecture/README.md` → `/content/architecture/_index.md`

2. Section indices for all major sections
   - Create all required `_index.md` files for each section

3. Core project organization and structure documents
   - `/docs/project/project-organization.md` → `/content/project/project-organization.md`
   - `/docs/project/documentation-directory-structure.md` → `/content/project/documentation-directory-structure.md`
   - `/docs/project/current-focus.md` → `/content/project/current-focus.md`

4. Documentation standards
   - `/docs/standards/documentation-guidelines.md` → `/content/standards/documentation-guidelines.md`

### Phase 2: Essential Technical Documentation (Priority 1 - Critical)

Migrate the essential technical documentation:

1. Architecture overview documents
   - `/docs/architecture/overview.md` → `/content/architecture/overview.md`
   - `/architecture/implementation-roadmap.md` → `/content/architecture/implementation-roadmap.md`
   - `/mcp-project/docs/architecture/overview.md` → `/content/mcp/architecture/overview.md`

2. Build engineer guides
   - `/docs/guides/build-engineer-implementation-guide.md` → `/content/guides/build-engineer-implementation-guide.md`
   - `/docs/guides/build-engineer-onboarding-checklist.md` → `/content/guides/build-engineer-onboarding-checklist.md`
   - `/docs/guides/build-engineer-quick-start.md` → `/content/guides/build-engineer-quick-start.md`

3. Environment setup guides
   - `/docs/guides/containerized-dev-environment.md` → `/content/guides/containerized-dev-environment.md`
   - `/mcp-project/docs/environment-setup.md` → `/content/mcp/docs/environment-setup.md`
   - `/mcp-project/docs/implementation/project-setup.md` → `/content/mcp/implementation/project-setup.md`
   - `/mcp-project/docs/project/first-steps.md` → `/content/mcp/project/first-steps.md`

### Phase 3: Supporting Documentation (Priority 2 - High)

Migrate the supporting technical documentation:

1. Project management documents
   - `/docs/project/documentation-migration-plan.md` → `/content/project/documentation-migration-plan.md`
   - `/docs/project/issues-registry.md` → `/content/project/issues-registry.md`
   - `/docs/project/path-reference-guide.md` → `/content/project/path-reference-guide.md`
   - `/docs/project/build-engineer-next-steps.md` → `/content/project/build-engineer-next-steps.md`

2. Architecture component documents
   - `/architecture/camera-integration-agent.md` → `/content/architecture/camera-integration-agent.md`
   - `/architecture/fsm-agent-interfaces.md` → `/content/architecture/fsm-agent-interfaces.md`
   - `/architecture/health-monitoring-framework.md` → `/content/architecture/health-monitoring-framework.md`
   - `/architecture/orchestrator-nats-integration.md` → `/content/architecture/orchestrator-nats-integration.md`

3. Additional guides
   - `/docs/guides/build-engineer-tech-specs.md` → `/content/guides/build-engineer-tech-specs.md`
   - `/docs/guides/health-monitoring-guide.md` → `/content/guides/health-monitoring-guide.md`
   - `/docs/guides/testing-guide.md` → `/content/guides/testing-guide.md`
   - `/mcp-project/docs/containerized-development-guide.md` → `/content/mcp/docs/containerized-development-guide.md`
   - `/mcp-project/docs/CONTRIBUTING.md` → `/content/mcp/docs/contributing.md`
   - `/mcp-project/docs/local-development-guide.md` → `/content/mcp/docs/local-development-guide.md`
   - `/mcp-project/docs/implementation/containerized-development-guide.md` → `/content/mcp/implementation/containerized-development-guide.md`
   - `/mcp-project/docs/implementation/local-development-guide.md` → `/content/mcp/implementation/local-development-guide.md`

### Phase 4: Templates and References (Priority 3 - Medium)

Migrate the template documents:

1. Templates
   - `/docs/templates/api-documentation-template.md` → `/content/templates/api-documentation-template.md`
   - `/docs/templates/architecture-component-template.md` → `/content/templates/architecture-component-template.md`
   - `/docs/templates/implementation-guide-template.md` → `/content/templates/implementation-guide-template.md`

## Migration Dependency Graph

Some documents have dependencies on others that should be considered during migration:

```
START_HERE.md
 └── README.md
     ├── project-organization.md
     │    └── documentation-directory-structure.md
     ├── documentation-guidelines.md
     └── architecture/overview.md
         └── implementation-roadmap.md
```

Ensure dependent documents are migrated together or in the correct sequence.

## Migration Progress Tracking

| Phase | Total Documents | Migrated | Progress |
|-------|-----------------|----------|----------|
| Phase 1 | 13 | 5 | 38% |
| Phase 2 | 12 | 0 | 0% |
| Phase 3 | 17 | 0 | 0% |
| Phase 4 | 3 | 0 | 0% |
| **Total** | **45** | **5** | **11%** |

## Conclusion

This content inventory and prioritization plan provides a structured approach to migrate all documentation to the Hugo static site framework. By following this prioritized order, we ensure that the most critical documentation is migrated first, maintaining documentation availability throughout the process.

## Changelog

- 1.0.0 (2025-03-23): Initial version