## Inspect everything default service account can do in default namespace

<details>
<summary>Show answer</summary>

```
kubectl auth can-i --list --as=system:serviceaccount:default:default
```

The identity format is always:

```
system:serviceaccount:<namespace>:<serviceaccount-name>
```

</details>


## What resources can the default SA create?

<details>
<summary>Show answer</summary>
In the output of can-i list command we see these resources with verb create

```
selfsubjectreviews.authentication.k8s.io
selfsubjectaccessreviews.authorization.k8s.io
selfsubjectrulesreviews.authorization.k8s.io
```

#### Explanation
These APIs allow an identity to ask questions like:

"Who am I?"
"Can I do X?"
"What are all my permissions?"

Without these, kubectl auth can-i couldn't work.

</details>

## What do entries with Non-Resource URLs mean?
<details>
<summary>Show answer</summary>
In the output of can-i list command we see:

| Non-Resource URL | Resource Names | Verbs |
| --- | --- | --- |
| /apis/* | [] | get |
| /apis | [] | get |
| /healthz | [] | get |
| /livez | [] | get |
 

#### Explanation
These are HTTP endpoints on the API server, not Kubernetes objects.
GET /healthz  returns whether the API server is healthy.
These are commonly readable by almost everyone because clients need to discover the API.

</details>

## Can default service account get / list / watch pods or deployments?
<details>
<summary>Show answer</summary>

The column Resources shows only Calico resources and selfsubjectreviews (mentioned above), so the default account can not perform any basic operations on pods or other resources

If, for instance, the SA was allowed to observe pods, the output would be

<code>pods    []    []    [get list watch]</code>


</details>


## Find what gives default SA such a broad permission set on calico network policies
<details>
<summary>Show answer</summary>
In the output of can-i list command we see:

| Resource | Resource Names | Non-Resource URLs | Verbs |
| --- | --- | --- | --- |
| globalnetworkpolicies.projectcalico.org | [] | [] | get list watch create update patch delete deletecollection |
| networkpolicies.projectcalico.org | [] | [] | get list watch create update patch delete deletecollection |


To find what gives default SA all these, we can inspect roles and cluster roles assigned to the default SA.
So we will inspect calico rolebindings and clusterrolebindings that bind to the default SA.
But first we need to filter out those that contain verbs create or update



```
kubectl get clusterrole -o json | jq -r '.items[] | select(.metadata.name | test("calico")
) | .metadata.name as $name |.rules[] | select((.verbs // [] | index("create")))  | "\($name): \(.verbs)  \(.resources)"
'
```
<details>
<summary>Explanation</summary>

- This line <code>kubectl get clusterrole -o json</code> gives us a list of objects <code>items</code>

```
{
    "apiVersion": "v1",
    "items": [
        {
            "aggregationRule": {
                "clusterRoleSelectors": [
                    {
                        "matchLabels": {
                            "rbac.authorization.k8s.io/aggregate-to-admin": "true"
                        }
                    }
                ]
            },
            "apiVersion": "rbac.authorization.k8s.io/v1",
            "kind": "ClusterRole",
            "metadata": {
              "name": "admin",
...}
```

- From each item object we select <code>.metadata.name</code> and test if it contains calico, i.e. filter out those that return true on reg exp <code>test("calico")</code>
- In <code>.metadata.name as $name</code> we store the name in the variable, cause we will need it at the end and in the next step we're going to descend into the rules, so without saving it, we'd lose access to the ClusterRole name.
- <code>.rules[]</code> iterates over each rule separately.
  

```
 "rules": [
                {
                    "apiGroups": [
                        ""
                    ],
                    "resources": [
                        "pods/attach",
                        "pods/exec",
                        "pods/portforward",
                        "pods/proxy",
                        "secrets",
                        "services/proxy"
                    ],
                    "verbs": [
                        "get",
                        "list",
                        "watch"
                    ]
                             
```
- <code>select((.verbs // [] | index("create")))</code>  - here <code>index("create")</code> returns **null** if array **verbs** does not contain <code>create</code> and **1** if it does. Since select() treats **null** as **false** and any number as **true**, only rules containing "delete" survive. The part <code>.verbs // []</code> avoids failure in case array verbs does not exist at all
- Finally we format the output  <code>"\($name): \(.verbs)"</code>


</details>


We see in the output that **clusterrole calico-tiered-policy-passthrough** allows creating and updating on network policies so it is worth looking into

```
calico-tiered-policy-passthrough: ["get","list","watch","create","update","patch","delete","deletecollection"] ["networkpolicies","globalnetworkpolicies"] 
```

We can search for clusterrolebinding with the same name to see who the role is bound to

```
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:authenticated

```

#### How do we know if the default service account is part of group system:authenticated

<code>kubectl auth whoami --as=system:serviceaccount:default:default </code>

The output shows groups

```
Username    system:serviceaccount:default:default
Groups      [system:serviceaccounts system:serviceaccounts:default system:authenticated]
```
</details>




