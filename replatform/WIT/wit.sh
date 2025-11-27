#!/bin/bash

################################################################################
# WebLogic Image Tool (WIT) - Automated Demo Script
# 
# This script automates the WIT workflow documented in WIT.md
# All operations are idempotent - can be run multiple times safely
#
# Usage: ./wit.sh [options]
# Options:
#   -c, --clean     Clean all WIT artifacts before starting
#   -h, --help      Display this help message
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment file if it exists
if [ -f "$SCRIPT_DIR/setWITEnv.sh" ]; then
    source "$SCRIPT_DIR/setWITEnv.sh"
fi

WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WIT_WORK_DIR="$SCRIPT_DIR/wit-output"
WIT_VERSION="1.16.1"
WIT_DOWNLOAD_URL="https://github.com/oracle/weblogic-image-tool/releases/download/release-${WIT_VERSION}/imagetool.zip"
WIT_HOME="$WIT_WORK_DIR/imagetool"
CACHE_DIR="${IMAGETOOL_CACHE_DIR:-$HOME/.imagetool-cache}"

# Installer locations (from /home/opc/DevOps)
INSTALLERS_DIR="/home/opc/DevOps"
WLS_INSTALLER="$INSTALLERS_DIR/fmw_12.2.1.4.0_wls_lite_Disk1_1of1.zip"
JDK_INSTALLER="$INSTALLERS_DIR/jdk-8u202-linux-x64.tar.gz"

# Image configuration
WLS_VERSION="12.2.1.4.0"
JDK_VERSION="8u202"

# OCIR Configuration
OCIR_REGION="scl"
OCIR_NAMESPACE="idi1o0a010nx"
OCIR_REPO="dalquint-docker-images"
OCIR_REGISTRY="${OCIR_REGION}.ocir.io"
OCIR_REGISTRY_PATH="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPO}"

# Local image tags
IMAGE_TAG="wls:12.2.1.4.0"
IMAGE_TAG_PATCHED="wls:12.2.1.4.0-patched"
IMAGE_TAG_WDT="wls-wdt:12.2.1.4.0"

# OCIR image tags
OCIR_IMAGE_TAG="${OCIR_REGISTRY_PATH}/wls:12.2.1.4.0"
OCIR_IMAGE_TAG_WDT_MII="${OCIR_REGISTRY_PATH}/wls-wdt-mii:12.2.1.4.0"
OCIR_IMAGE_TAG_WDT_DII="${OCIR_REGISTRY_PATH}/wls-wdt-dii:12.2.1.4.0"

# WDT integration
WDT_VERSION="4.3.8"
WDT_MODEL_FILE="$SCRIPT_DIR/../WDT/wdt-output/base_domain_model.yaml"
WDT_ARCHIVE_FILE="$SCRIPT_DIR/../WDT/wdt-output/base_domain_archive.zip"
WDT_VARIABLE_FILE="$SCRIPT_DIR/../WDT/wdt-output/base_domain.properties"
WDT_DOMAIN_HOME="/u01/domains/base_domain"  # For Domain-in-Image

# Flags
CLEAN_MODE=false
DOMAIN_TYPE="mii"  # Model-in-Image (default)
PUSH_TO_OCIR=true  # Push images to OCIR by default
INTERACTIVE_MODE=true  # Wait for user input between steps

################################################################################
# Helper Functions
################################################################################

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

push_to_ocir() {
    local LOCAL_IMAGE="$1"
    local OCIR_IMAGE="$2"
    
    print_section "Pushing Image to OCIR"
    
    # Check if logged in to OCIR
    if ! check_ocir_login; then
        print_warning "Not logged in to OCIR registry: ${OCIR_REGISTRY}"
        print_info "Skipping image push. To push images later:"
        print_info ""
        print_info "1. Create an Auth Token in OCI Console:"
        print_info "   Profile Icon → User Settings → Auth Tokens → Generate Token"
        print_info ""
        print_info "2. Login to OCIR:"
        print_command "docker login ${OCIR_REGISTRY}"
        print_info "   Username: ${OCIR_NAMESPACE}/oracleidentitycloudservice/<your-email>"
        print_info "   Password: <your-auth-token>"
        print_info ""
        print_info "3. Manually push the tagged images:"
        print_command "docker push $OCIR_IMAGE"
        print_info ""
        print_warning "Images are tagged locally. Run script again after login to push."
        return 1
    fi
    
    print_step "Tagging image for OCIR: $OCIR_IMAGE"
    print_command "docker tag $LOCAL_IMAGE $OCIR_IMAGE"
    docker tag "$LOCAL_IMAGE" "$OCIR_IMAGE" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Image tagged successfully"
    else
        print_error "Failed to tag image"
        return 1
    fi
    
    print_step "Pushing image to OCIR registry: ${OCIR_REGISTRY}"
    print_info "Repository: ${OCIR_NAMESPACE}/${OCIR_REPO}"
    print_command "docker push $OCIR_IMAGE"
    
    docker push "$OCIR_IMAGE" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Image pushed successfully to OCIR"
        print_info "Image available at: $OCIR_IMAGE"
        return 0
    else
        print_error "Failed to push image to OCIR"
        print_warning "Check your OCIR credentials and try logging in again"
        return 1
    fi
}

reset_environment() {
    print_banner "Resetting WIT Environment"
    
    local items_removed=0
    
    # Remove Docker images created by this script
    print_step "Checking for Docker images to remove"
    local images_to_remove=(
        "$IMAGE_TAG"
        "$IMAGE_TAG_PATCHED"
        "$IMAGE_TAG_WDT"
    )
    
    for image in "${images_to_remove[@]}"; do
        if docker images -q "$image" 2>/dev/null | grep -q .; then
            print_info "Removing Docker image: $image"
            docker rmi -f "$image" 2>/dev/null || print_warning "Failed to remove $image"
            items_removed=$((items_removed + 1))
        fi
    done
    
    # Remove wit-output directory
    if [ -d "$WIT_WORK_DIR" ]; then
        print_step "Removing wit-output directory: $WIT_WORK_DIR"
        rm -rf "$WIT_WORK_DIR"
        print_success "WIT output directory removed"
        items_removed=$((items_removed + 1))
    fi
    
    # Clear WIT cache
    if [ -d "$CACHE_DIR" ]; then
        print_step "Clearing WIT cache: $CACHE_DIR"
        rm -rf "$CACHE_DIR"
        print_success "WIT cache cleared"
        items_removed=$((items_removed + 1))
    fi
    
    if [ $items_removed -eq 0 ]; then
        print_info "Nothing to reset - environment is clean"
    else
        print_success "Reset complete - removed $items_removed item(s)"
    fi
    
    echo ""
    print_info "You can now run the script again to start fresh"
}

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "=============================================================================="
    echo "$1"
    echo "=============================================================================="
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}>>> $1${NC}\n"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"
}

print_command() {
    echo -e "${MAGENTA}[CMD]${NC} $1"
}

wait_for_input() {
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read
    fi
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local missing_prereqs=0
    
    # Check Docker
    print_step "Checking Docker installation"
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        print_success "Docker found: version $DOCKER_VERSION"
    else
        print_error "Docker is not installed or not in PATH"
        missing_prereqs=$((missing_prereqs + 1))
    fi
    
    # Check Java
    print_step "Checking Java installation"
    if [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ]; then
        JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
        print_success "Java found: version $JAVA_VERSION at $JAVA_HOME"
    else
        print_error "JAVA_HOME is not set or invalid"
        missing_prereqs=$((missing_prereqs + 1))
    fi
    
    # Check WLS installer
    print_step "Checking WebLogic installer"
    if [ -f "$WLS_INSTALLER" ]; then
        WLS_SIZE=$(du -h "$WLS_INSTALLER" | awk '{print $1}')
        print_success "WebLogic installer found: $WLS_INSTALLER ($WLS_SIZE)"
    else
        print_error "WebLogic installer not found: $WLS_INSTALLER"
        missing_prereqs=$((missing_prereqs + 1))
    fi
    
    # Check JDK installer
    print_step "Checking JDK installer"
    if [ -f "$JDK_INSTALLER" ]; then
        JDK_SIZE=$(du -h "$JDK_INSTALLER" | awk '{print $1}')
        print_success "JDK installer found: $JDK_INSTALLER ($JDK_SIZE)"
    else
        print_error "JDK installer not found: $JDK_INSTALLER"
        missing_prereqs=$((missing_prereqs + 1))
    fi
    
    if [ $missing_prereqs -gt 0 ]; then
        print_error "Missing $missing_prereqs prerequisite(s). Please install and retry."
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

setup_work_directory() {
    print_section "Setting Up Work Directory"
    
    if [ -d "$WIT_WORK_DIR" ]; then
        print_info "Work directory already exists: $WIT_WORK_DIR"
    else
        print_step "Creating work directory: $WIT_WORK_DIR"
        mkdir -p "$WIT_WORK_DIR"
        print_success "Work directory created"
    fi
    
    # Create logs directory
    mkdir -p "$WIT_WORK_DIR/logs"
    
    # Set log file
    LOG_FILE="$WIT_WORK_DIR/logs/wit_$(date +%Y%m%d_%H%M%S).log"
    touch "$LOG_FILE"
    print_info "Log file: $LOG_FILE"
}

download_wit() {
    print_section "Step 1: Download and Install WIT"
    
    if [ -d "$WIT_HOME" ] && [ -f "$WIT_HOME/bin/imagetool.sh" ]; then
        print_info "WIT already installed at: $WIT_HOME"
        WIT_INSTALLED_VERSION=$("$WIT_HOME/bin/imagetool.sh" --version 2>&1 | grep "ImageTool" | awk '{print $3}')
        print_info "Installed version: $WIT_INSTALLED_VERSION"
        return 0
    fi
    
    print_step "Downloading WIT version $WIT_VERSION"
    print_command "curl -fL $WIT_DOWNLOAD_URL -o $WIT_WORK_DIR/imagetool.zip"
    
    curl -fL "$WIT_DOWNLOAD_URL" -o "$WIT_WORK_DIR/imagetool.zip" 2>&1 | tee -a "$LOG_FILE"
    
    if [ ! -f "$WIT_WORK_DIR/imagetool.zip" ]; then
        print_error "Failed to download WIT"
        exit 1
    fi
    
    local ZIP_SIZE=$(du -h "$WIT_WORK_DIR/imagetool.zip" | awk '{print $1}')
    print_success "Downloaded WIT: $ZIP_SIZE"
    
    print_step "Extracting WIT"
    print_command "unzip -q $WIT_WORK_DIR/imagetool.zip -d $WIT_WORK_DIR"
    
    unzip -q "$WIT_WORK_DIR/imagetool.zip" -d "$WIT_WORK_DIR" 2>&1 | tee -a "$LOG_FILE"
    
    if [ ! -f "$WIT_HOME/bin/imagetool.sh" ]; then
        print_error "Failed to extract WIT - imagetool.sh not found"
        exit 1
    fi
    
    # Make the script executable
    chmod +x "$WIT_HOME/bin/imagetool.sh"
    
    print_success "WIT installed successfully"
    
    # Verify installation
    print_step "Verifying WIT installation"
    WIT_VERSION_OUTPUT=$("$WIT_HOME/bin/imagetool.sh" --version 2>&1)
    print_info "$WIT_VERSION_OUTPUT"
    print_success "WIT is ready to use"
}

setup_cache() {
    print_section "Step 2: Setup WIT Cache"
    
    print_step "Initializing cache directory"
    if [ -d "$CACHE_DIR" ]; then
        print_info "Cache directory already exists: $CACHE_DIR"
    else
        mkdir -p "$CACHE_DIR"
        print_success "Cache directory created: $CACHE_DIR"
    fi
    
    # Add JDK to cache
    print_step "Adding JDK to cache"
    print_command "$WIT_HOME/bin/imagetool.sh cache addInstaller --type jdk --version $JDK_VERSION --path $JDK_INSTALLER"
    
    if "$WIT_HOME/bin/imagetool.sh" cache listItems 2>&1 | grep -q "$JDK_VERSION"; then
        print_info "JDK $JDK_VERSION already in cache"
    else
        "$WIT_HOME/bin/imagetool.sh" cache addInstaller \
            --type jdk \
            --version "$JDK_VERSION" \
            --path "$JDK_INSTALLER" 2>&1 | tee -a "$LOG_FILE"
        print_success "JDK added to cache"
    fi
    
    # Add WebLogic to cache
    print_step "Adding WebLogic to cache"
    print_command "$WIT_HOME/bin/imagetool.sh cache addInstaller --type wls --version $WLS_VERSION --path $WLS_INSTALLER"
    
    if "$WIT_HOME/bin/imagetool.sh" cache listItems 2>&1 | grep -q "$WLS_VERSION"; then
        print_info "WebLogic $WLS_VERSION already in cache"
    else
        "$WIT_HOME/bin/imagetool.sh" cache addInstaller \
            --type wls \
            --version "$WLS_VERSION" \
            --path "$WLS_INSTALLER" 2>&1 | tee -a "$LOG_FILE"
        print_success "WebLogic added to cache"
    fi
    
    # Add WDT to cache (will be downloaded automatically if not present)
    print_step "Adding WDT to cache"
    print_command "$WIT_HOME/bin/imagetool.sh cache addInstaller --type wdt --version $WDT_VERSION"
    
    if "$WIT_HOME/bin/imagetool.sh" cache listItems 2>&1 | grep -q "wdt_${WDT_VERSION}"; then
        print_info "WDT $WDT_VERSION already in cache"
    else
        print_info "WIT will download WDT $WDT_VERSION automatically..."
        "$WIT_HOME/bin/imagetool.sh" cache addInstaller \
            --type wdt \
            --version "$WDT_VERSION" 2>&1 | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            print_success "WDT $WDT_VERSION added to cache"
        else
            print_warning "WDT will be downloaded during image creation if needed"
        fi
    fi
    
    # List cache contents
    print_step "Cache contents:"
    "$WIT_HOME/bin/imagetool.sh" cache listItems 2>&1 | tee -a "$LOG_FILE"
    print_success "Cache setup complete"
}

create_basic_image() {
    print_section "Step 3: Create Basic WebLogic Image"
    
    # Check if image already exists
    if docker images -q "$IMAGE_TAG" 2>/dev/null | grep -q .; then
        print_info "Image $IMAGE_TAG already exists"
        print_warning "Skipping image creation (use --clean to rebuild)"
        
        # Still push to OCIR if enabled
        if [ "$PUSH_TO_OCIR" = true ]; then
            push_to_ocir "$IMAGE_TAG" "$OCIR_IMAGE_TAG"
        fi
        return 0
    fi
    
    print_step "Creating WebLogic Docker image: $IMAGE_TAG"
    print_command "$WIT_HOME/bin/imagetool.sh create --tag $IMAGE_TAG --type wls --version $WLS_VERSION --jdkVersion $JDK_VERSION"
    
    print_info "This may take several minutes..."
    
    "$WIT_HOME/bin/imagetool.sh" create \
        --tag "$IMAGE_TAG" \
        --type wls \
        --version "$WLS_VERSION" \
        --jdkVersion "$JDK_VERSION" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "Image created successfully: $IMAGE_TAG"
    else
        print_error "Failed to create image"
        exit 1
    fi
    
    # Display image info
    print_step "Image details:"
    docker images "$IMAGE_TAG" | tee -a "$LOG_FILE"
    
    local IMAGE_SIZE=$(docker images "$IMAGE_TAG" --format "{{.Size}}")
    print_info "Image size: $IMAGE_SIZE"
    
    # Push to OCIR if enabled
    if [ "$PUSH_TO_OCIR" = true ]; then
        push_to_ocir "$IMAGE_TAG" "$OCIR_IMAGE_TAG"
    fi
}

inspect_image() {
    print_section "Step 4: Inspect Created Image"
    
    if ! docker images -q "$IMAGE_TAG" 2>/dev/null | grep -q .; then
        print_warning "Image $IMAGE_TAG not found - skipping inspection"
        return 0
    fi
    
    print_step "Inspecting image: $IMAGE_TAG"
    print_command "$WIT_HOME/bin/imagetool.sh inspect --image $IMAGE_TAG"
    
    "$WIT_HOME/bin/imagetool.sh" inspect \
        --image "$IMAGE_TAG" 2>&1 | tee -a "$LOG_FILE"
    
    print_success "Image inspection complete"
    
    # Additional Docker inspect
    print_step "Docker image layers:"
    docker history "$IMAGE_TAG" --no-trunc 2>&1 | tee -a "$LOG_FILE"
}

create_wdt_domain_image() {
    print_section "Step 5: Create WDT Domain Image (Optional)"
    
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        print_info "Domain Type: Model-in-Image (mii)"
        print_info "WDT model and archive included in image, domain created at runtime"
    elif [ "$DOMAIN_TYPE" = "dii" ]; then
        print_info "Domain Type: Domain-in-Image (dii)"
        print_info "Domain fully created in image at: $WDT_DOMAIN_HOME"
    fi
    echo ""
    
    # Check if WDT model files exist
    if [ ! -f "$WDT_MODEL_FILE" ]; then
        print_warning "WDT model file not found: $WDT_MODEL_FILE"
        print_info ""
        print_info "Looking for WDT files in: $(dirname "$WDT_MODEL_FILE")"
        
        # Check if WDT directory exists
        WDT_DIR="$SCRIPT_DIR/../WDT/wdt-output"
        if [ ! -d "$WDT_DIR" ]; then
            print_info "WDT output directory does not exist"
            print_info ""
            print_info "To create WDT domain model, run:"
            print_info "  cd $SCRIPT_DIR/../WDT"
            print_info "  ./wdt.sh --no-run"
            print_info ""
            print_info "Skipping WDT domain image creation"
            return 0
        fi
        
        # List what files exist in WDT directory
        print_info "Files found in WDT output directory:"
        ls -lh "$WDT_DIR" 2>/dev/null | tail -n +2 | awk '{print "  " $9 " (" $5 ")"}'
        print_info ""
        print_info "Expected files:"
        print_info "  - base_domain_model.yaml"
        print_info "  - base_domain_archive.zip"
        print_info ""
        print_info "To create these files, run:"
        print_info "  cd $SCRIPT_DIR/../WDT"
        print_info "  ./wdt.sh --no-run"
        print_info ""
        print_info "Skipping WDT domain image creation"
        return 0
    fi
    
    print_success "Found WDT model file: $WDT_MODEL_FILE"
    
    # Check for archive file
    if [ -f "$WDT_ARCHIVE_FILE" ]; then
        print_success "Found WDT archive file: $WDT_ARCHIVE_FILE"
    else
        print_info "WDT archive file not found (optional): $WDT_ARCHIVE_FILE"
    fi
    
    # Check for properties file
    if [ -f "$WDT_VARIABLE_FILE" ]; then
        print_success "Found WDT properties file: $WDT_VARIABLE_FILE"
    else
        print_warning "WDT properties file not found (may be required): $WDT_VARIABLE_FILE"
    fi
    
    # Check if image already exists
    if docker images -q "$IMAGE_TAG_WDT" 2>/dev/null | grep -q .; then
        print_info "Image $IMAGE_TAG_WDT already exists"
        print_warning "Skipping image creation (use --clean to rebuild)"
        
        # Still push to OCIR if enabled
        if [ "$PUSH_TO_OCIR" = true ]; then
            # Choose appropriate OCIR tag based on domain type
            if [ "$DOMAIN_TYPE" = "mii" ]; then
                push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_MII"
            elif [ "$DOMAIN_TYPE" = "dii" ]; then
                push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_DII"
            fi
        fi
        return 0
    fi
    
    print_step "Creating WebLogic image with WDT domain: $IMAGE_TAG_WDT"
    
    # Build command based on domain type
    local FULL_CMD="$WIT_HOME/bin/imagetool.sh create --tag $IMAGE_TAG_WDT --type wls --version $WLS_VERSION --jdkVersion $JDK_VERSION --wdtVersion $WDT_VERSION --wdtModel $WDT_MODEL_FILE"
    
    # Add archive if it exists
    if [ -f "$WDT_ARCHIVE_FILE" ]; then
        FULL_CMD="$FULL_CMD --wdtArchive $WDT_ARCHIVE_FILE"
    fi
    
    # Add properties/variable file if it exists
    if [ -f "$WDT_VARIABLE_FILE" ]; then
        FULL_CMD="$FULL_CMD --wdtVariables $WDT_VARIABLE_FILE"
        print_info "Using WDT properties file: $WDT_VARIABLE_FILE"
    fi
    
    # Add domain home for Domain-in-Image
    if [ "$DOMAIN_TYPE" = "dii" ]; then
        FULL_CMD="$FULL_CMD --wdtDomainHome $WDT_DOMAIN_HOME"
        print_info "Domain will be created at: $WDT_DOMAIN_HOME"
    fi
    
    print_command "$FULL_CMD"
    print_info "This may take several minutes..."
    
    eval "$FULL_CMD" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        print_success "WDT domain image created successfully: $IMAGE_TAG_WDT"
        
        # Display image info
        print_step "Image details:"
        docker images "$IMAGE_TAG_WDT" | tee -a "$LOG_FILE"
        
        local IMAGE_SIZE=$(docker images "$IMAGE_TAG_WDT" --format "{{.Size}}")
        print_info "Image size: $IMAGE_SIZE"
        
        # Push to OCIR if enabled
        if [ "$PUSH_TO_OCIR" = true ]; then
            # Choose appropriate OCIR tag based on domain type
            if [ "$DOMAIN_TYPE" = "mii" ]; then
                push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_MII"
            elif [ "$DOMAIN_TYPE" = "dii" ]; then
                push_to_ocir "$IMAGE_TAG_WDT" "$OCIR_IMAGE_TAG_WDT_DII"
            fi
        fi
    else
        print_error "Failed to create WDT domain image"
        # Non-fatal - continue with script
    fi
}

generate_summary() {
    print_section "Execution Summary"
    
    local SUMMARY_FILE="$WIT_WORK_DIR/summary.txt"
    
    {
        echo "WebLogic Image Tool (WIT) - Execution Summary"
        echo "=============================================="
        echo ""
        echo "Execution Date: $(date)"
        echo "WIT Version: $WIT_VERSION"
        echo "WIT Home: $WIT_HOME"
        echo "Cache Directory: $CACHE_DIR"
        if [ "$DOMAIN_TYPE" = "mii" ]; then
            echo "Domain Type: Model-in-Image (mii)"
        elif [ "$DOMAIN_TYPE" = "dii" ]; then
            echo "Domain Type: Domain-in-Image (dii)"
            echo "Domain Home: $WDT_DOMAIN_HOME"
        fi
        echo ""
        echo "Installers Used:"
        echo "  - WebLogic: $WLS_INSTALLER"
        echo "  - JDK: $JDK_INSTALLER"
        echo ""
        echo "Images Created:"
        
        if docker images -q "$IMAGE_TAG" 2>/dev/null | grep -q .; then
            local SIZE=$(docker images "$IMAGE_TAG" --format "{{.Size}}")
            echo "  ✓ $IMAGE_TAG ($SIZE)"
        else
            echo "  ✗ $IMAGE_TAG (not created)"
        fi
        
        if docker images -q "$IMAGE_TAG_WDT" 2>/dev/null | grep -q .; then
            local SIZE=$(docker images "$IMAGE_TAG_WDT" --format "{{.Size}}")
            echo "  ✓ $IMAGE_TAG_WDT ($SIZE)"
        else
            echo "  ✗ $IMAGE_TAG_WDT (not created)"
        fi
        
        echo ""
        
        if [ "$PUSH_TO_OCIR" = true ]; then
            echo "OCIR Images:"
            echo "  Registry: ${OCIR_REGISTRY}"
            echo "  Repository: ${OCIR_NAMESPACE}/${OCIR_REPO}"
            echo ""
            if docker images -q "$OCIR_IMAGE_TAG" 2>/dev/null | grep -q .; then
                echo "  ✓ ${OCIR_IMAGE_TAG}"
            fi
            if [ "$DOMAIN_TYPE" = "mii" ] && docker images -q "$OCIR_IMAGE_TAG_WDT_MII" 2>/dev/null | grep -q .; then
                echo "  ✓ ${OCIR_IMAGE_TAG_WDT_MII}"
            fi
            if [ "$DOMAIN_TYPE" = "dii" ] && docker images -q "$OCIR_IMAGE_TAG_WDT_DII" 2>/dev/null | grep -q .; then
                echo "  ✓ ${OCIR_IMAGE_TAG_WDT_DII}"
            fi
            echo ""
        fi
        
        echo "Cache Contents:"
        "$WIT_HOME/bin/imagetool.sh" cache listItems 2>&1
        
        echo ""
        echo "All Docker Images:"
        docker images | grep -E "REPOSITORY|wls"
        
        echo ""
        echo "Log File: $LOG_FILE"
        echo ""
        echo "Next Steps:"
        if [ "$PUSH_TO_OCIR" = true ]; then
            echo "  1. Images are available in OCIR at: ${OCIR_REGISTRY_PATH}"
            echo "  2. Deploy to Kubernetes using the OCIR image references"
            echo "  3. Update deployment manifests with OCIR image paths"
        else
            echo "  1. Test the image: docker run -d -p 7001:7001 $IMAGE_TAG"
            echo "  2. Push to OCIR: Run script again without --no-push flag"
            echo "  3. Deploy to Kubernetes using manifests in modernization-ports/*/kubernetes/"
        fi
        echo ""
        
    } | tee "$SUMMARY_FILE"
    
    print_success "Summary saved to: $SUMMARY_FILE"
}

show_help() {
    echo "WebLogic Image Tool (WIT) - Automated Demo Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -c, --clean     Clean all WIT artifacts before starting"
    echo "  --mii           Create Model-in-Image (default)"
    echo "  --dii           Create Domain-in-Image"
    echo "  --no-push       Skip pushing images to OCIR"
    echo "  -y, --yes       Non-interactive mode (skip prompts)"
    echo "  -h, --help      Display this help message"
    echo ""
    echo "Domain Types:"
    echo "  Model-in-Image (mii)   - WDT model in image, domain created at runtime (K8s)"
    echo "  Domain-in-Image (dii)  - Domain fully created in image, ready to run"
    echo ""
    echo "This script automates the following WIT operations:"
    echo "  1. Download and install WIT"
    echo "  2. Setup cache with JDK and WebLogic installers"
    echo "  3. Create basic WebLogic Docker image"
    echo "  4. Inspect created image"
    echo "  5. Create WDT domain image with selected type (if WDT model available)"
    echo "  6. Push images to OCIR (Oracle Cloud Infrastructure Registry)"
    echo ""
    echo "OCIR Configuration:"
    echo "  Registry: ${OCIR_REGISTRY}"
    echo "  Namespace: ${OCIR_NAMESPACE}"
    echo "  Repository: ${OCIR_REPO}"
    echo ""
    echo "Prerequisites:"
    echo "  - Docker installed and running"
    echo "  - Logged in to OCIR: docker login ${OCIR_REGISTRY}"
    echo "  - JAVA_HOME set correctly"
    echo "  - WebLogic installer at: $WLS_INSTALLER"
    echo "  - JDK installer at: $JDK_INSTALLER"
    echo ""
    echo "Environment:"
    echo "  Source setWITEnv.sh first to set environment variables"
    echo ""
}

################################################################################
# Main Script
################################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                CLEAN_MODE=true
                shift
                ;;
            --mii)
                DOMAIN_TYPE="mii"
                shift
                ;;
            --dii)
                DOMAIN_TYPE="dii"
                shift
                ;;
            --no-push)
                PUSH_TO_OCIR=false
                shift
                ;;
            -y|--yes)
                INTERACTIVE_MODE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle clean mode
    if [ "$CLEAN_MODE" = true ]; then
        reset_environment
        exit 0
    fi
    
    # Start execution
    print_banner "WebLogic Image Tool (WIT) - Automated Demo"
    
    print_info "Workspace: $WORKSPACE_ROOT"
    print_info "Work Directory: $WIT_WORK_DIR"
    print_info "WIT Version: $WIT_VERSION"
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        print_info "Domain Type: Model-in-Image (mii)"
    elif [ "$DOMAIN_TYPE" = "dii" ]; then
        print_info "Domain Type: Domain-in-Image (dii)"
    fi
    if [ "$PUSH_TO_OCIR" = true ]; then
        print_info "OCIR Push: Enabled"
        print_info "OCIR Registry: ${OCIR_REGISTRY_PATH}"
    else
        print_info "OCIR Push: Disabled (use without --no-push to enable)"
    fi
    echo ""
    
    # Execute workflow
    check_prerequisites
    wait_for_input
    
    setup_work_directory
    wait_for_input
    
    download_wit
    wait_for_input
    
    setup_cache
    wait_for_input
    
    create_basic_image
    wait_for_input
    
    inspect_image
    wait_for_input
    
    create_wdt_domain_image
    wait_for_input
    
    generate_summary
    
    print_banner "WIT Automation Complete!"
    print_success "All operations completed successfully"
    print_info "Review the summary at: $WIT_WORK_DIR/summary.txt"
    print_info "Review the log at: $LOG_FILE"
    echo ""
}

# Run main function
main "$@"
