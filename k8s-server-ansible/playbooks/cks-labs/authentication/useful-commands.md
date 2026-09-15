## Encode / decode base 64

<details>
<summary>Answer</summary>

```

echo -n "string" | base64 -w 0
echo -n "string" | base64 -d

```

-n is important to avoid new line character
- w 0 is important for long multi-line tokens

</details>

## Decode token from  a secret

<details>
<summary>Answer</summary>

```
k get secret my-service-account-token -o jsonpath="{.data.token}" | base64 -d

```

</details>

## Decode token from  a secret

<details>
<summary>Answer</summary>

```
k get secret my-service-account-token -o jsonpath="{.data.token}" | base64 -d

```

</details>

## Generate bootstrap token for new kubelet

<details>
<summary>Answer</summary>

```
kubeadm token create token1.randomsecret1234 --dry-run --print-join-command --ttl 2h

```

It will print something like 

```

kubeadm join controlplane-ip:6443 --token token1.randomsecret1234 --discovery-token-ca-cert-hash sha256:04a08f2775e81d16597bf99bb1...
```

</details>

## To inspect the HTTP calls involved in a specific kubectl operation you can turn up the verbosity

<details>
<summary>Answer</summary>

```
kubectl --v=8 version

```

</details>

