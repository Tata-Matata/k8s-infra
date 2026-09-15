### Basic idea

<details>
<summary>Answer</summary>

run this command with another user's privileges. Not necessarily root

<code>sudo -u postgres psql</code>

This runs psql as the postgres user.

If not otherwise specified, runs as root but the user doesn't become root permanently. Only that command runs with elevated privileges.


</details>

### How to interpret rules in /etc/sudoers

<details>
<summary>Answer</summary>

```

root    ALL=(ALL:ALL) ALL
%sudo   ALL=(ALL:ALL) ALL

```

1. who the rule applies to (root in first line, group sudo in second)
2. ALL= hosts where user can perform privilege escalation
3. (ALL:ALL) may run as any user and any group
4. ALL may run any command

So the first line means: root  may run any command as any user/group from any host.


##### a more restricted example

```

alice ALL=(root) /usr/bin/systemctl restart nginx

```

alice can use sudo specifically to restart nginx, rather than having unrestricted root access.

</details>

### Update user bob so that it can run sudo commands without entering the sudo password

<details>
<summary>Answer</summary>

```
vi /etc/sudoers

jim  ALL=(ALL) NOPASSWD:ALL

```

NOPASSWD: is appended to the last part that specifies the command

</details>


### Check what your current user is allowed to run through sudo

<details>
<summary>Answer</summary>

```
sudo -l

```

For another user

```
sudo -l -U alice
```


</details>

### Check who can use sudo

<details>
<summary>Answer</summary>

```
getent group sudo
sudo visudo

```

</details>

### Run something as a particular user or group

<details>
<summary>Answer</summary>

```

sudo -u alice whoami
sudo -g docker command

```

</details>

### Get a root shell

<details>
<summary>Answer</summary>

```
sudo -i

```
This gives you a root login shell.

You'll typically get:

```
root@server:~#

```

Another way:

```
sudo -s
```

This gives you a root shell while preserving more of your current shell environment.

</details>

### sudo and environment variables

<details>
<summary>Answer</summary>


<code>echo $HOME</code> gives: /home/alice

But:

<code>sudo sh -c 'echo $HOME'</code> may give: /root

because the command is running with root's environment.

Likewise: <code>sudo env</code>  can show you the environment available to the elevated process.


</details>


### sudoers.d

<details>
<summary>Answer</summary>


Instead of putting everything into **/etc/sudoers**, it is common to create separate files:

<code>/etc/sudoers.d/myapp</code>

For example:

<code>deploy ALL=(root) /usr/bin/systemctl restart myapp</code>

**Permissions matter** 

Typically: <code>udo chmod 440 /etc/sudoers.d/myapp</code>


</details>


### Validate sudo config file

<details>
<summary>Answer</summary>


<code>sudo visudo -cf /etc/sudoers.d/myapp</code>

</details>