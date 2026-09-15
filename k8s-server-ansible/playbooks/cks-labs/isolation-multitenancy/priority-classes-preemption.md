### Pod priority and preemption

<details>
<summary>Answer</summary>

When the cluster is full, Kubernetes can evict lower-priority Pods to make room for higher-priority Pods.

1. Define priority classes

Suppose we have two teams:

- team-a: production workloads
- team-b: less important workloads

We could define:

```
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: team-a-high
value: 100000
globalDefault: false
description: "High priority for Team A production workloads"

```

and:

```
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: team-b-low
value: 1000
globalDefault: false
description: "Low priority for Team B workloads"
```

Higher number = higher priority.

2. Pods select the priority class

Team A:

```
apiVersion: v1
kind: Pod
metadata:
  name: important-app
  namespace: team-a
spec:
  priorityClassName: team-a-high
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: "2"
          memory: "1Gi"
```

Team B:

```
apiVersion: v1
kind: Pod
metadata:
  name: batch-job
  namespace: team-b
spec:
  priorityClassName: team-b-low
  containers:
    - name: app
      image: nginx
      resources:
        requests:
          cpu: "2"
          memory: "1Gi"
```

Now imagine a node has only enough free CPU for one of them.

3. What happens when Team A needs resources?

Imagine the node currently looks like:

```
Node: 8 CPU

Team B:
  batch-1       2 CPU   priority 1000
  batch-2       2 CPU   priority 1000
  batch-3       2 CPU   priority 1000

Free:            2 CPU

Team A submits:

important-app
requests: 2 CPU
priority: 100000

```


It fits, so nothing special happens. But suppose the node were completely full:

```
Node: 8 CPU

team-b/batch-1    2 CPU   priority 1000
team-b/batch-2    2 CPU   priority 1000
team-b/batch-3    2 CPU   priority 1000
team-b/batch-4    2 CPU   priority 1000

Free: 0
```

Team A submits a Pod requesting 2 CPU. The scheduler says: "I cannot schedule this Pod because there isn't enough capacity.". It can then use preemption. It may evict one or more lower-priority Pods:

```

team-b/batch-2    2 CPU   priority 1000
team-b/batch-3    2 CPU   priority 1000
team-b/batch-4    2 CPU   priority 1000
team-a/important  2 CPU   priority 100000
```

So Team A's high-priority workload gets the resources at the expense of Team B's low-priority workload.


</details>


### Pod priority + preemption vs QoS based eviction

<details>
<summary>Answer</summary>

**Priority + Preemption** answers the question "Which Pod should get scheduled?" especially when Scheduler cannot fit a new higher-priority Pod. So here we are dealing a new resource is created (pod for ex.), but there is no room for it.

**QoS + kubelet eviction** decides "Which existing Pod should be removed because this node is under pressure?" when Node runs low on memory/disk/etc. So here there is no new pod at all. The node itself starts experiencing memory pressure. The kubelet may evict Pods to protect the node.
Generally, under resource pressure, Pods that are using more resources relative to their requests and have lower QoS get evicted earlier.

**Preemption** makes room for a Pod that wants to be scheduled. **Eviction** protects a node that is already under resource pressure.

</details>