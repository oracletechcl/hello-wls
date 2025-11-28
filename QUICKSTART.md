# Quick Start Guide

This guide provides summarized commands for all deployment options in the Host Info Modernization Workshop.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Standard WebLogic Deployment](#standard-weblogic-deployment)
- [Modernized Applications](#modernized-applications)
  - [Spring Boot](#spring-boot-deployment)
  - [Micronaut](#micronaut-deployment)
  - [Helidon](#helidon-deployment)
- [Replatforming with WebLogic Tools](#replatforming-with-weblogic-tools)
  - [WebLogic Deploy Tooling (WDT)](#weblogic-deploy-tooling-wdt)
  - [WebLogic Image Tool (WIT)](#weblogic-image-tool-wit)
  - [WebLogic Kubernetes Operator (WKO)](#weblogic-kubernetes-operator-wko)
- [Kubernetes Deployments](#kubernetes-deployments)
- [WebLogic Cluster Management](#weblogic-cluster-management)

---

## Prerequisites

| Requirement | Standard WLS | Modernized Apps | Replatforming | Kubernetes |
|-------------|--------------|-----------------|---------------|------------|
| Java 17+ (recommended) | - | ✅ | - | - |
| Java 11+ (minimum for modern) | - | ✅ | - | - |
| Java 8+ | ✅ | - | ✅ | - |
| Maven 3.6+ | ✅ | ✅ | - | - |
| Docker | - | ✅ | ✅ | - |
| kubectl | - | - | - | ✅ |
| Helm 3+ | - | - | - | ✅ |
| WebLogic 12.2.1.4 | ✅ | - | ✅ | - |

> **Note**: Modernized applications (Spring Boot 3.x, Micronaut 4.x, Helidon MP) require Java 17+ for full feature support. Some features may work with Java 11. Standard WebLogic and replatforming tools require Java 8 to match WebLogic 12.2.1.4.

---

## Standard WebLogic Deployment

### Build the WAR File

```bash
cd standard-wls-deployment
./build.sh
```

### Deploy to WebLogic Server

**Option 1: Admin Console**
1. Access WebLogic Console: `http://localhost:7001/console`
2. Navigate to Deployments → Install
3. Upload `target/hostinfo.war`

**Option 2: Autodeploy (Development Mode)**
```bash
cp target/hostinfo.war ${DOMAIN_HOME}/autodeploy/
```

**Option 3: WLST**
```bash
connect('weblogic','password','t3://localhost:7001')
deploy('hostinfo', '/path/to/target/hostinfo.war', targets='AdminServer')
```

### Access URLs

| URL | Description |
|-----|-------------|
| `http://localhost:7001/hostinfo/` | Home page |
| `http://localhost:7001/hostinfo/hostinfo` | Host information |
| `http://localhost:7001/hostinfo/database` | Database info |
| `http://localhost:7001/hostinfo/session` | Session management |
| `http://localhost:7001/hostinfo/webservice` | EJB Web Service demo |
| `http://localhost:7001/hostinfo/GreetingServiceBean?WSDL` | SOAP WSDL |

---

## Modernized Applications

### Spring Boot Deployment

#### Build and Run Locally

```bash
cd modernization-ports/springboot-port

# Build JAR only
./build.sh --jar

# Run locally
java -jar target/hostinfo.jar
```

#### Docker Deployment

```bash
# Build and run with Docker Compose
./build.sh --compose-up

# Stop and clean up
./build.sh --compose-down

# Build Docker image only
./build.sh --docker
docker run -p 8080:8080 hostinfo:springboot
```

#### Access URLs

| URL | Description |
|-----|-------------|
| `http://localhost:8080/hostinfo/` | Home page |
| `http://localhost:8080/hostinfo/api/host-info` | Host info API |
| `http://localhost:8080/hostinfo/api/database-info` | Database API |
| `http://localhost:8080/hostinfo/api/session-info` | Session API |
| `http://localhost:8080/hostinfo/api/greet?name=World` | Greeting API |
| `http://localhost:8080/hostinfo/swagger-ui.html` | Swagger UI |
| `http://localhost:8080/hostinfo/actuator/health` | Health check |

---

### Micronaut Deployment

#### Build and Run Locally

```bash
cd modernization-ports/micronaut-port

# Build JAR only
./build.sh --jar

# Run locally
java -jar target/hostinfo.jar
```

#### Docker Deployment

```bash
# Build and run with Docker Compose
./build.sh --compose-up

# Stop and clean up
./build.sh --compose-down

# Build Docker image only
./build.sh --docker
docker run -p 8080:8080 hostinfo:micronaut
```

#### Access URLs

| URL | Description |
|-----|-------------|
| `http://localhost:8080/hostinfo/` | Home page |
| `http://localhost:8080/hostinfo/api/host-info` | Host info API |
| `http://localhost:8080/hostinfo/api/database-info` | Database API |
| `http://localhost:8080/hostinfo/api/session-info` | Session API |
| `http://localhost:8080/hostinfo/api/greet?name=World` | Greeting API |
| `http://localhost:8080/hostinfo/swagger/views/swagger-ui/` | Swagger UI |
| `http://localhost:8080/hostinfo/health` | Health check |

---

### Helidon Deployment

#### Build and Run Locally

```bash
cd modernization-ports/helidon-port

# Build JAR only
./build.sh --jar

# Run locally
java -jar target/hostinfo.jar
```

#### Docker Deployment

```bash
# Build and run with Docker Compose
./build.sh --compose-up

# Stop and clean up
./build.sh --compose-down

# Build Docker image only
./build.sh --docker
docker run -p 8080:8080 hostinfo-helidon:latest
```

#### Access URLs

| URL | Description |
|-----|-------------|
| `http://localhost:8080/hostinfo/` | Home page |
| `http://localhost:8080/hostinfo/api/host-info` | Host info API |
| `http://localhost:8080/hostinfo/api/database-info` | Database API |
| `http://localhost:8080/hostinfo/api/session-info` | Session API |
| `http://localhost:8080/hostinfo/api/greet?name=World` | Greeting API |
| `http://localhost:8080/hostinfo/openapi` | OpenAPI spec |
| `http://localhost:8080/health` | Health check |

---

## Replatforming with WebLogic Tools

### WebLogic Deploy Tooling (WDT)

Discover, validate, and recreate WebLogic domains.

```bash
cd replatform/WDT

# Set environment variables
source ./setWDTEnv.sh

# Run complete WDT workflow (discover, validate, create, start)
./wdt.sh

# Reset environment (clean up created domains)
./wdt.sh --reset

# Show help
./wdt.sh --help
```

#### WDT Outputs

| File | Description |
|------|-------------|
| `wdt-output/base_domain_model.yaml` | Discovered domain model |
| `wdt-output/base_domain_archive.zip` | Application binaries |
| `wdt-output/domains/wdt-sample-domain/` | Recreated domain |

📖 Full documentation: [replatform/WDT.md](replatform/WDT.md)

---

### WebLogic Image Tool (WIT)

Build container images with WebLogic Server.

```bash
cd replatform/WIT

# Set environment variables
source ./setWITEnv.sh

# Run complete WIT workflow
./wit.sh

# Clean up Docker images and artifacts
./wit.sh --clean

# Show help
./wit.sh --help
```

#### WIT Outputs

| Item | Description |
|------|-------------|
| `wls:12.2.1.4.0` | Base WebLogic Docker image |
| `wls-wdt:12.2.1.4.0` | WebLogic image with WDT domain |
| `wit-output/` | WIT installation and logs |

📖 Full documentation: [replatform/WIT.md](replatform/WIT.md)

---

### WebLogic Kubernetes Operator (WKO)

Deploy WebLogic domains to Kubernetes.

```bash
cd replatform/WKO

# Set environment variables (if needed)
source ./.env.example

# Run WKO deployment workflow
./wko.sh
```

#### WKO Components

| Component | Purpose |
|-----------|---------|
| Operator | Manages WebLogic domains on Kubernetes |
| Traefik | Ingress controller for external access |
| Domain CRD | WebLogic domain custom resource |

📖 Full documentation: [replatform/WKO.md](replatform/WKO.md)

---

## Kubernetes Deployments

### Deploy Modernized Apps to Kubernetes

Each modernized application includes Kubernetes manifests in their `kubernetes/` directory.

```bash
# Spring Boot
cd modernization-ports/springboot-port/kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# Micronaut (includes HPA)
cd modernization-ports/micronaut-port/kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml

# Helidon (includes HPA)
cd modernization-ports/helidon-port/kubernetes
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
```

### Verify Kubernetes Deployment

```bash
# Check deployments
kubectl get deployments -n hostinfo

# Check pods
kubectl get pods -n hostinfo -o wide

# Check services
kubectl get svc -n hostinfo

# Check ingress
kubectl get ingress -n hostinfo

# View logs
kubectl logs -n hostinfo -l app=hostinfo-springboot --tail=50

# Port forward for local access
kubectl port-forward -n hostinfo svc/hostinfo-springboot 8080:8080
```

### Clean Up Kubernetes Deployment

```bash
kubectl delete namespace hostinfo
```

📖 Full documentation: [docs/KUBERNETES_DEPLOYMENT.md](docs/KUBERNETES_DEPLOYMENT.md)

---

## WebLogic Cluster Management

### Start/Stop WebLogic Cluster

```bash
# Navigate to cluster scripts
cd scripts/wls-plain-cluster

# Start cluster (Admin + Managed Servers)
./start-cluster.sh

# Monitor logs
tail -f ../../standard-wls-deployment/server-startup-scripts/logs/*.log

# Stop cluster
./stop-cluster.sh
```

📖 Full documentation: [scripts/README.md](scripts/README.md)

---

## Environment Variables Reference

### Database Configuration

All modernized applications support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_URL` | JDBC URL | Mock mode URL |
| `DB_USER` | Database username | `ADMIN` |
| `DB_PASSWORD` | Database password | (empty) |
| `MOCK_MODE` | Enable mock mode | `true` |
| `DB_SERVICE_NAME` | Oracle service name | `mock_adb_high` |
| `DB_WALLET_LOCATION` | Path to Oracle wallet | (empty) |

### Example: Run with Real Database

```bash
export DB_URL=jdbc:oracle:thin:@myadb_high?TNS_ADMIN=/path/to/wallet
export DB_USER=ADMIN
export DB_PASSWORD=YourPassword
export MOCK_MODE=false

java -jar target/hostinfo.jar
```

---

## Summary: Deployment Options

| Option | Build Command | Run Command | Access URL |
|--------|---------------|-------------|------------|
| **WebLogic WAR** | `./build.sh` | Deploy to WLS | `:7001/hostinfo/` |
| **Spring Boot** | `./build.sh --compose-up` | Auto-starts | `:8080/hostinfo/` |
| **Micronaut** | `./build.sh --compose-up` | Auto-starts | `:8080/hostinfo/` |
| **Helidon** | `./build.sh --compose-up` | Auto-starts | `:8080/hostinfo/` |
| **WDT** | `./wdt.sh` | New domain on `:8001` | `:8001/console` |
| **WIT** | `./wit.sh` | Docker image | Via container |
| **WKO** | `./wko.sh` | Kubernetes pods | Via ingress |

---

## Next Steps

1. Start with **Standard WebLogic Deployment** to understand the legacy application
2. Run **Modernized Applications** to see the same functionality with modern frameworks
3. Explore **Replatforming** to learn containerization workflows
4. Deploy to **Kubernetes** for production-ready deployments

For detailed documentation, see the [docs/](docs/) directory and individual component READMEs.
