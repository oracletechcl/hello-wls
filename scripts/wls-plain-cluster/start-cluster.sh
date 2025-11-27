#!/bin/bash

################################################################################
# WebLogic Cluster Startup - Centralized Lab Script
# 
# This is a wrapper script that calls the backend cluster startup script
# Location: scripts/wls-plain-cluster/start-cluster.sh (centralized)
# Backend: standard-wls-deployment/server-startup-scripts/start-cluster.sh
################################################################################

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Backend script location
BACKEND_SCRIPT="$WORKSPACE_ROOT/standard-wls-deployment/server-startup-scripts/start-cluster.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if backend script exists
if [ ! -f "$BACKEND_SCRIPT" ]; then
    echo -e "${RED}ERROR: Backend script not found at: $BACKEND_SCRIPT${NC}"
    echo -e "${YELLOW}Expected location: standard-wls-deployment/server-startup-scripts/start-cluster.sh${NC}"
    exit 1
fi

# Check if backend script is executable
if [ ! -x "$BACKEND_SCRIPT" ]; then
    echo -e "${YELLOW}Making backend script executable...${NC}"
    chmod +x "$BACKEND_SCRIPT"
fi

# Display information
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}WebLogic Cluster Startup (Lab)${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}Calling backend script...${NC}"
echo -e "${YELLOW}Backend: $BACKEND_SCRIPT${NC}"
echo ""

# Call the backend script with all arguments passed to this script
"$BACKEND_SCRIPT" "$@"
