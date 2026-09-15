## General principle

All traffic is allowed from each pod to each pod, if no network policies are applied.

## Important caveats

### Network policy enforcement is independent for each pod

#### Ingress 

<details>
<summary>Answer</summary>

For a given pod:

- If no Ingress NetworkPolicy selects the pod → all ingress is allowed.

- If at least one Ingress NetworkPolicy selects the pod → ingress becomes restricted to what those policies collectively allow.


#### Egress

- If no Egress NetworkPolicy selects the pod → all egress is allowed.
- If at least one Egress NetworkPolicy selects the pod → egress becomes restricted to what those policies collectively allow.


### multiple policies are additive, not overriding.

So if you have:

DB pod
 ├── policy 1: allow API
 └── policy 2: allow monitoring

the DB accepts traffic from API OR monitoring.

It does not mean policy 2 replaces policy 1.




### Support by CNI
Kubernetes NetworkPolicy is only the API abstraction. The actual enforcement is being done by your CNI. So if CNI does not support NetworkPolicies, we can create them on the cluster but they won't have any affect


### Namespaces

A podSelector by itself selects pods only in the same namespace as the NetworkPolicy.
In other words, a bare **podSelector** in a from/to clause doesn't have its own namespace field. Its namespace is implicitly the namespace of the NetworkPolicy.


For example, suppose the policy is:


```
metadata:
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: database


  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api


```

The **from.podSelector** means: Allow traffic from pods labelled app: api in the backend namespace. It does not mean API pods with that label in every namespace.

To allow a pod from another namespace, use namespaceSelector:

```
from:
  - namespaceSelector:
      matchLabels:
        name: frontend
    podSelector:
      matchLabels:
        app: api
```
This means: Allow pods labelled **app: api** in namespaces labelled **name: frontend**. The two selectors together are effectively AND:

