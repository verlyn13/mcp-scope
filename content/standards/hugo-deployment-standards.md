---
title: "Hugo Deployment Standards"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/project/hugo-documentation-organization-plan/"
  - "/standards/shortcode-documentation-guidelines/"
tags: ["deployment", "standards", "hugo", "github-pages"]
---

# Hugo Deployment Standards

{{< status >}}

This document outlines the standard procedures for deploying the MCP documentation site to GitHub Pages.

## Deployment Process Overview

The MCP documentation site is automatically deployed to GitHub Pages through a structured process that ensures consistency and quality. The deployment process:

1. Builds the Hugo site from the content in the `main` branch
2. Performs validation checks on the generated site
3. Pushes the built site to the `gh-pages` branch
4. GitHub Pages automatically serves the content from the `gh-pages` branch

## Deployment Prerequisites

Before deploying, ensure:

1. All documentation changes are committed to the `main` branch
2. The working directory is clean (no uncommitted changes)
3. Hugo is installed (version 0.80.0 or newer)
4. You have push access to the repository

## Standard Deployment Procedure

### Using the Deployment Script

The primary method for deployment is the `deploy-docs.sh` script:

```bash
./deploy-docs.sh
```

This script:
1. Cleans the content directory
2. Copies all documentation from various sources
3. Builds the Hugo site
4. Switches to the `gh-pages` branch
5. Replaces the contents with the new build
6. Commits and pushes the changes
7. Returns to the original branch

### Build-Only Mode

If you want to build without deploying (for testing):

```bash
./deploy-docs.sh --build-only
```

This builds the site locally in the `public` directory without pushing to GitHub.

### Dry-Run Mode

To simulate the deployment without making actual changes:

```bash
./deploy-docs.sh --dry-run
```

This shows what would happen during deployment without pushing changes.

## Pre-Deployment Validation

Before deploying, run the documentation checks to identify potential issues:

```bash
./doc-doctor.sh
```

This checks for:
- Unclosed shortcodes
- Missing shortcode templates
- Broken internal links
- Front matter consistency
- Documentation structure issues

## Deployment Best Practices

### 1. Regular Deployment Schedule

- Deploy after significant documentation updates
- Schedule regular deployments (weekly or bi-weekly)
- Coordinate deployments with other team members

### 2. Testing Before Deployment

- Always run `./deploy-docs.sh --build-only` before full deployment
- Check the built site locally using `hugo server`
- Validate changes with `./doc-doctor.sh`

### 3. Commit Messages

Use clear, descriptive commit messages for the deployment:

```
Update documentation - YYYY-MM-DD

- Added new guide for X
- Updated architecture diagrams
- Fixed broken links in Y section
```

### 4. Post-Deployment Verification

After deployment:
1. Visit the live site to verify changes
2. Check critical pages for proper rendering
3. Verify that shortcodes are working correctly
4. Test navigation and search functionality

## Troubleshooting Common Issues

### 1. Build Failures

If the build fails:
- Check Hugo version compatibility
- Look for unclosed shortcodes (use `./doc-doctor-modules/shortcode-check.sh --check-level comprehensive`)
- Verify front matter format
- Check for invalid or conflicting templates

### 2. Dirty Working Directory

If you get a "working directory is not clean" error:
1. Commit or stash changes
2. Run `git status` to check for untracked files
3. Try again with a clean working directory

### 3. Shortcode Rendering Issues

If shortcodes don't render correctly:
- Ensure all shortcode templates exist in `layouts/shortcodes/`
- Check for proper shortcode syntax
- Verify that example shortcodes are properly escaped with `{{</* shortcode */>}}`
- Refer to `/standards/shortcode-documentation-guidelines/`

### 4. Merge Conflicts in gh-pages Branch

If you encounter merge conflicts:
1. Resolve conflicts manually
2. Consider force-pushing with `--force` if the `gh-pages` branch is only used for generated content

## GitHub Pages Configuration

The GitHub Pages site is configured to:
- Serve from the `gh-pages` branch
- Use a custom domain (if configured)
- Not use Jekyll processing (using a `.nojekyll` file)

To modify GitHub Pages settings:
1. Go to the repository settings
2. Navigate to the Pages section
3. Adjust settings as needed

## Continuous Integration (Future Enhancement)

In the future, we plan to implement automated deployments via GitHub Actions:
- On push to main branch
- On schedule (nightly builds)
- On pull request (preview deployments)

## Documentation Updates

When making changes to the deployment process:
1. Update this document
2. Update related scripts
3. Communicate changes to the team

## Related Documentation

{{< related-docs >}}