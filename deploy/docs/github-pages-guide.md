---
title: "GitHub Pages Deployment Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/deploy/docs/branch-management/"
  - "/deploy/docs/system-integration/"
tags: ["github", "deployment", "pages", "documentation"]
---

# GitHub Pages Deployment Guide

{{< status >}}

This guide provides detailed instructions for safely deploying the MCP documentation site to GitHub Pages.

## Table of Contents

{{< toc >}}

## Overview

The MCP documentation is deployed to GitHub Pages using a dedicated `gh-pages` branch. This approach separates the compiled site content from the source files, enabling clean versioning and simplifying deployment.

## Branch Architecture

The repository uses a two-branch structure:

1. **`main` branch**: Contains all source content, configurations, scripts, and Hugo templates
2. **`gh-pages` branch**: Contains only the compiled static HTML site for deployment

This separation ensures:
- Clean version control history
- Simplified rollback capabilities
- Faster GitHub Pages loading
- Clearer distinction between source and output

## Prerequisites

Before deploying, ensure:

1. You have Git installed and configured
2. You have appropriate repository permissions
3. Hugo is installed locally or Docker/Podman is available
4. Your working directory is clean (no uncommitted changes)
5. You're on the `main` branch

## Deployment Process

### Standard Deployment

The recommended method for deployment uses our enhanced scripts with branch safety features:

```bash
# Build the site first
./deploy/unified-deploy.sh --mode local --skip-git

# Then deploy to GitHub Pages
./deploy/scripts/safe-gh-pages-deploy.sh
```

This process:
1. Builds the Hugo site in the `public` directory
2. Safely switches to the `gh-pages` branch
3. Updates the content with the new build
4. Commits and pushes the changes
5. Returns to the original branch

### Options and Flags

The deployment script supports several options:

| Flag | Description | Default |
|------|-------------|---------|
| `--target-branch` | The branch to deploy to | `gh-pages` |
| `--source-dir` | Directory containing built site | `public` |
| `--skip-confirm` | Skip confirmation prompts | `false` |
| `--dry-run` | Run without making changes | `false` |

Example with options:

```bash
./deploy/scripts/safe-gh-pages-deploy.sh --target-branch gh-pages-staging --dry-run
```

### Safety Features

The deployment script includes several safety mechanisms:

1. **Branch validation**: Verifies you're on the correct branch
2. **Clean working directory check**: Prevents deployment with uncommitted changes
3. **Safe branch switching**: Ensures proper return to original branch
4. **Confirmation prompts**: Requires approval for destructive operations
5. **Comprehensive logging**: Records all branch operations
6. **Dry run mode**: Previews changes without making them

## GitHub Pages Setup

### Initial Configuration

1. Navigate to your GitHub repository
2. Go to Settings > Pages
3. Configure these settings:
   - **Source**: Deploy from a branch
   - **Branch**: gh-pages
   - **Folder**: / (root)
4. Click "Save"

GitHub will provide a URL where your site is published, typically:
`https://<username>.github.io/<repository-name>/`

### Custom Domain (Optional)

To use a custom domain:

1. Add your domain in GitHub repository settings
2. Create appropriate DNS records:
   - For apex domains: A records pointing to GitHub Pages IPs
   - For subdomains: CNAME record pointing to `<username>.github.io`
3. Add a CNAME file to your source content

## Troubleshooting

### Common Issues

| Issue | Possible Solution |
|-------|-------------------|
| Failed branch switch | Commit or stash changes first |
| Push errors | Ensure you have write access to the repository |
| Jekyll errors | GitHub Pages uses Jekyll by default; add a `.nojekyll` file to disable it |
| Broken links | Use relative URLs in your content |
| Outdated content | Ensure you're deploying the latest build |

### Recovery Procedures

If something goes wrong:

1. **Branch Confusion**: Use `git branch --show-current` to identify your current branch
2. **Return to Main**: Use `git checkout main` to return to the main branch
3. **Reset Target Branch**: If the gh-pages branch is corrupted, recreate it with:
   ```bash
   git checkout --orphan gh-pages-new
   git rm -rf .
   echo "# MCP Documentation" > README.md
   git add README.md
   git commit -m "Reset gh-pages branch"
   git branch -D gh-pages
   git branch -m gh-pages
   git push -f origin gh-pages
   git checkout main
   ```

## Best Practices

1. **Always deploy from main**: Start the deployment process from the main branch
2. **Never edit gh-pages directly**: Always generate content from source
3. **Verify before pushing**: Use the `--dry-run` flag to preview changes
4. **Keep detailed logs**: Review deployment logs in `deploy-reports/branch-logs/`
5. **Automate where possible**: Consider setting up GitHub Actions for automatic deployment

## Deployment Verification

After deployment, verify:

1. **Site accessibility**: Visit the GitHub Pages URL
2. **Content correctness**: Check for missing pages or broken links
3. **Branch integrity**: Ensure both branches contain appropriate content
4. **Branch history**: Check that commit history makes sense

## Related Documentation

{{< related-docs >}}