#!/bin/bash

# WebLogic Cluster Shutdown Script
# This script gracefully stops all WebLogic servers

# Configuration
DOMAIN_HOME="/home/opc/wls/user_projects/domains/base_domain"
ADMIN_PORT=7001

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}WebLogic Cluster Shutdown Script${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to find and kill WebLogic processes
stop_weblogic_processes() {
    echo -e "${YELLOW}Looking for WebLogic processes...${NC}"
    
    # Find all WebLogic server processes
    WEBLOGIC_PIDS=$(ps aux | grep -E 'weblogic\.(Name|Server)' | grep -v grep | awk '{print $2}')
    
    if [ -z "$WEBLOGIC_PIDS" ]; then
        echo -e "${GREEN}No WebLogic processes found running.${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Found WebLogic processes:${NC}"
    ps aux | grep -E 'weblogic\.(Name|Server)' | grep -v grep | awk '{print "  PID: "$2" - "$11" "$12" "$13" "$14" "$15}'
    echo ""
    
    # Try graceful shutdown first
    echo -e "${YELLOW}Attempting graceful shutdown...${NC}"
    for pid in $WEBLOGIC_PIDS; do
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}Sending TERM signal to PID $pid${NC}"
            kill $pid 2>/dev/null
        fi
    done
    
    # Wait up to 60 seconds for graceful shutdown
    echo -e "${YELLOW}Waiting for processes to stop (up to 60 seconds)...${NC}"
    local waited=0
    while [ $waited -lt 60 ]; do
        RUNNING_PIDS=$(ps aux | grep -E 'weblogic\.(Name|Server)' | grep -v grep | awk '{print $2}')
        if [ -z "$RUNNING_PIDS" ]; then
            echo -e "${GREEN}All WebLogic processes stopped gracefully.${NC}"
            return 0
        fi
        sleep 2
        waited=$((waited + 2))
        echo -n "."
    done
    echo ""
    
    # Force kill if still running
    STILL_RUNNING=$(ps aux | grep -E 'weblogic\.(Name|Server)' | grep -v grep | awk '{print $2}')
    if [ -n "$STILL_RUNNING" ]; then
        echo -e "${RED}Some processes did not stop gracefully. Force killing...${NC}"
        for pid in $STILL_RUNNING; do
            if ps -p $pid > /dev/null 2>&1; then
                echo -e "${RED}Force killing PID $pid${NC}"
                kill -9 $pid 2>/dev/null
            fi
        done
        sleep 2
    fi
    
    # Final check
    FINAL_CHECK=$(ps aux | grep -E 'weblogic\.(Name|Server)' | grep -v grep)
    if [ -z "$FINAL_CHECK" ]; then
        echo -e "${GREEN}All WebLogic processes stopped.${NC}"
    else
        echo -e "${RED}Warning: Some processes may still be running:${NC}"
        echo "$FINAL_CHECK"
    fi
}

# Main execution
stop_weblogic_processes

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Shutdown complete${NC}"
echo -e "${GREEN}=========================================${NC}"
