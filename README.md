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

When creating `k8s_servers`, Terraform prompts for the admin laptop CIDR that is allowed SSH access to the cluster.

You can provide either:

1. An explicit `/32` CIDR, for example `203.0.113.10/32`
2. An empty value, in which case Terraform auto-detects the current laptop public IP and uses it as `/32`

### SSH jump

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

The NAT setup has two parts:

1. Terraform configures the Hetzner-side route so private worker traffic is sent to `controlplane-1`.
2. Ansible configures the Linux-side NAT on `controlplane-1`. Worker private-interface addressing and routing stay under Hetzner/Terraform provisioning and are verified separately.


## Ansible

Suggested order for the current playbooks:

1. private network egress / NAT setup
2. verify private network egress / NAT setup


The NAT-related Ansible step should run before package installation.
Without it, private-only workers will fail on tasks that download packages or
artifacts from public URLs.