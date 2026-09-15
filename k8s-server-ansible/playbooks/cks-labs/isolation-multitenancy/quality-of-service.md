### In the context of multi-tenancy

<details>
<summary>Answer</summary>

Quality of Service is mainly about how Kubernetes treats Pods **when a node is under resource pressure**, especially memory pressure. It is relevant to resource isolation and availability in multi-tenant clusters.

Kubernetes assigns every Pod one of three QoS classes:
- Guaranteed
- Burstable
- BestEffort

Suppose the node runs out of memory. Kubernetes' kubelet needs to reclaim memory and may evict Pods. If team A has:

```
requests:
  memory: 512Mi
limits:
  memory: 512Mi
```

while team B has Pods with no memory requests/limits: # no resources section

team B's Pods are **BestEffort**, so they're much more likely to be **evicted first.**


</details>

### QoS classes

<details>
<summary>Answer</summary>

QoS is determined for the **entire Pod** based on its containers, not just one container.

#### Guaranteed	

Last to be evicted.
A Pod is Guaranteed if every container in the Pod has:

- a CPU request
- a CPU limit
- a memory request
- a memory limit

and, for each container:

```
CPU request == CPU limit
Memory request == Memory limit
```

##### Example

```
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
```

##### Burstable	

Eviction priority - Middle

A Pod is Burstable when it has some resource requests or limits, but it doesn't meet all the requirements for Guaranteed.

```
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
  limits:
    cpu: "1"
    memory: "512Mi"
```

This is Burstable because:

- CPU:    request 500m < limit 1
- Memory: request 256Mi < limit 512Mi

The idea is literally that the container can burst above its requested amount, up to its limit.

Another example is with no memory limit.

```
resources:
  requests:
    memory: "256Mi"
```

##### Burstable vs Guaranteed

Guaranteed is essentially: "I've requested exactly as much as I'm allowed to use."

Burstable is: "I've requested some amount, but I'm allowed to use more."

##### BestEffort	
No CPU or memory requests/limits	
First to be evicted

resources: {} or not specified at all


</details>