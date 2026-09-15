A **TokenReview** asks the API server to authenticate a bearer token using the same authentication chain that is used for normal API requests. The API server verifies the token (for example, validating the JWT signature, issuer, audience, and expiration) and, if authentication succeeds, returns the identity produced by the configured authenticator.

For a **JWT** with claims like:

```
{
  "sub": "12345",
  "email": "alice@example.com",
  "groups": ["developers", "oncall"]
}
```

and an **AuthenticationConfiguration** that maps:

```
claimMappings:
  username:
    claim: email
  groups:
    claim: groups
```

the TokenReview response would contain something similar to:

```
status:
  authenticated: true
  user:
    username: alice@example.com
    groups:
      - developers
      - oncall
```
A typical TokenReview request looks like this:

```
apiVersion: authentication.k8s.io/v1
kind: TokenReview
spec:
  token: eyJhbGc...
```

<code>kubectl apply -f tokenreview.yaml</code>

The API server responds with:

```
apiVersion: authentication.k8s.io/v1
kind: TokenReview
status:
  authenticated: true
  user:
    username: alice@example.com
    uid: "12345"
    groups:
      - developers
      - oncall
```


TokenReview is an excellent troubleshooting tool because it lets you verify that:

- the token is valid and trusted by the API server,
- the expected authenticator accepted the token,
- claims were mapped to the correct Kubernetes username and groups,

before RBAC authorization is evaluated.

