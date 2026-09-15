### Capabilities vs AppArmor vs seccomp vs Linux permissions

<details>
<summary>Answer</summary>

Capabilities are basically the third layer in the Linux security picture alongside AppArmor and seccomp.


**Capabilities** = what privileged powers a process has
**AppArmor** = what a process is allowed to do to files/resources
**seccomp** = which syscalls a process is allowed to invoke


Traditionally, Linux has roughly: UID 0 (root) = lots of privileged operations
Capabilities break up the enormous power of root into smaller pieces.

```
CAP_NET_ADMIN
CAP_NET_RAW
CAP_SYS_ADMIN
CAP_CHOWN
CAP_DAC_OVERRIDE
CAP_KILL
```

So you can have:

process
  ├── CAP_NET_RAW
  └── no other special capabilities

That process can perform operations associated with CAP_NET_RAW, but doesn't automatically get all the powers of root.

#### Example with AppArmor and Linux permissions

Imagine a container wants to read: /etc/shadow

**Linux permissions**

Does the process have ordinary Unix permission to read it?

For example:

-rw-r----- root shadow /etc/shadow

**Capabilities**

Then capabilities can give a process additional privileges.

For example: CAP_DAC_OVERRIDE (Discretionary Access Control) can allow a process to bypass certain ordinary file permission checks. A normal user can't read that file.A process possessing CAP_DAC_OVERRIDE can bypass most of these read/write/execute permission checks.

So capabilities can effectively say: "This process has the power to bypass this particular type of restriction."

**AppArmor**

AppArmor can then say: "Even though you have that capability, this particular process is not allowed to read /etc/shadow."


</details>


### In K8s

<details>
<summary>Answer</summary>

```

securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - NET_RAW

```

Give this container the specific Linux capability CAP_NET_RAW, but don't give it the other capabilities.
This is useful for things such as operations involving raw network packets.
For ex., ping historically needed the ability to create raw ICMP packets. That's associated with: CAP_NET_RAW


</details>

### Check capabilities attached to executable

<details>
<summary>Answer</summary>

<code> getcap /usr/bin/ping </code>

/usr/bin/ping cap_net_raw=ep

This means the executable file itself has a file capability.

</details>

### Find executables on the system with special capabilities 

<details>
<summary>Answer</summary>

<code> sudo getcap -r / 2>/dev/null </code>

useful for security auditing

</details>

### Check capabilities of the running process

<details>
<summary>Answer</summary>

<code> getpcaps <PID> </code>
<code> getpcaps $(pgrep nginx) </code>

</details>
