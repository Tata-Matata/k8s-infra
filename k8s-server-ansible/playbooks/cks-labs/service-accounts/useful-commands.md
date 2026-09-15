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

## Create secret account token

<details>
<summary>Answer</summary>

```
kubectl create token my-sa

```

</details>