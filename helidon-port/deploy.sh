#!/bin/bash

# Deploy Script for Helidon Host Info Application
# Leverages build.sh to build the Docker image, then pushes to DockerHub and deploys to OKE

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REGISTRY="docker.io"
DOCKER_IMAGE_NAME="hostinfo-helidon"
DOCKER_IMAGE_TAG="helidon"
APP_NAME="hostinfo-helidon"
APP_NAMESPACE="hostinfo-helidon"
KUBERNETES_DIR="./kubernetes"

# OCI Container Instance Configuration
OCI_COMPARTMENT_OCID="ocid1.compartment.oc1..aaaaaaaal7vn7wsy3qgizklrlfgo2vllfta3wkqlnfkvykoroite3lzxbnna"
SUBNET_OCID="ocid1.subnet.oc1.sa-santiago-1.aaaaaaaactbyskvixf2iggfzfcuwmkzcsrvja2wbv2pi5bxkaofaogurmkpq"
CONTAINER_NAME="hostinfo-helidon-container"
DISPLAY_NAME="hostinfo-helidon-instance"
APP_PORT="8080"

# Auto-load Docker credentials from Podman
get_docker_username() {
    podman login --get-login "$DOCKER_REGISTRY" 2>/dev/null || echo ""
}

DOCKER_USERNAME="$(get_docker_username)"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check docker
    if ! command -v docker &> /dev/null; then
        print_error "docker is not installed"
        exit 1
    fi
    print_success "docker found: $(docker --version)"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi
    print_success "kubectl found: $(kubectl version --client --short)"
    
    # Check build.sh exists
    if [ ! -f "./build.sh" ]; then
        print_error "build.sh not found in current directory"
        exit 1
    fi
    print_success "build.sh found"
    
    # Check kubernetes directory
    if [ ! -d "$KUBERNETES_DIR" ]; then
        print_error "kubernetes directory not found at $KUBERNETES_DIR"
        exit 1
    fi
    print_success "kubernetes directory found"
}

# Check prerequisites for Container Instance deployment
check_prerequisites_ci() {
    print_header "Checking Prerequisites for Container Instance"
    
    # Check docker
    if ! command -v docker &> /dev/null; then
        print_error "docker is not installed"
        exit 1
    fi
    print_success "docker found: $(docker --version)"
    
    # Check OCI CLI
    if ! command -v oci &> /dev/null; then
        print_error "OCI CLI not found. Please install the OCI CLI."
        exit 1
    fi
    print_success "OCI CLI found: $(oci --version)"
    
    # Check build.sh exists
    if [ ! -f "./build.sh" ]; then
        print_error "build.sh not found in current directory"
        exit 1
    fi
    print_success "build.sh found"
    
    # Check for OCI_COMPARTMENT_OCID
    if [ -z "$OCI_COMPARTMENT_OCID" ]; then
        print_error "OCI_COMPARTMENT_OCID environment variable is not set"
        exit 1
    fi
    print_success "OCI_COMPARTMENT_OCID is set"
    
    # Check for AD_NAME or attempt to discover
    if [ -z "$AD_NAME" ]; then
        print_warning "AD_NAME not set, attempting to discover automatically"
        AD_NAME=$(oci iam availability-domain list --compartment-id "$OCI_COMPARTMENT_OCID" \
            --query 'data[0].name' --raw-output 2>/dev/null)
        if [ -z "$AD_NAME" ]; then
            print_error "Could not determine availability domain. Please set AD_NAME environment variable."
            exit 1
        fi
        print_success "Using availability domain: $AD_NAME"
    else
        print_success "Using availability domain: $AD_NAME"
    fi
}

# Build Docker image using build.sh
build_image() {
    print_header "Building Docker Image"
    
    print_info "Using build.sh to build JAR and Docker image..."
    ./build.sh --docker
    print_success "Docker image built: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
}

# Push image to DockerHub
push_image() {
    print_header "Pushing Image to DockerHub"
    
    if [ -z "$DOCKER_USERNAME" ]; then
        print_error "No DockerHub credentials found in Podman"
        print_info "Please login to DockerHub first: podman login docker.io"
        exit 1
    fi
    
    IMAGE_FULL_NAME="${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
    
    print_info "Using stored Podman credentials for: $DOCKER_USERNAME"
    print_info "Tagging image as: $IMAGE_FULL_NAME"
    docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${IMAGE_FULL_NAME}
    
    print_info "Pushing image: $IMAGE_FULL_NAME"
    docker push ${IMAGE_FULL_NAME}
    print_success "Image pushed to DockerHub successfully"
}

# Deploy to OKE
deploy_to_oke() {
    print_header "Deploying to OKE"
    
    if [ -z "$DOCKER_USERNAME" ]; then
        DEPLOYMENT_IMAGE="docker.io/library/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
        print_warning "DOCKER_USERNAME not set. Using local image without registry prefix."
    else
        DEPLOYMENT_IMAGE="${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
    fi
    
    # Verify kubectl connection
    print_info "Verifying Kubernetes cluster connection..."
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    
    # Create a temporary deployment file with updated image
    TEMP_DEPLOY_FILE="/tmp/${APP_NAME}-deployment-temp.yaml"
    cp "$KUBERNETES_DIR/deployment.yaml" "$TEMP_DEPLOY_FILE"
    sed -i "s|image: docker.io/library/hostinfo-.*:.*|image: ${DEPLOYMENT_IMAGE}|g" "$TEMP_DEPLOY_FILE"
    
    # Deploy in order: namespace, configmap, deployment, ingress, hpa
    print_info "Creating namespace: $APP_NAMESPACE"
    kubectl apply -f "$KUBERNETES_DIR/namespace.yaml"
    print_success "Namespace applied"
    
    print_info "Applying ConfigMap..."
    kubectl apply -f "$KUBERNETES_DIR/configmap.yaml"
    print_success "ConfigMap applied"
    
    print_info "Applying Deployment..."
    kubectl apply -f "$TEMP_DEPLOY_FILE"
    print_success "Deployment applied"
    
    print_info "Applying Ingress..."
    kubectl apply -f "$KUBERNETES_DIR/ingress.yaml"
    print_success "Ingress applied"
    
    print_info "Applying HPA..."
    kubectl apply -f "$KUBERNETES_DIR/hpa.yaml"
    print_success "HPA applied"
    
    # Clean up temporary file
    rm -f "$TEMP_DEPLOY_FILE"
    
    # Wait for deployment to be ready
    print_info "Waiting for deployment to be ready (timeout: 5 minutes)..."
    if kubectl rollout status deployment/${APP_NAME} -n ${APP_NAMESPACE} --timeout=5m; then
        print_success "Deployment is ready"
    else
        print_warning "Deployment did not reach ready state within timeout"
    fi
    
    print_success "Deployment to OKE completed successfully"
}

# Show deployment info
show_deployment_info() {
    print_header "Deployment Information"
    
    echo -e "\n${BLUE}Pods:${NC}"
    kubectl get pods -n ${APP_NAMESPACE} 2>/dev/null || echo "No pods found"
    
    echo -e "\n${BLUE}Service:${NC}"
    kubectl get svc -n ${APP_NAMESPACE} 2>/dev/null || echo "No services found"
    
    echo -e "\n${BLUE}Ingress:${NC}"
    kubectl get ingress -n ${APP_NAMESPACE} 2>/dev/null || echo "No ingress found"
    
    echo -e "\n${BLUE}HPA:${NC}"
    kubectl get hpa -n ${APP_NAMESPACE} 2>/dev/null || echo "No HPA found"
    
    echo -e "\n${BLUE}Application URL:${NC}"
    echo "http://wlsoke.alquinta.xyz/helidon"
}

# Show logs
show_logs() {
    print_header "Application Logs"
    
    print_info "Streaming logs from deployment (Press Ctrl+C to stop)..."
    kubectl logs -n ${APP_NAMESPACE} -l app=${APP_NAME} -f --tail=50 --all-containers=true 2>/dev/null || \
        print_warning "No logs available yet"
}

# Undeploy from OKE
undeploy_from_oke() {
    print_header "Undeploying from OKE"
    
    print_info "Removing HPA..."
    kubectl delete -f "$KUBERNETES_DIR/hpa.yaml" 2>/dev/null || print_warning "HPA not found"
    
    print_info "Removing Ingress..."
    kubectl delete -f "$KUBERNETES_DIR/ingress.yaml" 2>/dev/null || print_warning "Ingress not found"
    
    print_info "Removing Deployment..."
    kubectl delete -f "$KUBERNETES_DIR/deployment.yaml" 2>/dev/null || print_warning "Deployment not found"
    
    print_info "Removing ConfigMap..."
    kubectl delete -f "$KUBERNETES_DIR/configmap.yaml" 2>/dev/null || print_warning "ConfigMap not found"
    
    print_info "Removing Namespace..."
    kubectl delete -f "$KUBERNETES_DIR/namespace.yaml" 2>/dev/null || print_warning "Namespace not found"
    
    print_success "Undeployment completed"
}

# Check if container instance already exists
check_existing_ci() {
    print_info "Checking for existing container instances..."
    
    local EXISTING_OCID=$(oci container-instances container-instance list \
        --compartment-id "$OCI_COMPARTMENT_OCID" \
        --display-name "$DISPLAY_NAME" \
        --lifecycle-state "ACTIVE" \
        --query 'data.items[0].id' \
        --raw-output 2>/dev/null || echo "")
    
    if [ -n "$EXISTING_OCID" ] && [ "$EXISTING_OCID" != "null" ]; then
        print_info "Found existing container instance: $EXISTING_OCID"
        CONTAINER_INSTANCE_OCID="$EXISTING_OCID"
        return 0
    else
        print_info "No existing container instance found"
        return 1
    fi
}

# Destroy existing container instance
destroy_ci() {
    if [ -z "$CONTAINER_INSTANCE_OCID" ]; then
        print_warning "No container instance OCID provided, skipping destroy"
        return 0
    fi
    
    print_info "Destroying existing container instance: $CONTAINER_INSTANCE_OCID"
    
    oci container-instances container-instance delete \
        --container-instance-id "$CONTAINER_INSTANCE_OCID" \
        --force \
        --wait-for-state SUCCEEDED || {
            print_error "Failed to delete container instance"
            exit 1
        }
    
    print_success "Container instance destroyed successfully"
    CONTAINER_INSTANCE_OCID=""
}

# Deploy container instance to OCI
deploy_ci() {
    print_header "Deploying Container Instance to OCI"
    
    if [ -z "$DOCKER_USERNAME" ]; then
        print_error "No DockerHub credentials found in Podman"
        print_info "Please login to DockerHub first: podman login docker.io"
        exit 1
    fi
    
    IMAGE_FULL_NAME="${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
    
    print_info "Deploying Container Instance..."
    print_info "Image: $IMAGE_FULL_NAME"
    print_info "Subnet: $SUBNET_OCID"
    
    # Create container instance
    set +e
    local CREATE_OUTPUT=$(oci container-instances container-instance create \
        --compartment-id "$OCI_COMPARTMENT_OCID" \
        --availability-domain "$AD_NAME" \
        --shape "CI.Standard.E4.Flex" \
        --shape-config '{"memoryInGBs":8,"ocpus":1}' \
        --display-name "$DISPLAY_NAME" \
        --vnics '[{"subnetId":"'$SUBNET_OCID'","assignPublicIp":false,"displayName":"'$CONTAINER_NAME'-vnic","hostnameLabel":"'$CONTAINER_NAME'"}]' \
        --containers '[{
            "displayName": "'$CONTAINER_NAME'",
            "imageUrl": "'$IMAGE_FULL_NAME'",
            "environmentVariables": {
                "JAVA_OPTS": "-Xms512m -Xmx512m"
            }
        }]' \
        --wait-for-state SUCCEEDED 2>&1)
    
    local EXIT_CODE=$?
    set -e
    
    if [ $EXIT_CODE -ne 0 ]; then
        print_error "Container creation failed with error:"
        echo "$CREATE_OUTPUT"
        exit 1
    fi
    
    # Extract the container instance OCID
    CONTAINER_INSTANCE_OCID=$(echo "$CREATE_OUTPUT" | grep -o 'ocid1\.computecontainerinstance[^"]*' | head -1)
    
    if [ -z "$CONTAINER_INSTANCE_OCID" ]; then
        print_error "Failed to extract container instance OCID from output"
        exit 1
    fi
    
    print_success "Created Container Instance: $CONTAINER_INSTANCE_OCID"
}

# Get container instance details
get_ci_details() {
    print_header "Container Instance Details"
    
    # Get VNIC ID
    local VNIC_ID=$(oci container-instances container-instance get \
        --container-instance-id "$CONTAINER_INSTANCE_OCID" \
        --query 'data.vnics[0]."vnic-id"' --raw-output 2>/dev/null || echo "")
    
    if [ -z "$VNIC_ID" ] || [ "$VNIC_ID" == "null" ]; then
        print_warning "Could not retrieve VNIC ID"
        return 0
    fi
    
    # Get private IP from VNIC
    CONTAINER_PRIVATE_IP=$(oci network vnic get \
        --vnic-id "$VNIC_ID" \
        --query 'data."private-ip"' --raw-output 2>/dev/null || echo "")
    
    if [ -n "$CONTAINER_PRIVATE_IP" ] && [ "$CONTAINER_PRIVATE_IP" != "null" ]; then
        echo ""
        print_success "Container Instance deployed successfully!"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}OCID:${NC}       $CONTAINER_INSTANCE_OCID"
        echo -e "${GREEN}Private IP:${NC} $CONTAINER_PRIVATE_IP"
        echo -e "${GREEN}URL:${NC}        http://${CONTAINER_PRIVATE_IP}:${APP_PORT}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        print_warning "Could not retrieve private IP address"
        echo -e "${GREEN}OCID:${NC} $CONTAINER_INSTANCE_OCID"
    fi
}

# Full Container Instance deployment workflow
deploy_full_ci() {
    check_prerequisites_ci
    build_image
    push_image
    
    # Check for existing instance and destroy if found
    if check_existing_ci; then
        print_info "Existing instance found - will destroy and redeploy with latest image"
        destroy_ci
        echo ""
    fi
    
    # Deploy new container instance
    deploy_ci
    
    # Wait for networking to be ready
    print_info "Waiting for networking to be ready..."
    sleep 30
    
    # Get instance details
    get_ci_details
    
    print_success "Container Instance deployment complete!"
}

# Undeploy Container Instance
undeploy_ci() {
    print_header "Undeploying Container Instance"
    
    if [ -z "$OCI_COMPARTMENT_OCID" ]; then
        print_error "OCI_COMPARTMENT_OCID environment variable is not set"
        exit 1
    fi
    
    if check_existing_ci; then
        destroy_ci
        print_success "Container Instance undeployment completed"
    else
        print_warning "No container instance found to undeploy"
    fi
}

# Usage
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    --oke                       Build, push image, and deploy to OKE
    --ci                        Build, push image, and deploy to OCI Container Instance
    --build                     Build Docker image only (uses build.sh)
    --push                      Push image to DockerHub and tag
    --deploy                    Deploy to OKE (requires image in registry or locally)
    --logs                      Show application logs
    --undeploy                  Remove deployment from OKE
    --undeploy-ci               Remove Container Instance from OCI
    --status                    Show deployment status
    --help                      Show this help message

Options:
    --no-push                   Skip build and push, use existing image (for --oke and --ci)
    --compartment-ocid OCID     Override compartment OCID (for --ci)
    --subnet-ocid OCID          Override subnet OCID (for --ci)

Note: Credentials are automatically loaded from Podman's stored login.
      If not authenticated, run: podman login docker.io

Container Instance Requirements:
    - OCI_COMPARTMENT_OCID environment variable must be set (or use --compartment-ocid)
    - AD_NAME environment variable (or will auto-discover)
    - OCI CLI must be configured

Examples:
    # Build Docker image
    $0 --build

    # Push to DockerHub (uses stored credentials)
    $0 --push

    # Full deployment to OKE (uses stored credentials)
    $0 --oke

    # Full deployment to OCI Container Instance
    $0 --ci

    # Deploy using existing image
    $0 --deploy

    # Show status
    $0 --status

    # View logs
    $0 --logs

    # Remove from OKE
    $0 --undeploy

    # Remove Container Instance
    $0 --undeploy-ci

EOF
    exit 0
}

# Main
main() {
    if [ $# -eq 0 ]; then
        usage
    fi
    
    # Parse all arguments (command and options)
    local command=""
    local NO_PUSH=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --oke|--ci|--build|--push|--deploy|--logs|--status|--undeploy|--undeploy-ci|--help)
                command="$1"
                shift
                ;;
            --no-push)
                NO_PUSH=true
                shift
                ;;
            --compartment-ocid)
                OCI_COMPARTMENT_OCID="$2"
                shift 2
                ;;
            --subnet-ocid)
                SUBNET_OCID="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    if [ -z "$command" ]; then
        print_error "No command specified"
        usage
    fi
    
    case $command in
        --oke)
            check_prerequisites
            if [ "$NO_PUSH" = false ]; then
                build_image
                push_image
            else
                print_info "Skipping build and push (--no-push specified)"
            fi
            deploy_to_oke
            show_deployment_info
            ;;
        --ci)
            if [ "$NO_PUSH" = true ]; then
                print_info "Skipping build and push (--no-push specified)"
                check_prerequisites_ci
                
                # Check for existing instance and destroy if found
                if check_existing_ci; then
                    print_info "Existing instance found - will destroy and redeploy"
                    destroy_ci
                    echo ""
                fi
                
                deploy_ci
                
                print_info "Waiting for networking to be ready..."
                sleep 30
                
                get_ci_details
                print_success "Container Instance deployment complete!"
            else
                deploy_full_ci
            fi
            ;;
        --build)
            check_prerequisites
            build_image
            ;;
        --push)
            check_prerequisites
            push_image
            ;;
        --deploy)
            check_prerequisites
            deploy_to_oke
            show_deployment_info
            ;;
        --logs)
            show_logs
            ;;
        --status)
            show_deployment_info
            ;;
        --undeploy)
            undeploy_from_oke
            ;;
        --undeploy-ci)
            undeploy_ci
            ;;
        --help)
            usage
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            ;;
    esac
}

main "$@"
