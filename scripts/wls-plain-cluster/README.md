# WebLogic Plain Cluster Management Scripts

This directory contains centralized scripts for managing the standard (non-containerized) WebLogic Server cluster deployment.

## Overview

These scripts provide a simplified interface to start and stop the WebLogic cluster consisting of:
- **AdminServer**: WebLogic Administration Server (port 7001)
- **MS1**: Managed Server 1 (port 7003)
- **MS2**: Managed Server 2 (port 7004)

## Scripts

### start-cluster.sh

Starts the WebLogic cluster in **background mode**.

**Features:**
- Starts AdminServer first, waits for it to be ready
- Starts MS1 and MS2 in parallel after AdminServer is ready
- Runs in background and returns control immediately
- Creates PID file for process management
- Monitors server health in the background
- Logs all output to separate log files

**Usage:**
```bash
./start-cluster.sh
```

**Output Location:**
- Logs: `../../standard-wls-deployment/server-startup-scripts/logs/`
- PID file: `../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid`

**Process:**
1. Checks if cluster is already running (via PID file)
2. Starts AdminServer
3. Waits for AdminServer port 7001 to be listening
4. Waits additional 20 seconds for full initialization
5. Starts MS1 and MS2 in parallel
6. Returns control to user
7. Continues monitoring processes in background

### stop-cluster.sh

Stops the WebLogic cluster and the startup script.

**Features:**
- Kills the startup script process (via PID file)
- Gracefully stops all WebLogic server processes
- Force kills any remaining processes after 60 seconds
- Removes PID file
- Complete cleanup for fresh start

**Usage:**
```bash
./stop-cluster.sh
```

**Process:**
1. Finds startup script PID from file
2. Kills startup script and child processes
3. Finds all WebLogic server processes
4. Sends SIGTERM for graceful shutdown
5. Waits up to 60 seconds
6. Force kills (SIGKILL) any remaining processes
7. Removes PID file

## Common Workflows

### Start and Monitor Cluster

```bash
# Start the cluster
./start-cluster.sh

# Monitor startup logs
tail -f ../../standard-wls-deployment/server-startup-scripts/logs/*.log

# Check if servers are running
ps aux | grep -E 'weblogic\.Name=(AdminServer|ms1|ms2)' | grep -v grep
```

### Stop Cluster

```bash
# Stop all servers and cleanup
./stop-cluster.sh
```

### Restart Cluster

```bash
# Stop and start in one command
./stop-cluster.sh && sleep 5 && ./start-cluster.sh
```

### Check Cluster Status

```bash
# Check if startup script is running
cat ../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid 2>/dev/null \
  && echo "Startup script PID: $(cat ../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid)"

# Check WebLogic processes
ps aux | grep -E 'weblogic\.Name=(AdminServer|ms1|ms2)' | grep -v grep

# Check monitor log
tail ../../standard-wls-deployment/server-startup-scripts/logs/cluster-monitor.log
```

## Background Execution Details

### PID File Management

The startup script creates a PID file to track its process:
- **Location**: `../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid`
- **Contains**: The PID of the startup script itself
- **Used by**: stop-cluster.sh to kill the startup script
- **Removed**: Automatically on shutdown or cleanup

### Process Monitoring

The startup script runs a background monitor that:
- Checks server processes every 10 seconds
- Logs warnings if any server stops unexpectedly
- Continues running until killed by stop-cluster.sh
- Logs to: `../../standard-wls-deployment/server-startup-scripts/logs/cluster-monitor.log`

### Log Files

All server output is logged to separate files:

| Server | Log File |
|--------|----------|
| AdminServer | `logs/admin-server.log` |
| MS1 | `logs/ms1.log` |
| MS2 | `logs/ms2.log` |
| Monitor | `logs/cluster-monitor.log` |

## Troubleshooting

### Cluster Won't Start

**Error**: "Cluster startup script is already running"

```bash
# Check if really running
ps -p $(cat ../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid) 2>/dev/null

# If not running, remove stale PID file
rm ../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid

# Try starting again
./start-cluster.sh
```

### Port Already in Use

**Error**: Port 7001 (or other ports) already in use

```bash
# Check what's using the port
sudo lsof -i :7001

# Stop any existing WebLogic processes
./stop-cluster.sh

# Or manually kill specific PIDs
kill -9 <PID>
```

### Servers Won't Stop

```bash
# Stop script should handle this, but if needed:
# Force kill all WebLogic processes
ps aux | grep weblogic.Server | grep -v grep | awk '{print $2}' | xargs kill -9

# Remove PID file
rm ../../standard-wls-deployment/server-startup-scripts/.cluster-startup.pid
```

### Check Server Logs

```bash
# View all logs in real-time
tail -f ../../standard-wls-deployment/server-startup-scripts/logs/*.log

# Check specific server log
tail -100 ../../standard-wls-deployment/server-startup-scripts/logs/admin-server.log

# Search for errors
grep -i error ../../standard-wls-deployment/server-startup-scripts/logs/*.log
```

## Backend Implementation

These are wrapper scripts that delegate to the actual implementation:

**Backend Location**: `../../standard-wls-deployment/server-startup-scripts/`

The wrapper pattern provides:
- Centralized access point for lab exercises
- Simplified navigation (don't need to remember deep paths)
- Flexibility to reorganize backend without breaking labs
- Consistent interface across different deployment types

## Integration with Other Labs

This cluster can be used for:
- Testing standard WebLogic deployments
- Comparing with modernized deployments (Spring Boot, Helidon, Micronaut)
- WDT domain discovery and modeling
- Kubernetes migration exercises
- Performance benchmarking

## Domain Details

**Domain Configuration:**
- Domain Name: `base_domain`
- Domain Home: `/home/opc/wls/user_projects/domains/base_domain`
- WebLogic Version: 12.2.1.4.0
- Java Version: JDK 1.8

**Server Configuration:**
- AdminServer: localhost:7001
- MS1: localhost:7003 (clustered)
- MS2: localhost:7004 (clustered)
- Admin Username: `weblogic`
- Admin Password: (configured during domain creation)

**Deployed Application:**
- Application: `hostinfo`
- Type: Web Application (WAR)
- URL: `http://localhost:7001/hostinfo/`

## Related Documentation

- **Main Scripts README**: `../README.md`
- **WebLogic Setup Guide**: `../../docs/APACHE_WEBLOGIC_SETUP.md`
- **Deployment Guide**: `../../standard-wls-deployment/README.md`
- **Server Scripts**: `../../standard-wls-deployment/server-startup-scripts/README.md`

---

**Maintained by**: WebLogic Workshop Team  
**Last Updated**: November 27, 2025
