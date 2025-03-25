# MCP Documentation Deployment

🔴 **OUTDATED** - This document contains outdated deployment instructions. Please refer to [GitHub Pages Deployment Solution](/content/project/github-pages-deployment-solution.md) for the current official deployment process.

## Historical Context

This document describes previous deployment methods that have been replaced by GitHub Actions. The information below is preserved for historical reference only and **should not be used** for current deployments.

---

This document explains the two deployment options for the MCP documentation site to GitHub Pages.

## Option 1: Local Deployment Script (NO LONGER RECOMMENDED)

This repository previously used a local deployment script that sources a GitHub Personal Access Token (PAT) from a local secrets file.

### Prerequisites

1. Ensure you have a GitHub PAT with these permissions:
   - Contents (read/write) - For pushing to the gh-pages branch
   - Pages (read/write) - For GitHub Pages configuration
   - Metadata (read) - For basic repository access

2. Store your token in the local secrets file:
   ```
   /home/verlyn13/.secrets/mcp-scope/github_token
   ```

   The file should contain:
   ```bash
   export GH_PAT="your_personal_access_token_here"
   ```

### Deployment Steps

1. Make your changes to the documentation content
2. Commit your changes to the main branch
3. Run the local deployment script:
   ```bash
   ./deploy-to-github-pages.sh
   ```

This script will:
- Source your GitHub token from the local secrets file
- Build the Hugo site using the existing deploy-docs.sh script
- Switch to the gh-pages branch (or create it if it doesn't exist)
- Replace the contents with the new build
- Commit and push the changes using your GitHub token
- Switch back to the main branch

## Option 2: GitHub Actions Workflow (NOW THE OFFICIAL METHOD)

GitHub Actions is now the official and only supported deployment method. For current instructions, please see [GitHub Pages Deployment Solution](/content/project/github-pages-deployment-solution.md).

### Prerequisites

1. Uncomment the trigger section in `.github/workflows/hugo-deploy.yml`
2. Ensure GitHub Actions has proper permissions in your repository settings:
   - Go to Settings → Actions → General
   - Under "Workflow permissions" select "Read and write permissions"

### Deployment Steps

With GitHub Actions configured:
1. Make your changes to the documentation content
2. Commit and push your changes to the main branch
3. GitHub Actions will automatically build and deploy the site

You can also manually trigger the workflow from the Actions tab in your GitHub repository.

## Troubleshooting

### Permission Issues

If you encounter permission issues with GitHub Actions:
- Check that the workflow has proper permissions
- Confirm that branch protection rules allow GitHub Actions to push
- Consider using the local deployment script instead

### Missing Content

If some content is missing from the deployed site:
- Verify that the content copying script includes all your source directories
- Check for any errors in the Hugo build process
- Ensure the baseURL in config.toml is set correctly

## Verifying Deployment

After deployment, verify your site at:
```
https://verlyn13.github.io/mcp-scope/
```

Check that:
- The home page loads correctly
- Navigation between sections works
- All shortcodes render properly