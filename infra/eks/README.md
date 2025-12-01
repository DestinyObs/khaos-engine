# EKS Infrastructure for ChaosCraft

## Overview

This directory contains the EKS cluster configuration for ChaosCraft's chaos engineering platform.

**Cluster Name**: `chaoscraft`  
**Region**: `us-east-1`  
**Kubernetes Version**: `1.28`  
**Estimated Cost**: ~$5/day (~$157/month if running 24/7)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS EKS Cluster                          │
│                      (chaoscraft)                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐    ┌──────────────────────┐     │
│  │  System Node Group   │    │ Chaos Worker Group   │     │
│  │                      │    │                      │     │
│  │  Type: t3.medium     │    │  Type: t3.small      │     │
│  │  Count: 1            │    │  Count: 2            │     │
│  │  Strategy: On-Demand │    │  Strategy: Spot      │     │
│  │                      │    │                      │     │
│  │  Runs:               │    │  Runs:               │     │
│  │  - ArgoCD           │    │  - Demo Apps         │     │
│  │  - Prometheus       │    │  - Chaos Targets     │     │
│  │  - Grafana          │    │  - Test Workloads    │     │
│  │  - Control Plane    │    │                      │     │
│  │                      │    │  Label:              │     │
│  │  Label:              │    │  chaos-enabled=true  │     │
│  │  role=system         │    │                      │     │
│  └──────────────────────┘    └──────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Node Groups Explained

### 1. System Nodes
**Purpose**: Infrastructure workloads  
**Instance Type**: `t3.medium` (2 vCPU, 4GB RAM)  
**Strategy**: On-demand (always available)  
**Cost**: ~$30/month

**What runs here:**
- ArgoCD (GitOps controller)
- Prometheus + Grafana (observability)
- ChaosCraft control plane API
- Critical infrastructure

**Why on-demand?**
- Need 100% availability
- Can't afford interruptions
- Core platform components

### 2. Chaos Workers
**Purpose**: Chaos experiment targets  
**Instance Type**: `t3.small` (2 vCPU, 2GB RAM)  
**Strategy**: Spot instances (70% cheaper)  
**Cost**: ~$9/month for 2 nodes

**What runs here:**
- Demo applications
- Test microservices
- Workloads that receive chaos

**Why spot instances?**
- 70% cost savings
- Interruptions are acceptable (can tolerate failures)
- Perfect for non-critical workloads

**Special label**: `chaos-enabled=true`
- ChaosCraft agents use this to target experiments
- Won't accidentally kill infrastructure pods

---

## Prerequisites

### Required Tools
```bash
# AWS CLI
aws --version  # Need v2+
aws configure  # Set up credentials

# eksctl
eksctl version  # Need 0.150+
# Install: https://eksctl.io/installation/

# kubectl
kubectl version --client  # Need 1.28+
# Install: https://kubernetes.io/docs/tasks/tools/
```

### AWS Permissions Required
Your IAM user needs these permissions:
- `AmazonEKSClusterPolicy`
- `AmazonEKSServicePolicy`
- `AmazonEC2FullAccess` (for VPC, subnets, security groups)
- `IAMFullAccess` (for creating roles)

**Or** use `AdministratorAccess` for simplicity (dev environment).

---

## Quick Start

### 1. Create Cluster
```bash
# From project root
make cluster-create

# Or manually
cd infra/eks
eksctl create cluster -f cluster.yaml

# Takes ~15-20 minutes
```

### 2. Verify Cluster
```bash
# Check nodes
kubectl get nodes

# Expected output:
# NAME                          STATUS   ROLES    AGE
# ip-10-0-1-123.ec2.internal   Ready    <none>   5m   # system node
# ip-10-0-2-45.ec2.internal    Ready    <none>   5m   # chaos worker 1
# ip-10-0-2-67.ec2.internal    Ready    <none>   5m   # chaos worker 2

# Verify labels
kubectl get nodes --show-labels | grep chaos-enabled

# Check node groups
eksctl get nodegroup --cluster chaoscraft
```

### 3. Test Deployment
```bash
# Deploy nginx to chaos workers (they have taint, so we need toleration)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      # Tolerate the experimental taint
      tolerations:
        - key: experimental
          operator: Equal
          value: "true"
          effect: NoSchedule
      # Target chaos workers
      nodeSelector:
        chaos-enabled: "true"
      containers:
        - name: nginx
          image: nginx:alpine
          ports:
            - containerPort: 80
EOF

# Check where pods landed
kubectl get pods -o wide
```

### 4. Delete Cluster (When Done)
```bash
# From project root
make cluster-delete

# Or manually
eksctl delete cluster --name chaoscraft --wait

# Takes ~10-15 minutes
```

---

## Cost Management

### Daily Costs (running 24/7)
| Component | Cost/Day | Cost/Month |
|-----------|----------|------------|
| EKS Control Plane | $2.40 | $73 |
| NAT Gateway | $1.05 | $32 |
| System node (t3.medium) | $1.00 | $30 |
| Chaos workers (2x t3.small spot) | $0.30 | $9 |
| EBS volumes (60GB) | $0.15 | $5 |
| Data transfer | $0.15 | $5 |
| CloudWatch logs | $0.10 | $3 |
| **TOTAL** | **~$5.15** | **~$157** |

### Cost Optimization Tips

**1. Delete when not using** (recommended)
```bash
make cluster-delete  # Run at end of each session
make cluster-create  # Run when starting work again
```
Saves: ~$3/day when deleted (only pay for CloudWatch log storage)

**2. Reduce worker count**
Edit `cluster.yaml`: Change `desiredCapacity: 1` for chaos-workers
Saves: ~$0.15/day

**3. Use smaller instances**
Change chaos-workers to `t3.micro` (1 vCPU, 1GB RAM)
Saves: ~$0.20/day

**4. Stop nodes (doesn't work for EKS)**
❌ Can't stop EKS control plane
❌ Can't stop managed nodes (AWS auto-replaces them)
✅ Must delete entire cluster to stop costs

---

## Cluster Features

### ✅ Enabled
- Multi-AZ deployment (3 availability zones)
- Cluster Autoscaler ready (min/max configured)
- IRSA (IAM Roles for Service Accounts)
- EBS CSI driver for persistent volumes
- VPC CNI for pod networking
- CloudWatch logging
- Spot instances for workers

### ❌ Not Enabled (Can Add Later)
- Fargate profiles (adds complexity)
- AWS Load Balancer Controller (Phase 2)
- External DNS (Phase 2)
- Service mesh (Istio/Linkerd) - optional

---

## Troubleshooting

### Cluster creation fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check eksctl version
eksctl version  # Need 0.150+

# Check CloudFormation stacks
aws cloudformation list-stacks --region us-east-1

# Delete failed stack and retry
eksctl delete cluster --name chaoscraft
```

### Nodes not ready
```bash
# Check node status
kubectl describe node <node-name>

# Check AWS Console
# EC2 > Auto Scaling Groups > chaoscraft-*
```

### Can't connect to cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --name chaoscraft --region us-east-1

# Verify context
kubectl config current-context
```

### High costs
```bash
# Check actual costs
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-02 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=SERVICE

# Delete cluster if not using
make cluster-delete
```

---

## Security Considerations

### ✅ What's Secure
- Private subnets for nodes (not internet-exposed)
- IRSA for pod-level IAM permissions
- CloudWatch audit logging enabled
- Security groups managed by AWS
- No SSH access to nodes

### ⚠️  What Could Be Better (Production)
- Cluster endpoint should be private-only
- Enable encryption at rest for EBS
- Add VPC Flow Logs
- Use AWS Secrets Manager for secrets
- Enable Pod Security Standards
- Add network policies

We'll tackle these in later phases as we add security hardening.

---

## Next Steps

After cluster is running:
1. ✅ Verify nodes are Ready
2. ✅ Check node labels match expectations
3. 📦 Phase 2: Install ArgoCD
4. 📊 Phase 2: Deploy Prometheus + Grafana
5. 🎯 Phase 3: Build control plane API

See `ROADMAP.md` for full plan.

---

## References

- [eksctl documentation](https://eksctl.io/)
- [EKS best practices](https://aws.github.io/aws-eks-best-practices/)
- [EKS pricing](https://aws.amazon.com/eks/pricing/)
- [Spot instance best practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-best-practices.html)
