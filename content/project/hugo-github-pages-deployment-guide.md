---
title: "Hugo GitHub Pages Deployment Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/project/hugo-documentation-organization-plan/"
  - "/standards/hugo-deployment-standards/"
tags: ["deployment", "github-pages", "hugo", "documentation"]
---

# Hugo GitHub Pages Deployment Guide

{{< status >}}

This document provides a comprehensive guide to the GitHub Pages deployment system for the MCP documentation. It covers the deployment architecture, common issues, and solutions for maintaining the documentation site.

## Deployment Architecture

The MCP documentation uses a two-branch architecture for GitHub Pages:

1. **Main Branch**: Contains the source content (Markdown files, Hugo configuration, templates)
2. **gh-pages Branch**: Contains the built site (HTML, CSS, JavaScript) served by GitHub Pages

The deployment process:
1. Builds the Hugo site from content in the main branch
2. Switches to the gh-pages branch
3. Replaces content with the new build
4. Commits and pushes changes to GitHub
5. Returns to the main branch

## Deployment Scripts

### Main Deployment Script

The primary script `deploy-docs.sh` provides a user-friendly interface for deployment with options:

- `--build-only`: Build without deploying
- `--deploy-only`: Deploy without rebuilding
- `--dry-run`: Test deployment without making changes

### Enhanced Deployment Script

The enhanced deployment script (`deploy/scripts/enhanced-gh-pages-deploy.sh`) handles:

- Working directory validation
- Branch switching
- Content preparation
- Error handling
- File copying

### Content Preparation

The content preparation script (`deploy/scripts/copy-all-content.sh`) consolidates documentation from:
- docs/ directory
- architecture/ directory
- Root directory markdown files
- MCP project documentation

## Common Deployment Issues

### 1. Public Directory Issues

**Problem**: The deployment fails with `cp: cannot stat 'public/*': No such file or directory`

**Causes**:
- Hugo build failure
- Public directory not created
- Public directory created in a different location than expected

**Solutions**:
- Ensure Hugo is installed and working correctly
- Verify the build process creates the `public` directory
- Check for custom output directory settings in Hugo configuration

### 2. Working Directory Not Clean

**Problem**: Deployment fails with "Working directory is not clean"

**Causes**:
- Uncommitted changes in the repository
- Untracked files present

**Solutions**:
- Commit or stash changes before deploying
- Add temporary files to .gitignore
- Use `git status` to identify untracked files

### 3. Merge Conflicts in gh-pages Branch

**Problem**: Git conflicts when updating the gh-pages branch

**Causes**:
- Manual changes to the gh-pages branch
- Concurrent deployments

**Solutions**:
- Never make manual changes to the gh-pages branch
- Coordinate deployments among team members
- Consider using a force push for the gh-pages branch since it contains only generated content

### 4. Missing Content in Deployed Site

**Problem**: Some content is missing from the deployed site

**Causes**:
- Content not included in the build process
- Hugo front matter issues
- Shortcode errors

**Solutions**:
- Check the content copying process
- Validate front matter syntax
- Test for shortcode issues with `doc-doctor.sh`

## Deployment Directory Structure

The directory structure for the deployment process:

```
/                             # Repository root
├── content/                  # Hugo content directory (created during build)
│   ├── _index.md             # Home page
│   ├── project/              # Project documentation
│   ├── architecture/         # Architecture documentation
│   └── ...
├── public/                   # Built site (created by Hugo)
│   ├── index.html            # Generated home page
│   ├── css/                  # Generated CSS
│   └── ...
├── layouts/                  # Hugo layouts
│   ├── _default/             # Default templates
│   └── shortcodes/           # Custom shortcodes
├── deploy/                   # Deployment scripts
│   ├── scripts/              # Helper scripts
│   └── ...
└── deploy-docs.sh            # Main deployment script
```

## Deployment Workflow Improvements

### 1. Build Verification

Before deploying:
```bash
./deploy-docs.sh --build-only
```

This builds the site locally in the `public` directory. Verify the build by:
- Checking that the `public` directory exists and contains files
- Running a local server: `hugo serve`
- Validating key pages load correctly

### 2. Incremental Deployment

For faster deployments when making small changes:
```bash
hugo --minify && git checkout gh-pages && cp -r public/* . && git add . && git commit -m "Update docs" && git push && git checkout main
```

### 3. Debugging Deployment

To debug deployment issues:
1. Run with dry-run flag: `./deploy-docs.sh --dry-run`
2. Check the build output for errors: `hugo --minify --verbose`
3. Examine the public directory: `ls -la public/`
4. Check git status before and after each step

## GitHub Pages Configuration

The GitHub Pages site is configured in the repository settings:

1. **Source**: Set to `gh-pages` branch
2. **Custom Domain**: Can be configured if needed
3. **HTTPS**: Enforce HTTPS should be enabled
4. **Jekyll Processing**: Disabled with a `.nojekyll` file in the gh-pages branch

## Future Enhancements

### 1. GitHub Actions Integration

Implement a GitHub Actions workflow for automated deployments:

```yaml
name: Deploy Hugo site

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true
      - name: Build
        run: hugo --minify
      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

### 2. Deployment Notifications

Add deployment notifications via:
- GitHub status checks
- Slack notifications
- Email notifications

### 3. Preview Deployments

Implement preview deployments for pull requests:
- Build the site from the PR branch
- Deploy to a temporary location
- Provide a link for reviewers

## Maintenance Guidelines

### 1. Regular Deployments

Schedule regular deployments (weekly or bi-weekly) to ensure documentation stays current.

### 2. Pre-Deployment Checklist

Before deploying:
- Run documentation validation: `./doc-doctor.sh`
- Build locally: `./deploy-docs.sh --build-only`
- Check for shortcode issues
- Verify front matter is correct

### 3. Post-Deployment Validation

After deployment:
- Visit the live site
- Check critical pages
- Verify navigation works
- Ensure shortcodes render correctly

### 4. Deployment Logs

Maintain deployment logs:
- Date and time of deployment
- Changes included
- Issues encountered
- Verification results

## Conclusion

The GitHub Pages deployment system provides a reliable way to publish the MCP documentation. By understanding the deployment architecture and addressing common issues, you can ensure that the documentation remains accessible and up-to-date.

Regular maintenance and validation of the deployment process will help prevent issues and ensure a smooth experience for documentation users.

## Related Documentation

{{< related-docs >}}