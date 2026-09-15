## Create nginx pod

<details>
<summary>Show answer</summary>
kubectl run --image nginx ng
</details>

## Find the folder inside the pod container that contains token

<details>
<summary>Answer</summary>
kubectl get po -o yaml > ng.yaml
vi ng.yaml

Inspect volumes. Find the projected one kube-api-access-xxx
Find the corresponding volume mountPath under pod.spec.containers

</details>

## Inspect the projected volume inside the pod. What does it consist of? where do the components come from?

<details>
<summary>Answer</summary>
We have 3 sources: 
- the token is procured by kubelet from TokenAPI
- ca.crt certificate content is taken from the ConfigMap object kube-root-ca.crt
- namespace comes from pod metadata

*path* attribute tells us the name of the file

```
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```
</details>

## Decode ca.crt and find when it expires, who is the issuer, who it is issued for and SANs

<details>
<summary>Answer</summary>

a standard PEM-encoded X.509 certificate can be decoded with openssl x509

```
kubectl get configmap kube-root-ca.crt -o jsonpath='{.data.ca\.crt}' | openssl x509 -text -noout
```

OR from pod

```
kubectl exec -it  ng -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt | openssl x509 -text -noout
```

Inspect fields *Issuer, Subject, Validity Not After, Subject Alternative Name*

</details>

## Decode token and find when it expires, the audience, the issuer and the identity of the token owner

<details>
<summary>Answer</summary>

JWT token has this structure header.payload.signature
We need only payload

```
TOKEN=$(kubectl exec -it ng -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
echo "$TOKEN" | cut -d. -f2 | base64 -d | jq .

```

-d is delimiter to split the content on
-f2 means take the second part after splitting
jq can be installed with apt, gives nice output

Inspect fields 

### sub

```
"sub": "system:serviceaccount:default:default"
```

##### Format 
system:serviceaccount:<namespace>:<serviceaccount>

##### Meaning
When the Pod sends this token to the API server, the API server authenticates it as default service account in default namespace.
Later, authorization (RBAC) decides what this identity may do. For ex., a role binding may define that default SA can read configmaps

 ### aud

```
"aud": [
  "https://kubernetes.default.svc.cluster.local"
]

```
##### Meaning
Who is this token intended for? This token is only supposed to be accepted by

https://kubernetes.default.svc.cluster.local

which is the Kubernetes API Server. Suppose someone steals this token. If they try to authenticate to another service, that service should reject it because the audience doesn't match. This is one of the major improvements over legacy service account tokens.

### iss
```
"iss": "https://kubernetes.default.svc.cluster.local"

```
##### Meaning
Who created this token? API server signs this JWT. When later API server recieves the token, it verifies the issuer, signature and audience before authenticating it.

### exp
Expiration date. Linux timestamp

```
"exp": 1814035269
```

Convert with 

```
  date -d @1814035269
```


### kubernetes.io
This entire section is added by Kubernetes. It binds the token to Kubernetes objects.
Modern projected tokens are bound to a specific Pod. That means Kubernetes knows exactly which Pod requested this token.

```
"kubernetes.io": {
    "namespace": "default",
    "node": {
      "name": "k8s-playground",
      "uid": "50e8317b-c1da-4db5-943b-663d7f633a9a"
    },
    "pod": {
      "name": "ng",
      "uid": "6796f2d8-c18e-4e9d-9b2b-95dc5be8ea83"
    },
    "serviceaccount": {
      "name": "default",
      "uid": "c880f105-785e-4c28-83fd-c042195482a4"
    },
    "warnafter": 1782502876
  }
```


#### warnafter
This token should be refreshed after this time. The kubelet will request a fresh token before expiration. So Pods never suddenly lose access to the API.

### iat
When was issued. 

### nbf
can be used not before



</details>