# 🏗️ ChaosCraft Build Phases: Step-by-Step Guide

**Estimated Timeline:** 8-12 weeks (solo) | 4-6 weeks (team of 2-3)

This guide breaks down the entire build into manageable phases with clear **checkpoints** and **verification steps**.

---

## 📋 Pre-Flight Checklist

Before starting, ensure you have:

✅ **Tools Installed:**
- [ ] Docker Desktop (v24+)
- [ ] kind (v0.20+) - `go install sigs.k8s.io/kind@latest`
- [ ] kubectl (v1.28+) - `curl -LO https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl`
- [ ] Helm (v3.12+) - `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`
- [ ] Go (v1.21+) - `https://go.dev/doc/install`
- [ ] Git - `sudo apt install git`

✅ **Accounts Setup:**
- [ ] GitHub account with SSH key configured
- [ ] Docker Hub account (optional, for publishing images)

✅ **System Requirements:**
- [ ] 8GB+ RAM
- [ ] 20GB+ free disk space
- [ ] Linux/macOS/WSL2 (Windows)

---

## 🎯 Phase 0: Repository Setup (30 mins)

### Step 0.1: Create GitHub Repository

Follow `SETUP_GITHUB.md` to:
1. Set environment variables
2. Initialize Git locally
3. Create GitHub repo via API
4. Push initial commit

**Verification:**
```bash
# Check remote
git remote -v

# Visit your repo
echo "https://github.com/destinyobs/khaos-engine"
```

Expected: Repository visible on GitHub with all files

---

## 🔧 Phase 1: Local Cluster Setup (1-2 hours)

### Step 1.1: Create kind Cluster

```bash
# Create cluster
make cluster-create

# Wait for nodes to be ready (1-2 minutes)
kubectl get nodes
```

**Expected Output:**
```
NAME                       STATUS   ROLES           AGE   VERSION
chaoscraft-control-plane   Ready    control-plane   60s   v1.28.0
chaoscraft-worker          Ready    <none>          40s   v1.28.0
chaoscraft-worker2         Ready    <none>          40s   v1.28.0
```

**Verification Commands:**
```bash
# Check cluster info
kubectl cluster-info

# Check system pods
kubectl get pods -n kube-system

# Verify metrics-server
kubectl top nodes
```

**Troubleshooting:**
- **"cluster already exists"** → `kind delete cluster --name chaoscraft`, then retry
- **"context not found"** → `kubectl config use-context kind-chaoscraft`
- **"metrics not available"** → Wait 30s, metrics-server takes time to start

---

### Step 1.2: Verify Cluster Networking

```bash
# Deploy test pod
kubectl run test-nginx --image=nginx:alpine

# Wait for pod
kubectl wait --for=condition=Ready pod/test-nginx --timeout=60s

# Check connectivity
kubectl exec test-nginx -- wget -qO- http://kubernetes.default.svc
```

**Expected:** HTML response from Kubernetes API

**Cleanup:**
```bash
kubectl delete pod test-nginx
```

---

### Step 1.3: Test Port Forwarding

```bash
# Forward Kubernetes dashboard (optional)
kubectl proxy --port=8001 &

# Access in browser
curl http://localhost:8001/api/v1/namespaces/kube-system/services
```

**Expected:** JSON list of services

---

## 🔄 Phase 2: GitOps Setup (1 hour)

### Step 2.1: Install ArgoCD

```bash
# Install ArgoCD
make argocd-install

# Wait for pods (2-3 minutes)
kubectl wait --for=condition=available --timeout=300s \
  -n argocd deployment/argocd-server
```

**Verification:**
```bash
kubectl get pods -n argocd
```

**Expected:** All pods in `Running` state

---

### Step 2.2: Access ArgoCD UI

```bash
# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)

echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"

# Port-forward UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Open browser:** https://localhost:8080
- Accept self-signed certificate warning
- Login with credentials above

**Expected:** ArgoCD dashboard visible

---

### Step 2.3: Create ArgoCD Application (Manual - for now)

We'll automate this later. For now, verify ArgoCD is working:

**Verification:**
```bash
# Check ArgoCD components
kubectl get applications -n argocd

# Should be empty for now
```

---

## 📊 Phase 3: Observability Stack (2 hours)

### Step 3.1: Install Prometheus + Grafana

```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
make observability-install

# Wait for pods (5-7 minutes, downloads large images)
kubectl wait --for=condition=available --timeout=600s \
  -n monitoring deployment/prometheus-grafana
```

**Verification:**
```bash
kubectl get pods -n monitoring
```

**Expected:** ~15 pods in `Running` state:
- prometheus-kube-prometheus-prometheus-0
- prometheus-grafana-xxx
- prometheus-kube-state-metrics-xxx
- prometheus-prometheus-node-exporter-xxx (3 replicas)

---

### Step 3.2: Access Grafana

```bash
# Get Grafana password
GRAFANA_PASSWORD=$(kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d)

echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"

# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Open browser:** http://localhost:3000

**Verification Steps:**
1. Login with credentials
2. Navigate to **Explore** (left sidebar, compass icon)
3. Select **Prometheus** data source
4. Run query: `up`
5. Click **Run Query**

**Expected:** Graph showing all Prometheus targets (value: 1 = up)

---

### Step 3.3: Verify Prometheus Targets

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Open browser:** http://localhost:9090

Navigate to **Status → Targets**

**Expected:** All targets in `UP` state (green)

---

### Step 3.4: Install Loki (Logs)

```bash
# Install Loki
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=false
```

**Verification:**
```bash
kubectl get pods -n monitoring | grep loki
```

**Expected:**
- loki-0 (Running)
- loki-promtail-xxx (Running on each node)

---

### Step 3.5: Configure Loki in Grafana

1. Grafana → **Configuration** → **Data Sources** → **Add data source**
2. Select **Loki**
3. URL: `http://loki:3100`
4. Click **Save & Test**

**Expected:** "Data source is working" (green checkmark)

**Test Query:**
1. **Explore** → Select **Loki**
2. Query: `{namespace="kube-system"}`
3. Click **Run Query**

**Expected:** Logs from kube-system pods

---

## 🚀 Phase 4: Build Control Plane (2-3 hours)

### Step 4.1: Download Go Dependencies

```bash
cd control-plane

# Download dependencies
go mod download

# Verify
go mod verify
```

**Expected:** "all modules verified"

---

### Step 4.2: Build Control Plane Binary

```bash
# Build
go build -o bin/chaoscraft ./cmd/server

# Verify
./bin/chaoscraft --help
```

**Expected:** Binary exists and runs (will exit immediately without DB)

---

### Step 4.3: Run PostgreSQL Locally (Docker)

```bash
# Start PostgreSQL
docker run -d \
  --name chaoscraft-postgres \
  -e POSTGRES_USER=chaoscraft \
  -e POSTGRES_PASSWORD=chaoscraft \
  -e POSTGRES_DB=chaoscraft \
  -p 5432:5432 \
  postgres:15-alpine

# Wait for startup
sleep 5

# Test connection
docker exec chaoscraft-postgres psql -U chaoscraft -c "SELECT version();"
```

**Expected:** PostgreSQL version info

---

### Step 4.4: Run Database Migrations

```bash
# Set database URL
export DATABASE_URL="postgres://chaoscraft:chaoscraft@localhost:5432/chaoscraft?sslmode=disable"

# Install migrate tool
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run migrations
migrate -path migrations -database "$DATABASE_URL" up
```

**Expected:** "1/u init_schema (success)"

**Verify:**
```bash
docker exec chaoscraft-postgres psql -U chaoscraft -d chaoscraft -c "\dt"
```

**Expected:** Tables listed:
- experiments
- experiment_runs
- audit_logs
- schema_migrations

---

### Step 4.5: Run Control Plane Locally

```bash
# Set environment variables
export DATABASE_URL="postgres://chaoscraft:chaoscraft@localhost:5432/chaoscraft?sslmode=disable"
export PORT=8080
export LOG_LEVEL=info
export ENVIRONMENT=development

# Run server
./bin/chaoscraft
```

**Expected Output:**
```json
{"level":"info","ts":1234567890.123,"caller":"main.go:30","msg":"starting control plane","service":"chaoscraft-control-plane","version":"0.1.0"}
{"level":"info","ts":1234567890.456,"caller":"postgres.go:45","msg":"connected to PostgreSQL database"}
{"level":"info","ts":1234567890.789,"caller":"main.go:95","msg":"starting HTTP server","port":8080}
```

---

### Step 4.6: Test API Endpoints (New Terminal)

```bash
# Health check
curl http://localhost:8080/health

# Expected: {"status":"healthy","service":"chaoscraft-control-plane","version":"0.1.0"}

# Readiness check
curl http://localhost:8080/ready

# Expected: {"status":"ready","service":"chaoscraft-control-plane","version":"0.1.0"}

# Metrics
curl http://localhost:8080/metrics

# Expected: Prometheus metrics (text format)

# List experiments (empty)
curl http://localhost:8080/api/v1/experiments

# Expected: {"experiments":[],"total":0}

# Create experiment (stub)
curl -X POST http://localhost:8080/api/v1/experiments \
  -H "Content-Type: application/json" \
  -d '{
    "name": "test-experiment",
    "description": "Test chaos experiment"
  }'

# Expected: {"id":"exp-123","status":"created","message":"Experiment created successfully"}
```

**All tests pass?** ✅ Control plane is working!

**Stop the server:** `Ctrl+C`

---

### Step 4.7: Run Unit Tests

```bash
# Run all tests
go test -v ./...

# Run with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Open coverage report
xdg-open coverage.html  # Linux
open coverage.html      # macOS
```

**Expected:** Tests pass (currently minimal, will expand later)

---

## 🐳 Phase 5: Containerize & Deploy (2 hours)

### Step 5.1: Build Docker Image

```bash
# Build control plane image
docker build -t chaoscraft/control-plane:latest ./control-plane

# Verify
docker images | grep chaoscraft
```

**Expected:** Image size ~10-15MB

---

### Step 5.2: Load Image into kind

```bash
# Load image into cluster
kind load docker-image chaoscraft/control-plane:latest --name chaoscraft

# Verify (on one of the nodes)
docker exec chaoscraft-worker crictl images | grep chaoscraft
```

**Expected:** Image present in node's local registry

---

### Step 5.3: Deploy PostgreSQL to Cluster

```bash
# Create namespace
kubectl create namespace chaoscraft

# Install PostgreSQL via Helm
helm install chaoscraft-postgresql bitnami/postgresql \
  --namespace chaoscraft \
  --set auth.username=chaoscraft \
  --set auth.password=chaoscraft \
  --set auth.database=chaoscraft \
  --set primary.persistence.size=1Gi

# Wait for pod
kubectl wait --for=condition=Ready pod/chaoscraft-postgresql-0 \
  -n chaoscraft --timeout=180s
```

**Verification:**
```bash
kubectl get pods -n chaoscraft
```

**Expected:** chaoscraft-postgresql-0 (Running)

---

### Step 5.4: Deploy Control Plane via Helm

```bash
# Deploy
helm install chaoscraft-control-plane charts/control-plane \
  --namespace chaoscraft \
  --set image.tag=latest \
  --set image.pullPolicy=Never

# Wait for pod
kubectl wait --for=condition=available --timeout=180s \
  -n chaoscraft deployment/chaoscraft-control-plane
```

**Verification:**
```bash
kubectl get pods -n chaoscraft
kubectl logs -n chaoscraft deployment/chaoscraft-control-plane
```

**Expected:** Pod running, logs show "starting HTTP server"

---

### Step 5.5: Test Control Plane in Cluster

```bash
# Port-forward service
kubectl port-forward -n chaoscraft svc/chaoscraft-control-plane 8080:8080 &

# Test endpoints
curl http://localhost:8080/health
curl http://localhost:8080/ready
curl http://localhost:8080/api/v1/experiments
```

**Expected:** Same responses as local testing

---

## 🤖 Phase 6: Build Chaos Agent (3-4 hours)

### Step 6.1: Create Agent Directory Structure

```bash
mkdir -p agents/kubernetes/{cmd/agent,pkg/{agent,chaos}}
```

---

### Step 6.2: Implement Pod Kill Agent

Create `agents/kubernetes/pkg/chaos/pod_kill.go`:

```go
package chaos

import (
    "context"
    "fmt"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/client-go/kubernetes"
)

type PodKillChaos struct {
    clientset *kubernetes.Clientset
}

func NewPodKillChaos(clientset *kubernetes.Clientset) *PodKillChaos {
    return &PodKillChaos{clientset: clientset}
}

func (p *PodKillChaos) Execute(ctx context.Context, namespace, labelSelector string) error {
    // List pods matching selector
    pods, err := p.clientset.CoreV1().Pods(namespace).List(ctx, metav1.ListOptions{
        LabelSelector: labelSelector,
    })
    if err != nil {
        return fmt.Errorf("failed to list pods: %w", err)
    }

    if len(pods.Items) == 0 {
        return fmt.Errorf("no pods found matching selector: %s", labelSelector)
    }

    // Kill first pod (random in production)
    pod := pods.Items[0]
    err = p.clientset.CoreV1().Pods(namespace).Delete(ctx, pod.Name, metav1.DeleteOptions{})
    if err != nil {
        return fmt.Errorf("failed to delete pod %s: %w", pod.Name, err)
    }

    fmt.Printf("Killed pod: %s/%s\n", namespace, pod.Name)
    return nil
}
```

**Explanation:**
- Uses `client-go` to interact with Kubernetes API
- Lists pods by label selector
- Deletes first matching pod (simulating chaos)
- Production: randomize, respect blast radius, dry-run mode

---

### Step 6.3: Create Agent Main

Create `agents/kubernetes/cmd/agent/main.go`:

```go
package main

import (
    "context"
    "fmt"
    "os"
    "path/filepath"

    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
    "k8s.io/client-go/tools/clientcmd"
)

func main() {
    // Create Kubernetes client
    clientset, err := getKubernetesClient()
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }

    // Test: Kill a pod
    ctx := context.Background()
    
    // Example usage (hardcoded for demo)
    namespace := "demo"
    labelSelector := "app=nginx"
    
    chaos := NewPodKillChaos(clientset)
    if err := chaos.Execute(ctx, namespace, labelSelector); err != nil {
        fmt.Fprintf(os.Stderr, "Chaos execution failed: %v\n", err)
        os.Exit(1)
    }

    fmt.Println("Chaos experiment completed successfully!")
}

func getKubernetesClient() (*kubernetes.Clientset, error) {
    // Try in-cluster config first
    config, err := rest.InClusterConfig()
    if err != nil {
        // Fall back to kubeconfig
        kubeconfig := filepath.Join(os.Getenv("HOME"), ".kube", "config")
        config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
        if err != nil {
            return nil, err
        }
    }

    return kubernetes.NewForConfig(config)
}
```

---

### Step 6.4: Create Agent go.mod

```bash
cd agents/kubernetes

cat > go.mod <<EOF
module github.com/chaoscraft/chaos-agent

go 1.21

require (
    k8s.io/api v0.29.0
    k8s.io/apimachinery v0.29.0
    k8s.io/client-go v0.29.0
)
EOF

go mod tidy
```

---

### Step 6.5: Build and Test Agent Locally

```bash
# Build
go build -o bin/chaos-agent ./cmd/agent

# Deploy demo app first
kubectl create namespace demo
kubectl apply -f ../../examples/demo-app/deployment.yaml

# Wait for pods
kubectl wait --for=condition=Ready pod -l app=nginx -n demo --timeout=60s

# Check pods before chaos
kubectl get pods -n demo

# Run agent
./bin/chaos-agent

# Check pods after chaos
kubectl get pods -n demo
```

**Expected:** One nginx pod deleted, new pod created (Deployment self-heals)

---

## 🎭 Phase 7: End-to-End Demo (1 hour)

### Step 7.1: Deploy Demo Application

```bash
make demo-setup
```

**Verification:**
```bash
kubectl get pods -n demo
```

**Expected:** 3 nginx pods running

---

### Step 7.2: Create Chaos Experiment CRD (Manual)

```bash
kubectl apply -f examples/experiments/pod-kill-demo.yaml
```

**Note:** CRD doesn't exist yet - will implement operator in next phase

---

### Step 7.3: Manual Chaos Test

```bash
# Baseline: Check pods
kubectl get pods -n demo

# Run chaos agent
cd agents/kubernetes
./bin/chaos-agent

# Verify one pod killed
kubectl get pods -n demo

# Wait for self-healing (30s)
sleep 30
kubectl get pods -n demo
```

**Expected:** All 3 pods back to Running

---

### Step 7.4: Monitor with Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**In Grafana:**
1. Explore → Prometheus
2. Query: `kube_pod_status_phase{namespace="demo"}`
3. **Time range:** Last 5 minutes
4. **Graph:** Should show pod transitions (0 → 1)

---

## ✅ Phase 8: Verification & Documentation (2 hours)

### Step 8.1: Run E2E Tests

```bash
# From project root
chmod +x scripts/e2e-test.sh
./scripts/e2e-test.sh
```

**Expected:** All tests pass

---

### Step 8.2: Create Architecture Diagram

Use draw.io or mermaid to create diagram showing:
- Control Plane
- Chaos Agents
- Observability Stack
- Data flow

Save as `docs/architecture/system-diagram.png`

---

### Step 8.3: Record Demo Video

Record 5-minute demo showing:
1. Cluster setup (`make cluster-create`)
2. Deploy control plane (`make deploy`)
3. Run chaos experiment
4. Show Grafana metrics
5. Verify rollback

Upload to YouTube (unlisted) for portfolio

---

## 🚀 Phase 9: CI/CD & Polish (2 hours)

### Step 9.1: Verify GitHub Actions

```bash
# Push code
git add .
git commit -m "feat: implement chaos agent and E2E tests"
git push origin main
```

**Check GitHub Actions:** Should trigger CI pipeline

---

### Step 9.2: Fix Any CI Failures

Common issues:
- Linting errors: Run `golangci-lint run --fix`
- Test failures: Run tests locally first
- Docker build issues: Check Dockerfile syntax

---

### Step 9.3: Add README Badges

Add to `README.md`:
```markdown
[![CI Status](https://github.com/destinyobs/khaos-engine/workflows/CI/badge.svg)](https://github.com/destinyobs/khaos-engine/actions)
[![Go Report Card](https://goreportcard.com/badge/github.com/destinyobs/khaos-engine)](https://goreportcard.com/report/github.com/destinyobs/khaos-engine)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
```

---

## 🎉 Phase 10: Future Enhancements (Post-MVP)

### Week 5-6: Advanced Chaos Types
- [ ] Network latency injection (tc or eBPF)
- [ ] CPU/Memory stress (stress-ng)
- [ ] Container kill (SIGKILL)

### Week 7-8: Kubernetes Operator
- [ ] CRD for ChaosExperiment
- [ ] Controller with reconciliation loop
- [ ] Webhook validation

### Week 9-10: Web UI
- [ ] React dashboard
- [ ] Experiment builder
- [ ] Real-time metrics

### Week 11-12: Cloud Integration
- [ ] AWS EC2 chaos
- [ ] RDS failover
- [ ] Terraform modules

---

## 📊 Checkpoint Summary

After completing all phases, you should have:

✅ **Running System:**
- [ ] 3-node kind cluster
- [ ] Control plane deployed
- [ ] Chaos agent functional
- [ ] Observability stack
- [ ] Demo experiments working

✅ **Code Quality:**
- [ ] 70%+ test coverage
- [ ] All linters passing
- [ ] CI/CD pipeline green
- [ ] Security scans clean

✅ **Documentation:**
- [ ] Architecture diagram
- [ ] Getting started guide
- [ ] API documentation
- [ ] Demo video

✅ **Portfolio-Ready:**
- [ ] GitHub repo public
- [ ] Professional README
- [ ] Contribution guidelines
- [ ] License

---

## 🆘 Troubleshooting Guide

### Cluster Issues
**Problem:** `kind create cluster` fails
**Solution:**
```bash
docker ps  # Ensure Docker running
kind delete cluster --name chaoscraft
docker system prune -af
kind create cluster --name chaoscraft
```

### Database Issues
**Problem:** "connection refused" to PostgreSQL
**Solution:**
```bash
kubectl get pods -n chaoscraft | grep postgres
kubectl logs -n chaoscraft chaoscraft-postgresql-0
kubectl port-forward -n chaoscraft svc/chaoscraft-postgresql 5432:5432
psql -h localhost -U chaoscraft -d chaoscraft  # Test connection
```

### Image Pull Issues
**Problem:** "ImagePullBackOff"
**Solution:**
```bash
# Rebuild and reload image
docker build -t chaoscraft/control-plane:latest ./control-plane
kind load docker-image chaoscraft/control-plane:latest --name chaoscraft
kubectl rollout restart deployment/chaoscraft-control-plane -n chaoscraft
```

---

## 📚 Learning Resources

**Kubernetes:**
- https://kubernetes.io/docs/tutorials/
- https://kube.academy/ (free VMware course)

**Go:**
- https://tour.golang.org/
- https://gobyexample.com/

**Chaos Engineering:**
- https://principlesofchaos.org/
- https://www.gremlin.com/community/tutorials/

**DevOps:**
- https://12factor.net/
- https://sre.google/sre-book/

---

## 🎯 Next Steps

Ready to start? Begin with:

1. **Phase 0:** Push to GitHub (30 mins)
2. **Phase 1:** Create cluster (1 hour)
3. **Phase 2:** Install ArgoCD (1 hour)

Each phase builds on the previous one. Take your time and verify each step!

**Need help?** Check `TROUBLESHOOTING.md` or open a GitHub issue.

Good luck! 🚀
