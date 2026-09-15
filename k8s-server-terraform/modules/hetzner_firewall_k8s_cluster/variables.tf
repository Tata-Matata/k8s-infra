variable "admin_ssh_subnet_cidr" {
  type        = string
  description = "CIDR of the subnet that is allowed to ssh into the Hetzner server"
  validation {
    condition     = can(cidrnetmask(var.admin_ssh_subnet_cidr))
    error_message = "admin_ssh_subnet_cidr must be a valid CIDR block"
  }
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR of the private subnet used for node-to-node traffic"
  validation {
    condition     = can(cidrnetmask(var.private_subnet_cidr))
    error_message = "private_subnet_cidr must be a valid CIDR block"
  }
}

variable "controlplane_ip_cidrs" {
  type        = list(string)
  description = "Controlplane private IPs expressed as /32 CIDRs"
  validation {
    condition = alltrue([
      for cidr in var.controlplane_ip_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "controlplane_ip_cidrs must contain only valid CIDR blocks."
  }
}
