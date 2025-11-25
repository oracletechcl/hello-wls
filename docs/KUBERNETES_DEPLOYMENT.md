# Kubernetes Deployment Guide

This guide covers deploying all Host Info application ports to Kubernetes.

## Overview

Each application port (Spring Boot, Micronaut, and Helidon) has been configured with complete Kubernetes support. Each port includes:

- **namespace.yaml** - Isolated namespace for the application
- **configmap.yaml** - Environment configuration
- **deployment.yaml** - Pod deployment specification with health checks
- **service.yaml** - Kubernetes service for internal/external access
- **ingress.yaml** - HTTP ingress configuration
- **hpa.yaml** (Micronaut & Helidon) - Horizontal Pod Autoscaler for automatic scaling

## Prerequisites

Before deploying to Kubernetes, ensure:

1. **Kubernetes Cluster**: v1.19 or later
2. **kubectl**: Latest version installed and configured
3. **Docker Registry**: Docker images pushed to an accessible registry
4. **Metrics Server** (for HPA): Required for auto-scaling features
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

## Quick Start - Deploying an Application

### Step 1: Build and Push Docker Image

Navigate to the application directory and build:

```bash
cd springboot-port  # or micronaut-port or helidon-port
./build.sh --jar
docker build -t <registry>/<image-name>:1.0.0 .
docker push <registry>/<image-name>:1.0.0
```

### Step 2: Update Image Reference

Edit `kubernetes/deployment.yaml` and update the image field:

```yaml
image: <registry>/<image-name>:1.0.0
```

### Step 3: Deploy to Kubernetes

```bash
cd kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### Step 4: (Optional) Configure External Access

For Ingress:
```bash
kubectl apply -f ingress.yaml
```

For Auto-scaling (Micronaut & Helidon):
```bash
kubectl apply -f hpa.yaml
```

## Per-Application Guides

- **Spring Boot**: [springboot-port/kubernetes/README.md](main/hello-wls/springboot-port/kubernetes/README.md)
- **Micronaut**: [micronaut-port/kubernetes/README.md](main/hello-wls/micronaut-port/kubernetes/README.md)
- **Helidon**: [helidon-port/kubernetes/README.md](main/hello-wls/helidon-port/kubernetes/README.md)

## Verification Commands

### Check Deployments

```bash
# List all namespaces
kubectl get ns

# Check deployments in hostinfo namespace
kubectl get deployments -n hostinfo

# Check pods
kubectl get pods -n hostinfo -o wide

# Check services
kubectl get svc -n hostinfo

# Check ingress
kubectl get ingress -n hostinfo

# Check HPA (if enabled)
kubectl get hpa -n hostinfo
```

### View Logs

```bash
# Stream logs for a specific pod
kubectl logs -n hostinfo <pod-name> -f

# View logs for all pods with label
kubectl logs -n hostinfo -l app=hostinfo-springboot --tail=50

# Previous logs (if pod crashed)
kubectl logs -n hostinfo <pod-name> --previous
```

### Test Connectivity

```bash
# Port forward to local machine
kubectl port-forward -n hostinfo svc/hostinfo-springboot 8080:8080

# Access in browser
open http://localhost:8080/hostinfo/
```

## Configuration Management

### Update Application Configuration

Edit the ConfigMap YAML and reapply:

```bash
kubectl apply -f kubernetes/configmap.yaml
kubectl rollout restart deployment/hostinfo-springboot -n hostinfo
```

### Modify Replicas

```bash
# Manual scaling
kubectl scale deployment hostinfo-springboot -n hostinfo --replicas=3

# Check HPA status (if enabled)
kubectl describe hpa hostinfo-springboot -n hostinfo
```

## Networking

### Cluster Internal Access

Services are accessible within the cluster at:
```
http://hostinfo-springboot:8080
http://hostinfo-micronaut:8082
http://hostinfo-helidon:8081
```

### External Access

1. **Port Forward** (Development):
   ```bash
   kubectl port-forward -n hostinfo svc/hostinfo-springboot 8080:8080
   ```

2. **NodePort** (Quick access):
   ```bash
   kubectl expose deployment hostinfo-springboot -n hostinfo --type=NodePort
   ```

3. **Ingress** (Production):
   - Update host in `ingress.yaml`
   - Update ingress controller if needed
   - Apply the ingress configuration

## Monitoring & Observability

### Health Checks

All deployments include liveness and readiness probes:

- **Spring Boot**: `/actuator/health` and `/actuator/health/readiness`
- **Micronaut**: `/health`
- **Helidon**: `/health/live` and `/health/ready`

### Metrics

Pods are annotated for Prometheus scraping:
- Path: `/metrics` or `/actuator/prometheus`
- Port: Application port
- Interval: Default Prometheus scrape interval

### Logs

Aggregate logs using:
```bash
kubectl logs -n hostinfo -l app=hostinfo-springboot -f --all-containers=true
```

## Troubleshooting

### Pod Won't Start

```bash
# Check pod events
kubectl describe pod <pod-name> -n hostinfo

# Check logs
kubectl logs <pod-name> -n hostinfo --previous

# Check node status
kubectl get nodes
```

### HPA Not Scaling

```bash
# Verify Metrics Server is running
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa hostinfo-springboot -n hostinfo
kubectl get hpa hostinfo-springboot -n hostinfo
```

### Connection Issues

```bash
# Test connectivity from inside cluster
kubectl run -it --rm debug --image=busybox:1.35 --restart=Never -- \
  wget -O- http://hostinfo-springboot:8080/hostinfo/

# Check service endpoints
kubectl get endpoints -n hostinfo
```

## Production Best Practices

1. **Resource Limits**: Set appropriate CPU/memory requests and limits (already configured)
2. **Health Checks**: Configured with appropriate timeouts and thresholds
3. **Security**: Non-root containers with read-only filesystems
4. **Scaling**: Enable HPA for automatic scaling based on metrics
5. **Ingress**: Use NGINX or other production ingress controllers
6. **TLS/SSL**: Configure ingress with TLS certificates
7. **Secrets**: Use Kubernetes Secrets for sensitive data (database credentials, etc.)
8. **RBAC**: Configure appropriate Role-Based Access Control
9. **Network Policies**: Restrict network traffic between pods
10. **Monitoring**: Integrate with Prometheus/Grafana for observability

## Cleanup

### Delete an Application

```bash
cd kubernetes
kubectl delete -f ingress.yaml
kubectl delete -f hpa.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f configmap.yaml
kubectl delete -f namespace.yaml
```

### Delete Everything

```bash
kubectl delete namespace hostinfo
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Application Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
