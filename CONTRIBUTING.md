# Contributing to ChaosCraft

Thank you for your interest in contributing to ChaosCraft! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to the Contributor Covenant [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior** vs actual behavior
- **Environment details** (OS, Kubernetes version, ChaosCraft version)
- **Logs and screenshots** if applicable

Use the bug report template when creating issues.

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** explaining why this enhancement would be useful
- **Proposed solution** with examples if possible
- **Alternatives considered**

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** described below
3. **Add tests** for any new functionality
4. **Update documentation** as needed
5. **Ensure all tests pass** (`make test`)
6. **Run linters** (`make lint`)
7. **Write clear commit messages** following conventional commits

#### Branch Naming

Use the following prefixes:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests
- `chore/` - Maintenance tasks

Example: `feature/network-latency-injection`

#### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(agent): add network latency injection

Implement tc-based network latency injection with configurable
jitter and distribution patterns.

Closes #123
```

## Development Setup

### Prerequisites

- Go 1.21+
- Docker 24+
- kind v0.20+
- kubectl 1.28+
- Helm 3.12+

### Local Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/khaos-engine.git
cd khaos-engine

# Create local cluster
make cluster-create

# Install dependencies
make deps

# Build control plane
make build

# Run tests
make test

# Deploy to local cluster
make deploy
```

### Running Tests

```bash
# Unit tests
make test

# Integration tests
make test-integration

# End-to-end tests
make test-e2e

# Test coverage
make test-coverage
```

### Code Quality

Before submitting a PR, ensure:

```bash
# Run linters
make lint

# Format code
make fmt

# Run security scan
make security-scan

# Check for vulnerabilities
make vulnerability-check
```

## Coding Standards

### Go Code

- Follow [Effective Go](https://golang.org/doc/effective_go.html)
- Use `gofmt` for formatting
- Use `golangci-lint` for linting
- Write table-driven tests
- Aim for >80% test coverage
- Document exported functions and types

Example:
```go
// ExperimentManager manages chaos experiments lifecycle
type ExperimentManager struct {
    store      storage.Store
    scheduler  scheduler.Scheduler
    logger     *zap.Logger
}

// CreateExperiment creates a new chaos experiment
// Returns the created experiment ID or error
func (m *ExperimentManager) CreateExperiment(ctx context.Context, req *CreateRequest) (string, error) {
    // Implementation
}
```

### Kubernetes Manifests

- Use declarative YAML
- Include resource requests/limits
- Add appropriate labels and annotations
- Use namespaces for isolation
- Document custom resources

### Helm Charts

- Follow [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- Use semantic versioning
- Include comprehensive `values.yaml`
- Add chart tests
- Document all values

### Documentation

- Use clear, concise language
- Include code examples
- Add diagrams for complex concepts
- Keep README up to date
- Document breaking changes

## Project Structure

```
khaos-engine/
├── control-plane/          # Control plane service
│   ├── cmd/                # Entrypoints
│   ├── pkg/                # Business logic
│   │   ├── api/            # API handlers
│   │   ├── orchestrator/   # Experiment orchestration
│   │   ├── storage/        # Data persistence
│   │   └── policy/         # Policy evaluation
│   └── test/               # Tests
├── agents/                 # Chaos agents
│   ├── kubernetes/         # K8s operator
│   ├── network/            # Network chaos
│   └── cloud/              # Cloud provider agents
├── charts/                 # Helm charts
├── infra/                  # Infrastructure code
├── docs/                   # Documentation
└── .github/                # CI/CD workflows
```

## Release Process

1. Create a release branch: `release/v0.1.0`
2. Update version numbers
3. Update CHANGELOG.md
4. Create PR to `main`
5. After merge, tag the release
6. GitHub Actions will build and publish artifacts

## Getting Help

- **Documentation**: Check [docs/](docs/)
- **Issues**: Search existing [GitHub Issues](https://github.com/yourusername/khaos-engine/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/yourusername/khaos-engine/discussions)

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation

Thank you for contributing to ChaosCraft! 🎉
