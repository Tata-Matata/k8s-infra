1. explore kubectl api-resources and how it helps with troubleshooting

2. if you need for ex. to add permissions to role, we need to know apiGroups

3. CRD installed? kubectl get applications returns the server doesn't have a resource type "applications".Is ArgoCD installed? kubectl api-resources | grep application
4. Suppose Prometheus Operator should be installed. kubectl api-resources | grep monitoring. Expected prometheuses.monitoring.coreos.com, servicemonitors.monitoring.coreos.com,podmonitors.monitoring.coreos.com