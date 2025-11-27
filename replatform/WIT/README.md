# WebLogic Image Tool (WIT) Scripts

This directory contains automation scripts for the WebLogic Image Tool (WIT) workflow.

## Directory Structure

```
WIT/
├── README.md           # This file
├── WIT.md             # Comprehensive WIT documentation
├── setWITEnv.sh       # Environment configuration
├── wit.sh             # Main automation script
└── wit-output/        # Generated files (created during execution)
    ├── imagetool/     # WIT installation
    ├── logs/          # Execution logs
    └── summary.txt    # Execution summary
```

## Prerequisites

Before running the WIT scripts, ensure you have:

1. **Docker** - Installed and running (version 18.03.1+ or Podman 3.0.1+)
2. **Java** - JDK 8 or later installed
3. **WebLogic Installer** - Located at `/home/opc/DevOps/fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip`
4. **JDK Installer** - Located at `/home/opc/DevOps/jdk-8u202-linux-x64.tar.gz`

## Quick Start

### 1. Set Environment Variables

First, source the environment setup script:

```bash
cd /path/to/hello-wls/replatform/WIT
source ./setWITEnv.sh
```

This script sets:
- `JAVA_HOME` - Path to your JDK installation
- Optional Docker configuration variables

### 2. Run WIT Automation

Execute the main automation script:

```bash
./wit.sh
```

The script will:
1. ✓ Check prerequisites (Docker, Java, installers)
2. ✓ Download and install WIT
3. ✓ Setup cache with JDK and WebLogic installers
4. ✓ Create basic WebLogic Docker image
5. ✓ Inspect the created image
6. ✓ Create WDT domain image (if WDT model is available)
7. ✓ Generate summary report

### 3. Review Results

After execution, review the generated files:

```bash
# View summary
cat wit-output/summary.txt

# View detailed log
cat wit-output/logs/wit_*.log

# List Docker images created
docker images | grep wls
```

## Script Options

### Clean Mode

Remove all WIT artifacts and start fresh:

```bash
./wit.sh --clean
```

This will:
- Remove all Docker images created by the script
- Delete the `wit-output` directory
- Clear the WIT cache (`~/.imagetool-cache`)

### Help

Display usage information:

```bash
./wit.sh --help
```

## Configuration

### Environment Variables

Edit `setWITEnv.sh` to customize:

```bash
# Java Home
export JAVA_HOME="/opt/jdk"

# Optional: Custom cache directory
export IMAGETOOL_CACHE_DIR="$HOME/.imagetool-cache"

# Optional: Docker configuration
export DOCKER_BUILDKIT=1
```

### Installer Locations

Edit `wit.sh` to change installer paths:

```bash
# Installer locations (default: /home/opc/DevOps)
INSTALLERS_DIR="/home/opc/DevOps"
WLS_INSTALLER="$INSTALLERS_DIR/fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip"
JDK_INSTALLER="$INSTALLERS_DIR/jdk-8u202-linux-x64.tar.gz"
```

### Image Tags

Customize Docker image tags in `wit.sh`:

```bash
IMAGE_TAG="wls:12.2.1.4.0"
IMAGE_TAG_WDT="wls-wdt:12.2.1.4.0"
```

## Output Files

### Log Files

Detailed execution logs are saved to:
```
wit-output/logs/wit_YYYYMMDD_HHMMSS.log
```

### Summary Report

A summary of the execution is saved to:
```
wit-output/summary.txt
```

The summary includes:
- Execution date and time
- WIT version and installation path
- Installers used
- Images created with sizes
- Cache contents
- Next steps

### Docker Images

The script creates the following Docker images:

1. **wls:12.2.1.4.0** - Basic WebLogic Server image
2. **wls-wdt:12.2.1.4.0** - WebLogic with WDT domain (if WDT model available)

View created images:
```bash
docker images | grep wls
```

## Common Tasks

### Test the Created Image

Run a container from the created image:

```bash
docker run -d -p 7001:7001 wls:12.2.1.4.0
```

### Tag and Push to Registry

Tag and push the image to a container registry:

```bash
docker tag wls:12.2.1.4.0 myregistry.com/wls:12.2.1.4.0
docker push myregistry.com/wls:12.2.1.4.0
```

### Inspect Image Contents

Use WIT to inspect the image:

```bash
./wit-output/imagetool/bin/imagetool.sh inspect --image wls:12.2.1.4.0
```

### View Cache Contents

List all items in the WIT cache:

```bash
./wit-output/imagetool/bin/imagetool.sh cache listItems
```

### Add Custom Patches

To add patches to the image, modify the `create_basic_image()` function in `wit.sh`:

```bash
"$WIT_HOME/bin/imagetool.sh" create \
    --tag "$IMAGE_TAG" \
    --type wls \
    --version "$WLS_VERSION" \
    --jdkVersion "$JDK_VERSION" \
    --patches 12345678,87654321 \
    --latestPSU
```

## Integration with WDT

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

## Troubleshooting

### Docker Not Found

**Error**: `Docker is not installed or not in PATH`

**Solution**: Install Docker or add it to PATH:
```bash
# Check if Docker is installed
which docker

# Add Docker to PATH if needed
export PATH="/usr/bin:$PATH"
```

### Java Not Found

**Error**: `JAVA_HOME is not set or invalid`

**Solution**: Set JAVA_HOME in `setWITEnv.sh`:
```bash
export JAVA_HOME="/path/to/jdk"
```

### Installers Not Found

**Error**: `WebLogic installer not found` or `JDK installer not found`

**Solution**: 
1. Download installers from Oracle
2. Place them in `/home/opc/DevOps/`
3. Or update paths in `wit.sh`

### Image Creation Failed

**Error**: `Failed to create image`

**Solution**:
1. Check the log file for details
2. Verify Docker is running: `docker ps`
3. Check disk space: `df -h`
4. Review cache: `./wit-output/imagetool/bin/imagetool.sh cache listItems`

### Cache Issues

**Error**: `Failed to add installer to cache`

**Solution**:
1. Clear cache and try again:
```bash
./wit.sh --clean
./wit.sh
```

2. Manually verify installer files:
```bash
ls -lh /home/opc/DevOps/*.zip
ls -lh /home/opc/DevOps/*.tar.gz
```

## Advanced Usage

### Manual WIT Commands

After running the automation, you can use WIT manually:

```bash
cd wit-output/imagetool

# Create custom image
./bin/imagetool.sh create \
    --tag custom-wls:latest \
    --type wls \
    --version 12.2.1.4.0 \
    --jdkVersion 8u202 \
    --additionalBuildCommands /path/to/custom-build.txt

# Update existing image
./bin/imagetool.sh update \
    --tag wls:12.2.1.4.0 \
    --patches 12345678

# Rebase image
./bin/imagetool.sh rebase \
    --sourceImage wls:12.2.1.4.0 \
    --tag wls:12.2.1.4.0-new-base \
    --targetImage oraclelinux:8-slim
```

### Custom Base Images

To use a custom base image, modify the `create_basic_image()` function:

```bash
"$WIT_HOME/bin/imagetool.sh" create \
    --tag "$IMAGE_TAG" \
    --type wls \
    --version "$WLS_VERSION" \
    --jdkVersion "$JDK_VERSION" \
    --fromImage oraclelinux:8-slim
```

## Next Steps

After creating your WebLogic images:

1. **Test Locally**: Run containers from the images
2. **Push to Registry**: Tag and push to your container registry
3. **Deploy to Kubernetes**: Use the manifests in `modernization-ports/*/kubernetes/`
4. **Configure Monitoring**: Add monitoring tools to your images
5. **Automate CI/CD**: Integrate WIT into your CI/CD pipeline

## Resources

- **WIT Documentation**: `WIT.md` (comprehensive guide)
- **WIT GitHub**: https://github.com/oracle/weblogic-image-tool
- **Oracle Documentation**: https://oracle.github.io/weblogic-image-tool/
- **WDT Integration**: `../WDT/README.md`

## Support

For issues or questions:
1. Review the log files in `wit-output/logs/`
2. Check the troubleshooting section in `WIT.md`
3. Review Oracle WIT documentation
4. Check the GitHub issues page

---

**Note**: This automation script is designed for development and testing. For production use, customize the script according to your organization's requirements and best practices.
