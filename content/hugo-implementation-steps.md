# Hugo Migration Implementation Steps

This document provides a step-by-step guide for implementing the ScopeCam MCP documentation migration to Hugo. Follow these instructions to create the Hugo static site structure, migrate content, and deploy to GitHub Pages.

## Phase 1: Project Setup

### 1.1 Create the Hugo Project

```bash
# Install Hugo
# For Linux:
sudo apt install hugo

# For macOS:
brew install hugo

# Create a new Hugo site
hugo new site mcp-docs
cd mcp-docs

# Initialize Git repository (if not already in one)
git init
```

### 1.2 Configure Theme

You have two options:

#### Option A: Use an existing theme and customize it

```bash
# Add a theme as a git submodule
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke

# Or another documentation-focused theme like Docsy
git submodule add https://github.com/google/docsy.git themes/docsy

# Update the config.toml to use the theme
echo 'theme = "docsy"' >> config.toml
```

#### Option B: Create a custom theme (recommended for specialized needs)

```bash
# Create a new theme
hugo new theme mcp-theme

# Update the config.toml to use the theme
echo 'theme = "mcp-theme"' >> config.toml
```

### 1.3 Configure Hugo

Create the configuration file based on the `hugo-config-setup.md` document:

```bash
# Remove the default config.toml
rm config.toml

# Create the new config.toml with the provided content
# Copy content from hugo-config-setup.md
```

### 1.4 Set Up Directory Structure

Create the necessary directories for content organization:

```bash
# Create content directories
mkdir -p content/{project,guides,architecture,standards,templates,tools,mcp}

# Create subdirectories for MCP content
mkdir -p content/mcp/{docs,architecture,implementation,project}

# Create directories for assets and static files
mkdir -p static/images
mkdir -p assets/{scss,js}
mkdir -p layouts/{shortcodes,partials}
```

## Phase 2: Content Migration

### 2.1 Create Migration Script

Create a Python script to automate part of the migration process:

```python
#!/usr/bin/env python3
# migrate_content.py

import os
import re
import shutil
import yaml

# Define source and destination paths
source_root = "/home/verlyn13/Projects/mcp-scope"
hugo_root = "./mcp-docs"

# Load path mapping from the file mapping document
# This would parse the hugo-migration-file-mapping.md file
# and create a dictionary of current paths to Hugo paths

# Process each file
# 1. Read the source file
# 2. Update front matter if needed
# 3. Convert README.md to _index.md
# 4. Update internal links
# 5. Write to destination
```

### 2.2 Content Migration Process

Follow this process for each content section:

1. **Root Content**:
   ```bash
   # Convert main README.md to homepage
   python migrate_content.py --file "/README.md" --dest "content/_index.md"
   ```

2. **Project Documentation**:
   ```bash
   # Migrate project documentation
   python migrate_content.py --dir "/docs/project" --dest "content/project"
   ```

3. **Guides Documentation**:
   ```bash
   # Migrate guides documentation
   python migrate_content.py --dir "/docs/guides" --dest "content/guides"
   ```

4. **Architecture Documentation**:
   ```bash
   # Migrate architecture documentation
   python migrate_content.py --dir "/docs/architecture" --dest "content/architecture"
   python migrate_content.py --dir "/architecture" --dest "content/architecture"
   ```

5. **Standards Documentation**:
   ```bash
   # Migrate standards documentation
   python migrate_content.py --dir "/docs/standards" --dest "content/standards"
   ```

6. **Templates**:
   ```bash
   # Migrate templates
   python migrate_content.py --dir "/docs/templates" --dest "content/templates"
   ```

7. **MCP-specific Documentation**:
   ```bash
   # Migrate MCP documentation
   python migrate_content.py --dir "/mcp-project/docs" --dest "content/mcp"
   ```

### 2.3 Manual Content Updates

After automated migration, perform these manual checks:

1. Fix any broken internal links
2. Verify front matter is correctly formatted
3. Check that images are properly referenced
4. Ensure all `related_docs` references are updated
5. Convert any HTML-specific formatting to Hugo-compatible formats

## Phase 3: Theme Customization

### 3.1 Style Customization

Create or modify the theme's styles to match the current documentation:

```bash
# If using a custom theme
touch assets/scss/main.scss

# Add styles for the status system
cat > assets/scss/_status.scss << EOF
.status {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  font-weight: bold;
}

.status-active {
  background-color: #d4edda;
  color: #155724;
}

.status-draft {
  background-color: #fff3cd;
  color: #856404;
}

.status-review {
  background-color: #ffe5d0;
  color: #ff8000;
}

.status-outdated {
  background-color: #f8d7da;
  color: #721c24;
}

.status-archived {
  background-color: #e2e3e5;
  color: #383d41;
}
EOF

# Import status styles in main.scss
echo '@import "status";' >> assets/scss/main.scss
```

### 3.2 Create Shortcodes

Create custom shortcodes for special formatting:

```bash
# Create status shortcode
cat > layouts/shortcodes/status.html << EOF
{{ \$status := .Get 0 | default (.Page.Params.status) }}
{{ if eq \$status "Active" }}
  <span class="status status-active">🟢 Active</span>
{{ else if eq \$status "Draft" }}
  <span class="status status-draft">🟡 Draft</span>
{{ else if eq \$status "Review" }}
  <span class="status status-review">🟠 Review</span>
{{ else if eq \$status "Outdated" }}
  <span class="status status-outdated">🔴 Outdated</span>
{{ else if eq \$status "Archived" }}
  <span class="status status-archived">⚫ Archived</span>
{{ end }}
EOF

# Create progress bar shortcode
cat > layouts/shortcodes/progress.html << EOF
{{ \$value := .Get "value" | default 0 }}
<div class="progress">
  <div class="progress-bar" role="progressbar" style="width: {{ \$value }}%;" aria-valuenow="{{ \$value }}" aria-valuemin="0" aria-valuemax="100">{{ \$value }}%</div>
</div>
EOF

# Create related-docs shortcode
cat > layouts/shortcodes/related-docs.html << EOF
{{ if .Page.Params.related_docs }}
<div class="related-docs">
  <h3>Related Documents</h3>
  <ul>
    {{ range .Page.Params.related_docs }}
      {{ \$relPath := . }}
      {{ \$relPage := site.GetPage \$relPath }}
      {{ if \$relPage }}
        <li><a href="{{ \$relPage.RelPermalink }}">{{ \$relPage.Title }}</a></li>
      {{ else }}
        <li>{{ \$relPath }} (not found)</li>
      {{ end }}
    {{ end }}
  </ul>
</div>
{{ end }}
EOF
```

### 3.3 Create Custom Layouts

Create custom layouts for special pages:

```bash
# Create home page layout
cat > layouts/index.html << EOF
{{ define "main" }}
  <div class="home-page">
    <h1>{{ .Title }}</h1>
    {{ .Content }}
    
    <div class="dashboard">
      <!-- Project dashboard content -->
    </div>
  </div>
{{ end }}
EOF
```

## Phase 4: Testing & Deployment

### 4.1 Local Testing

Test the site locally before deployment:

```bash
# Start the Hugo server
hugo server -D

# Open browser at http://localhost:1313
```

Verify:
- All pages render correctly
- Navigation works as expected
- Status indicators display properly
- Internal links function correctly
- Images display properly

### 4.2 GitHub Pages Setup

Set up GitHub Pages deployment:

1. Create the GitHub Actions workflow file:
   ```bash
   mkdir -p .github/workflows
   # Copy content from github-workflow-setup.md to .github/workflows/hugo-deploy.yml
   ```

2. Configure the repository for GitHub Pages:
   - Go to repository Settings > Pages
   - Set Source to "GitHub Actions"

### 4.3 Deployment

Commit and push changes to trigger deployment:

```bash
git add .
git commit -m "Initial Hugo site migration"
git push origin main
```

Monitor the GitHub Actions workflow in the repository's Actions tab.

## Phase 5: Post-Migration Tasks

### 5.1 Validation

After deployment, validate:
- Check all pages on the live site
- Test on multiple devices and browsers
- Verify all links work correctly
- Test search functionality

### 5.2 Documentation Updates

Update references to documentation in other parts of the project:

- Update main README.md with link to the new documentation site
- Update contributing guidelines with information about the new documentation system
- Inform team members about the migration

### 5.3 Redirect Setup

If necessary, set up redirects from old documentation paths:

```
# In static/_redirects (for Netlify) or equivalent
/mcp-project/docs/architecture/overview.md  /mcp/architecture/overview/  301
```

## Maintenance Plan

### Regular Updates

Establish a process for keeping documentation up to date:

1. Documentation updates should be part of the development workflow
2. Regular reviews of documentation status
3. Automate status tracking with GitHub Actions

### Content Guidelines

Create guidelines for adding new content:

1. Where to add new documentation
2. Front matter requirements
3. How to use shortcodes
4. How to update related documents

### Training

Provide training for team members on:

1. How to navigate the new documentation system
2. How to contribute to documentation
3. How to build and test the documentation locally