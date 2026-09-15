### External identity provider


1. When user runs <code>kubectl</code>, kubectl needs Bearer token to issue authenticated request to K8s server
2. kubectl itself does not know how to talk to an identity provider. Instead, it delegates that job to an authentication plugin if it is configured

##### Exec plugin 

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

Now when user runs <code>kubectl get pods</code>, kubectl sends "I need credentials" to exec plugin (kubelogin),
the plugin opens browser (Keycloak / Entra ID / Okta), the external OIDC provides JWT. Now kubectl can use it to send requests to K8s server.

##### Cloud CLI

Managed Kubernetes services often use their cloud CLI. For example:

- Microsoft (az)
- Google (gcloud)
- Amazon Web Services (aws)


Example for Azure: kubeconfig may contain:

```
exec:
  command: kubelogin
```
or

```
exec:
  command: az
```

Then kubectl --> Azure CLI --> Microsoft Entra ID --> JWT --> kubectl

##### How does the plugin know where the IdP is?

For example, the plugin might know:

```
Issuer:
https://login.microsoftonline.com/<tenant-id>

Client ID:
abcd-1234

Redirect URI:
http://localhost:8000

```

These values are usually stored in: your kubeconfig, or the plugin's configuration, or provided by the cloud provider.

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

### AuthenticationConfiguration
<details>
<summary>Show answer</summary>



Recent Kubernetes versions support authenticating JWTs directly via **AuthenticationConfiguration**. 
AuthenticationConfiguration is a Kubernetes API object that lets you configure how the API server authenticates users, primarily via JWT authenticators (OIDC and other JWT issuers).
This configuration tells Kubernetes **how to interpret the token**, how claims map to usernames and groups.
It also specifies how to verify the JWT (issuer, audiences, signing keys/JWKS)

```
apiVersion: apiserver.config.k8s.io/v1
kind: AuthenticationConfiguration

jwt:
- issuer:
    url: https://issuer.example.com
    audiences:
    - kubernetes
  claimMappings:
    username:
      claim: sub
    groups:
      claim: groups
```

There are really two independent parts:

**Verification**: When the token arrives, API server checks if the issuer (iss), the audience are the expected ones? It checks expiration and whether the signature can be trusted (the API server has the issuer's public key to verify the signature).

**Mapping**: Tells API server to use the sub claim as the Kubernetes username and to use the groups claim as Kubernetes groups.


Previously, you configured OIDC authentication with many API server flags:

```
--oidc-issuer-url=...
--oidc-client-id=...
--oidc-username-claim=sub
--oidc-groups-claim=groups
```

With AuthenticationConfiguration, everything is in one YAML file:

```
kube-apiserver --authentication-config=/etc/kubernetes/authentication-config.yaml
```

#### Mapping to groups

Suppose an external identity provider issues this JWT:
```
{
  "sub": "alice",
  "groups": [
    "developers",
    "oncall"
  ]
}
```

and your configuration contains

```
claimMappings:
  username:
    claim: sub
  groups:
    claim: groups

```

Then Kubernetes authenticates the request as

```
Username: alice
Groups:
- developers
- oncall
```

RBAC then evaluates those groups.

