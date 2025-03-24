# MCP Documentation Directory Structure Guide

## Overview

This guide explains the MCP documentation directory structure following our transition to GitHub Actions-based deployment. Understanding this structure is essential for maintaining documentation organization and ensuring proper deployment.

## Primary Directory Structure

```
mcp-scope/
├── content/           # Primary Hugo content (deployed to GitHub Pages)
├── docs/              # Internal documentation and reference materials
│   └── consolidated/  # Consolidated documentation guidelines
├── deploy/            # Deployment reference scripts and documentation
├── themes/            # Hugo themes and templates
└── doc-doctor-modules/ # Documentation quality verification scripts
```

## Content Directory (`/content`)

The `/content` directory contains all documentation processed by Hugo and deployed to GitHub Pages. This is the **primary documentation source** that will appear on the published site.

### Structure

```
content/
├── _index.md                 # Home page
├── architecture/             # Architecture documentation
├── guides/                   # How-to guides and tutorials
├── mcp/                      # Core MCP documentation
├── project/                  # Project management documentation
├── standards/                # Coding and documentation standards
└── templates/                # Document templates
```

### Guidelines

- All user-facing documentation should be placed in the `/content` directory
- Maintain the established subdirectory organization
- Follow the document structure requirements from doc-doctor
- All files in this directory are automatically processed by Hugo

## Documentation Reference (`/docs`)

The `/docs` directory contains internal documentation, reference materials, and architectural documents that are not directly published to the documentation site.

### Structure

```
docs/
├── README.md
├── START_HERE.md
├── architecture/      # Architecture reference documents
├── guides/            # Internal guide references
├── project/           # Project management references
├── standards/         # Standards reference documents
├── templates/         # Template reference documents
└── tools/             # Documentation tools references
└── consolidated/      # Consolidated documentation guidelines
```

### Guidelines

- Use for internal reference materials not intended for publication
- Store architectural decisions and planning documents
- Keep historical references and lessons learned
- Reference material for documentation contributors

## Deployment Resources (`/deploy`)

The `/deploy` directory contains reference scripts and documentation about the deployment process. These are maintained for reference only and are not used in the GitHub Actions deployment process.

### Structure

```
deploy/
├── unified-deploy.sh
├── docs/              # Deployment reference documentation
└── scripts/           # Reference deployment scripts
```

### Guidelines

- Maintained for reference purposes only
- Do not use these scripts for deployment (use GitHub Actions instead)
- Documentation of historical deployment processes

## Doc-Doctor Quality System (`/doc-doctor-modules`)

The `/doc-doctor-modules` directory contains quality verification scripts for documentation.

### Structure

```
doc-doctor-modules/
├── frontmatter-check.sh     # Verifies frontmatter completeness
├── link-check.sh            # Validates internal and external links
├── shortcode-check.sh       # Checks shortcode syntax
├── status-check.sh          # Verifies document status metadata
└── structure-check.sh       # Validates document structure
```

### Guidelines

- Used by the main `doc-doctor.sh` script
- Add new check modules for additional quality requirements
- Comprehensive quality verification system

## File Organization Best Practices

1. **Documentation Type**
   - Architecture documents → `/content/architecture/`
   - User guides → `/content/guides/`
   - Project documentation → `/content/project/`
   - Standards and conventions → `/content/standards/`

2. **Naming Conventions**
   - Use kebab-case for filenames (e.g., `deployment-guide.md`)
   - Include descriptive prefixes for related documents
   - Group related documents in appropriately named directories

3. **Index Files**
   - Each directory should have an `_index.md` file
   - Section indices should list and categorize all contained documents

## GitHub Actions Deployment Process

The GitHub Actions workflow (`.github/workflows/hugo-deploy.yml`) processes only the following directories:

- `/content` - All user-facing documentation
- `/themes` - Hugo themes and templates
- `/static` - Static assets (images, CSS, JS)
- `/layouts` - Any custom layout overrides

Files outside these directories are not processed or deployed to GitHub Pages.

## Migration Notes

If you find documentation in the root directory that should be published:

1. Move the file to the appropriate location in the `/content` directory
2. Update any internal links that reference the old location
3. Run doc-doctor to verify the documentation structure

## Conclusion

Following this directory structure ensures:

1. Clear separation between published and internal documentation
2. Proper processing and deployment via GitHub Actions
3. Consistent organization that supports doc-doctor verification
4. Simplified maintenance and updates

For questions or suggestions about the documentation structure, please contact the documentation team.