# WebLogic Kubernetes Operator (WKO) Scripts

This directory contains automation scripts for deploying WebLogic Server domains to Kubernetes using the WebLogic Kubernetes Operator.

## Overview

The WebLogic Kubernetes Operator enables running WebLogic Server domains on Kubernetes with automated lifecycle management, scaling, and monitoring capabilities. This script automates the complete deployment workflow from operator installation to domain deployment and verification.

## Quick Start

### Prerequisites

1. **Kubernetes Cluster** - Running and accessible via kubectl
2. **kubectl** - Installed and configured
3. **Helm 3.x** - Installed
4. **Images in OCIR** - Already built and pushed (public repositories):
   - MII: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0`
   - DII: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0`

### Basic Usage

```bash
cd /path/to/hello-wls/replatform/WKO

# Deploy with Model-in-Image (recommended, non-interactive by default)
./wko.sh --mii

# Deploy with Domain-in-Image
./wko.sh --dii

# Deploy with interactive prompts between steps
./wko.sh --mii --interactive

# Show help
./wko.sh --help
```

## Domain Types

### Model-in-Image (MII) - Recommended

**Command:** `./wko.sh --mii`

Model-in-Image is the recommended approach where:
- WDT model files are in an auxiliary image
- Domain is created at runtime by the operator
- Configuration updates don't require image rebuilds
- Better suited for CI/CD and Kubernetes deployments

**Use when:**
- Deploying new applications to Kubernetes
- Need flexible configuration management
- Want to follow Oracle's recommended practices

### Domain-in-Image (DII)

**Command:** `./wko.sh --dii`

Domain-in-Image contains a complete pre-created domain:
- Domain fully configured in the container image
- Faster startup (domain already created)
- **Note:** Deprecated in WKO 4.0+

**Use when:**
- Migrating traditional WebLogic deployments
- Need compatibility with existing workflows
- Domain configuration rarely changes

## Script Options

```
Usage: ./wko.sh [OPTIONS]

Options:
  --mii                Create Model-in-Image domain (default)
  --dii                Create Domain-in-Image domain
  --clean              Clean all WKO resources before deploying
  --delete             Delete all WKO resources and exit
  --skip-operator      Skip operator installation (already installed)
  --skip-ingress       Skip ingress controller installation
  --interactive        Interactive mode (prompt between steps)
  --non-interactive    Non-interactive mode (default, no prompts)
  -h, --help           Display help message
```

## What the Script Does

### 1. Install WebLogic Kubernetes Operator

- Creates operator namespace: `weblogic-operator-ns`
- Installs operator via Helm chart
- Configures operator to manage labeled namespaces

### 2. Install Traefik Ingress Controller

- Creates ingress namespace: `traefik`
- Installs Traefik for routing external traffic
- Configures NodePorts: HTTP=30305, HTTPS=30443

### 3. Prepare Domain Namespace

Creates domain namespace based on domain type:
- **MII domains**: `wls-mii-ns` with UID `base-domain-mii`
- **DII domains**: `wls-dii-ns` with UID `base-domain-dii`
- Labels namespace for operator management
- Configures Traefik to route domain traffic

**Note:** Namespace separation allows deploying both MII and DII domains simultaneously in the same cluster.

### 4. Create Kubernetes Secrets

- WebLogic credentials: `weblogic` / `welcome1`
- Runtime encryption secret

### 5. Deploy WebLogic Domain

Creates Domain and Cluster custom resources:
- Domain UID: `base-domain-mii` or `base-domain-dii` (based on type)
- Cluster: `base_cluster` with 2 replicas
- Admin Server + 2 Managed Servers

### 6. Create Ingress Routes

- Routes `/console` to Admin Server
- Routes `/hostinfo` to cluster managed servers

### 7. Verify and Report

- Waits for domain startup
- Verifies all resources
- Generates summary report

## Examples

### Standard Deployment

```bash
# Model-in-Image deployment (recommended)
./wko.sh --mii
```

### Interactive Deployment

```bash
# Pause between steps for review
./wko.sh --mii --interactive
```

### Clean and Redeploy

```bash
# Remove existing resources and deploy fresh
./wko.sh --mii --clean
```

### Skip Already Installed Components

```bash
# Operator and ingress already installed, just deploy domain
./wko.sh --mii --skip-operator --skip-ingress
```

### Deploy Both MII and DII Simultaneously

```bash
# Deploy MII domain first
./wko.sh --mii

# Deploy DII domain (operator and ingress already installed)
./wko.sh --dii --skip-operator --skip-ingress

# Verify both domains are running
kubectl get domains -A

# Access each domain
# MII: http://<NODE_IP>:30305/console (namespace: wls-mii-ns)
# DII: http://<NODE_IP>:30305/console (namespace: wls-dii-ns)
```

### Domain-in-Image Deployment

```bash
# Deploy using Domain-in-Image (deprecated approach)
./wko.sh --dii
```

### Cleanup

```bash
# Delete all WKO resources
./wko.sh --delete

# Or interactively
./wko.sh --delete --interactive
```

## Access Information

After successful deployment:

### WebLogic Admin Console

- **Via NodePort:** `http://<NODE_IP>:30701/console`
- **Via Ingress:** `http://<NODE_IP>:30305/console`

### Application (hostinfo)

- **Via Ingress:** `http://<NODE_IP>:30305/hostinfo/`

### Credentials

- **Username:** `weblogic`
- **Password:** `welcome1`

### Get Node IP

```bash
kubectl get nodes -o wide
```

For local Kubernetes clusters (Kind, Minikube), use `localhost` or the node IP.

## Verification Commands

```bash
# Check domain status (replace with your namespace: wls-mii-ns or wls-dii-ns)
kubectl get domain base-domain-mii -n wls-mii-ns
kubectl get domain base-domain-dii -n wls-dii-ns

# View all pods in a namespace
kubectl get pods -n wls-mii-ns
kubectl get pods -n wls-dii-ns

# View all domains across all namespaces
kubectl get domains -A

# View domain details
kubectl describe domain base-domain-mii -n wls-mii-ns

# Check operator logs
kubectl logs -n weblogic-operator-ns -l app=weblogic-operator

# View admin server logs
kubectl logs -n wls-mii-ns base-domain-mii-admin-server

# Check ingress routes
kubectl get ingressroute -n wls-mii-ns
```

## Scaling

### Manual Scaling

```bash
# Scale MII cluster to 3 managed servers
kubectl patch cluster base-domain-mii-cluster-1 -n wls-mii-ns \
  --type merge \
  -p '{"spec":{"replicas":3}}'

# Scale down to 1
kubectl patch cluster base-domain-mii-cluster-1 -n wls-mii-ns \
  --type merge \
  -p '{"spec":{"replicas":1}}'

# Watch pods scale
kubectl get pods -n wls-mii-ns -w
```

### Horizontal Pod Autoscaler

Create HPA for automatic scaling:

```bash
kubectl autoscale cluster base-domain-mii-cluster-1 -n wls-mii-ns \
  --min=2 --max=5 --cpu-percent=70
```

## Output Files

After running the script, you'll find:

```
wko-output/
├── manifests/
│   ├── domain-mii.yaml    # Domain resource (MII)
│   ├── domain-dii.yaml    # Domain resource (DII)
│   └── ingress.yaml       # Ingress route
├── logs/                  # Execution logs (future)
└── summary.txt            # Deployment summary
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status (use your namespace)
kubectl get pods -n wls-mii-ns

# Describe pod for events
kubectl describe pod <pod-name> -n wls-mii-ns

# View pod logs
kubectl logs <pod-name> -n wls-mii-ns
```

### Domain Introspector Failed (MII)

```bash
# Check introspector job logs (use your domain UID)
kubectl logs -n wls-mii-ns jobs/base-domain-mii-introspector
```

### Image Pull Errors

```bash
# Verify images are accessible
docker pull scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0
```

### Operator Issues

```bash
# Check operator pods
kubectl get pods -n weblogic-operator-ns

# View operator logs
kubectl logs -n weblogic-operator-ns -c weblogic-operator deployments/weblogic-operator
```

### Ingress Not Working

```bash
# Check Traefik status
kubectl get pods -n traefik

# View Traefik logs
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Verify ingress route (use your namespace and domain UID)
kubectl describe ingressroute base-domain-mii-admin-route -n wls-mii-ns
```

## Configuration

### Namespace and Domain Naming

The script automatically assigns namespaces based on domain type:

- **MII Domains:**
  - Namespace: `wls-mii-ns`
  - Domain UID: `base-domain-mii`
  
- **DII Domains:**
  - Namespace: `wls-dii-ns`
  - Domain UID: `base-domain-dii`

This separation allows both domain types to coexist in the same cluster.

### Customize Domain Settings

Edit `wko.sh` to modify:

```bash
# Domain configuration (namespace/UID set automatically based on type)
DOMAIN_TYPE="mii"                   # 'mii' or 'dii'
DOMAIN_NAME="base_domain"           # WebLogic domain name
CLUSTER_NAME="base_cluster"         # Cluster name
INITIAL_REPLICAS=2                  # Initial managed server count

# Credentials
ADMIN_USERNAME="weblogic"           # Admin username
ADMIN_PASSWORD="welcome1"           # Admin password

# Ports
INGRESS_HTTP_PORT="30305"           # HTTP ingress port
INGRESS_HTTPS_PORT="30443"          # HTTPS ingress port
```

### Use Different Images

Modify image variables in `wko.sh`:

```bash
IMAGE_MII="your-registry/your-repo/wls-wdt-mii:tag"
IMAGE_DII="your-registry/your-repo/wls-wdt-dii:tag"
```

## Advanced Usage

### Multiple Domains

To deploy multiple domains:

1. Modify domain-specific variables:
   ```bash
   DOMAIN_NS="wls-domain2-ns"
   DOMAIN_UID="base-domain2"
   ```

2. Run the script:
   ```bash
   ./wko.sh --mii --skip-operator --skip-ingress
   ```

### Custom Resource Limits

Edit generated YAML in `wko-output/manifests/` to add resource limits:

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

Then reapply:

```bash
kubectl apply -f wko-output/manifests/domain-mii.yaml
```

## Integration with CI/CD

### Jenkins Pipeline Example

```groovy
stage('Deploy to Kubernetes') {
    steps {
        sh '''
            cd replatform/WKO
            ./wko.sh --mii --non-interactive
        '''
    }
}
```

### GitLab CI Example

```yaml
deploy-k8s:
  stage: deploy
  script:
    - cd replatform/WKO
    - ./wko.sh --mii --non-interactive
  only:
    - main
```

## Documentation

For detailed information, see:

- **[WKO.md](../WKO.md)** - Comprehensive deployment guide
- **[Official Documentation](https://oracle.github.io/weblogic-kubernetes-operator/)** - Oracle's WKO docs
- **[Quick Start](https://oracle.github.io/weblogic-kubernetes-operator/quickstart/)** - Official quick start

## Related Scripts

- **[wit.sh](../WIT/wit.sh)** - WebLogic Image Tool automation
- **[wdt.sh](../WDT/wdt.sh)** - WebLogic Deploy Tooling automation

## Support

For issues and questions:

- Check logs: `wko-output/logs/`
- Review summary: `wko-output/summary.txt`
- See troubleshooting section above
- Consult [WKO.md](../WKO.md) for detailed information
- Check [official documentation](https://oracle.github.io/weblogic-kubernetes-operator/)
