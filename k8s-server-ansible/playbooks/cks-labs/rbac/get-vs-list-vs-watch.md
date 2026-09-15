## Difference between verbs get, list and watch

<details>
<summary>Show answer</summary>

| Verb | HTTP Request | Example Endpoint | Meaning |
| --- | --- | --- | --- |
| get | GET | GET /api/v1/namespaces/default/pods/nginx | One specific object |
| list | GET | GET /api/v1/namespaces/default/pods | Collection of objects |
| watch | GET with watch=true | GET /api/v1/namespaces/default/pods?watch=1 | Continuous stream of changes |



#### For example:

<code>kubectl get pod nginx</code>

requires get because you're retrieving a single Pod.

<code>kubectl get pods</code>

requires list because Kubernetes first lists all Pods.

<code>kubectl get pods -A</code>

still requires list (in every namespace).

```
kubectl describe pod nginx
kubectl edit pod nginx
```

first fetch the object, so they require get.

</details>