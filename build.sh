#!/bin/bash

# Build script for WebLogic Host Info Application
# This script uses Maven to compile and package the application

echo "========================================="
echo "Building WebLogic Host Info Application"
echo "========================================="

# Set JAVA_HOME if not already set
export JAVA_HOME="${JAVA_HOME:-/home/opc/DevOps/jdk1.8.0_202}"

# Check if JAVA_HOME is set and exists
if [ ! -d "${JAVA_HOME}" ]; then
    echo "ERROR: Java home directory not found at ${JAVA_HOME}"
    echo "Please set JAVA_HOME environment variable or update this script"
    exit 1
fi

echo "Using Java from: ${JAVA_HOME}"

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "ERROR: Maven is not installed or not in PATH"
    echo "Please install Maven first:"
    echo "  - Download from https://maven.apache.org/download.cgi"
    echo "  - Or install via package manager: yum install maven"
    exit 1
fi

MAVEN_VERSION=$(mvn -version | head -n 1)
echo "Using Maven: ${MAVEN_VERSION}"
echo ""

# Clean and build with Maven
echo "Running Maven build..."
mvn clean package

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================="
    echo "Build successful!"
    echo "========================================="
    echo "WAR file created: target/hostinfo.war"
    echo ""
    echo "To deploy to WebLogic Server:"
    echo "1. Access WebLogic Admin Console"
    echo "2. Navigate to Deployments"
    echo "3. Click 'Install'"
    echo "4. Upload target/hostinfo.war"
    echo ""
    echo "Or copy to autodeploy directory:"
    echo "cp target/hostinfo.war \${DOMAIN_HOME}/autodeploy/"
    echo ""
else
    echo ""
    echo "========================================="
    echo "Build failed!"
    echo "========================================="
    echo "Please check the errors above."
    exit 1
fi
