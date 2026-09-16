variable "admin_ssh_subnet_cidr" {
  type        = string
  description = "CIDR of the subnet that is allowed to ssh into the Hetzner server"
  validation {
    condition     = can(cidrnetmask(var.admin_ssh_subnet_cidr))
    error_message = "admin_ssh_subnet_cidr must be a valid CIDR block"
  }
}

variable "controlplane_server_ids" {
  type        = list(number)
  description = "Hetzner server IDs for control plane nodes"
}
