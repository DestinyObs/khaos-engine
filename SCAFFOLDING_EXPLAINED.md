# 📚 Scaffolding Deep Dive: What We Built and Why

This document explains **every file** created in the scaffolding, its purpose, and how it fits into the bigger picture.

---

## 🗂️ Project Structure Overview

```
khaos-engine/
├── .github/              # GitHub-specific configs (CI/CD)
├── charts/               # Helm charts for Kubernetes deployment
├── control-plane/        # Go service (REST API + orchestration)
├── docs/                 # Documentation
├── examples/             # Demo apps and experiments
├── infra/                # Infrastructure as Code (IaC)
├── scripts/              # Automation scripts
├── CODE_OF_CONDUCT.md    # Community guidelines
├── CONTRIBUTING.md       # Contribution guidelines
├── LICENSE               # Apache 2.0 license
├── Makefile              # Build automation
└── README.md             # Project overview
```

---

## 📄 Root Level Files

### `README.md`
**Purpose:** Project landing page - first thing anyone sees

**What's Inside:**
- **Architecture diagram** (ASCII art showing control plane → agents flow)
- **Quick start** commands
- **Feature list** with checkboxes (MVP vs. planned)
- **Repository structure** guide
- **Links** to detailed docs

**Why It Matters:**
- Recruiters/hiring managers will judge your project in 30 seconds
- Clear README = professional portfolio piece
- Shows you understand documentation as code

---

### `LICENSE` (Apache 2.0)
**Purpose:** Legal protection and open-source compliance

**Why Apache 2.0:**
- Permissive (allows commercial use)
- Patent grant (protects users)
- Industry standard (used by Kubernetes, Docker, etc.)
- Portfolio-friendly (shows you understand licensing)

**Key Clauses:**
- Anyone can use/modify/distribute
- Must include license notice
- No warranty/liability

---

### `CODE_OF_CONDUCT.md`
**Purpose:** Set community standards (even for solo projects)

**Why Include It:**
- Shows professionalism
- Required if you want contributors
- Demonstrates understanding of healthy OSS communities
- Based on Contributor Covenant v2.1 (industry standard)

**Key Points:**
- Zero tolerance for harassment
- Enforcement guidelines
- Contact method for violations

---

### `CONTRIBUTING.md`
**Purpose:** Onboarding guide for contributors (including future you!)

**What's Inside:**
- **How to report bugs** (templates, required info)
- **How to suggest features** (use cases, alternatives)
- **Pull request workflow** (branch naming, commit conventions)
- **Coding standards** (Go style, test coverage requirements)
- **Development setup** (step-by-step)

**Why It Matters:**
- Reduces back-and-forth with contributors
- Sets quality bar (80% test coverage, linting)
- Shows you think about maintainability

---

### `Makefile`
**Purpose:** One-stop command center for all operations

**Key Targets:**

| Command | What It Does | When To Use |
|---------|--------------|-------------|
| `make cluster-create` | Spins up 3-node kind cluster | First-time setup |
| `make build` | Builds Go binaries | After code changes |
| `make build-docker` | Builds container images | Before deployment |
| `make deploy` | Deploys to Kubernetes | After building images |
| `make test` | Runs unit tests | After every change |
| `make argocd-install` | Installs ArgoCD | GitOps setup |
| `make observability-install` | Installs Prometheus/Grafana | Monitoring setup |

**Why Makefile vs. Scripts:**
- **Self-documenting** (`make help` lists all commands)
- **Cross-platform** (works on Linux, macOS, WSL)
- **Idempotent** (can run multiple times safely)
- **Dependency management** (targets can depend on others)

---

### `.gitignore`
**Purpose:** Keep secrets and binaries out of Git

**What's Ignored:**
- **Binaries:** `*.exe`, `bin/`, `*.out`
- **Dependencies:** `vendor/`, `node_modules/`
- **Secrets:** `*.key`, `.env`, `secrets.yaml`
- **IDE files:** `.vscode/`, `.idea/`
- **Logs:** `*.log`, `logs/`
- **Terraform state:** `*.tfstate`

**Why It Matters:**
- **Security:** Prevents accidental token leaks
- **Performance:** Smaller repo, faster clones
- **Cleanliness:** No build artifacts in commits

---

## 🐙 `.github/` - CI/CD Pipeline

### `workflows/ci.yaml`
**Purpose:** Automated testing and quality checks on every push/PR

**Pipeline Stages:**

#### 1. **Lint** (Code Quality)
```yaml
- golangci-lint (Go code)
- helm lint (Helm charts)
```
**Why:** Catches bugs, enforces style, finds unused code

#### 2. **Test** (Unit Tests)
```yaml
- go test -race -cover
- Upload coverage to Codecov
```
**Why:** Ensures code works, tracks coverage over time

#### 3. **Build** (Compilation)
```yaml
- Build Go binary
- Build Docker images
```
**Why:** Ensures code compiles, images build correctly

#### 4. **Security** (Vulnerability Scanning)
```yaml
- Trivy scan (Docker images)
- Upload results to GitHub Security
```
**Why:** Finds CVEs in dependencies, prevents supply chain attacks

#### 5. **E2E** (End-to-End Tests)
```yaml
- Create kind cluster
- Deploy control plane
- Run chaos experiment
- Verify rollback
```
**Why:** Tests entire system, not just units

**Portfolio Value:**
- Shows you understand CI/CD best practices
- Demonstrates security-first mindset
- Proves you test your code

---

## 🎛️ `control-plane/` - Go Service

### `go.mod` & `go.sum`
**Purpose:** Go dependency management (like `package.json`)

**Key Dependencies:**
- **gin-gonic/gin:** Web framework (fast, minimalist)
- **lib/pq:** PostgreSQL driver
- **golang-migrate:** Database migrations
- **prometheus/client_golang:** Metrics
- **zap:** Structured logging
- **cobra:** CLI framework
- **k8s.io/client-go:** Kubernetes API client

**Why These Choices:**
- **Gin:** 40% faster than standard library, minimal boilerplate
- **Zap:** 10x faster than other loggers, structured output
- **Prometheus:** De facto standard for Kubernetes metrics

---

### `cmd/server/main.go`
**Purpose:** Application entrypoint

**What It Does (Line by Line):**
1. **Initialize logger** (`zap.NewProduction()`)
   - Structured JSON logs
   - Automatic error stacks
   
2. **Load config** (`config.Load()`)
   - Reads environment variables
   - Validates required fields

3. **Initialize storage** (`storage.NewPostgresStore()`)
   - Connects to PostgreSQL
   - Sets connection pool limits

4. **Run migrations** (`store.Migrate()`)
   - Creates tables if missing
   - Idempotent (safe to run multiple times)

5. **Set up Gin router**
   - Middleware: logging, CORS, recovery
   - Routes: `/health`, `/ready`, `/metrics`, `/api/v1/*`

6. **Start HTTP server**
   - Listen on port 8080 (configurable)
   - Graceful shutdown on SIGTERM/SIGINT

**Why This Structure:**
- **12-Factor App:** Config via env vars, stateless
- **Observability:** Health checks, metrics, structured logs
- **Graceful shutdown:** Drains connections before exit

---

### `pkg/config/config.go`
**Purpose:** Configuration management

**Configuration Sources:**
1. **Environment variables** (primary)
2. **Defaults** (fallback)

**Why Environment Variables:**
- **Kubernetes-native:** ConfigMaps, Secrets
- **No code changes** to change config
- **Security:** Secrets never in code

**Example:**
```go
PORT=9000 ./chaoscraft  // Overrides default 8080
```

---

### `pkg/storage/postgres.go`
**Purpose:** Database abstraction layer

**Interface Pattern:**
```go
type Store interface {
    Ping(ctx context.Context) error
    Close() error
    Migrate() error
}
```

**Why Interface:**
- **Testability:** Mock in tests
- **Swappable:** Can replace with Redis, MongoDB, etc.
- **Contract:** Guarantees behavior

**Connection Pool Settings:**
- **MaxOpenConns: 25** (limit concurrent connections)
- **MaxIdleConns: 5** (keep warm connections)

**Why These Numbers:**
- PostgreSQL default max: 100 connections
- Leave headroom for other apps
- Reduce connection overhead

---

### `pkg/api/handlers.go`
**Purpose:** HTTP request handlers

**Current Endpoints (Stubs):**
- `GET /api/v1/experiments` → List experiments
- `POST /api/v1/experiments` → Create experiment
- `GET /api/v1/experiments/:id` → Get experiment details
- `DELETE /api/v1/experiments/:id` → Delete experiment
- `POST /api/v1/experiments/:id/start` → Start experiment
- `POST /api/v1/experiments/:id/stop` → Stop experiment

**Why Stubs:**
- Scaffolding first, logic later
- Tests can be written now (TDD)
- API contract defined early

---

### `pkg/api/middleware.go`
**Purpose:** Request/response interceptors

**Middleware Stack:**
1. **LoggerMiddleware:** Logs every request
   - Method, path, status, latency, IP
   - Structured for Loki/Elasticsearch

2. **CORSMiddleware:** Cross-origin requests
   - Allow all origins (dev mode)
   - Production: restrict to frontend domain

3. **Recovery:** Panic handler (built-in Gin)
   - Catches panics, returns 500
   - Prevents server crash

**Why Middleware:**
- **DRY:** Write once, apply to all routes
- **Separation of concerns:** Auth, logging, etc. separate from business logic

---

### `Dockerfile`
**Purpose:** Container image definition

**Multi-Stage Build:**

#### Stage 1: Builder
```dockerfile
FROM golang:1.21-alpine AS builder
COPY . .
RUN go build -o chaoscraft
```
**Why:** Full build toolchain (Go compiler, git)

#### Stage 2: Final Image
```dockerfile
FROM scratch
COPY --from=builder /build/chaoscraft /chaoscraft
USER 65534
ENTRYPOINT ["/chaoscraft"]
```
**Why:** Minimal attack surface, 10MB image

**Security Features:**
- **FROM scratch:** No OS, no shell, no vulnerabilities
- **USER 65534:** Run as nobody (non-root)
- **Read-only filesystem:** `-ldflags="-w -s"` strips debug symbols

**Image Size:**
- **With alpine:** ~20MB
- **With scratch:** ~10MB
- **Benefit:** Faster pulls, less attack surface

---

### `migrations/`
**Purpose:** Database schema versioning

**File Naming:**
```
000001_init_schema.up.sql    # Apply migration
000001_init_schema.down.sql  # Rollback migration
```

**Why Migrations:**
- **Version control** for database
- **Reproducible** schemas
- **Rollback** support
- **Team coordination** (no manual SQL)

**Schema Design:**

#### `experiments` Table
```sql
id          UUID PRIMARY KEY
name        VARCHAR(255)
spec        JSONB           -- Full experiment config
status      VARCHAR(50)     -- pending, running, completed
created_at  TIMESTAMP
labels      JSONB           -- For filtering
```

**Why JSONB:**
- **Flexible schema** (chaos specs vary)
- **Queryable** (can index JSON fields)
- **Performance** (binary format)

#### `experiment_runs` Table
```sql
id              UUID PRIMARY KEY
experiment_id   UUID FOREIGN KEY
run_number      INTEGER
result          JSONB
blast_radius_score  DECIMAL
```

**Why Separate Table:**
- One experiment → many runs
- Historical data
- Performance (don't bloat experiments table)

#### `audit_logs` Table
```sql
timestamp     TIMESTAMP
action        VARCHAR(100)
user_id       VARCHAR(255)
details       JSONB
```

**Why Audit Logs:**
- **Compliance** (who did what, when)
- **Debugging** (trace actions)
- **Security** (detect anomalies)

---

## ☸️ `charts/` - Helm Charts

### `Chart.yaml`
**Purpose:** Helm chart metadata

**Key Fields:**
- **apiVersion: v2** (Helm 3)
- **type: application** (vs. library)
- **version: 0.1.0** (chart version, SemVer)
- **appVersion: 0.1.0** (app version)

**Why Separate Versions:**
- Chart changes ≠ app changes
- Chart: 0.2.0 (added ingress), App: 0.1.0 (same code)

---

### `values.yaml`
**Purpose:** Default configuration values

**Key Sections:**

#### Image Config
```yaml
image:
  repository: chaoscraft/control-plane
  tag: latest
  pullPolicy: IfNotPresent
```

#### Resources
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```
**Why:**
- **Limits:** Prevent noisy neighbor issues
- **Requests:** Ensure minimum resources
- **QoS:** Guaranteed tier (limits = requests)

#### Autoscaling
```yaml
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 80
```
**When to Enable:**
- Traffic spikes expected
- Cost optimization (scale down at night)

#### PostgreSQL
```yaml
postgresql:
  enabled: true
  auth:
    username: chaoscraft
    password: chaoscraft
```
**Production:**
- `enabled: false`
- Use managed database (RDS, Cloud SQL)

---

### `templates/deployment.yaml`
**Purpose:** Kubernetes Deployment manifest (templated)

**Key Features:**

#### Pod Annotations
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "8080"
prometheus.io/path: "/metrics"
```
**Why:** Prometheus auto-discovery

#### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /health
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
  failureThreshold: 3
```
**Difference:**
- **Liveness:** Restart if failing (crash loop)
- **Readiness:** Remove from load balancer (not ready for traffic)

#### Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  readOnlyRootFilesystem: true
```
**Why:**
- Principle of least privilege
- Passes Kubernetes security best practices

---

### `templates/service.yaml`
**Purpose:** Kubernetes Service (load balancer)

**Service Type:**
```yaml
type: ClusterIP  # Internal only
```

**Ports:**
- **8080:** HTTP (REST API)
- **9090:** gRPC (agent communication)

**Why Two Ports:**
- REST: Human-friendly (UI, CLI)
- gRPC: Machine-to-machine (agents)

---

### `templates/secret.yaml`
**Purpose:** Database connection string

**Templating Logic:**
```yaml
{{- if .Values.postgresql.enabled }}
  # Use in-cluster PostgreSQL
{{- else }}
  # Use external database
{{- end }}
```

**Production Best Practice:**
- Use **External Secrets Operator** (sync from Vault, AWS Secrets Manager)
- Never commit secrets to Git

---

## 🏗️ `infra/` - Infrastructure

### `kind/cluster-config.yaml`
**Purpose:** Local Kubernetes cluster definition

**Node Configuration:**
```yaml
nodes:
  - role: control-plane  # Runs Kubernetes API server
  - role: worker          # Runs application pods
  - role: worker
```

**Why 3 Nodes:**
- Simulates production (multi-node)
- Tests network chaos (cross-node)
- High availability patterns (leader election)

**Port Mappings:**
```yaml
extraPortMappings:
  - containerPort: 30080
    hostPort: 8080
```
**Why:** Access services from localhost

**Networking:**
```yaml
podSubnet: "10.244.0.0/16"
serviceSubnet: "10.96.0.0/12"
```
**Standard ranges:** Compatible with most CNIs

---

## 📝 `examples/` - Demo Apps

### `demo-app/deployment.yaml`
**Purpose:** Sample nginx app for chaos testing

**Key Features:**
```yaml
replicas: 3  # High availability
labels:
  chaos-enabled: "true"  # Opt-in for chaos
```

**Resources:**
```yaml
requests:
  cpu: 50m
  memory: 64Mi
```
**Why Small:** Leave room for chaos experiments

---

### `experiments/pod-kill-demo.yaml`
**Purpose:** Example chaos experiment CRD

**Experiment Spec:**
```yaml
selector:
  labelSelectors:
    app: nginx
    chaos-enabled: "true"

chaos:
  type: pod-kill
  podKill:
    signal: SIGTERM
    count: 1
    mode: random

duration: 60s

steadyState:
  promQL: "kube_deployment_status_replicas_available..."
  threshold: 0.66

rollback:
  enabled: true
  triggers:
    - type: steady-state-violation
```

**Workflow:**
1. **Baseline:** Check steady-state (66% availability)
2. **Chaos:** Kill 1 random pod
3. **Monitor:** Every 5s, check PromQL query
4. **Rollback:** If below threshold, abort and restore
5. **Complete:** After 60s, finish experiment

---

## 🛠️ `scripts/` - Automation

### `e2e-test.sh`
**Purpose:** End-to-end test automation

**Test Flow:**
1. Create ephemeral kind cluster
2. Deploy control plane
3. Deploy demo app
4. Run chaos experiment
5. Verify rollback
6. Clean up cluster

**Why Bash:**
- Portable (runs in CI)
- Orchestrates multiple tools (kubectl, kind, curl)

---

## 🎯 How It All Fits Together

### Development Flow:
```
1. Edit Go code
2. `make build` → Compiles binary
3. `make test` → Runs unit tests
4. `make build-docker` → Builds image
5. `make deploy` → Deploys to kind cluster
6. `kubectl logs ...` → Check logs
7. Iterate
```

### CI/CD Flow:
```
1. Push to GitHub
2. GitHub Actions triggers
3. Lint + Test + Build
4. Security scan
5. E2E tests in ephemeral cluster
6. (On tag) Build + push Docker images
7. (On tag) Publish Helm chart
```

### Production Flow (Future):
```
1. Tag release (e.g., v0.1.0)
2. GitHub Actions builds release
3. ArgoCD syncs from Git
4. Helm upgrades running deployment
5. Prometheus alerts if issues
6. Rollback via Helm if needed
```

---

## 📊 Key Design Decisions

### Why Go (not Python/Rust):
- **Kubernetes-native:** client-go library
- **Compiled:** Single binary, no runtime
- **Concurrency:** Goroutines for agents
- **Performance:** Fast enough, simpler than Rust

### Why Gin (not Echo/Fiber):
- **Mature:** Battle-tested
- **Fast:** 40% faster than stdlib
- **Minimal:** No magic, explicit

### Why PostgreSQL (not MySQL/MongoDB):
- **JSONB:** Flexible schema
- **ACID:** Transactions for consistency
- **Extensions:** pgcrypto, timescale

### Why Helm (not Kustomize):
- **Templating:** Dynamic values
- **Versioning:** Rollback support
- **Ecosystem:** Chart repositories

### Why kind (not minikube/k3d):
- **Docker-native:** Uses Docker containers
- **Multi-node:** Simulates production
- **Fast:** Create cluster in 30s

---

## 🚀 Next: BUILD_PHASES.md

This explains **what** we built. Next file will explain **how** to build it step-by-step.

Ready to dive into the phased build guide? 💪
