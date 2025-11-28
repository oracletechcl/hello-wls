# Host Info Modernization Workshop

This repository demonstrates the complete lifecycle of WebLogic Server (WLS) application modernization - from running legacy Java EE applications on WebLogic Server, to replatforming with containers and Kubernetes, to full modernization using cloud-native Java frameworks.

## 🎯 What This Repository Covers

1. **Legacy WebLogic Application** - Traditional Java EE app with Servlets, EJB, and JAX-WS
2. **Replatforming** - Containerize WebLogic workloads using WDT, WIT, and WKO
3. **Modernization** - Port to Spring Boot, Micronaut, and Helidon frameworks
4. **Kubernetes Deployment** - Deploy modernized apps to Kubernetes with ingress

## 📁 Repository Structure

```
hello-wls/
├── standard-wls-deployment/     # Legacy WebLogic Java EE application
├── modernization-ports/         # Modernized framework ports
│   ├── springboot-port/         # Spring Boot 3.x port
│   ├── micronaut-port/          # Micronaut 4.x port
│   └── helidon-port/            # Helidon MP port
├── replatform/                  # WebLogic replatforming tools
│   ├── WDT/                     # WebLogic Deploy Tooling scripts
│   ├── WIT/                     # WebLogic Image Tool scripts
│   └── WKO/                     # WebLogic Kubernetes Operator configs
├── ingress-controller/          # Kubernetes ingress configuration
├── scripts/                     # Centralized lab scripts
│   └── wls-plain-cluster/       # WebLogic cluster management
└── docs/                        # Comprehensive documentation
    ├── APACHE_WEBLOGIC_SETUP.md
    ├── KUBERNETES_DEPLOYMENT.md
    ├── MIGRATION_SUMMARY.md
    └── SPRINGBOOT_MIGRATION.md
```

## 🏗️ Architecture Overview

### The Host Info Application

The Host Info application is a demonstration web application that provides:

| Feature | Description |
|---------|-------------|
| **Host Information** | Hostname, IP, OS, Java version, memory stats |
| **Database Connectivity** | Oracle Autonomous Database with connection pooling |
| **Session Management** | HTTP session tracking and persistence |
| **Greeting Service** | REST/SOAP service demonstrating business logic |

### API Endpoints

All versions of the application expose these REST endpoints:

| Endpoint | Description |
|----------|-------------|
| `/api/host-info` | System and host information |
| `/api/database-info` | Database connection status |
| `/api/session-info` | Session details and statistics |
| `/api/greet?name={name}` | Personalized greeting |
| `/api/welcome` | Welcome message with timestamp |
| `/api/service-info` | Service metadata |
| `/swagger-ui.html` | Interactive API documentation |
| `/health` | Health check endpoint |

## 🚀 Quick Start

For a complete command reference for all deployments, see **[QUICKSTART.md](QUICKSTART.md)**.

### Option 1: Standard WebLogic Deployment

```bash
cd standard-wls-deployment
./build.sh
# Deploy target/hostinfo.war to WebLogic Server
```

### Option 2: Modernized Spring Boot

```bash
cd modernization-ports/springboot-port
./build.sh --compose-up
# Access at http://localhost:8080/hostinfo/
```

### Option 3: Modernized Micronaut

```bash
cd modernization-ports/micronaut-port
./build.sh --compose-up
# Access at http://localhost:8080/hostinfo/
```

### Option 4: Modernized Helidon

```bash
cd modernization-ports/helidon-port
./build.sh --compose-up
# Access at http://localhost:8080/hostinfo/
```

## 📚 Documentation

### Deployment Guides

| Document | Description |
|----------|-------------|
| [QUICKSTART.md](QUICKSTART.md) | Quick command reference for all deployments |
| [docs/KUBERNETES_DEPLOYMENT.md](docs/KUBERNETES_DEPLOYMENT.md) | Kubernetes deployment guide |
| [docs/APACHE_WEBLOGIC_SETUP.md](docs/APACHE_WEBLOGIC_SETUP.md) | Apache proxy configuration |

### Migration Guides

| Document | Description |
|----------|-------------|
| [docs/SPRINGBOOT_MIGRATION.md](docs/SPRINGBOOT_MIGRATION.md) | WebLogic to Spring Boot migration |
| [docs/MIGRATION_SUMMARY.md](docs/MIGRATION_SUMMARY.md) | Migration status and summary |

### Replatforming Guides

| Document | Description |
|----------|-------------|
| [replatform/WDT.md](replatform/WDT.md) | WebLogic Deploy Tooling guide |
| [replatform/WIT.md](replatform/WIT.md) | WebLogic Image Tool guide |
| [replatform/WKO.md](replatform/WKO.md) | WebLogic Kubernetes Operator guide |

## 🔧 Components

### Standard WebLogic Deployment

The original Java EE application demonstrating:
- **Servlets** for request handling
- **EJB 3.x** Stateless Session Beans
- **JAX-WS** SOAP Web Services
- **Oracle UCP** Connection Pooling
- **WebLogic Session Management**

📖 [standard-wls-deployment/README.md](standard-wls-deployment/README.md)

### Modernization Ports

Three modernized versions using cloud-native Java frameworks:

| Framework | Key Features | Startup Time |
|-----------|--------------|--------------|
| **Spring Boot 3.x** | Embedded Tomcat, Spring MVC, Actuator | ~5 seconds |
| **Micronaut 4.x** | Embedded Netty, AOT compilation, GraalVM ready | ~1 second |
| **Helidon MP** | MicroProfile, JAX-RS, CDI | ~2 seconds |

Each port includes:
- ✅ REST APIs with JSON responses
- ✅ Swagger/OpenAPI documentation
- ✅ Health check endpoints
- ✅ HikariCP connection pooling
- ✅ Docker and Docker Compose support
- ✅ Kubernetes manifests

📖 Detailed READMEs:
- [modernization-ports/springboot-port/README.md](modernization-ports/springboot-port/README.md)
- [modernization-ports/micronaut-port/README.md](modernization-ports/micronaut-port/README.md)
- [modernization-ports/helidon-port/README.md](modernization-ports/helidon-port/README.md)

### Replatforming Tools

Scripts and configurations for containerizing WebLogic workloads:

| Tool | Purpose |
|------|---------|
| **WDT** | Discover domains, create models, validate configurations |
| **WIT** | Build container images with WebLogic and domains |
| **WKO** | Deploy and manage WebLogic domains on Kubernetes |

📖 Tool documentation in [replatform/](replatform/)

### Scripts

Centralized lab scripts for common operations:

```bash
# Start WebLogic cluster
./scripts/wls-plain-cluster/start-cluster.sh

# Stop WebLogic cluster
./scripts/wls-plain-cluster/stop-cluster.sh
```

📖 [scripts/README.md](scripts/README.md)

## 🎓 Workshop Labs

### Lab 1: Traditional WebLogic Deployment
1. Build the WAR file with `./build.sh`
2. Deploy to WebLogic Server
3. Access Host Info, Database, Session, and Web Service demos

### Lab 2: Replatforming with WDT/WIT/WKO
1. Discover domain with WDT: `./replatform/WDT/wdt.sh`
2. Build container image with WIT: `./replatform/WIT/wit.sh`
3. Deploy to Kubernetes with WKO: `./replatform/WKO/wko.sh`

### Lab 3: Application Modernization
1. Compare three modernization approaches
2. Build and run Spring Boot, Micronaut, and Helidon versions
3. Deploy to Kubernetes with provided manifests

## 📊 Comparison: WebLogic vs Modernized Frameworks

| Aspect | WebLogic 12.2.1.4 | Spring Boot 3.x | Micronaut 4.x | Helidon MP |
|--------|-------------------|-----------------|---------------|------------|
| **Packaging** | WAR | JAR | JAR | JAR |
| **Server** | External | Embedded Tomcat | Embedded Netty | Embedded |
| **Startup** | ~60 seconds | ~5 seconds | ~1 second | ~2 seconds |
| **Memory** | 512+ MB | ~256 MB | ~128 MB | ~150 MB |
| **Container** | Required | Optional | Optional | Optional |
| **Standards** | Java EE | Spring | Micronaut | MicroProfile |

## 🔗 Related Resources

- [WebLogic Documentation](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/)
- [WebLogic Deploy Tooling](https://oracle.github.io/weblogic-deploy-tooling/)
- [WebLogic Image Tool](https://oracle.github.io/weblogic-image-tool/)
- [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/)
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Micronaut Documentation](https://micronaut.io/documentation.html)
- [Helidon Documentation](https://helidon.io/docs/latest/)

## 📝 License

Copyright (c) Oracle Corporation
