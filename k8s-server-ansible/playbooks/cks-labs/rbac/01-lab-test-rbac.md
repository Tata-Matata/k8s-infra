## Test if default service account can list pods and create a configmap

<details>
<summary>Show answer</summary>

#### Simple approach
```
kubectl auth can-i get pods --as=system:serviceaccount:default:default
```
This however only tells you yes or no, without giving any details


#### More verbose approach 

<code>kubectl --as=system:serviceaccount:default:default get pods</code>

Gives more information like: Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" in the namespace "default


For more verbose information add
<code>kubectl --as=system:serviceaccount:default:default get pods -v=8</code>


#### More complicated and fun - from within the pod running with default service account

1. Create nginx pod and exec into it
```
kubectl run ng --image nginx
kubectl exec -it ng -- /bin/bash
```


2. Prepare token, certificate, namespace for future tests. 

The paths can be found in volumeMount if you inspect the pod 

```
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)

```

3. Test listing pods

```
curl --cacert $CACERT -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/pods

```

This shows as expected 

```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:default:default\" cannot list resource \"pods\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
```

Default service account does not have permissions on K8s resources. 
You can verify this with <code>kubectl auth can-i --list --as=system:serviceaccount:default:default</code>

4. Add permissions to list pods and create configmap
<details>
<summary>Show answer</summary>
1. Create role that allows to list, get, watch pods as well as to create configmap
  (we can output existing role and adjust it)

2. Create rolebinding for the service account and the role
(<code>kubectl create rolebinding -help</code> has good examples)
  
<code>kubectl create rolebinding default-binding --role=default-role --serviceaccount=default:default</code>

</details>


5. Test creating configMap
<details>
<summary>Show answer</summary>
1. Create  json with configmap

```
cat <<EOF >/tmp/configmap.json
 {
  "apiVersion":"v1",
  "kind":"ConfigMap",
  "metadata":{
    "name":"test-default-sa-configmap"
  },
  "data":{
    "hello":"world"
  }
 }
    EOF
```

2. Create configmap via REST

```
curl \
  --cacert $CACERT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -X POST \
  --data @/tmp/configmap.json \
  https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/configmaps
```

</details>




