//Restricts controlplane and worker access to the minimum ports needed by the cluster

resource "hcloud_firewall" "hetzner_controlplane_fw" {
  name = "hetzner_controlplane_fw"

  # K8s API accessible from the admin laptop.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [var.admin_ssh_subnet_cidr]
  }

  # Worker nodes must reach the API server over the private subnet.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [var.private_subnet_cidr]
  }

  # Cilium VXLAN traffic stays private.
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "4789"
    source_ips = [var.private_subnet_cidr]
  }

  apply_to {
    label_selector = "role=controlplane"
  }
}

resource "hcloud_firewall" "hetzner_worker_fw" {
  name = "hetzner_worker_fw"

  # ProxyJump lands on the worker from the controlplane over the private subnet.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.controlplane_ip_cidrs
  }

  # Controlplane components need kubelet access on the worker.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "10250"
    source_ips = var.controlplane_ip_cidrs
  }

  # Cilium VXLAN traffic stays private.
  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "4789"
    source_ips = [var.private_subnet_cidr]
  }

  apply_to {
    label_selector = "role=worker"
  }
}
