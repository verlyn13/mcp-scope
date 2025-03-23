---
title: "Path Reference Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/"
  - "/project/project-organization/"
tags: ["project-wide", "paths", "reference", "organization", "quick-reference", "hugo"]
---

# Path Reference Guide

{{< status >}}

[↩️ Back to Project Documentation](/project/) | [↩️ Back to Documentation Index](/docs/)

## Overview

This quick reference guide provides clear examples for correct path references in both the original repository structure and the new Hugo documentation site.

{{< callout "info" "Hugo Migration" >}}
As part of the migration to Hugo, path references have been standardized. All internal links now use Hugo's URL format (without file extensions), making navigation more consistent.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Documentation Structure

### Original Repository Structure

| Layer | Repository-Relative Path |
|-------|-------------------------|
| **Root Project** | `/` |
| **Root Documentation** | `/docs` |
| **MCP Implementation** | `/mcp-project` |
| **MCP Documentation** | `/mcp-project/docs` |

### Hugo Documentation Structure

| Section | Hugo Path | Content Directory |
|---------|-----------|-------------------|
| **Root Level** | `/` | `/content/` |
| **Documentation Index** | `/docs/` | `/content/docs/` |
| **Project Section** | `/project/` | `/content/project/` |
| **Architecture Section** | `/architecture/` | `/content/architecture/` |
| **Guides Section** | `/guides/` | `/content/guides/` |
| **MCP Documentation** | `/mcp/` | `/content/mcp/` |

## Path Reference Examples in Hugo

### Correct Hugo Path References

#### Linking to Root Documentation
```markdown
[Documentation Index](/docs/)
```

#### Linking to Project Documentation
```markdown
[Project Organization](/project/project-organization/)
```

#### Linking to MCP Documentation
```markdown
[MCP Architecture Overview](/mcp/architecture/overview/)
```

#### Linking to Guides
```markdown
[Testing Guide](/guides/testing-guide/)
```

### Hugo URL Conventions

Hugo uses a cleaner URL structure without file extensions:

| Content Type | Hugo URL Format |
|--------------|-----------------|
| Regular Page | `/section/page-name/` |
| Section Index | `/section/` |
| Home Page | `/` |

## Hugo-specific Path Guidelines

1. **No File Extensions**: URLs don't include `.md` or `.html` extensions
2. **Trailing Slash**: URLs typically end with a trailing slash
3. **Section Structure**: Content is organized into sections that correspond to top-level directories in the `content/` folder

## Implementation Progress

| Component | Status | Completion |
|-----------|--------|------------|
| Link Structure Documentation | 🟢 Active | {{< progress value="100" >}} |
| Repository Path Reference | 🟢 Active | {{< progress value="100" >}} |
| Hugo Path Guidelines | 🟢 Active | {{< progress value="95" >}} |
| Path Error Documentation | 🟡 Draft | {{< progress value="70" >}} |
| Visual Decision Tree | 🟡 Draft | {{< progress value="80" >}} |

## Original Repository Reference

For reference, here's how paths were structured in the original repository:

### Repository Path Examples

#### From Root Documentation to Root Documentation
```markdown
[Project Organization](/docs/project/project-organization.md)
```

#### From Root Documentation to MCP Documentation
```markdown
[MCP Architecture Overview](/mcp-project/docs/architecture/overview.md)
```

#### From MCP Documentation to MCP Documentation
```markdown
[Local Development Guide](/mcp-project/docs/implementation/local-development-guide.md)
```

#### From MCP Documentation to Root Documentation
```markdown
[Project Organization](/docs/project/project-organization.md)
```

## Hugo Path Decision Tree

```
Is the document you're referencing in:
│
├── Documentation Index?
│   │
│   └── YES → Use: /docs/
│
├── Project Documentation?
│   │
│   └── YES → Use: /project/page-name/
│
├── Architecture Documentation?
│   │
│   └── YES → Use: /architecture/page-name/
│
├── Guides?
│   │
│   └── YES → Use: /guides/guide-name/
│
└── MCP Documentation?
    │
    └── YES → Use: /mcp/section/page-name/
```

## Quick Reference for Common Documents

| Document | Hugo Path | Original Repository Path |
|----------|-----------|--------------------------|
| Documentation Index | `/docs/` | `/docs/README.md` |
| Project Organization | `/project/project-organization/` | `/docs/project/project-organization.md` |
| Architecture Overview | `/architecture/overview/` | `/docs/architecture/overview.md` |
| Testing Guide | `/guides/testing-guide/` | `/docs/guides/testing-guide.md` |
| MCP Architecture | `/mcp/architecture/overview/` | `/mcp-project/docs/architecture/overview.md` |
| Getting Started | `/mcp/docs/getting-started/` | `/mcp-project/docs/getting-started.md` |

## Common Path Errors

{{< callout "warning" "Common Mistakes" >}}
When migrating content or creating new documents, watch out for these common path reference errors.
{{< /callout >}}

| Error | Example | Correction |
|-------|---------|------------|
| Using file extensions | `/guides/testing-guide.md` | `/guides/testing-guide/` |
| Missing trailing slash | `/guides/testing-guide` | `/guides/testing-guide/` |
| Using repository paths | `/docs/project/project-organization.md` | `/project/project-organization/` |
| Incorrect section | `/docs/testing-guide/` | `/guides/testing-guide/` |

## Best Practices

1. **Always use relative URLs** starting from the site root
2. **Omit file extensions** in all internal links
3. **Include the trailing slash** at the end of URLs
4. **Use the correct section prefix** based on the document type
5. **Test all links** before committing changes

## Cross-section Navigation

For cross-section references, we use clear section indicators:

```markdown
See the [Testing Guide](/guides/testing-guide/) for more information on testing practices.
```

## Related Documentation

{{< related-docs >}}