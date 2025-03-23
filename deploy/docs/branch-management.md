---
title: "Branch Management for Documentation Deployment"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/deploy/docs/deployment-guide/"
  - "/deploy/docs/system-integration/"
tags: ["git", "branching", "deployment", "documentation", "github-pages"]
---

# Branch Management for Documentation Deployment

{{< status >}}

This guide outlines the critical branch management practices for MCP documentation deployment to ensure safe and reliable operations.

## Table of Contents

{{< toc >}}

## Branch Structure Overview

The MCP documentation repository uses a two-branch strategy for content management and deployment:

1. **`main` branch**: Contains all source content, configurations, and deployment scripts
2. **`gh-pages` branch**: Contains only the compiled static site for GitHub Pages deployment

## Critical Safety Considerations

### ⚠️ IMPORTANT WARNINGS

1. **Never** directly edit content on the `gh-pages` branch
2. **Never** merge from `gh-pages` back to `main`
3. **Never** modify deployment scripts while on the `gh-pages` branch
4. **Always** verify the current branch before making changes

Failure to follow these guidelines can result in:
- Loss of source content
- Website deployment failures
- Repository corruption requiring manual intervention

## Safe Branch Operations

### Checking Current Branch

Always verify which branch you're on before performing any operations:

```bash
# Display current branch
git branch --show-current

# List all branches with current one highlighted
git branch
```

### Safe Branch Switching

When switching branches, ensure all changes are committed or stashed:

```bash
# Check for uncommitted changes
git status

# If clean, switch branches
git checkout main
# OR
git checkout gh-pages
```

### Deployment Process Safety

The unified deployment script (`deploy/unified-deploy.sh`) handles branch switching automatically with these safety mechanisms:

1. **Current branch detection**: Records which branch you started on
2. **Clean working directory check**: Verifies no uncommitted changes exist
3. **Safe return**: Always returns to the original branch after deployment
4. **Failure recovery**: Returns to original branch even if deployment fails
5. **Confirmation prompts**: Requires confirmation for destructive operations

## Branch Management in the Deployment Script

The `unified-deploy.sh` script implements these safety measures for branch management:

```bash
# Store current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $current_branch"

# Ensure clean working directory
if ! git diff-index --quiet HEAD --; then
  echo "⚠️ Error: Working directory not clean. Commit or stash changes before deployment."
  exit 1
fi

# Try to switch branch with error handling
if ! git checkout $TARGET_BRANCH; then
  echo "⚠️ Error: Failed to switch to $TARGET_BRANCH branch."
  echo "Returning to $current_branch branch."
  git checkout $current_branch
  exit 1
fi

# After operations, always return to original branch
echo "Returning to $current_branch branch."
git checkout $current_branch
```

## Common Branch Management Scenarios

### Scenario 1: Normal Documentation Update

1. Make changes on `main` branch
2. Test locally with `./deploy/unified-deploy.sh --mode local --skip-git`
3. Commit changes to `main`
4. Deploy to GitHub Pages with `./deploy/unified-deploy.sh`

### Scenario 2: Deployment Script Update

1. Make script changes on `main` branch
2. Test with `--dry-run` and `--skip-git` flags
3. Commit changes to `main`
4. Deploy with added caution and verification

### Scenario 3: Recovery from Branch Issues

If you accidentally make changes on the wrong branch:

1. **DO NOT COMMIT** the changes
2. Stash the changes: `git stash`
3. Switch to correct branch: `git checkout main`
4. Apply stashed changes: `git stash apply`
5. Verify changes are as expected

## GitHub Pages Deployment Flow

The proper flow for GitHub Pages deployment is:

1. **Content Creation**: All content is created and edited on the `main` branch
2. **Local Testing**: Test the site locally on the `main` branch
3. **Deployment Execution**: Run the deployment script from the `main` branch
4. **Automatic Branch Handling**: The script will:
   - Switch to `gh-pages` branch
   - Update content with new compiled site
   - Commit and push changes
   - Return to the `main` branch

## Monitoring Branches

To maintain branch health, regularly:

1. **Check branch status**:
   ```bash
   git branch -v
   ```

2. **Verify remote branch status**:
   ```bash
   git remote show origin
   ```

3. **Ensure branches are in sync**:
   ```bash
   git fetch --all
   git status
   ```

## Related Documentation

{{< related-docs >}}