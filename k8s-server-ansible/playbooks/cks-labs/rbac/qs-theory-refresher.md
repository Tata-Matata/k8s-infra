## What can (Cluster)RoleBinding bind permissions to?

<details>
<summary>Show answer</summary>

- User
- Group
- ServiceAccount

```
subjects:
- kind: Group
  name: developers
```

</details>

## How to check if token contains any groups claim?
<details>
<summary>Show answer</summary>

```
TOKEN=$(cat /path/to/token)
echo "$TOKEN" | cut -d. -f2 | base64 -d | jq

```

</details>


## Audit logs TODO

<details>
<summary>Show answer</summary>
Option 3: API server audit logs

If audit logging is enabled, you'll see entries like:

```
"user": {
  "username": "system:serviceaccount:default:nginx-sa",
  "groups": [
    "system:serviceaccounts",
    "system:serviceaccounts:default",
    "system:authenticated"
  ]
}
```
</details>

## TokenReview API TODO
<details>
<summary>Show answer</summary>
If you submit the service account token to the TokenReview API:

```
apiVersion: authentication.k8s.io/v1
kind: TokenReview
spec:
  token: <service-account-token>
```

the response contains:

```
status:
  authenticated: true
  user:
    username: system:serviceaccount:default:nginx-sa
    uid: ...
    groups:
    - system:serviceaccounts
    - system:serviceaccounts:default
    - system:authenticated
```
TokenReview is an actual Kubernetes API resource, but it's a little unusual because it is not persisted in etcd.
TokenReview → send object to API server → API server authenticates the token → returns the result → discards the object.
Creating TokenReview objects requires the create permission on the tokenreviews.authentication.k8s.io resource.

</details>


