# Getting Started with ChaosCraft

This guide will walk you through setting up ChaosCraft locally and running your first chaos experiment.

## Prerequisites

Ensure you have the following tools installed:

- [Docker](https://www.docker.com/get-started) (v24+)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) (v0.20+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.28+)
- [Helm](https://helm.sh/docs/intro/install/) (v3.12+)
- [Go](https://go.dev/doc/install) (v1.21+) - for local development

## Step 1: Create Local Cluster

Create a 3-node kind cluster:

```bash
make cluster-create
```

This will:
- Create a kind cluster named `chaoscraft`
- Configure 1 control-plane node + 2 worker nodes
- Install metrics-server for resource monitoring
- Set up port mappings for accessing services

Verify the cluster:

```bash
kubectl get nodes
```

You should see 3 nodes in `Ready` state.

## Step 2: Install Infrastructure

### Install ArgoCD (GitOps)

```bash
make argocd-install
```

Wait for ArgoCD to be ready:

```bash
kubectl wait --for=condition=available --timeout=300s -n argocd deployment/argocd-server
```

Access ArgoCD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Open browser: https://localhost:8080
- Username: `admin`
- Password: (from command above)

### Install Observability Stack

```bash
make observability-install
```

This installs:
- Prometheus (metrics collection)
- Grafana (dashboards)
- Loki (log aggregation)
- Alertmanager (alerting)

Access Grafana:

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Open browser: http://localhost:3000
- Username: `admin`
- Password: `prom-operator` (default)

## Step 3: Build and Deploy ChaosCraft

### Build Docker Images

```bash
make build-docker
```

This builds:
- `chaoscraft/control-plane:latest`
- `chaoscraft/chaos-agent:latest`

### Deploy to Cluster

```bash
make deploy
```

This will:
- Load images into kind cluster
- Create `chaoscraft` namespace
- Deploy control plane via Helm
- Deploy chaos agent via Helm
- Set up PostgreSQL database

Verify deployment:

```bash
kubectl get pods -n chaoscraft
```

Expected output:
```
NAME                                        READY   STATUS    RESTARTS   AGE
chaoscraft-control-plane-xxxxxxxxx-xxxxx    1/1     Running   0          30s
chaoscraft-agent-xxxxx                      1/1     Running   0          30s
chaoscraft-postgresql-0                     1/1     Running   0          30s
```

## Step 4: Deploy Demo Application

Deploy a sample nginx application:

```bash
make demo-setup
```

This creates:
- `demo` namespace
- nginx deployment with 3 replicas
- Service exposing nginx

Verify demo app:

```bash
kubectl get pods -n demo
```

## Step 5: Run Your First Chaos Experiment

Create an experiment that kills one nginx pod:

```bash
cat > experiment.yaml <<EOF
apiVersion: chaos.chaoscraft.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-kill-demo
  namespace: demo
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
    promQL: "kube_deployment_status_replicas_available{deployment='nginx'}"
    threshold: 0.66  # At least 2/3 replicas available
EOF

kubectl apply -f experiment.yaml
```

Watch the experiment:

```bash
kubectl get chaosexperiment -n demo -w
```

Or use the CLI:

```bash
# TODO: Build CLI tool
# chaoscraft experiment get pod-kill-demo
```

## Step 6: View Results

### Check Grafana Dashboards

1. Open Grafana: http://localhost:3000
2. Navigate to "ChaosCraft Experiments" dashboard
3. View experiment metrics:
   - Experiment status
   - Blast radius score
   - Rollback triggers
   - Pod availability

### Check Prometheus Metrics

Open Prometheus: http://localhost:9090

Query examples:
```promql
# Total experiments run
chaoscraft_experiments_total

# Current running experiments
chaoscraft_experiments_running

# Rollback count
chaoscraft_rollbacks_total

# Pod availability during chaos
kube_deployment_status_replicas_available{deployment="nginx"}
```

### Check Logs

Control plane logs:
```bash
kubectl logs -n chaoscraft -l app=chaoscraft-control-plane -f
```

Agent logs:
```bash
kubectl logs -n chaoscraft -l app=chaoscraft-agent -f
```

## Step 7: Clean Up

Clean up demo:
```bash
make demo-cleanup
```

Undeploy ChaosCraft:
```bash
make undeploy
```

Delete cluster:
```bash
make cluster-delete
```

## Next Steps

1. **Read the Documentation**
   - [Architecture Overview](architecture/overview.md)
   - [Experiment Types](guides/experiment-types.md)
   - [Safety Mechanisms](guides/safety.md)

2. **Try More Experiments**
   - Network latency injection
   - Resource stress (CPU/Memory)
   - Container kill scenarios

3. **Set Up CI/CD**
   - Automated experiment runs in pipeline
   - Progressive chaos testing

4. **Configure Monitoring**
   - Custom Grafana dashboards
   - Alert rules for experiment failures
   - SLO tracking

## Troubleshooting

### Pods Not Starting

Check events:
```bash
kubectl describe pod <pod-name> -n chaoscraft
```

Check logs:
```bash
kubectl logs <pod-name> -n chaoscraft
```

### Database Connection Issues

Check PostgreSQL status:
```bash
kubectl get pods -n chaoscraft -l app.kubernetes.io/name=postgresql
```

Check database logs:
```bash
kubectl logs -n chaoscraft chaoscraft-postgresql-0
```

Test connection:
```bash
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h chaoscraft-postgresql -U chaoscraft -d chaoscraft
```

### Control Plane Not Ready

Check readiness probe:
```bash
kubectl describe pod -n chaoscraft -l app=chaoscraft-control-plane
```

Manual health check:
```bash
kubectl port-forward -n chaoscraft svc/chaoscraft-control-plane 8080:8080
curl http://localhost:8080/health
curl http://localhost:8080/ready
```

## Support

- **Documentation**: [docs/](../docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/khaos-engine/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/khaos-engine/discussions)
