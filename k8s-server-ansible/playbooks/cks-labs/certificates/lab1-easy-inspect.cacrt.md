### Decode ca.crt and find when it expires, who is the issuer, who it is issued for and SANs

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

Inspect fields Issuer, Subject, Validity Not After, Subject Alternative Name



</details>

## Why is ca.crt expiration date so far in the future?

<details>
<summary>Answer</summary>
The cluster CA is the root of trust for the cluster. It signs certificates for components like:

- API server
- kubelet (depending on configuration)
- etcd
- controller manager
- scheduler

Because replacing a cluster CA is a disruptive operation, Kubernetes installations typically create a CA that's valid for 10 years (sometimes even longer).
</details>

## What is this certificate actually used for?

<details>
<summary>Answer</summary>
Suppose your Pod executes:

```
curl https://kubernetes.default.svc
```

During the TLS handshake the API server sends its server certificate and curl needs to determine whether to trust it.
It reads ca.crt. It checks:

- Was the server certificate signed by this CA?
- Is the server certificate currently valid?
- Does the server name match (kubernetes.default.svc)?

If all checks pass, the TLS connection is established.

</details>

