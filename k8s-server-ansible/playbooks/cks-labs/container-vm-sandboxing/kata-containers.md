### Container isolation


<details>
<summary>Answer</summary>

**Normal containers** share the host kernel. Namespaces, cgroups, capabilities, seccomp, AppArmor, etc. restrict what the container can do, but the kernel itself is shared.

With Kata Containers:


```
Pod
 │
 └── Kata container
       │
       ↓
   Guest Linux kernel
       │
       ↓
   Virtual hardware
       │
       ↓
   Hypervisor
       │
       ↓
   Host Linux kernel

```

Each pod/container workload runs inside a lightweight VM with its own guest kernel. A hypervisor provides the VM boundary. So unlike normal containers and gvisor, Kata needs a **hypervisor**, unlike gvisor and normal containers

TO DO: The hypervisor is for the standard Kata architecture, but Kata supports different virtualization technologies depending on the platform/configuration (e.g. QEMU, Cloud Hypervisor).


#### Why this improves isolation

Suppose a process inside the container executes:

open("/etc/passwd")

With a normal container:


```
container process
      ↓ syscall
HOST Linux kernel

```

The host kernel directly handles the syscall.

With Kata:

```
container process
      ↓ syscall
GUEST Linux kernel
      ↓
virtual hardware
      ↓
hypervisor
      ↓
HOST

```

The workload is therefore separated from the host kernel by a VM boundary.


</details>

### Why would you use Kata?

<details>
<summary>Answer</summary>

Imagine you're running an untrusted workload:

Kubernetes
   │
   ├── trusted workloads
   │
   └── potentially malicious workload
             ↓
        Kata container
             ↓
        lightweight VM

If the workload manages to exploit a vulnerability in its guest kernel, it still has to get through the hypervisor/VM boundary to attack the host.

</details>

### Kata in K8s cluster

<details>
<summary>Answer</summary>

1. Install/configure Kata on a node
The container runtime (typically containerd) is configured with a Kata runtime handler, commonly called something like **kata**

2. Create a RuntimeClass

```
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: kata
handler: kata

```

3. Use in pod

```
apiVersion: v1
kind: Pod
metadata:
  name: untrusted-workload
spec:
  runtimeClassName: kata

  containers:
    - name: app
      image: nginx
```

</details>

### containerd and different runtimes

<details>
<summary>Answer</summary>
containerd is the higher-level container runtime that Kubernetes talks to.

In a Kubernetes cluster with multiple RuntimeClasses, containerd is configured with multiple runtime handlers, and Kubernetes tells containerd which handler to use for a Pod.


Kubernetes
    │
    │ Pod runtimeClassName
    ▼
containerd
    │
    ├── runc  ──→ normal Linux container
    │
    ├── runsc ──→ gVisor
    │              └─ Sentry
    │
    └── kata  ──→ Kata VM
                   └─ hypervisor


</details>