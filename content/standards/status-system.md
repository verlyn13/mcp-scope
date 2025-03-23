---
title: "Document Status System"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/standards/documentation-guidelines/"
  - "/standards/shortcode-standards/"
tags: ["standards", "status", "documentation", "metadata"]
---

# Document Status System

{{< status >}}

[↩️ Back to Standards](/standards/) | [↩️ Back to Documentation Index](/docs/)

## Overview

The document status system provides a standardized way to indicate the current state of a document in the MCP documentation. This system ensures consistency and clarity regarding document readiness and relevance.

## Table of Contents

{{< toc >}}

## Status Indicators

### Available Status Types

The MCP documentation uses the following standardized status types:

| Status | Description | Visual Indicator |
|--------|-------------|------------------|
| `Draft` | Document is in development and not ready for review | Orange badge |
| `Review` | Document is ready for peer review | Blue badge |
| `Active` | Document is complete, reviewed, and current | Green badge |
| `Deprecated` | Document is outdated but kept for reference | Gray badge |
| `Archived` | Document is no longer relevant but preserved | Black badge |

### Front Matter Configuration

Every document must include a status field in its front matter:

```yaml
---
title: "Document Title"
status: "Active"  # Required status field
version: "1.0"    # Version number
date_created: "YYYY-MM-DD"
last_updated: "YYYY-MM-DD"
---
```

### Status Shortcode Implementation

The status indicator is displayed using the `status` shortcode:

```markdown
# Document Title

{{< status >}}
```

## Status Lifecycle

Documents typically progress through the following status lifecycle:

1. **Draft**: Initial creation and development
2. **Review**: Ready for technical and editorial review
3. **Active**: Approved and current
4. **Deprecated** or **Archived**: When superseded or no longer relevant

### Status Transitions

Status transitions should be documented in the document's changelog and updated in the front matter.

## Visual Styling

The status indicator appears as a colored badge near the document title, providing immediate visual feedback on the document's state:

- **Draft**: Orange with document icon
- **Review**: Blue with check icon
- **Active**: Green with checkmark icon
- **Deprecated**: Gray with warning icon
- **Archived**: Black with archive icon

## Status System Implementation

### Shortcode Template

The status shortcode template extracts metadata from the front matter:

```html
{{ $status := .Page.Params.status | default "Draft" }}
<div class="status-indicator status-{{ lower $status }}">
  <span class="status-icon"></span>
  <span class="status-text">{{ $status }}</span>
  {{ if .Page.Params.last_updated }}
  <span class="status-date">Last updated: {{ .Page.Params.last_updated }}</span>
  {{ end }}
</div>
```

### CSS Styling

The status indicators are styled using CSS classes that correspond to each status type.

## Status Reporting

### Status Dashboard

A status dashboard is available that provides an overview of document statuses across the documentation:

- Total documents by status type
- Recently updated documents
- Documents needing review

### Status in Search Results

The documentation search functionality includes status indicators in search results to help users identify the most current and relevant content.

## Best Practices

1. **Accuracy**: Always ensure the status accurately reflects the current state of the document
2. **Timeliness**: Update the status and last_updated date whenever significant changes are made
3. **Transparency**: Include a changelog section to document status changes
4. **Consistency**: Use only the standardized status types listed above
5. **Visibility**: Always include the status shortcode immediately after the document title

## Automated Status Tools

### Status Verification

The documentation system includes tools to verify status consistency:

```bash
# Check for missing or invalid status fields
./verify-doc-status.sh
```

### Status Reports

Generate a report of document statuses:

```bash
# Generate a CSV report of all document statuses
./generate-status-report.sh
```

## Related Documentation

{{< related-docs >}}