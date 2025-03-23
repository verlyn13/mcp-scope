---
title: "Doc Doctor Integration Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/standards/documentation-guidelines/"
  - "/tools/doc-doctor-summary/"
tags: ["integration", "automation", "ci-cd", "documentation", "quality", "verification"]
---

# Doc Doctor Integration Guide

{{< status >}}

## Overview

This guide explains how to integrate the Doc Doctor documentation health check system into various workflows and automation pipelines. It provides practical examples and configuration templates for different integration scenarios.

{{< callout "info" "Purpose" >}}
Integrate Doc Doctor health checks into your existing workflows to automate documentation quality verification and maintain consistent standards across your documentation.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Integration Options

Doc Doctor can be integrated into your workflow in several ways:

### CI/CD Pipeline Integration

Adding Doc Doctor to your continuous integration process ensures documentation quality is verified with every change.

#### GitHub Actions

```yaml
name: Documentation Health Check

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'content/**'
      - 'docs/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'content/**'
      - 'docs/**'

jobs:
  doc-health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Doc Doctor
        run: |
          chmod +x ./doc-doctor.sh
          chmod +x ./run-doc-doctor.sh
          ./run-doc-doctor.sh -l standard -f markdown
          
      - name: Upload Doc Health Report
        uses: actions/upload-artifact@v3
        with:
          name: doc-health-report
          path: doc-reports/
```

#### GitLab CI

```yaml
documentation_health:
  stage: test
  script:
    - chmod +x ./doc-doctor.sh
    - chmod +x ./run-doc-doctor.sh
    - ./run-doc-doctor.sh -l standard -f json
  artifacts:
    paths:
      - doc-reports/
  rules:
    - changes:
        - content/**/*
        - docs/**/*
```

#### Jenkins Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Documentation Health') {
            when {
                changeset "content/**/*"
                changeset "docs/**/*"
            }
            steps {
                sh 'chmod +x ./doc-doctor.sh'
                sh 'chmod +x ./run-doc-doctor.sh'
                sh './run-doc-doctor.sh -l standard -f all'
                archiveArtifacts artifacts: 'doc-reports/*', fingerprint: true
            }
        }
    }
}
```

### Git Hooks Integration

Using Git hooks allows you to automatically check documentation health at specific points in the Git workflow.

#### Pre-Commit Hook

Add a hook to verify documentation before committing changes:

```bash
#!/bin/bash
# File: .git/hooks/pre-commit

# Get changed markdown files
changed_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(md|markdown)$')

if [ -n "$changed_files" ]; then
  echo "Running Doc Doctor check on changed documentation files..."
  
  # Run quick check with focus on changed files only
  ./run-doc-doctor.sh -l quick
  
  # Exit with error if critical issues were found
  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "Documentation health check failed. Please fix critical issues before committing."
    exit $exit_code
  fi
fi

exit 0
```

Make the hook executable:

```bash
chmod +x .git/hooks/pre-commit
```

#### Pre-Push Hook

Add a more thorough check before pushing changes:

```bash
#!/bin/bash
# File: .git/hooks/pre-push

# Run standard check before pushing
./run-doc-doctor.sh

# Exit with error if critical issues were found
exit_code=$?
if [ $exit_code -ne 0 ]; then
  echo "Documentation health check failed. Please fix critical issues before pushing."
  exit $exit_code
fi

exit 0
```

Make the hook executable:

```bash
chmod +x .git/hooks/pre-push
```

### Code Editor Integration

You can integrate Doc Doctor with popular code editors for on-demand health checks.

#### VS Code Tasks

Add Doc Doctor to VS Code tasks.json:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Doc Doctor: Quick Check",
      "type": "shell",
      "command": "./run-doc-doctor.sh -l quick",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Doc Doctor: Standard Check",
      "type": "shell",
      "command": "./run-doc-doctor.sh",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Doc Doctor: Comprehensive Check",
      "type": "shell",
      "command": "./run-doc-doctor.sh -l comprehensive -f markdown",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

#### Vim Integration

Add to your .vimrc file:

```vim
" Doc Doctor commands
command! DocDoctorQuick !./run-doc-doctor.sh -l quick
command! DocDoctorStandard !./run-doc-doctor.sh
command! DocDoctorComprehensive !./run-doc-doctor.sh -l comprehensive -f markdown
```

### Scheduled Health Checks

Set up regular documentation health checks using cron or other schedulers.

#### Cron Job

Add a scheduled task to run comprehensive checks periodically:

```bash
# Run comprehensive checks every Monday at 9 AM
0 9 * * 1 cd /path/to/project && ./run-doc-doctor.sh -l comprehensive -f all

# Run standard checks daily at midnight
0 0 * * * cd /path/to/project && ./run-doc-doctor.sh -f json > /var/log/doc-health/$(date +\%Y\%m\%d).json
```

### Automation Server Integration

Integrate with automation servers for scheduled or event-triggered checks.

#### Ansible Playbook

```yaml
---
- name: Run Documentation Health Check
  hosts: documentation_servers
  tasks:
    - name: Ensure Doc Doctor scripts are executable
      file:
        path: "{{ item }}"
        mode: '0755'
      loop:
        - "/path/to/doc-doctor.sh"
        - "/path/to/run-doc-doctor.sh"
    
    - name: Run Doc Doctor check
      command: /path/to/run-doc-doctor.sh -l comprehensive -f all
      args:
        chdir: /path/to/project
      register: doc_health_result
    
    - name: Show health check results
      debug:
        var: doc_health_result.stdout_lines
```

## Integration Best Practices

### Configure Check Levels Appropriately

Choose the right check level for each integration point:

- **Quick checks** for frequent operations (pre-commit, save actions)
- **Standard checks** for regular verification (CI/CD, pre-push)
- **Comprehensive checks** for periodic validation (scheduled jobs, releases)

### Focus on Relevant Areas

Use focus areas to target specific aspects:

```bash
# For content changes
./run-doc-doctor.sh -a structure

# For template changes
./run-doc-doctor.sh -a shortcodes
```

### Use Appropriate Output Formats

Select output formats based on the integration context:

- **Terminal**: For interactive use
- **Markdown**: For human-readable reports
- **JSON**: For further processing and automation

### Handle Exit Codes

Doc Doctor returns non-zero exit codes for critical issues, which can be used to gate processes:

```bash
./run-doc-doctor.sh
if [ $? -ne 0 ]; then
  echo "Documentation has critical issues"
  exit 1
fi
```

### Store Historical Reports

Keep reports to track documentation health over time:

```bash
# Create timestamped report
report_dir="reports/$(date +%Y-%m-%d)"
mkdir -p "$report_dir"
./run-doc-doctor.sh -f all --report-dir "$report_dir"
```

## Troubleshooting Integration Issues

### Common Issues and Solutions

1. **Permission Denied Errors**
   - Ensure scripts are executable: `chmod +x *.sh`
   - Check file ownership if running in automation

2. **Path Issues**
   - Use absolute paths in automation: `/full/path/to/run-doc-doctor.sh`
   - Run from the project root directory

3. **Timeouts in CI/CD**
   - Use quick check level for faster execution
   - Focus on specific areas to reduce scope

### Debugging Integration

Add debug output to help troubleshoot integration issues:

```bash
# Run with debug output
DOCDOCTOR_DEBUG=1 ./run-doc-doctor.sh
```

## Examples of Successful Integrations

### Release Process Integration

```bash
#!/bin/bash
# pre-release-check.sh

echo "Running documentation health check before release..."
./run-doc-doctor.sh -l comprehensive -f markdown

if [ $? -ne 0 ]; then
  echo "Documentation health check failed. Release aborted."
  exit 1
fi

echo "Documentation health check passed. Proceeding with release..."
# Continue with release steps
```

### Pull Request Validation

GitHub Action workflow that comments on PRs with documentation issues:

```yaml
name: Documentation Review

on:
  pull_request:
    paths:
      - 'content/**'
      - 'docs/**'

jobs:
  doc-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Doc Doctor
        run: |
          chmod +x ./doc-doctor.sh
          chmod +x ./run-doc-doctor.sh
          ./run-doc-doctor.sh -l standard -f json > doc-review.json
        continue-on-error: true
      
      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const docReview = JSON.parse(fs.readFileSync('doc-review.json', 'utf8'));
            
            let comment = '## Documentation Review\n\n';
            
            // Count issues by severity
            const critical = docReview.filter(i => i.severity === 'CRITICAL').length;
            const warnings = docReview.filter(i => i.severity === 'WARNING').length;
            
            comment += `Found ${critical} critical issues and ${warnings} warnings.\n\n`;
            
            // Add critical issues
            if (critical > 0) {
              comment += '### Critical Issues\n\n';
              docReview.filter(i => i.severity === 'CRITICAL').forEach(issue => {
                comment += `- **${issue.check}** in \`${issue.file}\`: ${issue.message}\n`;
              });
              comment += '\n';
            }
            
            // Summary
            if (critical === 0 && warnings === 0) {
              comment += '✅ Documentation looks good!';
            } else if (critical === 0) {
              comment += '⚠️ Documentation has some warnings but no critical issues.';
            } else {
              comment += '❌ Documentation has critical issues that must be fixed.';
            }
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

## Conclusion

Integrating Doc Doctor into your workflows provides continuous verification of documentation quality and ensures consistent standards across your project. By incorporating health checks at various stages of your process, you can catch and fix documentation issues early, maintaining high-quality documentation throughout the project lifecycle.

## Related Documentation

{{< related-docs >}}