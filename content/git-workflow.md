# MCP Documentation Git Workflow

This document explains the current Git workflow for the MCP Documentation system, including branch management and the GitHub Actions deployment process.

## Branch Structure

The documentation system uses the following branch structure:

- **main**: Development branch where all content and code changes are made.
- **gh-pages**: Deployment branch that contains the generated static site for GitHub Pages (managed automatically by GitHub Actions).

## Workflow Overview

1. All development work happens on the `main` branch.
2. GitHub Actions automatically builds and deploys the site to GitHub Pages when changes are pushed to `main`.
3. GitHub Pages serves the content deployed through GitHub Actions.

```
main branch: Content source files (Markdown, templates, scripts)
        |
        | (GitHub Actions triggered on push)
        ↓
GitHub Actions: Builds site with Hugo
        |
        | (Deploys to GitHub Pages)
        ↓
Public website
```

## Development Workflow

### 1. Regular Development Workflow

#### Option A: Test Before Committing (Recommended)

```bash
# Make sure you're on the main branch
git checkout main

# Make your changes to content, templates, etc.
# ...

# Test locally with live preview
./run-hugo.sh server

# When satisfied, commit your changes
git add .
git commit -m "Description of your changes"
git push origin main

# Deployment happens automatically through GitHub Actions
```

#### Option B: Build-Only Workflow (Faster)

```bash
# Make sure you're on the main branch
git checkout main

# Make your changes to content, templates, etc.
# ...

# Just verify the build works without preview
./run-hugo.sh build

# If build succeeds, commit your changes
git add .
git commit -m "Description of your changes"
git push origin main

# Deployment happens automatically through GitHub Actions
```

#### Option C: Direct Commit Workflow (Super Fast)

```bash
# Make sure you're on the main branch
git checkout main

# Make your changes to content, templates, etc.
# ...

# Commit and push directly without local testing
git add .
git commit -m "Description of your changes"
git push origin main

# Monitor the GitHub Actions workflow to ensure successful deployment
```

This approach is fastest but carries more risk - if your changes cause build failures, you'll need to make additional commits to fix them.

### 2. Monitoring Deployment

After pushing to the `main` branch:

1. Go to the "Actions" tab in the GitHub repository
2. Look for the "Deploy Hugo site to GitHub Pages" workflow
3. Monitor the progress of the deployment
4. Once complete, your changes will be live on the GitHub Pages site

### 3. Manual Deployment (if needed)

If you need to trigger a deployment manually without making changes:

1. Go to the "Actions" tab in the GitHub repository
2. Select "Deploy Hugo site to GitHub Pages" workflow
3. Click "Run workflow" button
4. Select the main branch and click "Run workflow"

## Handling Documentation Changes

When making significant documentation changes:

1. Test locally first using `./run-hugo.sh server`
2. Commit and push changes in smaller, logical batches
3. Verify each deployment completes successfully before making more changes
4. Check the live site to ensure content appears as expected

## Reverting Commits

If you accidentally commit files that shouldn't be tracked:

```bash
# View recent commits to find the commit to revert
git log --oneline -n 5

# Revert the most recent commit but keep changes staged
git reset --soft HEAD~1

# Or revert completely (discard changes)
git reset --hard HEAD~1

# If already pushed, you'll need to force push
# USE WITH CAUTION - only do this if you're sure no one else has pulled your changes
git push origin main --force
```

## Files That Should Not Be Committed

The following files/directories should not be committed to the `main` branch:

1. **Hugo build output**:
   - `/public/` directory
   - `/resources/_gen/` directory
   - `.hugo_build.lock`

2. **Generated template output**:
   - Any files with the pattern `*.generated.md`
   - `test-output.md`

3. **Python cache files**:
   - `__pycache__/` directories
   - `*.pyc` files

4. **Environment-specific files**:
   - `.env` files
   - `venv/` or any virtual environment directories

All these are already included in the `.gitignore` file.

## Best Practices

1. **Never commit directly to gh-pages**: The gh-pages branch is now managed entirely by GitHub Actions.

2. **Update .gitignore when needed**: If you find new types of files that shouldn't be committed, update `.gitignore`.

3. **Separate content from generated files**: All source files go in `main`, all generated files are handled automatically.

4. **Test locally before pushing**: Always test your changes with `./run-hugo.sh server` before pushing to GitHub.

5. **Commit frequently but mindfully**: Commit your changes to `main` frequently, but be aware that each push triggers a deployment.

6. **Monitor GitHub Actions**: Check the Actions tab to ensure your deployment completes successfully.

7. **Review the live site**: After deployment, verify your changes appear correctly on the public site.

## Troubleshooting

### Common Hugo Issues

If you encounter an error when running `./run-hugo.sh server`:

1. **Git executable not found error**:
   ```
   ERROR: Failed to read Git log: Git executable not found in $PATH
   ```
   
   Solution: Rebuild the Hugo container with:
   ```bash
   ./run-hugo.sh rebuild server
   ```
   
   This ensures the container has Git installed, which Hugo uses for last modified dates and other features.

2. **Other container issues**:
   If you encounter other issues with the Hugo container, you can:
   - Rebuild it with the above command
   - Check the Dockerfile.hugo file for any configuration issues
   - Ensure podman/docker is running correctly on your system

## Important Note on Deployment Scripts

⚠️ **IMPORTANT**: The older manual deployment scripts (`deploy-to-github-pages.sh`, `deploy-docs.sh`, etc.) are deprecated and should not be used. These remain in the repository for reference purposes only. Always use the GitHub Actions workflow for deployment.

For more details on the GitHub Actions deployment system, see:
- [GitHub Actions Deployment Guide](/project/github-actions-deployment-guide/)
- [GitHub Pages Deployment Solution](/project/github-pages-deployment-solution/)
- [Current Deployment Workflow](/project/current-deployment-workflow/)