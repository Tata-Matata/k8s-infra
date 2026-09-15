## Run 03-lab-fix-abac playbook

The playbook creates SA **abac** and configures ABAC authorization in kube-apiserver, but API server is not responding after the changes (if you run the playbook and kubectl still responds, wait about a minute for the API server static pod to be recreated. The lab starts with API server being down)

The ABAC policy gives the SA **abac** permission to list deployments

Initial API server manifest file (before ABAC changes) is backed up at /root/labs/abac/kube-apiserver-backup.yaml
**crictl** and **jq** are available on the host


IMPORTANT NOTE: there are several issues to be fixed, so once you get API server up and running again,
check if SA abac can get deployments.

## Fix the cluster and ABAC

<details>
<summary>Show answer</summary>

If we run <code>kubectl get pods</code> - we get error, so we need to figure out what is wrong with API server.

One way to do it is to inspect kubelet logs with <code>journalctl -u kubelet -f</code>
However, kubelet logs are quite noisy. There are a lot of entries that describe consequences of the disaster, not the initial failure.

We can use crictl to inspect the pod logs instead


```
crictl ps -a | grep -i kube-api
crictl logs <id>
```

The output is very clear

```
 err="invalid authorization config: open /root/labs/abac/abac.jsonl: no such file or directory"
```

<code>ls /root/labs/abac/abac.jsonl</code> shows that the file exists on the host.
But it has to be mounted inside the pod. So we need to inspect kube-apiserver static pod manifest file. 

If we don't remember the path 

1. check where kubelet config is <code> ps aux | grep '[k]ubelet'</code>
   For example: --config=/var/lib/kubelet/config.yaml

2. <code>grep -i staticPodPath /var/lib/kubelet/config.yaml</code> will show the manifests folder
   

In /etc/kubernetes/manifests/kube-apiserver.yaml we see that 


```
        - --authorization-mode=Node,RBAC,ABAC
        - --authorization-policy-file=/root/labs/abac/abac.jsonl

```

But there is not volume mount to support the abac.jsonl

We need to add the volume to volumes list

```
 - hostPath:
      path: /root/labs/abac/abac.jsonl
      type: File
   name: abac
```

And volumeMount inside container section

```
- mountPath: /root/labs/abac/abac.jsonl
  name: abac
  readOnly: true
```

Save the file and wait for the pod to be recreated.
Unfortunately, the server crushes again. 

```
crictl ps -a | grep -i kube-api
crictl logs <id>
```

shows again a very clear message: 

```
"command failed" err="invalid authorization config: error reading policy file /root/labs/abac/abac.jsonl, line 1: {\"apiVersion\":\"abac.authorization.kubernetes.io/v1beta1\",\"kind\":\"Policy\",\"spec\":{\"user\":\"system:serviceaccount:default:abac\",\"namespace\":\"default\",\"resource\":\"deployments\",\"apiGroup\":\"\",\"verb\":\"get\"}: couldn't get version/kind; json parse error: unexpected end of JSON input"
```

Something is structurally wrong with the jsonl file. We can inspect it with <code>jq -e . /root/labs/abac/abac.jsonl >/dev/null</code> 

```
Unfinished JSON term at EOF at line 1, column 199
```

gives us a hint and we can find the missing closing bracket } at the end of the line

Now we need to wait until the pod is recreated again. (crictl ps -a | grep -i kube-api)
This time, the new API server pod is running successfully. And we can check if ABAC policy really works

<code>kubectl auth can-i --as system:serviceaccount:default:abac list deploy</code>

no - No policy matched.

So something is not configured right in the jsonl Policy. The user, namespace, resource all seem to be correct, but the apiGroup "" is the core api group. We need to check if it is correct for deployments

<code>kubectl api-resources | grep -i deploy</code>
The apiGroup is **apps**, not "", so we need to change the jsonl and restart the API server static pod again

Now <code>kubectl auth can-i --as system:serviceaccount:default:abac list deploy</code> returns yes


</details>