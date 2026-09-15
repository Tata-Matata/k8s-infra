### Ways to authenticate to the API server at HTTP level
<details>
<summary>Show answer</summary>

1. client certificate (TLS handshake)
2. token
3. static token / username-password in file (--token-auth-file, --basic-auth-file) - legacy, not for production
   
</details>

### How kubectl obtains the auth material to submit request to API server

<details>
<summary>Show answer</summary>

There are different ways how kubectl can procure the authenticaton material (listed above)

##### embedded bearer token
Specified directly in kubeconfig
kubectl simply sends the stored bearer token with every request.

```
users:
- name: my-user
  user:
    token: eyJhbGc...

```


##### exec plugin (kubelogin, aws, gcloud, az)

The kubeconfig contains an exec section:

```
users:
- name: my-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1
      command: kubelogin
      args:
      - get-token

```



When user runs <code>kubectl get pods</code>, kubectl sends "I need credentials" to exec plugin (kubelogin), the plugin opens browser (Keycloak / Entra ID / Okta), the external OIDC provides JWT. 

The flow is:
kubectl --> exec plugin --> Identity Provider (Keycloak / Entra ID / Okta) --> token --> kubectl Authorization: Bearer eyJ... --> API server


##### cloud CLI

Managed Kubernetes services commonly use the cloud provider's CLI as the exec plugin.
- Azure (az or kubelogin)
- Google (gcloud)
- AWS (aws)

```
users:
- name: my-user
  user:
    exec:
      command: az

```

kubectl --> exec plugin --> Azure CLI / kubelogin --> Microsoft Entra ID --> token --> kubectl Authorization: Bearer eyJ... --> API server




##### client certificate

Your kubeconfig contains something like:

```
users:
- name: my-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1
      command: kubelogin
      args:
      - get-token
```

##### How does the exec plugin know where the identity provider is?

The plugin needs enough information to request a token:

- issuer URL
- client ID
- etc

These values may be stored:

- in the kubeconfig,
- in the plugin's own configuration,
- or supplied automatically by the cloud provider.

For example, the plugin might know:

```
Issuer:
https://login.microsoftonline.com/<tenant-id>

Client ID:
abcd-1234

Redirect URI:
http://localhost:8000

```

The values could be stored like this in kubeconfig

```
users:
- name: employee
  user:
    exec:
      command: kubelogin
      args:
      - get-token
      - --oidc-issuer-url=https://keycloak.company.com/realms/dev
      - --oidc-client-id=kubernetes

```

##### Example with Keycloak

Administrator tells everyone: "Download this kubeconfig."

```
users:
- name: employee
  user:
    exec:
      command: kubelogin
      args:
      - get-token
      - --oidc-issuer-url=https://keycloak.company.com/realms/dev
      - --oidc-client-id=kubernetes
```
When user runs <code>kubectl get pods</code>, the plugin knows exactly where to send you: https://keycloak.company.com/realms/dev

User logs in. The plugin receives a JWT. It gives the JWT to kubectl. Kubectl includes it in every request:

```
Authorization: Bearer eyJ...
```

</details>

### How API server validates token/certificate and maps it to user identity and eventually RBAC

<details>
<summary>Show answer</summary>

When API server recieves the token, it does not know what kind of token it has received.
There is a number of Authenticators that try to parse the token and determine if it is "their" token to process or not.

#### Bootstrap token authenticator  
Used when a new node joins the cluster to authenticate a brand-new kubelet that doesn't yet have a client certificate. 
Enabled with **--enable-bootstrap-token-auth** flag, watches for Secrets of type: bootstrap.kubernetes.io/token

1. The token has the form [token-id].[token-secret], so the Authenticator splits it into 2 parts ID + secret
2. Authenticator looks for Secret of type **bootstrap.kubernetes.io/token** with name <code>bootstrap-token-[token-id]</code> in **kube-system** namespace. It looks like this. The values are base64 encoded because all Secret data is. 

```
apiVersion: v1
kind: Secret
metadata:
  name: bootstrap-token-abcdef
  namespace: kube-system

type: bootstrap.kubernetes.io/token

data:
  token-id: YWJjZGVm
  token-secret: MTIzNDU2Nzg5MGFiY2RlZg==
  expiration: MjAyNi0wOC0wM1QxMjowMDowMFo=
  usage-bootstrap-authentication: dHJ1ZQ==
  usage-bootstrap-signing: dHJ1ZQ==
  auth-extra-groups: c3lzdGVtOmJvb3RzdHJhcHBlcnM6a3ViZWFkbTp...
```

- usage-bootstrap-authentication	Allows authentication to the API server
- usage-bootstrap-signing	Allows signing operations during bootstrap discovery
- auth-extra-groups	Additional groups assigned to authenticated clients (system:bootstrappers:kubeadm:default-node-token  allows the RBAC rules needed for node bootstrapping - creating a CSR and reading the cluster information needed for bootstrapping)


Since new kubelet doesn't have certificate yet, without some initial authentication, the API server has no idea whether this kubelet should be trusted. The bootstrap token solves this "first contact" problem. This mechanism avoids shipping long-lived client certificates to new nodes while still allowing them to securely enroll into the cluster. No cryptographic signing involved. 

1. Authenticator compares the token-secret with the submitted bootstrap token 
2. It verifies that the token hasn't expired, the requested usage (authentication/signing) is allowed.
3. If the token is valid, kubelet can submit CSR and receive client certificate with the signature that the server can later trust.

The API server trusts the token because the token is stored in the cluster itself. 
Why can't an attacker create one? Because creating that Secret is itself a privileged Kubernetes API operation.
You must already be authenticated and authorized.

##### Example flow with kubeadm

1. We run <code>kubeadm token create</code> or <code>kubeadm init</code>
   kubeadm creates a bootstrap token Secret (for ex., abcdef.1234567890abcdef  --> token-id.token-secret)
2. Then we run 
   
```
   kubeadm join 10.0.0.10:6443 \
  --token abcdef.1234567890abcdef \
  --discovery-token-ca-cert-hash sha256:...</code>
```
3. kubeadm writes a bootstrap kubeconfig for the kubelet

```
users:
- name: kubelet-bootstrap
  user:
    token: abcdef.1234567890abcdef
```


</details>

3. The kubelet then authenticates using that bearer token: <code>Authorization: Bearer abcdef.1234567890abcdef</code>

4. The kubelet creates a Certificate Signing Request (CSR). The CSR requests a client certificate.
5. Usually the controller manager automatically approves bootstrap CSRs.
6. The kubelet downloads the certificate and stores it under <code>/var/lib/kubelet/pki/kubelet-client-current.pem</code>
7. Then the bootstrap token is no longer used. Kubelet authenticates as client using mTLS

##### Other ways for initial authentication of kubelet, without token

1. Pre-generated client certificates. No bootstrap token needed. Generate certificate and key. Install them on the machine. The node already has a trusted identity. No CSR needed
2. External (corporate) PKI issues a certificate and it is installed on the machine. No token or CSR necessary
3. Cloud-provider identity. For ex., an EC2 instance already has an IAM role. The cloud just needs to verify that it is one of its instances
4. Your own bootstrap service that generates certificate and installs on the machine


#### ServiceAccount JWT Authenticator

Purpose: Pods talking to the API server. 
Needs **--service-account-key-file**


1. Parses the JWT.
2. Verifies its signature using the API server's public key (--service-account-key-file).
3. Checks expiration, audience and issuer.
4. Checks that the referenced ServiceAccount still exists (and for bound tokens, that the Pod/Secret binding is still valid).

So the trust comes from **digital signatures**.
Identity: system:serviceaccount:default:my-sa
Groups:
- system:serviceaccounts
- system:serviceaccounts:default
- system:authenticated


#### OIDC Authenticator
(e.g. from Keycloak, Okta, Entra ID)

Purpose: human  users. May be configured via AuthenticationConfiguration

The API server:

1. Downloads the OIDC provider's public keys (JWKS).
2. Verifies the JWT signature.
3. Checks issuer (iss).
4. Checks audience (aud).
5. Extracts username and groups from the claims. Maps to username and groups

(s. theory-external-idp-authentication-config.md)

Trust comes from Issuer's signing key

#### Authentication webhook

Purpose: delegate authentication

Some organizations configure an authentication webhook. The flag **--authentication-token-webhook-config-file** specifies where the configuration is to be found

The API server sends:

```
{
  "token": "eyJhbGc..."
}
```

to an external service. That service replies:


```
{
  "authenticated": true,
  "user": {
    "username": "alice",
    "groups": ["developers"]
  }
}
```

The API server trusts the webhook's answer.
Trust comes from: Webhook server

#### Static token (not recommended for production)
The token is stored in file, the path is passed as parameter to the API server

#### X509 client certificate (not a bearer token)

No Authorization header. Authentication happens during TLS.

During TLS handshake Client presents certificate. API server verifies it against **--client-ca-file**
Then extracts CN = username and O = groups
Example certificate:

```
CN=alice
O=developers
```

Identity:

```
alice
developers
```

#### How does API server determine  a list of Authenticators to pass the token to?

They come from command-line flags (or the equivalent structured configuration).

--client-ca-file registers X509 Authenticator
--enable-bootstrap-token-auth  Bootstrap Token Authenticator
--service-account-key-file  ServiceAccount JWT Authenticator
--oidc-issuer-url, --oidc-client-id  OIDC Authenticator
--authentication-token-webhook-config-file  Webhook Authenticator


#### How does the API server know which JWT authenticator to use?

Suppose the API server has:

JWT Authenticator A with Issuer: https://keycloak.company.com

and

JWT Authenticator B with Issuer: https://login.microsoftonline.com/...

Incoming JWT:

```
{
  "iss":"https://keycloak.company.com"
}
```

Authenticator A says: That's my issuer. Verifies signature.
Authenticator B is never used.

Incoming JWT:

```
{
  "iss":"https://login.microsoftonline.com/..."
}
```

Now B succeeds.