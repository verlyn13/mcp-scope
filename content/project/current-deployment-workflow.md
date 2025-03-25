---
title: "Current Documentation Deployment Workflow"
date: 2025-03-24
lastmod: 2025-03-24
weight: 1
description: "Step-by-step guide for the current GitHub Actions-based deployment workflow"
status: "complete"
---

# Current Documentation Deployment Workflow

This document provides a concise, step-by-step guide for building and deploying the MCP documentation site using our current GitHub Actions workflow.

## Overview

Our documentation uses GitHub Actions for automated deployment to GitHub Pages. This process:
- Requires no manual branch switching
- Happens automatically when changes are pushed
- Maintains a consistent build environment
- Provides clear logs and error reporting

## Step 1: Development Options

Choose one of these approaches based on your needs:

### Option A: Build and Test Locally (Full Testing)

When you need to see your changes before deploying:

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/verlyn13/mcp-scope.git
cd mcp-scope

# Make sure you're on the main branch
git checkout main
git pull origin main

# Run Hugo locally using our containerized setup
./run-hugo.sh server
# This builds and runs Hugo in a container with the correct configuration

# If you encounter any errors, you can rebuild the container:
./run-hugo.sh rebuild server

# View the local site at http://localhost:1313/
```

### Option B: Quick Build Without Testing (Fast Workflow)

If you just want to verify the site builds without viewing it:

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/verlyn13/mcp-scope.git
cd mcp-scope

# Make sure you're on the main branch
git checkout main
git pull origin main

# Just build the site without running the server
./run-hugo.sh build

# If you encounter any errors, you can rebuild the container:
./run-hugo.sh rebuild build
```

### Option C: Direct Commit and Push (Super Fast)

If you want to skip local validation entirely and rely on GitHub Actions:

```bash
# Clone the repository (if you haven't already)
git clone https://github.com/verlyn13/mcp-scope.git
cd mcp-scope

# Make sure you're on the main branch
git checkout main
git pull origin main

# Make your documentation changes
# ...

# Commit and push directly without local testing
git add .
git commit -m "Updated documentation"
git push origin main

# Monitor the build in GitHub Actions to ensure it succeeds
```

This approach is fastest but riskiest - if your changes cause build failures, you'll need to make additional commits to fix them.

## Step 2: Commit and Push Changes

Once you're satisfied with your changes:

```bash
# Stage your changes
git add .

# Commit with a descriptive message
git commit -m "Updated documentation for xyz component"

# Push to GitHub
git push origin main
```

## Step 3: Deployment Process (Automatic)

After pushing to main:

1. GitHub Actions automatically detects the push
2. The workflow defined in `.github/workflows/hugo-deploy.yml` starts running
3. Hugo builds the site with the correct configuration
4. The built site is deployed to GitHub Pages

**You can monitor this process:**
1. Go to the GitHub repository
2. Click the "Actions" tab
3. Look for the "Deploy Hugo site to GitHub Pages" workflow
4. Click on the most recent run to see detailed logs

## Step 4: Verify Deployment

After the GitHub Actions workflow completes:

1. Visit https://verlyn13.github.io/mcp-scope/
2. Check that your changes appear correctly
3. Verify all links and navigation work properly
4. Test any new features or content you've added

## Manual Deployment (If Needed)

If you need to trigger a deployment without making code changes:

1. Go to the GitHub repository
2. Click the "Actions" tab
3. Select "Deploy Hugo site to GitHub Pages" workflow
4. Click "Run workflow" button
5. Select the main branch
6. Click "Run workflow"

## Troubleshooting

### GitHub Actions Deployment Issues

If your deployment fails on GitHub:

1. Check the GitHub Actions logs for error messages
2. Common issues include:
   - Hugo build errors (syntax issues, invalid frontmatter)
   - Missing theme or components
   - Permission issues
3. Fix the issues locally and test with `./run-hugo.sh`
4. Commit and push the fixes
5. Monitor the new workflow run

### Local Hugo Issues

#### "Git Executable Not Found" Error

If you see this error when running Hugo locally:
```
ERROR: Failed to read Git log: Git executable not found in $PATH
```

The solution is to force a rebuild of the Hugo container:
```bash
./run-hugo.sh rebuild server  # For server mode
# OR
./run-hugo.sh rebuild build   # For build-only mode
```

This ensures the container has Git properly installed, which Hugo needs for generating last modified dates.

#### Other Container Issues

If other container issues persist:
1. Try the rebuild command shown above
2. Check if podman/docker is running properly on your system
3. Verify there are no permission issues in your current directory

## Important Notes

- The gh-pages branch is managed automatically by GitHub Actions - do not commit to it directly
- Older deployment scripts (`deploy-to-github-pages.sh`, `deploy-docs.sh`, etc.) are deprecated and should not be used
- Each push to main triggers a new deployment, so commit thoughtfully
- For larger changes, consider using feature branches and pull requests

## Related Documentation

- [Git Workflow Guide](/git-workflow/)
- [GitHub Actions Deployment Guide](/project/github-actions-deployment-guide/)
- [GitHub Pages Deployment Solution](/project/github-pages-deployment-solution/)