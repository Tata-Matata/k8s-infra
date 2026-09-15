### Seccomp

<details>
<summary>Answer</summary>

secure computing mode restricts which Linux syscalls a process is allowed to make.

Application
    ↓
libc / runtime
    ↓
syscall()
    ↓
Linux kernel

Seccomp can prevent the process from making a certain syscall.

The same for container process. A container process is using the host's Linux kernel.
If an application is compromised, you don't necessarily want it to have access to every syscall the kernel exposes.

</details>

### What happens when a syscall is blocked?

<details>
<summary>Answer</summary>

#### SCMP_ACT_ERRNO

The syscall fails and the application receives an error. The application might see something like: mount: Operation not permitted


#### SCMP_ACT_KILL

The process is terminated.


There are other actions such as TRAP, LOG, NOTIFY

</details>


### Check if seccomp supported by kernel

<details>
<summary>Answer</summary>

grep -i seccomp /boot/config-$(uname -r)

CONFIG_SECCOMP=y

</details>


### Docker and seccomp


<details>
<summary>Answer</summary>

Docker has historically shipped with a default seccomp profile.
So if you run: docker run nginx, Docker doesn't simply give nginx unrestricted access to all syscalls.
Docker applies its default seccomp profile.

##### You can explicitly specify a profile: 

```
docker run \
  --security-opt seccomp=/path/profile.json \
  nginx

```

##### You can disable seccomp

Use only for debugging, not in production

```
docker run \
  --security-opt seccomp=unconfined \
  nginx

```

</details>

### How do you see seccomp filter for a process?

<details>
<summary>Answer</summary>

<code>grep Seccomp /proc/1/status</code>

1 here is PID (on the host that would likely be systemd, inside container - its main process, for ex., nginx. The container has its own PID namespace.)

This output means: filter seccomp mode (2). It doesn't by itself tell you which profile is being used.

```
Seccomp:        2
Seccomp_filters: 1

```

0 = disabled. 1 = strict

</details>


### Seccomp in Kubernetes

<details>
<summary>Answer</summary>

Kubernetes isn't itself implementing syscall filtering.
It is specifying the desired security configuration, which the runtime applies.
The runtime ultimately implements the seccomp restriction at the Linux kernel level.

#### Pod/container security-context level

1. Use the container runtime's default seccomp profile.

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx
```

2. Use custom profile installed on the node

```
spec:
  securityContext:
    seccompProfile:
        type: Localhost
        localhostProfile: profiles/my-profile.json
  containers:
  - name: nginx
    image: nginx
```
Pod --> Kubelet --> container runtime --> /var/lib/kubelet/seccomp/...  --> custom JSON profile

The path is relative to the kubelet's seccomp profile directory. Conventionally, that's: 

**/var/lib/kubelet/seccomp/**

The file must be available on the node.

3. Unconfined

```
spec:
  securityContext:
    seccompProfile:
        type: Unconfined

```

</details>


### Custom Kubernetes profile

<details>
<summary>Answer</summary>

Can be white list or black list.

##### White list

Default action is deny, and then specific syscalls are allowed

```
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "syscalls": [
    {
      "names": [
        "read",
        "write",
        "exit",
        "exit_group",
        "openat"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}

```

</details>

### Writing your own profile

<details>
<summary>Answer</summary>

Applications use many syscalls.

Different libraries, runtimes, architectures, application features, kernel versions can change syscall requirements. 
That's why **RuntimeDefault** is often preferable unless you have a concrete reason to maintain a custom profile. Then we can observe workload, identify syscalls, create custom profile and test it. 

</details>

### Diagnostic/learning tool for seccomp

<details>
<summary>Answer</summary>

 "What restrictions actually apply to the container?"
 
```
kubectl run amicontained \
  --image jess/amicontained \
  amicontained -- amicontained

kubectl logs amicontained

```

It examines things such as:

- Linux namespaces
- capabilities
- seccomp
- AppArmor
- whether you're root
- other container isolation/security properties
 

</details>