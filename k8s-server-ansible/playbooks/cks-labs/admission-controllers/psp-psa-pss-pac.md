## PSP	PodSecurityPolicy	

Old Kubernetes admission mechanism; removed in 1.25

There was admission controller and you could create PodSecurityPolicy objects, for ex., to control:

- privileged containers
- Linux capabilities
- host namespaces
- host networking
- volumes
- runAsUser
- privilege escalation

## PSS	Pod Security Standards	

Kubernetes' security rules/profiles. Does not enforce anything by itself

Defines standardized security levels:

- Privileged = essentially unrestricted
    
- Baseline = prevents known privilege escalations
    
- Restricted = strongly hardened Pods

So PSS is basically: "What does a secure Pod look like?"

## PSA	Pod Security Admission enforces PSS

Kubernetes **built-in admission controller** that enforces PSS

PSA supports:

enforce → reject violating Pods
audit   → allow but record violation
warn    → allow but warn the user

Used as labels on namespaces

```
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## PAC	Policy as Code	

General approach: define security/compliance policies as machine-readable code so that software can automatically test/enforce them. It isn't a specific Kubernetes security mechanism.

For example, you could have a policy:

"Containers must not run privileged."

and express that using a policy engine such as OPA/Gatekeeper or Kyverno.

PAC can cover much more than Pod security, for example:

- Pods must have resource limits
- Images must come from an approved registry
- Deployments must have specific labels
- Services must not be LoadBalancer
- Ingress must use approved TLS settings
- Security/compliance requirements