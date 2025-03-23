# Hugo Configuration Setup

This document provides the initial Hugo configuration for the ScopeCam MCP documentation site. It includes the basic `config.toml` file and instructions for customizing it for your deployment.

## Base Configuration File

Create a file named `config.toml` in the root of your Hugo project with the following content:

```toml
# ScopeCam MCP Documentation Hugo Configuration

baseURL = "https://example.github.io/mcp-scope/"
languageCode = "en-us"
title = "ScopeCam MCP Documentation"
theme = "mcp-theme"
enableGitInfo = true
enableEmoji = true

# Enable robots.txt generation
enableRobotsTXT = true

# Syntax highlighting configuration
[markup.highlight]
  codeFences = true
  guessSyntax = true
  lineNos = true
  lineNumbersInTable = true
  tabWidth = 2

# Configure Markdown renderer
[markup.goldmark.renderer]
  unsafe = true # Allows HTML in Markdown

# Set permalinks structure
[permalinks]
  project = "/project/:filename/"
  guides = "/guides/:filename/"
  architecture = "/architecture/:filename/"
  standards = "/standards/:filename/"
  templates = "/templates/:filename/"
  mcp = "/mcp/:sections/:filename/"

# Define taxonomies
[taxonomies]
  tag = "tags"
  status = "status" 
  contributor = "contributors"

# Menu configuration
[menu]
  [[menu.main]]
    name = "Home"
    url = "/"
    weight = 10
  
  [[menu.main]]
    name = "Project"
    url = "/project/"
    weight = 20

  [[menu.main]]
    name = "Architecture"
    url = "/architecture/"
    weight = 30

  [[menu.main]]
    name = "Guides"
    url = "/guides/"
    weight = 40

  [[menu.main]]
    name = "Standards"
    url = "/standards/"
    weight = 50

  [[menu.main]]
    name = "MCP"
    url = "/mcp/"
    weight = 60

# Parameters for theme and site functionality
[params]
  description = "Documentation for the ScopeCam Multi-Agent Control Platform"
  author = "ScopeCam Team"
  github_repo = "https://github.com/example/mcp-scope"
  github_branch = "main"
  
  # Status settings
  [params.status]
    active = "🟢 Active"
    draft = "🟡 Draft"
    review = "🟠 Review"
    outdated = "🔴 Outdated"
    archived = "⚫ Archived"
  
  # Layer configuration
  [params.layers]
    [params.layers.root]
      name = "Root Documentation"
      description = "Project-wide information and ScopeCam integration"
    
    [params.layers.mcp]
      name = "MCP Documentation"
      description = "Detailed implementation guides and technical information"
```

## Custom Parameters Explanation

### Status System

The configuration uses a custom parameter section `[params.status]` to define the display format for each status. This will be used by the theme templates to render status indicators consistently.

### Documentation Layers

The configuration defines the dual-layer structure using `[params.layers]` with separate sections for the root documentation layer and the MCP-specific layer. This enables the theme to provide layer-specific navigation and styling.

### Taxonomies

The configuration sets up three taxonomies:
- `tags` - For categorizing content by topic
- `status` - For tracking document status
- `contributors` - For identifying document authors

These taxonomies will generate automatic listing pages and can be used for filtering content.

## GitHub Pages Configuration

When deploying to GitHub Pages from the `gh-pages` branch, make the following adjustments:

1. Update the `baseURL` to match your GitHub Pages URL
2. Set the correct repository and branch in `github_repo` and `github_branch`
3. If using a custom domain:
   - Add your domain to `baseURL`
   - Create a `static/CNAME` file with your domain

## Additional Configuration Options

### Language Settings

For multilingual support, add:

```toml
[languages]
  [languages.en]
    languageName = "English"
    weight = 1
  [languages.es]
    languageName = "Español"
    weight = 2
```

### Sitemap Configuration

For advanced sitemap settings:

```toml
[sitemap]
  changefreq = "weekly"
  priority = 0.5
  filename = "sitemap.xml"
```

### Output Formats

To generate additional output formats:

```toml
[outputs]
  home = ["HTML", "RSS", "JSON"]
  page = ["HTML"]
```

The JSON output is useful for implementing search functionality.

## Theme Customization

The MCP theme will need to be developed or adapted from an existing theme. Key components to implement:

1. Status styling and indicators
2. Layer navigation system
3. Progress bar visualization
4. Taxonomy displays
5. Search integration

## Implementation Instructions

1. Create a `config.toml` file in the Hugo project root directory
2. Copy the base configuration provided above
3. Adjust parameters based on your specific deployment needs
4. Test the configuration locally with `hugo server`
5. Deploy to GitHub Pages using the CI/CD workflow