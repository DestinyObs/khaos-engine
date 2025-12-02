# Observability Stack

Prometheus and Grafana for monitoring Kubernetes cluster metrics.

## Installation

```bash
make observability-install
```

This deploys:
- Prometheus: Metrics collection and storage
- Grafana: Visualization with pre-configured dashboards

## Access

**Prometheus:**
```bash
make prometheus-url
```

**Grafana:**
```bash
make grafana-url
```

Default Grafana credentials:
- Username: `admin`
- Password: `admin` (change on first login)

## Architecture

**Prometheus:**
- Scrapes metrics from Kubernetes API, nodes, and pods
- 15-day retention (no persistent volume)
- Exposes metrics at `:9090`

**Grafana:**
- Pre-configured Prometheus datasource
- Kubernetes cluster overview dashboard
- Exposes UI at `:3000`

## Metrics Collection

Prometheus automatically discovers and scrapes:
- Kubernetes API server
- Node metrics (CPU, memory, disk)
- Pods with annotation `prometheus.io/scrape: "true"`

## Dashboards

Pre-installed dashboards:
- Kubernetes Cluster Overview (CPU, memory usage)

Add more dashboards from [grafana.com/dashboards](https://grafana.com/grafana/dashboards/)

## Cost

LoadBalancers: +$40/month (2x NLB for Prometheus and Grafana)

## Uninstall

```bash
make observability-uninstall
```
