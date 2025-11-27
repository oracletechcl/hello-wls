# WebLogic Deploy Tooling (WDT) - Complete Demo Guide

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Install WebLogic Deploy Tooling](#step-1-install-weblogic-deploy-tooling)
4. [Step 2: Discover Existing Domain](#step-2-discover-existing-domain)
5. [Step 3: Examine Discovery Artifacts](#step-3-examine-discovery-artifacts)
6. [Step 4: Validate the Model](#step-4-validate-the-model)
7. [Step 5: Create New Domain from Model](#step-5-create-new-domain-from-model)
8. [Step 6: Start and Verify New Domain](#step-6-start-and-verify-new-domain)
9. [Advanced Topics](#advanced-topics)
10. [Troubleshooting](#troubleshooting)
11. [Script Documentation](#script-documentation)
    - [Overview](#script-overview)
    - [Prerequisites](#script-prerequisites)
    - [Usage](#script-usage)
    - [Configuration](#script-configuration)
    - [Features](#script-features)
    - [Workflow](#script-workflow)
    - [Troubleshooting](#script-troubleshooting-1)
12. [Appendix: WDT Model Schema Documentation](#appendix-wdt-model-schema-documentation)
13. [Conclusion](#conclusion)

## Overview

This guide provides detailed, step-by-step instructions for using **WebLogic Deploy Tooling (WDT)** to discover, model, and recreate a WebLogic Server 12.2.1.4 domain. This document is designed for demonstration purposes and includes all commands and explanations needed to successfully execute the WDT workflow.

**WebLogic Deploy Tooling (WDT)** is a declarative, model-driven approach to WebLogic Server domain lifecycle management that eliminates the need for hand-coded WLST scripts. It provides tools to:
- Discover existing domains and create portable models
- Create new domains from models
- Update existing domains
- Migrate domains across environments

## Prerequisites

### System Requirements

- **WebLogic Server**: 12.2.1.4 (already installed)
- **Java**: JDK 1.8 (required for WLS 12.2.1.4)
- **Domain Location**: `/home/opc/wls/user_projects/domains/base_domain`
- **Operating System**: Linux (bash shell)
- **Minimum Permissions**: Read access to domain home directory

### Required Information

Before starting, gather the following information about your domain:

1. **ORACLE_HOME**: WebLogic Server installation directory
2. **DOMAIN_HOME**: Domain directory location
3. **Admin Credentials**: WebLogic admin username and password (for online discovery)
4. **Domain Type**: WLS, JRF, or custom (default: WLS)

## Step 1: Install WebLogic Deploy Tooling

### 1.1 Download WDT

Download the latest production release of WDT from the GitHub releases page:

```bash
# Create a working directory for WDT
mkdir -p ~/wdt-demo
cd ~/wdt-demo

# Download the latest WDT release (check GitHub for the latest version)
# Example: Download version 4.2.0 (or latest available)
wget https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-4.2.0/weblogic-deploy.zip

# Alternative: Use curl if wget is not available
# curl -LO https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-4.2.0/weblogic-deploy.zip
```

**Note**: Visit https://github.com/oracle/weblogic-deploy-tooling/releases to find the latest stable release version.

### 1.2 Extract WDT

```bash
# Extract the WDT installation
unzip weblogic-deploy.zip

# Verify extraction
ls -la weblogic-deploy/
```

Expected directory structure:
```
weblogic-deploy/
├── bin/                    # Tool scripts (discoverDomain.sh, createDomain.sh, etc.)
├── lib/                    # JAR files and libraries
│   └── typedefs/          # Domain type definitions (WLS.json, JRF.json, etc.)
├── samples/               # Sample models and configurations
└── etc/                   # Additional configuration files
```

### 1.3 Set Environment Variables

```bash
# Set JAVA_HOME (adjust path to your JDK installation)
export JAVA_HOME=/usr/java/jdk1.8.0_291
# Verify Java version
$JAVA_HOME/bin/java -version

# Set ORACLE_HOME (adjust to your WebLogic installation path)
export ORACLE_HOME=/home/opc/wls/oracle_home
# Alternative common locations:
# export ORACLE_HOME=/u01/oracle
# export ORACLE_HOME=/opt/oracle/middleware

# Verify ORACLE_HOME
ls -l $ORACLE_HOME/wlserver

# Set WDT_HOME for convenience
export WDT_HOME=~/wdt-demo/weblogic-deploy

# Add WDT bin directory to PATH (optional but convenient)
export PATH=$WDT_HOME/bin:$PATH
```

**Important**: The JDK used to run WDT tools will be the JDK used to install WebLogic Server in the Oracle Home, not necessarily the one defined by JAVA_HOME. Set JAVA_HOME to match the WebLogic installation JDK for best results.

### 1.4 Verify Installation

```bash
# Test that WDT tools are accessible
$WDT_HOME/bin/discoverDomain.sh -help

# You should see the help output for the Discover Domain Tool
```

## Step 2: Discover the Existing WebLogic Domain

The **Discover Domain Tool** inspects an existing domain and creates:
1. **Model File** (YAML or JSON): Declarative representation of domain configuration
2. **Archive File** (ZIP): Applications, libraries, and other binaries referenced by the domain
3. **Variable File** (Properties): Externalized properties for environment-specific values

### 2.1 Offline Discovery (Recommended for Initial Discovery)

Offline mode uses WLST offline to read the domain configuration directly from the filesystem.

#### Basic Offline Discovery

```bash
# Navigate to your working directory
cd ~/wdt-demo

# Set variables for clarity
DOMAIN_HOME=/home/opc/wls/user_projects/domains/base_domain
MODEL_FILE=./base_domain_model.yaml
ARCHIVE_FILE=./base_domain_archive.zip
VARIABLE_FILE=./base_domain_variables.properties

# Run discovery in offline mode
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -archive_file $ARCHIVE_FILE \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE
```

**What happens during discovery:**
- WDT reads the domain configuration from `config.xml` and related files
- Applications, libraries, and scripts are collected into the archive file
- Configuration is written to the model file in YAML format
- Passwords are replaced with `--FIX ME--` placeholders (by default)
- Environment-specific values are extracted to the variable file

#### Discovery with Password Discovery

To discover actual passwords from the domain (requires WDT 4.1.0+):

```bash
# Create a passphrase for WDT encryption (store this securely!)
echo "MySecureWDTPassphrase2024" > ~/wdt_passphrase.txt
chmod 600 ~/wdt_passphrase.txt

# Discover domain with passwords
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -archive_file $ARCHIVE_FILE \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -discover_passwords \
    -passphrase_file ~/wdt_passphrase.txt
```

**Security Note**: Passwords will be encrypted using WDT encryption and stored in the model file. Keep your passphrase secure!

#### Discovery with Security Provider Data

To discover users, groups, policies, and roles (requires WDT 4.2.0+):

```bash
# Discover all security provider data
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -archive_file $ARCHIVE_FILE \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -discover_passwords \
    -discover_security_provider_data ALL \
    -passphrase_file ~/wdt_passphrase.txt

# Or discover specific providers:
# -discover_security_provider_data DefaultAuthenticator,XACMLAuthorizer
```

Provider types you can discover:
- **DefaultAuthenticator**: Users and groups
- **XACMLAuthorizer**: Authorization policies
- **XACMLRoleMapper**: Role definitions
- **DefaultCredentialMapper**: Credential mappings
- **ALL**: All of the above

### 2.2 Online Discovery (Alternative Method)

Online mode uses WLST online to connect to a running Administration Server via MBeans.

#### Prerequisites for Online Discovery
- Administration Server must be running
- You need admin credentials

#### Start the Administration Server (if not running)

```bash
# Navigate to domain directory
cd /home/opc/wls/user_projects/domains/base_domain

# Start the Admin Server
nohup ./startWebLogic.sh > /tmp/admin_server.log 2>&1 &

# Wait for server to start (check log)
tail -f /tmp/admin_server.log
# Look for "Server state changed to RUNNING"
# Press Ctrl+C to exit tail

# Verify server is running
ps -ef | grep weblogic
```

#### Online Discovery from Admin Server Host

```bash
# Run discovery in online mode
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -archive_file $ARCHIVE_FILE \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -admin_user weblogic \
    -admin_url t3://localhost:7001

# You will be prompted for the admin password
# Enter the password when prompted
```

**Alternative**: Provide password via environment variable:
```bash
# Set password in environment variable
export ADMIN_PASSWORD=welcome1
export WLS_ADMIN_PASSWORD=$ADMIN_PASSWORD

# Use environment variable for password
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -archive_file $ARCHIVE_FILE \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -admin_user weblogic \
    -admin_url t3://localhost:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD
```

#### Online Discovery in Remote Mode

If running WDT from a remote machine without access to the domain filesystem:

```bash
# Remote discovery (no archive file created)
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -remote \
    -model_file $MODEL_FILE \
    -admin_user weblogic \
    -admin_url t3://remote-admin-server:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD

# The model will contain TODO comments for files that need to be manually collected
```

### 2.3 Domain Type Specification

If your domain is not a standard WLS domain (e.g., JRF, Restricted JRF, SOA):

```bash
# Discover a JRF domain
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -domain_type JRF \
    -archive_file $ARCHIVE_FILE \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE

# For WLS 12.2.1.4 standard domain, use WLS (default):
# -domain_type WLS
```

Available domain types (must have corresponding typedef file):
- `WLS`: Standard WebLogic Server domain
- `JRF`: Java Required Files (FMW Infrastructure)
- `RestrictedJRF`: Restricted JRF
- Custom domain types can be defined in `$WDT_HOME/lib/typedefs/`

### 2.4 Verify Discovery Output

```bash
# Check that all files were created
ls -lh base_domain_*

# Expected output:
# base_domain_model.yaml          - Domain model
# base_domain_archive.zip         - Archive with applications and libraries
# base_domain_variables.properties - Variable file with externalized values

# View the model file
less base_domain_model.yaml

# Check the archive contents
unzip -l base_domain_archive.zip

# Review the variable file
cat base_domain_variables.properties

# Check the WDT log for any issues
cat $WDT_HOME/logs/discoverDomain.log
```

## Step 3: Review and Edit the Model

### 3.1 Understanding the Model Structure

The WDT model file has four main sections:

```yaml
domainInfo:
    # Domain-level information
    AdminUserName: weblogic
    AdminPassword: --FIX ME--
    ServerStartMode: prod

topology:
    # Servers, clusters, machines, templates
    Name: base_domain
    AdminServerName: AdminServer
    Server:
        AdminServer:
            ListenPort: 7001
            
resources:
    # JDBC, JMS, WLDF, and other resources
    JDBCSystemResource:
        MyDataSource:
            # ...
            
appDeployments:
    # Applications and libraries
    Application:
        myapp:
            SourcePath: wlsdeploy/applications/myapp.war
            Target: mycluster
```

### 3.2 Fix Password Placeholders

If you didn't use `-discover_passwords`, edit the model to replace `--FIX ME--` placeholders:

```bash
# Open the model in your preferred editor
vi base_domain_model.yaml

# Find and replace --FIX ME-- placeholders with actual values
# Common locations:
# - domainInfo:/AdminPassword
# - resources:/JDBCSystemResource/<name>/JdbcResource/JDBCDriverParams/PasswordEncrypted
# - topology:/Security/User/<username>/Password
```

**Alternatively**, use the WDT Encrypt Model Tool (recommended):

```bash
# Create a properties file with passwords
cat > passwords.properties << EOF
domainInfo.AdminPassword=welcome1
resources.JDBCSystemResource.MyDataSource.JdbcResource.JDBCDriverParams.PasswordEncrypted=dbpassword123
EOF

# Merge passwords into variable file
cat passwords.properties >> base_domain_variables.properties

# Update model to use variable tokens
# Change: AdminPassword: --FIX ME--
# To:     AdminPassword: @@PROP:domainInfo.AdminPassword@@

# Encrypt the variable file
$WDT_HOME/bin/encryptModel.sh \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -passphrase_file ~/wdt_passphrase.txt
```

### 3.3 Review and Customize

```bash
# Review key sections of the model

# Check domain configuration
grep -A 10 "domainInfo:" base_domain_model.yaml

# Check server configuration
grep -A 20 "topology:" base_domain_model.yaml

# Check application deployments
grep -A 10 "appDeployments:" base_domain_model.yaml

# Check JDBC data sources
grep -A 20 "JDBCSystemResource:" base_domain_model.yaml
```

### 3.4 Validate the Model

Use the Validate Model Tool to check for errors:

```bash
# Validate the model
$WDT_HOME/bin/validateModel.sh \
    -oracle_home $ORACLE_HOME \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -archive_file $ARCHIVE_FILE

# Check validation output
# Look for SEVERE or WARNING messages
```

## Step 4: Create a New Domain from the Model

Now that you have a validated model, you can create a new domain.

### 4.1 Prepare for Domain Creation

```bash
# Create a directory for the new domain
NEW_DOMAIN_PARENT=~/wdt-demo/domains
mkdir -p $NEW_DOMAIN_PARENT

# Define the new domain name
NEW_DOMAIN_NAME=base_domain_recreated
NEW_DOMAIN_HOME=$NEW_DOMAIN_PARENT/$NEW_DOMAIN_NAME
```

### 4.2 Create Domain Using Model

```bash
# Create the domain
$WDT_HOME/bin/createDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_parent $NEW_DOMAIN_PARENT \
    -domain_type WLS \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -archive_file $ARCHIVE_FILE

# If using encrypted passwords, include passphrase:
$WDT_HOME/bin/createDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_parent $NEW_DOMAIN_PARENT \
    -domain_type WLS \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -archive_file $ARCHIVE_FILE \
    -passphrase_file ~/wdt_passphrase.txt

# Alternatively, specify the full domain path:
$WDT_HOME/bin/createDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $NEW_DOMAIN_HOME \
    -domain_type WLS \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE \
    -archive_file $ARCHIVE_FILE
```

**What happens during domain creation:**
1. WDT creates the domain directory structure
2. Applies the base WebLogic domain template
3. Configures servers, clusters, and other topology elements
4. Creates and configures resources (data sources, JMS, etc.)
5. Deploys applications from the archive file
6. Sets up security realms and providers
7. Creates `boot.properties` files for development domains

### 4.3 Verify Domain Creation

```bash
# Check that the domain was created
ls -la $NEW_DOMAIN_HOME

# Verify key files exist
ls -la $NEW_DOMAIN_HOME/config/config.xml
ls -la $NEW_DOMAIN_HOME/bin/
ls -la $NEW_DOMAIN_HOME/servers/AdminServer/

# Check for boot.properties (if development mode)
ls -la $NEW_DOMAIN_HOME/servers/AdminServer/security/boot.properties

# Review the creation log
cat $WDT_HOME/logs/createDomain.log | grep -i "severe\|error\|warning"
```

### 4.4 Start the New Domain

```bash
# Navigate to the new domain directory
cd $NEW_DOMAIN_HOME

# Start the Admin Server
nohup ./startWebLogic.sh > /tmp/new_admin_server.log 2>&1 &

# Monitor the startup
tail -f /tmp/new_admin_server.log

# Wait for "Server state changed to RUNNING"
# Press Ctrl+C to exit tail

# Verify the server is running
ps -ef | grep java | grep $NEW_DOMAIN_NAME
```

### 4.5 Access the Admin Console

```bash
# Get the admin server URL
echo "Admin Console: http://$(hostname):7001/console"

# Default credentials (as specified in model):
# Username: weblogic
# Password: (value from your model/variable file)
```

Open a web browser and navigate to the Admin Console URL to verify:
- Domain configuration
- Servers and clusters
- Deployed applications
- Data sources and other resources

## Step 5: Additional WDT Tools and Operations

### 5.1 Update an Existing Domain

To modify an existing domain using a model:

```bash
# Update domain configuration
$WDT_HOME/bin/updateDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $NEW_DOMAIN_HOME \
    -model_file updated_model.yaml \
    -variable_file updated_variables.properties \
    -archive_file updated_archive.zip

# Update can be done online (while domain is running):
$WDT_HOME/bin/updateDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $NEW_DOMAIN_HOME \
    -model_file updated_model.yaml \
    -admin_user weblogic \
    -admin_url t3://localhost:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD
```

### 5.2 Deploy Applications

To deploy only applications (not full domain configuration):

```bash
# Deploy applications from a model
$WDT_HOME/bin/deployApps.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $NEW_DOMAIN_HOME \
    -model_file applications_model.yaml \
    -archive_file applications_archive.zip \
    -admin_user weblogic \
    -admin_url t3://localhost:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD
```

### 5.3 Compare Models

To compare two model files:

```bash
# Compare original and new models
$WDT_HOME/bin/compareModel.sh \
    -oracle_home $ORACLE_HOME \
    -output_dir ./comparison_results \
    -variable_file base_domain_variables.properties \
    base_domain_model.yaml \
    updated_model.yaml

# Review the comparison results
cat ./comparison_results/compare_model_stdout
```

### 5.4 Model Help Tool

To get information about valid model attributes:

```bash
# Get help for the entire model
$WDT_HOME/bin/modelHelp.sh -oracle_home $ORACLE_HOME

# Get help for a specific section
$WDT_HOME/bin/modelHelp.sh -oracle_home $ORACLE_HOME topology

# Get help for a specific folder
$WDT_HOME/bin/modelHelp.sh -oracle_home $ORACLE_HOME resources:/JDBCSystemResource

# Get attributes for a specific element
$WDT_HOME/bin/modelHelp.sh -oracle_home $ORACLE_HOME \
    -attributes_only \
    resources:/JDBCSystemResource/JdbcResource/JDBCDriverParams
```

### 5.5 Archive Helper Tool

To manage archive file contents:

```bash
# List contents of an archive
$WDT_HOME/bin/archiveHelper.sh list -archive_file $ARCHIVE_FILE

# Extract a file from the archive
$WDT_HOME/bin/archiveHelper.sh extract \
    -archive_file $ARCHIVE_FILE \
    -target ./extracted_files

# Add files to an archive
$WDT_HOME/bin/archiveHelper.sh add \
    -archive_file $ARCHIVE_FILE \
    -source ./myapp.war \
    -target wlsdeploy/applications/myapp.war
```

## Step 6: Demo Scenarios

### Scenario 1: Complete Domain Migration

**Use Case**: Migrate a domain from one environment to another

```bash
# 1. Discover the source domain
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home /home/opc/wls/user_projects/domains/base_domain \
    -archive_file source_domain.zip \
    -model_file source_domain.yaml \
    -variable_file source_variables.properties \
    -discover_passwords \
    -passphrase_file ~/wdt_passphrase.txt

# 2. Edit variable file for target environment
vi source_variables.properties
# Update environment-specific values:
# - Database URLs
# - File paths
# - Port numbers
# - Server names

# 3. Create domain in target environment
$WDT_HOME/bin/createDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_parent ~/target_environment/domains \
    -model_file source_domain.yaml \
    -variable_file target_variables.properties \
    -archive_file source_domain.zip \
    -passphrase_file ~/wdt_passphrase.txt

# 4. Start and verify the target domain
cd ~/target_environment/domains/<domain_name>
./startWebLogic.sh
```

### Scenario 2: Application Deployment Automation

**Use Case**: Deploy multiple applications consistently across environments

```bash
# 1. Create a model for applications only
cat > app_deployment_model.yaml << 'EOF'
appDeployments:
    Application:
        HostInfoApp:
            SourcePath: wlsdeploy/applications/hostinfo.war
            Target: AdminServer
            StagingMode: nostage
        MyEnterpriseApp:
            SourcePath: wlsdeploy/applications/myapp.ear
            Target: mycluster
            StagingMode: stage
            PlanStagingMode: stage
EOF

# 2. Create archive with applications
$WDT_HOME/bin/archiveHelper.sh add \
    -archive_file apps.zip \
    -source /path/to/hostinfo.war \
    -target wlsdeploy/applications/hostinfo.war

$WDT_HOME/bin/archiveHelper.sh add \
    -archive_file apps.zip \
    -source /path/to/myapp.ear \
    -target wlsdeploy/applications/myapp.ear

# 3. Deploy to running domain
$WDT_HOME/bin/deployApps.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -model_file app_deployment_model.yaml \
    -archive_file apps.zip \
    -admin_user weblogic \
    -admin_url t3://localhost:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD
```

### Scenario 3: Configuration Update

**Use Case**: Update JDBC data source configuration across multiple domains

```bash
# 1. Create a model with updated configuration
cat > update_datasource_model.yaml << 'EOF'
resources:
    JDBCSystemResource:
        MyDataSource:
            JdbcResource:
                JDBCConnectionPoolParams:
                    MaxCapacity: 100
                    InitialCapacity: 10
                    TestConnectionsOnReserve: true
                    TestTableName: SQL ISVALID
                JDBCDriverParams:
                    URL: jdbc:oracle:thin:@//newdb.example.com:1521/PDBORCL
                    Properties:
                        user:
                            Value: newuser
EOF

# 2. Update the domain (online)
$WDT_HOME/bin/updateDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home $DOMAIN_HOME \
    -model_file update_datasource_model.yaml \
    -admin_user weblogic \
    -admin_url t3://localhost:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD

# Changes are applied immediately to the running domain
```

## Step 7: Best Practices and Tips

### Model Management

1. **Use Variable Files**: Externalize environment-specific values
   ```properties
   # development.properties
   jdbc.url=jdbc:oracle:thin:@//dev-db:1521/devdb
   listen.port=7001
   
   # production.properties
   jdbc.url=jdbc:oracle:thin:@//prod-db:1521/proddb
   listen.port=7001
   ```

2. **Version Control**: Store models and variable files in Git
   ```bash
   git init
   git add *.yaml *.properties
   git commit -m "Initial domain model"
   ```

3. **Encrypt Sensitive Data**: Always encrypt passwords
   ```bash
   $WDT_HOME/bin/encryptModel.sh \
       -model_file model.yaml \
       -variable_file variables.properties \
       -passphrase_file passphrase.txt
   ```

4. **Use Multiple Models**: Layer models for different purposes
   ```bash
   # Base configuration
   base_model.yaml
   
   # Environment-specific overrides
   dev_overrides.yaml
   prod_overrides.yaml
   
   # Create domain with layered models
   createDomain.sh -model_file base_model.yaml,prod_overrides.yaml
   ```

### Archive Management

1. **Minimize Archive Size**: Only include necessary files
2. **Document Archive Contents**: Maintain a README in your archive
3. **Version Archives**: Use semantic versioning (app-v1.0.0.zip)

### Domain Types

1. **Specify Domain Type**: Always use `-domain_type` for non-WLS domains
2. **Custom Typedefs**: Create custom type definitions for standardized domains
3. **Template Extensions**: Add custom templates to typedef files

### Security

1. **Protect Passphrases**: Store encryption passphrases securely
2. **Limit Model Access**: Restrict read access to model files
3. **Rotate Passwords**: Regularly update passwords in models
4. **Audit Models**: Review models before applying to production

### Performance

1. **Use Offline Mode**: Faster than online for initial discovery
2. **Skip Archive When Possible**: Use `-skip_archive` for config-only changes
3. **Parallel Operations**: Run WDT operations on multiple domains in parallel

## Step 8: Troubleshooting

### Common Issues and Solutions

#### Issue: "Domain not found" error
```bash
# Solution: Verify DOMAIN_HOME is correct
ls -la $DOMAIN_HOME/config/config.xml

# Ensure you have read permissions
id
ls -ld $DOMAIN_HOME
```

#### Issue: "JAVA_HOME not set" error
```bash
# Solution: Set JAVA_HOME explicitly
export JAVA_HOME=/usr/java/jdk1.8.0_291
export PATH=$JAVA_HOME/bin:$PATH
java -version
```

#### Issue: Archive file not created
```bash
# Solution: Check disk space
df -h ~/wdt-demo

# Check file permissions
ls -la $(dirname $ARCHIVE_FILE)

# Use absolute paths
ARCHIVE_FILE=/home/opc/wdt-demo/archive.zip
```

#### Issue: Password validation errors
```bash
# Solution: Ensure passwords meet requirements
# - Minimum 8 characters
# - At least 1 number or special character

# Or disable validation (not recommended for production)
export WLSDEPLOY_PROPERTIES="-Dwdt.config.enable.create.domain.password.validation=false"
```

#### Issue: Model validation failures
```bash
# Solution: Review validation output carefully
$WDT_HOME/bin/validateModel.sh \
    -oracle_home $ORACLE_HOME \
    -model_file $MODEL_FILE \
    -variable_file $VARIABLE_FILE

# Check the log file for details
cat $WDT_HOME/logs/validateModel.log
```

### Logs and Debugging

```bash
# WDT log directory
ls -la $WDT_HOME/logs/

# View specific tool log
cat $WDT_HOME/logs/discoverDomain.log
cat $WDT_HOME/logs/createDomain.log
cat $WDT_HOME/logs/updateDomain.log

# Enable detailed logging
export WLSDEPLOY_PROPERTIES="-Djava.util.logging.level=FINEST"

# Run with verbose output
$WDT_HOME/bin/discoverDomain.sh -oracle_home $ORACLE_HOME ... 2>&1 | tee discovery.log
```

## Step 9: Advanced Topics

### SSH-Based Discovery

For discovering remote domains via SSH:

```bash
# Set up SSH key authentication (one-time setup)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/wdt_key
ssh-copy-id -i ~/.ssh/wdt_key.pub opc@remote-host

# Discover using SSH
$WDT_HOME/bin/discoverDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_home /remote/path/to/domain \
    -archive_file domain_archive.zip \
    -model_file domain_model.yaml \
    -ssh_host remote-host \
    -ssh_user opc \
    -ssh_private_key ~/.ssh/wdt_key \
    -admin_user weblogic \
    -admin_url t3://remote-host:7001 \
    -admin_pass_env WLS_ADMIN_PASSWORD
```

### Kubernetes Integration

Prepare models for WebLogic Kubernetes Operator:

```bash
# Prepare model for Kubernetes
$WDT_HOME/bin/prepareModel.sh \
    -oracle_home $ORACLE_HOME \
    -model_file base_domain_model.yaml \
    -target wko \
    -output_dir ./kubernetes_ready

# Generate domain resource YAML
$WDT_HOME/bin/extractDomainResource.sh \
    -oracle_home $ORACLE_HOME \
    -model_file base_domain_model.yaml \
    -domain_uid base-domain \
    -output_dir ./kubernetes_yaml
```

### Custom Domain Typedefs

Create a custom domain type:

```bash
# Create custom typedef file
cat > $WDT_HOME/lib/typedefs/CUSTOM.json << 'EOF'
{
    "copyright": "Copyright (c) 2024, Oracle Corporation",
    "name": "CUSTOM",
    "description": "Custom domain type with additional templates",
    "versions": {
        "12.2.1.4": "CUSTOM_12214"
    },
    "definitions": {
        "CUSTOM_12214": {
            "baseTemplate": "@@WL_HOME@@/common/templates/wls/wls.jar",
            "extensionTemplates": [
                "@@ORACLE_HOME@@/custom/templates/custom-template.jar"
            ],
            "serverGroupsToTarget": ["JRF-MAN-SVR", "WSMPM-MAN-SVR"],
            "customExtensionTemplates": []
        }
    }
}
EOF

# Use custom domain type
$WDT_HOME/bin/createDomain.sh \
    -oracle_home $ORACLE_HOME \
    -domain_parent ~/domains \
    -domain_type CUSTOM \
    -model_file model.yaml
```

### Model Filtering

Customize discovery filters:

```bash
# Create custom filter file
cat > model_filters.json << 'EOF'
{
    "model_filters": {
        "discover": [
            {
                "name": "Skip Test Servers",
                "path": "topology:/Server",
                "filter": "Name=TestServer.*",
                "action": "exclude"
            }
        ]
    }
}
EOF

# Reference in tool.properties
echo "model.filters.file=$(pwd)/model_filters.json" >> $WDT_HOME/lib/tool.properties
```

---

## Script Documentation

This section documents the automated `wdt.sh` script that simplifies the WDT workflow described in this guide.

### Directory Structure

All WDT-related scripts are organized under the `WDT/` subdirectory:

```
docs/replatform/
├── WDT.md                    # This documentation file
├── WDT/                      # WDT scripts directory
│   ├── wdt.sh               # Main automation script
│   └── setWDTEnv.sh         # Environment configuration
└── wdt-output/               # Generated artifacts (created by script)
    ├── weblogic-deploy/     # WDT installation
    ├── base_domain_model.yaml
    ├── base_domain_archive.zip
    └── domains/
        └── wdt-sample-domain/
```

### Script Overview

The `wdt.sh` script is a comprehensive automation tool that performs the complete WDT workflow:
- Automatically downloads and installs WDT
- Discovers an existing WebLogic domain
- Validates the discovered model
- Creates a new domain with port offset to avoid conflicts
- Starts the new domain for verification
- Provides cleanup capabilities

**Location**: `docs/replatform/WDT/wdt.sh`

### Script Prerequisites

#### Environment Configuration File

The script requires a `setWDTEnv.sh` file in the same directory to define persistent environment variables:

**File**: `docs/replatform/WDT/setWDTEnv.sh`

```bash
#!/bin/bash
# WebLogic Deploy Tooling Environment Configuration

# Oracle Home - WebLogic Server installation directory
export ORACLE_HOME="/home/opc/wls"

# Java Home - JDK used by WebLogic (must be JDK 1.8 for WLS 12.2.1.4)
export JAVA_HOME="/opt/jdk"

# Update PATH to include Java and WebLogic binaries
export PATH="$JAVA_HOME/bin:$ORACLE_HOME/oracle_common/common/bin:$PATH"

# Verification
echo "Environment configured:"
echo "  ORACLE_HOME: $ORACLE_HOME"
echo "  JAVA_HOME: $JAVA_HOME"
echo "  Java version: $(java -version 2>&1 | head -1)"
```

This file is automatically sourced by `wdt.sh` on startup.

#### System Requirements

- **WebLogic Server**: 12.2.1.4 installed at `/home/opc/wls`
- **Java**: JDK 1.8 at `/opt/jdk`
- **Source Domain**: Existing domain at `/home/opc/wls/user_projects/domains/base_domain`
- **Disk Space**: Minimum 500MB for WDT artifacts and new domain
- **Network**: Internet access to download WDT from GitHub

### Script Usage

#### Basic Execution

```bash
# Navigate to the script directory
cd /path/to/hello-wls/docs/replatform/WDT

# Make the script executable (first time only)
chmod +x wdt.sh

# Run the complete WDT workflow
./wdt.sh
```

#### Command-Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Display help message and usage information |
| `-r, --reset` | Reset environment - delete created domain and all WDT artifacts |

#### Examples

```bash
# Show help and usage information
./wdt.sh --help

# Reset environment (clean up everything)
./wdt.sh --reset

# Normal execution (discover, validate, create, start)
./wdt.sh
```

### Script Configuration

#### Key Variables

The script uses the following configuration (defined in the script header):

```bash
# WDT Configuration
WDT_VERSION="4.3.8"                       # WDT version to download
WDT_WORK_DIR="$SCRIPT_DIR/../wdt-output"  # Output directory for all artifacts

# Source Domain
SOURCE_DOMAIN_HOME="/home/opc/wls/user_projects/domains/base_domain"
DOMAIN_NAME="base_domain"

# New Domain
NEW_DOMAIN_NAME="wdt-sample-domain"    # Name of the created domain
NEW_DOMAIN_PARENT="$WDT_WORK_DIR/domains"
NEW_DOMAIN_HOME="$NEW_DOMAIN_PARENT/$NEW_DOMAIN_NAME"

# Admin Credentials (for new domain)
ADMIN_USER="weblogic"
ADMIN_PASS="Welcome1"
```

#### Port Offset Strategy

The script implements a **+1000 port offset** to avoid conflicts with the source domain:

| Server | Original Port | New Port |
|--------|--------------|----------|
| AdminServer | 7001 | **8001** |
| SSL Port | 7002 | **8002** |
| Managed Server 1 | 7003 | **8003** |
| Additional Ports | 7004, 7005, etc. | **8004, 8005**, etc. |

This ensures the new domain can run simultaneously with the source domain without port conflicts.

### Script Features

#### 1. Automatic Environment Setup

- Sources `setWDTEnv.sh` for environment variables
- Validates ORACLE_HOME and JAVA_HOME
- Checks source domain existence
- Creates output directory structure

#### 2. WDT Installation

- Downloads WDT version 4.3.8 from GitHub releases
- Skips download if already present
- Extracts to `wdt-output/weblogic-deploy/`
- Validates installation completeness

#### 3. Domain Discovery

- Discovers the source domain using WDT `discoverDomain.sh`
- Creates model file: `wdt-output/base_domain_model.yaml`
- Creates archive file: `wdt-output/base_domain_archive.zip`
- Creates variable file: `wdt-output/base_domain_variables.properties`
- **Applies port offset** immediately after discovery:
  - Sets AdminServer to port 8001
  - Adds 1000 to all other discovered ports

#### 4. Model Validation

- Validates the discovered model using `validateModel.sh`
- Checks model syntax and structure
- Verifies variable substitutions
- Reports validation errors (if any)

#### 5. Domain Creation

- Creates new domain from the modified model
- Uses temporary variable file for admin credentials
- Creates domain at `wdt-output/domains/wdt-sample-domain/`
- Preserves all configurations from source domain

#### 6. Domain Startup

- Checks for port conflicts before starting
- Starts AdminServer in background mode
- Monitors startup logs for readiness
- Detects and reports startup issues
- Displays console access URL

#### 7. Reset Functionality

The `--reset` option provides complete cleanup:

```bash
./wdt.sh --reset
```

**Reset Actions:**
1. Finds all WebLogic processes for `wdt-sample-domain`
2. Force kills all domain-related processes
3. Removes the created domain directory
4. Removes the entire `wdt-output` directory
5. Provides summary of cleanup actions

**Use Cases:**
- Start fresh after testing
- Clean up failed runs
- Remove all artifacts before re-running
- Resolve port conflicts or stuck processes

### Script Workflow

#### Phase 1: Initialization

1. Load environment variables from `setWDTEnv.sh`
2. Parse command-line arguments
3. Handle reset mode (if `--reset` specified)
4. Validate prerequisites (ORACLE_HOME, source domain)
5. Create output directory structure

#### Phase 2: WDT Installation

1. Check if WDT already exists
2. Download WDT 4.3.8 if needed
3. Extract to `wdt-output/weblogic-deploy/`
4. Verify installation

#### Phase 3: Domain Discovery

1. Execute WDT `discoverDomain.sh`
2. Generate model, archive, and variable files
3. **Apply port offset transformation:**
   - Use `sed` to set AdminServer ListenPort to 8001
   - Use `awk` to add 1000 to all other ListenPort values
4. Save modified model

#### Phase 4: Model Validation

1. Execute WDT `validateModel.sh`
2. Check for errors or warnings
3. Report validation results

#### Phase 5: Domain Creation

1. Create temporary variable file with admin credentials
2. Execute WDT `createDomain.sh`
3. Create domain at `wdt-output/domains/wdt-sample-domain/`
4. Clean up temporary files

#### Phase 6: Domain Startup

1. Check for port conflicts (port 8001)
2. Start AdminServer using `startWebLogic.sh`
3. Monitor `wdt-sample-domain_admin.log`
4. Detect server ready state
5. Display access information

#### Phase 7: Summary

1. Display all artifact locations
2. Show console access URL
3. Provide admin credentials
4. Note port offset information

### Script Troubleshooting

#### Common Issues

**Issue**: Script fails with "ORACLE_HOME not set"
```bash
# Solution: Ensure setWDTEnv.sh exists and has correct paths
cat docs/replatform/setWDTEnv.sh
```

**Issue**: Port 8001 already in use
```bash
# Check what's using the port
sudo lsof -i :8001

# Use reset to clean up
./wdt.sh --reset
```

**Issue**: Domain fails to start
```bash
# Check the startup log
tail -f wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/wdt-sample-domain_admin.log

# Look for errors in domain log
tail -f wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/AdminServer.log
```

**Issue**: WDT download fails (404 error)
```bash
# Verify the download URL is accessible
wget --spider https://github.com/oracle/weblogic-deploy-tooling/releases/download/release-4.3.8/weblogic-deploy.zip

# Check GitHub releases page for available versions
# https://github.com/oracle/weblogic-deploy-tooling/releases
```

**Issue**: Application not found during discovery
```bash
# Ensure the hostinfo.war symlink exists
ls -la /home/opc/DevOps/hello-wls/target/hostinfo.war

# Create if missing
mkdir -p /home/opc/DevOps/hello-wls/target
ln -s /path/to/actual/hostinfo.war /home/opc/DevOps/hello-wls/target/hostinfo.war
```

#### Reset and Retry

If the script encounters issues:

```bash
# Clean everything
./wdt.sh --reset

# Verify source domain is running
$ORACLE_HOME/user_projects/domains/base_domain/bin/stopWebLogic.sh
$ORACLE_HOME/user_projects/domains/base_domain/bin/startWebLogic.sh

# Run script again
./wdt.sh
```

#### Log Locations

| Log Type | Location |
|----------|----------|
| Domain Admin Log | `wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/wdt-sample-domain_admin.log` |
| Server Log | `wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/AdminServer.log` |
| Access Log | `wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/access.log` |
| Discovery Output | Console output during discovery phase |
| Validation Output | Console output during validation phase |

### Script Output Structure

After successful execution, the `wdt-output/` directory contains:

```
wdt-output/
├── weblogic-deploy/              # WDT installation
│   ├── bin/                      # WDT tools
│   ├── lib/                      # WDT libraries
│   └── samples/                  # Sample models
├── models/                       # Discovered models (from logs)
├── base_domain_model.yaml        # Discovered model (modified with port offset)
├── base_domain_archive.zip       # Application binaries
├── base_domain_variables.properties  # Configuration variables
├── .wdt_passphrase              # Password encryption key
└── domains/
    └── wdt-sample-domain/        # Created domain
        ├── bin/                  # Domain scripts
        ├── config/               # Domain configuration
        ├── servers/              # Server instances
        │   └── AdminServer/
        │       └── logs/         # Server logs
        └── autodeploy/           # Auto-deploy directory
```

### Best Practices

1. **Always use reset before re-running**: Ensures clean state
   ```bash
   ./wdt.sh --reset && ./wdt.sh
   ```

2. **Verify source domain is accessible**: Script needs read access
   ```bash
   ls -la /home/opc/wls/user_projects/domains/base_domain
   ```

3. **Monitor logs during startup**: Catch issues early
   ```bash
   tail -f wdt-output/domains/wdt-sample-domain/servers/AdminServer/logs/wdt-sample-domain_admin.log
   ```

4. **Keep setWDTEnv.sh updated**: If paths change, update the environment file

5. **Document customizations**: If you modify the model, document your changes

6. **Test external access**: Configure firewall if needed
   ```bash
   sudo firewall-cmd --permanent --add-port=8001/tcp
   sudo firewall-cmd --reload
   ```

### Integration with CI/CD

The script is designed for automation and can be integrated into CI/CD pipelines:

```bash
# In your Jenkins/GitLab pipeline
- name: Reset WDT Environment
  run: ./docs/replatform/wdt.sh --reset

- name: Run WDT Workflow
  run: ./docs/replatform/wdt.sh

- name: Verify Domain
  run: |
    curl -f http://localhost:8001/console || exit 1
```

---

## Conclusion

This guide provides a comprehensive walkthrough for using WebLogic Deploy Tooling with your WebLogic Server 12.2.1.4 domain. By following these steps, you can:

✅ Discover existing WebLogic domains
✅ Create portable, version-controlled models
✅ Recreate domains consistently across environments
✅ Automate deployment and configuration management
✅ Migrate domains to different platforms (including Kubernetes)

### Key Takeaways

1. **WDT enables declarative domain management** - Define your domain as code
2. **Models are portable** - Move domains between environments easily
3. **Automation-friendly** - Integrate with CI/CD pipelines
4. **Security-aware** - Encrypt sensitive data with WDT encryption
5. **Kubernetes-ready** - Prepare domains for cloud-native deployment

### Next Steps

1. Practice the basic discovery and creation workflow
2. Experiment with different discovery options
3. Create environment-specific variable files
4. Integrate WDT into your deployment pipeline
5. Explore Kubernetes deployment options

### Resources

- **Official Documentation**: https://oracle.github.io/weblogic-deploy-tooling/
- **GitHub Repository**: https://github.com/oracle/weblogic-deploy-tooling
- **Slack Community**: #weblogic channel
- **Release Notes**: https://oracle.github.io/weblogic-deploy-tooling/release-notes/

### Support and Community

- **GitHub Issues**: Report bugs and request features
- **Oracle Support**: Contact Oracle Support for production issues
- **Community Forums**: Oracle Community Forums for discussions

---

**Demo Preparation Checklist**

Before running your demo, ensure:

- [ ] WDT is downloaded and extracted
- [ ] JAVA_HOME and ORACLE_HOME are set correctly
- [ ] Source domain is accessible and permissions are correct
- [ ] Sufficient disk space for archives and new domains
- [ ] Admin credentials are available (for online discovery)
- [ ] Passphrase file created (for password discovery)
- [ ] Target directory for new domain exists
- [ ] Network connectivity (if using online mode)

**Estimated Demo Time**: 30-45 minutes for complete workflow

Good luck with your WebLogic Deploy Tooling demonstration! 🚀

---

## Appendix: WDT Model Schema Documentation

### Overview

When working with WDT YAML model files, you may need to understand all available configuration options beyond the basics covered in this guide. WDT provides a built-in tool called **Model Help** that serves as the authoritative reference for the complete schema.

### The Model Help Tool

WDT includes `modelHelp.sh` (or `modelHelp.cmd` on Windows) in the `bin/` directory. This tool provides interactive access to the complete model schema, including:

- All available model sections and folders
- Attribute names, types, and descriptions
- Default values and valid value ranges
- WebLogic MBean documentation
- Nested folder structures

The model schema is based on the WebLogic Server WLST offline structure (version 12.2.1.3+) with simplified paths and enhanced organization.

### Using the Model Help Tool

#### Basic Usage

```bash
# Navigate to your WDT installation
cd $WDT_HOME/bin

# Show top-level model sections
./modelHelp.sh -oracle_home $ORACLE_HOME top

# Output:
# domainInfo
# topology
# resources
# appDeployments
# kubernetes
```

#### Exploring Model Sections

```bash
# Show contents of a specific section
./modelHelp.sh -oracle_home $ORACLE_HOME topology

# Show details of a specific folder
./modelHelp.sh -oracle_home $ORACLE_HOME topology:/Server

# Show nested folder details
./modelHelp.sh -oracle_home $ORACLE_HOME resources:/JDBCSystemResource/JdbcResource/JDBCDriverParams
```

#### Interactive Mode

```bash
# Launch interactive mode (no path argument)
./modelHelp.sh -oracle_home $ORACLE_HOME

# Interactive prompt allows navigation:
# > ls               # List current location contents
# > cd Server        # Navigate to Server folder
# > attributes       # Show all attributes
# > help             # Show available commands
```

#### Recursive Listing

```bash
# Show all nested folders and attributes
./modelHelp.sh -oracle_home $ORACLE_HOME -recursive topology:/Server

# Output includes:
# - All folder attributes
# - All nested folders
# - Complete object hierarchy
```

### Model Structure Overview

#### Top-Level Sections

1. **domainInfo**: Domain metadata and WebLogic version information
   - Domain name, version, admin credentials placeholder

2. **topology**: Domain structure and server configuration
   - Servers, Clusters, Machines, Templates
   - Security configuration
   - Network channels and listen addresses

3. **resources**: Shared resources and services
   - JDBC data sources
   - JMS resources
   - Work Managers
   - Foreign JNDI providers

4. **appDeployments**: Application and library deployments
   - Applications, libraries, coherence clusters
   - Deployment targets and configuration

5. **kubernetes**: Kubernetes-specific configuration (WebLogic Kubernetes Operator)
   - Scaling, monitoring, and cloud-native settings

### Common Use Cases

#### Finding Server Configuration Options

```bash
# Explore all Server attributes
./modelHelp.sh -oracle_home $ORACLE_HOME topology:/Server

# Example attributes you'll see:
# ListenPort: integer (default: 7001)
# ListenAddress: string
# Machine: reference to topology:/Machine
# Cluster: reference to topology:/Cluster
# SSL: folder (nested SSL configuration)
```

#### Exploring JDBC DataSource Options

```bash
# Show JDBC resource structure
./modelHelp.sh -oracle_home $ORACLE_HOME resources:/JDBCSystemResource

# Show connection pool options
./modelHelp.sh -oracle_home $ORACLE_HOME -recursive resources:/JDBCSystemResource/JdbcResource/JDBCConnectionPoolParams
```

#### Understanding Security Configuration

```bash
# Explore security realm options
./modelHelp.sh -oracle_home $ORACLE_HOME topology:/SecurityConfiguration/Realm
```

### Token Reference

WDT supports variable substitution using tokens in your model files. The Model Help tool documents token syntax:

| Token Type | Syntax | Description | Example |
|------------|--------|-------------|---------|
| Property | `@@PROP:key@@` | Java system property | `@@PROP:user.home@@` |
| Environment | `@@ENV:VAR@@` | Environment variable | `@@ENV:ORACLE_HOME@@` |
| File | `@@FILE:path@@` | File contents | `@@FILE:/tmp/secret.txt@@` |
| Secret | `@@SECRET:key@@` | Encrypted secret | `@@SECRET:db.password@@` |
| Built-in | `@@WL_HOME@@` | WebLogic home directory | `@@WL_HOME@@` |
| Built-in | `@@DOMAIN_HOME@@` | Domain home directory | `@@DOMAIN_HOME@@` |
| Built-in | `@@JAVA_HOME@@` | Java home directory | `@@JAVA_HOME@@` |
| Built-in | `@@ORACLE_HOME@@` | Oracle home directory | `@@ORACLE_HOME@@` |
| Built-in | `@@PWD@@` | Current working directory | `@@PWD@@` |
| Built-in | `@@TMP@@` | System temp directory | `@@TMP@@` |

### Example: Customizing Your Model

After using Model Help to discover available options, you can enhance your model. For example:

```yaml
topology:
  ServerTemplate:
    AdminServer:
      ListenPort: 8001
      ListenAddress: "0.0.0.0"  # Found using modelHelp
      ServerStart:                # Found using modelHelp
        Arguments: "-Xms512m -Xmx1024m"
        ClassPath: "@@DOMAIN_HOME@@/lib/custom.jar"
      SSL:                        # Found using modelHelp
        Enabled: true
        ListenPort: 8002
      Log:                        # Found using modelHelp
        FileName: "logs/AdminServer.log"
        RotationType: "bySize"
        FileMinSize: 5000
        NumberOfFilesLimited: true
        FileCount: 10
```

### Practical Workflow

1. **Discover your domain** to get the baseline model:
   ```bash
   cd docs/replatform/WDT
   ./wdt.sh  # Uses the automated script from this guide
   ```

2. **Review the generated model** at `../wdt-output/models/base_domain_model.yaml`

3. **Explore additional options** using Model Help:
   ```bash
   cd ../wdt-output/weblogic-deploy/bin
   ./modelHelp.sh -oracle_home $ORACLE_HOME topology:/Server
   ```

4. **Enhance your model** with discovered options:
   - Add JVM arguments
   - Configure SSL settings
   - Set up custom logging
   - Define additional data sources

5. **Validate the updated model**:
   ```bash
   cd ../wdt-output/weblogic-deploy/bin
   ./validateModel.sh -oracle_home $ORACLE_HOME \
       -model_file ../../models/base_domain_model.yaml
   ```

6. **Create domain** with the enhanced model using the script

### Tips for Using Model Help

1. **Start broad, then narrow**: Begin with `top`, then drill down to specific sections
2. **Use recursive mode** to see the complete structure at once
3. **Reference MBean docs**: Model Help output includes links to WebLogic MBean documentation
4. **Check required vs optional**: The tool indicates which attributes are required
5. **Validate early**: Always validate your model after making manual changes

### Online Resources

- **Official Model Documentation**: https://oracle.github.io/weblogic-deploy-tooling/concepts/model/
- **Model Help Tool Guide**: https://oracle.github.io/weblogic-deploy-tooling/userguide/tools/model_help/
- **Model Token Reference**: https://oracle.github.io/weblogic-deploy-tooling/concepts/model/#model-tokens
- **WLST Offline Reference**: Oracle WebLogic Server documentation (MBean reference)

### Summary

The Model Help tool is your go-to resource for:
- ✅ Discovering all available model options
- ✅ Understanding attribute types and valid values
- ✅ Exploring nested folder structures
- ✅ Finding WebLogic MBean documentation
- ✅ Validating model syntax and structure

Use it whenever you need to customize your WDT models beyond the basic examples in this guide.
