## WireGuard


<details>
<summary>Answer</summary>

Cilium supports more than one encryption mechanism: WireGuard, IPsec. 

Cilium can use encrypted **WireGuard** tunnel to encrypt traffic **between Kubernetes nodes**. WireGuard is VPN technology integrated into Linux.

The application doesn't need to know anything about WireGuard. Instead, Cilium transparently handles it.
(transparent encryption). 

#### Between nodes vs pod-to-pod on the same node

Regardless of the underlying mechanism, this is not application level encryption like TLS, but rather network level (IP level). Cilium takes the IP packet and carries it through an encrypted WireGuard tunnel.
It transparently encrypts the packet as it crosses the node boundary and decrypts it on the other node.

The important consequence of this distinction is that while TLS can protect **same-node Pod-to-Pod** communication, because the encryption belongs to the application connection, **WireGuard/IPsec node encryption doesn't** have that property.


#### TODO
Where are the WireGuard interfaces?
What are the peer relationships?
What traffic gets routed through them?
How does Cilium know the peer's public key?
What happens with same-node pod traffic?
What happens with host traffic?
What does encryption.nodeEncryption change?
What is the difference between pod-to-pod encryption and node-to-node encryption?

What does the Cilium agent do versus the Linux WireGuard implementation?

</details>


## Installation and configuration

<details>
<summary>Answer</summary>

### With CLI, without Helm 

1. install Cilium CLI
2. cilium install

To enable pod-to-pod encryption

```
cilium install \
  --set encryption.enabled=true \
  --set encryption.type=wireguard
```

3. cilium status --wait

The Cilium agent is deployed as a DaemonSet. Verify:

<code>kubectl -n kube-system get daemonset cilium </code>

4. cilium encrypt status

#### Verify pod networking works
1. Create pod or deployment and check that pod has received an IP
2. Run 
<code>cilium connectivity test</code>

#### ConfigMap
Some configuration is in ConfigMap


<code>kubectl -n kube-system get configmap cilium-config</code>

### With Helm

```
helm repo add cilium https://helm.cilium.io/
helm repo update
helm search repo cilium/cilium

helm install cilium cilium/cilium \
  --namespace kube-system \
  --set encryption.enabled=true \
  --set encryption.type=wireguard


cilium status --wait
cilium encrypt status

```

##### Check encryption config

```
helm get values cilium -n kube-system
OR

helm show values cilium/cilium


encryption:
  enabled: true
  type: wireguard

```

</details>

## eBPF

<details>
<summary>Answer</summary>

**eBPF** = where Cilium implements the networking logic (datapath).
**WireGuard** = the encryption mechanism used by that networking logic.

Pod-A on Node-1 --> eBPF Cilium code --> WireGuard --> encrypted --> Wireguard on Node-2 --> eBPF Cilium code --> Pod-B

**eBPF** handles things such as:

- packet processing
- routing
- forwarding
- network policy
- load balancing
- connection tracking
- deciding what should happen to a packet

**WireGuard** handles:

- encrypting the packet
- authenticating the peer
- decrypting it on the other node

Cilium can attach eBPF programs to relevant points in the Linux networking stack.

pod --> kernel --> Cilium eBPF (policy enforcement, routing, identity, encryption integration) --> network



### What actually happens to a packet?

```
Pod A: 10.0.0.10
Pod B: 10.0.1.20
```

Pod-A sends HTTP request --> IP packet 10.0.0.10 → 10.0.1.20

Cilium's eBPF programs intercept/process that packet. Since "10.0.1.20 is on another node." and WireGuard encryption is enabled, Cilium sends the traffic through its WireGuard path.

WireGuard effectively transforms: 

```
Original packet

[ IP 10.0.0.10 → 10.0.1.20 | TCP | HTTP data ]
```

into something like:

```
Encrypted packet

[ Node1 IP → Node2 IP | UDP | encrypted payload ]
```


Over the physical network, you therefore see something like:

Node1 ═══ UDP / encrypted ═══► Node2

Node 2 receives it, WireGuard decrypts it, and Cilium's networking machinery delivers the resulting packet to Pod B.

</details>