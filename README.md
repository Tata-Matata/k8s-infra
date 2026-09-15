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

When creating `k8s_servers`, Terraform prompts for the admin laptop CIDR that is allowed SSH access to the cluster.

You can provide either:

1. An explicit `/32` CIDR, for example `203.0.113.10/32`
2. An empty value, in which case Terraform auto-detects the current laptop public IP and uses it as `/32`

## Ansible

This section is intentionally empty for now.

Ansible will be used later to configure the provisioned servers.