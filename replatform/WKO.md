# WebLogic Kubernetes Operator (WKO) Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying WebLogic Server domains to Kubernetes using the WebLogic Kubernetes Operator (WKO). The operator enables running WebLogic Server and Fusion Middleware Infrastructure domains on Kubernetes with automated lifecycle management, scaling, and monitoring capabilities.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture](#architecture)
3. [Installation Steps](#installation-steps)
4. [Domain Deployment Models](#domain-deployment-models)
5. [Verification and Access](#verification-and-access)
6. [Troubleshooting](#troubleshooting)
7. [Cleanup](#cleanup)
8. [References](#references)

## Prerequisites

### Required Tools

- **Kubernetes Cluster**: Version 1.21+ (can be local like Kind/Minikube, or cloud-based like OKE)
- **kubectl**: Kubernetes command-line tool, configured to access your cluster
- **Helm**: Version 3.x for installing operator and ingress controller
- **Docker/Podman**: For testing image accessibility

### Required Images

This guide assumes you have already built and pushed WebLogic images to Oracle Cloud Infrastructure Registry (OCIR):

- **Model-in-Image (MII)**: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0`
- **Domain-in-Image (DII)**: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0`
- **Base WebLogic**: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls:12.2.1.4.0`

### Kubernetes Resources

Minimum cluster requirements:
- **Nodes**: At least 2 worker nodes
- **CPU**: 2 cores per node
- **Memory**: 4GB RAM per node
- **Storage**: Persistent volume support (for Domain on PV)

## Architecture

### WebLogic Kubernetes Operator

The operator:
- Manages WebLogic domains as Kubernetes custom resources
- Automates domain lifecycle operations (start, stop, scale)
- Monitors domain health and performs automatic recovery
- Integrates with Kubernetes native tools for logging, monitoring, and ingress

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐    ┌─────────────────────────┐   │
│  │  Operator Namespace  │    │   Domain Namespace(s)    │   │
│  │                      │    │                          │   │
│  │  ┌───────────────┐   │    │  ┌─────────────────┐    │   │
│  │  │  WKO Operator │◄──┼────┼─►│  Domain Resource│    │   │
│  │  └───────────────┘   │    │  └─────────────────┘    │   │
│  │                      │    │                          │   │
│  │  ┌───────────────┐   │    │  ┌─────────────────┐    │   │
│  │  │  Conversion   │   │    │  │  Admin Server   │    │   │
│  │  │  Webhook      │   │    │  └─────────────────┘    │   │
│  │  └───────────────┘   │    │                          │   │
│  └──────────────────────┘    │  ┌─────────────────┐    │   │
│                              │  │ Managed Server  │    │   │
│  ┌──────────────────────┐    │  └─────────────────┘    │   │
│  │  Ingress Namespace   │    │                          │   │
│  │                      │    │  ┌─────────────────┐    │   │
│  │  ┌───────────────┐   │    │  │ Managed Server  │    │   │
│  │  │  Traefik      │◄──┼────┼─►└─────────────────┘    │   │
│  │  │  Controller   │   │    │                          │   │
│  │  └───────────────┘   │    └─────────────────────────┘   │
│  └──────────────────────┘                                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Installation Steps

### Step 1: Install the WebLogic Kubernetes Operator

#### 1.1 Create Operator Namespace

```bash
kubectl create namespace weblogic-operator-ns
```

#### 1.2 Create Service Account

```bash
kubectl create serviceaccount -n weblogic-operator-ns weblogic-operator-sa
```

#### 1.3 Add Helm Repository

```bash
helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts --force-update
helm repo update
```

#### 1.4 Install the Operator

```bash
helm install weblogic-operator weblogic-operator/weblogic-operator \
  --namespace weblogic-operator-ns \
  --set serviceAccount=weblogic-operator-sa \
  --set "enableClusterRoleBinding=true" \
  --set "domainNamespaceSelectionStrategy=LabelSelector" \
  --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
  --wait
```

**Parameters Explained:**
- `serviceAccount`: Service account for operator pods
- `enableClusterRoleBinding`: Allow operator to manage domains across namespaces
- `domainNamespaceSelectionStrategy`: Use label selector to identify managed namespaces
- `domainNamespaceLabelSelector`: Label that namespaces must have to be managed

#### 1.5 Verify Operator Installation

```bash
# Check operator pods are running
kubectl get pods -n weblogic-operator-ns

# Expected output:
# NAME                                         READY   STATUS    RESTARTS   AGE
# weblogic-operator-xxxxxxxxxx-xxxxx           1/1     Running   0          1m
# weblogic-operator-webhook-xxxxxxxxxx-xxxxx   1/1     Running   0          1m

# Check operator logs
kubectl logs -n weblogic-operator-ns -c weblogic-operator deployments/weblogic-operator
```

### Step 2: Install Ingress Controller (Traefik)

#### 2.1 Add Traefik Helm Repository

```bash
helm repo add traefik https://helm.traefik.io/traefik --force-update
helm repo update
```

#### 2.2 Create Traefik Namespace

```bash
kubectl create namespace traefik
```

#### 2.3 Install Traefik

```bash
helm install traefik-operator traefik/traefik \
  --namespace traefik \
  --set "ports.web.nodePort=30305" \
  --set "ports.websecure.nodePort=30443" \
  --set "service.type=NodePort" \
  --wait
```

**Parameters Explained:**
- `ports.web.nodePort`: HTTP port (30305)
- `ports.websecure.nodePort`: HTTPS port (30443)
- `service.type`: NodePort for direct access (use LoadBalancer for cloud)

#### 2.4 Verify Traefik Installation

```bash
# Check Traefik pod
kubectl get pods -n traefik

# Check Traefik service
kubectl get svc -n traefik
```

### Step 3: Prepare Domain Namespace

#### 3.1 Create Domain Namespace

```bash
kubectl create namespace wls-domain-ns
```

#### 3.2 Label Namespace for Operator Management

```bash
kubectl label namespace wls-domain-ns weblogic-operator=enabled
```

#### 3.3 Configure Traefik for Domain Namespace

```bash
helm upgrade traefik-operator traefik/traefik \
  --namespace traefik \
  --reuse-values \
  --set "kubernetes.namespaces={traefik,wls-domain-ns}" \
  --wait
```

### Step 4: Create Kubernetes Secrets

#### 4.1 Create Docker Registry Secret (for OCIR)

Since the images are public, this step is optional. For private repositories:

```bash
kubectl create secret docker-registry ocir-secret \
  --docker-server=scl.ocir.io \
  --docker-username='idi1o0a010nx/oracleidentitycloudservice/your-email@oracle.com' \
  --docker-password='your-auth-token' \
  --docker-email='your-email@oracle.com' \
  -n wls-domain-ns
```

#### 4.2 Create WebLogic Admin Credentials Secret

```bash
kubectl create secret generic base-domain-weblogic-credentials \
  --from-literal=username=weblogic \
  --from-literal=password=welcome1 \
  -n wls-domain-ns
```

**Note:** Password must be at least 8 characters with at least one non-alphabetical character.

#### 4.3 Create Runtime Encryption Secret

```bash
kubectl create secret generic base-domain-runtime-encryption-secret \
  --from-literal=password=welcome1 \
  -n wls-domain-ns
```

#### 4.4 Verify Secrets

```bash
kubectl get secrets -n wls-domain-ns
```

## Domain Deployment Models

### Model 1: Domain-in-Image (DII)

Domain-in-Image includes a complete WebLogic domain pre-created in the container image.

**Advantages:**
- Faster startup (domain already created)
- Simpler for traditional WebLogic deployments
- No external dependencies at runtime

**Disadvantages:**
- Deprecated in WKO 4.0+ (use for legacy migrations)
- Image must be rebuilt for configuration changes
- Larger image size

**Note:** Domain-in-Image is deprecated. Use Model-in-Image for new deployments.

#### DII Deployment Steps

1. **Create Domain Resource YAML** (`domain-dii.yaml`):

```yaml
apiVersion: weblogic.oracle/v9
kind: Domain
metadata:
  name: base-domain
  namespace: wls-domain-ns
  labels:
    weblogic.domainUID: base-domain
spec:
  # Domain basic info
  domainUID: base-domain
  domainHome: /u01/domains/base_domain
  domainHomeSourceType: Image
  
  # WebLogic image
  image: "scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0"
  imagePullPolicy: IfNotPresent
  # imagePullSecrets:              # Uncomment if using private registry
  #   - name: ocir-secret
  
  # WebLogic credentials
  webLogicCredentialsSecret:
    name: base-domain-weblogic-credentials
  
  # Include server logs in pod logs
  includeServerOutInPodLog: true
  
  # Server start policy
  serverStartPolicy: IfNeeded
  
  # Admin Server configuration
  adminServer:
    adminService:
      channels:
        - channelName: default
          nodePort: 30701
    serverPod:
      env:
        - name: JAVA_OPTIONS
          value: "-Dweblogic.StdoutDebugEnabled=false"
        - name: USER_MEM_ARGS
          value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
  
  # Clusters configuration
  clusters:
    - name: base-domain-cluster-1
  
  # Configuration for all servers
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"

---
apiVersion: weblogic.oracle/v1
kind: Cluster
metadata:
  name: base-domain-cluster-1
  namespace: wls-domain-ns
  labels:
    weblogic.domainUID: base-domain
spec:
  clusterName: base_cluster
  replicas: 2
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
```

2. **Apply Domain Resource:**

```bash
kubectl apply -f domain-dii.yaml
```

3. **Monitor Domain Startup:**

```bash
# Watch pods
kubectl get pods -n wls-domain-ns -w

# Check domain status
kubectl get domain base-domain -n wls-domain-ns -o jsonpath='{.status}' | jq .
```

### Model 2: Model-in-Image (MII) - Recommended

Model-in-Image includes WDT models in the image, with the domain created at runtime by the operator.

**Advantages:**
- Recommended approach for Kubernetes deployments
- Configuration updates without image rebuilds
- Smaller base image size
- Better suited for CI/CD pipelines

**Disadvantages:**
- Slightly longer initial startup (domain creation)
- Requires understanding of WDT model structure

#### MII Deployment Steps

1. **Create Domain Resource YAML** (`domain-mii.yaml`):

```yaml
apiVersion: weblogic.oracle/v9
kind: Domain
metadata:
  name: base-domain
  namespace: wls-domain-ns
  labels:
    weblogic.domainUID: base-domain
spec:
  # Domain basic info
  domainUID: base-domain
  domainHome: /u01/domains/base_domain
  domainHomeSourceType: FromModel
  
  # WebLogic base image
  image: "container-registry.oracle.com/middleware/weblogic:12.2.1.4"
  imagePullPolicy: IfNotPresent
  
  # Model in Image configuration
  configuration:
    model:
      domainType: WLS
      runtimeEncryptionSecret: base-domain-runtime-encryption-secret
    
    # Auxiliary images with WDT models
    initializationImages:
      - image: "scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0"
        imagePullPolicy: IfNotPresent
        # sourceModelHome: "/auxiliary/models"    # Default path
        # sourceWDTInstallHome: "/auxiliary/weblogic-deploy"  # Default path
  
  # WebLogic credentials
  webLogicCredentialsSecret:
    name: base-domain-weblogic-credentials
  
  # Include server logs in pod logs
  includeServerOutInPodLog: true
  
  # Server start policy
  serverStartPolicy: IfNeeded
  
  # Admin Server configuration
  adminServer:
    adminService:
      channels:
        - channelName: default
          nodePort: 30701
    serverPod:
      env:
        - name: JAVA_OPTIONS
          value: "-Dweblogic.StdoutDebugEnabled=false"
        - name: USER_MEM_ARGS
          value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
  
  # Clusters configuration
  clusters:
    - name: base-domain-cluster-1
  
  # Configuration for all servers
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"

---
apiVersion: weblogic.oracle/v1
kind: Cluster
metadata:
  name: base-domain-cluster-1
  namespace: wls-domain-ns
  labels:
    weblogic.domainUID: base-domain
spec:
  clusterName: base_cluster
  replicas: 2
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
```

2. **Apply Domain Resource:**

```bash
kubectl apply -f domain-mii.yaml
```

3. **Monitor Domain Startup:**

```bash
# Watch pods
kubectl get pods -n wls-domain-ns -w

# Check domain introspector job
kubectl get jobs -n wls-domain-ns

# Check domain status
kubectl get domain base-domain -n wls-domain-ns -o jsonpath='{.status}' | jq .
```

### Step 5: Create Ingress Routes

#### 5.1 Create Ingress for Admin Console and Application

Create `ingress.yaml`:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: base-domain-admin-route
  namespace: wls-domain-ns
spec:
  entryPoints:
    - web
  routes:
    - match: PathPrefix(`/console`)
      kind: Rule
      services:
        - name: base-domain-admin-server
          port: 8001
    - match: PathPrefix(`/hostinfo`)
      kind: Rule
      services:
        - name: base-domain-cluster-cluster-1
          port: 8004
```

#### 5.2 Apply Ingress

```bash
kubectl apply -f ingress.yaml
```

#### 5.3 Verify Ingress

```bash
kubectl get ingressroute -n wls-domain-ns
```

## Verification and Access

### Check Domain Status

```bash
# List all resources
kubectl get all -n wls-domain-ns

# Get domain details
kubectl describe domain base-domain -n wls-domain-ns

# Check domain status conditions
kubectl get domain base-domain -n wls-domain-ns -o jsonpath='{.status.conditions}' | jq .

# View server pods
kubectl get pods -n wls-domain-ns -l weblogic.domainUID=base-domain

# Expected pods:
# - base-domain-admin-server
# - base-domain-managed-server1
# - base-domain-managed-server2
```

### Access WebLogic Admin Console

**For Local Kubernetes (Kind, Minikube):**

```bash
# Get node IP
kubectl get nodes -o wide

# Access console at:
http://<NODE_IP>:30701/console
```

**Via Ingress (Traefik):**

```bash
# Access at:
http://<NODE_IP>:30305/console
```

**Credentials:**
- Username: `weblogic`
- Password: `welcome1`

### Access Application

```bash
# Test application via ingress
curl http://<NODE_IP>:30305/hostinfo/

# Or via browser
http://<NODE_IP>:30305/hostinfo/
```

### View Logs

```bash
# Admin Server logs
kubectl logs -n wls-domain-ns base-domain-admin-server

# Managed Server logs
kubectl logs -n wls-domain-ns base-domain-managed-server1

# Operator logs
kubectl logs -n weblogic-operator-ns -c weblogic-operator deployments/weblogic-operator

# Follow logs in real-time
kubectl logs -f -n wls-domain-ns base-domain-admin-server
```

## Scaling

### Scale Cluster Up/Down

```bash
# Scale to 3 managed servers
kubectl patch cluster base-domain-cluster-1 -n wls-domain-ns \
  --type merge \
  -p '{"spec":{"replicas":3}}'

# Scale to 1 managed server
kubectl patch cluster base-domain-cluster-1 -n wls-domain-ns \
  --type merge \
  -p '{"spec":{"replicas":1}}'

# Watch pods scale
kubectl get pods -n wls-domain-ns -w
```

### Enable Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: base-domain-hpa
  namespace: wls-domain-ns
spec:
  scaleTargetRef:
    apiVersion: weblogic.oracle/v1
    kind: Cluster
    name: base-domain-cluster-1
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod status
kubectl get pods -n wls-domain-ns

# Describe pod for events
kubectl describe pod <pod-name> -n wls-domain-ns

# Check pod logs
kubectl logs <pod-name> -n wls-domain-ns

# Check introspector job (MII only)
kubectl logs -n wls-domain-ns jobs/base-domain-introspector
```

#### 2. Image Pull Errors

```bash
# Verify secret exists
kubectl get secret ocir-secret -n wls-domain-ns

# Test image pull manually
kubectl run test-pull --image=scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0 --image-pull-policy=Always --restart=Never -n wls-domain-ns
```

#### 3. Domain Failed Status

```bash
# Get detailed domain status
kubectl get domain base-domain -n wls-domain-ns -o yaml

# Check status message
kubectl get domain base-domain -n wls-domain-ns -o jsonpath='{.status.message}'

# Check operator logs
kubectl logs -n weblogic-operator-ns -l app=weblogic-operator --tail=100
```

#### 4. Ingress Not Working

```bash
# Check ingress route
kubectl get ingressroute -n wls-domain-ns

# Check Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Verify service endpoints
kubectl get endpoints -n wls-domain-ns
```

### Debug Commands

```bash
# Get all events in namespace
kubectl get events -n wls-domain-ns --sort-by='.lastTimestamp'

# Exec into admin server pod
kubectl exec -it base-domain-admin-server -n wls-domain-ns -- /bin/bash

# Check WebLogic domain directory
kubectl exec base-domain-admin-server -n wls-domain-ns -- ls -la /u01/domains/base_domain

# Port forward to admin server
kubectl port-forward -n wls-domain-ns base-domain-admin-server 7001:7001
```

## Cleanup

### Delete Domain

```bash
# Delete domain resource
kubectl delete domain base-domain -n wls-domain-ns

# Delete cluster resource
kubectl delete cluster base-domain-cluster-1 -n wls-domain-ns

# Delete ingress
kubectl delete ingressroute base-domain-admin-route -n wls-domain-ns

# Delete secrets
kubectl delete secret base-domain-weblogic-credentials -n wls-domain-ns
kubectl delete secret base-domain-runtime-encryption-secret -n wls-domain-ns
kubectl delete secret ocir-secret -n wls-domain-ns
```

### Uninstall Ingress Controller

```bash
helm uninstall traefik-operator -n traefik
kubectl delete namespace traefik
```

### Uninstall Operator

```bash
helm uninstall weblogic-operator -n weblogic-operator-ns
kubectl delete namespace weblogic-operator-ns
```

### Delete Domain Namespace

```bash
kubectl delete namespace wls-domain-ns
```

## Best Practices

### 1. Resource Limits

Always set resource limits for production:

```yaml
serverPod:
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
```

### 2. Liveness and Readiness Probes

Customize probes for your application:

```yaml
serverPod:
  livenessProbe:
    initialDelaySeconds: 120
    periodSeconds: 30
    timeoutSeconds: 10
  readinessProbe:
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
```

### 3. Security

- Use Kubernetes secrets for credentials
- Enable RBAC for operator
- Use network policies to restrict pod communication
- Scan images for vulnerabilities
- Use private registry with pull secrets

### 4. Monitoring

- Enable Prometheus monitoring exporter
- Configure logging to external systems (ELK, Splunk)
- Set up alerts for pod failures
- Monitor resource usage

### 5. High Availability

- Run multiple managed server replicas
- Use pod anti-affinity to spread pods across nodes
- Configure persistent volumes for critical data
- Set up database connection pools properly

## References

### Official Documentation

- [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/)
- [Quick Start Guide](https://oracle.github.io/weblogic-kubernetes-operator/quickstart/)
- [Domain Resource](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/domain-resource/)
- [Model in Image](https://oracle.github.io/weblogic-kubernetes-operator/managing-domains/model-in-image/)
- [Operator Configuration](https://oracle.github.io/weblogic-kubernetes-operator/managing-operators/using-helm/)

### Related Tools

- [WebLogic Deploy Tooling (WDT)](https://oracle.github.io/weblogic-deploy-tooling/)
- [WebLogic Image Tool (WIT)](https://oracle.github.io/weblogic-image-tool/)
- [WebLogic Monitoring Exporter](https://github.com/oracle/weblogic-monitoring-exporter)
- [WebLogic Remote Console](https://oracle.github.io/weblogic-remote-console/)

### Community

- [GitHub Repository](https://github.com/oracle/weblogic-kubernetes-operator)
- [Slack Channel](https://join.slack.com/t/oracle-weblogic/shared_invite/zt-1ni1gtjv6-PGC6CQ4uIte3KBdm_67~aQ)
- [Oracle Blogs](https://blogs.oracle.com/weblogicserver/)

## Appendix

### A. Environment Variables Reference

Common environment variables for WebLogic pods:

```yaml
env:
  - name: JAVA_OPTIONS
    value: "-Dweblogic.StdoutDebugEnabled=false"
  - name: USER_MEM_ARGS
    value: "-Xms256m -Xmx1024m -XX:+UseG1GC"
  - name: ADMIN_USERNAME
    valueFrom:
      secretKeyRef:
        name: base-domain-weblogic-credentials
        key: username
  - name: ADMIN_PASSWORD
    valueFrom:
      secretKeyRef:
        name: base-domain-weblogic-credentials
        key: password
```

### B. Port Reference

Default ports used in this guide:

| Service | Port | NodePort | Description |
|---------|------|----------|-------------|
| Admin Server | 7001 | 30701 | WebLogic Admin Console |
| Managed Server 1 | 7004 | - | Application port |
| Managed Server 2 | 7005 | - | Application port |
| Traefik HTTP | 80 | 30305 | Ingress HTTP |
| Traefik HTTPS | 443 | 30443 | Ingress HTTPS |

### C. Namespace Label Reference

Labels used for operator management:

```bash
# Label namespace for operator management
kubectl label namespace <namespace> weblogic-operator=enabled

# Remove namespace from operator management
kubectl label namespace <namespace> weblogic-operator-

# View namespace labels
kubectl get namespace <namespace> --show-labels
```
