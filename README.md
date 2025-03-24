# MCP Documentation Project

This repository contains the documentation for the Multi-agent Control Platform (MCP) project.

## Quick Start

### Deploying Documentation

✨ **NEW: GitHub Actions Automated Deployment** ✨

The documentation now deploys **automatically** whenever changes are pushed to the main branch using GitHub Actions!

```bash
# Simply make your changes, then commit and push
git add .
git commit -m "Update documentation"
git push

# The site will automatically deploy - no additional commands needed
```

You can view deployment progress in the GitHub Actions tab of the repository.

### Testing Locally

To test the site locally before pushing changes:

```bash
# Build site locally without deploying
hugo server

# Or use the legacy build script
./deploy-docs.sh --build-only
```

## Development Workflow

1. Make all content changes on the `main` branch
2. Test locally with `hugo server` if needed
3. Commit and push to `main` - GitHub Actions will deploy automatically
4. View the deployed site at your GitHub Pages URL

## Deployment Architecture

This project uses a modern GitHub Actions workflow for deployment:

- **`main` branch**: Contains all source code, content, and configuration
- **GitHub Actions**: Automatically builds and deploys the site
- **GitHub Pages**: Hosts the generated static site

**Important**: Never manually manipulate the deployment - all deployment is handled automatically by GitHub Actions.

## Documentation Structure

- `content/`: Main content directory with all documentation source files
- `.github/workflows/`: GitHub Actions workflow configuration
- `architecture/`: Architecture documentation
- `docs/`: Project documentation and guides

## Deployment Resources

- [GitHub Actions Deployment Guide](content/project/github-actions-deployment-guide.md)
- [Deployment Verification Checklist](content/project/github-actions-deployment-checklist.md)
- [Troubleshooting Guide](content/project/github-actions-troubleshooting.md)
- [GitHub Pages Deployment Solution](content/project/github-pages-deployment-solution.md)

## Need Help?

If you encounter issues with the documentation or deployment process:
1. Check the [Troubleshooting Guide](content/project/github-actions-troubleshooting.md)
2. Look at the GitHub Actions logs in the repository's Actions tab
3. Open an issue if problems persist
