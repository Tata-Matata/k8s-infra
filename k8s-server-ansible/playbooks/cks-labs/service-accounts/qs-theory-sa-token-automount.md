## What is the default of automountServiceAccountToken? where can it be configured?

<details>
<summary>Show answer</summary>

The option can be set on both service account and pod. 
If **serviceAccountName** is not specified explicitly, the default one is used. 

1. So if neither SA not automountServiceAccountToken is configured, a new pod has a projected volume mounted into the container, with the token that has permissions of the default SA.

2. If automountServiceAccountToken is true on SA and a pod with this SA does not set automountServiceAccountToken false, the token will be mounted.

3. If a pod sets automountServiceAccountToken to false, while SA has it set to true, the pod's setting overrides the SA, so the token is not mounted.



</details>

## What are the risks of having automountServiceAccountToken set to true in the pod?

<details>
<summary>Show answer</summary>

Suppose we have a simple NGINX Pod serving static HTML. It does not need to access K8s API.
If we automount SA anyway, we  give the container credentials it never uses.
If an attacker finds a vulnerability in the application, without the token the attacker is limited to whatever is inside that container.
With a mounted token, however, the attacker has an authenticated identity. Even restricted get,list,watch permissions can give the attacker information about K8s objects in the cluster (namespaces, image versions, labels,
annotations)

</details>

## When is it appropriate to have automountServiceAccountToken set to true?

<details>
<summary>Show answer</summary>

If the application needs access to K8s API. For example:

- Prometheus Operator
- cert-manager
- Argo CD
- Flux

They continuously watch Kubernetes resources.


</details>

## How can we limit the token's power if we have to set automountServiceAccountToken to true?

<details>
<summary>Show answer</summary>
1. Set automountServiceAccountToken: false
2. mount the token somewhere else
3. use a shorter expiration
4. mount multiple service account tokens with different audiences
5. combine your own ConfigMaps, Secrets, DownwardAPI, etc.

```
volumes:
- name: my-token
  projected:
    sources:
    - serviceAccountToken:
        path: token
        audience: vault
        expirationSeconds: 600

```

</details>