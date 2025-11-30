# ChaosCraft: Enterprise Chaos Engineering Platform

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Go Version](https://img.shields.io/badge/go-1.21+-00ADD8?logo=go)](https://go.dev/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io/)

**ChaosCraft** is a production-grade chaos engineering platform for validating the resilience of distributed systems through controlled failure injection.

## 🎯 Project Status

**Phase**: MVP Development  
**Current Milestone**: Week 1-3 - Core Infrastructure

## ✨ Features

### Core Capabilities
- 🔥 **Kubernetes Pod Chaos**: Pod deletion, container kill, resource stress
- 🌐 **Network Chaos**: Latency injection, packet loss, network partitions
- 🛡️ **Blast Radius Control**: Automated safety mechanisms and progressive injection
- 📊 **Observability**: Prometheus metrics, Grafana dashboards, distributed tracing
- 🔄 **GitOps Integration**: ArgoCD/Flux support for declarative experiments
- 🚨 **Auto-Rollback**: Steady-state hypothesis validation with automated recovery

### Upcoming
- ☁️ Cloud provider chaos (AWS, GCP, Azure)
- 🗄️ Database fault injection
- 🎛️ Web UI for experiment management
- 📝 Experiment templates and cookbook

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Control Plane                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  REST API    │  │  gRPC Server │  │  CLI Tool    │      │
│  │  (Gin)       │  │              │  │  (Cobra)     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                                 │
│         └──────────────────┴─────────────────┐              │
│                                               │              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │        Orchestration Engine                          │   │
│  │  - Experiment Scheduler                              │   │
│  │  - Policy Evaluator                                  │   │
│  │  - Blast Radius Calculator                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────┐                                           │
│  │  PostgreSQL  │  State & Audit Logs                       │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ gRPC
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌──────▼──────┐  ┌────────▼────────┐
│  Chaos Agent   │  │ Chaos Agent │  │  Chaos Agent    │
│  (Node 1)      │  │ (Node 2)    │  │  (Node 3)       │
│                │  │             │  │                 │
│ - Pod Chaos    │  │ - Network   │  │ - Resource      │
│ - Health Check │  │   Chaos     │  │   Chaos         │
└────────────────┘  └─────────────┘  └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- [kind](https://kind.sigs.k8s.io/) v0.20+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.28+
- [Docker](https://www.docker.com/) v24+
- [Helm](https://helm.sh/) v3.12+
- [Go](https://go.dev/) 1.21+ (for local development)

### 1. Create Local Cluster

```bash
# Create 3-node kind cluster
make cluster-create

# Verify cluster
kubectl get nodes
```

### 2. Deploy Infrastructure

```bash
# Install ArgoCD
make argocd-install

# Deploy observability stack
make observability-install
```

### 3. Deploy ChaosCraft

```bash
# Build control plane
make build

# Deploy via Helm
make deploy
```

### 4. Run Your First Experiment

```bash
# Create experiment definition
cat > experiment.yaml <<EOF
apiVersion: chaos.chaoscraft.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-kill-demo
spec:
  selector:
    labelSelectors:
      app: nginx
  chaos:
    type: pod-kill
    podKill:
      signal: SIGTERM
      count: 1
  duration: 60s
  steadyState:
    promQL: "rate(http_requests_total{job='nginx'}[1m])"
    threshold: 0.95
EOF

# Apply experiment
kubectl apply -f experiment.yaml

# Watch experiment progress
kubectl get chaosexperiment pod-kill-demo -w
```

## 📂 Repository Structure

```
khaos-engine/
├── control-plane/          # Control plane Go service
│   ├── cmd/                # CLI and server entrypoints
│   ├── pkg/                # Core business logic
│   ├── api/                # REST/gRPC API definitions
│   └── Dockerfile          # Multi-stage Docker build
├── agents/                 # Chaos agents
│   ├── kubernetes/         # K8s operator (pod chaos)
│   ├── network/            # Network chaos agent
│   └── cloud/              # Cloud provider agents
├── charts/                 # Helm charts
│   ├── control-plane/      # Control plane chart
│   ├── chaos-agent/        # Agent chart
│   └── observability/      # Monitoring stack
├── infra/                  # Infrastructure as Code
│   ├── kind/               # kind cluster configs
│   ├── terraform/          # Cloud infrastructure
│   └── argocd/             # ArgoCD applications
├── docs/                   # Documentation
│   ├── architecture/       # Architecture diagrams
│   ├── guides/             # User guides
│   └── runbooks/           # Operational runbooks
├── .github/                # CI/CD workflows
└── Makefile                # Build automation
```

## 🛠️ Development

### Build Control Plane

```bash
cd control-plane
go mod download
go build -o bin/chaoscraft ./cmd/server
```

### Run Tests

```bash
make test              # Unit tests
make test-integration  # Integration tests
make test-e2e          # End-to-end tests
```

### Local Development

```bash
# Start control plane locally
make dev

# In another terminal, forward PostgreSQL
kubectl port-forward svc/postgres 5432:5432

# Run chaos agent locally
make agent-dev
```

## 📊 Observability

### Grafana Dashboards
- **ChaosCraft Overview**: [http://localhost:3000/d/chaoscraft-overview](http://localhost:3000/d/chaoscraft-overview)
- **Experiment Metrics**: [http://localhost:3000/d/chaoscraft-experiments](http://localhost:3000/d/chaoscraft-experiments)
- **Blast Radius**: [http://localhost:3000/d/chaoscraft-blast-radius](http://localhost:3000/d/chaoscraft-blast-radius)

### Prometheus Metrics
- Control Plane: `http://localhost:9090`
- Sample Queries:
  - `chaoscraft_experiments_total` - Total experiments run
  - `chaoscraft_rollbacks_total` - Auto-rollback count
  - `chaoscraft_blast_radius_score` - Current blast radius

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Chaos Mesh](https://chaos-mesh.org/)
- [Litmus Chaos](https://litmuschaos.io/)

## 📬 Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/khaos-engine/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/khaos-engine/discussions)

---

**⚠️ Disclaimer**: ChaosCraft is designed for controlled testing in non-production environments. Always start with dev/staging environments and implement proper safety controls before running chaos experiments in production.
