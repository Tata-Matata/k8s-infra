## Check if service account mysa in default namespace can list pods

<details>
<summary>Answer</summary>

```
kubectl auth can-i --as system:serviceaccount:default:mysa list pods

```

</details>

## Check everything service account mysa from default namespace can do

<details>
<summary>Answer</summary>

```
kubectl auth can-i --list --as system:serviceaccount:default:mysa

```

</details>

## Check if a token generated for default SA can list pods in namespace myns

<details>
<summary>Answer</summary>

```
SA_TOKEN=$(kubectl create token default -n default)
curl -k  -H "Authorization: Bearer $SA_TOKEN"  https://localhost:6443/api/v1/namespaces/myns/pods

```
use API address from <code>kubectl cluster-info</code>

</details>

## Check identity and groups of the current user 

<details>
<summary>Answer</summary>

```
kubectl auth whoami 

```

This shows username and groups

```
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
```

</details>


## Check which service account a token represents

<details>
<summary>Answer</summary>

```

echo "$SA_TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .

```

The output could be (check sub field)

```
{ "aud": [ "https://kubernetes.default.svc.cluster.local" ], "exp": 1786208531, "iat": 1786204931, "iss": "https://kubernetes.default.svc.cluster.local", "jti": "60b16040-98e8-47eb-923c-4f19a8a84ac0", "kubernetes.io": { "namespace": "default", "serviceaccount": { "name": "default", "uid": "c880f105-785e-4c28-83fd-c042195482a4" } }, "nbf": 1786204931, "sub": "system:serviceaccount:default:default" }
```


</details>
