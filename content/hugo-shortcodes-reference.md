---
title: "Hugo Shortcodes Reference for ScopeCam Documentation"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/documentation-compliance-check.md"
  - "/hugo-migration-checklist.md"
  - "/hugo-theme-design.md"
tags: ["hugo", "shortcodes", "reference", "documentation"]
---

# Hugo Shortcodes Reference for ScopeCam Documentation

🟢 **Active**

## Overview

This document provides a reference guide for the custom Hugo shortcodes available in the ScopeCam MCP documentation site. Shortcodes allow for consistent application of special formatting and components across the documentation.

## What Are Shortcodes?

Shortcodes are special Hugo constructs that provide a simple way to extend Markdown's capabilities. They allow for inserting complex content or formatting without resorting to HTML, ensuring consistency across the documentation.

## Available Shortcodes

The ScopeCam MCP Hugo implementation includes the following custom shortcodes:

1. [`status`](#status-shortcode) - Document status indicator
2. [`progress`](#progress-shortcode) - Progress bar for tracking completion
3. [`related-docs`](#related-docs-shortcode) - Displays related documents

## Status Shortcode

The `status` shortcode displays a document's status with appropriate styling and emoji.

### Syntax

```
{{< status >}}
```

or

```
{{< status "Active" >}}
```

### Parameters

- Status value (optional): If provided, displays the specified status. If not provided, uses the document's status from front matter.

### Examples

Display the document's status from front matter:

```
{{< status >}}
```

Display a specific status:

```
{{< status "Draft" >}}
```

### HTML Output

```html
<span class="status status-active">🟢 Active</span>
```

### Visual Example

🟢 **Active** - Current, reviewed and approved  
🟡 **Draft** - Work in progress, subject to change  
🟠 **Review** - Complete but pending final approval  
🔴 **Outdated** - Contains older information that needs updating  
⚫ **Archived** - Historical information, no longer applicable  

## Progress Shortcode

The `progress` shortcode displays a progress bar for tracking completion percentages.

### Syntax

```
{{< progress value="75" >}}
```

### Parameters

- `value`: The percentage value (0-100) of completion to display

### Examples

Display a 75% progress bar:

```
{{< progress value="75" >}}
```

Display a complete progress bar:

```
{{< progress value="100" >}}
```

### HTML Output

```html
<div class="progress">
  <div class="progress-bar" role="progressbar" style="width: 75%;" 
       aria-valuenow="75" aria-valuemin="0" aria-valuemax="100">75%</div>
</div>
```

### Visual Example

A progress bar at 75% would look like:

[================>    ] 75%

## Related-Docs Shortcode

The `related-docs` shortcode displays a list of related documents specified in the front matter.

### Syntax

```
{{< related-docs >}}
```

### Parameters

This shortcode does not take parameters. It automatically uses the `related_docs` list from the document's front matter.

### Examples

In front matter:

```yaml
related_docs:
  - "/project/document-a/"
  - "/guides/document-b/"
  - "/architecture/document-c/"
```

In content:

```
{{< related-docs >}}
```

### HTML Output

```html
<div class="related-docs">
  <h3>Related Documents</h3>
  <ul>
    <li><a href="/project/document-a/">Document A</a></li>
    <li><a href="/guides/document-b/">Document B</a></li>
    <li><a href="/architecture/document-c/">Document C</a></li>
  </ul>
</div>
```

### Visual Example

**Related Documents**
- [Document A](/project/document-a/)
- [Document B](/guides/document-b/)
- [Document C](/architecture/document-c/)

## Best Practices for Using Shortcodes

When using shortcodes in the ScopeCam MCP documentation, follow these best practices:

### Status Shortcode

- Place the status shortcode immediately after the main heading of a document
- Only use the parameter version when you need to display a status different from the document's own status
- Don't use more than one status indicator per document

```markdown
# Document Title

{{< status >}}

## Introduction
```

### Progress Shortcode

- Use progress shortcodes in roadmaps, dashboards, and status reports
- Include a descriptive label before or after the progress bar for context
- Use consistent progress values for related items
- Round progress values to whole numbers

```markdown
| Component | Progress |
|-----------|----------|
| Core System | {{< progress value="100" >}} |
| Camera Integration | {{< progress value="80" >}} |
```

### Related-Docs Shortcode

- Place the related-docs shortcode at the end of a document
- Keep the related_docs list in front matter up to date
- Limit related documents to those most relevant (5-7 max)
- Ensure all paths in related_docs are valid

```markdown
## Conclusion

...conclusion content...

{{< related-docs >}}
```

## Creating New Shortcodes

If additional shortcodes are needed, they should:

1. Be implemented in `themes/mcp-theme/layouts/shortcodes/`
2. Follow the same naming convention (lowercase, hyphenated)
3. Include appropriate validation and error handling
4. Be documented in this reference guide

## Troubleshooting

### Common Issues

- **Shortcode doesn't render**: Ensure the shortcode name is correct and syntax is valid
- **Status not showing**: Check if the status value is one of the supported values
- **Progress bar errors**: Ensure the value parameter is provided and is a number
- **Related docs not appearing**: Verify the related_docs list in front matter is formatted correctly

## Changelog

- 1.0.0 (2025-03-23): Initial version