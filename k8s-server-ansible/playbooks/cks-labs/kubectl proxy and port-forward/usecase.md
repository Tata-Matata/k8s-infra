# kubectl proxy

If your local machine can directly reach the API server and you have a kubeconfig with valid credentials, you usually don't need kubectl proxy.
*kubectl proxy* is not primarily about giving us access to the cluster. It's about providing a **local HTTP proxy** to the Kubernetes API, using our kubeconfig credentials on your behalf.



### Direct access vs kubectl proxy

<details>
<summary>Answer</summary>


```
kubectl --kubeconfig ~/.kube/config get pods
```

Request from local computer --> HTTPS + kubeconfig authentication --> API server

It reads from kubeconfig:

- API server address
- CA certificate
- client certificate/key or token
- context/namespace

We can also do this yourself with **curl**, if we extract the credentials appropriately.

```
kubectl proxy
```

Request from local computer --> localhost:8001 --> HTTPS + kubeconfig authentication --> API server

For example:

<code>curl http://127.0.0.1:8001/api/v1/namespaces/default/pods </code>

*kubectl proxy* converts local unauthenticated/plain HTTP into authenticated API request to the API server.

</details>

### When is it useful

<details>
<summary>Answer</summary>

1. Suppose we have some tool that can only make ordinary HTTP requests. It doesn't need to know about:

bearer tokens, client certificates, kubeconfig, Kubernetes contexts

*kubectl proxy* handles that part.
There is also a security perspective, because we are not giving the application K8s credentials.
But from authorization perspective there is no win here: The application can potentially perform whatever API operations your kubeconfig identity is allowed to perform.

2. It can also be convenient for quickly exploring the API

```
kubectl proxy
curl http://localhost:8001/apis
curl http://localhost:8001/api/v1/nodes
```

</details>

## kubectl port-forward

<details>
<summary>Answer</summary>

Suppose, we have a ClusterIP *nginx* service in the cluster, so only accessible within the cluster.

To access it from local computer we can:


```
kubectl proxy
curl http://localhost:8001/api/v1/namespaces/default/services/nginx/proxy/
kubectl get --raw /api/v1/namespaces/default/services/ng/proxy/

```


The trailing <code>/proxy/</code> is important
This delivers the html page served by the web server. Without trailing <code>/proxy/</code> we will get yaml output for the ClusterIP service resource 

Another option:

```
kubectl port-forward service/nginx 28080:80
curl http://localhost:28080

```

### Run on another port and in the background

<details>
<summary>Answer</summary>

```
kubectl proxy --port 8002 &

```

</details>

</details>




shasum -a 512 kubernetes.tar.gz
sha512sum