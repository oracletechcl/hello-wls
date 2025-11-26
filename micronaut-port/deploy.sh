#!/bin/bash

# Deploy Script for Micronaut Host Info Application
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
DOCKER_IMAGE_NAME="hostinfo"
DOCKER_IMAGE_TAG="micronaut"
APP_NAME="hostinfo-micronaut"
APP_NAMESPACE="hostinfo-micronaut"
KUBERNETES_DIR="./kubernetes"

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
    echo "http://wlsoke.alquinta.xyz/micronaut"
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

# Usage
usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    --oke                       Build, push image, and deploy to OKE
    --build                     Build Docker image only (uses build.sh)
    --push                      Push image to DockerHub and tag
    --deploy                    Deploy to OKE (requires image in registry or locally)
    --logs                      Show application logs
    --undeploy                  Remove deployment from OKE
    --status                    Show deployment status
    --help                      Show this help message

Note: Credentials are automatically loaded from Podman's stored login.
      If not authenticated, run: podman login docker.io

Examples:
    # Build Docker image
    $0 --build

    # Push to DockerHub (uses stored credentials)
    $0 --push

    # Full deployment to OKE (uses stored credentials)
    $0 --oke

    # Deploy using existing image
    $0 --deploy

    # Show status
    $0 --status

    # View logs
    $0 --logs

    # Remove from OKE
    $0 --undeploy

EOF
    exit 0
}

# Main
main() {
    if [ $# -eq 0 ]; then
        usage
    fi
    
    local command=$1
    
    case $command in
        --oke)
            check_prerequisites
            build_image
            push_image
            deploy_to_oke
            show_deployment_info
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
