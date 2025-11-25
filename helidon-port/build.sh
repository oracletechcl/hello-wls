#!/bin/bash

# Build script for Helidon MP Host Information Application
# Builds JAR, Docker image, and provides testing options

set -e

APP_NAME="hostinfo"
IMAGE_NAME="hostinfo-helidon"
IMAGE_TAG="latest"
DOCKER_BUILD=false
BUILD_JAR=false
RUN_APP=false

# Show help if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: ./build.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --jar          Build JAR file with Maven"
    echo "  --docker       Build Docker image after Maven build"
    echo "  --run          Build and run the application"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./build.sh --jar              # Build JAR only"
    echo "  ./build.sh --docker           # Build JAR and Docker image"
    echo "  ./build.sh --run              # Build and run locally"
    exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --jar)
            BUILD_JAR=true
            shift
            ;;
        --docker)
            BUILD_JAR=true
            DOCKER_BUILD=true
            shift
            ;;
        --run)
            BUILD_JAR=true
            RUN_APP=true
            shift
            ;;
        --help)
            echo "Usage: ./build.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --jar          Build JAR file with Maven"
            echo "  --docker       Build Docker image after Maven build"
            echo "  --run          Build and run the application"
            echo "  --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./build.sh --jar              # Build JAR only"
            echo "  ./build.sh --docker           # Build JAR and Docker image"
            echo "  ./build.sh --run              # Build and run locally"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run './build.sh --help' for usage information"
            exit 1
            ;;
    esac
done

# Build JAR if requested
if [ "$BUILD_JAR" = true ]; then
    echo "================================================"
    echo "Building Helidon MP Host Information Application"
    echo "================================================"
    echo ""

    # Check if Maven is installed
    if ! command -v mvn &> /dev/null; then
        echo "ERROR: Maven is not installed or not in PATH"
        exit 1
    fi

    echo "Maven version:"
    mvn --version
    echo ""

    # Clean and build the project
    echo "Running Maven clean package..."
    mvn clean package -DskipTests

    # Check if build was successful
    if [ $? -eq 0 ]; then
        echo ""
        echo "================================================"
        echo "BUILD SUCCESSFUL!"
        echo "================================================"
        echo ""
        echo "JAR file location: target/hostinfo.jar"
        echo "Dependencies: target/libs/"
        echo ""
    else
        echo ""
        echo "================================================"
        echo "BUILD FAILED!"
        echo "================================================"
        exit 1
    fi
fi

# Build Docker image if requested
if [ "$DOCKER_BUILD" = true ]; then
    echo ""
    echo "================================================"
    echo "Building Docker Image"
    echo "================================================"
    echo ""
    
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi
    
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
        echo ""
        echo "To run with Docker:"
        echo "  docker run -p 8080:8080 ${IMAGE_NAME}:${IMAGE_TAG}"
        echo ""
        echo "To run with environment variables:"
        echo "  docker run -p 8080:8080 -e DB_MOCK_MODE=false -e DB_URL=... ${IMAGE_NAME}:${IMAGE_TAG}"
        echo ""
    else
        echo "ERROR: Docker build failed!"
        exit 1
    fi
fi

# Run application if requested
if [ "$RUN_APP" = true ]; then
    echo ""
    echo "================================================"
    echo "Starting Helidon MP Application"
    echo "================================================"
    echo ""
    
    echo "Access the application at:"
    echo "  http://localhost:8080/api/host-info"
    echo ""
    echo "OpenAPI documentation:"
    echo "  http://localhost:8080/openapi"
    echo ""
    echo "Health check:"
    echo "  http://localhost:8080/health"
    echo ""
    echo "Press Ctrl+C to stop the application"
    echo ""
    
    java -jar target/hostinfo.jar
else
    echo "To run the application:"
    echo "  java -jar target/hostinfo.jar"
    echo ""
    echo "Access the application at:"
    echo "  http://localhost:8080/api/host-info"
    echo ""
    echo "OpenAPI documentation:"
    echo "  http://localhost:8080/openapi"
    echo ""
    echo "Health check:"
    echo "  http://localhost:8080/health"
    echo ""
fi
