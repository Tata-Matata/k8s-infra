

### What network sockets are listening on which ports?

<details>
<summary>Answer</summary>

#### netstat

```
netstat -an | grep -w LISTEN
```

grep -w means match the pattern as a whole word.

-a → show all sockets, including listening sockets
-n → show numeric IP addresses and port numbers; don't perform DNS/service-name resolution

```

LISTEN  0  128  0.0.0.0:443  0.0.0.0:*

```

Meaning: There is a TCP socket in the LISTEN state, bound to port 443 on all IPv4 interfaces.

#### ss

On modern Linux, netstat is usually deprecated and ss is preferred:

```
ss -an
```

And for listening TCP/UDP sockets:

```
ss -tuln
```


</details>


### Get more info about a specific port, what is using it

<details>
<summary>Answer</summary>


For example, if we don't know what is listening on port 53

#### /etc/services

<code>cat /etc/services | grep -w 53</code>

Output could be

```
domain		53/tcp				# Domain Name Server
domain		53/udp

```

This tells you: By convention, port 53 is associated with the domain service (DNS).
It does not tell you: DNS is actually running on port 53 on this machine. So think of /etc/services as documentation/convention, not a reflection of the machine's current configuration.


#### ss

<code>sudo ss -lntup | grep -w 53</code>

users: output could be useful here

```

udp   UNCONN 0      0                               127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=1098,fd=16))
udp   UNCONN 0      0                            127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=1098,fd=14))
tcp   LISTEN 0      4096                            127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=1098,fd=17))
tcp   LISTEN 0      4096                         127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=1098,fd=15))

```

#### ps

we can also get some more info using this process id

<code>sudo ps -fp 1098</code>

-f → full format — show more information about the process
-p 742 → select the process with PID 742

```
systemd+    1098       1  0 20:49 ?        00:00:00 /usr/lib/systemd/systemd-resolved

```

#### 


#### lsof

<code>sudo lsof -i :53</code>

```

systemd-r 1098 systemd-resolve   14u  IPv4  13653      0t0  UDP _localdnsstub:domain 
systemd-r 1098 systemd-resolve   15u  IPv4  13654      0t0  TCP _localdnsstub:domain (LISTEN)
systemd-r 1098 systemd-resolve   16u  IPv4  13655      0t0  UDP _localdnsproxy:domain 
systemd-r 1098 systemd-resolve   17u  IPv4  13656      0t0  TCP _localdnsproxy:domain (LISTEN)

```

</details>