# ChaosCraft

**Production-grade Chaos Engineering Platform for Kubernetes**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.28-blue.svg)](https://kubernetes.io/)
[![Go](https://img.shields.io/badge/go-1.21-blue.svg)](https://golang.org/)

> *"It is not enough for code to work." - Robert C. Martin*

ChaosCraft helps you validate your system's resilience by intentionally injecting failures in a controlled, safe manner. Built for DevOps engineers who want to learn chaos engineering while creating a portfolio-worthy project.

---

## Project Goals

This is a **DevOps portfolio project** designed to demonstrate:
- Advanced Kubernetes operations (operators, CRDs, controllers)
- Production-grade infrastructure automation
- Site Reliability Engineering practices
- Complete CI/CD pipelines
- Observability and monitoring at scale
- Security best practices (RBAC, IRSA, encryption)

**Timeline**: 8-12 weeks  
**Budget**: $50-150/month (AWS free tier + spot instances)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Control Plane                         │
│  (REST API + gRPC Server - Go)                         │
│  • Experiment orchestration                            │
│  • Policy evaluation                                   │
│  • Blast radius control                                │
│  • Automated rollback                                  │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
┌───────▼──────┐    ┌────────▼────────┐
│ Kubernetes   │    │  Observability  │
│ Chaos Agent  │    │     Stack       │
│              │    │                 │
│ • Pod chaos  │    │ • Prometheus    │
│ • Network    │    │ • Grafana       │
│ • Resources  │    │ • Jaeger        │
└──────────────┘    │ • Loki          │
                    └─────────────────┘
```

---

## Current Status: Phase 1 - Infrastructure

**What's Done:**
- EKS cluster configuration with eksctl
- Multi-node groups (system + chaos workers)
- Spot instances for 70% cost savings
- Proper workload isolation with taints/labels
- Cost optimization strategies

**Next Up (Phase 2):**
- ArgoCD installation for GitOps
- Prometheus + Grafana deployment
- Demo application for chaos experiments

See [ROADMAP.md](ROADMAP.md) for full plan.

---

## Quick Start

### Prerequisites

```bash
# Required tools
aws --version       # AWS CLI v2+
eksctl version      # eksctl 0.150+
kubectl version     # kubectl 1.28+

# Configure AWS credentials
aws configure
```

### 1. Create EKS Cluster

```bash
# Clone repository
git clone https://github.com/destinyobs/khaos-engine.git
cd khaos-engine

# Create cluster (~15-20 min)
make cluster-create

# Verify nodes
kubectl get nodes
```

Expected output:
```
NAME                          STATUS   ROLES    AGE
ip-10-0-1-123.ec2.internal   Ready    <none>   5m   # system node
ip-10-0-2-45.ec2.internal    Ready    <none>   5m   # chaos worker
ip-10-0-2-67.ec2.internal    Ready    <none>   5m   # chaos worker
```

### 2. Verify Cluster

```bash
# Check node labels
kubectl get nodes --show-labels | grep chaos-enabled

# View cluster info
make cluster-info
```

### 3. Clean Up (Important!)

```bash
# Delete cluster when done to avoid charges
make cluster-delete
```

---

## Cost Management

**Estimated Costs** (running 24/7):
- **Daily**: ~$5.15
- **Monthly**: ~$157

**Cost Breakdown:**
| Component | Daily | Monthly |
|-----------|-------|---------|
| EKS Control Plane | $2.40 | $73 |
| NAT Gateway | $1.05 | $32 |
| System node (t3.medium) | $1.00 | $30 |
| Chaos workers (2x t3.small spot) | $0.30 | $9 |
| Storage & logs | $0.40 | $13 |

**Cost Optimization:**
- Delete cluster when not using: `make cluster-delete`
- Use spot instances for workers (already configured)
- Single NAT gateway (already configured)
- Short CloudWatch log retention (already configured)

See [infra/eks/README.md](infra/eks/README.md) for details.

---

## Documentation

- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Complete file structure
- **[ROADMAP.md](ROADMAP.md)** - 8-phase development plan
- **[infra/eks/README.md](infra/eks/README.md)** - EKS cluster details

---

## Technology Stack

**Infrastructure:**
- AWS EKS (Kubernetes 1.28)
- eksctl for cluster management
- Spot instances for cost optimization

**Backend** (Coming in Phase 3):
- Go 1.21+ (control plane API)
- PostgreSQL (state management)
- gRPC (agent communication)

**Observability** (Coming in Phase 2):
- Prometheus (metrics)
- Grafana (visualization)
- Jaeger (distributed tracing)
- Loki (log aggregation)

**DevOps** (Coming in Phase 8):
- GitHub Actions (CI/CD)
- Helm (packaging)
- ArgoCD (GitOps)

---

## Learning Objectives

By building this project, you'll learn:

1. **Kubernetes Deep Dive**
   - Custom Resource Definitions (CRDs)
   - Operators and controllers
   - RBAC and security
   - Multi-tenant workload isolation

2. **AWS & Cloud Infrastructure**
   - EKS cluster design
   - VPC networking
   - IAM Roles for Service Accounts (IRSA)
   - Cost optimization strategies

3. **Site Reliability Engineering**
   - Chaos engineering principles
   - Blast radius control
   - Automated rollback mechanisms
   - Steady-state hypothesis validation

4. **DevOps Practices**
   - Infrastructure as Code
   - GitOps workflows
   - CI/CD automation
   - Observability and monitoring

5. **Go Programming**
   - REST API development
   - gRPC services
   - Kubernetes client-go
   - Concurrent programming

---

## Project Milestones

- [x] **Phase 1** (Week 1): EKS cluster running
- [ ] **Phase 2** (Week 2): GitOps + Observability
- [ ] **Phase 3** (Weeks 3-4): Control Plane API
- [ ] **Phase 4** (Weeks 5-6): Kubernetes Chaos Agent
- [ ] **Phase 5** (Weeks 7-8): Safety & Rollback
- [ ] **Phase 6** (Weeks 9-10): Network Chaos
- [ ] **Phase 7** (Week 11): Advanced Observability
- [ ] **Phase 8** (Week 12): CI/CD & Portfolio Polish

---

## Contributing

This is a personal learning project, but feedback and suggestions are welcome!

1. Open an issue to discuss changes
2. Fork the repository
3. Create a feature branch
4. Submit a pull request

---

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

---

## Acknowledgments

Inspired by:
- [Netflix Chaos Monkey](https://netflix.github.io/chaosmonkey/)
- [Chaos Mesh](https://chaos-mesh.org/)
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Google SRE Book](https://sre.google/)

---

## Contact

**Destiny Obueh**  
- GitHub: [@destinyobs](https://github.com/destinyobs)
- Email: destinyobueh14@gmail.com

---

<div align="center">

**Built for learning DevOps and Site Reliability Engineering**

Remember to run `make cluster-delete` when done to avoid charges.

</div>
