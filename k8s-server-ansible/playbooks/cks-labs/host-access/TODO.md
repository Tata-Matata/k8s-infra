## Tracee

In production, you'd normally deploy it continuously on every node, collect its events, and send the useful ones into your security/observability pipeline. Daemonset

Labs:

- "Did somebody execute a shell inside a container?"
- "Did a container suddenly execute a suspicious binary?"

container: payments
execve("/tmp/x")

- "Did something attempt privilege escalation?"
setuid()
setgid()
capset()

- "Did a container attempt to access something unusual?"

/etc/shadow
/proc/...
/var/run/docker.sock


- "Did something attempt kernel/container escape techniques?"

You can monitor suspicious activity involving things such as:

ptrace
mount
unshare
setns
namespace operations
capabilities
kernel modules

- "Tell me when something looks suspicious."
Instead of receiving millions of raw events, Tracee can identify security-relevant behaviors.
You want something more like:

CRITICAL

Container attempted to access host filesystem

namespace: production
pod: payments-6c7...
container: payments
process: /bin/bash
event: ...

- Where does the output go?

Prometheus/Grafana/OpenSearch.
**Metrics** are good for:

number of security events
events per node
events per namespace
Tracee health

**Security** events

Tracee JSON events --> log/event pipeline --> Vector parse Tracee's JSON? --> OpenSearch --> OpenSearch Dashboards

Vector can:

parse Tracee's JSON
enrich events
filter noise
transform fields
route different event types
buffer events
send them to OpenSearch

OpenSearch - Dashboards

Security Events
────────────────────────────────

Events today                    1,284

Critical                           2
High                              17
Medium                           143

Top namespaces

production                       723
monitoring                       312
kube-system                      181
default                           68

Suspicious container behavior

┌─────────────────────────────────────────┐
│ Container       Event          Severity │
├─────────────────────────────────────────┤
│ backend          ptrace          HIGH   │
│ payments         shell           HIGH   │
│ frontend         /tmp/x          CRIT   │
│ worker           mount           HIGH   │





2. seccomp amicontained RuntimeDefault  and Unconfined, custom Localhost profile
Compare output
It's especially nice because you can change the Pod's security context and observe the difference.

For example:

securityContext:
  seccompProfile:
    type: RuntimeDefault

versus:

securityContext:
  seccompProfile:
    type: Unconfined

Then run amicontained in each and compare what it reports.



3. apparmor profiles
Check whether AppArmor is enabled on your worker.
Create a tiny AppArmor profile.
Load it on the worker.
Run a pod using localhost/my-profile.
Verify /proc/self/attr/current.
Attempt an operation explicitly denied by the profile.
Observe the Permission denied.
Check the kernel/AppArmor logs.
Compare the experiment with a seccomp profile denying a syscall.

4. simple lab - misconfigured sudoers - the intention was to add group but missing % adds user
%admin ALL=(ALL) ALL 

1. the task is to configure ssh login from say root on host1 to user bob on host2. (ssh-keygen, ssh-copy-id). Only after accomplishing all this, it turns out that the login doesnt work, because bob has /usr/sbin/nologin as their shell