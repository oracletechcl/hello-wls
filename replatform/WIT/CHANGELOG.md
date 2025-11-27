# WIT Script Changes - OCIR Integration

## Date: November 27, 2025

### Summary

Added automatic OCIR (Oracle Cloud Infrastructure Registry) push functionality to the WIT automation script, enabling seamless image distribution to Oracle Cloud.

### Key Changes

#### 1. OCIR Configuration

Added hardcoded OCIR configuration at the top of `wit.sh`:

```bash
# OCIR Configuration
OCIR_REGION="scl"
OCIR_NAMESPACE="idi1o0a010nx"
OCIR_REPO="dalquint-docker-images"
OCIR_REGISTRY="${OCIR_REGION}.ocir.io"
OCIR_REGISTRY_PATH="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPO}"

# OCIR image tags
OCIR_IMAGE_TAG="${OCIR_REGISTRY_PATH}/wls:12.2.1.4.0"
OCIR_IMAGE_TAG_WDT_MII="${OCIR_REGISTRY_PATH}/wls-wdt-mii:12.2.1.4.0"
OCIR_IMAGE_TAG_WDT_DII="${OCIR_REGISTRY_PATH}/wls-wdt-dii:12.2.1.4.0"
```

#### 2. OCIR Login Check Function

Added function to detect OCIR authentication across Docker and Podman:

```bash
check_ocir_login() {
    # Check both Docker and Podman auth locations
    local AUTH_FILES=(
        ~/.docker/config.json
        ${XDG_RUNTIME_DIR}/containers/auth.json
        ~/.config/containers/auth.json
    )
    
    for auth_file in "${AUTH_FILES[@]}"; do
        if [ -f "$auth_file" ] && grep -q "${OCIR_REGISTRY}" "$auth_file" 2>/dev/null; then
            return 0
        fi
    done
    
    return 1
}
```

#### 3. Push to OCIR Function

Added automated push function with authentication check:

```bash
push_to_ocir() {
    local LOCAL_IMAGE="$1"
    local OCIR_IMAGE="$2"
    
    # Check if logged in to OCIR
    if ! check_ocir_login; then
        print_warning "Not logged in to OCIR registry"
        # Displays login instructions
        return 1
    fi
    
    # Tag and push image
    docker tag "$LOCAL_IMAGE" "$OCIR_IMAGE"
    docker push "$OCIR_IMAGE"
}
```

#### 4. Automatic Push on Image Creation

Modified both base WebLogic and WDT image creation functions to automatically push after successful build:

**Base WebLogic Image:**
```bash
# After successful image creation
if [ "$PUSH_TO_OCIR" = true ]; then
    push_to_ocir "$IMAGE_TAG" "$OCIR_IMAGE_TAG"
fi
```

**WDT Domain Image:**
```bash
# After successful WDT image creation
if [ "$PUSH_TO_OCIR" = true ]; then
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_MII"
    elif [ "$DOMAIN_TYPE" = "dii" ]; then
        push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_DII"
    fi
fi
```

#### 5. Push on Existing Images

**Critical Fix:** Added push logic when images already exist locally:

**For base WebLogic image:**
```bash
if docker images -q "$IMAGE_TAG" 2>/dev/null | grep -q .; then
    print_info "Image $IMAGE_TAG already exists"
    print_warning "Skipping image creation (use --clean to rebuild)"
    
    # Still push to OCIR if enabled
    if [ "$PUSH_TO_OCIR" = true ]; then
        push_to_ocir "$IMAGE_TAG" "$OCIR_IMAGE_TAG"
    fi
    return 0
fi
```

**For WDT domain image:**
```bash
if docker images -q "$IMAGE_TAG_WDT" 2>/dev/null | grep -q .; then
    print_info "Image $IMAGE_TAG_WDT already exists"
    print_warning "Skipping image creation (use --clean to rebuild)"
    
    # Still push to OCIR if enabled
    if [ "$PUSH_TO_OCIR" = true ]; then
        if [ "$DOMAIN_TYPE" = "mii" ]; then
            push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_MII"
        elif [ "$DOMAIN_TYPE" = "dii" ]; then
            push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_DII"
        fi
    fi
    return 0
fi
```

#### 6. Non-Interactive Mode

Added `-y` / `--yes` flag for automated execution:

```bash
# Flag
INTERACTIVE_MODE=true  # Wait for user input between steps

# Modified wait_for_input function
wait_for_input() {
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read
    fi
}

# Command line parsing
-y|--yes)
    INTERACTIVE_MODE=false
    shift
    ;;
```

#### 7. New Command Line Flags

Added two new flags:

- `--no-push` - Skip OCIR push entirely
- `-y` / `--yes` - Run in non-interactive mode (skip prompts)

### Images Pushed to OCIR

After these changes, the script pushes three images to OCIR:

1. **Base WebLogic Image:**
   - Local: `wls:12.2.1.4.0`
   - OCIR: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls:12.2.1.4.0`

2. **Model-in-Image:**
   - Local: `wls-wdt:12.2.1.4.0`
   - OCIR: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0`

3. **Domain-in-Image:**
   - Local: `wls-wdt:12.2.1.4.0`
   - OCIR: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0`

### Usage Examples

**Automated DII build with OCIR push:**
```bash
./wit.sh --dii -y
```

**MII build with OCIR push:**
```bash
./wit.sh --mii -y
```

**Build without OCIR push:**
```bash
./wit.sh --dii --no-push
```

**Interactive mode (default):**
```bash
./wit.sh --dii
```

### Authentication

Users must login to OCIR before running the script:

```bash
docker login scl.ocir.io
Username: idi1o0a010nx/oracleidentitycloudservice/denny.alquinta@oracle.com
Password: <auth-token>
```

See [OCIR_LOGIN.md](OCIR_LOGIN.md) for detailed authentication instructions.

### Testing Results

✅ **Tested Scenarios:**
1. Fresh image build → Automatic push to OCIR
2. Existing images → Automatic push to OCIR (no rebuild)
3. Model-in-Image (--mii) → Correct MII tag pushed
4. Domain-in-Image (--dii) → Correct DII tag pushed
5. Non-interactive mode (-y) → No prompts, fully automated
6. Authentication detection → Works with both Docker and Podman

✅ **Verified:**
- All three images successfully pushed to OCIR
- Images available at: `scl.ocir.io/idi1o0a010nx/dalquint-docker-images/`
- Repository is public (pull without authentication)
- Script works in CI/CD scenarios with `-y` flag

### Files Modified

1. **replatform/WIT/wit.sh**
   - Added OCIR configuration variables
   - Added `check_ocir_login()` function
   - Added `push_to_ocir()` function
   - Modified image creation functions to include push
   - Added push logic to "image exists" checks
   - Added `INTERACTIVE_MODE` flag
   - Modified `wait_for_input()` function
   - Added `-y` / `--yes` command line option

2. **replatform/WIT/README.md**
   - Added non-interactive mode documentation
   - Updated OCIR configuration section

3. **replatform/WIT/OCIR_LOGIN.md**
   - Updated with correct namespace (idi1o0a010nx)
   - Updated username format documentation

### Behavior Changes

**Before:**
- No OCIR integration
- Images only available locally
- Manual tagging and pushing required

**After:**
- Automatic OCIR push for all scenarios
- Images automatically available in Oracle Cloud
- Push happens even when images already exist
- Non-interactive mode for automation
- Proper authentication detection

### Next Steps

Users can now:
1. Build and push images with a single command
2. Use OCIR images in Kubernetes deployments
3. Integrate script into CI/CD pipelines with `-y` flag
4. Deploy to OKE (Oracle Kubernetes Engine) using OCIR images
