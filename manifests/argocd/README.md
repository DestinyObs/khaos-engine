# ArgoCD Installation

ArgoCD is a GitOps continuous delivery tool for Kubernetes. It monitors Git repositories and automatically deploys changes to the cluster.

## Installation

```bash
make argocd-install
```

This will:
1. Create `argocd` namespace
2. Install ArgoCD from official manifests
3. Wait for all components to be ready

## Access UI

```bash
make argocd-ui
```

This opens a port-forward to `https://localhost:8888`

**Default credentials:**
- Username: `admin`
- Password: Run `make argocd-password` to retrieve

## Architecture

ArgoCD consists of:
- **API Server**: REST/gRPC API and Web UI
- **Repository Server**: Clones Git repos and generates manifests
- **Application Controller**: Monitors apps and syncs desired state
- **Redis**: Caching layer
- **Dex**: SSO integration (optional)

## How GitOps Works

1. Push Kubernetes manifests to Git repo
2. Create ArgoCD Application pointing to that repo
3. ArgoCD syncs changes automatically (or manually)
4. View deployment status in UI

## Security Notes

- ArgoCD runs in `argocd` namespace
- Initial admin password stored in secret `argocd-initial-admin-secret`
- Change password after first login (recommended)
- UI only accessible via port-forward (no public LoadBalancer)

## Uninstall

```bash
make argocd-uninstall
```

This removes all ArgoCD resources and the namespace.
