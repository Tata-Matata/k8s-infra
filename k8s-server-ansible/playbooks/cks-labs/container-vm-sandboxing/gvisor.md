### Container isolation


<details>
<summary>Answer</summary>

gVisor enhances container isolation by putting an extra kernel-like security boundary between the container and the host Linux kernel.

**Normal containers** share the host kernel. Namespaces, cgroups, capabilities, seccomp, AppArmor, etc. restrict what the container can do, but the container still interacts with the host kernel.

```
container process
      │
      │ open("/data/file")
      ▼
host Linux kernel
      │
      ▼
host filesystem / devices

```

This means a serious vulnerability in the kernel code reachable from a container could potentially become a container escape.


gVisor intercepts most of the container's system calls and handles them in a **user-space "sandbox kernel"** instead of letting the container talk directly to the host kernel.
So if the application does: open("/data/file", ...), the syscall doesn't simply become a normal host-kernel filesystem operation.

Instead, gVisor's Sentry component implements the relevant Linux kernel behavior in user space.

```
cat
 ↓
syscall
 ↓
gVisor Sentry
 ↓
gVisor implements the operation
 ↓
possibly host syscall(s)
 ↓
host Linux kernel

```

So gVisor doesn't eliminate the host kernel. It reduces the amount of direct interaction between the workload and the host kernel. Therefore, an attacker who compromises an application has to get through another security boundary before reaching the host kernel.


</details>

### In K8s

<details>
<summary>Answer</summary>

You might use gVisor for workloads where a container escape would be particularly concerning, such as running third-party code, user-submitted code, or less-trusted workloads.

1. Install gVisor on a node
After that, a Kubernetes node is configured with a gVisor runtime handler, commonly called **runsc**. So the node can support both ordinary containers and gVisor-sandboxed containers.

2. Create a RuntimeClass

This tells Kubernetes: "When a Pod requests runtimeClassName: gvisor, use the runsc runtime handler."

```
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
```

3. Use in a pod

```
apiVersion: v1
kind: Pod
metadata:
  name: untrusted-app
spec:
  runtimeClassName: gvisor

  containers:
    - name: app
      image: nginx
```

</details>