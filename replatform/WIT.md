# WebLogic Image Tool (WIT) - Complete Guide

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Install WebLogic Image Tool](#step-1-install-weblogic-image-tool)
4. [Step 2: Setup Cache](#step-2-setup-cache)
5. [Step 3: Download Required Installers](#step-3-download-required-installers)
6. [Step 4: Add Installers to Cache](#step-4-add-installers-to-cache)
7. [Step 5: Create Basic WebLogic Image](#step-5-create-basic-weblogic-image)
8. [Step 6: Create Image with WDT Domain](#step-6-create-image-with-wdt-domain)
9. [Step 7: Apply Patches to Image](#step-7-apply-patches-to-image)
10. [Step 8: Update Existing Image](#step-8-update-existing-image)
11. [Step 9: Inspect and Verify Images](#step-9-inspect-and-verify-images)
12. [Advanced Topics](#advanced-topics)
13. [Troubleshooting](#troubleshooting)
14. [Script Automation](#script-automation)
15. [Conclusion](#conclusion)

## Overview

This guide provides detailed, step-by-step instructions for using **WebLogic Image Tool (WIT)** to create, update, and manage WebLogic Server container images. This document is designed for demonstration purposes and includes all commands and explanations needed to successfully execute the WIT workflow.

**WebLogic Image Tool (WIT)** is a tool that simplifies and automates the creation of container images for WebLogic Server. It helps organizations move WebLogic workloads into cloud-native environments by:

- Creating Linux-based container images with JDK and WebLogic Server
- Optionally creating WebLogic domains using WebLogic Deploy Tooling (WDT)
- Applying WebLogic Server patches
- Updating existing images with new patches or applications
- Rebasing images to new base operating systems

### Key Capabilities

With the WebLogic Image Tool you can:

✅ **Create** - Build a new container image with JDK and WebLogic installations  
✅ **Update** - Apply patches or add applications to an existing image  
✅ **Rebase** - Move a domain to a different base image or WebLogic version  
✅ **Cache** - Manage installers and patches locally  
✅ **Inspect** - View metadata and contents of created images  

## Prerequisites

### System Requirements

Before starting, ensure you have the following:

#### 1. Container Runtime

You need a container image client on your build machine:

- **Docker**: Minimum version 18.03.1.ce
  ```bash
  docker --version
  # Docker version 20.10.0 or later recommended
  ```

- **Podman**: Minimum version 3.0.1 (alternative to Docker)
  ```bash
  podman --version
  ```

#### 2. Java Development Kit

- **Java**: JDK 8 or later to run Image Tool
  ```bash
  java -version
  # Ensure JAVA_HOME is set
  echo $JAVA_HOME
  ```

#### 3. Required Installers

You will need to download from [Oracle Software Delivery Cloud](https://edelivery.oracle.com/):

- **Oracle JDK** installer (tar.gz format for Linux)
- **Oracle WebLogic Server** installer (ZIP format)

#### 4. Oracle Support Credentials

When using patching options (`--patches`, `--recommendedPatches`, `--latestPSU`), you need:

- Valid Oracle Support account credentials
- Access to Oracle Support patches

#### 5. Disk Space

- Minimum 10GB free disk space for:
  - WIT installation (~50MB)
  - Cached installers (~2-3GB)
  - Container images (~1-2GB per image)

#### 6. Optional: Bash 4.0+

For tab completion when using the `imagetool` alias (not required for `imagetool.sh` script).

### Verify Prerequisites

Run these commands to verify your environment:

```bash
# Check Docker
docker version
docker info

# Check Java
java -version
echo $JAVA_HOME

# Check available disk space
df -h

# Check if you can pull base images
docker pull ghcr.io/oracle/oraclelinux:8-slim
```

## Step 1: Install WebLogic Image Tool

### 1.1 Download WebLogic Image Tool

Download the latest WIT release from GitHub:

```bash
# Create a working directory
mkdir -p ~/wit-demo
cd ~/wit-demo

# Download the latest WIT release
curl -m 120 -fL https://github.com/oracle/weblogic-image-tool/releases/latest/download/imagetool.zip -o imagetool.zip

# Alternative: Download specific version (e.g., 1.12.1)
# curl -L https://github.com/oracle/weblogic-image-tool/releases/download/release-1.12.1/imagetool.zip -o imagetool.zip
```

**Check Latest Version**: Visit https://github.com/oracle/weblogic-image-tool/releases

### 1.2 Extract WebLogic Image Tool

```bash
# Extract the ZIP file
unzip imagetool.zip

# Verify extraction
ls -la imagetool/
```

Expected directory structure:
```
imagetool/
├── bin/
│   ├── imagetool.sh       # Main script (Linux/Mac)
│   ├── imagetool.cmd      # Main script (Windows)
│   └── setup.sh           # Setup script for aliases
├── lib/                   # JAR files and libraries
└── LICENSE.txt
```

### 1.3 Set Up Environment

```bash
# Set JAVA_HOME (adjust path to your JDK installation)
export JAVA_HOME=/opt/jdk
export PATH=$JAVA_HOME/bin:$PATH

# Add WIT to PATH
export WIT_HOME=~/wit-demo/imagetool
export PATH=$WIT_HOME/bin:$PATH

# Verify installation
imagetool.sh --version
```

### 1.4 (Optional) Set Up Bash Aliases

For easier command execution and tab completion:

```bash
# Source the setup script (Bash 4.0+ required)
source ~/wit-demo/imagetool/bin/setup.sh

# Now you can use 'imagetool' instead of 'imagetool.sh'
imagetool --version

# Enable tab completion
imagetool <TAB><TAB>
```

### 1.5 Verify Installation

```bash
# Display help
imagetool.sh --help

# You should see available commands:
# - cache
# - create
# - update
# - rebase
# - inspect
```

**Sample Output**:
```
Usage: imagetool [OPTIONS] [COMMAND]

WebLogic Image Tool

Options:
  -h, --help      Show this help message and exit.
  -v, --version   Show version information and exit.

Commands:
  cache     Manage local cache of installers and patches
  create    Create a new container image
  update    Update an existing container image
  rebase    Rebase a domain to a different base image
  inspect   Inspect the metadata for an image
```

## Step 2: Setup Cache

The WIT cache stores installers and patches locally for reuse. This improves build performance and reduces network usage.

### 2.1 Initialize Cache

The cache is automatically initialized on first use. You can check its location:

```bash
# Check cache configuration
imagetool.sh cache listItems

# By default, cache is at: ~/.imagetool/cache
# Cache metadata is at: ~/.imagetool/cache/.metadata
```

### 2.2 Configure Cache Location (Optional)

To use a custom cache location:

```bash
# Create custom cache directory
mkdir -p ~/my-wit-cache

# Set cache location
imagetool.sh cache addInstaller --help
# Note: You can set WLSIMG_CACHEDIR environment variable

export WLSIMG_CACHEDIR=~/my-wit-cache

# Verify new location
imagetool.sh cache listItems
```

### 2.3 View Cache Contents

```bash
# List all cached items
imagetool.sh cache listItems

# Expected output when empty:
# Cache contents
# (empty)
```

### 2.4 Understanding Cache Structure

The cache stores:

- **Installers**: JDK and WebLogic installers
- **Patches**: WebLogic patches from Oracle Support
- **Metadata**: Information about cached items

## Step 3: Download Required Installers

### 3.1 Access Oracle Software Delivery Cloud

1. Navigate to: https://edelivery.oracle.com/
2. Sign in with your Oracle account
3. Search for the required software

### 3.2 Download Oracle JDK

**Search for**: "Java SE Development Kit"

**Recommended Versions**:
- JDK 8u202 or later (for WebLogic 12.2.1.x)
- JDK 11 (for WebLogic 14.1.1.0)
- JDK 17 or JDK 21 (for WebLogic 14.1.2.0)

**File Format**: `jdk-8u202-linux-x64.tar.gz` or similar

**Download Location**: Create a downloads directory
```bash
mkdir -p ~/wls-installers
cd ~/wls-installers
```

**Example Files**:
- `jdk-8u202-linux-x64.tar.gz` (for JDK 8)
- `jdk-11.0.10_linux-x64_bin.tar.gz` (for JDK 11)
- `jdk-21_linux-x64_bin.tar.gz` (for JDK 21)

### 3.3 Download WebLogic Server

**Search for**: "Oracle WebLogic Server"

**Available Versions**:
- WebLogic 12.2.1.3.0
- WebLogic 12.2.1.4.0
- WebLogic 14.1.1.0.0
- WebLogic 14.1.2.0.0 (latest)

**File Format**: `fmw_14.1.2.0.0_wls_Disk1_1of1.zip` or similar

**Example Files**:
- `fmw_12.2.1.3.0_wls_Disk1_1of1.zip` (WebLogic 12.2.1.3)
- `fmw_12.2.1.4.0_wls_Disk1_1of1.zip` (WebLogic 12.2.1.4)
- `fmw_14.1.2.0.0_wls_Disk1_1of1.zip` (WebLogic 14.1.2)

### 3.4 Download WebLogic Patches (Optional)

If you plan to apply patches, download them from:

**Oracle Support**: https://support.oracle.com

1. Navigate to Patches & Updates
2. Search for WebLogic patch numbers
3. Download patch ZIP files

Common patch types:
- **PSU** (Patch Set Update): Quarterly cumulative patches
- **CPU** (Critical Patch Update): Security patches
- **SPU** (Security Patch Update): Urgent security fixes
- **One-off patches**: Specific bug fixes

**Note**: You'll need Oracle Support credentials to download patches.

### 3.5 Verify Downloaded Files

```bash
# List downloaded files
ls -lh ~/wls-installers/

# Expected files:
# jdk-8u202-linux-x64.tar.gz
# fmw_12.2.1.3.0_wls_Disk1_1of1.zip
```

## Step 4: Add Installers to Cache

### 4.1 Add JDK to Cache

```bash
# Add JDK 8u202 to cache
imagetool.sh cache addInstaller \
  --type jdk \
  --version 8u202 \
  --path ~/wls-installers/jdk-8u202-linux-x64.tar.gz

# Verify addition
imagetool.sh cache listItems
```

**Output**:
```
[INFO] Added jdk 8u202 to cache
Cache contents
jdk_8u202=~/wls-installers/jdk-8u202-linux-x64.tar.gz
```

**For other JDK versions**:
```bash
# JDK 11
imagetool.sh cache addInstaller \
  --type jdk \
  --version 11.0.10 \
  --path ~/wls-installers/jdk-11.0.10_linux-x64_bin.tar.gz

# JDK 21
imagetool.sh cache addInstaller \
  --type jdk \
  --version 21 \
  --path ~/wls-installers/jdk-21_linux-x64_bin.tar.gz
```

### 4.2 Add WebLogic Server to Cache

```bash
# Add WebLogic 12.2.1.3.0 to cache
imagetool.sh cache addInstaller \
  --type wls \
  --version 12.2.1.3.0 \
  --path ~/wls-installers/fmw_12.2.1.3.0_wls_Disk1_1of1.zip

# Verify addition
imagetool.sh cache listItems
```

**Output**:
```
[INFO] Added wls 12.2.1.3.0 to cache
Cache contents
jdk_8u202=~/wls-installers/jdk-8u202-linux-x64.tar.gz
wls_12.2.1.3.0=~/wls-installers/fmw_12.2.1.3.0_wls_Disk1_1of1.zip
```

**For other WebLogic versions**:
```bash
# WebLogic 12.2.1.4.0
imagetool.sh cache addInstaller \
  --type wls \
  --version 12.2.1.4.0 \
  --path ~/wls-installers/fmw_12.2.1.4.0_wls_Disk1_1of1.zip

# WebLogic 14.1.2.0.0
imagetool.sh cache addInstaller \
  --type wls \
  --version 14.1.2.0.0 \
  --path ~/wls-installers/fmw_14.1.2.0.0_wls_Disk1_1of1.zip
```

### 4.3 Add Patches to Cache (Optional)

```bash
# Add a patch to cache
imagetool.sh cache addEntry \
  --key 12345678_14.1.2.0.0 \
  --value ~/wls-installers/p12345678_141200_Generic.zip

# Add multiple patches
imagetool.sh cache addEntry \
  --key 87654321_14.1.2.0.0 \
  --value ~/wls-installers/p87654321_141200_Generic.zip
```

### 4.4 Verify Complete Cache

```bash
# List all cached items
imagetool.sh cache listItems
```

**Expected Output**:
```
Cache contents
jdk_8u202=~/wls-installers/jdk-8u202-linux-x64.tar.gz
wls_12.2.1.3.0=~/wls-installers/fmw_12.2.1.3.0_wls_Disk1_1of1.zip
12345678_14.1.2.0.0=~/wls-installers/p12345678_141200_Generic.zip
```

### 4.5 Delete Cache Entries (If Needed)

```bash
# Delete a specific entry
imagetool.sh cache deleteEntry --key jdk_8u202

# Clear entire cache
imagetool.sh cache clear
```

## Step 5: Create Basic WebLogic Image

### 5.1 Create Simple WebLogic Image

Create a basic WebLogic Server image with JDK and WebLogic installed:

```bash
# Create image with WebLogic 12.2.1.3.0 and JDK 8u202
imagetool.sh create \
  --tag wls:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202

# Monitor the build process
# This will take several minutes...
```

**What This Does**:
1. Pulls base image (Oracle Linux 8 Slim by default)
2. Installs JDK 8u202
3. Installs WebLogic Server 12.2.1.3.0
4. Creates final image tagged as `wls:12.2.1.3.0`

**Build Output** (abbreviated):
```
[INFO] WebLogic Image Tool version 1.12.1
[INFO] Image Tool build ID: 12345678-1234
[INFO] Building image wls:12.2.1.3.0
[INFO] Using base image: ghcr.io/oracle/oraclelinux:8-slim
[INFO] Installing JDK 8u202...
[INFO] Installing WebLogic Server 12.2.1.3.0...
[INFO] Image wls:12.2.1.3.0 created successfully!
```

### 5.2 Verify Created Image

```bash
# List Docker images
docker images | grep wls

# Expected output:
# wls   12.2.1.3.0   abc123def456   2 minutes ago   2.1GB

# Inspect image details
docker inspect wls:12.2.1.3.0
```

### 5.3 Test the Image

```bash
# Run a container to test
docker run -it --rm wls:12.2.1.3.0 bash

# Inside the container:
ls -la /u01/
# You should see:
# - jdk (Java installation)
# - oracle (WebLogic installation)

# Check Java version
/u01/jdk/bin/java -version

# Check WebLogic version
cat /u01/oracle/inventory/registry.xml | grep "WebLogic Server"

# Exit container
exit
```

### 5.4 Image Structure

The created image has this structure:

```
/u01/
├── jdk/                          # Java Development Kit
│   ├── bin/
│   ├── lib/
│   └── ...
└── oracle/                       # Oracle Home
    ├── wlserver/                # WebLogic Server
    ├── oracle_common/           # Common components
    ├── oui/                     # Oracle Universal Installer
    └── inventory/               # Installation inventory
```

## Step 6: Create Image with WDT Domain

Create an image with a WebLogic domain using WebLogic Deploy Tooling (WDT).

### 6.1 Prepare WDT Model Files

Create a simple WDT model file:

```bash
# Create models directory
mkdir -p ~/wit-demo/models

# Create a basic domain model
cat > ~/wit-demo/models/simple-domain.yaml << 'EOF'
domainInfo:
    AdminUserName: weblogic
    AdminPassword: Welcome1
    ServerStartMode: prod

topology:
    Name: base_domain
    AdminServerName: AdminServer
    Cluster:
        cluster-1:
            DynamicServers:
                ServerTemplate: cluster-1-template
                ServerNamePrefix: managed-server
                DynamicClusterSize: 2
                MaxDynamicClusterSize: 5
                CalculatedListenPorts: false
    Server:
        AdminServer:
            ListenPort: 7001
    ServerTemplate:
        cluster-1-template:
            ListenPort: 8001
            Cluster: cluster-1
EOF
```

### 6.2 Create WDT Variables File (Optional)

```bash
# Create variables file for environment-specific values
cat > ~/wit-demo/models/domain.properties << 'EOF'
ADMIN_USER=weblogic
ADMIN_PASS=Welcome1
DOMAIN_NAME=base_domain
ADMIN_PORT=7001
MANAGED_PORT=8001
EOF
```

### 6.3 Create Image with WDT Domain

```bash
# Create image with WDT domain
imagetool.sh create \
  --tag wls-domain:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --wdtModel ~/wit-demo/models/simple-domain.yaml \
  --wdtVariables ~/wit-demo/models/domain.properties \
  --wdtDomainHome /u01/domains/base_domain

# This will:
# 1. Install JDK and WebLogic
# 2. Download latest WDT
# 3. Create domain using WDT
```

**What This Does**:
1. Creates base image with JDK and WebLogic
2. Downloads and installs WebLogic Deploy Tooling
3. Creates WebLogic domain from model file
4. Domain is ready to start immediately

### 6.4 Create Model-Only Image

For Kubernetes deployments, you may want an image with just the model (domain created at runtime):

```bash
# Create model-only image
imagetool.sh create \
  --tag wls-model:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --wdtModel ~/wit-demo/models/simple-domain.yaml \
  --wdtVariables ~/wit-demo/models/domain.properties \
  --wdtModelOnly

# WDT and models are included, but domain is NOT created
# Domain will be created when container starts
```

### 6.5 Test WDT Domain Image

```bash
# Start the domain
docker run -d -p 7001:7001 --name wls-admin \
  wls-domain:12.2.1.3.0

# Monitor startup logs
docker logs -f wls-admin

# Wait for "Server state changed to RUNNING"
# Access console: http://localhost:7001/console
# Username: weblogic
# Password: Welcome1

# Stop and remove
docker stop wls-admin
docker rm wls-admin
```

## Step 7: Apply Patches to Image

### 7.1 Create Image with Latest PSU

```bash
# Create image with latest Patch Set Update
imagetool.sh create \
  --tag wls-patched:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --latestPSU \
  --user your.email@company.com \
  --passwordEnv ORACLE_SUPPORT_PASSWORD

# You'll be prompted for Oracle Support password
# Or set it in environment: export ORACLE_SUPPORT_PASSWORD=yourpassword
```

**What This Does**:
1. Connects to Oracle Support
2. Finds latest PSU for WebLogic 12.2.1.3.0
3. Downloads and applies the patch
4. Creates patched image

### 7.2 Apply Recommended Patches

```bash
# Create image with recommended patches (PSU + recommended CPUs/SPUs)
imagetool.sh create \
  --tag wls-recommended:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --recommendedPatches \
  --user your.email@company.com \
  --passwordEnv ORACLE_SUPPORT_PASSWORD
```

### 7.3 Apply Specific Patches

```bash
# Apply specific patch numbers
imagetool.sh create \
  --tag wls-custom-patches:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --patches 12345678,87654321 \
  --user your.email@company.com \
  --passwordEnv ORACLE_SUPPORT_PASSWORD

# Patches can be with or without 'p' prefix:
# --patches 12345678,p87654321
```

### 7.4 Verify Patches Applied

```bash
# Inspect image to see applied patches
imagetool.sh inspect --image wls-patched:12.2.1.3.0

# Or run OPatch inside container
docker run --rm wls-patched:12.2.1.3.0 \
  /u01/oracle/OPatch/opatch lsinventory
```

## Step 8: Update Existing Image

Update an existing WebLogic image with new patches or applications.

### 8.1 Update Image with Patches

```bash
# Update existing image with latest PSU
imagetool.sh update \
  --tag wls:12.2.1.3.0 \
  --latestPSU \
  --user your.email@company.com \
  --passwordEnv ORACLE_SUPPORT_PASSWORD

# This creates a new layer with patches applied
```

### 8.2 Update Image with Application

```bash
# Create WDT archive with application
mkdir -p ~/wit-demo/archives/wlsdeploy/applications
cp /path/to/myapp.war ~/wit-demo/archives/wlsdeploy/applications/
cd ~/wit-demo/archives
zip -r myapp-archive.zip wlsdeploy/

# Update model to include application
cat > ~/wit-demo/models/add-app.yaml << 'EOF'
appDeployments:
    Application:
        myapp:
            SourcePath: wlsdeploy/applications/myapp.war
            Target: cluster-1
            ModuleType: war
EOF

# Update image
imagetool.sh update \
  --fromImage wls-domain:12.2.1.3.0 \
  --tag wls-domain-with-app:12.2.1.3.0 \
  --wdtModel ~/wit-demo/models/add-app.yaml \
  --wdtArchive ~/wit-demo/archives/myapp-archive.zip
```

### 8.3 Update Multiple Images

```bash
# Update multiple images in sequence
for version in 12.2.1.3.0 12.2.1.4.0; do
  imagetool.sh update \
    --tag wls:${version} \
    --latestPSU \
    --user your.email@company.com \
    --passwordEnv ORACLE_SUPPORT_PASSWORD
done
```

## Step 9: Inspect and Verify Images

### 9.1 Inspect Image Metadata

```bash
# Inspect image created by WIT
imagetool.sh inspect --image wls:12.2.1.3.0

# Output shows:
# - Image layers
# - Installed components
# - Applied patches
# - Environment variables
# - Entry point
```

### 9.2 View Docker Image Details

```bash
# Docker inspect
docker inspect wls:12.2.1.3.0

# View history
docker history wls:12.2.1.3.0

# View size
docker images wls:12.2.1.3.0 --format "{{.Size}}"
```

### 9.3 Test Image Contents

```bash
# Run interactive shell in image
docker run -it --rm wls:12.2.1.3.0 bash

# Check installed Java
/u01/jdk/bin/java -version

# Check WebLogic version
cat /u01/oracle/inventory/registry.xml | grep version

# Check for domain (if created)
ls -la /u01/domains/

# Check applied patches
/u01/oracle/OPatch/opatch lsinventory

# Exit
exit
```

## Advanced Topics

### Using Custom Base Images

#### Specify Custom Base Image

```bash
# Use custom base image
imagetool.sh create \
  --tag wls-custom-base:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --fromImage registry.example.com/custom-linux:latest
```

#### Provide Base Image Properties

```bash
# Create properties file for custom base
cat > ~/wit-demo/base-image.properties << 'EOF'
packageManager=YUM
__OS__ID=ol
__OS__VERSION=8.10
EOF

# Use with custom base
imagetool.sh create \
  --tag wls-custom:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --fromImage registry.example.com/custom-linux:latest \
  --fromImageProperties ~/wit-demo/base-image.properties
```

### Adding Custom Build Commands

#### Create Additional Build Commands File

```bash
# Create custom build commands
cat > ~/wit-demo/additional-build.txt << 'EOF'
[after-fmw-install]
RUN yum install -y telnet nc
RUN echo "Custom configuration" > /u01/custom.txt

[final-build-commands]
LABEL maintainer="devops@company.com"
LABEL version="1.0"
EXPOSE 7001 7002
EOF

# Use in image creation
imagetool.sh create \
  --tag wls-custom-build:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --additionalBuildCommands ~/wit-demo/additional-build.txt
```

### Adding Additional Files

```bash
# Create additional files to include
mkdir -p ~/wit-demo/extra-files
echo "#!/bin/bash\necho 'Custom script'" > ~/wit-demo/extra-files/custom.sh

# Create build commands to copy files
cat > ~/wit-demo/copy-files.txt << 'EOF'
[final-build-commands]
COPY --chown=oracle:oracle files/custom.sh /u01/bin/
RUN chmod +x /u01/bin/custom.sh
EOF

# Create image with additional files
imagetool.sh create \
  --tag wls-with-files:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --additionalBuildFiles ~/wit-demo/extra-files/custom.sh \
  --additionalBuildCommands ~/wit-demo/copy-files.txt
```

### OpenShift Compatibility

```bash
# Create image for OpenShift
imagetool.sh create \
  --tag wls-openshift:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --target OpenShift \
  --wdtModel ~/wit-demo/models/simple-domain.yaml

# This sets group permissions to rwxrwx--- instead of rwxr-x---
```

### Using Argument Files

```bash
# Create argument file
cat > ~/wit-demo/build-args.txt << 'EOF'
create
--type wls
--version 12.2.1.3.0
--jdkVersion 8u202
--tag wls:12.2.1.3.0
--wdtModel ~/wit-demo/models/simple-domain.yaml
--latestPSU
--user your.email@company.com
--passwordEnv ORACLE_SUPPORT_PASSWORD
EOF

# Use argument file
imagetool.sh @~/wit-demo/build-args.txt
```

### Rebase Image

Move a domain from one WebLogic version to another:

```bash
# Rebase domain from 12.2.1.3.0 to 14.1.2.0.0
imagetool.sh rebase \
  --sourceImage wls-domain:12.2.1.3.0 \
  --tag wls-domain:14.1.2.0.0 \
  --version 14.1.2.0.0 \
  --jdkVersion 21

# This extracts domain, creates new base, and recreates domain
```

### Create Auxiliary Image

For WebLogic Kubernetes Operator Model-in-Image:

```bash
# Create auxiliary image with model and applications
imagetool.sh createAuxImage \
  --tag wls-aux:v1 \
  --wdtModel ~/wit-demo/models/simple-domain.yaml \
  --wdtArchive ~/wit-demo/archives/myapp-archive.zip

# Auxiliary images contain only models/applications
# Much smaller than full WebLogic images
```

### Multi-Platform Builds

```bash
# Build for specific platform
imagetool.sh create \
  --tag wls:12.2.1.3.0-arm64 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --platform linux/arm64

# Or build for multiple platforms
imagetool.sh create \
  --tag wls:12.2.1.3.0-multiarch \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --platform linux/amd64,linux/arm64 \
  --useBuildx
```

## Troubleshooting

### Common Issues

#### Issue: Cannot Connect to Docker

**Error**: "Cannot connect to the Docker daemon"

**Solution**:
```bash
# Check Docker service
sudo systemctl status docker

# Start Docker if stopped
sudo systemctl start docker

# Verify Docker access
docker ps

# Add user to docker group (requires logout/login)
sudo usermod -aG docker $USER
```

#### Issue: Out of Disk Space

**Error**: "no space left on device"

**Solution**:
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Remove unused images
docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi

# Check cache size
du -sh ~/.imagetool/cache
```

#### Issue: Installer Not Found

**Error**: "Unable to locate installer"

**Solution**:
```bash
# Verify cache contents
imagetool.sh cache listItems

# Check installer file exists
ls -lh ~/wls-installers/

# Re-add installer to cache
imagetool.sh cache addInstaller \
  --type wls \
  --version 12.2.1.3.0 \
  --path ~/wls-installers/fmw_12.2.1.3.0_wls_Disk1_1of1.zip
```

#### Issue: Oracle Support Authentication Failed

**Error**: "Failed to authenticate with Oracle Support"

**Solution**:
```bash
# Verify credentials
# Make sure email and password are correct

# Use environment variable for password
export ORACLE_SUPPORT_PASSWORD='your-password'

# Try with password file instead
echo 'your-password' > ~/.oracle-password
chmod 600 ~/.oracle-password

imagetool.sh create \
  --tag wls-patched:12.2.1.3.0 \
  --latestPSU \
  --user your.email@company.com \
  --passwordFile ~/.oracle-password
```

#### Issue: WDT Domain Creation Failed

**Error**: "WDT createDomain failed"

**Solution**:
```bash
# Validate model syntax
# Use WDT validateModel tool separately

# Check for model errors
cat ~/wit-demo/models/simple-domain.yaml

# Use --dryRun to see generated Dockerfile
imagetool.sh create \
  --tag wls-domain:12.2.1.3.0 \
  --wdtModel ~/wit-demo/models/simple-domain.yaml \
  --dryRun

# Check WDT version compatibility
imagetool.sh create --wdtVersion 3.4.2 ...
```

#### Issue: Image Build Hangs

**Problem**: Build appears stuck

**Solution**:
```bash
# Check Docker logs
docker events

# Monitor system resources
top
df -h

# Kill stuck build
docker ps -a
docker rm -f <container-id>

# Clean up build cache
docker builder prune
```

#### Issue: Cannot Pull Base Image

**Error**: "Failed to pull base image"

**Solution**:
```bash
# Test network connectivity
curl -I https://ghcr.io

# Try pulling base image manually
docker pull ghcr.io/oracle/oraclelinux:8-slim

# Use alternative base image
imagetool.sh create \
  --fromImage oraclelinux:8-slim \
  ...

# Configure proxy if needed
imagetool.sh create \
  --httpProxyUrl http://proxy:80 \
  --httpsProxyUrl http://proxy:80 \
  ...
```

### Debugging Tips

#### Enable Verbose Logging

```bash
# Set log level
export WLSIMG_LOGLEVEL=FINE

# Run with debugging
imagetool.sh --loglevel FINE create ...
```

#### Use Dry Run Mode

```bash
# See generated Dockerfile without building
imagetool.sh create \
  --tag wls:12.2.1.3.0 \
  --type wls \
  --version 12.2.1.3.0 \
  --jdkVersion 8u202 \
  --dryRun > /tmp/Dockerfile

# Review the Dockerfile
cat /tmp/Dockerfile
```

#### Keep Build Context

```bash
# Don't delete build context after failure
imagetool.sh create \
  --tag wls:12.2.1.3.0 \
  --skipcleanup \
  ...

# Build context location shown in output
# Examine files in build context
```

#### Inspect Intermediate Images

```bash
# List all images including intermediate
docker images -a

# Run shell in intermediate image
docker run -it <image-id> bash

# Check what went wrong
```

## Conclusion

This guide provides a comprehensive walkthrough for using WebLogic Image Tool. By following these steps, you can:

✅ Create container images with WebLogic Server  
✅ Apply patches and updates to images  
✅ Create domains using WebLogic Deploy Tooling  
✅ Customize images for specific requirements  
✅ Prepare images for Kubernetes deployment  
✅ Automate image creation workflows  

### Key Takeaways

1. **WIT simplifies containerization** - Automates complex image building
2. **Cache improves efficiency** - Reuse installers across builds
3. **Integration with WDT** - Create domains declaratively
4. **Patching made easy** - Apply latest patches automatically
5. **Kubernetes-ready** - Prepare images for cloud-native deployment

### Next Steps

1. Create your first WebLogic image
2. Experiment with WDT domain models
3. Apply patches to existing images
4. Deploy images to Kubernetes
5. Integrate WIT into CI/CD pipelines

---

## Script Automation

For automated execution of the WIT workflow, comprehensive scripts are provided in the `WIT/` directory.

### Directory Structure

```
docs/replatform/WIT/
├── README.md           # Script usage documentation
├── WIT.md             # This comprehensive guide
├── setWITEnv.sh       # Environment configuration
├── wit.sh             # Main automation script
└── wit-output/        # Generated files (created during execution)
    ├── imagetool/     # WIT installation
    ├── logs/          # Execution logs
    └── summary.txt    # Execution summary
```

### Quick Start with Automation

#### 1. Navigate to WIT Directory

```bash
cd docs/replatform/WIT
```

#### 2. Set Environment Variables

```bash
source ./setWITEnv.sh
```

This configures:
- `JAVA_HOME` - Path to your JDK installation
- Optional Docker configuration variables

#### 3. Run WIT Automation

```bash
./wit.sh
```

The script will automatically:
1. ✓ Check prerequisites (Docker, Java, installers)
2. ✓ Download and install WIT
3. ✓ Setup cache with JDK and WebLogic installers
4. ✓ Create basic WebLogic Docker image
5. ✓ Inspect the created image
6. ✓ Create WDT domain image (if WDT model is available)
7. ✓ Generate summary report

### Script Options

#### Clean Mode

Remove all WIT artifacts and start fresh:

```bash
./wit.sh --clean
```

This will:
- Remove all Docker images created by the script
- Delete the `wit-output` directory
- Clear the WIT cache (`~/.imagetool-cache`)

#### Help

Display usage information:

```bash
./wit.sh --help
```

### Configuration

The script uses the following default configurations:

**Installer Locations** (from `/home/opc/DevOps`):
- WebLogic: `fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip`
- JDK: `jdk-8u202-linux-x64.tar.gz`

**Default Image Tags**:
- Basic WebLogic: `wls:12.2.1.4.0`
- WDT Domain: `wls-wdt:12.2.1.4.0`

**WIT Version**: 1.16.1

To customize these values, edit the configuration section in `wit.sh`.

### Output Files

After execution, review the generated files:

```bash
# View summary
cat wit-output/summary.txt

# View detailed log
cat wit-output/logs/wit_*.log

# List Docker images created
docker images | grep wls
```

### Integration with WDT

The WIT script can automatically create images with WDT domains if you have already run the WDT automation:

1. Run WDT automation first:
```bash
cd ../WDT
./wdt.sh
```

2. Run WIT automation:
```bash
cd ../WIT
./wit.sh
```

The WIT script will detect the WDT model files and create a `wls-wdt:12.2.1.4.0` image with your domain pre-configured.

### Advanced Script Features

The `wit.sh` script provides:
- **Idempotent operations** - Can be run multiple times safely
- **Color-coded output** - Clear visual feedback
- **Interactive mode** - Press Enter to proceed between steps
- **Comprehensive logging** - All operations logged with timestamps
- **Error handling** - Exits on first error with clear messages
- **Summary generation** - Creates detailed execution summary

For complete script documentation, see `WIT/README.md`.

---

### Resources

- **Official Documentation**: https://oracle.github.io/weblogic-image-tool/
- **GitHub Repository**: https://github.com/oracle/weblogic-image-tool
- **Release Notes**: https://oracle.github.io/weblogic-image-tool/release-notes/
- **Samples**: https://oracle.github.io/weblogic-image-tool/samples/
- **WebLogic Deploy Tooling**: https://oracle.github.io/weblogic-deploy-tooling/
- **WebLogic Kubernetes Operator**: https://oracle.github.io/weblogic-kubernetes-operator/

### Support and Community

- **GitHub Issues**: Report bugs and request features
- **Oracle Support**: Contact Oracle Support for production issues
- **Public Slack**: Join #weblogic channel for community discussions

---

**Estimated Time**: 
- Manual execution: 60-90 minutes for complete workflow
- Automated script: 15-30 minutes (mostly image build time)

Good luck with your WebLogic containerization journey! 🐳🚀
