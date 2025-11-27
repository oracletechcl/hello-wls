# WebLogic Deploy Tooling (WDT) Scripts

This directory contains automated scripts for working with WebLogic Deploy Tooling (WDT).

## Overview

WDT provides a declarative, model-driven approach to WebLogic Server domain lifecycle management. These scripts automate the complete WDT workflow for discovering, modeling, and recreating WebLogic domains.

## Directory Structure

```
replatform/
├── WDT.md                    # Complete WDT documentation (manual and automated workflows)
├── WDT/                      # WDT scripts directory (THIS DIRECTORY)
│   ├── README.md            # This file
│   ├── wdt.sh               # Main automation script
│   └── setWDTEnv.sh         # Environment configuration
└── wdt-output/               # Generated artifacts (created by wdt.sh)
    ├── weblogic-deploy/     # WDT installation
    ├── base_domain_model.yaml
    ├── base_domain_archive.zip
    ├── base_domain_variables.properties
    ├── .wdt_passphrase
    └── domains/
        └── wdt-sample-domain/
```

## Scripts

### wdt.sh

Main automation script that performs the complete WDT workflow.

**Purpose**: Automates domain discovery, validation, creation, and startup using WDT.

**Features**:
- Downloads and installs WDT 4.3.8
- Discovers existing WebLogic domain
- Creates portable model, archive, and variable files
- Applies +1000 port offset to avoid conflicts
- Validates the model
- Creates new domain from model
- Starts the new domain
- Provides reset functionality

**Usage**:
```bash
cd replatform/WDT

# Run complete workflow (non-interactive by default)
./wdt.sh -c

# Run with interactive prompts between steps
./wdt.sh -c --interactive

# Create domain without starting it
./wdt.sh -c -n

# Reset and clean everything
./wdt.sh --reset

# Display help
./wdt.sh --help
```

**Options**:
- `-c, --clean`: Clean all WDT artifacts before starting
- `-n, --no-run`: Create domain but do not start it
- `--interactive`: Interactive mode (prompt between steps)
- `--non-interactive`: Non-interactive mode (default, no prompts)
- `-h, --help`: Display help message
- `-r, --reset`: Delete created domain and all WDT artifacts

### setWDTEnv.sh

Environment configuration script that sets required variables.

**Purpose**: Defines persistent environment variables for WDT operations.

**Variables Set**:
- `ORACLE_HOME`: WebLogic Server installation directory (`/home/opc/wls`)
- `JAVA_HOME`: JDK installation directory (`/opt/jdk`)
- `PATH`: Updated to include Java and WebLogic binaries

**Usage**:
This file is automatically sourced by `wdt.sh`. You can also source it manually:
```bash
source ./setWDTEnv.sh
```

**Customization**:
Edit this file to match your environment if paths differ:
```bash
export ORACLE_HOME="/your/weblogic/installation"
export JAVA_HOME="/your/jdk/installation"
```

## Quick Start

1. **Navigate to the WDT directory**:
   ```bash
   cd /path/to/hello-wls/replatform/WDT
   ```

2. **Ensure source domain is running**:
   ```bash
   # Verify base_domain exists
   ls -la /home/opc/wls/user_projects/domains/base_domain
   ```

3. **Run the automation script**:
   ```bash
   # Run in non-interactive mode (default)
   ./wdt.sh -c
   
   # Run with interactive prompts between steps
   ./wdt.sh -c --interactive
   
   # Show help and available options
   ./wdt.sh --help
   ```

4. **Monitor the process**:
   - Script will download WDT if needed
   - Discover the source domain
   - Create new domain with +1000 port offset
   - Start the new domain

5. **Access the new domain**:
   - Console: `http://localhost:8001/console`
   - Username: `weblogic`
   - Password: `Welcome1`

## Output Location

All WDT artifacts are created in `../wdt-output/`:

| Artifact | Location | Description |
|----------|----------|-------------|
| WDT Installation | `../wdt-output/weblogic-deploy/` | WDT tools and libraries |
| Model File | `../wdt-output/base_domain_model.yaml` | Domain configuration model |
| Archive File | `../wdt-output/base_domain_archive.zip` | Application binaries |
| Variable File | `../wdt-output/base_domain_variables.properties` | Configuration variables |
| New Domain | `../wdt-output/domains/wdt-sample-domain/` | Created domain |
| Logs | `../wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/` | Server logs |

## Port Configuration

The script creates a new domain with a **+1000 port offset** to avoid conflicts:

| Server | Original Port | New Port |
|--------|---------------|----------|
| AdminServer | 7001 | **8001** |
| SSL Port | 7002 | **8002** |
| Additional Ports | 7003, 7004, etc. | **8003, 8004**, etc. |

This allows both domains to run simultaneously.

## Common Workflows

### Complete Workflow

```bash
cd replatform/WDT

# Run full workflow
./wdt.sh

# Access console
# http://localhost:8001/console
```

### Reset and Retry

```bash
cd replatform/WDT

# Clean everything
./wdt.sh --reset

# Run again
./wdt.sh
```

### Monitor Logs

```bash
# View domain startup log
tail -f ../wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/wdt-sample-domain_admin.log

# View server log
tail -f ../wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/AdminServer.log
```

### Explore Model

```bash
# View discovered model
cat ../wdt-output/base_domain_model.yaml

# Use Model Help tool
cd ../wdt-output/weblogic-deploy/bin
./modelHelp.sh -oracle_home $ORACLE_HOME top
```

## Troubleshooting

### Environment Variables Not Set

**Error**: "ORACLE_HOME not set"

**Solution**: Edit `setWDTEnv.sh` with correct paths:
```bash
vim setWDTEnv.sh
# Update ORACLE_HOME and JAVA_HOME
```

### Port Already in Use

**Error**: Port 8001 conflicts

**Solution**: Reset and check for running processes:
```bash
./wdt.sh --reset
sudo lsof -i :8001
```

### Application Not Found

**Error**: Missing hostinfo.war during discovery

**Solution**: Create symlink:
```bash
mkdir -p /home/opc/DevOps/hello-wls/target
ln -s /path/to/actual/hostinfo.war /home/opc/DevOps/hello-wls/target/hostinfo.war
```

### Domain Creation Fails

**Solution**: Check logs and reset:
```bash
# View errors
tail -50 ../wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/*.log

# Reset and retry
./wdt.sh --reset
./wdt.sh
```

## Integration with Other Labs

The WDT workflow can be used for:
- **Domain Migration**: Move domains between environments
- **Configuration as Code**: Version control domain configurations
- **Kubernetes Deployment**: Prepare domains for WebLogic Kubernetes Operator
- **Environment Consistency**: Ensure dev/test/prod parity
- **Disaster Recovery**: Quick domain recreation from models

## Related Documentation

- **Complete WDT Guide**: `../WDT.md` (comprehensive manual and automated workflows)
- **WDT Official Docs**: https://oracle.github.io/weblogic-deploy-tooling/
- **Model Schema**: Use `modelHelp.sh` tool in WDT installation
- **WebLogic Setup**: `../../APACHE_WEBLOGIC_SETUP.md`

## Requirements

- **WebLogic Server**: 12.2.1.4 or later
- **Java**: JDK 1.8 (must match WebLogic installation)
- **Source Domain**: Existing domain at `/home/opc/wls/user_projects/domains/base_domain`
- **Disk Space**: Minimum 500MB for WDT artifacts and new domain
- **Network**: Internet access to download WDT from GitHub
- **Permissions**: Read access to source domain

## Best Practices

1. **Always reset before running**: Ensures clean state
   ```bash
   ./wdt.sh --reset && ./wdt.sh
   ```

2. **Review model before creation**: Verify port offsets and configurations
   ```bash
   cat ../wdt-output/base_domain_model.yaml
   ```

3. **Monitor logs during startup**: Catch issues early
   ```bash
   tail -f ../wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/*.log
   ```

4. **Version control your models**: Commit generated models to git
   ```bash
   git add ../wdt-output/*.yaml
   git commit -m "WDT domain model"
   ```

5. **Test in non-production first**: Validate workflow before production use

---

**Maintained by**: WebLogic Workshop Team  
**Last Updated**: November 27, 2025  
**WDT Version**: 4.3.8
