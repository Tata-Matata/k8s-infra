## Run 03-lab playbook under resources

The playbook deploys a web application in default namespace 
that queries K8s API and exposes on /pods endpoint list of pods.

After running the playbook, port forward the application with 

<code>kubectl port-forward --namespace default service/k8s-api-client 8888:8888</code>

and investigate the issue with the app on http://localhost:8888


<details>
<summary>Troubleshooting on the cluster</summary>

The application does not run at all. So we can check the pods status.
<code>kubectl get pods</code> does not show any pods

We need to check the deployment status with <code>kubectl get deploy</code>
We see that deploy *k8s-api-client* has 0 pods in status Ready
Inspect the deployment with 

<code>kubectl get deploy -o yaml > dep.yaml</code>

The yaml shows the error clearly 

```
 message: 'pods "k8s-api-client-8cbbc4fd8-" is forbidden: error looking up service
      account default/k8s-api-client: serviceaccount "k8s-api-client" not found'

```
so we need to create service account k8s-api-client in default namespace

<code>kubectl create sa  k8s-api-client</code>

Now let's check what is happening with our deployment

<code>kubectl rollout restart deploy/k8s-api-client</code>

Now if we check the deployment, the pod is in state Running. One problem solved.
If we check in browser - the app is running, but if we click Pods, we get error 

```
pods is forbidden: User "system:serviceaccount:default:k8s-api-client" cannot list resource "pods" in API group "" in the namespace "default"
```
Clearly, our new service account lacks the necessary permissions to list pods. To confirm this,
we can run

<code>kubectl auth can-i --list --as system:serviceaccount:default:k8s-api-client</code>

To fix this, we need to create role and rolebinding for the SA

```
kubectl create role k8s-api-client --verb=get --verb=list --verb=watch --resource=pods
kubectl create rolebinding k8s-api-client-binding --role=k8s-api-client --serviceaccount=default:k8s-api-client
```

</details>


