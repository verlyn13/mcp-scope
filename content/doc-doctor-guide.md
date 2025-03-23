---
title: "Doc Doctor Guide"
status: "Active"
version: "1.0"
date_created: "2025-03-23"
last_updated: "2025-03-23"
contributors: ["Documentation Architect"]
related_docs:
  - "/standards/documentation-guidelines/"
  - "/standards/shortcode-standards/"
  - "/standards/status-system/"
tags: ["tool", "documentation", "health", "verification", "quality"]
---

# Doc Doctor: Documentation Health Check System

{{< status >}}

[↩️ Back to Tools](/tools/) | [↩️ Back to Documentation Index](/docs/)

## Overview

Doc Doctor is a comprehensive documentation health check system designed to ensure high-quality, consistent documentation across the MCP project. It performs a variety of checks on documentation content, structure, and metadata to identify issues and provide actionable feedback.

{{< callout "info" "Concept" >}}
Think of Doc Doctor as a medical professional for your documentation - it performs routine check-ups, diagnoses issues, and provides treatment recommendations to keep your documentation healthy.
{{< /callout >}}

## Table of Contents

{{< toc >}}

## Features

- **Modular Architecture**: Easily extendable with additional check modules
- **Multi-level Checking**: Quick, standard, and comprehensive check levels
- **Focus Areas**: Target specific aspects of documentation for review
- **Reporting Options**: Terminal output, markdown reports, and JSON data
- **Actionable Feedback**: Clear guidance on how to fix identified issues
- **Integration-Ready**: Designed to work with CI/CD pipelines and other tools

## Architecture

Doc Doctor follows a modular architecture:

```
doc-doctor.sh                  # Main script and framework
├── doc-doctor-modules/        # Check modules directory
│   ├── status-check.sh        # Status field checks
│   ├── shortcode-check.sh     # Shortcode validation
│   ├── frontmatter-check.sh   # Front matter validation
│   ├── link-check.sh          # Link verification
│   ├── structure-check.sh     # Document structure analysis
│   └── ...                    # Additional modules
├── .doc-doctor-temp/          # Temporary files (created at runtime)
└── doc-reports/               # Generated reports
```

The main script provides the framework, while individual modules perform specific checks and report findings back to the main script.

## Check Modules

Doc Doctor includes multiple specialized check modules:

| Module | Purpose | Checks Performed |
|--------|---------|------------------|
| `status-check.sh` | Verifies document status metadata | Missing status, invalid status values, outdated status |
| `shortcode-check.sh` | Analyzes shortcode usage | Unclosed shortcodes, unknown shortcodes, malformed syntax |
| `frontmatter-check.sh` | Validates front matter completeness | Required fields, valid values, consistency |
| `link-check.sh` | Verifies internal and external links | Broken links, outdated references, proper formatting |
| `structure-check.sh` | Analyzes document structure | Heading hierarchy, expected sections, proper organization |

Additional modules available in comprehensive mode:
- `image-check.sh`: Verifies image references and accessibility
- `style-check.sh`: Checks for consistent writing style and terminology
- `template-check.sh`: Validates template usage and conformity

## Usage

```bash
./doc-doctor.sh [options]
```

### Options

- `--help`: Display help message
- `--check-level LEVEL`: Set check level (quick, standard, comprehensive)
- `--output-format FORMAT`: Set output format (terminal, markdown, json, all)
- `--focus-area AREA`: Set focus area (all, status, shortcodes, frontmatter, links, structure)
- `--report-dir DIR`: Set report directory

### Examples

```bash
# Run quick health check
./doc-doctor.sh --check-level quick

# Focus on shortcode checks only
./doc-doctor.sh --focus-area shortcodes

# Generate markdown report
./doc-doctor.sh --output-format markdown

# Thorough check with all outputs
./doc-doctor.sh --check-level comprehensive --output-format all
```

## Check Levels

Doc Doctor offers three levels of checking:

1. **Quick**: Fast overview of critical issues
   - Samples approximately 20% of documents
   - Focuses on the most important checks
   - Ideal for frequent verification during work
   - Execution time: 30-60 seconds

2. **Standard** (Default): Balanced and comprehensive
   - Checks all documents
   - Performs core validation on status, shortcodes, frontmatter, etc.
   - Suitable for regular maintenance
   - Execution time: 1-3 minutes

3. **Comprehensive**: Deep analysis
   - Examines all aspects of documentation
   - Includes additional specialized modules
   - Performs advanced checks like style consistency
   - Best for periodic thorough review
   - Execution time: 5-10 minutes

## Focus Areas

Focus areas allow you to concentrate on specific aspects of documentation:

- `all`: Run all applicable checks
- `status`: Focus on document status metadata
- `shortcodes`: Focus on shortcode usage and templates
- `frontmatter`: Focus on front matter fields and values
- `links`: Focus on internal and external links
- `structure`: Focus on document structure and organization

## Reports

Doc Doctor can generate reports in multiple formats:

- **Terminal Output**: Colored, human-readable feedback
- **Markdown Reports**: Structured documentation with categorized findings
- **JSON Data**: Machine-readable format for integration with other tools

Reports are saved in the `./doc-reports` directory by default.

### Report Structure

Markdown reports follow this structure:

```markdown
# Doc Doctor Health Check Report

Generated on: YYYY-MM-DD HH:MM:SS

## Check Level: [level]
## Focus Area: [area]

## Findings

- ❌ **Invalid Status** in `content/project/example.md:5`: Status 'Draft123' is not a valid status
- ⚠️ **Unknown Shortcode** in `content/guides/guide.md:42`: Using unknown shortcode: 'custom'
- ✅ **Valid Status** in `content/architecture/overview.md`: Document has valid status: Active

## Summary

- Total Checks: 123
- Passed: 100
- Warnings: 18
- Critical Issues: 5
```

JSON reports follow this structure:

```json
[
  {
    "severity": "CRITICAL",
    "check": "Invalid Status",
    "message": "Status 'Draft123' is not a valid status",
    "file": "content/project/example.md",
    "line": "5"
  },
  {
    "severity": "WARNING",
    "check": "Unknown Shortcode",
    "message": "Using unknown shortcode: 'custom'",
    "file": "content/guides/guide.md",
    "line": "42"
  }
]
```

## Integration

Doc Doctor is designed to integrate with your documentation workflow:

### CI/CD Integration

Add Doc Doctor to your CI/CD pipeline:

```yaml
documentation_health:
  stage: test
  script:
    - ./doc-doctor.sh --check-level standard --output-format json
  artifacts:
    paths:
      - doc-reports/
```

### Pre-commit Hooks

Create a pre-commit hook for quick checks:

```bash
#!/bin/bash
# Pre-commit hook for documentation health
./doc-doctor.sh --check-level quick

# If critical issues are found, prevent commit
if [ $? -ne 0 ]; then
  echo "Documentation health check failed. Please fix critical issues before committing."
  exit 1
fi
```

### Scheduled Reviews

Set up scheduled comprehensive reviews:

```bash
# In your crontab
# Run comprehensive check every Monday at 9 AM
0 9 * * 1 cd /path/to/project && ./doc-doctor.sh --check-level comprehensive --output-format all
```

## Creating New Modules

Doc Doctor's modular architecture makes it easy to create new check modules:

1. Create a new script in the `doc-doctor-modules` directory
2. Follow the module template structure
3. Implement your specific checks
4. Create result summaries in the required format

### Module Template

```bash
#!/bin/bash

# Doc Doctor Module: [Your Module Name]
# [Brief description of what your module checks]

# Module information
MODULE_NAME="your-module-name"
TEMP_DIR="./.doc-doctor-temp"

# Custom variables for your checks
...

# Parse command line arguments and perform checks
...

# Create results file
cat > "$TEMP_DIR/${MODULE_NAME}-results.sh" << EOF
# [Your module] check results
your_module_total_checks=$total_checks
your_module_passed_checks=$passed_checks
your_module_warning_checks=$warning_checks
your_module_critical_checks=$critical_checks

# Update global counters
total_checks=\$((total_checks + $total_checks))
passed_checks=\$((passed_checks + $passed_checks))
warning_checks=\$((warning_checks + $warning_checks))
critical_checks=\$((critical_checks + $critical_checks))
EOF
```

## Troubleshooting

### Common Issues

1. **Module not found or not executable**
   - Ensure the module file exists in `doc-doctor-modules/`
   - Check file permissions (`chmod +x module.sh`)

2. **Parsing errors**
   - Check for proper quoting in front matter
   - Ensure markdown files use UTF-8 encoding

3. **Performance issues**
   - Use `--check-level quick` for faster checks
   - Focus on specific areas with `--focus-area`

### Debug Mode

Run with debug output:

```bash
DOCDOCTOR_DEBUG=1 ./doc-doctor.sh
```

## Example Output

### Terminal Output

```
========================================
     Doc Doctor
     Documentation Health Check System 1.0.0
==========================================

[INFO] Running health checks (Level: standard, Focus: all)
[INFO] Running module: status-check
[SUCCESS] Valid Status in content/architecture/overview.md: Document has valid status: Active
[WARNING] Missing Status in content/guides/example.md: Document is missing status field
[CRITICAL] Invalid Status in content/project/overview.md: Status 'Draft123' is not a valid status

[INFO] Status check complete!
[INFO] Total documents: 42
[SUCCESS] Valid status: 38
[WARNING] Missing status: 2
[CRITICAL] Invalid status: 2

[INFO] Running module: shortcode-check
...

[INFO] Health check complete!
======= Health Check Summary =======
Total Checks: 284
Passed: 245
Warnings: 28
Critical Issues: 11

Overall Health: Fair
Recommendation: Consider addressing warnings to improve documentation quality.
```

## Related Documentation

{{< related-docs >}}