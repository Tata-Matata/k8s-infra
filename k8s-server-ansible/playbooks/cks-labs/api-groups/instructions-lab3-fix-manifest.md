## Run 03-fix-manifest.yaml playbook

The playbook copies manifest file used to create NetworkPolicy.
Applying the manifest runs into error. Fix it.

After that, remove the resource created by this manifest from the cluster.

## Test and fix permissions 

<details>
<summary>Show answer</summary>

Error

```
error: resource mapping not found for name: "default-deny-ingress" namespace: "" from "03-fix-manifest.yaml": no matches for kind "NetworkPolicy" in version "networking.k8s.io/v2"
```

We need to check what version NetworkPolicy resource belongs to, because networking.k8s.io/v2 is apparently wrong

<code>kubectl api-resources | grep -i networkpolic</code>

**networking.k8s.io/v1**   is the correct version. After changing the manifest, kubectl apply creates the resource

</details>

## Remove the resource 

<details>
<summary>Show answer</summary>

<code>kubectl delete --force networkpolicy default-deny-ingress</code>

</details>