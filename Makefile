.PHONY: help cluster-create cluster-delete cluster-info cluster-cost

# ==============================================================================
# ChaosCraft Makefile - Phase 1: Cluster Management
# ==============================================================================

CLUSTER_NAME ?= chaoscraft
AWS_REGION ?= us-east-1
EKS_CONFIG ?= infra/eks/cluster.yaml

help: ## Display available commands
	@echo "ChaosCraft - EKS Cluster Management"
	@echo "===================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==============================================================================
# Cluster Operations
# ==============================================================================

cluster-create: ## Create EKS cluster (takes ~15-20 min)
	@echo "Creating EKS cluster: $(CLUSTER_NAME)"
	@echo "Region: $(AWS_REGION)"
	@echo "This will take 15-20 minutes..."
	@echo ""
	@echo "Cost Estimate: ~\$$5/day (~\$$157/month if running 24/7)"
	@echo "WARNING: Remember to run 'make cluster-delete' when done!"
	@echo ""
	@read -p "Press Enter to continue or Ctrl+C to cancel... " confirm
	@echo "Running pre-flight checks..."
	@$(MAKE) preflight-check
	@echo "Pre-flight checks passed"
	@echo ""
	@echo "Creating cluster..."
	exksctl create cluster -f $(EKS_CONFIG)
	@echo ""
	@echo "Cluster created successfully!"
	@echo ""
	@$(MAKE) cluster-info

cluster-delete: ## Delete EKS cluster (takes ~10-15 min)
	@echo "Deleting EKS cluster: $(CLUSTER_NAME)"
	@echo "WARNING: This will DELETE ALL resources in the cluster!"
	@echo ""
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "Deletion cancelled"; \
		exit 1; \
	fi
	@echo ""
	@echo "Deleting cluster..."
	exksctl delete cluster --name $(CLUSTER_NAME) --region $(AWS_REGION) --wait
	@echo ""
	@echo "Cluster deleted successfully!"
	@echo "CloudWatch logs retained (small cost, ~\$$3/month)"

cluster-info: ## Show cluster information
	@echo "Cluster Information"
	@echo "======================"
	@echo ""
	@echo "Cluster Name: $(CLUSTER_NAME)"
	@echo "Region: $(AWS_REGION)"
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes -o wide 2>/dev/null || echo "Cannot connect to cluster"
	@echo ""
	@echo "Node Labels (chaos-enabled):"
	@kubectl get nodes --show-labels 2>/dev/null | grep chaos-enabled || echo "Cannot connect to cluster"
	@echo ""
	@echo "Node Groups:"
	@eksctl get nodegroup --cluster $(CLUSTER_NAME) --region $(AWS_REGION) 2>/dev/null || echo "Cluster not found"
	@echo ""
	@echo "Cluster Endpoint:"
	@aws eks describe-cluster --name $(CLUSTER_NAME) --region $(AWS_REGION) --query 'cluster.endpoint' --output text 2>/dev/null || echo "Cluster not found"

cluster-cost: ## Estimate cluster costs
	@echo "Cost Estimation"
	@echo "=================="
	@echo ""
	@echo "Daily Costs (running 24/7):"
	@echo "  EKS Control Plane:        \$$2.40/day  (\$$73/month)"
	@echo "  NAT Gateway:              \$$1.05/day  (\$$32/month)"
	@echo "  System node (t3.medium):  \$$1.00/day  (\$$30/month)"
	@echo "  Chaos workers (2x spot):  \$$0.30/day  (\$$9/month)"
	@echo "  EBS volumes:              \$$0.15/day  (\$$5/month)"
	@echo "  Data transfer:            \$$0.15/day  (\$$5/month)"
	@echo "  CloudWatch logs:          \$$0.10/day  (\$$3/month)"
	@echo "  ─────────────────────────────────────"
	@echo "  TOTAL:                    ~\$$5.15/day (~\$$157/month)"
	@echo ""
	@echo "Cost Optimization:"
	@echo "  • Delete cluster when not using: 'make cluster-delete'"
	@echo "  • Reduce workers to 1: Edit cluster.yaml, desiredCapacity: 1"
	@echo "  • Use t3.micro for workers: Edit cluster.yaml, instanceType"
	@echo ""
	@echo "Checking actual AWS costs (last 7 days)..."
	@aws ce get-cost-and-usage \
		--time-period Start=$$(date -d '7 days ago' +%Y-%m-%d),End=$$(date +%Y-%m-%d) \
		--granularity DAILY \
		--metrics "UnblendedCost" \
		--group-by Type=SERVICE \
		--filter file://<(echo '{"Tags":{"Key":"Project","Values":["ChaosCraft"]}}') \
		2>/dev/null | jq -r '.ResultsByTime[] | "\(.TimePeriod.Start): \(.Total.UnblendedCost.Amount) \(.Total.UnblendedCost.Unit)"' \
		|| echo "WARNING: Cannot retrieve cost data (need Cost Explorer API enabled)"

# ==============================================================================
# Pre-flight Checks
# ==============================================================================

preflight-check: ## Run pre-flight checks
	@echo "Checking prerequisites..."
	@which aws > /dev/null || (echo "ERROR: AWS CLI not found. Install: https://aws.amazon.com/cli/" && exit 1)
	@which eksctl > /dev/null || (echo "ERROR: eksctl not found. Install: https://eksctl.io/" && exit 1)
	@which kubectl > /dev/null || (echo "ERROR: kubectl not found. Install: https://kubernetes.io/docs/tasks/tools/" && exit 1)
	@aws sts get-caller-identity > /dev/null 2>&1 || (echo "ERROR: AWS credentials not configured. Run: aws configure" && exit 1)
	@echo "Checking if cluster already exists..."
	@eksctl get cluster --name $(CLUSTER_NAME) --region $(AWS_REGION) > /dev/null 2>&1 && \
		(echo "WARNING: Cluster '$(CLUSTER_NAME)' already exists!" && \
		 echo "Delete it first: make cluster-delete" && \
		 exit 1) || true

# ==============================================================================
# Utility Commands
# ==============================================================================

cluster-kubeconfig: ## Update kubeconfig for cluster
	@echo "Updating kubeconfig..."
	aws eks update-kubeconfig --name $(CLUSTER_NAME) --region $(AWS_REGION)
	@echo "Kubeconfig updated"
	@echo "Current context: $$(kubectl config current-context)"

cluster-test: ## Test cluster with nginx deployment
	@echo "Testing cluster with nginx deployment..."
	@echo "Deploying nginx to chaos workers..."
	@cat <<EOF | kubectl apply -f - \
	apiVersion: apps/v1; \
	kind: Deployment; \
	metadata:; \
	  name: test-nginx; \
	spec:; \
	  replicas: 2; \
	  selector:; \
	    matchLabels:; \
	      app: nginx; \
	  template:; \
	    metadata:; \
	      labels:; \
	        app: nginx; \
	    spec:; \
	      tolerations:; \
	        - key: experimental; \
	          operator: Equal; \
	          value: "true"; \
	          effect: NoSchedule; \
	      nodeSelector:; \
	        chaos-enabled: "true"; \
	      containers:; \
	        - name: nginx; \
	          image: nginx:alpine; \
	          ports:; \
	            - containerPort: 80; \
	EOF
	@echo ""
	@echo "Waiting for pods to be ready..."
	@kubectl wait --for=condition=Ready pod -l app=nginx --timeout=60s
	@echo ""
	@echo "Test deployment successful!"
	@kubectl get pods -l app=nginx -o wide
	@echo ""
	@echo "Cleanup: kubectl delete deployment test-nginx"

cluster-logs: ## View cluster logs
	@echo "Fetching cluster logs from CloudWatch..."
	@echo "Control plane logs are in CloudWatch Logs:"
	@echo "Log Groups:"
	@aws logs describe-log-groups --log-group-name-prefix "/aws/eks/$(CLUSTER_NAME)" --region $(AWS_REGION) --query 'logGroups[*].logGroupName' --output table

.DEFAULT_GOAL := help
