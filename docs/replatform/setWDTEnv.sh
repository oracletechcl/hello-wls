#!/bin/bash

################################################################################
# WDT Environment Setup Script
# 
# This script sets up the required environment variables for WDT operations.
# Source this script before running wdt.sh:
#   source ./setWDTEnv.sh
#   ./wdt.sh
################################################################################

# WebLogic Oracle Home
# Update this path to match your WebLogic installation
export ORACLE_HOME="/home/opc/wls"

# Java Home
# Update this path to match your JDK installation
export JAVA_HOME="/opt/jdk"

# Optional: Add Java and WebLogic binaries to PATH
export PATH="$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin:$PATH"

# Display current settings
echo "WDT Environment Variables Set:"
echo "  ORACLE_HOME: $ORACLE_HOME"
echo "  JAVA_HOME: $JAVA_HOME"
echo ""
echo "To use these settings, source this file:"
echo "  source ./setWDTEnv.sh"
