## NetworkPolicy and CiliumNetworkPolicy
Cilium can enforce Kubernetes NetworkPolicies.

But it also has its own:

```
kind: CiliumNetworkPolicy
```

which provides additional capabilities.


## Allow frontend Pods to access backend Pods on TCP/80, but deny everything else

<details>
<summary>Answer</summary>


1. Deploy some pods

```
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  namespace: demo
  labels:
    app: frontend
spec:
  containers:
  - name: frontend
    image: busybox
    command: ["sh", "-c", "sleep 3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: backend
  namespace: demo
  labels:
    app: backend
spec:
  containers:
  - name: backend
    image: nginx

```


2. CiliumNetworkPolicy

This policy applies to backend Pods. Backend Pods may receive traffic from frontend Pods. The traffic is allowed only on port 80

Once an endpoint is selected by a CiliumNetworkPolicy containing ingress rules, ingress becomes restricted to what is explicitly allowed.

So after applying the policy, backend effectively has:

frontend → backend:80       ✅
frontend → backend:443      ❌
other pod → backend:80      ❌
other pod → backend:any     ❌


```
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: frontend-to-backend
  namespace: demo
spec:
  endpointSelector:
    matchLabels:
      app: backend

  ingress:
  - fromEndpoints:
    - matchLabels:
        app: frontend

    toPorts:
    - ports:
      - port: "80"
        protocol: TCP

```


</details>


## Allow DNS
<details>
<summary>Answer</summary>

Suppose you create a restrictive egress policy:


```
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: backend-egress
  namespace: demo
spec:
  endpointSelector:
    matchLabels:
      app: backend

  egress:
  - toEndpoints:
    - matchLabels:
        app: database

    toPorts:
    - ports:
      - port: "5432"
        protocol: TCP

```

Now backend can only initiate:

backend ──TCP/5432──► database

But there's a common problem: backend need DNS look-up. If you put an endpoint into egress isolation, DNS may need to be explicitly allowed.

```
egress:
- toEndpoints:
  - matchLabels:
      k8s-app: kube-dns

  toPorts:
  - ports:
    - port: "53"
      protocol: UDP
    - port: "53"
      protocol: TCP
```

</details>

## CiliumNetworkPolicy can filter at Layer 7, not just IP/port.

<details>
<summary>Answer</summary>

For HTTP, for example:

```
toPorts:
- ports:
  - port: "80"
    protocol: TCP
  rules:
    http:
    - method: GET
      path: "/public"

```

Now you're saying something much more specific:

frontend ── GET /public ──► backend:80    ✅

frontend ── POST /public ─► backend:80    ❌

frontend ── GET /admin ───► backend:80    ❌

That's something the standard Kubernetes NetworkPolicy API cannot express.


</details>