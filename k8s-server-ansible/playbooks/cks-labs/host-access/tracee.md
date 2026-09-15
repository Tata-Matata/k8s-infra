### Tracee vs strace

<details>
<summary>Answer</summary>

Tracee can see activity from many processes/containers on a node simultaneously.

strace is extremely useful, but its basic model is attaching to **one process**

Tracee is much more suited to: "Tell me what is happening across this Linux system, including containers, and alert me when interesting security events occur."

Suppose a container executes <code> curl http://evil.example </code>

With strace, you'd have to know which process to trace: <code> sudo strace -p <PID> </code> and then interpret its syscalls.

With Tracee, you can ask for events such as:

<code>  sudo tracee --trace event=execve </code>

and observe process execution across the system.

More importantly, Tracee can enrich kernel events with **container/Kubernetes context.** You can get information like:

- container
- pod
- namespace
- process
- executable
- user
- syscall
- network connection

Imagine you have:

Node
├── nginx pod
├── frontend pod
├── backend pod
├── database pod
└── kube-system pods

You don't want to manually:

```
strace -p PID1
strace -p PID2
strace -p PID3
```

An eBPF-based security tool can sit at the node/kernel level and observe activity from containers as they come and go.


</details>

### How Tracee traces

<details>
<summary>Answer</summary>

It uses **eBPF** programs attached to kernel hooks to observe events such as:

- syscalls
- process execution (execve)
- file access
- network activity
- privilege changes
- namespace operations
- container-related activity
- suspicious kernel behavior

#### eBPF

Extended Berkeley Packet Filter lets you run small programs inside the Linux kernel at specific **hook** **points**, without modifying/recompiling the kernel. It has become a general **kernel instrumentation** mechanism.

eBPF gives **user-space** applications a programmable way to **observe** and influence **kernel** behavior.

You can essentially say: "When this particular kernel event happens, execute this small program and give me some information about it."

##### eBPF programs run in the kernel

The eBPF program is not a normal user-space process. It executes in kernel context. That sounds dangerous — and it would be if arbitrary programs could simply execute kernel code. That's why Linux has an eBPF verifier.

The verifier performs static analysis to ensure the program satisfies various safety constraints.

For example, it needs to prevent things like arbitrary kernel memory access


##### eBPF programs are attached to hooks

There are many possible hook types:
- Tracepoints (instrumentation points provided by the kernel)
- kprobes (You can instrument kernel functions)
- uprobes (user-space functions)
- Network hooks (Tools such as Cilium use eBPF extensively for Kubernetes networking)

Suppose we want to observe every process execution. Conceptually, we'd attach an eBPF program to tracepoint
*sys_enter_execve*

When somebody runs */usr/bin/curl* the kernel reaches the syscall *execve("/usr/bin/curl", ...)* and *sys_enter_execve* 

You can then get something like:

```
PID=3812
UID=1000
COMMAND=curl
PATH=/usr/bin/curl
```

</details>

### See available events

<details>
<summary>Answer</summary>


<code> tracee --events list </code>

</details>

### Trace a particular event

<details>
<summary>Answer</summary>


<code> sudo tracee --trace event=execve </code>

##### Events

- execve
- openat
- connect
- ptrace
- setuid
- setgid
- mount
- unshare
- clone

</details>



