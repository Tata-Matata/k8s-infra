https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/?utm_source=chatgpt.com

https://v1-33.docs.kubernetes.io/docs/tasks/configure-pod-container/user-namespaces/?utm_source=chatgpt.com



Without a user namespace, **container root is root on the node in the event of a container breakout**; with a user namespace, container root is mapped to an unprivileged host user.


If you want to guarantee that container UID 0 is never host UID 0, you need to run the Pod in a Linux user namespace. Merely setting runAsUser, runAsNonRoot, or Linux permissions does not provide that guarantee.

**hostUsers: false**

Do not put this Pod in the host's user namespace. Create a new user namespace for it.
Kubernetes then arranges a mapping such that the container's UID 0 is mapped to a non-zero host UID. Kubernetes specifically says the kubelet selects the host UID/GID mappings and guarantees that mappings don't overlap between Pods on the same node. The actual host UID range is selected by Kubernetes; you don't manually choose "100000" in the Pod manifest.

```
apiVersion: v1
kind: Pod
metadata:
  name: test
spec:
  hostUsers: false
  containers:
    - name: test
      image: ubuntu
      command: ["sleep", "infinity"]
      securityContext:
        runAsUser: 0

```

So if your threat model is:

"A container might get compromised and exploit a container-runtime/kernel vulnerability to escape."

then running container root in the host user namespace means a successful escape can result in host-root privileges.

### How do you verify that it actually happened?

```
kubectl exec -it test -- bash
cat /proc/self/uid_map
```


You should see something conceptually like:

         0      100000      65536

You can also verify that you're in a different user namespace:

```
readlink /proc/self/ns/user
```