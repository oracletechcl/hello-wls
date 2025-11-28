# WebLogic Replatforming Tools

This directory contains comprehensive guides and automation scripts for replatforming WebLogic Server workloads to containers and Kubernetes.

## Overview

Replatforming enables moving traditional WebLogic deployments to cloud-native environments without rewriting application code. Oracle provides three key tools for this journey:

| Tool | Purpose | Use Case |
|------|---------|----------|
| **WDT** | WebLogic Deploy Tooling | Discover domains, create models, validate configurations |
| **WIT** | WebLogic Image Tool | Build container images with WebLogic and domains |
| **WKO** | WebLogic Kubernetes Operator | Deploy and manage domains on Kubernetes |

## Quick Start

### Prerequisites

- WebLogic Server 12.2.1.4 installed
- Docker or Podman for container builds
- Kubernetes cluster (for WKO)
- Java 8+ and Bash shell

### Recommended Workflow

1. **Discover your domain with WDT**
   ```bash
   cd WDT
   ./wdt.sh
   ```

2. **Build container images with WIT**
   ```bash
   cd WIT
   ./wit.sh --mii
   ```

3. **Deploy to Kubernetes with WKO**
   ```bash
   cd WKO
   ./wko.sh --mii
   ```

## Directory Structure

```
replatform/
├── README.md          # This file
├── WDT.md             # Comprehensive WDT guide (manual + automated)
├── WDT/               # WDT automation scripts
│   ├── wdt.sh         # Main script
│   ├── setWDTEnv.sh   # Environment configuration
│   └── README.md      # Script documentation
├── WIT.md             # Comprehensive WIT guide
├── WIT/               # WIT automation scripts
│   ├── wit.sh         # Main script
│   ├── setWITEnv.sh   # Environment configuration
│   └── README.md      # Script documentation
├── WKO.md             # Comprehensive WKO guide
└── WKO/               # WKO automation scripts
    ├── wko.sh         # Main script
    └── README.md      # Script documentation
```

## Tools Documentation

### WebLogic Deploy Tooling (WDT)

**Purpose**: Declarative, model-driven domain lifecycle management.

**Key Capabilities**:
- Discover existing domains and create portable models
- Create new domains from models
- Validate and compare models
- Update existing domains
- Prepare domains for Kubernetes

**Quick Commands**:
```bash
cd WDT

# Full workflow: discover, validate, create, start
./wdt.sh

# Reset environment
./wdt.sh --reset

# Help
./wdt.sh --help
```

📖 **Documentation**: [WDT.md](WDT.md) | [WDT/README.md](WDT/README.md)

---

### WebLogic Image Tool (WIT)

**Purpose**: Build container images with WebLogic Server.

**Key Capabilities**:
- Create images with JDK and WebLogic
- Optionally create domains using WDT
- Apply patches to images
- Update existing images
- Support for MII and DII patterns

**Quick Commands**:
```bash
cd WIT

# Build Model-in-Image (recommended)
./wit.sh --mii

# Build Domain-in-Image
./wit.sh --dii

# Clean up
./wit.sh --clean

# Help
./wit.sh --help
```

📖 **Documentation**: [WIT.md](WIT.md) | [WIT/README.md](WIT/README.md)

---

### WebLogic Kubernetes Operator (WKO)

**Purpose**: Deploy and manage WebLogic domains on Kubernetes.

**Key Capabilities**:
- Automated domain lifecycle management
- Scaling (manual and auto)
- Rolling restarts
- Monitoring integration
- Ingress configuration

**Quick Commands**:
```bash
cd WKO

# Deploy with Model-in-Image
./wko.sh --mii

# Deploy with Domain-in-Image
./wko.sh --dii

# Clean up
./wko.sh --delete

# Help
./wko.sh --help
```

📖 **Documentation**: [WKO.md](WKO.md) | [WKO/README.md](WKO/README.md)

---

## Domain Deployment Models

### Model-in-Image (MII) - Recommended

```
┌─────────────────────────────────────────────────┐
│              WebLogic Base Image                │
│  (wls:12.2.1.4.0)                              │
├─────────────────────────────────────────────────┤
│        + Auxiliary Image with WDT Model         │
│  (wls-wdt-mii:12.2.1.4.0)                      │
├─────────────────────────────────────────────────┤
│        → Domain Created at Runtime             │
│          by WKO Introspector                   │
└─────────────────────────────────────────────────┘
```

**Benefits**:
- Configuration changes without image rebuilds
- Smaller base images
- Follows Oracle's recommended pattern
- Better for CI/CD pipelines

### Domain-in-Image (DII)

```
┌─────────────────────────────────────────────────┐
│              WebLogic Image                     │
│  (wls:12.2.1.4.0)                              │
├─────────────────────────────────────────────────┤
│        + Domain Fully Created                   │
│  (wls-wdt-dii:12.2.1.4.0)                      │
├─────────────────────────────────────────────────┤
│        → Ready to Run Immediately              │
└─────────────────────────────────────────────────┘
```

**Benefits**:
- Faster startup (domain pre-created)
- Simpler for traditional migrations
- Self-contained images

**Note**: Domain-in-Image is deprecated in WKO 4.0+. Use for legacy migrations only.

## Workflow Diagrams

### End-to-End Replatforming

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   WebLogic       │     │   Container      │     │   Kubernetes     │
│   Domain         │────►│   Image          │────►│   Deployment     │
│                  │     │                  │     │                  │
│   (Traditional)  │     │   (Docker)       │     │   (Cloud-Native) │
└──────────────────┘     └──────────────────┘     └──────────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
   ┌─────────┐              ┌─────────┐              ┌─────────┐
   │   WDT   │              │   WIT   │              │   WKO   │
   │ Discover│              │  Build  │              │ Deploy  │
   │ Domain  │              │  Image  │              │ Domain  │
   └─────────┘              └─────────┘              └─────────┘
```

### Tool Integration

```
                    ┌─────────────────────────────────────┐
                    │           Source Domain             │
                    │     /domains/base_domain            │
                    └─────────────────────────────────────┘
                                     │
                                     ▼
                    ┌─────────────────────────────────────┐
                    │              WDT                    │
                    │   discoverDomain.sh                 │
                    └─────────────────────────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
             ┌────────────┐   ┌────────────┐   ┌────────────┐
             │   Model    │   │  Archive   │   │ Variables  │
             │   YAML     │   │   ZIP      │   │ Properties │
             └────────────┘   └────────────┘   └────────────┘
                    │                │                │
                    └────────────────┼────────────────┘
                                     ▼
                    ┌─────────────────────────────────────┐
                    │              WIT                    │
                    │   imagetool.sh create              │
                    └─────────────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    ▼                                 ▼
             ┌────────────┐                    ┌────────────┐
             │    MII     │                    │    DII     │
             │   Image    │                    │   Image    │
             └────────────┘                    └────────────┘
                    │                                 │
                    └────────────────┬────────────────┘
                                     ▼
                    ┌─────────────────────────────────────┐
                    │              WKO                    │
                    │   Domain Custom Resource            │
                    └─────────────────────────────────────┘
                                     │
                                     ▼
                    ┌─────────────────────────────────────┐
                    │         Kubernetes Cluster          │
                    │   Operator + Domain + Ingress       │
                    └─────────────────────────────────────┘
```

## Common Scenarios

### Scenario 1: Lift-and-Shift Migration

Migrate an existing WebLogic domain to Kubernetes with minimal changes.

```bash
# 1. Discover domain
cd WDT && ./wdt.sh

# 2. Build Domain-in-Image
cd ../WIT && ./wit.sh --dii

# 3. Deploy to Kubernetes
cd ../WKO && ./wko.sh --dii
```

### Scenario 2: Cloud-Native Deployment

Deploy a WebLogic application using recommended Kubernetes patterns.

```bash
# 1. Create/update WDT model
cd WDT && ./wdt.sh

# 2. Build Model-in-Image
cd ../WIT && ./wit.sh --mii

# 3. Deploy with WKO
cd ../WKO && ./wko.sh --mii
```

### Scenario 3: Environment Replication

Replicate a production domain for testing/development.

```bash
# 1. Discover production domain
cd WDT
./wdt.sh

# 2. Edit variables for new environment
vim ../wdt-output/base_domain_variables.properties

# 3. Create new domain from model
./wdt.sh --reset && ./wdt.sh
```

## Best Practices

1. **Start with WDT Discovery** - Always discover your existing domain first
2. **Use Model-in-Image** - Follow Oracle's recommended pattern for new deployments
3. **Version Control Models** - Commit WDT models to git
4. **Test Locally First** - Validate domains before Kubernetes deployment
5. **Automate Everything** - Integrate scripts into CI/CD pipelines
6. **Monitor Resources** - Set appropriate CPU/memory limits

## Related Documentation

- [Main README](../README.md) - Repository overview
- [QUICKSTART.md](../QUICKSTART.md) - Quick command reference
- [docs/KUBERNETES_DEPLOYMENT.md](../docs/KUBERNETES_DEPLOYMENT.md) - Kubernetes guide
- [docs/MIGRATION_SUMMARY.md](../docs/MIGRATION_SUMMARY.md) - Migration summary

## External Resources

- [WebLogic Deploy Tooling](https://oracle.github.io/weblogic-deploy-tooling/)
- [WebLogic Image Tool](https://oracle.github.io/weblogic-image-tool/)
- [WebLogic Kubernetes Operator](https://oracle.github.io/weblogic-kubernetes-operator/)
- [Oracle WebLogic Server Documentation](https://docs.oracle.com/en/middleware/fusion-middleware/weblogic-server/)
