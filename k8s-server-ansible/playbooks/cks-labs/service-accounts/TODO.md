app with API requests to K8s doesnt work because: 
1. on SA we configure automount: false
2. SA doesn't exist
3. RBAC for SA doesn't allow
4. we added own projected volume with audience: vault instead of kubernetes
5. added own projected volume with expirationSeconds too short
6. added own projected volume but forgot serviceAccountName so it is bound to default SA
7. mounted at one location - app expects somewhere else