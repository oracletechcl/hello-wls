#!/bin/bash

# WebLogic Cluster Startup Script
# This script starts the Admin Server and Managed Servers (ms1 and ms2)
# All servers will continue running until the script is terminated (Ctrl+C)

# Configuration
DOMAIN_HOME="/home/opc/wls/user_projects/domains/base_domain"
ADMIN_SERVER_SCRIPT="${DOMAIN_HOME}/startWebLogic.sh"
MANAGED_SERVER_SCRIPT="${DOMAIN_HOME}/bin/startManagedWebLogic.sh"
ADMIN_SERVER_URL="t3://localhost:7001"
ADMIN_PORT=7001

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file directory
LOG_DIR="$(pwd)/logs"
mkdir -p "${LOG_DIR}"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}WebLogic Cluster Startup Script${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if domain home exists
if [ ! -d "${DOMAIN_HOME}" ]; then
    echo -e "${RED}ERROR: Domain home not found at ${DOMAIN_HOME}${NC}"
    exit 1
fi

# Check if scripts exist
if [ ! -f "${ADMIN_SERVER_SCRIPT}" ]; then
    echo -e "${RED}ERROR: Admin server script not found at ${ADMIN_SERVER_SCRIPT}${NC}"
    exit 1
fi

if [ ! -f "${MANAGED_SERVER_SCRIPT}" ]; then
    echo -e "${RED}ERROR: Managed server script not found at ${MANAGED_SERVER_SCRIPT}${NC}"
    exit 1
fi

# Array to store background process IDs
declare -a PIDS

# Cleanup function to stop all servers
cleanup() {
    echo ""
    echo -e "${YELLOW}=========================================${NC}"
    echo -e "${YELLOW}Shutting down all servers...${NC}"
    echo -e "${YELLOW}=========================================${NC}"
    
    # Kill all background processes
    for pid in "${PIDS[@]}"; do
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}Stopping process $pid...${NC}"
            kill $pid 2>/dev/null
        fi
    done
    
    # Wait a moment for graceful shutdown
    sleep 3
    
    # Force kill if still running
    for pid in "${PIDS[@]}"; do
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${RED}Force stopping process $pid...${NC}"
            kill -9 $pid 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}All servers stopped.${NC}"
    exit 0
}

# Trap Ctrl+C and other termination signals
trap cleanup SIGINT SIGTERM

# Function to check if a port is listening
wait_for_port() {
    local port=$1
    local max_wait=120
    local waited=0
    
    echo -e "${YELLOW}Waiting for port ${port} to be available...${NC}"
    
    while [ $waited -lt $max_wait ]; do
        if netstat -tuln 2>/dev/null | grep -q ":${port} " || \
           ss -tuln 2>/dev/null | grep -q ":${port} "; then
            echo -e "${GREEN}Port ${port} is now listening!${NC}"
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done
    
    echo ""
    echo -e "${RED}Timeout waiting for port ${port}${NC}"
    return 1
}

# Step 1: Start Admin Server
echo -e "${BLUE}Step 1: Starting Admin Server...${NC}"
echo -e "${BLUE}=========================================${NC}"
cd "${DOMAIN_HOME}" || exit 1

ADMIN_LOG="${LOG_DIR}/admin-server.log"
echo -e "${YELLOW}Admin Server output will be logged to: ${ADMIN_LOG}${NC}"
"${ADMIN_SERVER_SCRIPT}" > "${ADMIN_LOG}" 2>&1 &
ADMIN_PID=$!
PIDS+=($ADMIN_PID)

echo -e "${GREEN}Admin Server started with PID: ${ADMIN_PID}${NC}"
echo ""

# Wait for Admin Server to be ready
if ! wait_for_port ${ADMIN_PORT}; then
    echo -e "${RED}Failed to start Admin Server${NC}"
    cleanup
    exit 1
fi

# Additional wait to ensure Admin Server is fully initialized
echo -e "${YELLOW}Waiting additional 20 seconds for Admin Server to fully initialize...${NC}"
sleep 20
echo ""

# Step 2: Start Managed Servers (ms1 and ms2) in parallel
echo -e "${BLUE}Step 2: Starting Managed Servers (ms1 and ms2)...${NC}"
echo -e "${BLUE}=========================================${NC}"
cd "${DOMAIN_HOME}/bin" || exit 1

# Start ms1
MS1_LOG="${LOG_DIR}/ms1.log"
echo -e "${YELLOW}MS1 output will be logged to: ${MS1_LOG}${NC}"
"${MANAGED_SERVER_SCRIPT}" ms1 "${ADMIN_SERVER_URL}" > "${MS1_LOG}" 2>&1 &
MS1_PID=$!
PIDS+=($MS1_PID)
echo -e "${GREEN}Managed Server 1 (ms1) started with PID: ${MS1_PID}${NC}"

# Start ms2 immediately (in parallel)
MS2_LOG="${LOG_DIR}/ms2.log"
echo -e "${YELLOW}MS2 output will be logged to: ${MS2_LOG}${NC}"
"${MANAGED_SERVER_SCRIPT}" ms2 "${ADMIN_SERVER_URL}" > "${MS2_LOG}" 2>&1 &
MS2_PID=$!
PIDS+=($MS2_PID)
echo -e "${GREEN}Managed Server 2 (ms2) started with PID: ${MS2_PID}${NC}"
echo ""

# Summary
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}All servers started successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${BLUE}Process IDs:${NC}"
echo -e "  Admin Server: ${ADMIN_PID}"
echo -e "  MS1:          ${MS1_PID}"
echo -e "  MS2:          ${MS2_PID}"
echo ""
echo -e "${BLUE}Log Files:${NC}"
echo -e "  Admin Server: ${ADMIN_LOG}"
echo -e "  MS1:          ${MS1_LOG}"
echo -e "  MS2:          ${MS2_LOG}"
echo ""
echo -e "${YELLOW}Servers are now running...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all servers${NC}"
echo ""

# Keep the script running and monitor the processes
while true; do
    sleep 10
    
    # Check if any process has died
    for i in "${!PIDS[@]}"; do
        pid="${PIDS[$i]}"
        if ! ps -p $pid > /dev/null 2>&1; then
            case $i in
                0)
                    echo -e "${RED}WARNING: Admin Server (PID $pid) has stopped!${NC}"
                    ;;
                1)
                    echo -e "${RED}WARNING: MS1 (PID $pid) has stopped!${NC}"
                    ;;
                2)
                    echo -e "${RED}WARNING: MS2 (PID $pid) has stopped!${NC}"
                    ;;
            esac
        fi
    done
done
