### Service mesh
<details>
<summary>Answer</summary>

A service mesh is a dedicated infrastructure layer for managing **communication between services**.

Without a service mesh, your applications themselves have to deal with things like:

- TLS/encryption
- retries
- timeouts
- authentication
- traffic routing
- observability
- load balancing

A service mesh moves much of this networking functionality outside your application code. Typically, a proxy (Envoy) sits next to each application. The proxies communicate with each other.

</details>

### How mTLS is implemented

<details>
<summary>Answer</summary>

```
Pod A -->  plaintext from application --> Istio sidecar --> mTLS encrypted --> Istio sidecar --> plaintext to application on Pod B.

```

The applications themselves don't need to implement TLS. The **Istio sidecars (Envoy)** handle the encryption/decryption.

#### Envoy 

Envoy is like a **network proxy** that Istio puts next to your Pod. The traffic gets intercepted by Envoy, and Envoy handles the network-level stuff. Istio commonly deploys an Envoy **sidecar container** into the same Pod as your application. They're separate containers, but they share the **Pod's network namespace**.

So with Istio sidecar injection, you'll often see something like:

```
kubectl get pods -n <namespace>


frontend   2/2     Running
backend    2/2     Running

```

</details>

### PeerAuthentication
<details>
<summary>Answer</summary>

PeerAuthentication is about how a workload accepts incoming traffic: “What kind of traffic will this workload accept from its peers?”

It is the **receiving** Pod's perspective. 

With:

```
mtls:
  mode: STRICT
```

the server says: "I will accept connections only if they come through Istio mTLS."

So:

```
client Envoy ──── mTLS ────> server Envoy ──> server container
                 ✓

```
but:

```
client ───── plaintext ─────> server
                 ✗
```

</details>

### Modes
<details>
<summary>Answer</summary>

We can think of the receiving workload as a **security guard**. 


##### Strict
only mTLS traffic is accepted. "Only authenticated/mTLS peers are allowed."

```
spec:
  mtls:
    mode: STRICT
```

##### Permissive
accepts both mTLS and plaintext traffic. Useful during migration. 
"I'll accept either mTLS or plaintext."
You can have some clients already using sidecars/mTLS while others aren't.

```
spec:
  mtls:
    mode: PERMISSIVE
```

##### Disable
mTLS is not used.

```
spec:
  mtls:
    mode: DISABLE
```

</details>

### Namespace vs workload

<details>
<summary>Answer</summary>

#### namespace-wide policy

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


#### target a particular workload

```
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: backend-mtls
  namespace: production
spec:
  selector:
    matchLabels:
      app: backend
  mtls:
    mode: STRICT
```

</details>



kubectl exec -ti -n test test -- curl --head http://helloworld.default.svc:5000/hello 

root@controlplane ~ ➜  kubectl exec -ti -n test test -- curl --head http://helloworld.default.svc:5000/hello
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56

apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT


    IMPORTANT: This is happening because Istio Injection is not enabled on the test namespace, so traffic from the test pod to the helloworld endpoint is going over plaintext. But the PeerAuthentication policy is enforcing that all traffic must be mTLS encrypted.


    How do we fix this?

If your first instinct is to enable Istio Injection on the test namespace, delete the test pod and recreate it; you would then be 100% correct.

Let's enable Istio Injection on the test namespace, and then delete and recreate the test pod.


