### Identify the CNI

<details>
<summary>Answer</summary>

On a Kubernetes node, kubelet is configured to use a CNI plugin. The kubelet has CNI-related configuration such as:

```
--cni-conf-dir=/etc/cni/net.d
--cni-bin-dir=/opt/cni/bin
```

The CNI configuration files are normally under **/etc/cni/net.d/**


For example, you might find:

```
/etc/cni/net.d/05-cilium.conflist
```

or:

```
/etc/cni/net.d/10-flannel.conflist
```

or:

```
/etc/cni/net.d/10-calico.conflist
```

That file tells the container runtime/CNI machinery which plugin(s) should be invoked.

Additionally, we can check the pods in kube-system namespace

kubectl get pods -n kube-system

</details>


### Verify encryption

<details>
<summary>Answer</summary>

#### Verify that Cilium is configured with encryption

```
cilium status
cilium encrypt status

Encryption: WireGuard
Enabled:    true
Interface:  cilium_wg0
```


Information about WireGuard peers/endpoints, for example:

```
Node             Public Key              Endpoint
worker-1         <key>                   <endpoint>
worker-2         <key>                   <endpoint>
```

#### Verify actual traffic via packet capture

Generate traffic from Pod A to Pod B:

<code>kubectl exec -it pod-a -- curl http://<pod-b-ip>:8080 </code>

Then capture traffic on Node 1's physical interface, e.g.:

<code>tcpdump -i eth0 -n host node-2-ip  </code>

You should not see the original Pod-to-Pod traffic as ordinary TCP/HTTP.

#### We can also exec into Cilium daemonset's pod and check configuration

```
kubectl -n kube-system exec -ti ds/cilium -- bash and execute the following commands:

Check that WireGuard has been enabled (number of peers should correspond to a number of nodes subtracted by one):

cilium-dbg status | grep Encryption

Install tcpdump

apt-get update
apt-get -y install tcpdump

Check that traffic is sent via the cilium_wg0 tunnel device is encrypted:

tcpdump -n -i cilium_wg0 -X

The -n option avoids DNS lookups, and the -X option shows packet content in both hexadecimal and ASCII format.

```

</details>


### Check WireGuard interface

<details>
<summary>Answer</summary>

Cilium normally creates a WireGuard interface on the node, commonly: cilium_wg0

```
ip link show
wg show
```
You should see WireGuard peers and their public keys.

</details>

