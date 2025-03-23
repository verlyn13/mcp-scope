---
title: "Documentation Guidelines"
status: "Active"
version: "1.1"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/"
  - "/project/path-reference-guide/"
  - "/project/documentation-migration-plan/"
tags: ["standards", "documentation", "guidelines", "hugo"]
---

# Documentation Guidelines

{{< status >}}

[↩️ Back to Standards](/standards/) | [↩️ Back to Documentation Index](/docs/)

## Overview

This document establishes the standards and best practices for creating and maintaining documentation for the Multi-Agent Control Platform (MCP). Following these guidelines ensures that our documentation remains consistent, accessible, and valuable throughout the project lifecycle.

{{< callout "info" "Hugo Migration" >}}
These guidelines have been updated to reflect our migration to Hugo. All new and updated documentation should follow these Hugo-specific standards.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Document Structure

### Standard Sections

All technical documents should include these sections where applicable:

1. **Overview**: Brief introduction to the document's purpose and content
2. **Prerequisites**: Any information or setup required before using the document
3. **Main Content**: The primary technical information (architecture, implementation, etc.)
4. **Examples**: Practical examples demonstrating key concepts
5. **Troubleshooting**: Common issues and their solutions
6. **Implementation Progress**: Status of implementation with progress indicators
7. **Related Documents**: Links to related information
8. **Glossary**: Definitions of domain-specific terms (if needed)

### Technical Specification Structure

Architecture and component specification documents should follow this structure:

1. **Component Overview**: Purpose and role in the system
2. **Core Interfaces/Classes**: Key code structures with explanations
3. **Behavior**: How the component functions, including state transitions
4. **Communication**: How the component interacts with other components
5. **Data Models**: Essential data structures
6. **Implementation Guidelines**: Best practices for implementation
7. **Implementation Progress**: Current status with progress indicators
8. **Known Limitations**: Documented constraints or issues

## Metadata and Front Matter

Every document must begin with YAML front matter containing:

```yaml
---
title: "Document Title"
status: "Active"  # Active, Draft, Review, Outdated, or Archived
version: "1.0"    # Semantic versioning
date_created: "YYYY-MM-DD"
last_updated: "YYYY-MM-DD"
contributors: ["Name"]
related_docs:
  - "/path/to/related/document/"
tags: ["tag1", "tag2"]
---
```

## Documentation Status Lifecycle

Documents follow this lifecycle:

1. **Draft** 🟡: Initial creation, content may change substantially
2. **Review** 🟠: Complete but pending final approval
3. **Active** 🟢: Current, approved documentation
4. **Outdated** 🔴: No longer current but not yet updated
5. **Archived** ⚫: Historical information, no longer applicable

Status should be updated in the front matter whenever the document status changes.

## Status Indicators

Include status indicators at the beginning of each document using the status shortcode:

```
{{</* status */>}}
```

This will automatically render the appropriate status indicator based on the front matter status field.

## Hugo Shortcodes

The documentation site includes several custom shortcodes to enhance readability:

### Table of Contents

Add a table of contents to longer documents:

```
{{</* toc */>}}
```

### Progress Bars

Show implementation progress:

```
{{</* progress value="75" */>}}
```

### Callouts

Create highlighted information blocks:

```
{{</* callout "info" "Title Here" */>}}
This is important information that needs to stand out.
{{</* /callout */>}}
```

Available callout types:
- `info`: General information
- `tip`: Helpful suggestions
- `warning`: Important cautions
- `danger`: Critical warnings
- `note`: Additional notes

### Related Documents

Add a related documents section that automatically pulls from front matter:

```
{{</* related-docs */>}}
```

## Cross-Referencing

### Internal Links

Use Hugo-style links to reference other documents:

```markdown
[Document Title](/section/page-name/)
```

Note that Hugo URLs:
- Do not include file extensions (.md or .html)
- Typically end with a trailing slash
- Use the section/page structure

### External Links

For external references, include the full URL and describe the target:

```markdown
[External Service Documentation](https://example.com/docs) - Official documentation for Example Service
```

### Issue References

When referencing known issues, include a link to the Issues Registry:

```markdown
This component has a [known performance issue](/project/issues-registry/#mcp-sched-001-task-priority-inversion) with large datasets.
```

## Code Samples

### Formatting

Format code samples with appropriate language identifiers:

````markdown
```kotlin
fun example() {
    println("This is a Kotlin code sample")
}
```
````

### Inline Code

Use backticks for inline code references: `McpAgent`.

## Diagrams

### Guidelines

- Use ASCII diagrams for simple flowcharts in Markdown
- Create complex diagrams using Mermaid or PlantUML
- Store diagram source in the document for future editing
- Keep diagrams focused on one concept per visual

### Example Mermaid Diagram

```mermaid
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
    C --> E[End]
    D --> E
```

## Images

- Store images in `/static/images/`
- Use descriptive filenames: `component-state-diagram.png`
- Include alt text for accessibility: `![Component State Diagram](/images/component-state-diagram.png)`
- Keep images below 1MB in size
- Provide image source files when available

## Tables

Use tables for structured information:

| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
| Data 3   | Data 4   |

## Document Naming Conventions

- Use lowercase kebab-case for filenames: `fsm-agent-interfaces.md`
- Use the same convention for directories: `/content/architecture/`
- Be descriptive but concise
- Group related documents with common prefixes
- Avoid special characters except hyphens

## Content Organization

The Hugo site organizes content into sections:

| Section | Purpose | Path |
|---------|---------|------|
| `/docs/` | Documentation index and entry points | `/content/docs/` |
| `/architecture/` | Architecture documentation | `/content/architecture/` |
| `/guides/` | Implementation and development guides | `/content/guides/` |
| `/project/` | Project management documents | `/content/project/` |
| `/standards/` | Standards and guidelines | `/content/standards/` |
| `/mcp/` | MCP-specific documentation | `/content/mcp/` |

## Version Control

### Version Numbers

Use semantic versioning for documents:

- **Major version** (1.0.0): Substantial content changes
- **Minor version** (0.1.0): Additions/improvements without major structural changes
- **Patch version** (0.0.1): Small corrections or clarifications

### Changelogs

For significant documents, maintain a changelog at the end:

```markdown
## Changelog

- 1.1.0 (2025-03-25): Added section on error handling
- 1.0.0 (2025-03-22): Initial release
```

## Known Issues and Pitfalls

Document known issues directly in relevant technical documents and in the [Issues Registry](/project/issues-registry/).

For each issue include:

1. Issue ID and descriptive title
2. Impact on functionality or development
3. Workarounds or mitigation strategies
4. Status (open, under investigation, resolved)
5. Related components or documents

## Documentation Review Process

1. Author creates document in Draft status
2. Internal review by technical team
3. Updates based on feedback
4. Final review by Documentation Architect
5. Status changed to Active when approved
6. Periodic reviews to maintain freshness

## Implementation Progress

| Component | Status | Completion |
|-----------|--------|------------|
| Documentation Standards | 🟢 Active | {{< progress value="100" >}} |
| Hugo Migration Guidelines | 🟢 Active | {{< progress value="95" >}} |
| Custom Shortcodes | 🟢 Active | {{< progress value="90" >}} |
| Path Reference Standards | 🟢 Active | {{< progress value="100" >}} |
| Template Migration | 🟡 Draft | {{< progress value="75" >}} |
| Accessibility Guidelines | 🟢 Active | {{< progress value="85" >}} |

## Hugo-Specific Guidelines

{{< callout "tip" "Hugo Best Practices" >}}
These guidelines specifically address the Hugo implementation of our documentation site. Following these practices ensures a consistent user experience.
{{< /callout >}}

### Content Structure

- Place all content files in the appropriate section directory under `/content/`
- Create section index files as `_index.md` in each section directory
- Use front matter to provide metadata for all content

### URL Structure

- Hugo generates clean URLs without file extensions
- URLs typically end with a trailing slash
- Use the path format: `/section/page-name/`
- Avoid using file extensions in internal links

### Shortcode Usage

- Use the provided shortcodes for consistency
- Don't mix HTML and Markdown unnecessarily
- Test shortcodes in the development environment before publishing

## Documentation Templates

Templates for common document types are located in `/content/templates/`:

- [Architecture Component Template](/templates/architecture-component-template/)
- [Implementation Guide Template](/templates/implementation-guide-template/)
- [API Documentation Template](/templates/api-documentation-template/)

## Accessibility Guidelines

- Use proper heading hierarchy (H1, H2, etc.)
- Provide alt text for all images
- Use sufficient color contrast
- Avoid conveying information through color alone
- Use descriptive link text instead of "click here"

## Contribution Flow

1. Identify documentation need
2. Check if similar documentation exists
3. Create or update document following these guidelines
4. Add appropriate front matter and metadata
5. Submit for review
6. Address feedback
7. Update status when approved

## Related Documentation

{{< related-docs >}}

## Changelog

- 1.1.0 (2025-03-23): Updated for Hugo migration with shortcodes and new path structure
- 1.0.0 (2025-03-22): Initial release