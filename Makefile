.PHONY: help build test deploy clean cluster-create cluster-delete

# Variables
CLUSTER_NAME ?= chaoscraft
KIND_CONFIG ?= infra/kind/cluster-config.yaml
ARGOCD_VERSION ?= v2.9.3

help: ## Display this help message
	@echo "ChaosCraft - Makefile Commands"
	@echo "================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

##@ Development

build: ## Build control plane binary
	@echo "Building control plane..."
	cd control-plane && go build -o bin/chaoscraft ./cmd/server

build-docker: ## Build Docker images
	@echo "Building Docker images..."
	cd control-plane && docker build -t chaoscraft/control-plane:latest .
	cd agents/kubernetes && docker build -t chaoscraft/chaos-agent:latest .

test: ## Run unit tests
	@echo "Running unit tests..."
	cd control-plane && go test -v -race -cover ./...

test-integration: ## Run integration tests
	@echo "Running integration tests..."
	cd control-plane && go test -v -tags=integration ./test/integration/...

test-e2e: ## Run end-to-end tests
	@echo "Running E2E tests..."
	./scripts/e2e-test.sh

test-coverage: ## Generate test coverage report
	@echo "Generating coverage report..."
	cd control-plane && go test -coverprofile=coverage.out ./...
	cd control-plane && go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: control-plane/coverage.html"

lint: ## Run linters
	@echo "Running linters..."
	cd control-plane && golangci-lint run
	helm lint charts/control-plane
	helm lint charts/chaos-agent

fmt: ## Format code
	@echo "Formatting code..."
	cd control-plane && go fmt ./...
	cd agents/kubernetes && go fmt ./...

##@ Cluster Management

cluster-create: ## Create local kind cluster
	@echo "Creating kind cluster: $(CLUSTER_NAME)"
	kind create cluster --name $(CLUSTER_NAME) --config $(KIND_CONFIG)
	@echo "Installing metrics-server..."
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
	kubectl patch -n kube-system deployment metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
	@echo "Cluster created successfully!"
	@echo "Run 'kubectl get nodes' to verify"

cluster-delete: ## Delete local kind cluster
	@echo "Deleting kind cluster: $(CLUSTER_NAME)"
	kind delete cluster --name $(CLUSTER_NAME)

cluster-info: ## Display cluster information
	@echo "Cluster: $(CLUSTER_NAME)"
	@kubectl cluster-info
	@kubectl get nodes

##@ Infrastructure

argocd-install: ## Install ArgoCD
	@echo "Installing ArgoCD..."
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml
	@echo "Waiting for ArgoCD to be ready..."
	kubectl wait --for=condition=available --timeout=300s -n argocd deployment/argocd-server
	@echo "ArgoCD installed! Access UI:"
	@echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
	@echo "  Username: admin"
	@echo "  Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"

observability-install: ## Install observability stack (Prometheus, Grafana, Loki)
	@echo "Installing observability stack..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring \
		--values charts/observability/prometheus-values.yaml
	helm upgrade --install loki grafana/loki-stack \
		--namespace monitoring \
		--values charts/observability/loki-values.yaml
	@echo "Observability stack installed!"
	@echo "Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
	@echo "Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"

##@ Deployment

deploy: build-docker ## Deploy ChaosCraft to cluster
	@echo "Deploying ChaosCraft..."
	kind load docker-image chaoscraft/control-plane:latest --name $(CLUSTER_NAME)
	kind load docker-image chaoscraft/chaos-agent:latest --name $(CLUSTER_NAME)
	kubectl create namespace chaoscraft --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install chaoscraft-control-plane charts/control-plane \
		--namespace chaoscraft \
		--set image.tag=latest
	helm upgrade --install chaoscraft-agent charts/chaos-agent \
		--namespace chaoscraft \
		--set image.tag=latest
	@echo "ChaosCraft deployed!"
	@echo "Check status: kubectl get pods -n chaoscraft"

undeploy: ## Undeploy ChaosCraft from cluster
	@echo "Undeploying ChaosCraft..."
	helm uninstall chaoscraft-agent -n chaoscraft || true
	helm uninstall chaoscraft-control-plane -n chaoscraft || true
	kubectl delete namespace chaoscraft || true

##@ Demo

demo-setup: ## Set up demo environment
	@echo "Setting up demo environment..."
	kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f examples/demo-app/deployment.yaml
	@echo "Demo app deployed to 'demo' namespace"

demo-run: ## Run demo chaos experiment
	@echo "Running demo experiment..."
	kubectl apply -f examples/experiments/pod-kill-demo.yaml
	@echo "Watch experiment: kubectl get chaosexperiment -n demo -w"

demo-cleanup: ## Clean up demo environment
	@echo "Cleaning up demo..."
	kubectl delete namespace demo || true

##@ Utilities

logs-control-plane: ## View control plane logs
	kubectl logs -n chaoscraft -l app=chaoscraft-control-plane -f

logs-agent: ## View agent logs
	kubectl logs -n chaoscraft -l app=chaoscraft-agent -f

port-forward-control-plane: ## Port-forward control plane API
	kubectl port-forward -n chaoscraft svc/chaoscraft-control-plane 8080:8080

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf control-plane/bin
	rm -rf agents/kubernetes/bin
	rm -f control-plane/coverage.out control-plane/coverage.html

deps: ## Install development dependencies
	@echo "Installing dependencies..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/golang/mock/mockgen@latest

##@ Documentation

docs-serve: ## Serve documentation locally
	@echo "Serving documentation at http://localhost:8000"
	cd docs && python -m http.server 8000

docs-generate: ## Generate API documentation
	@echo "Generating API documentation..."
	cd control-plane && swag init -g cmd/server/main.go -o api/docs

.DEFAULT_GOAL := help
