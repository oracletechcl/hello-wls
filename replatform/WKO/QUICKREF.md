# WKO Quick Reference

## One-Line Commands

```bash
# Model-in-Image (recommended)
./wko.sh --mii

# Domain-in-Image  
./wko.sh --dii

# Interactive mode
./wko.sh --mii --interactive

# Clean and redeploy
./wko.sh --mii --clean

# Delete everything
./wko.sh --delete
```

## Access URLs

```bash
# Get node IP first
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Admin Console
echo "http://$NODE_IP:30305/console"

# Application
echo "http://$NODE_IP:30305/hostinfo/"
```

**Credentials:** weblogic / welcome1

## Verification

```bash
# Check everything
kubectl get all -n wls-domain-ns

# Domain status
kubectl get domain base-domain -n wls-domain-ns

# Pods
kubectl get pods -n wls-domain-ns

# Logs
kubectl logs -f base-domain-admin-server -n wls-domain-ns
```

## Scaling

```bash
# Scale to 3
kubectl patch cluster base-domain-cluster-1 -n wls-domain-ns \
  --type merge -p '{"spec":{"replicas":3}}'

# Scale to 1
kubectl patch cluster base-domain-cluster-1 -n wls-domain-ns \
  --type merge -p '{"spec":{"replicas":1}}'
```

## Troubleshooting

```bash
# Domain details
kubectl describe domain base-domain -n wls-domain-ns

# Events
kubectl get events -n wls-domain-ns --sort-by='.lastTimestamp'

# Operator logs
kubectl logs -n weblogic-operator-ns -l app=weblogic-operator

# Introspector (MII only)
kubectl logs jobs/base-domain-introspector -n wls-domain-ns
```

## Cleanup

```bash
# Delete domain only
kubectl delete domain base-domain -n wls-domain-ns

# Delete everything
./wko.sh --delete
```

## Port Forward (Alternative Access)

```bash
# Admin Console
kubectl port-forward -n wls-domain-ns base-domain-admin-server 7001:7001

# Then access at: http://localhost:7001/console
```

## Resources

- Full guide: [WKO.md](../WKO.md)
- README: [README.md](README.md)
- Official docs: https://oracle.github.io/weblogic-kubernetes-operator/
