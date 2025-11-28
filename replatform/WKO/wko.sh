#!/bin/bash

################################################################################
# WebLogic Kubernetes Operator (WKO) - Automated Deployment Script
# 
# This script automates the deployment of WebLogic domains to Kubernetes
# using the WebLogic Kubernetes Operator
#
# Usage: ./wko.sh [options]
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
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WKO_WORK_DIR="$SCRIPT_DIR/wko-output"

# Load environment variables from .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a  # Export all variables
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Operator configuration
OPERATOR_NS="weblogic-operator-ns"
OPERATOR_SA="weblogic-operator-sa"
OPERATOR_RELEASE="weblogic-operator"

# Ingress configuration
INGRESS_NS="traefik"
INGRESS_RELEASE="traefik-operator"
INGRESS_HTTP_PORT="30305"
INGRESS_HTTPS_PORT="30443"
INGRESS_SERVICE_TYPE="LoadBalancer"

# OCI Load Balancer configuration (for OKE deployments)
OCI_LB_SUBNET="ocid1.subnet.oc1.sa-santiago-1.aaaaaaaactbyskvixf2iggfzfcuwmkzcsrvja2wbv2pi5bxkaofaogurmkpq"
OCI_LB_SHAPE="flexible"
OCI_LB_SHAPE_MIN="10"
OCI_LB_SHAPE_MAX="100"

# Domain configuration (will be set based on domain type)
DOMAIN_TYPE="mii"  # Model-in-Image (default), can be 'dii' for Domain-in-Image
DOMAIN_NS=""       # Will be set based on domain type
DOMAIN_UID=""      # Will be set based on domain type
DOMAIN_NAME="base_domain"
CLUSTER_NAME="base_cluster"

# OCIR Images (public repositories)
OCIR_REGISTRY="scl.ocir.io"
OCIR_NAMESPACE="idi1o0a010nx"
OCIR_REPO="dalquint-docker-images"
IMAGE_MII="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPO}/wls-wdt-mii:12.2.1.4.0"
IMAGE_DII="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPO}/wls-wdt-dii:12.2.1.4.0"
IMAGE_BASE="${OCIR_REGISTRY}/${OCIR_NAMESPACE}/${OCIR_REPO}/weblogic:12.2.1.4"

# OCIR Credentials (required for pulling images from OCIR)
# Set these via environment variables or modify here
OCIR_SECRET_NAME="ocir-secret"
OCIR_USERNAME="${OCIR_USERNAME:-}"
OCIR_AUTH_TOKEN="${OCIR_AUTH_TOKEN:-}"

# WebLogic credentials
ADMIN_USERNAME="weblogic"
ADMIN_PASSWORD="welcome1"
RUNTIME_PASSWORD="welcome1"

# Cluster configuration
INITIAL_REPLICAS=2

# Flags
CLEAN_MODE=false
DELETE_MODE=false
INTERACTIVE_MODE=false  # Non-interactive by default
SKIP_OPERATOR=false
SKIP_INGRESS=false

################################################################################
# Helper Functions
################################################################################

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_command() {
    echo -e "${MAGENTA}[CMD]${NC} $1"
}

pause_for_review() {
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read -r
    fi
}

wait_for_pods() {
    local namespace=$1
    local label=$2
    local timeout=${3:-300}
    
    print_step "Waiting for pods with label '$label' in namespace '$namespace'"
    
    # Check if pods already exist and are ready
    if kubectl get pods -n "$namespace" -l "$label" 2>/dev/null | grep -q "Running"; then
        local ready_count=$(kubectl get pods -n "$namespace" -l "$label" -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null | grep -c "True" || echo "0")
        local total_count=$(kubectl get pods -n "$namespace" -l "$label" --no-headers 2>/dev/null | wc -l)
        if [ "$ready_count" = "$total_count" ] && [ "$total_count" -gt 0 ]; then
            print_success "Pods are already ready"
            return 0
        fi
    fi
    
    kubectl wait --for=condition=ready pod \
        -l "$label" \
        -n "$namespace" \
        --timeout="${timeout}s" 2>/dev/null || {
        print_warning "Timeout waiting for pods. Checking status..."
        kubectl get pods -n "$namespace" -l "$label"
        return 1
    }
    
    print_success "Pods are ready"
    return 0
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local all_good=true
    
    # Check kubectl
    print_step "Checking kubectl"
    if command -v kubectl &> /dev/null; then
        local version=$(kubectl version --client --short 2>/dev/null | head -1)
        print_success "kubectl found: $version"
    else
        print_error "kubectl not found"
        all_good=false
    fi
    
    # Check helm
    print_step "Checking Helm"
    if command -v helm &> /dev/null; then
        local version=$(helm version --short 2>/dev/null)
        print_success "Helm found: $version"
    else
        print_error "Helm not found"
        all_good=false
    fi
    
    # Check kubectl cluster access
    print_step "Checking Kubernetes cluster access"
    if kubectl cluster-info &> /dev/null; then
        local context=$(kubectl config current-context)
        print_success "Connected to cluster: $context"
    else
        print_error "Cannot connect to Kubernetes cluster"
        all_good=false
    fi
    
    # Check and setup OCIR credentials
    print_step "Checking OCIR credentials"
    if [ -n "$OCIR_USERNAME" ] && [ -n "$OCIR_AUTH_TOKEN" ]; then
        print_success "OCIR credentials found"
        
        # Automatically login to OCIR with docker/podman
        print_step "Logging into OCIR"
        if command -v docker &> /dev/null; then
            echo "$OCIR_AUTH_TOKEN" | docker login "$OCIR_REGISTRY" -u "$OCIR_USERNAME" --password-stdin &> /dev/null && \
                print_success "Docker logged into OCIR" || print_warning "Docker OCIR login failed (non-critical)"
        elif command -v podman &> /dev/null; then
            echo "$OCIR_AUTH_TOKEN" | podman login "$OCIR_REGISTRY" -u "$OCIR_USERNAME" --password-stdin &> /dev/null && \
                print_success "Podman logged into OCIR" || print_warning "Podman OCIR login failed (non-critical)"
        fi
    else
        print_warning "OCIR credentials not found in .env file"
        print_info "Image pulls may fail - set credentials in $SCRIPT_DIR/.env"
        all_good=false
    fi
    
    # Verify required images exist
    print_step "Checking required images in OCIR"
    local missing_images=()
    
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        # For MII, check base image and auxiliary image
        if ! docker pull "$IMAGE_BASE" &> /dev/null; then
            missing_images+=("$IMAGE_BASE")
        fi
        if ! docker pull "$IMAGE_MII" &> /dev/null; then
            missing_images+=("$IMAGE_MII")
        fi
    else
        # For DII, only check the domain-in-image
        if ! docker pull "$IMAGE_DII" &> /dev/null; then
            missing_images+=("$IMAGE_DII")
        fi
    fi
    
    if [ ${#missing_images[@]} -gt 0 ]; then
        print_warning "Some required images are not available in OCIR:"
        for img in "${missing_images[@]}"; do
            print_info "  - $img"
        done
        print_info ""
        print_info "Run the WIT script first to build and push images:"
        print_info "  cd ../WIT && ./wit.sh --$DOMAIN_TYPE"
        all_good=false
    else
        print_success "All required images available in OCIR"
    fi
    
    if [ "$all_good" = false ]; then
        print_error "Prerequisites check failed"
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
    pause_for_review
}

setup_work_directory() {
    print_section "Setting Up Work Directory"
    
    mkdir -p "$WKO_WORK_DIR"
    mkdir -p "$WKO_WORK_DIR/logs"
    mkdir -p "$WKO_WORK_DIR/manifests"
    
    print_success "Work directory created: $WKO_WORK_DIR"
    pause_for_review
}

install_operator() {
    if [ "$SKIP_OPERATOR" = true ]; then
        print_info "Skipping operator installation"
        return 0
    fi
    
    print_section "Step 1: Installing WebLogic Kubernetes Operator"
    
    # Check if operator already exists
    if helm list -n "$OPERATOR_NS" 2>/dev/null | grep -q "$OPERATOR_RELEASE"; then
        print_warning "Operator already installed"
        print_info "Use --clean to remove and reinstall"
        pause_for_review
        return 0
    fi
    
    # Create namespace
    print_step "Step 1.1: Creating operator namespace: $OPERATOR_NS"
    kubectl create namespace "$OPERATOR_NS" 2>/dev/null || {
        print_info "Namespace already exists"
    }
    
    # Create service account
    print_step "Step 1.2: Creating service account: $OPERATOR_SA"
    kubectl create serviceaccount -n "$OPERATOR_NS" "$OPERATOR_SA" 2>/dev/null || {
        print_info "Service account already exists"
    }
    
    # Add Helm repository
    print_step "Step 1.3: Adding WebLogic Operator Helm repository"
    print_command "helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts --force-update"
    helm repo add weblogic-operator https://oracle.github.io/weblogic-kubernetes-operator/charts --force-update
    helm repo update
    
    # Install operator
    print_step "Step 1.4: Installing operator via Helm"
    print_command "helm install $OPERATOR_RELEASE weblogic-operator/weblogic-operator..."
    helm install "$OPERATOR_RELEASE" weblogic-operator/weblogic-operator \
        --namespace "$OPERATOR_NS" \
        --set serviceAccount="$OPERATOR_SA" \
        --set "enableClusterRoleBinding=true" \
        --set "domainNamespaceSelectionStrategy=LabelSelector" \
        --set "domainNamespaceLabelSelector=weblogic-operator\=enabled" \
        --wait
    
    print_success "Operator installed successfully"
    
    # Verify operator pods
    print_step "Step 1.5: Verifying operator pods"
    kubectl get pods -n "$OPERATOR_NS"
    
    pause_for_review
}

install_ingress() {
    if [ "$SKIP_INGRESS" = true ]; then
        print_info "Skipping ingress controller installation"
        return 0
    fi
    
    print_section "Step 2: Installing Traefik Ingress Controller"
    
    # Check if ingress already exists
    if helm list -n "$INGRESS_NS" 2>/dev/null | grep -q "$INGRESS_RELEASE"; then
        print_warning "Traefik already installed"
        print_info "Use --clean to remove and reinstall"
        pause_for_review
        return 0
    fi
    
    # Create namespace
    print_step "Step 2.1: Creating ingress namespace: $INGRESS_NS"
    kubectl create namespace "$INGRESS_NS" 2>/dev/null || {
        print_info "Namespace already exists"
    }
    
    # Add Helm repository
    print_step "Step 2.2: Adding Traefik Helm repository"
    print_command "helm repo add traefik https://helm.traefik.io/traefik --force-update"
    helm repo add traefik https://helm.traefik.io/traefik --force-update
    helm repo update
    
    # Install Traefik
    print_step "Step 2.3: Installing Traefik via Helm"
    print_command "helm install $INGRESS_RELEASE traefik/traefik..."
    
    if [ "$INGRESS_SERVICE_TYPE" = "LoadBalancer" ]; then
        print_info "Configuring Traefik with OCI LoadBalancer"
        helm install "$INGRESS_RELEASE" traefik/traefik \
            --namespace "$INGRESS_NS" \
            --set "service.type=LoadBalancer" \
            --set-string "service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-shape=$OCI_LB_SHAPE" \
            --set-string "service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-min=$OCI_LB_SHAPE_MIN" \
            --set-string "service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-max=$OCI_LB_SHAPE_MAX" \
            --set-string "service.annotations.service\.beta\.kubernetes\.io/oci-load-balancer-subnet1=$OCI_LB_SUBNET" \
            --wait
    else
        print_info "Configuring Traefik with NodePort"
        helm install "$INGRESS_RELEASE" traefik/traefik \
            --namespace "$INGRESS_NS" \
            --set "ports.web.nodePort=$INGRESS_HTTP_PORT" \
            --set "ports.websecure.nodePort=$INGRESS_HTTPS_PORT" \
            --set "service.type=NodePort" \
            --wait
    fi
    
    print_success "Traefik installed successfully"
    
    # Verify Traefik pods
    print_step "Step 2.4: Verifying Traefik pods"
    kubectl get pods -n "$INGRESS_NS"
    
    pause_for_review
}

prepare_domain_namespace() {
    print_section "Step 3: Preparing Domain Namespace"
    
    # Create namespace
    print_step "Step 3.1: Creating domain namespace: $DOMAIN_NS"
    kubectl create namespace "$DOMAIN_NS" 2>/dev/null || {
        print_info "Namespace already exists"
    }
    
    # Label namespace for operator management
    print_step "Step 3.2: Labeling namespace for operator management"
    print_command "kubectl label namespace $DOMAIN_NS weblogic-operator=enabled"
    kubectl label namespace "$DOMAIN_NS" weblogic-operator=enabled --overwrite
    
    # Configure Traefik for domain namespace
    if [ "$SKIP_INGRESS" = false ]; then
        print_step "Step 3.3: Configuring Traefik for domain namespace"
        print_command "helm upgrade $INGRESS_RELEASE..."
        helm upgrade "$INGRESS_RELEASE" traefik/traefik \
            --namespace "$INGRESS_NS" \
            --reuse-values \
            --set "kubernetes.namespaces={$INGRESS_NS,$DOMAIN_NS}" \
            --wait
    fi
    
    print_success "Domain namespace prepared"
    pause_for_review
}

create_secrets() {
    print_section "Step 4: Creating Kubernetes Secrets"
    
    # OCIR secret for pulling images
    if [ -n "$OCIR_USERNAME" ] && [ -n "$OCIR_AUTH_TOKEN" ]; then
        print_step "Step 4.1: Creating OCIR image pull secret"
        kubectl create secret docker-registry "$OCIR_SECRET_NAME" \
            --docker-server="$OCIR_REGISTRY" \
            --docker-username="$OCIR_USERNAME" \
            --docker-password="$OCIR_AUTH_TOKEN" \
            --docker-email="${OCIR_USERNAME}" \
            -n "$DOMAIN_NS" 2>/dev/null || {
            print_info "OCIR secret already exists"
        }
    else
        print_warning "OCIR credentials not provided - image pulls may fail"
        print_info "Set OCIR_USERNAME and OCIR_AUTH_TOKEN environment variables"
        print_info "Example: export OCIR_USERNAME='<tenancy>/<username>'"
        print_info "         export OCIR_AUTH_TOKEN='<auth-token>'"
    fi
    
    # WebLogic credentials secret
    print_step "Step 4.2: Creating WebLogic credentials secret"
    kubectl create secret generic "${DOMAIN_UID}-weblogic-credentials" \
        --from-literal=username="$ADMIN_USERNAME" \
        --from-literal=password="$ADMIN_PASSWORD" \
        -n "$DOMAIN_NS" 2>/dev/null || {
        print_info "WebLogic credentials secret already exists"
    }
    
    # Runtime encryption secret
    print_step "Step 4.3: Creating runtime encryption secret"
    kubectl create secret generic "${DOMAIN_UID}-runtime-encryption-secret" \
        --from-literal=password="$RUNTIME_PASSWORD" \
        -n "$DOMAIN_NS" 2>/dev/null || {
        print_info "Runtime encryption secret already exists"
    }
    
    # List secrets
    print_step "Step 4.4: Verifying secrets"
    kubectl get secrets -n "$DOMAIN_NS" | grep -E "$DOMAIN_UID|$OCIR_SECRET_NAME" || kubectl get secrets -n "$DOMAIN_NS"
    
    print_success "Secrets created successfully"
    pause_for_review
}

create_wdt_config_map() {
    print_section "Step 4: Creating WDT Runtime ConfigMap"
    
    # Check if ConfigMap already exists
    if kubectl get configmap "${DOMAIN_UID}-wdt-config-map" -n "$DOMAIN_NS" &>/dev/null; then
        print_warning "WDT ConfigMap already exists"
        print_info "Updating existing ConfigMap"
    fi
    
    print_step "Creating WDT runtime properties ConfigMap"
    cat <<EOF | kubectl apply -f - -n "$DOMAIN_NS"
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${DOMAIN_UID}-wdt-config-map
  namespace: $DOMAIN_NS
data:
  wdt_runtime.properties: |
    AdminUserName=$ADMIN_USERNAME
    AdminPassword=$ADMIN_PASSWORD
    LDAP.CredentialEncrypted=$ADMIN_PASSWORD
EOF
    
    print_success "WDT ConfigMap created"
    pause_for_review
}

create_domain_resource_dii() {
    print_section "Deployment Model: Domain-in-Image (DII)"
    
    # Check if domain already exists
    if kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS" &>/dev/null; then
        print_warning "Domain '$DOMAIN_UID' already exists"
        local domain_status=$(kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        if [ "$domain_status" = "True" ]; then
            print_success "Domain is already running and healthy"
            pause_for_review
            return 0
        else
            print_info "Domain exists but may not be fully ready"
            print_info "Use --clean to remove and recreate"
            pause_for_review
            return 0
        fi
    fi
    
    local manifest_file="$WKO_WORK_DIR/manifests/domain-dii.yaml"
    
    print_step "Generating domain resource YAML"
    print_info "NOTE: Using FromModel approach with auxiliary images (same as MII)"
    cat > "$manifest_file" << EOF
apiVersion: weblogic.oracle/v9
kind: Domain
metadata:
  name: $DOMAIN_UID
  namespace: $DOMAIN_NS
  labels:
    weblogic.domainUID: $DOMAIN_UID
spec:
  domainUID: $DOMAIN_UID
  domainHome: /u01/domains/$DOMAIN_NAME
  domainHomeSourceType: FromModel
  
  image: "$IMAGE_BASE"
  imagePullPolicy: IfNotPresent
  
  imagePullSecrets:
  - name: $OCIR_SECRET_NAME
  
  configuration:
    model:
      domainType: WLS
      runtimeEncryptionSecret: ${DOMAIN_UID}-runtime-encryption-secret
      configMap: ${DOMAIN_UID}-wdt-config-map
      auxiliaryImages:
      - image: "$IMAGE_DII"
        imagePullPolicy: Always
        sourceWDTInstallHome: /auxiliary/weblogic-deploy
        sourceModelHome: /auxiliary/models
    secrets:
    - ${DOMAIN_UID}-weblogic-credentials
  
  webLogicCredentialsSecret:
    name: ${DOMAIN_UID}-weblogic-credentials
  
  includeServerOutInPodLog: true
  serverStartPolicy: IfNeeded
  
  adminServer:
    adminService:
      channels:
        - channelName: default
          nodePort: 30701
    serverPod:
      env:
        - name: JAVA_OPTIONS
          value: "-Dweblogic.StdoutDebugEnabled=false"
        - name: USER_MEM_ARGS
          value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
        - name: ADMIN_USERNAME
          valueFrom:
            secretKeyRef:
              name: ${DOMAIN_UID}-weblogic-credentials
              key: username
        - name: ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${DOMAIN_UID}-weblogic-credentials
              key: password
  
  clusters:
    - name: ${DOMAIN_UID}-cluster-1
  
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
      - name: ADMIN_USERNAME
        valueFrom:
          secretKeyRef:
            name: ${DOMAIN_UID}-weblogic-credentials
            key: username
      - name: ADMIN_PASSWORD
        valueFrom:
          secretKeyRef:
            name: ${DOMAIN_UID}-weblogic-credentials
            key: password

---
apiVersion: weblogic.oracle/v1
kind: Cluster
metadata:
  name: ${DOMAIN_UID}-cluster-1
  namespace: $DOMAIN_NS
  labels:
    weblogic.domainUID: $DOMAIN_UID
spec:
  clusterName: $CLUSTER_NAME
  replicas: $INITIAL_REPLICAS
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
EOF

    print_success "Domain resource YAML created: $manifest_file"
    
    print_step "Applying domain resource"
    print_command "kubectl apply -f $manifest_file"
    kubectl apply -f "$manifest_file"
    
    print_success "Domain resource applied"
    pause_for_review
}

create_domain_resource_mii() {
    print_section "Deployment Model: Model-in-Image (MII)"
    
    # Check if domain already exists
    if kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS" &>/dev/null; then
        print_warning "Domain '$DOMAIN_UID' already exists"
        local domain_status=$(kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        if [ "$domain_status" = "True" ]; then
            print_success "Domain is already running and healthy"
            pause_for_review
            return 0
        else
            print_info "Domain exists but may not be fully ready"
            print_info "Use --clean to remove and recreate"
            pause_for_review
            return 0
        fi
    fi
    
    local manifest_file="$WKO_WORK_DIR/manifests/domain-mii.yaml"
    
    print_step "Generating domain resource YAML"
    cat > "$manifest_file" << EOF
apiVersion: weblogic.oracle/v9
kind: Domain
metadata:
  name: $DOMAIN_UID
  namespace: $DOMAIN_NS
  labels:
    weblogic.domainUID: $DOMAIN_UID
spec:
  domainUID: $DOMAIN_UID
  domainHome: /u01/domains/$DOMAIN_NAME
  domainHomeSourceType: FromModel
  
  image: "$IMAGE_BASE"
  imagePullPolicy: IfNotPresent
  
  imagePullSecrets:
  - name: $OCIR_SECRET_NAME
  
  configuration:
    model:
      domainType: WLS
      runtimeEncryptionSecret: ${DOMAIN_UID}-runtime-encryption-secret
      configMap: ${DOMAIN_UID}-wdt-config-map
      auxiliaryImages:
      - image: "$IMAGE_MII"
        imagePullPolicy: Always
        sourceWDTInstallHome: /auxiliary/weblogic-deploy
        sourceModelHome: /auxiliary/models
    secrets:
    - ${DOMAIN_UID}-weblogic-credentials
  
  webLogicCredentialsSecret:
    name: ${DOMAIN_UID}-weblogic-credentials
  
  includeServerOutInPodLog: true
  serverStartPolicy: IfNeeded
  
  adminServer:
    adminService:
      channels:
        - channelName: default
          nodePort: 30701
    serverPod:
      env:
        - name: JAVA_OPTIONS
          value: "-Dweblogic.StdoutDebugEnabled=false"
        - name: USER_MEM_ARGS
          value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
        - name: ADMIN_USERNAME
          valueFrom:
            secretKeyRef:
              name: ${DOMAIN_UID}-weblogic-credentials
              key: username
        - name: ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${DOMAIN_UID}-weblogic-credentials
              key: password
  
  clusters:
    - name: ${DOMAIN_UID}-cluster-1
  
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
      - name: ADMIN_USERNAME
        valueFrom:
          secretKeyRef:
            name: ${DOMAIN_UID}-weblogic-credentials
            key: username
      - name: ADMIN_PASSWORD
        valueFrom:
          secretKeyRef:
            name: ${DOMAIN_UID}-weblogic-credentials
            key: password

---
apiVersion: weblogic.oracle/v1
kind: Cluster
metadata:
  name: ${DOMAIN_UID}-cluster-1
  namespace: $DOMAIN_NS
  labels:
    weblogic.domainUID: $DOMAIN_UID
spec:
  clusterName: $CLUSTER_NAME
  replicas: $INITIAL_REPLICAS
  serverPod:
    env:
      - name: JAVA_OPTIONS
        value: "-Dweblogic.StdoutDebugEnabled=false"
      - name: USER_MEM_ARGS
        value: "-Djava.security.egd=file:/dev/./urandom -Xms256m -Xmx512m"
EOF

    print_success "Domain resource YAML created: $manifest_file"
    
    print_step "Applying domain resource"
    print_command "kubectl apply -f $manifest_file"
    kubectl apply -f "$manifest_file"
    
    print_success "Domain resource applied"
    pause_for_review
}

create_ingress_route() {
    print_section "Step 5: Creating Ingress Route"
    
    # Check if ingress route already exists
    if kubectl get ingressroute "${DOMAIN_UID}-admin-route" -n "$DOMAIN_NS" &>/dev/null; then
        print_warning "Ingress route '${DOMAIN_UID}-admin-route' already exists"
        print_info "Updating existing ingress route"
    fi
    
    local manifest_file="$WKO_WORK_DIR/manifests/ingress.yaml"
    
    # Determine path prefix based on domain type
    local path_prefix=""
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        path_prefix="/mii"
    else
        path_prefix="/dii"
    fi
    
    print_step "Generating ingress route YAML"
    print_info "NOTE: WebLogic Console uses root paths. Only one domain type should be active at a time, or use different hostnames."
    cat > "$manifest_file" << EOF
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: ${DOMAIN_UID}-admin-route
  namespace: $DOMAIN_NS
spec:
  entryPoints:
    - web
  routes:
    - match: PathPrefix(\`/console\`) || PathPrefix(\`/em\`) || PathPrefix(\`/consolehelp\`)
      kind: Rule
      services:
        - name: ${DOMAIN_UID}-adminserver
          port: 8001
    - match: PathPrefix(\`/hostinfo\`)
      kind: Rule
      services:
        - name: ${DOMAIN_UID}-cluster-base-cluster
          port: 8001
EOF

    print_success "Ingress route YAML created: $manifest_file"
    
    # Check if ingress route needs to be updated
    local needs_update=false
    if ! kubectl get ingressroute "${DOMAIN_UID}-admin-route" -n "$DOMAIN_NS" &>/dev/null; then
        needs_update=true
    else
        # Compare with existing - only apply if different
        local current=$(kubectl get ingressroute "${DOMAIN_UID}-admin-route" -n "$DOMAIN_NS" -o yaml 2>/dev/null | grep -A 20 "spec:")
        local new=$(cat "$manifest_file" | grep -A 20 "spec:")
        if [ "$current" != "$new" ]; then
            needs_update=true
        fi
    fi
    
    if [ "$needs_update" = true ]; then
        print_step "Applying ingress route"
        print_command "kubectl apply -f $manifest_file"
        kubectl apply -f "$manifest_file"
        print_success "Ingress route applied"
    else
        print_success "Ingress route is already up to date"
    fi
    
    pause_for_review
}

wait_for_domain() {
    print_section "Waiting for Domain Startup"
    
    print_info "This may take several minutes..."
    
    # Wait for introspector job (MII only)
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        print_step "Waiting for introspector job to complete"
        local introspector_job="${DOMAIN_UID}-introspector"
        local job_found=false
        local job_completed=false
        
        for i in {1..60}; do
            if kubectl get job "$introspector_job" -n "$DOMAIN_NS" &> /dev/null; then
                job_found=true
                if kubectl wait --for=condition=complete job/"$introspector_job" -n "$DOMAIN_NS" --timeout=5s 2>/dev/null; then
                    print_success "Introspector job completed"
                    job_completed=true
                    break
                fi
            elif [ "$job_found" = true ]; then
                # Job existed but now gone - it completed and was cleaned up
                print_success "Introspector job completed and cleaned up"
                job_completed=true
                break
            fi
            sleep 5
        done
        
        if [ "$job_completed" = false ]; then
            print_warning "Introspector job timeout - continuing anyway"
        fi
    fi
    
    # Wait for admin server
    print_step "Waiting for Admin Server pod"
    wait_for_pods "$DOMAIN_NS" "weblogic.serverName=${DOMAIN_UID}-admin-server" 600 || {
        print_warning "Admin Server not ready yet, checking status..."
    }
    
    # Wait for managed servers
    print_step "Waiting for Managed Server pods"
    sleep 30  # Give some time for managed servers to start
    kubectl get pods -n "$DOMAIN_NS" -l "weblogic.domainUID=$DOMAIN_UID"
    
    print_success "Domain startup complete"
    pause_for_review
}

verify_deployment() {
    print_section "Verifying Deployment"
    
    print_step "Domain Status"
    kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS"
    
    print_step "Cluster Status"
    kubectl get cluster "${DOMAIN_UID}-cluster-1" -n "$DOMAIN_NS"
    
    print_step "Pods"
    kubectl get pods -n "$DOMAIN_NS" -l "weblogic.domainUID=$DOMAIN_UID"
    
    print_step "Services"
    kubectl get svc -n "$DOMAIN_NS" -l "weblogic.domainUID=$DOMAIN_UID"
    
    print_step "Ingress Routes"
    kubectl get ingressroute -n "$DOMAIN_NS"
    
    print_success "Deployment verification complete"
    pause_for_review
}

display_access_info() {
    print_section "Access Information"
    
    # Get LoadBalancer IP
    local lb_ip=""
    local service_type=$(kubectl get svc traefik-operator -n "$INGRESS_NS" -o jsonpath='{.spec.type}' 2>/dev/null)
    
    if [ "$service_type" = "LoadBalancer" ]; then
        print_info "Waiting for LoadBalancer IP assignment..."
        for i in {1..60}; do
            lb_ip=$(kubectl get svc traefik-operator -n "$INGRESS_NS" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
            if [ -n "$lb_ip" ]; then
                break
            fi
            sleep 2
        done
    fi
    
    echo ""
    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║      WebLogic Domain Deployed Successfully!               ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}Domain:${NC} ${DOMAIN_UID}"
    echo -e "${CYAN}${BOLD}Namespace:${NC} ${DOMAIN_NS}"
    echo -e "${CYAN}${BOLD}Type:${NC} $([ "$DOMAIN_TYPE" = "mii" ] && echo "Model-in-Image" || echo "Domain-in-Image")"
    echo ""
    
    if [ -n "$lb_ip" ]; then
        echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${GREEN}║                    ACCESS URLS                            ║${NC}"
        echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}${BOLD}WebLogic Admin Console:${NC}"
        echo -e "  ${BOLD}${GREEN}http://${lb_ip}/console${NC}"
        echo ""
        echo -e "${CYAN}${BOLD}Clustered Application (hostinfo):${NC}"
        echo -e "  ${BOLD}${GREEN}http://${lb_ip}/hostinfo/${NC}"
        echo ""
        echo -e "${CYAN}${BOLD}Credentials:${NC}"
        echo -e "  Username: ${BOLD}${ADMIN_USERNAME}${NC}"
        echo -e "  Password: ${BOLD}${ADMIN_PASSWORD}${NC}"
        echo ""
        echo -e "${BOLD}${GREEN}LoadBalancer IP: ${lb_ip}${NC}"
        echo ""
        echo -e "${YELLOW}${BOLD}Note:${NC} Only one domain type (MII or DII) should be active at a time"
        echo -e "      or use different hostnames for each domain to avoid path conflicts."
    else
        echo -e "${YELLOW}${BOLD}Warning: LoadBalancer IP not yet assigned${NC}"
        echo -e "  Check status: ${BOLD}kubectl get svc traefik-operator -n ${INGRESS_NS}${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    pause_for_review
}

generate_summary() {
    # Summary generation removed - access info is displayed by display_access_info()
    return 0
}

clean_environment() {
    print_banner "Cleaning WKO Environment"
    
    print_warning "This will remove all WebLogic Kubernetes Operator resources"
    
    if [ "$INTERACTIVE_MODE" = true ]; then
        echo -n "Are you sure? (yes/no): "
        read -r response
        if [ "$response" != "yes" ]; then
            print_info "Cleanup cancelled"
            exit 0
        fi
    fi
    
    # Clean both MII and DII namespaces if they exist
    local mii_ns="wls-mii-ns"
    local dii_ns="wls-dii-ns"
    local mii_uid="base-domain-mii"
    local dii_uid="base-domain-dii"
    
    for ns_type in "mii" "dii"; do
        local ns_name="wls-${ns_type}-ns"
        local domain_uid="base-domain-${ns_type}"
        
        if kubectl get namespace "$ns_name" &>/dev/null; then
            print_step "Cleaning $ns_type namespace: $ns_name"
            
            # Delete domain
            kubectl delete domain "$domain_uid" -n "$ns_name" --ignore-not-found=true
            kubectl delete cluster "${domain_uid}-cluster-1" -n "$ns_name" --ignore-not-found=true
            
            # Delete ingress routes
            kubectl delete ingressroute "${domain_uid}-admin-route" -n "$ns_name" --ignore-not-found=true
            
            # Delete secrets
            kubectl delete secret "${domain_uid}-weblogic-credentials" -n "$ns_name" --ignore-not-found=true
            kubectl delete secret "${domain_uid}-runtime-encryption-secret" -n "$ns_name" --ignore-not-found=true
            
            # Wait for pods to terminate
            print_step "Waiting for pods in $ns_name to terminate"
            kubectl wait --for=delete pod -l "weblogic.domainUID=$domain_uid" -n "$ns_name" --timeout=120s 2>/dev/null || true
            
            # Delete namespace
            print_step "Deleting namespace: $ns_name"
            kubectl delete namespace "$ns_name" --ignore-not-found=true
        fi
    done
    
    # Uninstall Traefik
    print_step "Uninstalling Traefik"
    helm uninstall "$INGRESS_RELEASE" -n "$INGRESS_NS" 2>/dev/null || true
    kubectl delete namespace "$INGRESS_NS" --ignore-not-found=true
    
    # Uninstall operator
    print_step "Uninstalling WebLogic Operator"
    helm uninstall "$OPERATOR_RELEASE" -n "$OPERATOR_NS" 2>/dev/null || true
    kubectl delete namespace "$OPERATOR_NS" --ignore-not-found=true
    
    # Clean work directory
    print_step "Cleaning work directory"
    rm -rf "$WKO_WORK_DIR"
    
    print_success "Cleanup complete"
}

show_help() {
    cat << EOF
${BOLD}WebLogic Kubernetes Operator (WKO) - Automated Deployment Script${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    --mii                Create Model-in-Image domain (default)
    --dii                Create Domain-in-Image domain
    --clean              Clean all WKO resources before deploying
    --delete             Delete all WKO resources and exit
    --skip-operator      Skip operator installation (assume already installed)
    --skip-ingress       Skip ingress controller installation
    --interactive        Interactive mode (prompt between steps)
    --non-interactive    Non-interactive mode (default, no prompts)
    -h, --help           Display this help message

${BOLD}DESCRIPTION:${NC}
    This script automates the deployment of WebLogic Server domains to Kubernetes
    using the WebLogic Kubernetes Operator. It performs the following steps:

    1. Install WebLogic Kubernetes Operator
    2. Install Traefik Ingress Controller
    3. Prepare domain namespace
    4. Create Kubernetes secrets for credentials
    5. Deploy WebLogic domain (MII or DII)
    6. Create ingress routes
    7. Verify deployment

${BOLD}DOMAIN TYPES:${NC}
    Model-in-Image (mii)   - WDT model in auxiliary image, domain created at runtime (Recommended)
    Domain-in-Image (dii)  - Complete domain pre-created in image (Deprecated)

${BOLD}EXAMPLES:${NC}
    # Deploy with Model-in-Image (default, non-interactive)
    $0 --mii

    # Deploy with Domain-in-Image
    $0 --dii

    # Deploy with interactive prompts
    $0 --mii --interactive

    # Clean and redeploy
    $0 --mii --clean

    # Skip operator installation (already installed)
    $0 --mii --skip-operator

    # Delete all resources
    $0 --delete

${BOLD}PREREQUISITES:${NC}
    - Kubernetes cluster (local or cloud)
    - kubectl configured and working
    - Helm 3.x installed
    - Images available in OCIR (public):
      * MII: scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-mii:12.2.1.4.0
      * DII: scl.ocir.io/idi1o0a010nx/dalquint-docker-images/wls-wdt-dii:12.2.1.4.0
    - OCIR credentials (set as environment variables):
      * export OCIR_USERNAME='<tenancy>/<username>'
      * export OCIR_AUTH_TOKEN='<auth-token>'

${BOLD}ACCESS INFORMATION:${NC}
    After successful deployment:
    - Admin Console: http://<NODE_IP>:30305/console
    - Application: http://<NODE_IP>:30305/hostinfo/
    - Credentials: weblogic / welcome1

For detailed documentation, see: replatform/WKO.md

EOF
}

################################################################################
# Main Script
################################################################################

main() {
    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --mii)
                DOMAIN_TYPE="mii"
                shift
                ;;
            --dii)
                DOMAIN_TYPE="dii"
                shift
                ;;
            --clean)
                CLEAN_MODE=true
                shift
                ;;
            --delete)
                DELETE_MODE=true
                shift
                ;;
            --skip-operator)
                SKIP_OPERATOR=true
                shift
                ;;
            --skip-ingress)
                SKIP_INGRESS=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --non-interactive)
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
    
    # Set namespace, UID, and domain name based on domain type
    if [ "$DOMAIN_TYPE" = "mii" ]; then
        DOMAIN_NS="wls-mii-ns"
        DOMAIN_UID="base-domain-mii"
        DOMAIN_NAME="mii_base_domain"
    else
        DOMAIN_NS="wls-dii-ns"
        DOMAIN_UID="base-domain-dii"
        DOMAIN_NAME="dii_base_domain"
    fi
    
    # Handle delete mode
    if [ "$DELETE_MODE" = true ]; then
        clean_environment
        exit 0
    fi
    
    # Handle clean mode
    if [ "$CLEAN_MODE" = true ]; then
        clean_environment
        print_success "Environment cleaned successfully"
        print_info "Run without --clean to deploy"
        exit 0
    fi
    
    # Display banner
    print_banner "WebLogic Kubernetes Operator - Automated Deployment"
    
    print_info "Domain Type: $([ "$DOMAIN_TYPE" = "mii" ] && echo "Model-in-Image (mii)" || echo "Domain-in-Image (dii)")"
    print_info "Domain Namespace: $DOMAIN_NS"
    print_info "Domain UID: $DOMAIN_UID"
    print_info "Cluster Replicas: $INITIAL_REPLICAS"
    print_info "Interactive Mode: $([ "$INTERACTIVE_MODE" = true ] && echo "Enabled" || echo "Disabled")"
    echo ""
    
    # Execute deployment workflow
    check_prerequisites
    setup_work_directory
    install_operator
    install_ingress
    prepare_domain_namespace
    
    # Check if domain already exists and is running
    local domain_exists=false
    if kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS" &>/dev/null; then
        local domain_status=$(kubectl get domain "$DOMAIN_UID" -n "$DOMAIN_NS" -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)
        if [ "$domain_status" = "True" ]; then
            domain_exists=true
            print_section "Domain Already Running"
            print_success "Domain '$DOMAIN_UID' is already deployed and healthy"
            print_info "Skipping domain creation, secrets, ConfigMap, and ingress"
            print_info "Use --clean to remove and recreate"
            echo ""
        fi
    fi
    
    # Only create domain resources if domain doesn't exist
    if [ "$domain_exists" = false ]; then
        create_secrets
        create_wdt_config_map
        
        # Create domain based on type
        if [ "$DOMAIN_TYPE" = "mii" ]; then
            create_domain_resource_mii
        else
            create_domain_resource_dii
        fi
        
        create_ingress_route
        wait_for_domain
        verify_deployment
    fi
    
    display_access_info
    generate_summary
    
    print_banner "WKO Deployment Complete!"
    print_success "All operations completed successfully"
    print_info "Summary: $WKO_WORK_DIR/summary.txt"
    print_info "Manifests: $WKO_WORK_DIR/manifests/"
}

# Run main function
main "$@"
