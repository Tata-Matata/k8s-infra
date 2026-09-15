# Certificates API vs traditional certificates signing

If someone needs certificate to authenticate to the cluster, they would create a private key, then a certificate signing request. Then an admin with access to the cluster's CA root certificate and private key would create the new certificate from this CSR. So in this traditional approach, you always need someone to access directly the root certificate and private key file. And the procedure has to be repeated every time the certificate expires.

Certificates API allows an admin - instead of logging into the server where the CA private key is stored - to create a K8s object **CertificateSigningRequest** that contains base64 encoded CSR received from the user. Then any admin with proper cluster role (s. below) can approve this request with <code>kubectl certificate approve</code>. 

The approved request then goes to the signer (controller deployed on the cluster, for ex., in kube-controller-manager) specified in the **signerName**. If the signer accepts the request, it issues the certificate. The certificate data is then available base64 encoded in the approved K8s object.

## Who are the signers?

<details>
<summary>Show answer</summary>

**signerName** is not just documentation. It tells Kubernetes which signer is responsible for this CSR.
The signer (either a built-in controller or an external signer like cert-manager) watches for CSRs with its signerName. So signerName is essentially a routing mechanism: it tells the appropriate signer, "This request is for you." Separating signers lets Kubernetes apply different validation rules to each type of certificate.

Each signer has its own policy about what it will sign. If the CSR doesn't satisfy the signer's policy, it may never be signed even if it has been approved (s. examples below)

### Built-in signers    

These are implemented by the **kube-controller-manager**. These are intended for Kubernetes' own PKI.

#### kubernetes.io/kube-apiserver-client-kubelet

Every kubelet authenticates to the API server using a client certificate.
That certificate is typically signed by the built-in signer.
These certificates identify the kubelet as

```
CN=system:node:<node-name>
O=system:nodes
```
The Node Authorizer and NodeRestriction admission plugin rely on these identities to grant kubelets only the permissions they need. They limit what that identity can do.

##### Who issues the CSR in this case?
The kubelet itself creates the CSR. When a node joins the cluster using <code>kubeadm join</code>, it initially authenticates with a bootstrap token. The kubelet then generates a private key and a CSR with with

```
signerName:
  kubernetes.io/kube-apiserver-client-kubelet
```
It submits the CSR to the API server. Depending on cluster configuration, that CSR may be automatically approved and signed by the controller manager. The resulting client certificate is then used for all future authentication to the API server.

##### Rotation
Later, before the certificate expires, the kubelet automatically generates another key pair and submits another CSR.
Rotation can be enabled or disabled in kubelet configuration (<code>/var/lib/kubelet/config.yaml</code>)

```
rotateCertificates: true
```

#### kubernetes.io/kubelet-serving

Sometimes the API server (or another client) wants to establish a TLS connection to the kubelet.


For example:

- kubectl logs
- kubectl exec
- kubectl port-forward

The kubelet acts as server and needs to prove its identity to the client, so the kubelet needs a server certificate.
That certificate is signed by the built-in signer as well. 


##### Who issues?
The kubelet also needs a server certificate and therefore generates another CSR

```
signerName:
  kubernetes.io/kubelet-serving
```

If serving certificate **rotation** is enabled, it periodically renews that certificate in exactly the same way.


#### kubernetes.io/kube-apiserver-client

This one is for ordinary clients authenticating to the API server.
- administrators
- automation
- controllers outside the cluster

When admin user creates **CertificateSigningRequest** object, usually the signer will be kubernetes.io/kube-apiserver-client

```
apiVersion: certificates.l8s.io/v1
kind: CertificateSigningRequest
spec:
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 600 #seconds
  usages:
  - client auth
  request: <base64 csr data>
```


### External signers

Anyone can write a controller that watches CSRs with a custom signer name. For example:
A company has a corporate PKI (Microsoft AD CS, HashiCorp Vault, etc.). The CA private key is stored securely (perhaps in a Vault). Security policies dictate who may receive certificates. You could write a controller that watches

<code>signerName: corp.example.com/kubernetes-users</code>

When an approved CSR appears, the controller could:

- Read the CSR.
- Validate it:
        - Is the CN an existing LDAP user?
        - Is the user in the "Kubernetes Admins" group?
        - Is the requested validity period acceptable?
        - Are the requested usages allowed?
- Ask Vault (or another PKI) to sign the CSR.
- Write the resulting certificate back to the CSR's status.certificate.

</details>

## Why are usages important?

<details>
<summary>Show answer</summary>
specifies what the resulting certificate is allowed to be used for.
These become the certificate's X.509 **Key Usage** and **Extended Key Usage** extensions.

If you request the wrong usages, the signer may reject the CSR or issue a certificate that won't work for your intended purpose. For example: A certificate with only server auth cannot be used to authenticate to the Kubernetes API as a client. A certificate without client auth will typically fail client authentication.

Approver may not check these fields. Approval and signing are different phases. The approver merely indicates, "This request is authorized to proceed." The signer decides whether the request matches its policy.



#### Example of client certificate

```
usages:
- digital signature
- key encipherment
- client auth
```

#### Example of server certificate

```
usages:
- digital signature
- key encipherment
- server auth
```

</details>

## Who can see such requests in the cluster? Who can approve?
<details>
<summary>Show answer</summary>

To approve other users' Certificate Signing Requests (CSRs) in Kubernetes, the user needs permission to update the approval subresource of the CertificateSigningRequest resource.


```
apiGroups: ["certificates.k8s.io"]
resources: ["certificatesigningrequests/approval"]
verbs: ["update"]
```

In practice, you'll usually also want:


```
apiGroups: ["certificates.k8s.io"]
resources: ["certificatesigningrequests"]
verbs: ["get", "list", "watch"]
```

</details>

## When CSR object is created, API server populates fields groups and username. What values does it set?
<details>
<summary>Show answer</summary>

When you create a csr with <code>kubectl apply -f csr.yaml</code>, API server sets these sections. For example:

```
  groups:
  - kubeadm:cluster-admins
  - system:authenticated
  username: kubernetes-admin

```

These values represent who submitted the CSR, i.e. who executed <code>kubectl apply -f csr.yaml</code>, not who the certificate is requesting to become (these are fields CN and O in the certificate request generated with openssl).

The user, who submits the CSR, authenticates to the API server (using kubeconfig, token, etc.). API server records that identity in the CSR:

- username
- uid
- groups
- extra

Approvers can use that information to decide whether the request is legitimate.
Suppose the CSR looks like this:


```
Requested certificate:
    CN=system:node:worker-1
    O=system:nodes

```

but the CSR object shows:


```
username: bob
groups:
- system:authenticated

```

An approver can immediately see that an ordinary user named bob is trying to obtain a kubelet certificate and reject the request.

By contrast, if the submitter is:


```
username: system:node:worker-1
groups:
- system:nodes

```

then the built-in approver recognizes this as a legitimate kubelet bootstrap or renewal request and can approve it automatically.

So there are two identities involved:

1. Identity of the requester (username, groups, uid on the CSR object) — filled in by the API server.
2. Identity requested in the certificate (CN, O, etc. inside spec.request) — generated by whoever created the CSR.

</details>