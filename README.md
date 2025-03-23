# MCP Documentation Project

This repository contains the documentation for the Multi-agent Control Platform (MCP) project.

## Quick Start

### Deploying Documentation

Use the simple command to build and deploy documentation to GitHub Pages:

```bash
./deploy-docs.sh
```

This will:
1. Build the documentation site
2. Deploy to GitHub Pages (gh-pages branch)
3. Return you to the main branch

### Options

```bash
# Build site without deploying
./deploy-docs.sh --build-only

# Deploy existing build without rebuilding
./deploy-docs.sh --deploy-only

# Test deployment without making changes
./deploy-docs.sh --dry-run

# Show all options
./deploy-docs.sh --help
```

## Development Workflow

1. Make all content changes on the `main` branch
2. Build and test locally with `./deploy-docs.sh --build-only`
3. Deploy to GitHub Pages with `./deploy-docs.sh`
4. View the deployed site at your GitHub Pages URL

## Branch Strategy

This project follows the standard GitHub Pages branch strategy:

- **`main` branch**: Contains all source code, content, and configuration
- **`gh-pages` branch**: Contains only the built site for hosting

**Important**: Never directly edit content on the `gh-pages` branch. All development should happen on `main`.

## Documentation Structure

- `content/`: Main content directory with all documentation source files
- `deploy/`: Deployment scripts and configuration
- `architecture/`: Architecture documentation
- `docs/`: Project documentation and guides

## Additional Resources

- [Branch Management Guide](deploy/docs/branch-management.md)
- [GitHub Pages Guide](deploy/docs/github-pages-guide.md)
- [Deployment Scripts README](deploy/scripts/README.md)

## Need Help?

If you encounter any issues with the documentation or deployment process, consult the troubleshooting guide in the documentation or open an issue.
