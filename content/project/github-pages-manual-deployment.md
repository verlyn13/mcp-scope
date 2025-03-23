---
title: "GitHub Pages Manual Deployment Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/project/hugo-github-pages-deployment-guide/"
  - "/standards/hugo-deployment-standards/"
tags: ["deployment", "github-pages", "hugo", "permissions"]
---

# GitHub Pages Manual Deployment Guide

{{< status >}}

This guide provides instructions for manually deploying the MCP documentation to GitHub Pages when automated deployments encounter permission issues.

## Permission Issues with GitHub Actions

The automatic deployment using GitHub Actions may fail with permission errors like:

```
remote: Permission to repository.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/username/repository.git/': The requested URL returned error: 403
```

This occurs when GitHub Actions doesn't have sufficient permissions to push to the gh-pages branch. Below are several approaches to resolve this issue.

## Manual Deployment Process

### Option 1: Direct Deployment from Local Machine

1. **Clone the repository**:
   ```bash
   git clone https://github.com/verlyn13/mcp-scope.git
   cd mcp-scope
   ```

2. **Build the site locally**:
   ```bash
   ./deploy-docs.sh --build-only
   ```

3. **Create and switch to the gh-pages branch**:
   ```bash
   git checkout -b gh-pages
   ```
   
   If the branch already exists:
   ```bash
   git checkout gh-pages
   ```

4. **Remove existing files** (except .git):
   ```bash
   git rm -rf .
   git clean -fxd
   ```

5. **Copy the built files**:
   ```bash
   cp -r public/* .
   touch .nojekyll
   ```

6. **Commit and push the changes**:
   ```bash
   git add .
   git commit -m "Update documentation"
   git push -f origin gh-pages
   ```

7. **Switch back to the main branch**:
   ```bash
   git checkout main
   ```

### Option 2: Using a Personal Access Token

If you need to use GitHub Actions for deployment, you can set up a Personal Access Token (PAT):

1. **Create a Personal Access Token**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Create a new token with `repo` scope
   - Copy the token

2. **Add the token to repository secrets**:
   - Go to your repository → Settings → Secrets and variables → Actions
   - Create a new repository secret named `GH_PAT` with your token as the value

3. **Update the GitHub Actions workflow** to use your PAT:
   ```yaml
   - name: Deploy
     uses: peaceiris/actions-gh-pages@v3
     with:
       personal_token: ${{ secrets.GH_PAT }}
       publish_dir: ./public
   ```

### Option 3: Configure Repository Permissions

1. **Update repository settings**:
   - Go to your repository → Settings → Actions → General
   - In the "Workflow permissions" section, select "Read and write permissions"
   - Save changes

2. **Update branch protection rules** (if applicable):
   - Go to your repository → Settings → Branches → Branch protection rules
   - Edit the rules for the gh-pages branch to allow GitHub Actions to push

## Verifying Deployment

After deploying:

1. Visit `https://verlyn13.github.io/mcp-scope/` in your browser
2. Check that all content loads correctly
3. Verify navigation and shortcodes work as expected
4. Inspect the console for any 404 errors related to assets

## Troubleshooting Common Issues

### 1. Asset URL Issues

If assets (CSS, JS, images) are not loading properly:

- **Check the baseURL in config.toml**:
  ```toml
  baseURL = "https://verlyn13.github.io/mcp-scope/"
  ```

- **Verify that asset paths are relative** or use the baseURL variable:
  ```html
  <link rel="stylesheet" href="{{ .Site.BaseURL }}css/main.css">
  ```

### 2. .nojekyll File Missing

If GitHub is trying to process your site with Jekyll:

- Ensure a `.nojekyll` file exists in the root of the gh-pages branch
- Add it manually if needed:
  ```bash
  touch .nojekyll
  git add .nojekyll
  git commit -m "Add .nojekyll file"
  git push
  ```

### 3. Commit History Conflicts

If you encounter conflicts due to divergent history:

- Use force push with caution:
  ```bash
  git push -f origin gh-pages
  ```

- Consider creating a fresh gh-pages branch:
  ```bash
  git checkout --orphan gh-pages
  git rm -rf .
  ```

## Recommended Workflow for Frequent Updates

For teams making frequent documentation updates:

1. **Maintain clear separation** between content (main branch) and built site (gh-pages branch)
2. **Use a dedicated build script** that handles the branch switching and copying
3. **Document the deployment process** clearly for all team members
4. **Consider setting up automation** with proper permissions once the manual process is stable

## Conclusion

While automated deployments via GitHub Actions are convenient, manual deployments provide greater control and are more reliable when facing permission issues. By following this guide, you can ensure your documentation remains accessible on GitHub Pages even when automated systems encounter obstacles.

## Related Documentation

{{< related-docs >}}