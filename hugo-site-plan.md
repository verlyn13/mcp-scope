# Hugo Static Site Migration Plan for ScopeCam MCP Documentation

## Executive Summary

This document outlines the plan for migrating the ScopeCam MCP documentation to a Hugo-based static site for deployment on GitHub Pages. The plan preserves the current dual-layer documentation structure while leveraging Hugo's capabilities for organization, navigation, and presentation.

## Current State Analysis

The ScopeCam MCP documentation currently follows a well-structured dual-layer approach:

1. **Root Documentation Layer** (`/docs/`)
   - Project-wide information and ScopeCam integration
   - Audience: All stakeholders, system integrators, project managers
   - Content: Project vision, integration guides, organizational structure

2. **MCP Documentation Layer** (`/mcp-project/docs/`)
   - Detailed MCP implementation guides and technical information
   - Audience: Developers implementing or extending the MCP
   - Content: Architecture details, implementation guides, API specifications

The documentation uses a consistent status system and YAML front matter that is already Hugo-compatible.

## Hugo Site Structure

### Directory Organization

```
hugo-site/               # Root of Hugo project
├── archetypes/          # Content templates
├── assets/              # Raw assets (SCSS, JS, etc.)
├── config.toml          # Hugo configuration
├── content/             # Site content (markdown files)
│   ├── _index.md        # Homepage (converted from README.md)
│   ├── project/         # Project-level information
│   │   └── _index.md    # Section index
│   ├── guides/          # Implementation and technical guides
│   │   └── _index.md    # Section index
│   ├── architecture/    # Architecture documentation
│   │   └── _index.md    # Section index
│   ├── standards/       # Documentation standards
│   │   └── _index.md    # Section index
│   ├── templates/       # Document templates
│   │   └── _index.md    # Section index
│   ├── tools/           # Documentation tools
│   │   └── _index.md    # Section index
│   └── mcp/             # MCP implementation layer
│       ├── _index.md    # MCP section index
│       ├── project/     # MCP project information
│       ├── architecture/# MCP architecture details
│       ├── implementation/# Implementation guides
│       └── standards/   # MCP documentation standards
├── data/                # Site data files
│   ├── status.yaml      # Status definitions
│   └── progress.yaml    # Project progress data
├── layouts/             # Theme overrides and custom layouts
├── static/              # Static assets (images, etc.)
└── themes/              # Hugo themes
    └── mcp-theme/       # Custom theme for MCP
```

### Content Migration Strategy

1. **README.md Files**: Convert to `_index.md` files with appropriate front matter
2. **Section Organization**: Map current directories to Hugo sections 
3. **YAML Front Matter**: Retain existing front matter and extend with Hugo-specific parameters
4. **Status System**: Implement with Hugo taxonomies and custom shortcodes

### Front Matter Standard

Extend current front matter to include Hugo-specific fields:

```yaml
---
title: "Document Title"
status: "Active"  # Active, Draft, Review, Outdated, or Archived
version: "1.0"    # Semantic versioning
date_created: "YYYY-MM-DD"
last_updated: "YYYY-MM-DD"
contributors: ["Name"]
related_docs:
  - "/docs/path/to/related/document.md"
tags: ["tag1", "tag2"]
weight: 10           # Hugo-specific for ordering
draft: false         # Hugo-specific for draft status
layout: "standard"   # Hugo-specific layout choice
---
```

## Hugo Theme Design

### Key Features

1. **Dual-Layer Navigation**
   - Sidebar menu with collapsible sections
   - "Layer switch" toggle to navigate between Root and MCP documentation layers
   - Breadcrumbs showing the path through the documentation hierarchy

2. **Status Visualization**
   - Color-coded status banners matching current emoji system
   - Filtering by status in section listings
   - Status dashboard showing document counts by status

3. **Tagging System**
   - Tag cloud for common tags
   - Filtered views by tag
   - Layer-specific tag visualization

4. **Progress Tracking**
   - Dashboard-style progress bars matching the current README.md
   - Visual roadmap with status indicators
   - Integration with status system

5. **Search Functionality**
   - Full-text search across all documentation
   - Filters by layer, section, and status
   - Result highlighting

### Custom Shortcodes

Create Hugo shortcodes to maintain consistent styling and functionality:

1. `{{< status >}}` - Display document status with appropriate styling
2. `{{< progress value="80" >}}` - Render progress bars
3. `{{< related-docs >}}` - List related documents with proper links
4. `{{< mermaid >}}` - Mermaid diagram rendering
5. `{{< layer-switch >}}` - Toggle between documentation layers

## GitHub Pages Integration

### Repository Structure

The GitHub Pages site will be deployed from the `gh-pages` branch with the following organization:

```
gh-pages/                # Root of gh-pages branch
├── index.html          # Generated home page
├── css/                # Compiled CSS
├── js/                 # JavaScript files
├── images/             # Image assets
├── project/            # Project section
├── guides/             # Guides section
├── architecture/       # Architecture section
├── standards/          # Standards section
├── templates/          # Templates section
├── tools/              # Tools section
└── mcp/                # MCP section
```

### Build and Deployment Workflow

1. **GitHub Actions Workflow**:
   - Trigger: Push to main branch or manual dispatch
   - Steps:
     1. Checkout repository
     2. Set up Hugo environment
     3. Build site with Hugo
     4. Deploy to gh-pages branch

2. **Custom Domain Configuration**:
   - Add CNAME file to static/ directory
   - Configure GitHub Pages settings for custom domain (if desired)

## Implementation Roadmap

### Phase 1: Foundation Setup (Week 1)

1. Create basic Hugo project structure
2. Set up GitHub Actions workflow for CI/CD
3. Implement custom theme foundation
4. Create test content migration to validate structure

### Phase 2: Content Migration (Week 2)

1. Migrate Root Documentation Layer
2. Migrate MCP Documentation Layer 
3. Implement cross-references and navigation
4. Validate content integrity

### Phase 3: Enhanced Functionality (Week 3)

1. Implement status system with taxonomies
2. Develop custom shortcodes
3. Create dashboard and visualization components
4. Add search functionality

### Phase 4: Testing & Refinement (Week 4)

1. User acceptance testing
2. Responsive design refinement
3. Performance optimization
4. Documentation of the Hugo site maintenance

## Maintenance Guidelines

### Adding New Content

1. Create markdown files in appropriate content directories
2. Include required front matter
3. Run local Hugo server to preview changes
4. Commit changes to trigger deployment

### Updating Existing Content

1. Locate content file in the appropriate directory
2. Update content and front matter
3. Update `last_updated` date in the front matter
4. Preview changes locally before committing

### Style & Formatting

1. Follow Markdown best practices
2. Use custom shortcodes for consistent styling
3. Adhere to front matter requirements
4. Optimize images before adding to the repository

## Recommendations for GitHub Pages Deployment

1. **Base URL Configuration**: Set `baseURL` in Hugo config to match GitHub Pages URL
2. **404 Page**: Create a custom 404.html page with links back to documentation index
3. **Redirects**: Implement redirects for compatibility with existing documentation links
4. **Robots.txt**: Configure for appropriate search engine indexing
5. **Sitemap**: Enable Hugo's built-in sitemap generation for better SEO

## Conclusion

This plan provides a comprehensive approach to migrating the ScopeCam MCP documentation to a Hugo-based static site while preserving the current organization and enhancing the user experience. The migration will maintain the dual-layer structure while adding new features for navigation, visualization, and content discovery.

The proposed implementation follows a phased approach that allows for testing and refinement at each stage, ensuring a smooth transition to the new documentation system. The result will be a more maintainable, searchable, and visually appealing documentation site that serves the needs of all stakeholders in the ScopeCam MCP project.