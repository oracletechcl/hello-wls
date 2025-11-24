#!/bin/bash

# Build script for Spring Boot Host Information Application
# This script builds the Spring Boot JAR using Maven

echo "================================================"
echo "Building Spring Boot Host Information Application"
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
mvn clean package

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "BUILD SUCCESSFUL!"
    echo "================================================"
    echo ""
    echo "JAR file location: target/hostinfo.jar"
    echo ""
    echo "To run the application:"
    echo "  java -jar target/hostinfo.jar"
    echo ""
    echo "To run with custom configuration:"
    echo "  java -jar target/hostinfo.jar --server.port=8081"
    echo ""
    echo "Access the application at:"
    echo "  http://localhost:8080/hostinfo/"
    echo ""
    echo "Access Swagger UI at:"
    echo "  http://localhost:8080/hostinfo/swagger-ui.html"
    echo ""
else
    echo ""
    echo "================================================"
    echo "BUILD FAILED!"
    echo "================================================"
    exit 1
fi
