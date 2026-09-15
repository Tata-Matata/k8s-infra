### install ufw, check status

<details>
<summary>Answer</summary>

```
apt install ufw
systemctl status ufw
```

</details>

### display the rules along with rule numbers next to each rule

<details>
<summary>Answer</summary>

```
ufw status numbered
```

it also helps to run 

```
ufw status verbose
```

</details>

### allow a tcp port range between 80 and 8080

<details>
<summary>Answer</summary>

```
 ufw allow 80:8080/tcp
```
ufw allow by default refers to incoming connections. We can specify explicitly

```
 ufw allow in 80:8080/tcp
```

for outgoing connections - ufw allow out

</details>

### reset ufw rules to their default settings

<details>
<summary>Answer</summary>

```
  ufw reset
```

</details>

### allow incoming SSH connections

<details>
<summary>Answer</summary>

```
  ufw allow 22
```

</details>

### allow  or deny all incoming connections

<details>
<summary>Answer</summary>

This is useful if we want to allow or deny connections to all ports and then create explicit rules for specific ports

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

</details>

### allow incoming connection on ports 9090 and 9091 from IP range 152.20.65.0/24 to any interface. Enable the firewall.

<details>
<summary>Answer</summary>

```
ufw allow  from 152.20.65.0/24 to any port 9090 proto tcp
ufw allow  from 152.20.65.0/24 to any port 9091 proto tcp
ufw  enable
```

</details>


### Disable port 80 for ALL incoming requests
<details>
<summary>Answer</summary>

```
 ufw deny 80
```

</details>

### Temporarily disable ufw firewall but make sure to preserve all rules so that these can be effective when we enable firewall again
<details>
<summary>Answer</summary>

```
ufw disable
```
This will temporarily disable the firewall but the old rules are still maintained.

</details>


### What to be aware of when enabling ufw

<details>
<summary>Answer</summary>

**ufw enable** means: Turn on the firewall and start enforcing the UFW rules. But you can add rules after ufw enable as well.

#### What to be careful about

Imagine you're connected to a remote server via SSH: ssh user@server

Then you do: **ufw enable**

If UFW's incoming policy is *deny*, but you haven't allowed SSH yet, your SSH connection can be blocked.

The safer sequence is:

```
sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw enable

```

Now when UFW is activated:

SSH → allowed
HTTP → allowed
HTTPS → allowed
everything else incoming →  denied
outgoing →  allowed



</details>


### Delete a rule

<details>
<summary>Answer</summary>

1. Delete by repeating the rule with delete

If you have:

```
sudo ufw allow 22/tcp
```

delete it with:

```
sudo ufw delete allow 22/tcp
```

2. Delete by rule number

```
sudo ufw status numbered

[ 1] 22/tcp    ALLOW IN    Anywhere
[ 2] 80/tcp    ALLOW IN    Anywhere
[ 3] 443/tcp   ALLOW IN    Anywhere

sudo ufw delete 2

```





</details>