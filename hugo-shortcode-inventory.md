# Hugo Shortcode Inventory and Implementation Plan

## Overview

This document catalogs all shortcodes used in the MCP documentation, their implementation status, and a plan to ensure all are properly supported.

## Shortcode Inventory

| Shortcode | Purpose | Status | Files Using | Template Path |
|-----------|---------|--------|-------------|---------------|
| `toc` | Table of Contents | ✅ Created | health-monitoring-guide.md | themes/mcp-theme/layouts/shortcodes/toc.html |
| `callout` | Styled message boxes | ⚠️ Exists but issues | phase3-progress.md | themes/mcp-theme/layouts/shortcodes/callout.html |
| `status` | Document status indicator | ✅ Exists | Multiple | themes/mcp-theme/layouts/shortcodes/status.html |
| `progress` | Progress bar | ✅ Exists | Multiple | themes/mcp-theme/layouts/shortcodes/progress.html |
| `related-docs` | List related documents | ✅ Exists | Multiple | themes/mcp-theme/layouts/shortcodes/related-docs.html |

## Issues to Resolve

1. **Malformed Shortcodes**:
   - Unclosed callout shortcode in phase3-progress.md (line 87)
   - Need to scan other content files for similar issues

2. **Missing Templates**:
   - The toc shortcode was missing but has been created
   - Need to verify all other required shortcodes have templates and are working

3. **Inconsistent Usage**:
   - Different formats or parameters across documents
   - Need to standardize usage patterns

## Implementation Plan

### 1. Complete the Shortcode Template Set

Ensure all required shortcodes have proper templates:

```bash
# Create any missing shortcode templates
mkdir -p themes/mcp-theme/layouts/shortcodes
touch themes/mcp-theme/layouts/shortcodes/[shortcode].html
```

### 2. Fix Malformed Content

Identify and fix any content with malformed shortcode usage:

```bash
# Check phase3-progress.md line 87 for unclosed callout
# Scan other content files for similar issues
```

### 3. Standardize Usage

Create a documentation standard for shortcode usage:

- Consistent parameter formats
- Clear examples
- Validated templates

### 4. Verify Hugo Configuration

Ensure Hugo configuration is correct:

- theme setting
- content directories
- shortcode directory paths

## Shortcode Implementation Details

### Table of Contents (`toc`)

**Template:**
```html
{{ .Page.TableOfContents }}
```

### Callout (`callout`)

**Template:**
```html
{{ $type := .Get 0 }}
{{ $title := .Get 1 }}
<div class="callout callout-{{ $type }}">
  <h4 class="callout-title">{{ $title }}</h4>
  <div class="callout-content">
    {{ .Inner | markdownify }}
  </div>
</div>
```

**Usage:**
```markdown
{{< callout "info" "Note" >}}
This is an informational note.
{{< /callout >}}
```

### Status (`status`)

**Template:**
```html
{{ $status := .Page.Params.status | default "Draft" }}
<div class="status-indicator status-{{ lower $status }}">
  <span class="status-text">{{ $status }}</span>
</div>
```

### Progress (`progress`)

**Template:**
```html
{{ $value := .Get "value" | default "0" }}
<div class="progress">
  <div class="progress-bar" style="width: {{ $value }}%">{{ $value }}%</div>
</div>
```

### Related Docs (`related-docs`)

**Template:**
```html
{{ if .Page.Params.related_docs }}
<div class="related-docs">
  <h2>Related Documents</h2>
  <ul>
    {{ range .Page.Params.related_docs }}
    <li><a href="{{ . }}">{{ . }}</a></li>
    {{ end }}
  </ul>
</div>
{{ end }}
```

## Next Steps

- Fix the phase3-progress.md unclosed callout issue
- Create a complete documentation standard for shortcode usage
- Verify all content files follow the standards
- Test Hugo build with fixed shortcodes