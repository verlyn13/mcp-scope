# MCP Documentation Deployment Scripts

This directory contains scripts for deploying the MCP documentation to GitHub Pages while maintaining proper branch management.

## Standard Branch Strategy

The MCP documentation project follows the standard GitHub Pages branch strategy:

- **`main` branch**: Contains all source code, project files, and version history
- **`gh-pages` branch**: Contains only the built static site for hosting

## Available Scripts

### Standard GitHub Pages Deployment

`standard-gh-pages-deploy.sh` - Implements the standard workflow:
- Always deploys from `main` branch to `gh-pages` branch
- Enforces that you start from the `main` branch
- Automatically returns to `main` branch after deployment
- Includes safety checks for working directory cleanliness
- Simple and focused on the most common deployment scenario

Usage:
```bash
# First build the site
./deploy/unified-deploy.sh --mode local --skip-git

# Then deploy to GitHub Pages
./deploy/scripts/standard-gh-pages-deploy.sh
```

### Safe Branch Management

`safe-gh-pages-deploy.sh` - Enhanced deployment with more safety features:
- More extensive validation and safety checks
- Includes dry-run mode for testing
- Provides detailed logging of branch operations
- Handles edge cases and recovery scenarios
- More verbose output for troubleshooting

Usage:
```bash
# Deploy with enhanced safety features
./deploy/scripts/safe-gh-pages-deploy.sh

# Test deployment without making changes
./deploy/scripts/safe-gh-pages-deploy.sh --dry-run
```

### Branch Safety Library

`branch-safety.sh` - Core functions used by other scripts:
- Not meant to be run directly
- Provides common safety functions for branch operations
- Can be sourced by other scripts to add branch safety

## Recommended Workflow

1. **Do all development on `main` branch**:
   ```bash
   git checkout main
   # Make changes to content, scripts, etc.
   ```

2. **Build the site locally for testing**:
   ```bash
   ./deploy/unified-deploy.sh --mode local --skip-git
   ```

3. **Commit changes to `main` branch**:
   ```bash
   git add .
   git commit -m "Update documentation content"
   git push origin main
   ```

4. **Deploy to GitHub Pages**:
   ```bash
   # Standard deployment (recommended for most cases)
   ./deploy/scripts/standard-gh-pages-deploy.sh
   
   # OR with enhanced safety features
   ./deploy/scripts/safe-gh-pages-deploy.sh
   ```

5. **Verify the deployment**:
   - Check your GitHub Pages URL
   - Verify you're back on the `main` branch

## Important Rules

1. **Never develop directly on the `gh-pages` branch**
2. **Never manually edit files on the `gh-pages` branch**
3. **Always start deployment from the `main` branch**
4. **Always build the site before deploying**

Remember: The `gh-pages` branch is for hosting only, not for development.