### If kubectl is not available, for example, because you have made changes to the static pod manifest of API server

<details>
<summary>Answer</summary>

```
crictl ps -a

```

</details>

### curl: Inspect HTTP/TLS-related headers without downloading body

<details>
<summary>Answer</summary>

```
curl -I
curl --head

```
</details>

### curl: Verbose output for debugging TLS/auth/networking

<details>
<summary>Answer</summary>

```
curl -v
curl --verbose

```
</details>

### curl: Testing HTTPS endpoints with self-signed/untrusted certs

<details>
<summary>Answer</summary>

-k = Don't verify TLS certificate

```
curl -k
curl --insecure

```
</details>

### curl: Write response to file

<details>
<summary>Answer</summary>


```
curl -o <file>
```
</details>

### curl: Downloading from URLs that redirect

<details>
<summary>Answer</summary>

```
curl -L
```
</details>

### curl: POST request with body and cert auth

<details>
<summary>Answer</summary>

```
curl \
  --cacert ca.crt \
  --cert client.crt \
  --key client.key \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"my-pod","namespace":"default"}' \
  https://api.example.com:8443/create
```
</details>

### curl: Save the downloaded file using the filename from the URL.

<details>
<summary>Answer</summary>

```
curl -O https://example.com/manifests/pod.yaml

With -o YOU choose filename
With -q ignore ~/.curlrc where some settings can be specified

in K8s context

curl -qO- https://... | kubectl apply -f -
```
</details>

### curl: Suppress progress/errors

<details>
<summary>Answer</summary>

Useful for ex., when combined with *watch* in K8s context

```
watch kubectl exec -it curlpod -- curl -s http://nginx
```
</details>



