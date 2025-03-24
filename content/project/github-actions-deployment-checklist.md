---
title: "GitHub Actions Deployment Verification Checklist"
date: 2025-03-23
lastmod: 2025-03-23
weight: 11
description: "A step-by-step checklist to verify your GitHub Actions deployment for Hugo is working correctly"
status: "complete"
---

# GitHub Actions Deployment Verification Checklist

This checklist will help you verify that the GitHub Actions deployment workflow is correctly set up and functioning as expected. Use it to validate the deployment process after initial setup or when troubleshooting issues.

## 1. Prerequisites Verification

- [ ] Ensure you have Git installed and can commit/push to the repository
- [ ] Verify you have Hugo installed locally for testing (recommended but not required)
- [ ] Confirm you have proper permissions to the GitHub repository

## 2. Workflow File Verification

- [ ] Confirm the workflow file exists at `.github/workflows/hugo-deploy.yml`
- [ ] Verify the workflow triggers are configured correctly:
  ```yaml
  on:
    push:
      branches:
        - main
    workflow_dispatch:
  ```
- [ ] Check that the Hugo version specified in the workflow matches your local version (if applicable)
- [ ] Ensure the workflow has the correct permissions:
  ```yaml
  permissions:
    contents: read
    pages: write
    id-token: write
  ```

## 3. GitHub Repository Settings Verification

- [ ] Go to your repository's Settings → Pages
- [ ] Verify "Source" is set to "GitHub Actions"
- [ ] Check that the "Custom domain" setting is correct (if you're using a custom domain)
- [ ] Confirm "Enforce HTTPS" is enabled (if applicable)

## 4. Testing the Workflow

- [ ] Make a minor change to a content file (e.g., add a comment or update the date)
- [ ] Commit and push this change to the main branch
- [ ] Navigate to the Actions tab in your repository
- [ ] Verify a new workflow run has been triggered automatically
- [ ] Wait for the workflow to complete (should show a green checkmark when successful)

## 5. Deployment Verification

- [ ] Once the workflow completes, go to Settings → Pages
- [ ] Click on the provided deployment URL
- [ ] Verify the site loads correctly
- [ ] Check that the changes you made are visible
- [ ] Validate that internal links work correctly
- [ ] Confirm site styling and images load properly

## 6. Feature Verification

- [ ] Verify that the `.nojekyll` file is present (check your GitHub Pages branch or look at the build logs)
- [ ] Confirm the site has the correct base URL (no 404 errors on navigation)
- [ ] Validate that site-specific features work (search, navigation, etc.)
- [ ] Check that code syntax highlighting works (if applicable)
- [ ] Ensure any custom shortcodes render correctly

## 7. Manual Deployment Test

- [ ] Go to Actions tab in GitHub repository
- [ ] Click on "Deploy Hugo site to GitHub Pages" workflow
- [ ] Click "Run workflow" button
- [ ] Select main branch and click "Run workflow"
- [ ] Verify the workflow runs successfully
- [ ] Confirm the site updates after manual deployment

## 8. Common Issues Checklist

If you encounter problems, check for these common issues:

- [ ] **404 errors**: Verify the baseURL in your Hugo config matches your GitHub Pages URL
- [ ] **Missing theme**: Ensure the theme is either included directly in your repository or added as a Git submodule
- [ ] **Permission errors**: Confirm your repository has GitHub Pages enabled and the workflow has correct permissions
- [ ] **Build errors**: Check the workflow logs for Hugo build errors and fix any reported issues
- [ ] **Inconsistent rendering**: Make sure your Hugo version matches between local and GitHub Actions environments

## 9. Post-Deployment Documentation

- [ ] Update project documentation to reflect that GitHub Actions is now the deployment method
- [ ] Document any project-specific configurations or considerations
- [ ] Share the deployment URL with relevant team members
- [ ] Consider adding a GitHub Actions badge to your README.md to show deployment status

## 10. Cleanup Considerations

- [ ] If transitioning from another deployment method, consider archiving or removing old deployment scripts
- [ ] If you were using a gh-pages branch directly, consider whether to delete it or keep it for reference
- [ ] Update any CI/CD documentation to reflect the new process
- [ ] Review any GitHub repository settings that might have been specific to the old deployment method

---

After completing this checklist, your GitHub Actions deployment process should be fully verified and ready for ongoing use. Keep this checklist handy for future reference or troubleshooting.