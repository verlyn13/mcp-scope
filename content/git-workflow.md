# MCP Documentation Git Workflow

This document explains the Git workflow for the MCP Documentation system, including branch management and deployment process.

## Branch Structure

The documentation system uses the following branch structure:

- **main**: Development branch where all content and code changes are made.
- **gh-pages**: Deployment branch that contains the generated static site for GitHub Pages.

## Workflow Overview

1. All development work happens on the `main` branch.
2. The deployment script (`./mcp-docs deploy`) builds the site and pushes to the `gh-pages` branch.
3. GitHub Pages serves the content from the `gh-pages` branch.

```
main branch: Content source files (Markdown, templates, scripts)
        |
        | (build with Hugo)
        ↓
gh-pages branch: Generated static HTML files
        |
        | (served by GitHub Pages)
        ↓
Public website
```

## Development Workflow

### 1. Regular Development

```bash
# Make sure you're on the main branch
git checkout main

# Make your changes to content, templates, etc.
# ...

# Test locally
./mcp-docs hugo server

# When satisfied, commit your changes
git add .
git commit -m "Description of your changes"
git push origin main
```

### 2. Deployment

```bash
# Make sure you're on the main branch with latest changes
git checkout main
git pull origin main

# Run the deployment script
./mcp-docs deploy

# This will:
# 1. Build the Hugo site
# 2. Switch to gh-pages branch
# 3. Replace content with the new build
# 4. Commit and push to gh-pages
# 5. Switch back to main branch
```

## Reverting Commits

If you accidentally commit files that shouldn't be tracked (e.g., generated files), you can revert the commit:

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

### Reverting the Most Recent Commit

To revert the most recent commit (which is what you mentioned you need to do):

```bash
# Soft reset keeps your changes but uncommits them
git reset --soft HEAD~1

# Now you can review the files, update .gitignore, and commit only what you want
git status
# Update .gitignore as needed
git add .gitignore
# Add only files you want to commit
git add file1 file2 ...
git commit -m "Proper commit with updated .gitignore"
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

## Checking What Would Be Committed

Before committing, it's good practice to check what files would be included:

```bash
# See what files are staged for commit
git status

# For a more detailed view of changes
git diff --staged
```

## Best Practices

1. **Keep gh-pages branch clean**: Never commit directly to gh-pages; only use the deployment script.

2. **Update .gitignore when needed**: If you find new types of files that shouldn't be committed, update `.gitignore`.

3. **Separate content from generated files**: All source files go in `main`, all generated files go in `gh-pages`.

4. **Test locally before deployment**: Always test your changes with `./mcp-docs hugo server` before deploying.

5. **Commit frequently but deploy intentionally**: Commit your changes to `main` frequently, but only deploy when you have a stable version.