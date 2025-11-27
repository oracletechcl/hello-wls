# OCIR Login Guide

## Oracle Cloud Infrastructure Registry (OCIR) Configuration

### Registry Information
- **Region**: Santiago (scl)
- **Registry URL**: `scl.ocir.io`
- **Namespace**: `idi1o0a010nx`
- **Repository**: `dalquint-docker-images`

### Login to OCIR

Before pushing images to OCIR, you must authenticate:

```bash
docker login scl.ocir.io
```

When prompted:
- **Username**: `idi1o0a010nx/oracleidentitycloudservice/denny.alquinta@oracle.com` (format: namespace/idp/username)
- **Password**: Your OCI Auth Token (not your console password)

### Creating an Auth Token

1. Log into OCI Console
2. Click your profile icon (top right) → User Settings
3. Under Resources, click "Auth Tokens"
4. Click "Generate Token"
5. Give it a description (e.g., "Docker OCIR")
6. Copy the generated token immediately (you can't retrieve it later)
7. Use this token as the password when running `docker login`

### Image Naming Convention

Images pushed to OCIR follow this format:
```
scl.ocir.io/idi1o0a010nx/dalquint-docker-images/<image-name>:<tag>
```

**Examples:**
- Base WebLogic: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls:12.2.1.4.0`
- Model-in-Image: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0`
- Domain-in-Image: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0`

### Repository Access

The repository `dalquint-docker-images` is configured as **public**, so:
- ✅ Anyone can **pull** images without authentication
- ✅ You need authentication to **push** images

### Using Images from OCIR

**Pull an image:**
```bash
docker pull scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls:12.2.1.4.0
```

**In Kubernetes manifests:**
```yaml
spec:
  containers:
  - name: weblogic
    image: scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0
```

### Troubleshooting

**401 Unauthorized:**
- Verify your auth token is correct
- Ensure username format is: `namespace/username`
- Check your auth token hasn't expired

**404 Not Found:**
- Verify the repository name is correct
- Ensure the image has been pushed successfully

**Check if logged in:**
```bash
cat ~/.docker/config.json | grep scl.ocir.io
```

**View pushed images:**
```bash
docker images | grep scl.ocir.io
```

### WIT Script Integration

The `wit.sh` script automatically:
1. Builds images locally
2. Tags them with OCIR registry path
3. Pushes them to OCIR

**To disable OCIR push:**
```bash
./wit.sh --no-push
```

**To enable OCIR push (default):**
```bash
./wit.sh --mii  # Pushes Model-in-Image
./wit.sh --dii  # Pushes Domain-in-Image
```
