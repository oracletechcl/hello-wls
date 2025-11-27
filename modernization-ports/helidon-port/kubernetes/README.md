# Helidon Host Info - Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Helidon MP Host Information application.

## Files

- `namespace.yaml` - Kubernetes namespace for the application
- `configmap.yaml` - Configuration for the application
- `deployment.yaml` - Deployment specification with health checks
- `service.yaml` - Kubernetes service definition
- `ingress.yaml` - Ingress configuration for external access
- `hpa.yaml` - Horizontal Pod Autoscaler for automatic scaling

## Prerequisites

- A running Kubernetes cluster (v1.19+)
- `kubectl` CLI installed and configured
- Docker image of the Helidon application pushed to a registry
- Metrics Server installed (for HPA to work)

## Quick Start

### 1. Build and Push Docker Image

```bash
cd ..
./build.sh --jar
docker build -t <your-registry>/hostinfo-helidon:1.0.0 .
docker push <your-registry>/hostinfo-helidon:1.0.0
```

### 2. Update Image Reference

Edit `deployment.yaml` and update the image field:

```yaml
image: <your-registry>/hostinfo-helidon:1.0.0
```

### 3. Create Namespace

```bash
kubectl apply -f namespace.yaml
```

### 4. Deploy ConfigMap

```bash
kubectl apply -f configmap.yaml
```

### 5. Deploy the Application

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 6. (Optional) Configure Ingress

```bash
kubectl apply -f ingress.yaml
```

### 7. (Optional) Enable Auto-scaling

```bash
kubectl apply -f hpa.yaml
```

## Verification

```bash
# Check namespace
kubectl get ns

# Check deployment
kubectl get deployments -n hostinfo

# Check pods
kubectl get pods -n hostinfo

# Check services
kubectl get svc -n hostinfo

# Check HPA
kubectl get hpa -n hostinfo

# Check logs
kubectl logs -n hostinfo -l app=hostinfo-helidon

# Port forward to access locally
kubectl port-forward -n hostinfo svc/hostinfo-helidon 8081:8081
```

## Access the Application

- Via Port Forward: `http://localhost:8081/hostinfo/`
- Via Ingress (if configured): `http://hostinfo-helidon.example.com/`

## Helidon-Specific Features

The Helidon deployment includes:
- Health check endpoints for liveness and readiness probes
- Container-aware JVM configuration
- Non-root security context
- Pod disruption budget for high availability

## Configuration

The application uses environment variables defined in `configmap.yaml`. Update the ConfigMap to change:
- Application name
- Environment
- Log level
- Server port

## Cleanup

```bash
kubectl delete -f hpa.yaml
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f configmap.yaml
kubectl delete -f namespace.yaml
```

## Scaling

### Manual Scaling

```bash
kubectl scale deployment hostinfo-helidon -n hostinfo --replicas=3
```

### Auto-scaling

The HPA configuration automatically scales between 2-5 replicas based on CPU and memory usage.

```bash
kubectl get hpa -n hostinfo
kubectl describe hpa hostinfo-helidon -n hostinfo
```

## Monitoring & Health

The application exposes health endpoints:
- `/health/live` - Liveness probe
- `/health/ready` - Readiness probe
- `/metrics` - Prometheus metrics

These are used by Kubernetes probes and can integrate with monitoring tools like Prometheus.

## Troubleshooting

### HPA not scaling
Check if Metrics Server is installed:
```bash
kubectl get deployment metrics-server -n kube-system
```

### Pod stuck in pending
```bash
kubectl describe pod <pod-name> -n hostinfo
```

### Check container logs
```bash
kubectl logs -n hostinfo -l app=hostinfo-helidon --tail=100 -f
```
