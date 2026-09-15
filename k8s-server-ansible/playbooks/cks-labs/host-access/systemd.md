### List services

<details>
<summary>Answer</summary>


<code>sudo systemctl list-units --type service</code>


</details>


### Stop nginx service and remove its service unit file. Make sure not to remove nginx package from the system.

<details>
<summary>Answer</summary>

```

systemctl list-units --all | grep nginx

systemctl stop nginx

// Find out the location of the service unit:

systemctl status nginx

rm /lib/systemd/system/nginx.service

```

</details>


### Stop service listening on port 9090

<details>
<summary>Answer</summary>

```

netstat -natp  | grep 9090

OR

ss -tulnp | grep 9090

systemctl stop <service>
```

</details>
