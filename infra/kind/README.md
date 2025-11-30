# kind Cluster Infrastructure

This directory contains configuration for local kind (Kubernetes IN Docker) clusters.

## Quick Start

```bash
# Create cluster
make cluster-create

# Verify cluster
kubectl get nodes

# Delete cluster
make cluster-delete
```

## Cluster Configuration

- **Name**: chaoscraft
- **Nodes**: 3 (1 control-plane, 2 workers)
- **CNI**: kindnet (default)
- **Pod Subnet**: 10.244.0.0/16
- **Service Subnet**: 10.96.0.0/12

## Port Mappings

The cluster exposes the following ports on localhost:

| Service | Container Port | Host Port | URL |
|---------|---------------|-----------|-----|
| ArgoCD UI | 30080 | 8080 | http://localhost:8080 |
| Grafana | 30300 | 3000 | http://localhost:3000 |
| Prometheus | 30900 | 9090 | http://localhost:9090 |
| Control Plane API | 30800 | 8000 | http://localhost:8000 |

## Labels

### Control Plane Node
- `node-role=control-plane`

### Worker Nodes
- `node-role=worker`
- `chaos-enabled=true` (targets for chaos experiments)

## Advanced Configuration

### Using Calico CNI

To use Calico instead of kindnet:

1. Edit `cluster-config.yaml`:
   ```yaml
   networking:
     disableDefaultCNI: true
   ```

2. Create cluster and install Calico:
   ```bash
   kind create cluster --config infra/kind/cluster-config.yaml
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

### Local Registry

To use a local Docker registry with kind:

```bash
# Run local registry
docker run -d -p 5000:5000 --restart=always --name registry registry:2

# Connect registry to kind network
docker network connect kind registry

# Update cluster-config.yaml containerdConfigPatches
```

## Troubleshooting

### Cluster creation fails
```bash
# Check Docker is running
docker ps

# Check kind version
kind version

# View kind logs
kind export logs --name chaoscraft
```

### Pods not scheduling
```bash
# Check node status
kubectl get nodes -o wide

# Check node conditions
kubectl describe nodes

# Check system pods
kubectl get pods -n kube-system
```

### Metrics-server issues
```bash
# Verify metrics-server is running
kubectl get deployment -n kube-system metrics-server

# Check logs
kubectl logs -n kube-system deployment/metrics-server

# Test metrics
kubectl top nodes
```

## Clean Up

```bash
# Delete cluster
make cluster-delete

# Remove all kind clusters
kind delete clusters --all

# Clean up Docker resources
docker system prune -a
```
