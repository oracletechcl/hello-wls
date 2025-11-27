#!/bin/bash

################################################################################
# WIT Environment Setup Script
# 
# This script sets up the required environment variables for WIT operations.
# Source this script before running wit.sh:
#   source ./setWITEnv.sh
#   ./wit.sh
################################################################################

# Java Home
# Update this path to match your JDK installation
export JAVA_HOME="/opt/jdk"

# Docker configuration (optional)
# Uncomment and modify if you need specific Docker settings
# export DOCKER_HOST="unix:///var/run/docker.sock"
# export DOCKER_BUILDKIT=1

# WIT Cache Directory (optional)
# Default is ~/.imagetool-cache
# export IMAGETOOL_CACHE_DIR="$HOME/.imagetool-cache"

# Optional: Add Java to PATH
export PATH="$JAVA_HOME/bin:$PATH"

# Display current settings
echo "WIT Environment Variables Set:"
echo "  JAVA_HOME: $JAVA_HOME"
if [ -n "$IMAGETOOL_CACHE_DIR" ]; then
    echo "  IMAGETOOL_CACHE_DIR: $IMAGETOOL_CACHE_DIR"
fi
echo ""
echo "To use these settings, source this file:"
echo "  source ./setWITEnv.sh"
