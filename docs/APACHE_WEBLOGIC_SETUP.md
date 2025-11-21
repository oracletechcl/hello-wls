# Apache WebLogic Proxy Plugin Configuration

## Overview
This document summarizes the configuration of Apache HTTP Server with the WebLogic proxy plugin to enable external access to WebLogic applications running in the `base_domain` cluster.

---

## Environment Details

- **Apache Version**: 2.4.62 (Oracle Linux Server)
- **WebLogic Domain**: `/home/opc/wls/user_projects/domains/base_domain`
- **WebLogic Cluster Members**:
  - ms1: `10.0.0.226:7004`
  - ms2: `10.0.0.226:7005`
- **Application**: `hostinfo.war`
- **Server IPs**:
  - Private IP: `10.0.0.226`
  - Public IP: `161.153.199.58`

---

## Configuration Steps

### 1. Install Required Oracle Libraries

The WebLogic Apache plugin (`mod_wl_24.so`) requires Oracle Notification Service (ONS) and DMS libraries that are not included in standard installations.

#### Oracle Instant Client Installation
```bash
# Install Oracle Instant Client repository
sudo yum install -y oracle-instantclient-release-el9

# Install Oracle Instant Client 19.29
sudo yum install -y oracle-instantclient19.29-basic
```

#### Manual Library Installation
Since the Instant Client didn't include ONS libraries, they were manually installed:

```bash
# Create directory for WebLogic libraries
sudo mkdir -p /usr/lib64/weblogic

# Copy required libraries from download
sudo cp /home/opc/DevOps/libonsssl.so /usr/lib64/weblogic/
sudo cp /home/opc/DevOps/libonssys.so /usr/lib64/weblogic/
sudo cp /home/opc/DevOps/libdms2.so /usr/lib64/weblogic/

# Configure system to find the libraries
sudo sh -c 'echo "/usr/lib64/weblogic" > /etc/ld.so.conf.d/weblogic.conf'
sudo ldconfig
```

#### Verify Libraries
```bash
ldd /etc/httpd/modules/mod_wl_24.so | grep -E "libons|libdms"
```

**Expected Output**:
```
libonssys.so => /usr/lib64/weblogic/libonssys.so
libonsssl.so => /usr/lib64/weblogic/libonsssl.so
libdms2.so => /usr/lib64/weblogic/libdms2.so
```

---

### 2. Configure WebLogic Proxy Plugin

Created `/etc/httpd/conf.d/weblogic.conf` with the following configuration:

```apache
# Load the WebLogic proxy module
LoadModule weblogic_module modules/mod_wl_24.so

# WebLogic cluster configuration
<IfModule mod_weblogic.c>
    # Define WebLogic cluster members
    WebLogicCluster 10.0.0.226:7004,10.0.0.226:7005
 
    # Enable dynamic server list (optional)
    DynamicServerList ON
    
    # Connection parameters
    ConnectTimeoutSecs 10
    ConnectRetrySecs 2
    WLSocketTimeoutSecs 30
    Idempotent ON
    FileCaching ON
    KeepAliveEnabled ON
    KeepAliveSecs 20
    
    # Debug level (0=none, 1=errors, 2=info, 3=debug)
    Debug OFF
    WLLogFile /var/log/httpd/weblogic.log
    DebugConfigInfo ON
    
    # Proxy specific application - original context
    <Location /hostinfo>
        SetHandler weblogic-handler
        WebLogicCluster 10.0.0.226:7004,10.0.0.226:7005
        WLCookieName JSESSIONID
        WLProxySSL OFF
        WLProxySSLPassThrough OFF
    </Location>
    
    # Proxy hostinfo application through /demoapp path
    <Location /demoapp>
        SetHandler weblogic-handler
        WebLogicHost 10.0.0.226
        WebLogicPort 7004
        PathTrim /demoapp
        PathPrepend /hostinfo
        WLCookieName JSESSIONID
        WLProxySSL OFF
        WLProxySSLPassThrough OFF
    </Location>
</IfModule>
```

**Key Configuration Details**:
- **Original Path**: `/hostinfo` - Direct proxy to the hostinfo application
- **Alternative Path**: `/demoapp` - Rewrites to `/hostinfo` on the backend
  - `PathTrim /demoapp` - Removes `/demoapp` from incoming requests
  - `PathPrepend /hostinfo` - Adds `/hostinfo` before forwarding to WebLogic

---

### 3. Configure Firewall

Enable HTTP traffic through the firewall:

```bash
# Add HTTP service to firewall
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-services
```

**Expected Output**: `dhcpv6-client http ssh`

---

### 4. Configure SELinux

Apache was blocked by SELinux from making network connections to WebLogic backend servers.

```bash
# Check SELinux status
getenforce
# Output: Enforcing

# Allow Apache to make network connections
sudo setsebool -P httpd_can_network_connect 1
```

**Error Before Fix**:
```
apr_socket_connect call failed with error=13, host=10.0.0.226, port=7004
Permission denied
```

---

### 5. Test and Validate

```bash
# Test Apache configuration
sudo apachectl configtest

# Restart Apache
sudo systemctl restart httpd

# Check Apache status
sudo systemctl status httpd

# Test direct WebLogic access
curl -I http://10.0.0.226:7004/hostinfo/

# Test via Apache (localhost)
curl -I http://localhost/hostinfo
curl -I http://localhost/demoapp/

# Test via Apache (public IP)
curl -I http://161.153.199.58/hostinfo
curl -I http://161.153.199.58/demoapp/
```

---

## Access URLs

After configuration, the application is accessible via:

- **Direct WebLogic Access**:
  - `http://10.0.0.226:7004/hostinfo/`
  - `http://10.0.0.226:7005/hostinfo/`

- **Via Apache (Private IP)**:
  - `http://10.0.0.226/hostinfo`
  - `http://10.0.0.226/demoapp`

- **Via Apache (Public IP)**:
  - `http://161.153.199.58/hostinfo`
  - `http://161.153.199.58/demoapp`

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Library Loading Error
**Error**: `libonssys.so: cannot open shared object file`

**Solution**: Ensure libraries are in `/usr/lib64/weblogic/` and ldconfig is updated.

#### 2. 503 Service Unavailable
**Possible Causes**:
- WebLogic servers not running
- SELinux blocking connections
- Firewall blocking traffic
- Wrong host/port configuration

**Check Logs**:
```bash
sudo tail -f /var/log/httpd/error_log
```

#### 3. Connection Timeout
**Error**: `No backend server available for connection: timed out after 10 seconds`

**Check**:
- WebLogic servers are running: `ss -tlnp | grep -E ":7004|:7005"`
- SELinux permissions: `getsebool httpd_can_network_connect`
- Network connectivity: `curl http://10.0.0.226:7004/hostinfo/`

---

## Maintenance Commands

### Restart Services
```bash
# Restart Apache
sudo systemctl restart httpd

# Reload Apache configuration (without full restart)
sudo systemctl reload httpd
```

### View Logs
```bash
# Apache error log
sudo tail -f /var/log/httpd/error_log

# Apache access log
sudo tail -f /var/log/httpd/access_log

# Filter WebLogic plugin messages
sudo tail -f /var/log/httpd/error_log | grep weblogic
```

### Check Configuration
```bash
# Test configuration syntax
sudo apachectl configtest

# View current configuration
cat /etc/httpd/conf.d/weblogic.conf
```

---

## Backup Files

Configuration backup created at:
- `/etc/httpd/conf.d/weblogic.conf.backup`

---

## Notes

1. The `Debug` and `WLLogFile` directives in the WebLogic plugin configuration are ignored by Apache 2.4. Apache uses its native logging configuration instead.

2. The WebLogic proxy plugin supports both cluster-aware and single-server configurations:
   - `WebLogicCluster` - For clustered deployments with failover
   - `WebLogicHost/WebLogicPort` - For single server or when path manipulation is needed

3. OCI Security List must also allow inbound traffic on port 80 for external access to work properly.

---

**Document Created**: November 21, 2025  
**Last Updated**: November 21, 2025
