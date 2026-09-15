
## Troubleshoot why Alice can't <code>kubectl get pods</code>

1. Run resources/01-lab-troubleshoot-authentication.yaml 
2. Use Alice's kubeconfig to run <code>kubectl get pods</code>


<details>
<summary>Error and explanation</summary>

#### Error

```
"Unhandled Error" err="couldn't get current server API group list: the server has asked for the client to provide credentials" error: You must be logged in to the server (the server has asked for the client to provide credentials)
```

if you run with higher verbosity <code>kubectl get pods -v=8</code>, you will also see

```
"Response" status="401 Unauthorized" 
```

#### What does it mean?
The error indicates authentication failed, not RBAC, corresponds to an HTTP 401 Unauthorized response from the API server.
When we run <code>kubectl get pods</code>  kubectl first queries:  <code>GET /api</code>  and <code>GET /apis</code>
to discover which API groups are available. Since authentication fails, even these discovery requests are rejected, and we see the final error <code>provide credentials" error: You must be logged in to the server</code>
The API server did not accept the client's identity.

#### Possible reasons 

Common causes include:

- Wrong or untrusted client CA (--client-ca-file in kube-apiserver configuration)
- Expired client certificate
- Certificate not yet valid
- Client certificate missing from the kubeconfig
- Private key doesn't match the certificate
- Corrupted certificate or key
- The client didn't present a certificate at all

#### Authentication error vs RBAC error (authorization)

If authentication was successful, but authorization failed, we would see 

```
Error from server (Forbidden): pods is forbidden:
User "alice" cannot list resource "pods"
in API group "" in the namespace "default"
```

The key difference is:

**401 Unauthorized** / "provide credentials" → the API server doesn't recognize or trust your identity.
**403 Forbidden** → the API server knows exactly who you are, but RBAC denies the requested action.

#### why does kubectl query /apis endpoint

kubectl doesn't initially know what APIs the server supports, so before executing your command it performs API discovery.
So instead of directly <code>GET /api/v1/pods</code> it does:

```
GET /version        (sometimes)
GET /api
GET /apis
GET /api/v1
GET /apis/apps/v1
...
GET /api/v1/namespaces/default/pods
```

/apis lists all named API groups. Now kubectl learns things like:

```
Deployment → apps/v1
Job → batch/v1
Role → rbac.authorization.k8s.io/v1
```

without hardcoding them.

</details>




<details>
<summary>Troubleshooting</summary>

Since the error points at authentication failure (<code>the server has asked for the client to provide credentials" error: You must be logged in to the server (the server has asked for the client to provide credentials)</code>) - we need to check what is wrong with the client certificate.

The certificate data is inside the kubeconfig file as base64 encoded certificate content, so we need to first see it in human readable format

```
kubectl --kubeconfig <path-to-alice-config> config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -text -noout > alice.crt
```

Fields to pay attention to:
- Issuer
- Subject: CN
- Validity

We see that Issuer is CN=Alice, which is suspicious, because the certificate is supposed to be signed by K8s CA.
To verify if the certificate is indeed signed by the proper authority, we need to see the path specified in <code>--client-ca-file</code> of K8s API server config. We need to obtain this CA certificate. Then run

```
openssl verify -CAfile ca.crt alice.crt
```
Result is 

```
CN = Alice, O = Wonderland
error 18 at 0 depth lookup: self-signed certificate
error /home/tati/delete.crt: verification failed
```
So clearly Alice's certificate is not signed by CA. We need to generate a new one



</details>



<details>
<summary>How to fix</summary>

#### Generate client certificate for Alice

1. Generate a private key

<code>openssl genrsa -out alice.key 2048</code>

2. Create a Certificate Signing Request (CSR)

<code>openssl req -new -key alice.key -out alice.csr -subj "/CN=Alice/O=developers"</code>

CN is going to be used by API server as user and O - as group when mapping to roles in role bindings while performing RBAC

3. Sign the CSR with the client CA
The client CA cert can be procured from K8s cluster, path specified as <code>--client-ca-file</code> in kube-apiserver configuration
The client CA key is usually in the same folder.

<code>openssl x509 -req -in alice.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out alice.crt -days 365 </code>

4. Verify

<code>openssl verify -CAfile ca.crt alice.crt</code>


5. Configure kubeconfig for Alice
Either use file paths

```
users:
- name: alice
  user:
    client-certificate: alice.crt
    client-key: alice.key

clusters:
- name: mycluster
  cluster:
    server: https://...
    certificate-authority: server-ca.crt

contexts:
- context:
    cluster: mycluster
    user: alice
```

OR base64 encoded

```
base64 -w0 alice.crt
base64 -w0 alice.key
base64 -w0 ca.crt
```

```
users:
- name: Alice
  user:
    client-certificate-data: <BASE64_OF_alice.crt>
    client-key-data: <BASE64_OF_alice.key>
```

6. kubectl --kubeconfig <path-to-alice-config> get pods


</details>