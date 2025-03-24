# GitHub Actions Deployment: Updated Guide

## Overview

This guide provides updated instructions for deploying documentation changes to GitHub Pages using GitHub Actions. It includes both the automated workflow process and a new streamlined deployment script.

## Quick Deployment Guide

The simplest way to deploy updates is to use the deployment script:

```bash
# Make your documentation changes

# Run the deployment script
./docs/consolidated/deploy-to-github.sh

# Enter a commit message when prompted
# The script will commit, push, and monitor the workflow
```

The script handles:
- Checking for uncommitted changes
- Adding proper commit message prefixes
- Pushing to the correct branch
- Monitoring workflow status (if GitHub CLI is installed)

## Detailed GitHub Actions Workflow

The deployment process follows these steps:

1. **Changes are pushed to the main branch**
   - Either manually using git commands
   - Or using the deployment script

2. **GitHub Actions workflow is triggered automatically**
   - `.github/workflows/hugo-deploy.yml` executes
   - Workflow installs Hugo with the correct version
   - Content is built with proper configuration

3. **Build artifacts are published to GitHub Pages**
   - Built site is packaged as a deployment artifact
   - GitHub's deployment system publishes to GitHub Pages
   - No manual branch management required

4. **Deployment completes**
   - Site is available at https://verlyn13.github.io/mcp-scope/
   - Workflow status is visible in the Actions tab

## Monitoring Deployment Status

### Using GitHub CLI

If you have the GitHub CLI installed (`gh`), you can monitor workflow status:

```bash
# View workflow status
gh workflow view "Deploy Hugo site to GitHub Pages"

# List recent workflow runs
gh run list --workflow "Deploy Hugo site to GitHub Pages"

# View details of the latest run
gh run view $(gh run list --workflow "Deploy Hugo site to GitHub Pages" --limit 1 --json databaseId --jq '.[0].databaseId')
```

### Using Web Interface

You can also monitor deployment through the GitHub web interface:

1. Go to the repository page
2. Click on the "Actions" tab
3. Select the "Deploy Hugo site to GitHub Pages" workflow
4. View the latest run to see deployment status

## Manual Workflow Triggering

If you need to trigger a rebuild without making changes:

```bash
# Using GitHub CLI
gh workflow run "Deploy Hugo site to GitHub Pages" --ref main

# Or using the deployment script with no changes
./docs/consolidated/deploy-to-github.sh
# Select "y" when asked if you want to trigger the workflow
```

## Troubleshooting

### Common Issues

1. **Workflow not triggering**
   - Check branch name (should be `main`)
   - Verify workflow is enabled in Actions settings
   - Ensure `.github/workflows/hugo-deploy.yml` exists

2. **Build errors**
   - Check Actions logs for specific error messages
   - Common issues include missing theme files or YAML syntax errors
   - Test locally with `./mcp-docs.sh hugo server` before pushing

3. **Deployment without publishing**
   - Verify GitHub Pages is configured to deploy from GitHub Actions
   - Check repository permissions for GitHub Actions

### Accessing Build Logs

Detailed build logs help diagnose issues:

1. Go to Actions tab in the repository
2. Select the failed workflow run
3. Expand the job that failed
4. Review logs for error messages

## Best Practices

1. **Always test locally before deploying**
   ```bash
   ./mcp-docs.sh hugo server
   ```

2. **Use descriptive commit messages**
   - Prefix with `docs:` for documentation changes
   - Include specific details about what changed

3. **Monitor deployment status**
   - Verify changes appear correctly on the live site
   - Check for any warnings in build logs

4. **Run doc-doctor before deploying**
   ```bash
   ./doc-doctor.sh --check-level standard
   ```

## Conclusion

The GitHub Actions deployment process provides a reliable, consistent way to deploy documentation updates. Using the new deployment script simplifies this process further, handling the Git operations and providing workflow status monitoring.

By following this guide and using the provided tools, you can ensure smooth, error-free documentation deployments.