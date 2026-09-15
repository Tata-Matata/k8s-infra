## Run 02-lab-fix-apigroups-in-role playbook

The playbook creates a role and rolebinding **apigroups** to allow an application operator to manage:

- ConfigMaps
- Deployments
- Jobs
- NetworkPolicies
- HorizontalPodAutoscalers

However, there is some problem with the defined Role. Troubleshoot and fix.
The goal is to get **yes** for commands like <code>kubectl auth can-i --as system:serviceaccount:default:apigroups get configmaps</code>

## Test and fix permissions 

<details>
<summary>Show answer</summary>

<code>kubectl auth can-i --as system:serviceaccount:default:apigroups  get configmaps</code> returns yes, so at least the rolebinding works fine


<code>kubectl auth can-i --as system:serviceaccount:default:apigroups  get deploy</code> returns no

We need to inspect the role:

```
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - deployments
  - jobs
  - networkpolicies
  - horizontalpodautoscalers
  verbs:
  - get
  - list
  - create
```

apiGroups: [""] means the core API group, which is the ungrouped API served under paths like /api/v1. 
By contrast, grouped APIs live under /apis/...
This is why configmaps work (core API group), but the rest of the resources don't.
 
So we need to find out which apiGroups to specify

##### Jobs

<code>kubectl api-resources | grep -i job</code>

For jobs we need **batch**

##### Deployments

<code>kubectl api-resources | grep -i deploy</code>

For deployments we need **apps**

##### networkpolicies

<code>kubectl api-resources | grep -i networkpol</code>

For network policies we need **networking.k8s.io**

##### HPA

<code>kubectl api-resources | grep -i horizo</code>

For HPA we need **autoscaling**

##### How to structure rules

We could collect everything under one rule, since the verbs are the same

```
rules:
- apiGroups: ["", "apps", "batch", "networking.k8s.io", "autoscaling"]
  resources: ["configmaps", "deployments", "jobs", "networkpolicies", "horizontalpodautoscalers"]
  verbs: ["get", "list", "create"]
```

Although a single mixed rule is valid, it is harder to read and easier to get wrong later. When someone reviews the Role, they have to mentally map each resource to one of several API groups in the same rule. That is exactly the kind of RBAC config that becomes confusing during troubleshooting.


A clearer approach is to create separate rule for each apiGroup:

```
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create"]

- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create"]

- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "list", "create"]

- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
  verbs: ["get", "list", "create"]

- apiGroups: ["autoscaling"]
  resources: ["horizontalpodautoscalers"]
  verbs: ["get", "list", "create"]
```

##### Fix apigroups role

<code>kubectl edit role apigroups</code>

##### Check

Run <code>kubectl auth can-i --as system:serviceaccount:default:apigroups  get deploy</code> 
for each verb and resource to ensure the result is yes

</details>