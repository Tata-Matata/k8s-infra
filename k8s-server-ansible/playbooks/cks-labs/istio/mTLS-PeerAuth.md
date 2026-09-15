### Strict mTLS

<details>
<summary>Answer</summary>

All workloads in production must use mTLS when communicating with each other.

  
```
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT
```

</details>

### Global (vs namespaced) PeerAuthentication
<details>
<summary>Answer</summary>

 if **namespace: istio-system** + no selector and assuming istio-system is configured as Istio's root namespace (the common default) - this policy affects all namespaces.

```
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

</details>

### Enable Istio in specific namespace

<details>
<summary>Answer</summary>

If not enabled, then new Pods there normally won't get an Envoy sidecar through automatic sidecar injection. So this namespace will not participate in sidecar-based mesh.

```
kubectl label ns test istio-injection=enabled
kubectl get ns --show-labels
```

</details>

### How else can Istio inject the sidecar?

<details>
<summary>Answer</summary>

1. namespace
2. Pod-level automatic injection

```
metadata:
  labels:
    sidecar.istio.io/inject: "true"
```

3. Manual injection with istioctl

```
istioctl kube-inject \
  -f deployment.yaml \
  | kubectl apply -f -o.io/inject: "true"
```


</details>

### For backend workloads, require mTLS from their peers

<details>
<summary>Answer</summary>

  
```
spec:
  selector:
    matchLabels:
      app: backend
  mtls:
    mode: STRICT
```

</details>

### Check what Istio is actually enforcing on the pod

<details>
<summary>Answer</summary>

<code>istioctl x describe pod <pod-name> -n production </code>


</details>