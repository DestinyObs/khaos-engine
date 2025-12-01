# ChaosCraft - Project Structure

```
khaos-engine/
│
├── .github/
│   └── workflows/
│       ├── ci.yaml              # CI pipeline (test, lint, build)
│       └── cd.yaml              # CD pipeline (deploy to staging/prod)
│
├── control-plane/               # Go REST API + gRPC server
│   ├── cmd/
│   │   └── server/
│   │       └── main.go          # Entry point
│   ├── internal/
│   │   ├── api/                 # HTTP handlers
│   │   │   ├── handlers.go
│   │   │   └── routes.go
│   │   ├── grpc/                # gRPC server for agents
│   │   │   └── server.go
│   │   ├── db/                  # Database layer
│   │   │   ├── postgres.go
│   │   │   └── migrations/
│   │   ├── models/              # Data models
│   │   │   └── experiment.go
│   │   └── safety/              # Safety mechanisms
│   │       ├── blast_radius.go
│   │       ├── hypothesis.go
│   │       └── rollback.go
│   ├── test/
│   │   ├── unit/
│   │   └── integration/
│   ├── Dockerfile
│   └── go.mod
│
├── agents/
│   └── kubernetes/              # K8s chaos operator
│       ├── api/
│       │   └── v1alpha1/
│       │       └── chaosexperiment_types.go  # CRD definition
│       ├── controllers/
│       │   └── chaosexperiment_controller.go # Reconciliation logic
│       ├── chaos/               # Chaos implementations
│       │   ├── pod/
│       │   │   └── killer.go    # Pod deletion
│       │   └── network/
│       │       ├── latency.go
│       │       └── packet_loss.go
│       ├── config/
│       │   ├── crd/             # CRD manifests
│       │   └── rbac/            # ServiceAccount, Role, RoleBinding
│       ├── Dockerfile
│       └── go.mod
│
├── charts/                      # Helm charts
│   ├── control-plane/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       └── configmap.yaml
│   ├── chaos-agent/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   └── observability/           # Prometheus, Grafana, Jaeger, Loki
│       ├── Chart.yaml
│       └── values.yaml
│
├── manifests/                   # Raw K8s manifests
│   ├── argocd/
│   │   └── install.yaml
│   ├── observability/
│   │   ├── prometheus.yaml
│   │   ├── grafana.yaml
│   │   ├── jaeger.yaml
│   │   └── loki.yaml
│   └── demo/                    # Demo applications for testing
│       └── nginx-app.yaml
│
├── infra/
│   └── eks/
│       └── cluster.yaml         # eksctl cluster config
│
├── scripts/
│   ├── setup-cluster.sh         # Cluster creation helper
│   ├── deploy-observability.sh
│   └── e2e-test.sh              # End-to-end test runner
│
├── docs/
│   ├── ARCHITECTURE.md          # System architecture
│   ├── API.md                   # API documentation
│   ├── DEVELOPMENT.md           # Development guide
│   └── dashboards/              # Grafana dashboard JSONs
│
├── examples/
│   └── experiments/             # Example chaos experiments
│       ├── pod-kill.yaml
│       ├── network-latency.yaml
│       └── cpu-stress.yaml
│
├── Makefile                     # Development commands
├── ROADMAP.md                   # This file
├── README.md                    # Project overview
└── .gitignore

```

---

## Phase-by-Phase File Creation

### Phase 1 (Week 1): EKS Cluster
**Create only:**
- `infra/eks/cluster.yaml`
- `Makefile` (cluster-create, cluster-delete)
- `.gitignore`
- `README.md` (basic)

### Phase 2 (Week 2): GitOps + Observability
**Create only:**
- `manifests/argocd/install.yaml`
- `manifests/observability/prometheus.yaml`
- `manifests/observability/grafana.yaml`
- `manifests/demo/nginx-app.yaml`
- Update `Makefile` (argocd-install, observability-install)

### Phase 3 (Weeks 3-4): Control Plane
**Create only:**
- `control-plane/` directory structure
- `control-plane/cmd/server/main.go`
- `control-plane/internal/api/`
- `control-plane/internal/db/`
- `control-plane/Dockerfile`
- `charts/control-plane/`

### Phase 4 (Weeks 5-6): Chaos Agent
**Create only:**
- `agents/kubernetes/` directory structure
- CRD definition
- Controller
- `charts/chaos-agent/`

... and so on for remaining phases.

---

## Folder Philosophy

1. **control-plane/** - Brain of the system (API, database, orchestration)
2. **agents/** - Hands of the system (execute chaos on clusters)
3. **charts/** - Packaging (how we deploy everything)
4. **manifests/** - Raw K8s resources (for things we don't Helm)
5. **infra/** - Cluster definitions (eksctl configs)
6. **docs/** - Knowledge base
7. **examples/** - Working examples for users

---

## What Gets Created When

- **Week 1**: 5 files (cluster setup)
- **Week 2**: 10 files (GitOps + monitoring)
- **Week 3-4**: 20 files (control plane)
- **Week 5-6**: 15 files (chaos agent)
- **Week 7-8**: 10 files (safety)
- **Week 9-10**: 8 files (network chaos)
- **Week 11**: 10 files (observability)
- **Week 12**: 15 files (CI/CD + docs)

**Total**: ~100 files over 12 weeks

