#!/bin/bash

################################################################################
# WebLogic Deploy Tooling (WDT) - Automated Demo Script
# 
# This script automates the WDT workflow documented in WDT.md
# All operations are idempotent - can be run multiple times safely
#
# Usage: ./wdt.sh [options]
# Options:
#   -c, --clean     Clean all WDT artifacts before starting
#   -h, --help      Display this help message
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment file if it exists
if [ -f "$SCRIPT_DIR/setWDTEnv.sh" ]; then
    source "$SCRIPT_DIR/setWDTEnv.sh"
fi
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WDT_WORK_DIR="$SCRIPT_DIR/wdt-output"
WDT_VERSION="4.3.8"
WDT_DOWNLOAD_URL="https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-${WDT_VERSION}/weblogic-deploy.zip"
WDT_HOME="$WDT_WORK_DIR/weblogic-deploy"

# Domain configuration
SOURCE_DOMAIN_HOME="/home/opc/wls/user_projects/domains/base_domain"
DOMAIN_NAME="base_domain"
MODEL_FILE="$WDT_WORK_DIR/${DOMAIN_NAME}_model.yaml"
ARCHIVE_FILE="$WDT_WORK_DIR/${DOMAIN_NAME}_archive.zip"
VARIABLE_FILE="$WDT_WORK_DIR/${DOMAIN_NAME}_variables.properties"
PASSPHRASE_FILE="$WDT_WORK_DIR/.wdt_passphrase"

# New domain configuration
NEW_DOMAIN_PARENT="$WDT_WORK_DIR/domains"
NEW_DOMAIN_NAME="wdt-sample-domain"
NEW_DOMAIN_HOME="$NEW_DOMAIN_PARENT/$NEW_DOMAIN_NAME"

# Admin credentials for new domain
ADMIN_USER="weblogic"
ADMIN_PASS="Welcome1"

# Flags
CLEAN_MODE=false
RESET_MODE=false
NO_RUN_MODE=false
INTERACTIVE_MODE=false  # Non-interactive by default (can be enabled with --interactive)

################################################################################
# Helper Functions
################################################################################

reset_environment() {
    print_banner "Resetting WDT Environment"
    
    local items_removed=0
    
    # Stop and remove the created domain if running
    if [ -d "$NEW_DOMAIN_HOME" ]; then
        print_step "Checking for running processes bound to domain"
        
        # Find all WebLogic processes related to this domain
        local domain_pids=$(ps aux | grep -E "[D]weblogic\.(Domain|Name)" | grep "$NEW_DOMAIN_NAME" | awk '{print $2}')
        
        if [ -n "$domain_pids" ]; then
            print_warning "Found running WebLogic processes for domain $NEW_DOMAIN_NAME"
            echo "$domain_pids" | while read pid; do
                if [ -n "$pid" ]; then
                    local proc_name=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
                    print_info "Force killing process: $proc_name (PID: $pid)"
                    kill -9 $pid 2>/dev/null || true
                fi
            done
            sleep 1
            print_success "All domain processes stopped"
        else
            print_info "No running processes found for domain"
        fi
        
        print_step "Removing created domain: $NEW_DOMAIN_HOME"
        rm -rf "$NEW_DOMAIN_HOME"
        print_success "Domain removed"
        items_removed=$((items_removed + 1))
    fi
    
    # Remove wdt-output directory and all its contents
    if [ -d "$WDT_WORK_DIR" ]; then
        print_step "Removing wdt-output directory: $WDT_WORK_DIR"
        rm -rf "$WDT_WORK_DIR"
        print_success "WDT output directory removed"
        items_removed=$((items_removed + 1))
    fi
    
    if [ $items_removed -eq 0 ]; then
        print_info "Nothing to reset - environment is clean"
    else
        print_success "Reset complete - removed $items_removed item(s)"
    fi
    
    echo ""
    print_info "You can now run the script again to start fresh"
}

print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "=============================================================================="
    echo "$1"
    echo "=============================================================================="
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${BLUE}${BOLD}>>> $1${NC}\n"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"
}

print_command() {
    echo -e "${MAGENTA}[CMD]${NC} $1"
}

pause_for_review() {
    if [ "$INTERACTIVE_MODE" = true ] && [ -t 0 ]; then
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read -r
    fi
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in java unzip wget curl; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and try again"
        exit 1
    fi
    
    # Check for source domain
    if [ ! -d "$SOURCE_DOMAIN_HOME" ]; then
        print_error "Source domain not found: $SOURCE_DOMAIN_HOME"
        exit 1
    fi
    
    if [ ! -f "$SOURCE_DOMAIN_HOME/config/config.xml" ]; then
        print_error "Invalid domain: config.xml not found in $SOURCE_DOMAIN_HOME"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

detect_oracle_home() {
    print_section "Detecting Oracle Home"
    
    # Try to detect ORACLE_HOME from domain
    if [ -z "$ORACLE_HOME" ]; then
        print_info "ORACLE_HOME not set, attempting to detect..."
        
        # Check common locations
        local possible_homes=(
            "/home/opc/wls/oracle_home"
            "/u01/oracle"
            "/opt/oracle/middleware"
            "/home/oracle/Oracle/Middleware"
        )
        
        for home in "${possible_homes[@]}"; do
            if [ -d "$home/wlserver" ]; then
                export ORACLE_HOME="$home"
                print_success "Detected ORACLE_HOME: $ORACLE_HOME"
                break
            fi
        done
        
        if [ -z "$ORACLE_HOME" ]; then
            print_error "Could not detect ORACLE_HOME. Please set it manually:"
            print_info "export ORACLE_HOME=/path/to/oracle/middleware"
            exit 1
        fi
    else
        print_success "Using ORACLE_HOME: $ORACLE_HOME"
    fi
    
    # Verify ORACLE_HOME
    if [ ! -d "$ORACLE_HOME/wlserver" ]; then
        print_error "Invalid ORACLE_HOME: $ORACLE_HOME/wlserver not found"
        exit 1
    fi
}

detect_java_home() {
    print_section "Detecting Java Home"
    
    if [ -z "$JAVA_HOME" ]; then
        print_info "JAVA_HOME not set, attempting to detect..."
        
        # Try to get Java from the system
        if command -v java &> /dev/null; then
            local java_path=$(which java)
            # Follow symlinks
            while [ -L "$java_path" ]; do
                java_path=$(readlink "$java_path")
            done
            export JAVA_HOME=$(dirname $(dirname "$java_path"))
            print_success "Detected JAVA_HOME: $JAVA_HOME"
        else
            print_error "Could not detect JAVA_HOME. Please set it manually:"
            print_info "export JAVA_HOME=/path/to/jdk"
            exit 1
        fi
    else
        print_success "Using JAVA_HOME: $JAVA_HOME"
    fi
    
    # Verify Java version
    local java_version=$("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1 | cut -d'"' -f2)
    print_info "Java version: $java_version"
}

clean_artifacts() {
    print_section "Cleaning Previous Artifacts (Idempotent Reset)"
    
    # Remove WDT working directory
    if [ -d "$WDT_WORK_DIR" ]; then
        print_step "Removing WDT working directory: $WDT_WORK_DIR"
        rm -rf "$WDT_WORK_DIR"
        print_success "Cleaned WDT working directory"
    else
        print_info "WDT working directory does not exist (clean state)"
    fi
    
    # Stop any running instances of the recreated domain
    if [ -d "$NEW_DOMAIN_HOME" ]; then
        print_step "Checking for running servers in recreated domain..."
        local admin_pid=$(ps -ef | grep "$NEW_DOMAIN_HOME" | grep "weblogic.Server" | grep -v grep | awk '{print $2}')
        if [ -n "$admin_pid" ]; then
            print_warning "Stopping running servers (PIDs: $admin_pid)"
            kill -9 $admin_pid 2>/dev/null || true
            sleep 2
            print_success "Stopped running servers"
        else
            print_info "No running servers found"
        fi
    fi
    
    print_success "Environment is clean and ready"
}

install_wdt() {
    print_section "Step 1: Installing WebLogic Deploy Tooling"
    
    # Create working directory
    mkdir -p "$WDT_WORK_DIR"
    cd "$WDT_WORK_DIR"
    
    # Check if WDT is already installed
    if [ -d "$WDT_HOME" ] && [ -f "$WDT_HOME/bin/discoverDomain.sh" ]; then
        print_info "WDT already installed at $WDT_HOME"
        print_success "WDT installation verified"
        return 0
    fi
    
    print_step "Downloading WDT version $WDT_VERSION"
    print_command "wget $WDT_DOWNLOAD_URL"
    
    if [ -f "weblogic-deploy.zip" ]; then
        print_info "WDT zip file already exists, skipping download"
    else
        if command -v wget &> /dev/null; then
            wget -q --show-progress "$WDT_DOWNLOAD_URL" || {
                print_error "Failed to download WDT"
                exit 1
            }
        elif command -v curl &> /dev/null; then
            curl -L -o weblogic-deploy.zip "$WDT_DOWNLOAD_URL" || {
                print_error "Failed to download WDT"
                exit 1
            }
        fi
    fi
    
    print_step "Extracting WDT"
    print_command "unzip -q weblogic-deploy.zip"
    unzip -q -o weblogic-deploy.zip
    
    # Verify installation
    if [ -f "$WDT_HOME/bin/discoverDomain.sh" ]; then
        chmod +x "$WDT_HOME/bin/"*.sh
        print_success "WDT installed successfully at $WDT_HOME"
    else
        print_error "WDT installation failed"
        exit 1
    fi
    
    # Display WDT structure
    print_info "WDT directory structure:"
    ls -la "$WDT_HOME" | head -10
    
    pause_for_review
}

setup_environment() {
    print_section "Step 1.3: Setting Up Environment Variables"
    
    print_step "Configuring environment variables"
    
    export WDT_HOME="$WDT_HOME"
    export PATH="$WDT_HOME/bin:$PATH"
    
    print_info "Environment variables:"
    echo -e "  ${CYAN}JAVA_HOME${NC}   = $JAVA_HOME"
    echo -e "  ${CYAN}ORACLE_HOME${NC} = $ORACLE_HOME"
    echo -e "  ${CYAN}WDT_HOME${NC}    = $WDT_HOME"
    
    # Verify WDT tools are accessible
    print_step "Verifying WDT tools"
    if "$WDT_HOME/bin/discoverDomain.sh" -help > /dev/null 2>&1; then
        print_success "WDT tools are accessible"
    else
        print_error "WDT tools are not accessible"
        exit 1
    fi
    
    pause_for_review
}

create_passphrase() {
    print_section "Step 2.0: Creating WDT Encryption Passphrase"
    
    if [ -f "$PASSPHRASE_FILE" ]; then
        print_info "Passphrase file already exists"
    else
        print_step "Generating secure passphrase"
        echo "WDTSecurePassphrase$(date +%s)" > "$PASSPHRASE_FILE"
        chmod 600 "$PASSPHRASE_FILE"
        print_success "Passphrase created and secured"
    fi
    
    print_info "Passphrase file: $PASSPHRASE_FILE"
}

discover_domain() {
    print_section "Step 2: Discovering WebLogic Domain"
    
    print_info "Source Domain: $SOURCE_DOMAIN_HOME"
    print_info "Output Files:"
    echo -e "  ${CYAN}Model File${NC}    : $MODEL_FILE"
    echo -e "  ${CYAN}Archive File${NC}  : $ARCHIVE_FILE"
    echo -e "  ${CYAN}Variable File${NC} : $VARIABLE_FILE"
    
    print_step "Running WDT Discover Domain Tool in OFFLINE mode"
    print_command "$WDT_HOME/bin/discoverDomain.sh \\"
    print_command "    -oracle_home $ORACLE_HOME \\"
    print_command "    -domain_home $SOURCE_DOMAIN_HOME \\"
    print_command "    -archive_file $ARCHIVE_FILE \\"
    print_command "    -model_file $MODEL_FILE \\"
    print_command "    -variable_file $VARIABLE_FILE \\"
    print_command "    -discover_passwords \\"
    print_command "    -passphrase_file $PASSPHRASE_FILE"
    
    echo ""
    print_warning "Discovery in progress... This may take a few minutes"
    echo ""
    
    # Run discovery and capture exit code (exit code 1 may indicate warnings, not necessarily failure)
    set +e
    "$WDT_HOME/bin/discoverDomain.sh" \
        -oracle_home "$ORACLE_HOME" \
        -domain_home "$SOURCE_DOMAIN_HOME" \
        -archive_file "$ARCHIVE_FILE" \
        -model_file "$MODEL_FILE" \
        -variable_file "$VARIABLE_FILE" \
        -discover_passwords \
        -passphrase_file "$PASSPHRASE_FILE" 2>&1 | while IFS= read -r line; do
            echo -e "${CYAN}[WDT]${NC} $line"
        done
    local discovery_exit_code=$?
    set -e
    
    # Check if discovery was successful by verifying essential files exist
    # Archive file may not exist if applications couldn't be archived (warnings)
    if [ -f "$MODEL_FILE" ]; then
        if [ -f "$ARCHIVE_FILE" ]; then
            print_success "Domain discovery completed successfully"
        else
            print_warning "Domain discovery completed with warnings (archive not created)"
            print_info "Model file was created successfully, continuing..."
        fi
        
        # Immediately update the model file with port offsets for the new domain
        print_step "Applying port offset (+1000) to model file"
        
        # Replace AdminServer: {} with AdminServer with ListenPort: 8001
        sed -i 's/^        AdminServer: {}$/        AdminServer:\n            ListenPort: 8001/' "$MODEL_FILE"
        
        # Update all other ListenPort values by adding 1000
        awk '/ListenPort:/ && !/8001/ {
            match($0, /ListenPort: ([0-9]+)/, arr);
            if (arr[1] != "") {
                indent = "";
                for(i=1; i<=match($0, /[^ ]/)-1; i++) indent = indent " ";
                new_port = arr[1] + 1000;
                print indent "ListenPort: " new_port;
                next;
            }
        }
        { print }' "$MODEL_FILE" > "$MODEL_FILE.tmp" && mv "$MODEL_FILE.tmp" "$MODEL_FILE"
        
        print_success "Ports updated in model: AdminServer→8001, ms1→8004, ms2→8005"
    else
        print_error "Domain discovery failed - model file not created"
        exit 1
    fi
    
    pause_for_review
}

review_discovery_output() {
    print_section "Step 2.4: Reviewing Discovery Output"
    
    print_step "Checking generated files"
    
    if [ -f "$MODEL_FILE" ]; then
        local model_size=$(du -h "$MODEL_FILE" | cut -f1)
        print_success "Model file created: $MODEL_FILE ($model_size)"
    else
        print_error "Model file not found"
    fi
    
    if [ -f "$ARCHIVE_FILE" ]; then
        local archive_size=$(du -h "$ARCHIVE_FILE" | cut -f1)
        print_success "Archive file created: $ARCHIVE_FILE ($archive_size)"
        
        print_info "Archive contents:"
        unzip -l "$ARCHIVE_FILE" 2>/dev/null | head -20
    else
        print_error "Archive file not found"
    fi
    
    if [ -f "$VARIABLE_FILE" ]; then
        local var_count=$(wc -l < "$VARIABLE_FILE")
        print_success "Variable file created: $VARIABLE_FILE ($var_count variables)"
        
        print_info "Sample variables (first 10):"
        head -10 "$VARIABLE_FILE" | while IFS= read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done
    fi
    
    print_step "Checking WDT logs"
    if [ -f "$WDT_HOME/logs/discoverDomain.log" ]; then
        local severe_count=$(grep -c "SEVERE" "$WDT_HOME/logs/discoverDomain.log" 2>/dev/null || echo "0")
        local warning_count=$(grep -c "WARNING" "$WDT_HOME/logs/discoverDomain.log" 2>/dev/null || echo "0")
        # Remove any whitespace/newlines and ensure it's a single number
        severe_count=$(echo "$severe_count" | head -1 | tr -d '\n\r ')
        warning_count=$(echo "$warning_count" | head -1 | tr -d '\n\r ')
        
        if [ "$severe_count" -eq 0 ] 2>/dev/null; then
            print_success "No SEVERE errors in log"
        elif [ -n "$severe_count" ] 2>/dev/null; then
            print_warning "Found $severe_count SEVERE errors in log"
        fi
        
        if [ "$warning_count" -gt 0 ] 2>/dev/null; then
            print_info "Found $warning_count warnings in log"
        fi
    fi
    
    pause_for_review
}

review_model_structure() {
    print_section "Step 3: Reviewing Model Structure"
    
    print_step "Displaying model sections"
    
    if [ -f "$MODEL_FILE" ]; then
        print_info "domainInfo section:"
        grep -A 5 "^domainInfo:" "$MODEL_FILE" | head -10 | while IFS= read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done
        
        echo ""
        print_info "topology section (first 10 lines):"
        grep -A 10 "^topology:" "$MODEL_FILE" | head -15 | while IFS= read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done
        
        echo ""
        print_info "Model statistics:"
        echo -e "  ${CYAN}Total lines${NC}: $(wc -l < "$MODEL_FILE")"
        echo -e "  ${CYAN}Servers${NC}: $(grep -c "^    [A-Za-z].*:$" "$MODEL_FILE" || echo "0")"
    fi
    
    pause_for_review
}

validate_model() {
    print_section "Step 3.4: Validating Model"
    
    print_step "Running WDT Validate Model Tool"
    print_command "$WDT_HOME/bin/validateModel.sh \\"
    print_command "    -oracle_home $ORACLE_HOME \\"
    print_command "    -model_file $MODEL_FILE \\"
    print_command "    -variable_file $VARIABLE_FILE \\"
    print_command "    -archive_file $ARCHIVE_FILE"
    
    echo ""
    
    "$WDT_HOME/bin/validateModel.sh" \
        -oracle_home "$ORACLE_HOME" \
        -model_file "$MODEL_FILE" \
        -variable_file "$VARIABLE_FILE" \
        -archive_file "$ARCHIVE_FILE" 2>&1 | while IFS= read -r line; do
            if echo "$line" | grep -q "SEVERE"; then
                echo -e "${RED}[WDT]${NC} $line"
            elif echo "$line" | grep -q "WARNING"; then
                echo -e "${YELLOW}[WDT]${NC} $line"
            else
                echo -e "${CYAN}[WDT]${NC} $line"
            fi
        done
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Model validation completed"
    else
        print_warning "Model validation completed with warnings/errors"
        print_info "Check the validation output above for details"
    fi
    
    pause_for_review
}

create_domain() {
    print_section "Step 4: Creating New Domain from Model"
    
    print_step "Preparing domain creation"
    mkdir -p "$NEW_DOMAIN_PARENT"
    
    print_info "New Domain Configuration:"
    echo -e "  ${CYAN}Domain Parent${NC}: $NEW_DOMAIN_PARENT"
    echo -e "  ${CYAN}Domain Name${NC}  : $NEW_DOMAIN_NAME"
    echo -e "  ${CYAN}Domain Home${NC}  : $NEW_DOMAIN_HOME"
    
    # Check if domain already exists
    if [ -d "$NEW_DOMAIN_HOME" ]; then
        print_warning "Domain already exists at $NEW_DOMAIN_HOME"
        print_step "Removing existing domain for idempotent execution"
        rm -rf "$NEW_DOMAIN_HOME"
    fi
    
    # Update variable file with admin credentials
    print_step "Setting admin credentials in variable file"
    local temp_var_file="$WDT_WORK_DIR/temp_variables.properties"
    cp "$VARIABLE_FILE" "$temp_var_file"
    sed -i "s/^AdminUserName=.*/AdminUserName=$ADMIN_USER/" "$temp_var_file"
    sed -i "s/^AdminPassword=.*/AdminPassword=$ADMIN_PASS/" "$temp_var_file"
    print_success "Admin credentials configured"
    
    print_step "Running WDT Create Domain Tool"
    print_command "$WDT_HOME/bin/createDomain.sh \\"
    print_command "    -oracle_home $ORACLE_HOME \\"
    print_command "    -domain_parent $NEW_DOMAIN_PARENT \\"
    print_command "    -domain_type WLS \\"
    print_command "    -model_file $MODEL_FILE \\"
    print_command "    -variable_file <temp_variables.properties> \\"
    print_command "    -archive_file $ARCHIVE_FILE \\"
    print_command "    -passphrase_file $PASSPHRASE_FILE"
    
    echo ""
    print_warning "Domain creation in progress... This may take several minutes"
    echo ""
    
    # Update the domain name in the model to avoid conflicts (ports already updated during discovery)
    if [ -f "$MODEL_FILE" ]; then
        print_step "Creating temporary model with updated domain name"
        
        # Create a temporary model with updated domain name
        local temp_model="$WDT_WORK_DIR/temp_model.yaml"
        sed "s/Name: $DOMAIN_NAME$/Name: $NEW_DOMAIN_NAME/" "$MODEL_FILE" > "$temp_model"
        
        print_success "Domain name updated to: $NEW_DOMAIN_NAME"
        
        "$WDT_HOME/bin/createDomain.sh" \
            -oracle_home "$ORACLE_HOME" \
            -domain_parent "$NEW_DOMAIN_PARENT" \
            -domain_type WLS \
            -model_file "$temp_model" \
            -variable_file "$temp_var_file" \
            -archive_file "$ARCHIVE_FILE" \
            -passphrase_file "$PASSPHRASE_FILE" 2>&1 | while IFS= read -r line; do
                if echo "$line" | grep -q "SEVERE"; then
                    echo -e "${RED}[WDT]${NC} $line"
                elif echo "$line" | grep -q "WARNING"; then
                    echo -e "${YELLOW}[WDT]${NC} $line"
                else
                    echo -e "${CYAN}[WDT]${NC} $line"
                fi
            done
        
        rm -f "$temp_model" "$temp_var_file"
    fi
    
    # Check if domain was created successfully
    if [ -d "$NEW_DOMAIN_HOME" ] && [ -f "$NEW_DOMAIN_HOME/config/config.xml" ]; then
        print_success "Domain created successfully at $NEW_DOMAIN_HOME"
    else
        print_error "Domain creation failed"
        exit 1
    fi
    
    pause_for_review
}

verify_domain_creation() {
    print_section "Step 4.3: Verifying Domain Creation"
    
    print_step "Checking domain structure"
    
    if [ -d "$NEW_DOMAIN_HOME" ]; then
        print_success "Domain directory exists: $NEW_DOMAIN_HOME"
        
        local key_files=(
            "config/config.xml"
            "bin/startWebLogic.sh"
            "servers/AdminServer/security/boot.properties"
        )
        
        for file in "${key_files[@]}"; do
            if [ -f "$NEW_DOMAIN_HOME/$file" ] || [ -d "$NEW_DOMAIN_HOME/$file" ]; then
                print_success "Found: $file"
            else
                print_warning "Missing: $file"
            fi
        done
        
        print_info "Domain contents:"
        ls -la "$NEW_DOMAIN_HOME" | while IFS= read -r line; do
            echo -e "  ${CYAN}$line${NC}"
        done
    else
        print_error "Domain directory not found"
        exit 1
    fi
    
    print_step "Checking WDT logs"
    if [ -f "$WDT_HOME/logs/createDomain.log" ]; then
        local severe_count=$(grep -c "SEVERE" "$WDT_HOME/logs/createDomain.log" || echo "0")
        
        if [ "$severe_count" -eq 0 ]; then
            print_success "No SEVERE errors in creation log"
        else
            print_warning "Found $severe_count SEVERE errors in log"
            print_info "Review log at: $WDT_HOME/logs/createDomain.log"
        fi
    fi
    
    pause_for_review
}

start_new_domain() {
    print_section "Step 4.4: Starting New Domain"
    
    # Check for port conflicts
    print_step "Checking for port conflicts"
    local listen_port=$(grep -oP 'listen-port>\K[0-9]+' "$NEW_DOMAIN_HOME/config/config.xml" | head -1)
    if [ -z "$listen_port" ]; then
        listen_port=8001  # default port for new domain (original 7001 + 1000)
    fi
    
    local port_in_use=$(netstat -tuln 2>/dev/null | grep ":$listen_port " || ss -tuln 2>/dev/null | grep ":$listen_port ")
    if [ -n "$port_in_use" ]; then
        print_error "Port $listen_port is already in use"
        print_warning "Another WebLogic instance or service is using this port"
        print_info "Please stop the conflicting service or change the domain's listen port"
        print_info "You can check what's using the port with: netstat -tuln | grep $listen_port"
        return 1
    fi
    print_success "Port $listen_port is available"
    
    print_step "Checking if Admin Server is already running"
    local admin_pid=$(ps -ef | grep "$NEW_DOMAIN_HOME" | grep "weblogic.Server" | grep -v grep | awk '{print $2}')
    
    if [ -n "$admin_pid" ]; then
        print_warning "Admin Server is already running (PID: $admin_pid)"
        print_info "Skipping startup"
        return 0
    fi
    
    print_step "Starting Admin Server"
    print_command "cd $NEW_DOMAIN_HOME && nohup ./startWebLogic.sh > /tmp/${NEW_DOMAIN_NAME}_admin.log 2>&1 &"
    
    cd "$NEW_DOMAIN_HOME"
    nohup ./startWebLogic.sh > "/tmp/${NEW_DOMAIN_NAME}_admin.log" 2>&1 &
    local server_pid=$!
    
    print_info "Admin Server starting with PID: $server_pid"
    print_info "Log file: /tmp/${NEW_DOMAIN_NAME}_admin.log"
    
    print_step "Waiting for server to start (this may take 1-2 minutes)..."
    
    local max_wait=120
    local elapsed=0
    local server_started=false
    
    while [ $elapsed -lt $max_wait ]; do
        if grep -q "Server state changed to RUNNING" "/tmp/${NEW_DOMAIN_NAME}_admin.log" 2>/dev/null; then
            server_started=true
            break
        fi
        
        if grep -q "Server state changed to FAILED" "/tmp/${NEW_DOMAIN_NAME}_admin.log" 2>/dev/null; then
            print_error "Server failed to start"
            print_info "Check log at: /tmp/${NEW_DOMAIN_NAME}_admin.log"
            return 1
        fi
        
        echo -n "."
        sleep 3
        elapsed=$((elapsed + 3))
    done
    
    echo ""
    
    if [ "$server_started" = true ]; then
        print_success "Admin Server started successfully"
        
        # Get listen port from config
        local listen_port=$(grep -oP 'listen-port>\K[0-9]+' "$NEW_DOMAIN_HOME/config/config.xml" | head -1)
        local hostname=$(hostname)
        
        print_info "Admin Console: http://${hostname}:${listen_port}/console"
        print_info "Default credentials: weblogic / (from your model)"
    else
        print_warning "Server startup timeout after $max_wait seconds"
        print_info "Server may still be starting. Check log: /tmp/${NEW_DOMAIN_NAME}_admin.log"
    fi
    
    pause_for_review
}

display_summary() {
    print_banner "WDT Demo Execution Summary"
    
    print_section "Artifacts Created"
    
    echo -e "${BOLD}Source Domain:${NC}"
    echo -e "  Location: ${CYAN}$SOURCE_DOMAIN_HOME${NC}"
    
    echo -e "\n${BOLD}WDT Installation:${NC}"
    echo -e "  Location: ${CYAN}$WDT_HOME${NC}"
    echo -e "  Version:  ${CYAN}$WDT_VERSION${NC}"
    
    echo -e "\n${BOLD}Discovery Artifacts:${NC}"
    if [ -f "$MODEL_FILE" ]; then
        echo -e "  Model File:    ${GREEN}✓${NC} ${CYAN}$MODEL_FILE${NC}"
        echo -e "                 Size: $(du -h "$MODEL_FILE" | cut -f1)"
    fi
    
    if [ -f "$ARCHIVE_FILE" ]; then
        echo -e "  Archive File:  ${GREEN}✓${NC} ${CYAN}$ARCHIVE_FILE${NC}"
        echo -e "                 Size: $(du -h "$ARCHIVE_FILE" | cut -f1)"
    fi
    
    if [ -f "$VARIABLE_FILE" ]; then
        echo -e "  Variable File: ${GREEN}✓${NC} ${CYAN}$VARIABLE_FILE${NC}"
        echo -e "                 Variables: $(wc -l < "$VARIABLE_FILE")"
    fi
    
    echo -e "\n${BOLD}New Domain:${NC}"
    if [ -d "$NEW_DOMAIN_HOME" ]; then
        echo -e "  Location: ${GREEN}✓${NC} ${CYAN}$NEW_DOMAIN_HOME${NC}"
        echo -e "  ${YELLOW}Note:${NC} All ports are offset by +1000 (e.g., 7001→8001, 7004→8004)"
        
        local admin_pid=$(ps -ef | grep "$NEW_DOMAIN_HOME" | grep "weblogic.Server" | grep -v grep | awk '{print $2}')
        if [ -n "$admin_pid" ]; then
            echo -e "  Status:   ${GREEN}RUNNING${NC} (PID: $admin_pid)"
            
            local listen_port=$(grep -oP 'listen-port>\K[0-9]+' "$NEW_DOMAIN_HOME/config/config.xml" | head -1)
            local hostname=$(hostname)
            echo -e "  Console:  ${CYAN}http://${hostname}:${listen_port}/console${NC}"
        else
            echo -e "  Status:   ${YELLOW}STOPPED${NC}"
        fi
    fi
    
    echo -e "\n${BOLD}Logs:${NC}"
    echo -e "  WDT Logs:      ${CYAN}$WDT_HOME/logs/${NC}"
    echo -e "  Server Log:    ${CYAN}/tmp/${NEW_DOMAIN_NAME}_admin.log${NC}"
    
    echo -e "\n${BOLD}Next Steps:${NC}"
    echo -e "  1. Access Admin Console at the URL above"
    echo -e "  2. Review the model file: ${CYAN}$MODEL_FILE${NC}"
    echo -e "  3. Explore WDT logs for details"
    echo -e "  4. Compare source and recreated domains"
    
    echo -e "\n${BOLD}Cleanup:${NC}"
    echo -e "  To clean all artifacts and start fresh:"
    echo -e "  ${CYAN}$0 --clean${NC}"
    
    print_banner "WDT Demo Completed Successfully!"
}

show_help() {
    cat << EOF
${BOLD}WebLogic Deploy Tooling (WDT) - Automated Demo Script${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -c, --clean          Clean all WDT artifacts before starting (idempotent reset)
    -n, --no-run         Create domain but do not start it
    --interactive        Interactive mode (prompt between steps)
    --non-interactive    Non-interactive mode (default, no prompts)
    -h, --help           Display this help message

${BOLD}DESCRIPTION:${NC}
    This script automates the WebLogic Deploy Tooling workflow documented in WDT.md.
    It performs the following steps:

    1. Install WebLogic Deploy Tooling
    2. Discover existing WebLogic domain
    3. Create model, archive, and variable files
    4. Validate the model
    5. Create a new domain from the model
    6. Start the new domain (skip with --no-run)

    All operations are idempotent - the script can be run multiple times safely.

${BOLD}EXAMPLES:${NC}
    # Run the full demo
    $0

    # Clean and run fresh
    $0 --clean

    # Create domain without starting it
    $0 --no-run

    # Reset everything (remove created domain and all WDT outputs)
    $0 --reset

${BOLD}REQUIREMENTS:${NC}
    - WebLogic Server 12.2.1.4 or later
    - Java JDK 1.8 or later
    - Source domain at: $SOURCE_DOMAIN_HOME
    - Internet access for downloading WDT

${BOLD}ENVIRONMENT VARIABLES:${NC}
    ORACLE_HOME     WebLogic installation directory (auto-detected if not set)
    JAVA_HOME       Java JDK directory (auto-detected if not set)

For more information, see: replatform/WDT.md

EOF
}

################################################################################
# Main Execution
################################################################################

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                CLEAN_MODE=true
                shift
                ;;
            -r|--reset)
                RESET_MODE=true
                shift
                ;;
            -n|--no-run)
                NO_RUN_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --non-interactive)
                INTERACTIVE_MODE=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Handle reset mode
    if [ "$RESET_MODE" = true ]; then
        reset_environment
        exit 0
    fi
    
    # Display banner
    print_banner "WebLogic Deploy Tooling (WDT) - Automated Demo"
    echo -e "${CYAN}Following the procedures documented in WDT.md${NC}\n"
    
    # Check prerequisites
    check_prerequisites
    
    # Detect environment
    detect_oracle_home
    detect_java_home
    
    # Clean if requested
    if [ "$CLEAN_MODE" = true ]; then
        clean_artifacts
    else
        # Always clean for idempotency
        clean_artifacts
    fi
    
    # Execute WDT workflow
    install_wdt
    setup_environment
    create_passphrase
    discover_domain
    review_discovery_output
    review_model_structure
    validate_model
    create_domain
    verify_domain_creation
    
    # Start domain unless --no-run flag is set
    if [ "$NO_RUN_MODE" = false ]; then
        start_new_domain
    else
        print_info "Skipping domain startup (--no-run flag set)"
        print_info "To start the domain manually, run:"
        print_info "  cd $NEW_DOMAIN_HOME && ./startWebLogic.sh"
    fi
    
    # Display summary
    display_summary
}

# Run main function
main "$@"
