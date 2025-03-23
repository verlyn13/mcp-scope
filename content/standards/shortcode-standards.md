---
title: "Shortcode Usage Standards"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/standards/documentation-guidelines/"
  - "/project/documentation-directory-structure/"
tags: ["standards", "shortcodes", "documentation", "hugo"]
---

# Shortcode Usage Standards

{{< status >}}

[↩️ Back to Standards](/standards/) | [↩️ Back to Documentation Index](/docs/)

## Overview

This document defines the standards for using Hugo shortcodes in MCP documentation. Shortcodes are custom Hugo elements that provide specific functionality and consistent styling throughout the documentation.

{{< callout "info" "Importance of Consistency" >}}
Consistent shortcode usage ensures a uniform look and feel across the entire documentation site, improves readability, and simplifies maintenance.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Standard Shortcodes

The following shortcodes are available in MCP documentation:

### 1. Status Indicator (`status`)

Displays the document status based on front matter.

**Usage:**
```markdown
{{< status >}}
```

**Example Output:**
- For a document with `status: "Active"`: An "Active" status indicator
- For a document with `status: "Draft"`: A "Draft" status indicator

**Placement:** Always place immediately after the main document title (h1).

### 2. Table of Contents (`toc`)

Generates a table of contents based on the document's headings.

**Usage:**
```markdown
{{< toc >}}
```

**Placement:** Place after the document introduction, before the main content sections.

### 3. Callout Boxes (`callout`)

Creates styled information boxes to highlight important content.

**Usage:**
```markdown
{{< callout "type" "title" >}}
Content goes here
{{< /callout >}}
```

**Parameters:**
- `type`: Determines the style/color of the callout (required)
  - Valid types: `info`, `warning`, `success`, `danger`, `note`
- `title`: The title of the callout (required)

**Example:**
```markdown
{{< callout "warning" "Important Note" >}}
This is important information that needs attention.
{{< /callout >}}
```

### 4. Progress Indicator (`progress`)

Displays a visual progress bar.

**Usage:**
```markdown
{{< progress value="75" >}}
```

**Parameters:**
- `value`: Percentage completion (0-100)

**Example Output:** A progress bar showing 75% completion

### 5. Related Documents (`related-docs`)

Lists related documents defined in the front matter.

**Usage:**
```markdown
{{< related-docs >}}
```

**Requirements:** The document must include `related_docs` in its front matter:
```yaml
related_docs:
  - "/path/to/document1/"
  - "/path/to/document2/"
```

**Placement:** Always place at the end of the document, before any appendices or changelog.

## Best Practices

### General Guidelines

1. **Self-Closing vs. Content Shortcodes**
   - Use self-closing syntax for shortcodes without content: `{{< shortcode >}}`
   - Use paired syntax for shortcodes with content: `{{< shortcode >}}Content{{< /shortcode >}}`

2. **Parameter Quoting**
   - Always use double quotes for parameter values: `{{< shortcode "parameter" >}}`
   - Exception: Use single quotes if the parameter value itself contains double quotes

3. **Placement Consistency**
   - Follow the placement guidelines for each shortcode type
   - Maintain consistent spacing before and after shortcodes

### Document Structure

Standard document structure with shortcodes:

```markdown
---
title: "Document Title"
status: "Active"
# Other front matter
---

# Document Title

{{< status >}}

[Navigation links]

## Introduction

Brief introduction to the document.

{{< toc >}}

## Section 1

Content...

{{< callout "info" "Note" >}}
Important information.
{{< /callout >}}

## Section 2

Content with progress indicator:

{{< progress value="50" >}}

## Related Documentation

{{< related-docs >}}
```

## Common Mistakes to Avoid

1. **Unclosed Shortcodes**
   - ❌ `{{< callout "info" "Note" >}} Content without closing tag`
   - ✅ `{{< callout "info" "Note" >}} Content {{< /callout >}}`

2. **Missing Parameters**
   - ❌ `{{< callout >}} Content {{< /callout >}}`
   - ✅ `{{< callout "info" "Note" >}} Content {{< /callout >}}`

3. **Improper Nesting**
   - ❌ Nesting shortcodes is generally not supported
   - ✅ Use separate, sequential shortcodes

## Troubleshooting

### Hugo Build Errors

If you encounter Hugo build errors related to shortcodes:

1. **Missing shortcode template**
   - Error: `failed to extract shortcode: template for shortcode "X" not found`
   - Solution: Ensure the shortcode template exists in `themes/mcp-theme/layouts/shortcodes/`

2. **Unclosed shortcode**
   - Error: `shortcode "X" must be closed or self-closed`
   - Solution: Ensure all paired shortcodes have closing tags

3. **Parameter errors**
   - Error: `failed to extract shortcode: wrong number of arguments`
   - Solution: Check the required parameters for the shortcode

## Related Documentation

{{< related-docs >}}