# ScopeCam MCP Documentation - Hugo Static Site

This directory contains a Hugo-based static site for the ScopeCam MCP Documentation, designed to be deployed to GitHub Pages.

## About the Documentation Site

The documentation site preserves the current dual-layer structure of the ScopeCam MCP documentation:

1. **Root Documentation Layer** - Project-wide information and ScopeCam integration
2. **MCP Documentation Layer** - Detailed MCP implementation guides and technical information

The site includes features like:
- Status indicators for document status (Active, Draft, Review, etc.)
- Progress tracking for project components
- Dual-layer navigation between Root and MCP documentation
- Responsive design for mobile and desktop viewing

## Directory Structure

```
/                               # Root directory
├── config/                     # Hugo configuration
│   ├── _default/               # Base configuration
│   ├── development/            # Development environment settings
│   └── production/             # Production environment settings
├── content/                    # Content files (Markdown)
│   ├── project/                # Project documentation
│   ├── guides/                 # Implementation guides
│   ├── architecture/           # Architecture documentation
│   ├── standards/              # Standards documentation
│   ├── templates/              # Document templates
│   └── mcp/                    # MCP-specific documentation
├── themes/                     # Hugo themes
│   └── mcp-theme/              # Custom MCP theme
│       ├── layouts/            # HTML templates
│       ├── assets/             # SCSS and JS files
│       └── static/             # Static assets
├── Dockerfile.hugo             # Container definition for Hugo
├── run-hugo.sh                 # Script to run Hugo in container
└── .github/workflows/          # GitHub Actions workflows
    └── hugo-deploy.yml         # Deployment workflow for GitHub Pages
```

## Local Development

### Prerequisites

- Podman or Docker installed
- Git

### Running Locally

The `run-hugo.sh` script provides a convenient way to run Hugo in a containerized environment:

```bash
# Start the development server
./run-hugo.sh server

# Build the static site
./run-hugo.sh build

# Create new content
./run-hugo.sh new project/new-document.md
```

This script will:
1. Build the Hugo container if it doesn't exist
2. Mount the current directory to the container
3. Run the appropriate Hugo command

Alternatively, you can use the `podman-compose.yml` file:

```bash
# Start all services including the docs service
podman-compose up -d

# Start only the docs service
podman-compose up -d docs
```

### Creating New Content

To create new documentation:

1. Determine the appropriate section (project, guides, architecture, etc.)
2. Create a new file using the script:
   ```bash
   ./run-hugo.sh new SECTION/document-name.md
   ```
3. Edit the file, ensuring it has the proper front matter:
   ```yaml
   ---
   title: "Document Title"
   status: "Draft"  # Active, Draft, Review, Outdated, or Archived
   version: "0.1"
   date_created: "YYYY-MM-DD"
   last_updated: "YYYY-MM-DD"
   contributors: ["Your Name"]
   related_docs:
     - "/docs/path/to/related/document.md"
   tags: ["tag1", "tag2"]
   ---
   ```

## GitHub Pages Deployment

The site is automatically deployed to GitHub Pages when changes are pushed to the `main` branch, using the GitHub Actions workflow defined in `.github/workflows/hugo-deploy.yml`.

To manually trigger a deployment:
1. Go to the Actions tab in the GitHub repository
2. Select the "Deploy Hugo Site to GitHub Pages" workflow
3. Click "Run workflow"

## Customization

### Theme Customization

The custom MCP theme is located in `themes/mcp-theme/` and can be customized:
- Layout templates in `themes/mcp-theme/layouts/`
- Styles in `themes/mcp-theme/assets/scss/`
- JavaScript in `themes/mcp-theme/assets/js/`
- Static assets in `themes/mcp-theme/static/`

### Configuration

Hugo configuration is in the `config/` directory:
- Base configuration in `config/_default/config.toml`
- Development-specific settings in `config/development/config.toml`
- Production-specific settings in `config/production/config.toml`

## Migration Process

This site was created following the specifications in:
- [Hugo Migration Executive Summary](hugo-migration-executive-summary.md)
- [Hugo Migration File Mapping](hugo-migration-file-mapping.md)
- [Hugo Implementation Steps](hugo-implementation-steps-update.md)

For the complete documentation on the migration process, refer to these documents.