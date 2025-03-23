# Contributing to the Multi-Agent Control Platform

Thank you for your interest in contributing to the MCP project! This document provides guidelines and workflows to make the contribution process smooth and effective.

## Code of Conduct

This project adheres to a Code of Conduct that sets expectations for participation in our community. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

When reporting bugs, please include:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior and actual behavior
- Screenshots if applicable
- Environment details (OS, JDK/Python versions, etc.)

Use the issue template provided in the repository when creating new issues.

### Suggesting Enhancements

Enhancement suggestions are welcome! When suggesting enhancements:

- Use a clear, descriptive title
- Provide a step-by-step description of the enhancement
- Explain why this enhancement would be useful to most users
- Include mockups or diagrams if applicable

### Pull Requests

When submitting pull requests:

1. Fork the repository and create a new branch from `main`
2. Make your changes
3. Add or update tests as necessary
4. Ensure all tests pass
5. Update documentation to reflect your changes
6. Submit the pull request with a clear description of the changes

## Development Workflow

### Setting Up Your Development Environment

Before you start, make sure you have set up your development environment according to the [Environment Setup Guide](environment-setup.md).

### Branching Strategy

- `main` - The primary branch containing stable code
- `feature/*` - Feature branches for new functionality
- `bugfix/*` - Branches for bug fixes
- `docs/*` - Branches for documentation updates

### Commit Messages

Follow these conventions for commit messages:

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests after the first line

Example:
```
Add USB device hot-plug detection to camera agent

This enhances the camera agent to detect when USB devices are connected or 
disconnected while the agent is running. Previously, devices were only 
detected during initialization.

Fixes #123
```

### Code Style

#### Kotlin/Java Code

- Follow the standard Kotlin coding conventions
- Use 4 spaces for indentation (no tabs)
- Maximum line length of 100 characters
- Use meaningful variable and function names
- Document public APIs with KDoc comments

#### Python Code

- Follow PEP 8 style guide
- Use 4 spaces for indentation (no tabs)
- Use type hints whenever possible
- Document functions with docstrings

### Testing Guidelines

- Write unit tests for all new functionality
- Ensure existing tests pass with your changes
- For Kotlin code, use JUnit and MockK for testing
- For Python code, use pytest
- Include both positive and negative test cases
- Mock external dependencies when appropriate

## Local Development Process

1. Choose an issue to work on or create a new one
2. Create a new branch
3. Make your changes following the code style guidelines
4. Write tests for your changes
5. Run the local test suite
6. Update documentation as needed
7. Submit a pull request

## Review Process

All pull requests will be reviewed by at least one maintainer. The review process checks for:

1. Code quality and adherence to style guidelines
2. Appropriate test coverage
3. Documentation updates
4. Compatibility with existing code
5. Performance considerations

Reviewers may suggest changes or improvements before your PR is merged.

## Building and Testing

### Building the Kotlin Components

```bash
# Build all components
./gradlew build

# Run tests
./gradlew test

# Run specific tests
./gradlew :mcp-core:test --tests "com.example.mcp.AgentStateMachineTest"
```

### Testing Python Components

```bash
# Navigate to the Python agent directory
cd agents/python-processor

# Activate the virtual environment
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Run tests
pytest
```

### Running the Complete System

To test your changes in the context of the entire system:

1. Start NATS server
2. Run all components locally or via containers
3. Verify your changes work as expected in the integrated environment

## Documentation

When contributing, please update the relevant documentation:

- Update code comments and API documentation 
- Modify README.md if introducing new components or major changes
- Update architecture diagrams if changing system structure
- Add to the appropriate guide if introducing new workflows

## Release Process

The release process is managed by the core maintainers and follows these steps:

1. Version bump in build files
2. Update CHANGELOG.md with new features and fixes
3. Create a release branch
4. Run final tests and quality checks
5. Tag the release
6. Build release artifacts
7. Publish release notes

## Getting Help

If you have questions or need help with the contribution process:

- Start a discussion in the repository
- Ask questions in the relevant issue
- Contact the project maintainers

## License

By contributing to this project, you agree that your contributions will be licensed under the project's MIT License.