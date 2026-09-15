//Restricts SSH access

resource "hcloud_firewall" "hetzner_only_ssh_fw" {
  name = "hetzner_only_ssh_fw"



  # SSH to the server only from admin home network 
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = [var.admin_ssh_subnet_cidr]
  }

  apply_to {
    label_selector = "firewall=ssh-only"
  }

}
