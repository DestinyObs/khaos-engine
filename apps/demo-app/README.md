# Demo App

Simple Go web application with Prometheus metrics for chaos engineering experiments.

## Features

- Beautiful web UI with pod information
- Prometheus metrics at `/metrics`
- Health check endpoint at `/health`
- Auto-discovered by Prometheus via annotations

## Deployment

Deployed via ArgoCD (GitOps):

```bash
kubectl apply -f apps/demo-app/argocd-app.yaml
```

ArgoCD will automatically sync and deploy the app.

## Access

Get the LoadBalancer URL:
```bash
kubectl get svc demo-app -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}'
```

## Endpoints

- `/` - Web UI
- `/health` - Health check (JSON)
- `/metrics` - Prometheus metrics

## Architecture

- 3 replicas running on chaos-workers
- Tolerations for `experimental: true` taint
- LoadBalancer service for external access
- Prometheus scraping enabled via annotations

## Testing GitOps

1. Edit `deployment.yaml` and change replicas: 3 → 5
2. Commit and push to Git
3. Watch ArgoCD auto-sync in UI
4. Verify 5 pods running: `kubectl get pods -l app=demo-app`
