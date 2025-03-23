# GitHub Actions Workflow for Hugo Deployment

This document provides the GitHub Actions workflow configuration for automatic building and deploying the Hugo static site to GitHub Pages.

## Workflow Configuration

Create a file in your repository at `.github/workflows/hugo-deploy.yml` with the following content:

```yaml
name: Deploy Hugo Site to GitHub Pages

on:
  push:
    branches:
      - main  # Set this to your default branch
  workflow_dispatch:  # Allow manual triggering

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
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
        with:
          submodules: recursive
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.110.0'
          extended: true

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v3

      - name: Build with Hugo
        env:
          # For maximum backward compatibility with Hugo modules
          HUGO_ENVIRONMENT: production
          HUGO_ENV: production
        run: |
          hugo \
            --minify \
            --baseURL "${{ steps.pages.outputs.base_url }}/"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          path: ./public

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

## Workflow Explanation

This workflow consists of two jobs:

1. **Build**: Sets up Hugo and builds the static site
2. **Deploy**: Deploys the built site to GitHub Pages

### Key Components:

- **Triggers**: The workflow is triggered on pushes to the main branch or can be manually triggered.
- **Hugo Setup**: Uses the `peaceiris/actions-hugo@v2` action to install Hugo with the extended version (required for SCSS processing).
- **Build Process**: Builds the site with minification and sets the base URL dynamically.
- **Artifact Upload**: Uploads the built site as a GitHub Pages artifact.
- **Deployment**: Uses GitHub's deploy-pages action to publish the site to GitHub Pages.

## Setup Instructions

1. Create the `.github/workflows` directory in your repository if it doesn't exist:

   ```bash
   mkdir -p .github/workflows
   ```

2. Create the workflow file:

   ```bash
   touch .github/workflows/hugo-deploy.yml
   ```

3. Copy the workflow configuration above into the file.

4. Commit and push the workflow file to your repository:

   ```bash
   git add .github/workflows/hugo-deploy.yml
   git commit -m "Add GitHub Actions workflow for Hugo deployment"
   git push
   ```

## GitHub Pages Configuration

Before the workflow can successfully deploy your site, you need to configure GitHub Pages in your repository settings:

1. Go to your repository on GitHub.
2. Navigate to Settings > Pages.
3. Under "Source", select "GitHub Actions".

## Custom Domain Configuration (Optional)

If you want to use a custom domain:

1. Create a file named `CNAME` in the `static/` directory of your Hugo project:

   ```
   example.com
   ```

2. Configure your domain's DNS settings:
   - For an apex domain: Add an A record pointing to GitHub Pages IP addresses
   - For a subdomain: Add a CNAME record pointing to your GitHub Pages URL

3. In your repository settings:
   - Go to Settings > Pages
   - Enter your custom domain
   - Check "Enforce HTTPS" (recommended)

## Workflow Customization

You may need to customize the workflow for specific requirements:

### Using a Different Hugo Version

Update the hugo-version parameter in the Setup Hugo step:

```yaml
- name: Setup Hugo
  uses: peaceiris/actions-hugo@v2
  with:
    hugo-version: '0.120.0'  # Use a specific version
    extended: true
```

### Building from a Different Branch

Change the trigger branch in the `on.push.branches` section:

```yaml
on:
  push:
    branches:
      - development  # Change from main to your branch
```

### Building from a Subdirectory

If your Hugo project is in a subdirectory, add a working-directory parameter:

```yaml
- name: Build with Hugo
  env:
    HUGO_ENVIRONMENT: production
    HUGO_ENV: production
  working-directory: ./docs-site  # Specify the subdirectory
  run: |
    hugo \
      --minify \
      --baseURL "${{ steps.pages.outputs.base_url }}/"
```

## Troubleshooting

If the deployment fails, check the following:

1. **Hugo Version**: Ensure the Hugo version in the workflow is compatible with your theme.
2. **Missing Dependencies**: Some themes require additional dependencies. Add installation steps if needed.
3. **Submodules**: If using submodules for themes, ensure they're properly checked out.
4. **Repository Permissions**: Verify the workflow has the necessary permissions in the repository settings.

For detailed logs and debugging information, check the workflow run in the Actions tab of your repository.