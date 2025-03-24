# MCP Documentation Build & Quality Assurance Plan

## Overview

This document outlines the consolidated build, verification, and deployment process for MCP documentation following the migration to GitHub Actions-based deployment. It preserves the best elements of our previous verification system while streamlining the deployment process.

## Documentation Quality Pipeline

```
┌─────────────────┐     ┌─────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Local Content  │────▶│ Quality Checks  │────▶│  GitHub Push   │────▶│GitHub Actions  │
│   Development   │     │   (doc-doctor)  │     │  (main branch) │     │   Deployment   │
└─────────────────┘     └─────────────────┘     └────────────────┘     └────────────────┘
```

## 1. Pre-Commit Quality Assurance

Before committing documentation changes, run the doc-doctor tool to ensure quality standards:

```bash
# Standard documentation health check
./doc-doctor.sh

# Comprehensive check for critical documentation
./doc-doctor.sh --check-level comprehensive --focus-area all

# Quick check for minor updates
./doc-doctor.sh --check-level quick
```

The doc-doctor system checks:
- Shortcode syntax and consistency
- Document structure and heading hierarchy
- Frontmatter completeness
- Link validity
- Content organization

## 2. Local Build Verification (Optional)

While no longer required for deployment, you can still verify local builds:

```bash
# Using local Hugo (if installed)
hugo serve

# Using containerized Hugo 
./mcp-docs serve
```

## 3. Commit and Push Changes

Once quality checks pass:

```bash
git add .
git commit -m "docs: [concise description of changes]"
git push origin main
```

## 4. Automated GitHub Actions Deployment

The GitHub Actions workflow will:
1. Detect changes to the main branch
2. Set up Hugo with the correct version
3. Build the site with proper configuration
4. Deploy directly to GitHub Pages
5. Provide deployment status in the Actions tab

**Note:** No manual deployment steps required. The workflow in `.github/workflows/hugo-deploy.yml` handles everything automatically.

## Quality Standards Enforcement

### Document Structure Requirements

All documentation should follow these structural guidelines:

1. **Heading Hierarchy**
   - Start with an H1 title
   - Don't skip heading levels (e.g., H2 to H4)
   
2. **Expected Sections by Document Type**
   - Architecture docs: Overview, Components, Interfaces, Dependencies
   - Guides: Overview, Prerequisites, Usage, Examples
   - Standards: Overview, Guidelines, Examples, References
   - Project docs: Overview, Status, Timeline, Next Steps

3. **Navigation and TOC**
   - Include Table of Contents for documents longer than 50 lines
   - Provide navigation/back links in all documents except the home page

### Shortcode Standards

1. **Properly Closed Tags**
   - All paired shortcodes must have closing tags (`{{< shortcode >}}...{{< /shortcode >}}`)
   
2. **Known Shortcodes**
   - Use only approved shortcodes: callout, tab, tabs, code, highlight, figure, toc, status, progress, related-docs
   
3. **Parameter Format**
   - Parameters should be properly quoted

## Deployment Verification

After GitHub Actions completes deployment:

1. Visit the deployed site: https://verlyn13.github.io/mcp-scope/
2. Check that:
   - The home page loads correctly
   - Navigation between sections works
   - All shortcodes render properly
   - Content is up-to-date with the latest changes

## Legacy Deployment Scripts Reference

The following scripts have been superseded by GitHub Actions and are maintained for reference only:

- `deploy-docs.sh` - Original script that builds the Hugo site
- `deploy-gh-pages.sh` - Manual gh-pages branch deployment
- `deploy-to-github-pages.sh` - Local token-based deployment
- `mcp-docs.sh` - Container-based deployment utility
- `direct-deploy.sh` - Direct Hugo deployment script

**Do not use these scripts for deployment.** GitHub Actions now handles all deployment needs.