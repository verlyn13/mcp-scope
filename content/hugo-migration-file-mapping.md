# ScopeCam MCP Documentation to Hugo Migration File Mapping

This document provides a comprehensive mapping of the current documentation files to their locations in the Hugo site structure. This will serve as a guide during the migration process.

## Current vs. Hugo Path Mapping

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/README.md` | `/content/_index.md` | Site homepage |
| `/docs/README.md` | `/content/docs/_index.md` | Documentation index |
| `/docs/START_HERE.md` | `/content/getting-started.md` | Entry point |

### Root Documentation Layer

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/docs/project/current-focus.md` | `/content/project/current-focus.md` | |
| `/docs/project/documentation-directory-structure.md` | `/content/project/documentation-directory-structure.md` | |
| `/docs/project/documentation-migration-plan.md` | `/content/project/documentation-migration-plan.md` | |
| `/docs/project/issues-registry.md` | `/content/project/issues-registry.md` | |
| `/docs/project/path-reference-guide.md` | `/content/project/path-reference-guide.md` | |
| `/docs/project/project-organization.md` | `/content/project/project-organization.md` | |
| `/docs/project/build-engineer-next-steps.md` | `/content/project/build-engineer-next-steps.md` | |

### Architecture Documentation

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/docs/architecture/overview.md` | `/content/architecture/overview.md` | |
| `/architecture/camera-integration-agent.md` | `/content/architecture/camera-integration-agent.md` | Moving from root to architecture section |
| `/architecture/fsm-agent-interfaces.md` | `/content/architecture/fsm-agent-interfaces.md` | Moving from root to architecture section |
| `/architecture/health-monitoring-framework.md` | `/content/architecture/health-monitoring-framework.md` | Moving from root to architecture section |
| `/architecture/implementation-roadmap.md` | `/content/architecture/implementation-roadmap.md` | Moving from root to architecture section |
| `/architecture/orchestrator-nats-integration.md` | `/content/architecture/orchestrator-nats-integration.md` | Moving from root to architecture section |
| `/architecture/README.md` | `/content/architecture/_index.md` | Converted to index |

### Guides Documentation

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/docs/guides/build-engineer-implementation-guide.md` | `/content/guides/build-engineer-implementation-guide.md` | |
| `/docs/guides/build-engineer-onboarding-checklist.md` | `/content/guides/build-engineer-onboarding-checklist.md` | |
| `/docs/guides/build-engineer-quick-start.md` | `/content/guides/build-engineer-quick-start.md` | |
| `/docs/guides/build-engineer-tech-specs.md` | `/content/guides/build-engineer-tech-specs.md` | |
| `/docs/guides/containerized-dev-environment.md` | `/content/guides/containerized-dev-environment.md` | |
| `/docs/guides/health-monitoring-guide.md` | `/content/guides/health-monitoring-guide.md` | |
| `/docs/guides/testing-guide.md` | `/content/guides/testing-guide.md` | |

### Standards Documentation

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/docs/standards/documentation-guidelines.md` | `/content/standards/documentation-guidelines.md` | |

### Templates

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/docs/templates/api-documentation-template.md` | `/content/templates/api-documentation-template.md` | |
| `/docs/templates/architecture-component-template.md` | `/content/templates/architecture-component-template.md` | |
| `/docs/templates/implementation-guide-template.md` | `/content/templates/implementation-guide-template.md` | |

### Tools

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/docs/tools/doc-manager.py` | `/static/tools/doc-manager.py` | Moved to static as it's not content |

### MCP Implementation Layer

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/mcp-project/README.md` | `/content/mcp/_index.md` | MCP section index |
| `/mcp-project/docs/README.md` | `/content/mcp/docs/_index.md` | MCP docs index |
| `/mcp-project/docs/containerized-development-guide.md` | `/content/mcp/docs/containerized-development-guide.md` | |
| `/mcp-project/docs/CONTRIBUTING.md` | `/content/mcp/docs/contributing.md` | Renamed to lowercase |
| `/mcp-project/docs/environment-setup.md` | `/content/mcp/docs/environment-setup.md` | |
| `/mcp-project/docs/getting-started.md` | `/content/mcp/docs/getting-started.md` | |
| `/mcp-project/docs/local-development-guide.md` | `/content/mcp/docs/local-development-guide.md` | |

#### MCP Architecture

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/mcp-project/docs/architecture/overview.md` | `/content/mcp/architecture/overview.md` | |

#### MCP Implementation

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/mcp-project/docs/implementation/containerized-development-guide.md` | `/content/mcp/implementation/containerized-development-guide.md` | |
| `/mcp-project/docs/implementation/local-development-guide.md` | `/content/mcp/implementation/local-development-guide.md` | |
| `/mcp-project/docs/implementation/project-setup.md` | `/content/mcp/implementation/project-setup.md` | |

#### MCP Project

| Current Path | Hugo Path | Notes |
|-------------|------------|-------|
| `/mcp-project/docs/project/first-steps.md` | `/content/mcp/project/first-steps.md` | |

## File Migration Process

For each file, the migration process will involve:

1. **Copy Content**: Copy the file content from the current location
2. **Convert Front Matter**: Ensure front matter is Hugo-compatible:
   - Add `draft: false` if not a draft
   - Add `weight` parameter for ordering within sections
   - Add `menu` parameter if it should appear in navigation
3. **Update Internal Links**: Convert all internal links to Hugo-style paths
4. **Fix Image Paths**: Update image references to point to `/static/images/`
5. **Convert README.md Files**: Transform into `_index.md` files for section indices
6. **Update Cross-References**: Ensure related_docs paths are updated to match new structure

## Special Considerations

### Converting README.md to _index.md

For README.md files that serve as section indices, they will be converted to _index.md with appropriate front matter. For example:

```yaml
---
title: "Section Title"
description: "Section description"
weight: 10
---

# Section Title

Content of the README.md file...
```

### Handling Cross-References

All cross-references (`related_docs` in front matter and inline links) will need to be updated to reflect the new Hugo structure. This will be done by:

1. Creating a mapping table (as above)
2. Implementing a script to automatically update links in markdown content
3. Manually verifying critical links

### Status System Implementation

The current status emoji system will be implemented in Hugo using:

1. A custom taxonomy called `status`
2. Front matter parameter: `status: "Active"`
3. A custom shortcode to display the appropriate status emoji and styling:

```go
{{ $status := .Get 0 | default (.Page.Params.status) }}
{{ if eq $status "Active" }}
  <span class="status status-active">🟢 Active</span>
{{ else if eq $status "Draft" }}
  <span class="status status-draft">🟡 Draft</span>
{{ else if eq $status "Review" }}
  <span class="status status-review">🟠 Review</span>
{{ else if eq $status "Outdated" }}
  <span class="status status-outdated">🔴 Outdated</span>
{{ else if eq $status "Archived" }}
  <span class="status status-archived">⚫ Archived</span>
{{ end }}
```

### Tag System Implementation

The current tag system will be implemented using Hugo's built-in taxonomy support:

```toml
[taxonomies]
  tag = "tags"
  status = "status"
  contributor = "contributors"
```

This will automatically generate tag pages and allow for filtering content by tag.