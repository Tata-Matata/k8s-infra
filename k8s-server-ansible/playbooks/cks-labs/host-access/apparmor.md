### What is it for?

<details>
<summary>Answer</summary>

A Linux kernel security mechanism that allows you to restrict access to resources for a **process**, things like:

- may read /etc/resolv.conf
- may write to /var/log/myapp.log
- may execute /usr/bin/curl
- may not access /etc/shadow
- may not write to /etc
- may not access /proc/...
- may not use certain capabilities

AppArmor itself is implemented through the Linux kernel's LSM (Linux Security Modules) framework. Other security mechanisms that use LSM include SELinux.

If the process attempts an operation prohibited by the profile, the kernel can deny it. The application doesn't get to bypass this simply because it runs as UID 0.

</details>


### AppArmor vs Linux permissions

<details>
<summary>Answer</summary>

*Linux file permissions*: Who can access a file?  identity-based
*AppArmor*: What is a particular program allowed to do? program/process-based

Two processes running as the same Unix user can have different capabilities under AppArmor.

#### Example

Suppose you have **/etc/shadow** with:

<code> -rw-r----- 1 root shadow /etc/shadow </code>

Normal permissions say: Only root and members of shadow can read this file.

Now imagine your **web server** runs as **root** — or somehow has sufficient privileges. Linux permissions might allow it to read /etc/shadow. 

But you can create an **AppArmor profile **saying:

```
/usr/sbin/nginx {
    /var/www/** r,
    /etc/nginx/** r,
    /etc/shadow deny,
}

```

Now AppArmor says: Regardless of the Unix permissions, nginx is not allowed to read /etc/shadow.

#### Attack context

Say, nginx has vulnerability that an attacker takes advantage of and executes code as nginx.
The attacker now effectively has whatever access nginx has.

If nginx is allowed by Unix permissions to read:

```
/etc/passwd
/etc/hosts
/home/user/.ssh/...
/var/www/...
```


then the compromised process may be able to read those things. AppArmor adds another layer:
Even if the process has the Unix permissions necessary, AppArmor can say: DENY


</details>

### Profiles

<details>
<summary>Answer</summary>

A profile is essentially a set of rules associated with a program.

```
profile myapp {
    /usr/bin/myapp rix,
    /app/** r,
    /var/log/myapp.log w,
    /etc/shadow r,
}

```

</details>

### Modes

<details>
<summary>Answer</summary>

AppArmor profiles can operate in different modes.

**Enforce**: Violations are blocked.
**Complain**: Violations are logged, but not necessarily blocked.   This is useful when developing a profile.
**unconfined**: The process is not restricted by an AppArmor profile.

</details>


### Check whether the kernel has AppArmor enabled

<details>
<summary>Answer</summary>

<code>cat /sys/module/apparmor/parameters/enabled</code>

contains Y if enabled

we can also check the service status with systemctl

<code>sudo systemctl status apparmor</code>

</details>

### Check loaded profiles and their status

<details>
<summary>Answer</summary>

<code>sudo aa-status</code>
<code>cat /sys/kernel/security/apparmor/profiles</code>

The files themselves can be inspected under <code>/etc/apparmor.d/ </code> directory

</details>


### How do you test that AppArmor actually blocks something inside container?

<details>
<summary>Answer</summary>

Suppose your profile says:

<code>/etc/shadow r</code>

Then inside the container: <code>cat /etc/shadow</code> should fail

Then check the kernel logs:

<code> sudo journalctl -k | grep -i apparmor </code>

You can see denial events.


</details>

### How do you see whether your container is using AppArmor?

<details>
<summary>Answer</summary>

Inside the container

<code>cat /proc/self/attr/current</code>

For a process under an AppArmor profile you may see something like:

myapp-profile (enforce)


</details>


### in K8s

<details>
<summary>Answer</summary>

```
securityContext:
  appArmorProfile:
    type: Localhost
    localhostProfile: myapp-profile

```

The profile must already be **loaded into the kernel** on each node before the container starts!!!
(s. below)

Just placing the file into the specified path does not suffice.


</details>

### Generate and load AppArmor profile interactively

<details>
<summary>Answer</summary>

#### Install AppArmor utilities

<code>apt install apparmor-utils</code>

#### Generate profile 

**aa-genprof** helps you create an AppArmor profile for an application by observing what the application does.

<code>sudo aa-genprof /usr/bin/myapp</code>

It puts the application under AppArmor observation and lets you exercise the application.

Suppose your application does:

```
read /etc/myapp.conf
read /app/data
write /var/log/myapp.log
execute /usr/bin/foo
```

AppArmor records these accesses. **aa-genprof** then presents you with events and asks whether they should be allowed.

#### Load profile

suppose you create: **/etc/apparmor.d/myapp** containing your profile.

You can load it with:

<code> sudo apparmor_parser -r /etc/apparmor.d/myapp </code>

-r means replace an existing profile.

#### Check

<code> sudo aa-status </code>

</details>