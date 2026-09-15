### Disable ssh root login and password authentication

<details>
<summary>Answer</summary>

```
vi /etc/ssh/sshd_config

PermitRootLogin no
PasswordAuthentication no

```

</details>