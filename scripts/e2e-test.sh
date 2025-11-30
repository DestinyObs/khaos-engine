#!/usr/bin/env bash

set -euo pipefail

echo "Running E2E tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_start() {
    echo -e "${YELLOW}TEST: $1${NC}"
}

test_pass() {
    echo -e "${GREEN}✓ PASSED: $1${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAILED: $1${NC}"
    echo -e "${RED}  Error: $2${NC}"
    ((TESTS_FAILED++))
}

# Create temporary cluster for testing
CLUSTER_NAME="chaoscraft-e2e-test"

cleanup() {
    echo "Cleaning up test cluster..."
    kind delete cluster --name "$CLUSTER_NAME" 2>/dev/null || true
}

trap cleanup EXIT

echo "Creating test cluster..."
kind create cluster --name "$CLUSTER_NAME" --config infra/kind/cluster-config.yaml

echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Test 1: Deploy control plane
test_start "Deploy control plane"
if make deploy CLUSTER_NAME="$CLUSTER_NAME"; then
    test_pass "Control plane deployed"
else
    test_fail "Control plane deployment" "Deployment failed"
fi

# Test 2: Check control plane health
test_start "Control plane health check"
kubectl wait --for=condition=available --timeout=180s -n chaoscraft deployment/chaoscraft-control-plane
if kubectl exec -n chaoscraft deployment/chaoscraft-control-plane -- wget -qO- http://localhost:8080/health | grep -q "healthy"; then
    test_pass "Control plane is healthy"
else
    test_fail "Control plane health check" "Health endpoint not responding correctly"
fi

# Test 3: Deploy demo application
test_start "Deploy demo application"
if make demo-setup; then
    kubectl wait --for=condition=available --timeout=120s -n demo deployment/nginx
    test_pass "Demo application deployed"
else
    test_fail "Demo application deployment" "Deployment failed"
fi

# Test 4: Run chaos experiment
test_start "Run chaos experiment"
cat <<EOF | kubectl apply -f -
apiVersion: chaos.chaoscraft.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: e2e-test-pod-kill
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
  duration: 30s
EOF

# Wait for experiment to complete
sleep 35

if kubectl get chaosexperiment e2e-test-pod-kill -n demo -o jsonpath='{.status.phase}' | grep -q "Completed"; then
    test_pass "Chaos experiment completed"
else
    test_fail "Chaos experiment" "Experiment did not complete successfully"
fi

# Test 5: Verify rollback
test_start "Verify application recovered"
sleep 10
REPLICAS=$(kubectl get deployment nginx -n demo -o jsonpath='{.status.availableReplicas}')
if [ "$REPLICAS" -eq 3 ]; then
    test_pass "Application recovered to 3 replicas"
else
    test_fail "Application recovery" "Expected 3 replicas, got $REPLICAS"
fi

# Print summary
echo ""
echo "========================================="
echo "E2E Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
