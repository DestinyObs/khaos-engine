# ChaosCraft - Project Roadmap

**Goal**: Build production-grade chaos engineering platform step-by-step

---

## Phase 1: Foundation - EKS Cluster (Week 1)

### What we're building
A working Kubernetes cluster on AWS EKS that we can deploy applications to.

### Tasks
1. Create `eksctl` cluster config (simple YAML)
2. Add Makefile targets for cluster lifecycle
3. Deploy and verify cluster

### Success criteria
- `kubectl get nodes` shows 3 nodes (1 control-plane, 2 workers)
- Can deploy a test nginx pod
- Understand EKS costs (~$4/day)

### Files to create
```
infra/
  eks/
    cluster.yaml          # eksctl config
Makefile                  # cluster-create, cluster-delete targets
```

---

## Phase 2: GitOps + Observability (Week 2)

### What we're building
ArgoCD for GitOps deployment + Prometheus/Grafana for monitoring.

### Tasks
1. Install ArgoCD
2. Deploy Prometheus + Grafana via ArgoCD
3. Create basic dashboards
4. Deploy demo application

### Success criteria
- ArgoCD UI accessible
- Grafana showing cluster metrics
- Demo app deployed via Git commit

### Files to create
```
manifests/
  argocd/
    install.yaml
  observability/
    prometheus.yaml
    grafana.yaml
apps/
  demo/
    deployment.yaml
    service.yaml
```

---

## Phase 3: Control Plane API (Weeks 3-4)

### What we're building
REST API that manages chaos experiments (create, list, run, stop).

### Tasks
1. Build Go REST API with Gin
2. PostgreSQL database + migrations
3. Basic CRUD endpoints
4. Dockerize + Helm chart

### Success criteria
- POST /api/experiments creates experiment
- GET /api/experiments lists all experiments
- API deployed to EKS cluster
- Database persists data

### Files to create
```
control-plane/
  cmd/
    server/
      main.go
  internal/
    api/
      handlers.go
      routes.go
    db/
      postgres.go
      migrations/
  Dockerfile
charts/
  control-plane/
    Chart.yaml
    values.yaml
    templates/
```

---

## Phase 4: Kubernetes Chaos Agent (Weeks 5-6)

### What we're building
Kubernetes operator that kills pods on command.

### Tasks
1. Create CRD (ChaosExperiment)
2. Build controller with kubebuilder
3. Implement pod deletion logic
4. Add safety checks (label selectors, PDB respect)

### Success criteria
- Create ChaosExperiment CR → pod gets deleted
- Only targets pods with specific labels
- Respects PodDisruptionBudgets

### Files to create
```
agents/
  kubernetes/
    api/
      v1alpha1/
        chaosexperiment_types.go
    controllers/
      chaosexperiment_controller.go
    config/
      crd/
      rbac/
    Dockerfile
charts/
  chaos-agent/
    Chart.yaml
    templates/
```

---

## Phase 5: Safety & Rollback (Weeks 7-8)

### What we're building
Blast radius controls + automated rollback when things go wrong.

### Tasks
1. Calculate blast radius (% of pods affected)
2. Steady-state hypothesis validation (Prometheus queries)
3. Auto-rollback on error rate spike
4. Progressive chaos (start small, increase gradually)

### Success criteria
- Experiment stops if >10% pods affected
- Auto-rollback when error rate >5%
- PromQL queries validate system health

### Files to create
```
control-plane/
  internal/
    safety/
      blast_radius.go
      hypothesis.go
      rollback.go
```

---

## Phase 6: Network Chaos (Weeks 9-10)

### What we're building
Inject network latency, packet loss, and bandwidth limits.

### Tasks
1. Network chaos module (using tc or toxiproxy)
2. Latency injection
3. Packet loss injection
4. Bandwidth throttling

### Success criteria
- Add 100ms latency between services
- 10% packet loss injection
- Measure impact with distributed tracing

### Files to create
```
agents/
  kubernetes/
    chaos/
      network/
        latency.go
        packet_loss.go
        bandwidth.go
```

---

## Phase 7: Advanced Observability (Week 11)

### What we're building
Distributed tracing + log aggregation.

### Tasks
1. Deploy Jaeger for tracing
2. Deploy Loki for logs
3. Tag traces with experiment IDs
4. Create chaos-specific Grafana dashboards

### Success criteria
- Trace requests through chaos injection
- Correlate logs with experiments
- Custom dashboards show blast radius, rollback events

### Files to create
```
manifests/
  observability/
    jaeger.yaml
    loki.yaml
    dashboards/
      chaos-overview.json
      blast-radius.json
```

---

## Phase 8: CI/CD & Portfolio (Week 12)

### What we're building
Automated testing + documentation + demo.

### Tasks
1. GitHub Actions pipeline (test, build, deploy)
2. Unit + integration tests
3. E2E tests with kind
4. Documentation + demo video

### Success criteria
- All tests pass in CI
- Automated Docker builds
- Portfolio-ready README
- 5-min demo video

### Files to create
```
.github/
  workflows/
    ci.yaml
    cd.yaml
control-plane/
  test/
    integration/
README.md (portfolio version)
docs/
  ARCHITECTURE.md
  API.md
```

---

## Key Principles

1. **One phase at a time** - Complete phase N before starting N+1
2. **Commit working code** - Small, frequent commits
3. **Test as you go** - Don't move forward with broken code
4. **Ask before creating** - No scaffolding without discussion
5. **Cost awareness** - Tear down cluster when not using

---

## Current Status

**Phase**: 0 (Setup)
**Next step**: Review project structure proposal
**Blocker**: None

