---
title: "Shortcode Documentation Guidelines"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/standards/documentation-guidelines/"
  - "/hugo-shortcodes-reference/"
tags: ["shortcodes", "documentation", "guidelines", "standards", "hugo"]
---

# Shortcode Documentation Guidelines

{{< status >}}

This document provides guidelines for documenting Hugo shortcodes in the MCP documentation system. Following these standards ensures that documentation renders correctly and that shortcode examples are properly displayed without being interpreted by Hugo.

## Overview

Shortcodes are a powerful feature in Hugo that allow for reusable content snippets. When writing documentation that includes shortcode examples, special care must be taken to prevent Hugo from interpreting these examples as actual shortcodes to process.

## Shortcode Escaping

### Basic Principle

To display a shortcode example in documentation without having Hugo process it, you must use the special escape syntax:

```markdown
{{</* shortcode */>}}
```

This syntax tells Hugo to display the shortcode verbatim, rather than attempting to execute it.

### Examples

#### Incorrect (Will Be Processed by Hugo)

```markdown
Use {{< status >}} to display the document's status.
```

#### Correct (Will Be Displayed as Example)

```markdown
Use {{</* status */>}} to display the document's status.
```

### Paired Shortcodes

For shortcodes that have opening and closing tags, both tags must be escaped:

#### Incorrect

```markdown
{{</* note */>}}
This is a note.
{{< /note >}}
```

#### Correct

```markdown
{{</* note */>}}
This is a note.
{{</* /note */>}}
```

## Common Shortcodes and Their Parameters

### Status Shortcode

The status shortcode displays the current document's status based on front matter.

**Usage:**
```markdown
{{</* status */>}}
```

With explicit status:
```markdown
{{</* status "Active" */>}}
```

### Progress Shortcode

The progress shortcode creates a visual progress bar.

**Usage:**
```markdown
{{</* progress value="80" */>}}
```

### Related Documents Shortcode

The related-docs shortcode lists related documents defined in the front matter.

**Usage:**
```markdown
{{</* related-docs */>}}
```

### Mermaid Diagram Shortcode

The mermaid shortcode renders diagrams using Mermaid.js.

**Usage:**
```markdown
{{</* mermaid */>}}
graph TD
    A[Start] --> B[Process]
    B --> C[End]
{{</* /mermaid */>}}
```

### Layer Switch Shortcode

The layer-switch shortcode creates a toggle between Root and MCP documentation layers.

**Usage:**
```markdown
{{</* layer-switch */>}}
```

### Note and Warning Shortcodes

These shortcodes create highlighted note and warning boxes.

**Usage:**
```markdown
{{</* note */>}}
This is important information.
{{</* /note */>}}

{{</* warning */>}}
This is a warning.
{{</* /warning */>}}
```

## Best Practices

1. **Always Test Rendering**: After documenting shortcodes, always test the rendering to ensure the examples display correctly.

2. **Use Code Blocks**: When showing multiple shortcode examples, consider placing them in code blocks with triple backticks and the `markdown` language specifier.

3. **Document Parameters**: Always clearly document all possible parameters for each shortcode.

4. **Provide Real Examples**: Include practical examples showing how the shortcode appears when rendered.

5. **Escape Inside Code Blocks**: Even within code blocks, shortcodes should be escaped to prevent unexpected behavior.

## Troubleshooting

### Common Issues

1. **Shortcode Being Executed Instead of Displayed**: 
   - Solution: Use the `{{</* shortcode */>}}` escape syntax.

2. **Unclosed Shortcode Errors**:
   - Solution: Ensure all paired shortcodes have properly escaped closing tags.

3. **Shortcode Not Found Errors**:
   - Solution: Verify that the shortcode template exists in `layouts/shortcodes/`.

### Validation Tools

Use the shortcode checker tool to identify potential issues:

```bash
./doc-doctor-modules/shortcode-check.sh --check-level comprehensive
```

This will identify:
- Unclosed shortcodes
- Missing shortcode templates
- Unknown shortcodes
- Malformed shortcode syntax

## Creating New Shortcodes

When creating new shortcodes:

1. Add the template to `layouts/shortcodes/`
2. Document the shortcode in this guide
3. Add example usage
4. Update shortcode validation tools to include the new shortcode

## Related Documentation

{{< related-docs >}}