---
title: "Hugo Documentation Organization Plan"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/project/documentation-directory-structure/"
  - "/hugo-site-plan/"
  - "/standards/shortcode-documentation-guidelines/"
tags: ["documentation", "organization", "hugo", "planning"]
---

# Hugo Documentation Organization Plan

{{< status >}}

This document outlines the organizational structure of the ScopeCam MCP documentation system implemented with Hugo and deployed on GitHub Pages.

## Current Organization

The documentation follows a hierarchical structure that clearly separates different types of content while maintaining relationships between related documents. The primary sections are:

1. **Architecture** (`/architecture/`)
   - System architecture documentation
   - Component diagrams and specifications
   - Decision records and rationales

2. **Project** (`/project/`)
   - Project management documentation
   - Planning documents
   - Status reports and roadmaps
   - Directory structures and organizational guides

3. **Guides** (`/guides/`)
   - Implementation guides
   - User guides
   - Build and deployment procedures
   - Environment setup instructions

4. **Standards** (`/standards/`)
   - Coding standards
   - Documentation guidelines
   - Shortcode usage guidelines
   - Best practices

5. **Templates** (`/templates/`)
   - Reusable documentation templates
   - API documentation templates
   - Architecture component templates
   - Implementation guide templates

6. **MCP-Specific Documentation** (`/mcp/`)
   - Core MCP documentation
   - MCP architecture
   - MCP implementation details
   - MCP project specifics

This structure aligns with the two-layer approach:
- Root Documentation Layer: All general ScopeCam documentation
- MCP-Specific Layer: Documentation specific to the MCP core components

## Key Features Implemented

### 1. Metadata and Status System

All documentation includes structured front matter with:

```yaml
---
title: "Document Title"
status: "Active"  # or Draft, Review, Archived
version: "1.0"
date_created: "YYYY-MM-DD"
last_updated: "YYYY-MM-DD"
contributors: ["Name1", "Name2"]
related_docs:
  - "/path/to/related/doc1/"
  - "/path/to/related/doc2/"
tags: ["tag1", "tag2", "tag3"]
---
```

This metadata is used for:
- Displaying document status badges
- Tracking document versions
- Showing last updated dates
- Linking related documents
- Categorizing content via tags

### 2. Shortcode System

Custom shortcodes have been implemented for consistent styling and functionality:

- `{{< status >}}` - Shows document status with appropriate styling
- `{{< progress value="80" >}}` - Renders progress bars
- `{{< related-docs >}}` - Lists related documents with proper links
- `{{< mermaid >}}` - Renders Mermaid.js diagrams
- `{{< layer-switch >}}` - Toggles between documentation layers
- `{{< note >}}` and `{{< warning >}}` - Creates highlighted information boxes

Documentation for shortcode usage is available in `/standards/shortcode-documentation-guidelines/`.

### 3. Navigation System

The navigation system provides:

- Section-based navigation in the sidebar
- Breadcrumb navigation at the top of each page
- Table of contents for each document
- Cross-references between documents
- Tag-based navigation

### 4. Deployment System

The documentation is deployed to GitHub Pages using:

- The `gh-pages` branch for hosting
- Automated build and deployment scripts
- Content validation before deployment
- Shortcode validation

## Integration with Labeling and Status Systems

### Document Status System

Each document has a status that is visually indicated:

1. **Draft** (Yellow) - Initial content, incomplete, not reviewed
2. **Review** (Orange) - Complete content awaiting review
3. **Active** (Green) - Reviewed, approved, and current
4. **Archived** (Gray) - Outdated but kept for reference

The status is defined in the front matter and displayed via the `{{< status >}}` shortcode.

### Tagging System

Documents are categorized with tags in the front matter:

```yaml
tags: ["architecture", "camera", "integration"]
```

Tags provide:
- Cross-sectional navigation
- Related content discovery
- Search filtering

### Progress Tracking

Implementation progress is tracked using:

- Progress indicators in key documents
- Progress bars rendered with the `{{< progress value="80" >}}` shortcode
- Project status documents in the `/project/` section

## Maintenance Guidelines

### 1. Document Creation and Updates

When creating or updating documents:

1. Use the appropriate template from `/templates/`
2. Include complete front matter with status, version, dates, etc.
3. Place the document in the appropriate section
4. Add the `{{< status >}}` shortcode after the main heading
5. Add the `{{< related-docs >}}` shortcode at the end
6. Use other shortcodes as needed for visual elements

### 2. Shortcode Usage

When using shortcodes:

1. Follow the guidelines in `/standards/shortcode-documentation-guidelines/`
2. Properly escape shortcode examples in documentation
3. Test rendering locally before deploying

### 3. Deployment Process

For deployment:

1. Ensure all changes are committed to the main branch
2. Run validation checks using `./doc-doctor.sh`
3. Deploy to GitHub Pages using `./deploy-docs.sh`
4. Verify the deployed site

## Future Enhancements

### 1. Search Functionality

Implement full-text search with:
- Section filtering
- Tag filtering
- Status filtering

### 2. User Authentication

Consider adding authentication for:
- Internal-only documentation
- Role-based access to certain sections

### 3. Versioning System

Implement version control for documentation:
- Version-specific URLs
- Version selector
- Change logs

### 4. Interactive Elements

Add more interactive elements:
- Interactive diagrams
- Code playgrounds
- API explorers

### 5. Automated Documentation

Set up automated documentation generation for:
- API documentation from code comments
- Component diagrams from architecture definitions
- Test coverage reports

## Conclusion

The Hugo-based documentation system provides a robust, maintainable, and extensible platform for ScopeCam MCP documentation. By following the organizational structure and guidelines outlined in this document, the team can ensure that documentation remains consistent, up-to-date, and accessible.

The separation between general documentation and MCP-specific content, combined with the metadata and status systems, enables efficient navigation and maintenance of the documentation. The deployment to GitHub Pages ensures that the latest documentation is always available to all stakeholders.

## Related Documentation

{{< related-docs >}}