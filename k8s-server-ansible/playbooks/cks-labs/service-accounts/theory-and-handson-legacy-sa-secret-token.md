## What is the practical use of a (legacy) ServiceAccount secret token (as opposed to new projected ServiceAccount token)?

<details>
<summary>Show answer</summary>

A manually created **kubernetes.io/service-account-token Secret** exists mainly to obtain a **long-lived** ServiceAccount token that is **not tied to a Pod.**

That makes it useful for things like:

- External automation scripts
- **Legacy** applications that expect a token in a Secret
- CI/CD systems that can't use OIDC or another modern authentication mechanism
- Lab environments where you want a static credential

We can generate SA, then Secret, extract token and copy it to Jenkins / backup server / custom script.

In contrast: when a Pod starts, kubelet submits request to TokenRequest API and obtains short-lived JWT, which is 
mounted into Pod and which kubelet refreshes automatically

**A projected token**:

- belongs to a specific Pod,
- is intended for in-cluster use,
- expires and is rotated.

**A Secret-based token**:

- belongs only to the ServiceAccount,
- can be used from anywhere that can reach the API server,
- typically does not expire (unless your cluster is configured otherwise or you recreate it).

<details>
<summary>Hands-On</summary>

1. Create SA my-service-account
2. Create secret of  <code>type: kubernetes.io/service-account-token</code> and annotation <code>kubernetes.io/service-account.name: "my-service-account"</code>

```
apiVersion: v1
kind: Secret
metadata:
  name: my-service-account-token
  namespace: default
  annotations:
    kubernetes.io/service-account.name: "my-service-account"
type: kubernetes.io/service-account-token
```


3. Inspect the secret
4. The secret has the automatically populated field **token**. If we base64 decode the token and then decode the JWT, we see
```
{

  "iss": "kubernetes/serviceaccount",

  "kubernetes.io/serviceaccount/namespace": "default",

  "kubernetes.io/serviceaccount/secret.name": "my-service-account-token",

  "kubernetes.io/serviceaccount/service-account.name": "my-service-account",

  "kubernetes.io/serviceaccount/service-account.uid": "0fc8bd6f-28c2-450c-9ba6-26a241890566",

  "sub": "system:serviceaccount:default:my-service-account"

}

```

It also has ca.crt. Its purpose is for the client to verify the API server's identity (certificate). It is not the one the token's signature is validated with!

The token is signed and verified by this key pair, that is configured in API server:

```
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
```

Now we can use this token in applications that need to access K8s API. 

When the JWT is used in request, API server 
- verifies the signature using the ServiceAccount public key
- checks standard JWT claims (exp, nbf, etc., if present)
- extracts the ServiceAccount identity from the claims
- verifies that the referenced ServiceAccount still exists.
- authenticates the request as that ServiceAccount.
- runs RBAC authorization.

Once we have extracted the JWT, the Secret no longer participates in the authentication process.
Even if we delete the secret, if the token is still cryptographically valid, it will continue to authenticate successfully because the API server validates the JWT itself, not the Secret.

</details>

</details>

## Do we actually need a Secret?

<details>
<summary>Show answer</summary>

If we just need a long-lived token that belongs to a certain SA, we can generate it without Secret

```
kubectl create token my-sa

```

</details>

## What are the disadvantages of this (legacy) ServiceAccount secret token?

<details>
<summary>Show answer</summary>
These can stop the token from working:


- The ServiceAccount is deleted.
- The API server's ServiceAccount signing key changes.
- The token has an expiration claim and has expired.
- The cluster is reconfigured to reject it.

Since token is long-lived, once someone copies it, deleting the Secret doesn't revoke it. Since the API server validates the JWT independently, anyone with a valid copy can continue using it until it expires (if it ever does) or becomes invalid for one of the reasons above.

</details>