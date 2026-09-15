### Problem statement

<details>
<summary>Answer</summary>

Kubernetes API Priority and Fairness (APF) is about isolating **access to the Kubernetes API server**

Imagine a multi-tenant cluster:

Team A has 500 pods and constantly watches/updates them. Team B has 20 pods.
Team A's automation suddenly starts sending thousands of API requests to K8s API server.

Without APF, Team A can potentially consume a disproportionate amount of the API server's request-handling capacity.

APF lets Kubernetes classify requests into PriorityLevels and control how requests compete for API-server concurrency.


</details>

### PriorityLevelConfiguration and FlowSchema

<details>
<summary>Answer</summary>


```
apiVersion: flowcontrol.apiserver.k8s.io/v1
kind: PriorityLevelConfiguration
metadata:
  name: tenant-a
spec:
  type: Limited
  limited:
    nominalConcurrencyShares: 10
``` 

Another tenant might have: nominalConcurrencyShares: 5. Tenant-a gets a larger share of the available concurrency when there is contention.

It's not: "Team A is allowed 10 API requests." It's closer to: "When requests are competing, Team A's priority level has 10 concurrency shares relative to other priority levels."

But with this alone, Kubernetes doesn't know which requests should use it. So we need to create a **FlowSchema**, which says: "Requests made by the team-a/app ServiceAccount belong to this FlowSchema."

```
apiVersion: flowcontrol.apiserver.k8s.io/v1
kind: FlowSchema
metadata:
  name: team-a
spec:
  matchingPrecedence: 100
  priorityLevelConfiguration:
    name: team-a

  rules:
  - subjects:
    - kind: ServiceAccount
      serviceAccount:
        namespace: team-a
        name: app

```

#### Queuing

When a priority level reaches its concurrency limit, requests don't necessarily get immediately rejected. APF can queue requests. The API server can then fairly distribute execution among flows.

</details>