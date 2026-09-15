## What is ABAC

<details>
<summary>Show answer</summary>

ABAC (Attribute-Based Access Control) makes authorization decisions based on attributes of the request.

**Example**

Bob can just read pods in namespace *projectns*. Alice can do anything to all resources. The last example is for SA.

```
{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"user": "bob", "namespace": "projectns", "resource": "pods", "readonly": true}}

{"apiVersion": "abac.authorization.kubernetes.io/v1beta1", "kind": "Policy", "spec": {"user": "alice", "namespace": "*", "resource": "*", "apiGroup": "*"}}

{"apiVersion":"abac.authorization.kubernetes.io/v1beta1","kind":"Policy","spec":{"user":"system:serviceaccount:default:my-app","namespace":"default","resource":"pods","apiGroup":"","verb":"get"}}

```

**File format jsonl**

The file format is **one JSON object per line**. There should be no enclosing list or map, only one map per line.


**ABAC vs RBAC**

RBAC says: Don't create one policy per user. Create roles and assign users to those roles.
If you have hundreds of users, teams, namespaces - with ABAC, you often end up writing hundreds or thousands of individual rules.

With RBAC you define roles and bind people to roles.

</details>

## Why do we still have ABAC if we can use RBAC?
<details>
<summary>Show answer</summary>

Because RBAC wasn't always available. Early Kubernetes versions only had:

- AlwaysAllow
- AlwaysDeny
- ABAC

RBAC was introduced later and became the recommended mechanism after it matured. ABAC remains mainly for **backward compatibility.**

</details>


## How to enable ABAC

<details>
<summary>Show answer</summary>

Configure these for API server:

<code>--authorization-policy-file=SOME_FILENAME</code> 
<code>--authorization-mode=ABAC </code> 

If API server runs as static pod, the file must be mounted into the pod

</details>




