### In the context of multi-tenancy

<details>
<summary>Answer</summary>

ResourceQuota limits the total amount of resources that a namespace can consume.
Useful for preventing one namespace/team from consuming all cluster resources and provides a degree of **tenant isolation**

Suppose you have two teams: team-a and team-b. You don't want team-a to create 100 Pods and consume the entire cluster.

This is enforced across all Pods in team-a. If team-a has already reached: requests.cpu: 2, another Pod requesting 500m CPU will be rejected.

```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
```

</details>

### Example of how to restrict the number of objects

<details>
<summary>Answer</summary>


```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-quota
  namespace: team-a
spec:
  hard:
    pods: "10"
    services: "5"
    secrets: "20"
    configmaps: "20"
```

So if an attacker or misconfigured workload tries to create thousands of Pods in team-a, the API server will reject them once the quota is reached. That's a useful DoS / **resource-exhaustion protection** mechanism.

</details>

### ResourceQuota vs LimitRange

<details>
<summary>Answer</summary>

**ResourceQuota** = namespace-wide budget

**LimitRange** = per-container/Pod defaults and constraints

```
Namespace: team-a

ResourceQuota: "The entire namespace gets 4 GiB memory."

LimitRange: "No individual container can request more than 1 GiB."

```

#### Can be used together

##### LimitRange (per Container)

```
limits:
  - type: Container
    max:
      memory: 1Gi
    default:
      memory: 512Mi
    defaultRequest:
      memory: 256Mi
```

##### ResourceQuota (per namespace)

```
hard:
  requests.memory: 4Gi
  limits.memory: 8Gi
```

</details>