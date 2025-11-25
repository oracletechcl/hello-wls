# Micronaut Host Info - Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Micronaut Host Information application.

## Files

- `namespace.yaml` - Kubernetes namespace for the application
- `configmap.yaml` - Configuration for the application
- `deployment.yaml` - Deployment specification
- `service.yaml` - Kubernetes service definition
- `ingress.yaml` - Ingress configuration for external access
- `hpa.yaml` - Horizontal Pod Autoscaler for automatic scaling

## Prerequisites

- A running Kubernetes cluster (v1.19+)
- `kubectl` CLI installed and configured
- Docker image of the Micronaut application pushed to a registry

## Quick Start

### 1. Build and Push Docker Image

```bash
cd ..
./build.sh --jar
docker build -t <your-registry>/hostinfo-micronaut:1.0.0 .
docker push <your-registry>/hostinfo-micronaut:1.0.0
```

### 2. Update Image Reference

Edit `deployment.yaml` and update the image field:

```yaml
image: <your-registry>/hostinfo-micronaut:1.0.0
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
kubectl logs -n hostinfo -l app=hostinfo-micronaut

# Port forward to access locally
kubectl port-forward -n hostinfo svc/hostinfo-micronaut 8082:8082
```

## Access the Application

- Via Port Forward: `http://localhost:8082/hostinfo/`
- Via Ingress (if configured): `http://hostinfo-micronaut.example.com/`

## Configuration

The application uses environment variables defined in `configmap.yaml`. Update the ConfigMap to change:
- Application name
- Environment
- Log level

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
kubectl scale deployment hostinfo-micronaut -n hostinfo --replicas=3
```

### Auto-scaling

The HPA configuration automatically scales between 2-5 replicas based on CPU usage.

```bash
kubectl get hpa -n hostinfo
kubectl describe hpa hostinfo-micronaut -n hostinfo
```

## Monitoring & Health

The application exposes health endpoints:
- `/health` - Health check
- `/metrics` - Metrics endpoint

These can be used with Kubernetes probes and monitoring tools.
