# NGINX Ingress Controller for OKE

This directory contains the Kubernetes manifest for deploying the NGINX Ingress Controller on Oracle Kubernetes Engine (OKE).

## Overview

The NGINX Ingress Controller provides HTTP(S) load balancing and routing for Kubernetes services. This configuration is optimized for Oracle Cloud Infrastructure (OCI) with OCI-specific annotations for the LoadBalancer service.

## Contents

| File | Description |
|------|-------------|
| `deployment.yaml` | Complete NGINX Ingress Controller deployment manifest |

## Features

- **NGINX Ingress Controller v1.14.0** - Latest stable version
- **OCI Load Balancer Integration** - Flexible shape with configurable bandwidth (10-100 Mbps)
- **Admission Webhook** - Validates Ingress resources before creation
- **Security Hardened** - Non-root containers, seccomp profiles, read-only filesystems
- **Production Ready** - Liveness/readiness probes, resource requests

## Quick Start

### Deploy the Ingress Controller

```bash
# Apply the deployment
kubectl apply -f deployment.yaml

# Verify deployment
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### Wait for Load Balancer

```bash
# Get the external IP (may take 1-2 minutes)
kubectl get svc ingress-nginx-controller -n ingress-nginx -w

# Note the EXTERNAL-IP when it appears
```

## Configuration

### OCI Load Balancer Settings

The manifest includes OCI-specific annotations for the LoadBalancer:

```yaml
annotations:
  service.beta.kubernetes.io/oci-load-balancer-shape: flexible
  service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
  service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "100"
  service.beta.kubernetes.io/oci-load-balancer-subnet1: <your-subnet-ocid>
```

**Important**: Update the subnet OCID with your OKE cluster's load balancer subnet.

### Exposed Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 80 | HTTP | Standard HTTP traffic |
| 443 | HTTPS | HTTPS traffic (TLS termination) |
| 8443 | HTTPS | Admission webhook |

## Usage with Applications

### Create an Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hostinfo-ingress
  namespace: hostinfo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: hostinfo.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: hostinfo-springboot
                port:
                  number: 8080
```

### Path-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-app-ingress
  namespace: hostinfo
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /springboot
            pathType: Prefix
            backend:
              service:
                name: hostinfo-springboot
                port:
                  number: 8080
          - path: /micronaut
            pathType: Prefix
            backend:
              service:
                name: hostinfo-micronaut
                port:
                  number: 8082
          - path: /helidon
            pathType: Prefix
            backend:
              service:
                name: hostinfo-helidon
                port:
                  number: 8081
```

## Components Deployed

| Component | Description |
|-----------|-------------|
| `Namespace` | `ingress-nginx` namespace |
| `ServiceAccount` | Controller and webhook service accounts |
| `RBAC` | Roles, ClusterRoles, and bindings |
| `ConfigMap` | Controller configuration |
| `Deployment` | NGINX Ingress Controller pods |
| `Service` | LoadBalancer for external access |
| `IngressClass` | Default `nginx` ingress class |
| `ValidatingWebhookConfiguration` | Admission webhook for validation |
| `Jobs` | Certificate generation for webhook |

## Verification

```bash
# Check controller is running
kubectl get pods -n ingress-nginx

# Check LoadBalancer service
kubectl get svc -n ingress-nginx

# Check IngressClass
kubectl get ingressclass

# Test health endpoint (via port-forward)
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
curl http://localhost:8080/healthz
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod -n ingress-nginx -l app.kubernetes.io/component=controller

# Check logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### LoadBalancer Pending

```bash
# Check OCI annotations
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml

# Verify subnet OCID is correct
# Verify OKE cluster has permissions to create load balancers
```

### Webhook Errors

```bash
# Check webhook pod
kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=admission-webhook

# Check webhook certificate job
kubectl get jobs -n ingress-nginx

# Force recreate webhook certificate
kubectl delete job ingress-nginx-admission-create -n ingress-nginx
kubectl apply -f deployment.yaml
```

## Cleanup

```bash
# Delete ingress controller
kubectl delete -f deployment.yaml

# Or delete namespace (removes everything)
kubectl delete namespace ingress-nginx
```

## Related Documentation

- [NGINX Ingress Controller Docs](https://kubernetes.github.io/ingress-nginx/)
- [OCI Load Balancer Annotations](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingloadbalancer.htm)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## Notes

1. **Subnet OCID**: Update the subnet annotation with your specific OKE subnet OCID
2. **TLS**: For production, configure TLS certificates using cert-manager or manual secrets
3. **Scaling**: Consider horizontal pod autoscaling for high-traffic scenarios
4. **Monitoring**: Enable Prometheus metrics with `--enable-metrics` controller argument
