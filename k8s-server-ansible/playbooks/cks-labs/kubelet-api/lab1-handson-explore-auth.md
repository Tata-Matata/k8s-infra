### Find on which ports kubelet is listening

<details>
<summary>Answer</summary>


```
ss -tnlp | grep kubelet
```

</details>

## Explore authentication / authorization options 

<details>
<summary>Answer</summary>

By default, on kubeadm cluster, kubelet is listening on 10250.
In Kubelet Config (normally /var/lib/kubelet/config.yaml) there is a section disabling anonymous authentication

```
authentication:
  anonymous:
    enabled: false
```

With this configuration, user has to provide some form of authentication when querying kubelet API (certificate, token). If the value is set to **true**, anonymous requests pass authentication, but can still be stopped by API server RBAC  if authorization mode is set to **Webhook**

Kubelet Webhook authorizer (Kubelet-side authorization plugin) sends SubjectAccessReview to API server to evaluate

```
authorization:
  mode: Webhook
```

Setting it to **AlwaysAllow** bypasses RBAC.  
So enabling anonymous authentication and disabling Webhook authorization creates the most dangerous combination.

### Endpoints to explore

```
/metrics
/stats/summary
/pods
/logs/
/runningpods
/healthz

```

### anonymous false and authentication Webhook

Set this in kubelet config and restart the service if needed

```
authentication:
  anonymous:
    enabled: false
```

```
authorization:
  mode: Webhook
```
Check the endpoints with curl -k to see what information is exposed.
**Unauthorized** response from curl means 401 - authentication failed.
So the request is dropped before reaching the Webhoot and RBAC.


### anonymous true and authentication Webhook
Set anonymous enabled: true, but leave authentication to Webhook, restart kubelet
Check the endpoints

**Forbidden** response from curl means 403 - authentication passed, but API server rejected authorization
The response also shows 

```
Forbidden (user=system:anonymous, verb=get, resource=nodes, subresource(s)=[pods proxy])
```


### inspect RBAC for system:anonymous

**system:anonymous** belongs to **system:unauthenticated** group

<code>kubectl get clusterrolebindings -o yaml | grep -B20 -A10 'system:unauthenticated'</code>

This shows us system:public-info-viewer 

<code>kubectl get clusterrolebinding system:public-info-viewer -o yaml </code>

This binds to clusterrole system:public-info-viewer

<code>kubectl get clusterrole system:public-info-viewer -o yaml</code>

This shows us what endpoints we can access with **system:anonymous**

```
rules:
- nonResourceURLs:
  - /healthz
  - /livez
  - /readyz
  - /version
  - /version/
  verbs:
  - get
```

These are API server endpoints, so we could <code>curl -k https://server:6443/version</code> but nothing around kubelet endpoints.  Let's edit clusterrole system:public-info-viewer to temporarily give /pods access on kubelet api to our anonymous user. Based on <code>Forbidden (user=system:anonymous, verb=get, resource=nodes, subresource(s)=[pods proxy])</code> we could add this rule


```
rules:
- apiGroups: [""]
  resources:
    - nodes/pods
    - nodes/proxy
  verbs:
    - get
```


we can finally <code>curl -k https://server:10250/pods</code>

**DO NOT FORGET** to revert this change


</details>


### anonymous true and authentication AlwaysAllow
```
authentication:
  anonymous:
    enabled: false
```

```
authorization:
  mode: AlwaysAllow
```

should allow us to bypass all the checks and query whatever we want from kubelet api


## Enable readOnlyPort: 10255

<details>
<summary>Answer</summary>

The old http read-only port 10255 is disabled by default in current Kubernetes. The Kubelet config's default is now 0.

Add <code>readOnlyPort: 10255</code> to kubelet configuration and restart kubelet

Try these endpoints to see how much info is exposed now, even with authorization forwarded to API server by Webhook.
**RBAC-controlled access is not working here**. We're talking directly to the kubelet's unauthenticated HTTP interface. There is no kube-apiserver involved, so there is no opportunity for the API server's RBAC authorizer to evaluate the request.

```
curl -L http://<server>:10255/pods

/metrics
/logs
/stats/summary


```

Run **01-lab-apply-secret-nginx-pod.yaml**, it creates a pod with environment variables injected from a secret. Examine what information is available via /pods endpoint. 

Remove readOnlyPort from kubelet config and explore what has changed

</details>

