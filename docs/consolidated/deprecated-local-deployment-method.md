# Deprecated Local Deployment Method for Hugo Documentation

⚫ **ARCHIVED** - This document preserves information about a deployment approach that is no longer in use.

## Context and Status

This document archives the previous local script-based approach to deploying the MCP documentation site to GitHub Pages. This method has been **fully replaced** by GitHub Actions automation as of March 2025.

For the current official deployment method, please refer to:
- [GitHub Pages Deployment Solution](/content/project/github-pages-deployment-solution.md)
- [GitHub Actions Deployment Guide](/content/project/github-actions-deployment-guide.md)

## Historical Implementation

The project previously used a set of shell scripts for manual deployment:

1. `deploy-docs.sh` - Built the Hugo site
2. `deploy-gh-pages.sh` - Attempted manual deployment with branch switching
3. `deploy-to-github-pages.sh` - Used a local GitHub token to authenticate and deploy

### Prerequisites (Historical)

This approach required:
- A GitHub Personal Access Token with specific permissions
- Token stored in a local secrets file
- Manual branch management and switching
- Local Hugo installation

### Process Overview (Historical)

The previous deployment workflow involved:
1. Building the site locally
2. Manually switching to the gh-pages branch
3. Copying built files to the correct location
4. Committing and pushing with personal access token
5. Switching back to the main branch

## Issues That Led to Replacement

This approach was ultimately replaced because:

1. **Branch Switching Problems**: Developers would often get "stuck" in the gh-pages branch
2. **Path Resolution Issues**: Scripts couldn't reliably locate directories after branch switching
3. **Security Concerns**: Required managing personal access tokens locally
4. **Inconsistent Environment**: Results varied depending on local environment differences
5. **Manual Process**: Required manual intervention and could not be scheduled or triggered by events

## Transition to GitHub Actions

In March 2025, the project migrated to GitHub Actions for deployment, as documented in:
- [GITHUB-PAGES-DEPLOYMENT-SUMMARY.md](/GITHUB-PAGES-DEPLOYMENT-SUMMARY.md)
- [GitHub Actions Deployment Guide](/content/project/github-actions-deployment-guide.md)

The GitHub Actions approach resolved all the issues with the prior method by:
- Eliminating branch switching
- Using a consistent build environment
- Leveraging GitHub's built-in authentication
- Automating the entire process
- Providing clear logs and status updates

## Historical Scripts Reference

The original scripts remain in the repository root for historical reference only:
- `deploy-docs.sh`
- `deploy-gh-pages.sh`
- `deploy-to-github-pages.sh`

These scripts should not be used for current deployments.

## Archival Notes

This documentation was archived on March 24, 2025, by the Documentation Architect as part of the documentation maintenance process. The information is preserved to maintain historical context about project evolution.