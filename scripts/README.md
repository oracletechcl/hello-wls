# Lab Scripts - Centralized Script Directory

This directory contains centralized wrapper scripts for all lab exercises. These scripts provide a single entry point for common operations while maintaining the actual implementation in their respective module directories.

## Purpose

- **Centralized Access**: All lab scripts accessible from one location
- **Simplified Navigation**: Students don't need to navigate deep directory structures
- **Consistent Interface**: Uniform script naming and behavior
- **Backend Preservation**: Original scripts remain in their logical locations
- **Easy Maintenance**: Updates to backend scripts automatically reflected

## Available Scripts

### WebLogic Plain Cluster Management (`wls-plain-cluster/`)

Scripts for managing the standard WebLogic cluster (non-containerized deployment).

| Script | Description | Backend Location |
|--------|-------------|------------------|
| `wls-plain-cluster/start-cluster.sh` | Start WebLogic cluster in background (Admin + Managed Servers) | `standard-wls-deployment/server-startup-scripts/start-cluster.sh` |
| `wls-plain-cluster/stop-cluster.sh` | Stop WebLogic cluster and startup script | `standard-wls-deployment/server-startup-scripts/stop-cluster.sh` |

## Usage

### WebLogic Plain Cluster

```bash
# Navigate to the wls-plain-cluster directory
cd /path/to/hello-wls/scripts/wls-plain-cluster

# Start WebLogic cluster (runs in background)
./start-cluster.sh

# The script will start Admin Server, MS1, and MS2, then return control
# Servers continue running in the background
# Monitor logs with: tail -f ../../standard-wls-deployment/server-startup-scripts/logs/*.log

# Stop WebLogic cluster (kills startup script and all servers)
./stop-cluster.sh
```

### Background Execution

The `start-cluster.sh` script now runs in **background mode**:
- Script returns immediately after starting servers
- Creates a PID file at `standard-wls-deployment/server-startup-scripts/.cluster-startup.pid`
- Monitors server processes in the background
- Logs warnings to `cluster-monitor.log` if any server stops unexpectedly

The `stop-cluster.sh` script provides **complete cleanup**:
- Finds and kills the startup script using the PID file
- Gracefully stops all WebLogic processes (SIGTERM)
- Force kills any remaining processes after 60 seconds (SIGKILL)
- Removes the PID file
- Ensures clean environment for next startup

### Script Behavior

- **Wrapper Pattern**: These scripts are lightweight wrappers that delegate to backend implementations
- **Argument Passing**: All command-line arguments are forwarded to backend scripts
- **Error Handling**: Scripts validate backend script existence before execution
- **Auto-Permissions**: Scripts automatically make backend scripts executable if needed
- **Path Independence**: Scripts use dynamic path resolution to find backend scripts

## Architecture

```
scripts/                                    # Centralized lab scripts (THIS DIRECTORY)
├── README.md                              # This file
└── wls-plain-cluster/                     # WebLogic Plain Cluster scripts
    ├── start-cluster.sh                   # Wrapper → backend start script
    └── stop-cluster.sh                    # Wrapper → backend stop script

standard-wls-deployment/
└── server-startup-scripts/                # Backend implementation
    ├── start-cluster.sh                   # Actual cluster startup logic
    └── stop-cluster.sh                    # Actual cluster shutdown logic
```

## Adding New Scripts

To add a new centralized lab script:

1. **Create the wrapper script** in this directory:
   ```bash
   #!/bin/bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
   BACKEND_SCRIPT="$WORKSPACE_ROOT/path/to/backend/script.sh"
   
   # Validation and error handling
   [ ! -f "$BACKEND_SCRIPT" ] && echo "ERROR: Backend not found" && exit 1
   [ ! -x "$BACKEND_SCRIPT" ] && chmod +x "$BACKEND_SCRIPT"
   
   # Call backend with all arguments
   exec "$BACKEND_SCRIPT" "$@"
   ```

2. **Make it executable**:
   ```bash
   chmod +x scripts/new-script.sh
   ```

3. **Update this README** with script information

4. **Test the integration**:
   ```bash
   ./scripts/new-script.sh --help
   ```

## Benefits

### For Students
- **Single Location**: All lab commands in one place
- **Simplified Workflow**: No need to remember complex paths
- **Consistent Experience**: All scripts follow the same pattern

### For Instructors
- **Easy Updates**: Modify backend scripts without changing lab instructions
- **Better Organization**: Clear separation between interface and implementation
- **Flexible Structure**: Can reorganize backend without breaking labs

### For Developers
- **Maintainability**: Backend scripts stay in their logical modules
- **Modularity**: Each module owns its implementation
- **Scalability**: Easy to add new lab scripts as needed

## Best Practices

1. **Keep Wrappers Simple**: Wrappers should only handle routing, not logic
2. **Maintain Backend Scripts**: All functionality belongs in backend scripts
3. **Document Changes**: Update this README when adding new scripts
4. **Test Integration**: Always test wrapper → backend communication
5. **Preserve Arguments**: Forward all arguments to backend scripts

## Troubleshooting

### Script Not Found Error
```bash
ERROR: Backend script not found at: /path/to/backend/script.sh
```
**Solution**: Verify the backend script exists at the expected location

### Permission Denied
```bash
bash: ./script.sh: Permission denied
```
**Solution**: Make the script executable
```bash
chmod +x scripts/script.sh
```

### Backend Script Fails
Check the backend script directly for detailed error messages:
```bash
# Run backend script directly for debugging
/path/to/backend/script.sh --verbose
```

## Future Enhancements

Planned additions to this directory:

- WDT workflow scripts (discover, create, validate domains)
- Modernization framework scripts (Spring Boot, Helidon, Micronaut builds)
- Kubernetes deployment scripts
- Database connection test scripts
- Health check and monitoring scripts

## Related Documentation

- **WebLogic Setup**: `../docs/APACHE_WEBLOGIC_SETUP.md`
- **WDT Documentation**: `../docs/replatform/WDT.md`
- **Kubernetes Deployment**: `../docs/KUBERNETES_DEPLOYMENT.md`
- **Migration Summary**: `../docs/MIGRATION_SUMMARY.md`

---

**Maintained by**: WebLogic Workshop Team  
**Last Updated**: November 27, 2025
