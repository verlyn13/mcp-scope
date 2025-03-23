---
title: "Branch Management Testing Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/deploy/docs/branch-management/"
  - "/deploy/docs/github-pages-guide/"
tags: ["testing", "branching", "deployment", "github-pages"]
---

# Branch Management Testing Guide

{{< status >}}

This guide outlines the testing procedures for the enhanced branch management features to ensure safe and reliable GitHub Pages deployments.

## Table of Contents

{{< toc >}}

## Testing Prerequisites

Before conducting any branch management tests, ensure:

1. You have a clean working directory (`git status` shows no uncommitted changes)
2. Your repository has both `main` and `gh-pages` branches set up
3. All branch safety scripts are executable:
   ```bash
   chmod +x deploy/scripts/*.sh
   ```
4. You understand which branch you're currently on (`git branch --show-current`)

## Test Matrix

The following test matrix covers critical branch management scenarios:

| Test ID | Scenario | Starting Branch | Expected Result | Script |
|---------|----------|-----------------|-----------------|--------|
| BM-01 | Basic branch switching | main | Return to main | safe-gh-pages-deploy.sh |
| BM-02 | Deployment with uncommitted changes | main | Fail with warning | safe-gh-pages-deploy.sh |
| BM-03 | Deployment from non-main branch | gh-pages | Prompt with warning | safe-gh-pages-deploy.sh |
| BM-04 | Branch safety with script errors | main | Return to main | safe-gh-pages-deploy.sh |
| BM-05 | Dry run mode | main | No actual changes | safe-gh-pages-deploy.sh --dry-run |
| BM-06 | Different target branch | main | Deploy to specified branch | safe-gh-pages-deploy.sh --target-branch test-pages |
| BM-07 | Integration with unified script | main | Successful integration | unified-deploy.sh |

## Testing Procedures

### BM-01: Basic Branch Switching

**Purpose**: Verify that the script safely switches to the target branch and back.

1. Ensure you're on the `main` branch:
   ```bash
   git checkout main
   ```

2. Run the deployment script with dry run:
   ```bash
   ./deploy/scripts/safe-gh-pages-deploy.sh --dry-run
   ```

3. Verify the script:
   - Switched to `gh-pages` branch
   - Returned to `main` branch
   - Created log entries

### BM-02: Deployment with Uncommitted Changes

**Purpose**: Verify that the script prevents deployment with uncommitted changes.

1. Ensure you're on the `main` branch:
   ```bash
   git checkout main
   ```

2. Make a temporary change to any file:
   ```bash
   echo "# Test comment" >> README.md
   ```

3. Run the deployment script:
   ```bash
   ./deploy/scripts/safe-gh-pages-deploy.sh
   ```

4. Verify the script:
   - Detects uncommitted changes
   - Displays appropriate warning
   - Does not switch branches
   - Logs the failure

5. Clean up the test:
   ```bash
   git checkout -- README.md
   ```

### BM-03: Deployment from Non-Main Branch

**Purpose**: Verify that the script provides warnings when deploying from a non-main branch.

1. Switch to the `gh-pages` branch:
   ```bash
   git checkout gh-pages
   ```

2. Run the deployment script:
   ```bash
   ./deploy/scripts/safe-gh-pages-deploy.sh
   ```

3. Verify the script:
   - Displays a warning about deploying from a non-main branch
   - Prompts for confirmation
   - If confirmed, attempts deployment (may fail depending on content)
   - Logs the non-standard branch usage

4. Return to the main branch:
   ```bash
   git checkout main
   ```

### BM-04: Branch Safety with Script Errors

**Purpose**: Verify that the script returns to the original branch even if errors occur.

1. Create a test script that simulates a deployment error:
   ```bash
   cat > test-error.sh << 'EOL'
   #!/bin/bash
   # Source the branch safety functions
   source "./deploy/scripts/branch-safety.sh"
   # Get current branch
   current_branch=$(git rev-parse --abbrev-ref HEAD)
   # Switch to target branch
   safe_branch_switch "gh-pages"
   # Simulate an error
   echo "Simulated error during deployment" >&2
   exit 1
   EOL
   chmod +x test-error.sh
   ```

2. Run the test script:
   ```bash
   ./test-error.sh
   ```

3. Verify:
   - The script switched to the `gh-pages` branch
   - The error was reported
   - The script automatically returned to the original branch

4. Clean up:
   ```bash
   rm test-error.sh
   ```

### BM-05: Dry Run Mode

**Purpose**: Verify the dry run mode works correctly.

1. Ensure you're on the `main` branch:
   ```bash
   git checkout main
   ```

2. Run the deployment script in dry run mode:
   ```bash
   ./deploy/scripts/safe-gh-pages-deploy.sh --dry-run
   ```

3. Verify:
   - Script switches branches
   - Shows what would be done
   - Makes no actual changes to the target branch
   - Returns to original branch
   - Logs the dry run operation

### BM-06: Different Target Branch

**Purpose**: Verify deployment to a non-standard target branch.

1. Create a test target branch:
   ```bash
   git checkout -b test-pages
   git checkout main
   ```

2. Run the deployment script with a custom target branch:
   ```bash
   ./deploy/scripts/safe-gh-pages-deploy.sh --target-branch test-pages
   ```

3. Verify:
   - Script switches to `test-pages` branch
   - Updates content on that branch
   - Returns to `main` branch
   - Logs the operation

4. Clean up:
   ```bash
   git branch -D test-pages
   ```

### BM-07: Integration with Unified Script

**Purpose**: Verify integration with the main unified deployment script.

1. Temporarily modify unified-deploy.sh to use the integration script:
   ```bash
   # Add to the beginning after VERSION declaration
   source "./deploy/scripts/integrate-deployment.sh"
   ```

2. Run the unified script with the safe branch option:
   ```bash
   ./deploy/unified-deploy.sh --safe-branch --skip-verify
   ```

3. Verify:
   - Unified script successfully uses enhanced branch management
   - Build and deployment complete successfully
   - Script returns to original branch
   - Operations are properly logged

4. Clean up:
   ```bash
   # Revert the changes to unified-deploy.sh
   git checkout -- deploy/unified-deploy.sh
   ```

## Verifying Test Results

After each test, verify:

1. **Current Branch**: You should be back on the branch you started on
   ```bash
   git branch --show-current
   ```

2. **Logging**: Check the branch operation logs
   ```bash
   cat deploy-reports/branch-logs/branch-operations.log
   ```

3. **Branch State**: Verify branches contain appropriate content
   ```bash
   git checkout gh-pages
   ls -la
   git checkout main
   ```

## Reporting Test Results

Document your test results in a structured format:

```
Test ID: BM-XX
Date/Time: YYYY-MM-DD HH:MM
Tester: Your Name
Starting Branch: main
Command Run: ./script.sh --option
Result: Pass/Fail
Notes: Any observations or issues
```

## Troubleshooting Common Issues

| Issue | Solution |
|-------|----------|
| Script fails to detect current branch | Ensure you're in a git repository with at least one commit |
| Script fails to switch branches | Check for uncommitted changes or permission issues |
| Script doesn't return to original branch | Manually run `git checkout <original-branch>` |
| Log directory missing | Create the directory: `mkdir -p deploy-reports/branch-logs` |
| Integration issues | Ensure paths are correct and scripts are executable |

## Related Documentation

{{< related-docs >}}