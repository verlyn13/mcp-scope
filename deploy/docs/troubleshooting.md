---
title: "Deployment Troubleshooting Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/deploy/docs/deployment-guide/"
  - "/deploy/docs/deployment-architecture/"
tags: ["deployment", "troubleshooting", "documentation", "hugo", "github-pages"]
---

# Deployment Troubleshooting Guide

{{< status >}}

This guide helps diagnose and resolve common issues with the documentation deployment system.

{{< callout "info" "First Steps" >}}
When troubleshooting deployment issues, always run with verbose output first:
```bash
./deploy/unified-deploy.sh --output verbose
```
This provides detailed information about what's happening at each step.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Diagnostic Tools

The unified deployment system includes several diagnostic tools:

### Verbose Output

Enables detailed logging of all deployment steps:

```bash
./deploy/unified-deploy.sh --output verbose
```

### Deployment Reports

Check the latest deployment report for detailed information:

```bash
ls -lt ./deploy-reports/
```

### Environment Verification

Run the verification step independently:

```bash
./deploy/scripts/verify-environment.sh
```

## Common Issues

### Container-Related Issues

#### Issue: Container Runtime Not Found

**Symptoms:**
```
✗ No container runtime found (Podman or Docker)
```

**Solutions:**
1. Install Podman or Docker:
   ```bash
   # Fedora/RHEL
   sudo dnf install podman
   
   # Ubuntu/Debian
   sudo apt install docker.io
   ```

2. Use local Hugo instead:
   ```bash
   ./deploy/unified-deploy.sh --mode local
   ```

3. Use minimal mode as fallback:
   ```bash
   ./deploy/unified-deploy.sh --mode minimal
   ```

#### Issue: Failed to Pull Hugo Image

**Symptoms:**
```
Error: failed to pull image...
```

**Solutions:**
1. Check network connectivity
2. Try with explicit registry path:
   ```bash
   podman pull docker.io/klakegg/hugo:0.110-ext-alpine
   ```
3. Check registry availability:
   ```bash
   curl -s https://registry.hub.docker.com/v2/repositories/klakegg/hugo/tags | grep 0.110
   ```
4. Use minimal mode as fallback:
   ```bash
   ./deploy/unified-deploy.sh --mode minimal
   ```

#### Issue: Permission Denied When Mounting Volume

**Symptoms:**
```
Error: permission denied on volume mount
```

**Solutions:**
1. For SELinux systems, ensure proper context:
   ```bash
   # Podman with :z volume flag
   podman run --rm -v "$(pwd)":/src:z -w /src hugo-local --help
   ```

2. Run as different user:
   ```bash
   sudo ./deploy/unified-deploy.sh --mode container
   ```

### Hugo-Related Issues

#### Issue: Hugo Not Found

**Symptoms:**
```
✗ Hugo not found locally
```

**Solutions:**
1. Install Hugo:
   ```bash
   # Fedora/RHEL
   sudo dnf install hugo
   
   # Ubuntu/Debian
   sudo apt install hugo
   
   # macOS
   brew install hugo
   ```

2. Use container mode instead:
   ```bash
   ./deploy/unified-deploy.sh --mode container
   ```

#### Issue: Shortcode Errors

**Symptoms:**
```
Error: failed to extract shortcode: template for shortcode "X" not found
```

**Solutions:**
1. Check if shortcode templates exist:
   ```bash
   ls themes/mcp-theme/layouts/shortcodes/
   ```

2. Create missing shortcode templates:
   ```bash
   cp ./deploy/templates/shortcodes/toc.html themes/mcp-theme/layouts/shortcodes/
   ```

3. Use minimal mode to bypass shortcode issues:
   ```bash
   ./deploy/unified-deploy.sh --mode minimal
   ```

4. Fix shortcodes in content files:
   ```bash
   ./doc-doctor.sh --focus-area shortcodes
   ```

#### Issue: Hugo Build Errors

**Symptoms:**
```
Error: error building site: ...
```

**Solutions:**
1. Check build logs for specific errors
2. Validate Hugo configuration:
   ```bash
   hugo config
   ```
3. Try with `--minify=false`:
   ```bash
   ./deploy/unified-deploy.sh --hugo-flags "--minify=false"
   ```

### Git-Related Issues

#### Issue: Permission Denied When Pushing

**Symptoms:**
```
✗ Failed to push to gh-pages branch
Permission denied (publickey)
```

**Solutions:**
1. Check your Git authentication:
   ```bash
   ssh -T git@github.com
   ```

2. Set up SSH key or credential helper:
   ```bash
   # SSH key setup
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

3. Use HTTPS URL if necessary:
   ```bash
   git remote set-url origin https://github.com/username/repo.git
   ```

#### Issue: Merge Conflicts on Target Branch

**Symptoms:**
```
Error: Failed to switch to gh-pages branch
```

**Solutions:**
1. Manually resolve the conflicts:
   ```bash
   git checkout gh-pages
   git pull
   # Resolve conflicts
   git add .
   git commit -m "Resolve conflicts"
   git push
   ```

2. Force reset the branch (use with caution):
   ```bash
   git checkout gh-pages
   git reset --hard origin/gh-pages
   git checkout main
   ```

#### Issue: Branch Does Not Exist

**Symptoms:**
```
fatal: reference is not a tree: gh-pages
```

**Solutions:**
1. Create the branch:
   ```bash
   git checkout --orphan gh-pages
   git reset --hard
   touch index.html
   git add index.html
   git commit -m "Initialize gh-pages branch"
   git push -u origin gh-pages
   git checkout main
   ```

2. Use a different branch name:
   ```bash
   ./deploy/unified-deploy.sh --branch documentation
   ```

## Environment-Specific Issues

### CI/CD Environments

#### Issue: GitHub Actions Authentication

**Symptoms:**
```
✗ Failed to push to gh-pages branch
```

**Solutions:**
1. Use the `actions/checkout@v3` with token:
   ```yaml
   - uses: actions/checkout@v3
     with:
       token: ${{ secrets.GITHUB_TOKEN }}
       fetch-depth: 0
   ```

2. Set up deployment key:
   ```yaml
   - name: Set up SSH key
     run: |
       mkdir -p ~/.ssh
       echo "${{ secrets.DEPLOY_KEY }}" > ~/.ssh/id_ed25519
       chmod 600 ~/.ssh/id_ed25519
   ```

#### Issue: GitLab CI Missing Files

**Symptoms:**
```
Error: File not found
```

**Solutions:**
1. Make sure to use a proper Git depth:
   ```yaml
   variables:
     GIT_DEPTH: "0"
   ```

2. Include submodules if used:
   ```yaml
   variables:
     GIT_SUBMODULE_STRATEGY: recursive
   ```

### Local Environment Issues

#### Issue: Old Content Still Showing After Deployment

**Symptoms:**
- Deployed site shows outdated content despite successful deployment

**Solutions:**
1. Clear browser cache
2. Wait for GitHub Pages to rebuild (can take a few minutes)
3. Check the commit history on GitHub:
   ```bash
   git log origin/gh-pages -n 5
   ```

#### Issue: Deployment Takes Too Long

**Symptoms:**
- Deployment process is much slower than expected

**Solutions:**
1. Skip verification steps when not needed:
   ```bash
   ./deploy/unified-deploy.sh --skip-verify
   ```

2. Skip precaching when containers are already available:
   ```bash
   ./deploy/unified-deploy.sh --skip-precache
   ```

3. Use local mode for faster builds:
   ```bash
   ./deploy/unified-deploy.sh --mode local
   ```

## Advanced Troubleshooting

### Manual Build Process

If the unified script fails, you can try the individual steps manually:

1. Build the site:
   ```bash
   # With local Hugo
   hugo --minify
   
   # With container
   podman run --rm -v "$(pwd)":/src:z -w /src klakegg/hugo:0.110-ext-alpine --minify
   ```

2. Deploy manually:
   ```bash
   # Store current branch
   current_branch=$(git rev-parse --abbrev-ref HEAD)
   
   # Switch to target branch
   git checkout gh-pages
   
   # Remove existing content
   find . -maxdepth 1 -not -path "*/\.*" -not -path "." -not -path "./public" -exec rm -rf {} \;
   
   # Copy new content
   cp -r public/* .
   
   # Commit and push
   git add .
   git commit -m "Manual deployment"
   git push
   
   # Return to original branch
   git checkout $current_branch
   ```

### Debugging Container Issues

For detailed container debugging:

```bash
# Run container interactively
podman run --rm -it -v "$(pwd)":/src:z -w /src klakegg/hugo:0.110-ext-alpine sh

# Inside the container
ls -la
hugo version
hugo --minify
```

### Debugging Hugo Issues

For detailed Hugo debugging:

```bash
# Run Hugo with verbose output
hugo --minify -v

# List all shortcodes used in content
grep -r "{{<" --include="*.md" content/
```

## When All Else Fails

If nothing else works:

1. **Minimal Mode**: Use the minimal deployment mode to get a basic site online:
   ```bash
   ./deploy/unified-deploy.sh --mode minimal
   ```

2. **Manual HTML**: Create a simple index.html and deploy:
   ```bash
   echo "<html><body><h1>MCP Documentation</h1><p>Site under maintenance.</p></body></html>" > index.html
   git checkout gh-pages
   git add index.html
   git commit -m "Basic placeholder page"
   git push
   ```

3. **Seek Help**: Create an issue in the repository with:
   - Deployment logs
   - Environment details
   - Steps to reproduce

## Related Documentation

{{< related-docs >}}