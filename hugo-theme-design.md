# Hugo Theme Design for ScopeCam MCP Documentation

This document outlines the design and implementation plan for the custom Hugo theme that will support the ScopeCam MCP documentation site. The theme is designed to maintain the dual-layer structure of the documentation while providing enhanced navigation, status visualization, and search capabilities.

## Theme Overview

The MCP theme will be built as a custom Hugo theme optimized for technical documentation with the following key features:

1. **Dual-Layer Navigation**: Support for navigating between Root and MCP documentation layers
2. **Status Visualization**: Color-coded status indicators matching the current system
3. **Progress Tracking**: Visual representation of project progress
4. **Search Functionality**: Full-text search across documentation
5. **Responsive Design**: Mobile-friendly layout
6. **Taxonomy Support**: Tag filtering and visualization

## Design Principles

The theme design will adhere to the following principles:

1. **Consistency with Existing Documentation**: Maintain the look and feel of the current documentation
2. **Clarity and Readability**: Focus on typography and spacing for optimal reading experience
3. **Information Architecture**: Structured navigation and organization
4. **Visual Hierarchy**: Clear distinction between different content types and importance levels
5. **Accessibility**: Ensure WCAG 2.1 AA compliance
6. **Performance**: Optimize for fast loading and rendering

## Visual Design Elements

### Color Palette

The theme will use the following color palette:

1. **Primary Colors**:
   - Main Brand Color: `#007bff` (blue)
   - Secondary Brand Color: `#6c757d` (gray)

2. **Status Colors**:
   - Active: `#28a745` (green)
   - Draft: `#ffc107` (yellow)
   - Review: `#fd7e14` (orange)
   - Outdated: `#dc3545` (red)
   - Archived: `#343a40` (dark gray)

3. **Background Colors**:
   - Light: `#ffffff` (white)
   - Light Gray: `#f8f9fa`
   - Dark Mode Background: `#212529` (optional)

### Typography

The theme will use a clean, readable typography system:

1. **Font Family**:
   - Headings: System sans-serif stack with fallbacks
   - Body Text: System sans-serif stack with fallbacks
   - Code: Monospace stack

2. **Font Sizes**:
   - Base: 16px
   - Scale: 1.25 ratio

3. **Line Heights**:
   - Headings: 1.2
   - Body: 1.5
   - Code: 1.6

### Icons and Visual Elements

1. **Status Indicators**: Emoji-based status indicators consistent with current system
2. **Progress Bars**: Visual representation of project progress
3. **Navigation Icons**: Simple icons for navigation elements
4. **Layer Switch**: Visual toggle for switching between documentation layers

## Layout Structure

### Page Templates

The theme will include the following page templates:

1. **Home Page (`layouts/index.html`)**:
   - Project dashboard with progress visualization
   - Layer selection
   - Quick navigation links
   - Recent updates

2. **Section Landing Pages (`layouts/_default/section.html`)**:
   - Section overview
   - List of section documents with status indicators
   - Section-specific navigation

3. **Single Pages (`layouts/_default/single.html`)**:
   - Content with status indicator
   - Table of contents
   - Related documents
   - Last updated timestamp
   - Contributors list

4. **List Pages (`layouts/_default/list.html`)**:
   - Filterable list of pages
   - Status indicators
   - Brief descriptions

### Base Layout

The base layout will include:

1. **Header**:
   - Site logo
   - Layer switch toggle
   - Global navigation
   - Search bar

2. **Sidebar**:
   - Section navigation
   - Collapsible tree menu
   - Current section indicator

3. **Main Content Area**:
   - Content with proper spacing and typography
   - Status indicator
   - Metadata

4. **Footer**:
   - Copyright information
   - Links to important resources
   - Build information

## Navigation System

### Dual-Layer Navigation

The theme will implement a dual-layer navigation system that:

1. Clearly distinguishes between Root Documentation and MCP Documentation layers
2. Allows easy switching between layers
3. Visually indicates the current layer
4. Shows proper section hierarchy within each layer

Implementation:

```html
<!-- Example layout/partials/layer-switch.html -->
<div class="layer-switch">
  <button class="layer-button {{ if eq $.Site.Params.currentLayer "root" }}active{{ end }}" data-layer="root">
    Root Documentation
  </button>
  <button class="layer-button {{ if eq $.Site.Params.currentLayer "mcp" }}active{{ end }}" data-layer="mcp">
    MCP Documentation
  </button>
</div>
```

### Hierarchical Navigation

The sidebar will implement hierarchical navigation:

1. **Main Sections**: Top-level sections like Project, Architecture, Guides
2. **Subsections**: Nested under main sections
3. **Active Section**: Visual indication of current section
4. **Expandable/Collapsible**: Toggle visibility of subsections

```html
<!-- Example layout/partials/sidebar.html -->
<nav class="sidebar">
  <ul class="nav-list">
    {{ range .Site.Menus.main }}
      <li class="nav-item {{ if .HasChildren }}has-children{{ end }}">
        <a href="{{ .URL }}" class="{{ if $.IsMenuCurrent "main" . }}active{{ end }}">
          {{ .Name }}
        </a>
        {{ if .HasChildren }}
          <ul class="nav-children">
            {{ range .Children }}
              <li class="nav-child">
                <a href="{{ .URL }}" class="{{ if $.IsMenuCurrent "main" . }}active{{ end }}">
                  {{ .Name }}
                </a>
              </li>
            {{ end }}
          </ul>
        {{ end }}
      </li>
    {{ end }}
  </ul>
</nav>
```

### Breadcrumbs

Breadcrumb navigation will show the path through the documentation:

```html
<!-- Example layout/partials/breadcrumbs.html -->
<div class="breadcrumbs">
  <a href="/">Home</a>
  {{ range .Ancestors.Reverse }}
    <span class="separator">/</span>
    <a href="{{ .RelPermalink }}">{{ .Title }}</a>
  {{ end }}
  <span class="separator">/</span>
  <span class="current">{{ .Title }}</span>
</div>
```

## Status Visualization

The theme will implement the status system using:

1. **Status Shortcode**: Easy insertion of status indicators
2. **Status Taxonomy**: Filtering content by status
3. **Status CSS Classes**: Consistent styling across the site

Implementation:

```html
<!-- Example layouts/shortcodes/status.html -->
{{ $status := .Get 0 | default (.Page.Params.status) }}
<span class="status status-{{ lower $status }}">
  {{ if eq $status "Active" }}🟢 Active{{ end }}
  {{ if eq $status "Draft" }}🟡 Draft{{ end }}
  {{ if eq $status "Review" }}🟠 Review{{ end }}
  {{ if eq $status "Outdated" }}🔴 Outdated{{ end }}
  {{ if eq $status "Archived" }}⚫ Archived{{ end }}
</span>
```

## Progress Tracking

The theme will implement progress tracking with:

1. **Progress Bar Shortcode**: Visual progress indication
2. **Dashboard Component**: Project-wide progress visualization
3. **Timeline Component**: Project roadmap visualization

Implementation:

```html
<!-- Example layouts/shortcodes/progress.html -->
{{ $value := .Get "value" | default 0 }}
<div class="progress">
  <div class="progress-bar" role="progressbar" style="width: {{ $value }}%;" 
       aria-valuenow="{{ $value }}" aria-valuemin="0" aria-valuemax="100">
    {{ $value }}%
  </div>
</div>
```

## Search Implementation

The theme will implement search using:

1. **Client-Side Search**: Using Fuse.js for instant results
2. **Search Index**: Automatically generated from content
3. **Result Highlighting**: Visual indication of search matches
4. **Filtered Results**: Ability to filter by section, status, and tag

Implementation:

```html
<!-- Example layouts/partials/search.html -->
<div class="search-container">
  <input type="text" id="search-input" placeholder="Search documentation...">
  <div id="search-results" class="search-results"></div>
</div>

<script>
  // Initialize Fuse.js with search index
  const searchIndex = {{ .Site.Data.searchIndex | jsonify }};
  const fuse = new Fuse(searchIndex, {
    keys: ['title', 'content', 'tags'],
    includeMatches: true,
    threshold: 0.3
  });
  
  // Search implementation
  document.getElementById('search-input').addEventListener('input', function(e) {
    const query = e.target.value;
    if (query.length < 2) {
      document.getElementById('search-results').innerHTML = '';
      return;
    }
    
    const results = fuse.search(query);
    // Render results
  });
</script>
```

## Responsive Design

The theme will be fully responsive using:

1. **Mobile-First Approach**: Design for small screens first
2. **Breakpoints**: Specific layouts for different screen sizes
3. **Collapsible Elements**: Menu and sidebar collapse on small screens
4. **Touch-Friendly**: Optimized for touch interactions

Implementation using CSS media queries:

```scss
// Base styles (mobile-first)
.sidebar {
  position: fixed;
  width: 100%;
  height: auto;
  transform: translateX(-100%);
  transition: transform 0.3s ease;
  
  &.open {
    transform: translateX(0);
  }
}

// Tablet breakpoint
@media (min-width: 768px) {
  .sidebar {
    width: 250px;
    transform: none;
  }
  
  .main-content {
    margin-left: 250px;
  }
}

// Desktop breakpoint
@media (min-width: 1024px) {
  .sidebar {
    width: 300px;
  }
  
  .main-content {
    margin-left: 300px;
  }
}
```

## Implementation Approach

### Theme Structure

The theme will follow the standard Hugo theme structure:

```
mcp-theme/
├── archetypes/          # Content templates
├── assets/              # Raw assets (SCSS, JS)
│   ├── scss/            # SCSS files
│   │   ├── main.scss    # Main stylesheet
│   │   ├── _variables.scss  # Variables
│   │   ├── _layout.scss     # Layout styles
│   │   ├── _typography.scss # Typography styles
│   │   └── ...          # Other partials
│   └── js/              # JavaScript files
│       ├── main.js      # Main JavaScript file
│       ├── search.js    # Search functionality
│       └── ...          # Other JS modules
├── layouts/             # Templates
│   ├── _default/        # Default templates
│   │   ├── baseof.html  # Base template
│   │   ├── list.html    # List template
│   │   └── single.html  # Single page template
│   ├── partials/        # Partial templates
│   │   ├── header.html  # Header partial
│   │   ├── footer.html  # Footer partial
│   │   ├── sidebar.html # Sidebar partial
│   │   └── ...          # Other partials
│   ├── shortcodes/      # Shortcode templates
│   │   ├── status.html  # Status shortcode
│   │   ├── progress.html # Progress bar shortcode
│   │   └── ...          # Other shortcodes
│   └── index.html       # Homepage template
├── static/              # Static assets
│   ├── images/          # Images
│   ├── fonts/           # Fonts
│   └── ...              # Other static assets
└── theme.toml           # Theme metadata
```

### Development Workflow

The theme development will follow this workflow:

1. **Setup**: Create the basic theme structure
2. **Base Templates**: Implement base templates (baseof.html, header, footer)
3. **CSS Framework**: Set up SCSS structure and compilation
4. **Layout Implementation**: Implement layout templates
5. **Navigation**: Build the navigation system
6. **Shortcodes**: Create custom shortcodes
7. **JavaScript Functionality**: Implement interactive features
8. **Responsive Design**: Ensure mobile compatibility
9. **Testing**: Test with sample content
10. **Documentation**: Document theme usage

### Dependencies

The theme will use the following dependencies:

1. **Hugo Extended**: Required for SCSS processing
2. **Fuse.js**: For client-side search
3. **Bootstrap (optional)**: For grid and utility classes
4. **Font Awesome (optional)**: For icons
5. **Mermaid.js**: For diagram rendering

## Custom Shortcodes

The theme will implement these custom shortcodes:

1. **Status**: `{{< status >}}` or `{{< status "Active" >}}`
2. **Progress**: `{{< progress value="80" >}}`
3. **Related Docs**: `{{< related-docs >}}`
4. **Mermaid Diagram**: `{{< mermaid >}}...{{< /mermaid >}}`
5. **Layer Switch**: `{{< layer-switch >}}`
6. **Notes and Warnings**: `{{< note >}}...{{< /note >}}` and `{{< warning >}}...{{< /warning >}}`

## Theme Configuration Options

The theme will support these configuration options:

```toml
[params]
  # Theme color scheme
  colorScheme = "light"  # light or dark
  
  # Logo configuration
  logo = "images/logo.png"
  logoAlt = "ScopeCam MCP Logo"
  
  # Default layer
  defaultLayer = "root"  # root or mcp
  
  # GitHub repository
  github_repo = "https://github.com/example/mcp-scope"
  github_branch = "main"
  
  # Search configuration
  enableSearch = true
  searchDebounceDuration = 300  # milliseconds
  
  # Status settings
  [params.status]
    active = "🟢 Active"
    draft = "🟡 Draft"
    review = "🟠 Review"
    outdated = "🔴 Outdated"
    archived = "⚫ Archived"
```

## Conclusion

This theme design provides a comprehensive foundation for building a Hugo theme that will support the ScopeCam MCP documentation needs. The design maintains the current documentation structure while enhancing it with Hugo's capabilities for organization, navigation, and presentation.

The implementation of this theme will provide a modern, maintainable documentation site that can be easily deployed to GitHub Pages and updated as the project evolves.