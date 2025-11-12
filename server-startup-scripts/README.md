# WebLogic Server Startup Scripts

This directory contains scripts to easily start and stop the WebLogic cluster.

## Scripts

### start-cluster.sh
Starts the entire WebLogic cluster in the correct order:
1. **Admin Server** - Started first and waits until it's ready
2. **Managed Server 1 (ms1)** - Started after Admin Server is available
3. **Managed Server 2 (ms2)** - Started after ms1

All servers will continue running until you press **Ctrl+C** or kill the script.

**Features:**
- Automatic port checking to ensure Admin Server is ready
- All server output is logged to separate files in the `logs/` directory
- Process monitoring to detect if any server crashes
- Graceful shutdown of all servers when script is terminated
- Color-coded output for easy reading

**Usage:**
```bash
cd /home/opc/DevOps/hello-wls/server-startup-scripts
./start-cluster.sh
```

**Log Files:**
- `logs/admin-server.log` - Admin Server output
- `logs/ms1.log` - Managed Server 1 output
- `logs/ms2.log` - Managed Server 2 output

**To Stop:**
Press `Ctrl+C` in the terminal where the script is running. This will gracefully shut down all servers.

### stop-cluster.sh
Stops all running WebLogic processes (Admin Server and Managed Servers).

**Features:**
- Finds all running WebLogic server processes
- Attempts graceful shutdown first (SIGTERM)
- Waits up to 60 seconds for processes to stop
- Force kills processes that don't stop gracefully
- Displays process information before stopping

**Usage:**
```bash
cd /home/opc/DevOps/hello-wls/server-startup-scripts
./stop-cluster.sh
```

## Configuration

Both scripts use the following default configuration:

- **Domain Home:** `/home/opc/wls/user_projects/domains/base_domain`
- **Admin Server URL:** `t3://localhost:7001`
- **Admin Server Port:** `7001`

If your WebLogic installation is in a different location, edit the scripts and update the configuration variables at the top:

```bash
DOMAIN_HOME="/home/opc/wls/user_projects/domains/base_domain"
ADMIN_SERVER_URL="t3://localhost:7001"
ADMIN_PORT=7001
```

## Typical Workflow

### Starting the Cluster
```bash
# Start all servers
./start-cluster.sh

# Wait for all servers to be RUNNING
# Monitor the output or check the log files
# Press Ctrl+C when you want to stop all servers
```

### Stopping the Cluster
If you need to stop servers outside of the start-cluster.sh script:
```bash
./stop-cluster.sh
```

### Checking Server Status
While servers are running, you can check their status:
```bash
# View Admin Server log
tail -f logs/admin-server.log

# View MS1 log
tail -f logs/ms1.log

# View MS2 log
tail -f logs/ms2.log

# Check running processes
ps aux | grep weblogic
```

## Troubleshooting

### Port Already in Use
If you see errors about ports already in use, stop any existing WebLogic processes:
```bash
./stop-cluster.sh
```

### Admin Server Not Starting
Check the admin-server.log file for errors:
```bash
cat logs/admin-server.log
```

### Managed Servers Can't Connect
Ensure the Admin Server is fully started and listening on port 7001:
```bash
netstat -tuln | grep 7001
# or
ss -tuln | grep 7001
```

### Cleanup Stuck Processes
If processes are stuck and won't stop:
```bash
# Find WebLogic processes
ps aux | grep weblogic

# Force kill specific PID
kill -9 <PID>
```

## Notes

- The start-cluster.sh script keeps running until you stop it (Ctrl+C)
- Server output goes to log files, not the console
- The script monitors processes and will alert if any server crashes
- Use the Admin Console (http://localhost:7001/console) to verify server status
- Default admin credentials are typically: weblogic/welcome1 (check your setup)
