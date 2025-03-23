---
title: "Path Reference Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-22"
last_updated: "2025-03-22"
contributors: ["Documentation Architect"]
related_docs:
  - "/docs/README.md"
  - "/docs/project/project-organization.md"
tags: ["project-wide", "paths", "reference", "organization", "quick-reference"]
---

# Path Reference Guide

🟢 **Active**

[↩️ Back to Documentation Hub](/docs/README.md)

## Overview

This quick reference guide provides clear examples for correct path references across the dual-layer structure of the ScopeCam MCP project, eliminating path confusion once and for all.

## Project Base Directories

| Layer | Absolute Path | Repository-Relative Path |
|-------|--------------|-------------------------|
| **Root Project** | `/home/verlyn13/Projects/mcp-scope` | `/` |
| **MCP Implementation** | `/home/verlyn13/Projects/mcp-scope/mcp-project` | `/mcp-project` |

## Documentation Directories

| Documentation | Absolute Path | Repository-Relative Path |
|---------------|--------------|-------------------------|
| **Root Documentation** | `/home/verlyn13/Projects/mcp-scope/docs` | `/docs` |
| **MCP Documentation** | `/home/verlyn13/Projects/mcp-scope/mcp-project/docs` | `/mcp-project/docs` |

## Path Reference Examples

### ✅ Correct Path References

#### From Root Documentation to Root Documentation
```markdown
[Project Organization](/docs/project/project-organization.md)
```

#### From Root Documentation to MCP Documentation
```markdown
[🔄 MCP Architecture Overview](/mcp-project/docs/architecture/overview.md)
```

#### From MCP Documentation to MCP Documentation
```markdown
[Local Development Guide](/mcp-project/docs/implementation/local-development-guide.md)
```

#### From MCP Documentation to Root Documentation
```markdown
[🔄 Project Organization](/docs/project/project-organization.md)
```

### ❌ Incorrect Path References

#### Incorrect: Using Absolute Paths
```markdown
[Project Organization](/home/verlyn13/Projects/mcp-scope/docs/project/project-organization.md)
```

#### Incorrect: Missing Layer Context
```markdown
[Architecture Overview](/docs/architecture/overview.md)  <!-- Wrong! MCP docs are in /mcp-project/docs/ -->
```

#### Incorrect: Improper Directory Navigation
```markdown
[Project Organization](../../docs/project/project-organization.md)
```

## Visual Path Decision Tree

```
Is the document you're referencing in:
│
├── Root Project Documentation?
│   │
│   └── YES → Use: /docs/path/to/document.md
│
└── MCP Implementation Documentation?
    │
    └── YES → Use: /mcp-project/docs/path/to/document.md
```

## Quick Reference for Common Documents

| Document | Correct Path Reference |
|----------|------------------------|
| Root README | `/README.md` |
| Documentation Hub | `/docs/README.md` |
| Project Organization | `/docs/project/project-organization.md` |
| MCP README | `/mcp-project/README.md` |
| MCP Documentation Index | `/mcp-project/docs/README.md` |
| Architecture Overview | `/mcp-project/docs/architecture/overview.md` |
| First Steps Guide | `/mcp-project/docs/project/first-steps.md` |

## CLI Command Examples

When running commands, always be explicit about which directory you're in:

### Root Project Commands
```bash
# From the root project directory
cd /home/verlyn13/Projects/mcp-scope
ls -la docs/
```

### MCP Implementation Commands
```bash
# From the MCP implementation directory
cd /home/verlyn13/Projects/mcp-scope/mcp-project
./gradlew build
```

## Path Confusion Resolution Chart

| If you want to... | Use this path |
|-------------------|---------------|
| Reference root project files | `/README.md`, `/LICENSE`, etc. |
| Reference root documentation | `/docs/...` |
| Reference MCP implementation files | `/mcp-project/...` |
| Reference MCP documentation | `/mcp-project/docs/...` |
| Run MCP implementation commands | First `cd /home/verlyn13/Projects/mcp-scope/mcp-project` |
| Run root project commands | First `cd /home/verlyn13/Projects/mcp-scope` |

## Repository-Relative vs. Document-Relative Paths

- **Repository-relative paths** (starting with `/`) are recommended for consistency
- **Document-relative paths** may be used for files in the same directory:
  - Same directory: `other-file.md`
  - Child directory: `child-dir/file.md`
  - Parent directory: `../file.md` (use sparingly)

## Remember

1. **Always use repository-relative paths** (starting with `/`) for cross-directory references
2. **Include the 🔄 symbol** when crossing between documentation layers 
3. **Never use absolute file system paths** in documentation

This guide, combined with the [Project Organization](/docs/project/project-organization.md) document, should eliminate all path confusion in the project.

## Changelog

- 1.0.0 (2025-03-22): Initial release