# WebLogic Image Tool (WIT) - Quick Reference

## Prerequisites Checklist

- [ ] Docker installed and running (18.03.1.ce+ or Podman 3.0.1+)
- [ ] Java 8+ installed with JAVA_HOME set
- [ ] WebLogic installer: `/home/opc/DevOps/fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip`
- [ ] JDK installer: `/home/opc/DevOps/jdk-8u202-linux-x64.tar.gz`

## Quick Start (3 Commands)

```bash
# 1. Set environment
source ./setWITEnv.sh

# 2. Run automation
./wit.sh

# 3. View results
cat wit-output/summary.txt
```

## Common Commands

### Automation Script

```bash
# Full automation
./wit.sh

# Clean and rebuild
./wit.sh --clean
./wit.sh

# Show help
./wit.sh --help
```

### Manual WIT Commands

```bash
# View cache
./wit-output/imagetool/bin/imagetool.sh cache listItems

# Create image
./wit-output/imagetool/bin/imagetool.sh create \
    --tag wls:12.2.1.4.0 \
    --type wls \
    --version 12.2.1.4.0 \
    --jdkVersion 8u202

# Inspect image
./wit-output/imagetool/bin/imagetool.sh inspect --image wls:12.2.1.4.0
```

### Docker Commands

```bash
# List WLS images
docker images | grep wls

# Run container
docker run -d -p 7001:7001 wls:12.2.1.4.0

# Tag and push
docker tag wls:12.2.1.4.0 myregistry.com/wls:12.2.1.4.0
docker push myregistry.com/wls:12.2.1.4.0

# Remove image
docker rmi wls:12.2.1.4.0
```

## File Locations

| File | Description | Location |
|------|-------------|----------|
| Main automation | WIT workflow script | `wit.sh` |
| Environment setup | Set variables | `setWITEnv.sh` |
| Documentation | Complete guide | `WIT.md` |
| Script help | Script usage | `README.md` |
| This file | Quick reference | `QUICKREF.md` |
| Execution logs | Detailed logs | `wit-output/logs/wit_*.log` |
| Summary | Execution summary | `wit-output/summary.txt` |
| WIT installation | ImageTool binaries | `wit-output/imagetool/` |

## Default Configuration

| Setting | Value |
|---------|-------|
| WIT Version | 1.16.1 |
| WebLogic Version | 12.2.1.4.0 |
| JDK Version | 8u202 |
| Basic Image Tag | `wls:12.2.1.4.0` |
| WDT Image Tag | `wls-wdt:12.2.1.4.0` |
| Cache Directory | `~/.imagetool-cache` |
| Work Directory | `wit-output/` |

## What the Script Does

1. ✓ **Check Prerequisites** - Verify Docker, Java, installers
2. ✓ **Download WIT** - Get latest ImageTool from GitHub
3. ✓ **Setup Cache** - Add installers to local cache
4. ✓ **Create Image** - Build WebLogic Docker image
5. ✓ **Inspect Image** - Verify image contents
6. ✓ **WDT Integration** - Create domain image (if available)
7. ✓ **Generate Summary** - Create execution report

## Output Images

| Image | Description | Size (approx) |
|-------|-------------|---------------|
| `wls:12.2.1.4.0` | Basic WebLogic Server | ~1.2 GB |
| `wls-wdt:12.2.1.4.0` | WebLogic with WDT domain | ~1.3 GB |

## Troubleshooting Quick Fixes

### Docker Not Running
```bash
sudo systemctl start docker
docker ps
```

### Permission Denied
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Cache Issues
```bash
./wit.sh --clean
./wit.sh
```

### Disk Space
```bash
df -h
docker system prune -a
```

### View Logs
```bash
tail -f wit-output/logs/wit_*.log
```

## Integration Workflow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  WDT Script │ ───> │  WIT Script │ ───> │ Kubernetes  │
│  (Domain)   │      │  (Image)    │      │ (Deploy)    │
└─────────────┘      └─────────────┘      └─────────────┘
```

1. Create domain with WDT (`../WDT/wdt.sh`)
2. Build image with WIT (`./wit.sh`)
3. Deploy to K8s (`../../modernization-ports/*/kubernetes/`)

## Next Steps After Image Creation

1. **Test Locally**
   ```bash
   docker run -d -p 7001:7001 wls:12.2.1.4.0
   curl http://localhost:7001/console
   ```

2. **Push to Registry**
   ```bash
   docker tag wls:12.2.1.4.0 myregistry.com/wls:12.2.1.4.0
   docker push myregistry.com/wls:12.2.1.4.0
   ```

3. **Deploy to Kubernetes**
   ```bash
   cd ../../modernization-ports/springboot-port/kubernetes
   kubectl apply -f namespace.yaml
   kubectl apply -f deployment.yaml
   ```

## Resources

- **Full Documentation**: `WIT.md`
- **Script Help**: `README.md`
- **Oracle Docs**: https://oracle.github.io/weblogic-image-tool/
- **GitHub**: https://github.com/oracle/weblogic-image-tool

## Support

| Issue | Solution |
|-------|----------|
| Script errors | Check `wit-output/logs/wit_*.log` |
| Docker issues | Verify `docker ps` works |
| Installer not found | Check `/home/opc/DevOps/` |
| Java issues | Set `JAVA_HOME` in `setWITEnv.sh` |
| Out of disk space | Run `docker system prune -a` |

---

**Pro Tip**: Run `./wit.sh --help` for all options and examples.
