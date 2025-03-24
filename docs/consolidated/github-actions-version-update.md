# GitHub Actions Version Update

## Overview

This document outlines the updates made to the GitHub Actions workflow configuration to address version compatibility issues. The changes ensure that all GitHub Actions components are using compatible versions, fixing the workflow failure related to `actions/upload-artifact@v3`.

## Changes Made

The `.github/workflows/hugo-deploy.yml` file has been updated with the following version changes:

1. **GitHub Action Versions Updated**:
   - `actions/checkout@v3` → `actions/checkout@v4`
   - `actions/configure-pages@v3` → `actions/configure-pages@v4`
   - `actions/upload-pages-artifact@v2` → `actions/upload-pages-artifact@v3`
   - `actions/deploy-pages@v2` → `actions/deploy-pages@v4`

2. **Reason for Updates**:
   - The workflow was encountering an error: `Error: Missing download info for actions/upload-artifact@v3`
   - This indicated a version compatibility issue between the GitHub Actions components
   - All components are now using the latest compatible versions

## Compatibility Table

| Component                   | Old Version | New Version | Notes                          |
|-----------------------------|-------------|-------------|--------------------------------|
| actions/checkout            | v3          | v4          | Latest stable version          |
| actions/configure-pages     | v3          | v4          | Latest version                 |
| actions/upload-pages-artifact | v2        | v3          | Compatible with upload-artifact@v3 |
| actions/deploy-pages        | v2          | v4          | Latest version                 |

## Workflow File Comparison

### Original Workflow (Before Changes)

```yaml
name: Deploy Hugo site to GitHub Pages

on:
  # Runs on pushes to the main branch
  push:
    branches:
      - main  # Set to your default branch if different (e.g., master)
  
  # Allows manual triggering from the Actions tab
  workflow_dispatch:

# Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
permissions:
  contents: read
  pages: write
  id-token: write

# Allow only one concurrent deployment
concurrency:
  group: "pages"
  cancel-in-progress: true

# Default to bash
defaults:
  run:
    shell: bash

jobs:
  # Build job
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.111.3  # Set to a specific Hugo version for consistency
    steps:
      - name: Install Hugo CLI
        run: |
          wget -O ${{ runner.temp }}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb
          sudo dpkg -i ${{ runner.temp }}/hugo.deb

      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v3

      - name: Build with Hugo
        run: |
          hugo \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/"
        
      - name: Create .nojekyll file
        run: touch public/.nojekyll
          
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: ./public

  # Deployment job
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```

### Updated Workflow (After Changes)

```yaml
name: Deploy Hugo site to GitHub Pages

on:
  # Runs on pushes to the main branch
  push:
    branches:
      - main  # Set to your default branch if different (e.g., master)
  
  # Allows manual triggering from the Actions tab
  workflow_dispatch:

# Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
permissions:
  contents: read
  pages: write
  id-token: write

# Allow only one concurrent deployment
concurrency:
  group: "pages"
  cancel-in-progress: true

# Default to bash
defaults:
  run:
    shell: bash

jobs:
  # Build job
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.111.3  # Set to a specific Hugo version for consistency
    steps:
      - name: Install Hugo CLI
        run: |
          wget -O ${{ runner.temp }}/hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb
          sudo dpkg -i ${{ runner.temp }}/hugo.deb

      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v4

      - name: Build with Hugo
        run: |
          hugo \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/"
        
      - name: Create .nojekyll file
        run: touch public/.nojekyll
          
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  # Deployment job
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

## Troubleshooting GitHub Actions Version Issues

If you encounter similar version compatibility issues in the future, follow these steps:

1. **Identify the Error Message**:
   - Look for specific errors in the GitHub Actions workflow logs
   - Pay attention to missing dependencies or version conflicts

2. **Check GitHub Actions Changelog**:
   - Review the changelog for each action to understand version compatibility
   - GitHub Actions documentation: https://github.com/actions

3. **Update All Related Actions Together**:
   - Actions often have interdependencies
   - Update related actions as a group to maintain compatibility

4. **Test the Workflow**:
   - After updating, trigger a workflow run to verify the fix
   - Check all job steps complete successfully

## Conclusion

By updating the GitHub Actions component versions, we've resolved the compatibility issue that was preventing successful deployment. All components are now using current, compatible versions, ensuring reliable documentation deployment.

The updated workflow should now run successfully, building and deploying the Hugo site to GitHub Pages without the previously encountered errors.