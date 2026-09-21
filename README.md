# k8s-infra

This repository is split into two parts:

## Terraform

Terraform is used to provision the Hetzner infrastructure for the Kubernetes cluster.

Provision the Terraform stacks in this order:

1. `k8s-server-terraform/global/ssh_keys`
2. `k8s-server-terraform/core_network`
3. `k8s-server-terraform/k8s_servers`

The order matters:

1. `global/ssh_keys` registers the SSH key in Hetzner and exports the key ID.
2. `core_network` creates the private network and subnet used by the cluster nodes.
3. `k8s_servers` creates the controlplane and worker servers and attaches them to the network and firewalls.

The `k8s_servers` stack also creates a Hetzner private network route `0.0.0.0/0`
through `controlplane-1`. This is required because worker nodes do not have public
IP addresses and need `controlplane-1` to act as a NAT gateway for outbound
internet access.

### SSH access for cluster admin 

When creating `k8s_servers`, Terraform prompts for the admin laptop CIDR that is allowed SSH access to the cluster.

You can provide either:

1. An explicit `/32` CIDR, for example `203.0.113.10/32`
2. An empty value, in which case Terraform auto-detects the current laptop public IP and uses it as `/32`

##### SSH jump

Worker nodes are on private network, do not have public IP. They can be reached from admin computer via ssh jump over controlplane host.
Example ssh config to make this work on laptop.

~/.ssh/config

```
Host controlplane
  HostName <public-ip>
  User root
  IdentityFile <path to private key>
Host worker
  HostName <private-ip>
  User root
  IdentityFile <path to private key>

```

<code>ssh -J root@controlplane root@worker</code>

### Private worker egress

Workers are private-only Hetzner VMs. That means:

1. They can be reached over SSH via `controlplane-1`.
2. They cannot download packages or release artifacts from the internet unless outbound traffic is routed through a NAT gateway.
3. `controlplane-1` is used as that NAT gateway.

The egress path has two routing layers, and both are required.

1. Guest-side routing inside the worker VM.

Hetzner brings up the worker private NIC on Linux through DHCP on the private
network. In this context, DHCP does not only mean "assign an IP address". The
lease also carries other network settings, such as routes and MTU.

On these worker VMs, that private-network DHCP lease gives the interface a
private address such as `10.50.1.1/32` and installs routes into the private
network via the Hetzner-managed gateway `10.50.0.1` (this IP can be determined
from Terraform state after creating the subnet). That gateway is a property of
the Hetzner private subnet itself, not something we set explicitly in
Terraform.

We want private workers to use this gateway not only for access to the private subnet, 
but to any target outside the cluster. Terraform cloud-init adds a persistent guest-side default
route:

`default via 10.50.0.1 dev enp7s0`

This tells the worker kernel where to send internet-bound traffic.

2. Provider-side routing inside the Hetzner private network.

Terraform creates an `hcloud_network_route` for `0.0.0.0/0` whose gateway is
the private IP of `controlplane-1`, for example `10.50.1.101`.

This is not a Linux route inside the worker VM. It is a Hetzner network object
that tells the private network to forward default traffic toward the control
plane once the worker has already sent that traffic to the Hetzner subnet
gateway (the one mentioned above).

3. Linux NAT on the control plane.

When traffic reaches `controlplane-1`, that node must behave like a router:

1. `net.ipv4.ip_forward=1`
2. `iptables` MASQUERADE from the private network to the public interface
3. `FORWARD` rules for outbound and return traffic

Without this third step, traffic can reach `controlplane-1` but cannot leave to
the public internet.

The end-to-end packet path is therefore:

1. worker sends all traffic to `10.50.0.1`
2. Hetzner private-network routing forwards `0.0.0.0/0` traffic to `10.50.1.101`
3. `controlplane-1` NATs it out through its public interface

### Cloud-init responsibilities

The control plane and workers now use separate `user_data` templates.

Control plane cloud-init:

1. trusts Hetzner to bring up the private NIC
2. installs `iptables-persistent` and `netfilter-persistent`
3. enables IPv4 forwarding
4. detects the public and private interfaces at first boot
5. installs persistent NAT and FORWARD rules

Worker cloud-init:

1. extends the active Hetzner private-NIC netplan definition
2. adds a persistent default route via the Hetzner subnet gateway `10.50.0.1`
3. adds explicit DNS resolvers

This split exists because control planes already boot with both NICs correctly
configured by Hetzner, while workers need one extra guest-side default route to
make private-only egress work.

### DNS special case

Worker routing and NAT alone are not enough for name resolution.

In this setup, Hetzner's private-network DHCP lease provides the worker private
address and private-network routes, but it does not provide upstream DNS
servers. That means worker internet access by IP can work while DNS still
fails.

To keep the solution simple, worker cloud-init sets explicit public DNS
resolvers in netplan. Today that is configured through Terraform as
`worker_dns_servers` in `k8s-server-terraform/k8s_servers/variables.tf`.

So the worker boot path now guarantees all three pieces:

1. private IP on the Hetzner network
2. default route via `10.50.0.1`
3. explicit upstream DNS servers


## Ansible

Suggested order for the current playbooks:

1. verify private network egress / NAT setup


The control-plane NAT itself is now bootstrapped by Terraform cloud-init.
Ansible is still useful as a verification layer before package installation.
Without working egress, private-only workers will fail on tasks that download
packages or artifacts from public URLs.

