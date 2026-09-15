## Explore API groups through endpoints

<details>
<summary>Show answer</summary>

```
kubectl get --raw /
```
This way, we can see the high level API structure

```
    "/api",
    "/api/v1",
    "/apis",
    "/apis/",
    "/apis/admissionregistration.k8s.io",
    "/apis/admissionregistration.k8s.io/v1",
    "/apis/apiextensions.k8s.io",
    "/apis/apiextensions.k8s.io/v1",
    "/apis/apiregistration.k8s.io",
    "/apis/apiregistration.k8s.io/v1",
    "/apis/apps",
    "/apis/apps/v1",
    "/apis/authentication.k8s.io",

```

Now, we can explore *named API groups* under **/apis/apps/v1** and *core API* under **/api/v1** 
When Kubernetes was first created, there were no API groups. Everything lived under a single API: /api/v1
- Pods
- Services
- ConfigMaps
- Secrets
- Nodes
- Namespaces
- PersistentVolumes

As Kubernetes grew, putting everything into one giant API version became unmanageable. API Groups solved this:

- apps
- networking.k8s.io
- rbac.authorization.k8s.io
- storage.k8s.io
- certificates.k8s.io
- autoscaling
- policy

The resources are for example:

- /apis/apps/v1/deployments
- /apis/batch/v1/jobs
- /apis/networking.k8s.io/v1/ingresses

<code>kubectl get pods</code> uses /api/v1/pods
<code>kubectl get deployments</code> uses /apis/apps/v1/deployments

</details>

## Explore API groups through resources
<details>
<summary>Show answer</summary>


<code>kubectl api-resources</code>

</details>


## List actual objects through API

<details>
<summary>Show answer</summary>


<code>kubectl get --raw /api/v1/namespaces/default/pods </code>

</details>

## Mapping yaml to API

<details>
<summary>Show answer</summary>

```
apiVersion: apps/v1
kind: Deployment
```

<details>
<summary>Show answer</summary>

<code>kubectl get --raw /api/v1/namespaces/default/pods </code>

</details>

```
apiVersion: v1
kind: ConfigMap
```
<details>
<summary>Show answer</summary>



<code>kubectl get --raw /api/v1/namespaces/default/configmaps </code>

</details>

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
```
<details>
<summary>Show answer</summary>


<code>kubectl get --raw /apis/networking.k8s.io/v1/namespaces/default/networkpolicies </code>

</details>
</details>

## Namespaced resources

<details>
<summary>Show answer</summary>


<code>kubectl api-resources --namespaced=true </code>

</details>

## Check HTTP requests executed by kubectl


<details>
<summary>Show answer</summary>


<code>kubectl get deployment nginx -v=8 </code>

GET https://127.0.0.1:6443/apis/apps/v1/namespaces/default/deployments/nginx

</details>

## Explore what endpoints and actual resources a restricted SA token can access

<details>
<summary>Show answer</summary>


Create SA with limited RBAC, create token, then explore


<code>curl -k -H "Authorization: Bearer $TOKEN" https://localhost:6443/api</code>

<code>curl -k -H "Authorization: Bearer $TOKEN" https://localhost:6443/apis/apps/v1</code>

<code>curl -k -H "Authorization: Bearer $TOKEN" https://localhost:6443/api/v1/namespaces/default/pods</code>

</details>

## Determine API version for Kind

<details>
<summary>Show answer</summary>
you want to create HPA but you don't remember the API version

<code>kubectl api-resources | grep -i horizontal</code>

```
horizontalpodautoscalers   hpa   autoscaling/v2
```

Now we can create resource

```
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

```
</details>

## What verbs are supported?

<details>
<summary>Show answer</summary>

kubectl api-resources --verbs=create

</details>


## How does kubectl api-resources discover everything?