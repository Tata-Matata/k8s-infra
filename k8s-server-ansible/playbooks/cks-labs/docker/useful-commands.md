## Run docker as foreground process

Useful for troubleshooting, especially in debug mode


<details>
<summary>Answer</summary>

```
dockerd
dockerd --debug
```

</details>

## Make docker accessible to docker CLI on a remote host

<details>
<summary>Answer</summary>

When docker daemon starts, it listens on internal unix socket at **/var/run/docker.sock**. Unix socket is an inter-process communication mechanism, for processes communicating on the same host, so docker daemon is only accessible on the same host.

Docker CLI is configured to communicate with docker daemon on this Unix socket.
What if we want to use Docker CLI on another host.  By default, docker daemon only listens on the unix socket of the localhost, but  we can make it listen on TCP interface on the Docker host. 

```
dockerd --debug --host=tcp://192.168.1.10:2375
```

**2375** is the standard port for Docker
The remote host can set env var <code>export DOCKER_HOST="tcp://192.168.1.10:2375"</code>


This connection is **not encrypted** by default and no authentication is required, so you should not do this on a public facing host

</details>

## Enable encryption

<details>
<summary>Answer</summary>

1. create a pair of TLS certificates
2. Now the standard port will be 2376, not 2375
   
   ```

   dockerd --debug --host=tcp://192.168.1.10:2376 \
   --tls=true \
   --tlscert=/var/docker/server.pem  \
   --tlskey=/var/docker/serverkey.pem

   ```

3. or move these options to config file at **/etc/docker/daemon.json** in key value format

```

{
  "debug" : true,
  "hosts": ["tcp://192.168.1.10:2376"]
  "tls": true,
  "tlscert": ...
  ...

}

```

*hosts* is an array and so it supports multiple listeners
   

This config is also used if we start Docker as service with <code>systemctl start docker</code>

On the client side, we set <code> export DOCKER_TLS=true</code> or <code> docker --tls ps</code>

### This enables encrypted communication but does not necessarily verify server certificate 

The daemon presents its certificate, the client encrypts the connection, but the client doesn't authenticate itself with a client certificate.
So this setup alone does not prevent anyone to connect to our docker daemon if the public facing interface is exposed. 

</details>

## Enable certificate based authentication

<details>
<summary>Answer</summary>

We need to add these flags. <code>tlsverify</code> enables cert based authentication and the CA cert is used to verify the certificates presented by clients

```

{

  "tlsverify": true,
  "tlscacert": "/var/docker/ca.pem"
  ...

}

```

We generate certificates for our clients signed by this CA key and share cert, key and CA cert securely with the client host that wants to connect to docker daemon remotely.

On the client side, we also set <code> export DOCKER_TLS_VERIFY=true</code>

Now we can pass cert and key as cmd parameter

```
docker --tlscert ... --tlskey ... --tlscacert ... 
```

or we drop the certs under **~/.docker**

This setup enables mTLS

</details>

## Risks associated with access to docker daemon

<details>
<summary>Answer</summary>


Anyone with access to docker daemon can 

- delete existing containers hosting applications
- delete volumes storing data
- run containers hosting their own applications
- run a privileged container and gain root access to the host system

</details>

## Securing Docker server

<details>
<summary>Answer</summary>

1. Secure docker host
   - disable password based authentication
   - enable ssh key based authentication
   - determine users who need access to the host
   - disable unused ports
2. if you allow access to docker daemon from remote host
   - expose on private interfaces accessible within the private network of the organisation
   - secure communication through TLS certificates for server (s. above)
   - enable certificate based authentication for remote clients

</details>