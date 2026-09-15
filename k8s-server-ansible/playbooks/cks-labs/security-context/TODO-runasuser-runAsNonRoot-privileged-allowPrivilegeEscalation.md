## runAsUser	and runAsNonRoot

<details>
<summary>Answer</summary>

Who am I?

**runAsUser: 0** makes the process UID 0 (root), but it does not necessarily give it unrestricted power. Its Linux capabilities can still be reduced, and AppArmor/seccomp can still restrict it.

**default runAsUser if not specified is root!**
And if we do not set explicitly **hostUsers: false** then hostUsers defaults to true. The Pod uses the host user namespace. So that container's root is host root. (Unless the image contains USER 1000)

Check and investigate more details - s. map-uid-to-host.md

**runAsNonRoot: true** means essentially: "The container's process must not run with UID 0."

So this is fine:

```
runAsUser: 1000
runAsNonRoot: true
```

while this is rejected because the process would be root:

```
runAsUser: 0
runAsNonRoot: true
```
</details>


## capabilities	

<details>
<summary>Answer</summary>
What privileged operations can I perform?

Can be set only under securityContext of container! not in pod spec

```
spec:
  containers:
    - name: app
      image: nginx
      securityContext:
        runAsUser: 1000
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
          add:
            - NET_BIND_SERVICE

```
drop: ALL  = remove all Linux capabilities
give the process only CAP_NET_BIND_SERVICE

Normally, Linux prevents a non-root process from binding to ports below 1024. With this capability, a non-root process can, for example, bind to port 80:

#### verify capabilities inside the container with:

<details>
<summary>Answer</summary>

```
kubectl exec capabilities-demo -- cat /proc/1/status | grep Cap
```

</details>

</details>

## allowPrivilegeEscalation	

<details>
<summary>Answer</summary>

Can the process acquire **additional privileges beyond its current permitted set** - through Linux mechanisms such as **setuid/setgid** binaries or **file capabilities**.

The important thing is that this doesn't remove privileges the process already has.
So for example, if **privileged: true** - this has already requested a highly privileged container configuration. So don't use **allowPrivilegeEscalation : false** as a replacement for privileged: false.



#### K8s context 
https://kubernetes.io/docs/tasks/configure-pod-container/security-context/?utm_source=chatgpt.com#set-the-security-context-for-a-container

#### Example

Suppose you start with:

```
securityContext:
  runAsUser: 1000
  allowPrivilegeEscalation: false
```

The process starts as UID = 1000 and **allowPrivilegeEscalation: false** means it cannot use mechanisms such as a setuid-root executable to turn itself into UID 0.

#### The underlying Linux mechanism 

<details>
<summary>Answer</summary>

PR_SET_NO_NEW_PRIVS, documented by the Linux kernel:
https://docs.kernel.org/userspace-api/no_new_privs.html

You can see it from inside a container with:

<code>cat /proc/self/status | grep NoNewPrivs</code>

For example:

<code>NoNewPrivs:  1 </code>

means the process has no_new_privs enabled.

</details>

#### setuid/setgid bits

<details>
<summary>Answer</summary>

Normally, when a process executes a file: 

process with real UID = alice and effective UID = alice -->    exec() --> program with  real UID = alice
and effective UID = alice

But suppose an executable is owned by root and has the setuid bit:

```
ls -l /usr/bin/some-program
-rwsr-xr-x 1 root root ... /usr/bin/some-program
```
The s in the owner's x position means setuid.

When Alice executes it, alice process  exec("/usr/bin/some-program") --> kernel sees:
    owner = root
    setuid = enabled
    
new process credentials:
    real UID      = alice
    effective UID = root

So the process has gained a new privilege: its effective UID is now root.

setgid - the same idea applied to groups.

```
-rwxr-sr-x root secret-group program
```

**passwd** is a classic example of a setuid-root program. Because it needs to modify password-related data that ordinary users aren't allowed to modify directly, traditionally /etc/shadow.

</details>

#### File capabilities

<details>
<summary>Answer</summary>
you can configure an executable to grant a particular capability.

```
sudo setcap cap_net_raw+ep ./my-program
getcap ./my-program
//./my-program cap_net_raw=ep
```

Now when a process executes that file, the kernel incorporates the file's capabilities into the process's capability set.
alice  exec(my-program) --> kernel -->  file has CAP_NET_RAW --> process CAP_NET_RAW

The process is still UID 1000. It did not become root. But it has acquired a specific privileged operation represented by CAP_NET_RAW. For example, this capability can permit operations involving raw/packet sockets that an ordinary unprivileged process normally cannot perform.

</details>

</details>

## privileged	

<details>
<summary>Answer</summary>

How much of the container isolation do I remove? Run the container in privileged mode.

it gives the container access to a much broader set of Linux capabilities and devices and disables/reduces several runtime security restrictions.

Kubernetes places restrictions around combining **privileged** with **user namespaces**. In particular, a privileged container cannot currently be used with **hostUsers: false** in the normal Kubernetes Pod user-namespace model.

privileged: true is primarily implemented by the container runtime/OCI runtime (runc, crun...)

A privileged container generally gets things such as:

- a broad/full capability set
- access to host devices
- relaxed device cgroup restrictions
- fewer restrictions imposed by the runtime
- security mechanisms such as seccomp/AppArmor may be disabled or bypassed depending on runtime/configuration
- other namespace/isolation restrictions are relaxed
  
https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1

https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

https://github.com/opencontainers/runtime-spec/blob/main/config-linux.md


</details>

## Example

```
securityContext:
  runAsUser: 1000
  privileged: false
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

gives you process with UID 1000  that:

- starts without capabilities
- cannot use setuid/file-capability mechanisms to gain new privileges
- is not a privileged container