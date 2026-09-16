// Hetzner Cloud Firewalls filter public interfaces only.
// Private east-west cluster traffic must be secured on the hosts themselves.

resource "hcloud_firewall" "hetzner_controlplane_fw" {
  name = "hetzner_controlplane_fw"

  # K8s API accessible from the admin laptop.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "6443"
    source_ips = [var.admin_ssh_subnet_cidr]
  }

  dynamic "apply_to" {
    for_each = toset(var.controlplane_server_ids)
    content {
      server = apply_to.value
    }
  }
}
